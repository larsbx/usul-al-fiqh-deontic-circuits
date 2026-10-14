"""Negative controls run offline; the mandatory CLI separately replays real witnesses."""
import hashlib
import json

import pytest

from usul_corpus import source_verify as gate

TEXT = "# هذا الحكم ثابت إلا عند الضرورة\nPageV01P001\n# لا إجمال في البيع\nPageV01P002\n"
QUOTE = "لا إجمال في البيع"


@pytest.fixture
def fixture(tmp_path):
    corpus, cache = tmp_path / "corpus", tmp_path / "cache"
    (corpus / "reconciliation").mkdir(parents=True)
    cache.mkdir()
    witness = {"id": "test-source", "kind": "openiti", "repo": "test",
               "commit": "a" * 40, "path": "source"}
    registry = {"works": [{"rights": "public_domain_text", "witnesses": [witness]}]}
    lock = {"witnesses": {"test-source": {"url": gate.fetch.witness_url(witness),
            "bytes": len(TEXT.encode()), "sha256": hashlib.sha256(TEXT.encode()).hexdigest()}}}
    evidence = {"ref": "src:test-source/v01:p002", "excerpt_ar": QUOTE}
    ledger = {"entries": [{"far": "base-case", "evidence": [evidence]}]}
    for name, data in (("registry.json", registry), ("lock.json", lock), ("reconciliation/ledger.json", ledger)):
        (corpus / name).write_text(json.dumps(data), encoding="utf-8")
    (cache / "test-source.txt").write_text(TEXT, encoding="utf-8")
    return corpus, cache


def change_evidence(corpus, **updates):
    path = corpus / "reconciliation/ledger.json"
    data = json.loads(path.read_text())
    data["entries"][0]["evidence"][0].update(updates)
    path.write_text(json.dumps(data))


def test_real_quote_with_page_and_qualifier_passes(fixture):
    corpus, cache = fixture
    change_evidence(corpus, excerpt_ar="هذا الحكم ثابت إلا عند الضرورة", ref="src:test-source/v01:p001")
    report = gate.verify(corpus, cache)
    assert report["status"] == "verified_required_subset"
    assert report["counts"] == {"verified": 1}
    assert report["witnesses"][0]["sha256"] == hashlib.sha256(TEXT.encode()).hexdigest()


@pytest.mark.parametrize("mutation", ["missing", "changed_bytes", "wrong_quote", "wrong_page", "qualifier", "empty", "lfs", "missing_pin", "wrong_url", "bad_locator"])
def test_negative_controls_fail_closed(fixture, mutation):
    corpus, cache = fixture
    source = cache / "test-source.txt"
    if mutation == "missing": source.unlink()
    elif mutation == "changed_bytes": source.write_text(TEXT + " ")
    elif mutation == "wrong_quote": change_evidence(corpus, excerpt_ar="إجمال في النكاح")
    elif mutation == "wrong_page": change_evidence(corpus, ref="src:test-source/v01:p001")
    elif mutation == "qualifier": change_evidence(corpus, excerpt_ar="هذا الحكم ثابت", ref="src:test-source/v01:p001")
    elif mutation == "empty": change_evidence(corpus, excerpt_ar="...")
    elif mutation == "lfs": source.write_text("version https://git-lfs.github.com/spec/v1\noid sha256:" + hashlib.sha256(TEXT.encode()).hexdigest() + f"\nsize {len(TEXT.encode())}\n")
    elif mutation == "missing_pin": (corpus / "lock.json").write_text('{"witnesses": {}}')
    elif mutation == "wrong_url":
        path = corpus / "lock.json"
        lock = json.loads(path.read_text()); lock["witnesses"]["test-source"]["url"] += "other"
        path.write_text(json.dumps(lock))
    elif mutation == "bad_locator": change_evidence(corpus, ref="src:test-source#q1")
    assert gate.verify(corpus, cache)["status"] == "failed"
    report = corpus.parent / "report.json"
    assert gate.main(["--corpus", str(corpus), "--cache", str(cache), "--report", str(report)]) == 1
    assert json.loads(report.read_text())["status"] == "failed"


def test_fetch_is_pinned_and_does_not_update_the_lock(fixture, monkeypatch):
    corpus, cache = fixture
    path = cache / "test-source.txt"
    path.unlink()
    before = (corpus / "lock.json").read_bytes()
    calls = []
    monkeypatch.setattr(gate.fetch, "_get", lambda url: calls.append(url) or TEXT.encode())
    assert gate.verify(corpus, cache, fetch_source=True)["status"] == "verified_required_subset"
    assert calls == [json.loads(before)["witnesses"]["test-source"]["url"]]
    assert (corpus / "lock.json").read_bytes() == before
    path.unlink()
    monkeypatch.setattr(gate.fetch, "_get", lambda url: TEXT.encode() + b"changed")
    assert gate.verify(corpus, cache, fetch_source=True)["status"] == "failed"
    assert (corpus / "lock.json").read_bytes() == before


def test_fetch_failure_is_a_failure_not_an_exclusion(fixture, monkeypatch):
    corpus, cache = fixture
    (cache / "test-source.txt").unlink()
    def fail(url): raise OSError("network unavailable")
    monkeypatch.setattr(gate.fetch, "_get", fail)
    report = gate.verify(corpus, cache, fetch_source=True)
    assert report["status"] == "failed" and report["counts"] == {"failed": 1}


def test_restore_uses_actual_locked_text_not_pointer(fixture, monkeypatch):
    corpus, cache = fixture
    (cache / "test-source.txt").unlink()
    (corpus / "texts").mkdir()
    (corpus / "texts/test-source.txt").write_text(TEXT)
    assert gate.verify(corpus, cache)["status"] == "verified_required_subset"


def test_repeated_quote_checks_the_declared_page():
    text = "# هذا الحكم ثابت إلا عند الضرورة\nPageV01P001\n# هذا الحكم ثابت\nPageV01P002\n"
    assert gate.check_quote(text, "هذا الحكم ثابت", "v01:p002") is None
    assert "qualifier" in gate.check_quote(text, "هذا الحكم ثابت", "v01:p001")
    assert "absent" in gate.check_quote(text, "هذا الحكم ثابت", "v01:p003")


def test_page_break_does_not_hide_a_qualifier():
    text = "# هذا الحكم ثابت\nPageV01P001\n# إلا عند الضرورة\nPageV01P002\n"
    assert "qualifier" in gate.check_quote(text, "هذا الحكم ثابت", "v01:p001")


def test_exclusions_are_explicit_and_required_failure_cannot_be_excluded(fixture):
    corpus, cache = fixture
    (corpus / "other.json").write_text(json.dumps([
        {"ref": "src:unavailable-modern/v01:p001", "excerpt_ar": QUOTE},
        {"ref": "src:test-source#q001", "excerpt_ar": QUOTE}]))
    report = gate.verify(corpus, cache)
    assert report["counts"] == {"excluded": 2, "verified": 1}
    assert all(row["reason"] for row in report["checks"] if row["status"] == "excluded")
    (cache / "test-source.txt").unlink()
    report = gate.verify(corpus, cache)
    assert report["status"] == "failed" and report["counts"]["failed"] == 1


def test_empty_required_set_is_not_success(fixture):
    corpus, cache = fixture
    (corpus / "reconciliation/ledger.json").write_text('{"entries": []}')
    assert gate.verify(corpus, cache)["status"] == "failed"


def test_shard_only_witness_is_required_and_cannot_hide_in_exclusions(fixture):
    corpus, cache = fixture
    registry = json.loads((corpus / "registry.json").read_text())
    witness = {**registry["works"][0]["witnesses"][0], "id": "shard-source"}
    registry["works"][0]["witnesses"].append(witness)
    (corpus / "registry.json").write_text(json.dumps(registry))
    locks = json.loads((corpus / "lock.json").read_text())
    locks["witnesses"]["shard-source"] = locks["witnesses"]["test-source"].copy()
    (corpus / "lock.json").write_text(json.dumps(locks))
    fragments = corpus / "reconciliation/entries"
    fragments.mkdir()
    (fragments / "new.json").write_text(json.dumps({"entries": [{"far": "shard-case", "evidence": [
        {"ref": "src:shard-source/v01:p002", "excerpt_ar": QUOTE}]}]}))
    assert gate.required_witnesses(corpus) == {"test-source", "shard-source"}
    report = gate.verify(corpus, cache)
    assert report["status"] == "failed" and report["counts"] == {"failed": 1, "verified": 1}
    (cache / "shard-source.txt").write_text(TEXT)
    assert gate.verify(corpus, cache)["counts"] == {"verified": 2}
