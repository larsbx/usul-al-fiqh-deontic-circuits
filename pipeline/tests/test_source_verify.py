"""Negative controls run offline; the mandatory CLI separately replays real witnesses."""
import hashlib
import json

import pytest

from usul_corpus import source_verify as gate
from usul_corpus import position_receipts

TEXT = "# هذا الحكم ثابت إلا عند الضرورة\nPageV01P001\n# لا إجمال في البيع\nPageV01P002\n"
QUOTE = "لا إجمال في البيع"


def receipt_case(far):
    return {"far": far, "positions": [{"who": "fixture holder", "ruling": False}]}


@pytest.fixture
def fixture(tmp_path):
    corpus, cache = tmp_path / "corpus", tmp_path / "cache"
    (corpus / "reconciliation").mkdir(parents=True)
    (corpus / "takhrij").mkdir()
    cache.mkdir()
    witness = {"id": "test-source", "kind": "openiti", "repo": "test",
               "commit": "a" * 40, "path": "source"}
    registry = {"works": [{"rights": "public_domain_text", "witnesses": [witness]}]}
    lock = {"witnesses": {"test-source": {"url": gate.fetch.witness_url(witness),
            "bytes": len(TEXT.encode()), "sha256": hashlib.sha256(TEXT.encode()).hexdigest()}}}
    evidence = {"ref": "src:test-source/v01:p002", "excerpt_ar": QUOTE}
    cases = [receipt_case(far) for far in ("base-case", "shard-case")]
    ledger = {"entries": [{"far": "base-case", "evidence": [evidence],
                           position_receipts.FIELD: position_receipts.digest(cases[0])}]}
    for name, data in (("registry.json", registry), ("lock.json", lock),
                       ("takhrij/cases.json", {"cases": cases}), ("reconciliation/ledger.json", ledger)):
        (corpus / name).write_text(json.dumps(data), encoding="utf-8")
    (cache / "test-source.txt").write_text(TEXT, encoding="utf-8")
    # Every negative control must begin with an admissible, passing source case.
    assert gate.verify(corpus, cache)["status"] == "verified_required_subset"
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


def test_a_stale_cached_witness_is_refetched_only_when_fetching(fixture, monkeypatch):
    """A restored CI cache may hold bytes of an earlier pin: verification fails on them, a fetch replaces them."""
    corpus, cache = fixture
    (cache / "test-source.txt").write_text(TEXT + "earlier pin")
    assert gate.verify(corpus, cache)["status"] == "failed"
    monkeypatch.setattr(gate.fetch, "_get", lambda url: TEXT.encode())
    assert gate.verify(corpus, cache, fetch_source=True)["status"] == "verified_required_subset"
    assert (cache / "test-source.txt").read_text() == TEXT


def test_a_checkpoint_resumes_only_under_its_own_pin(fixture, monkeypatch):
    """A restored `.part` from an interrupted fetch resumes only for the pin it was started under."""
    corpus, cache = fixture
    (cache / "test-source.txt").unlink()
    part, seen = cache / "test-source.part", []
    def fetch(w, c):
        seen.append(part.exists())
        (c / "test-source.txt").write_text(TEXT)
        part.unlink(missing_ok=True)
    monkeypatch.setattr(gate.fetch, "fetch", fetch)
    part.write_text("pages of an earlier pin")
    assert gate.verify(corpus, cache, fetch_source=True)["status"] == "verified_required_subset"
    (cache / "test-source.txt").unlink()
    part.write_text("pages of this pin")
    (cache / "test-source.part.pin").write_text(gate._pin(json.loads((corpus / "lock.json").read_text())["witnesses"]["test-source"]))
    assert gate.verify(corpus, cache, fetch_source=True)["status"] == "verified_required_subset"
    assert seen == [False, True]


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


NUMERAL_TEXT = "# أقر أن عليه 100 درهم حالة\nPageV01P001\n"


@pytest.mark.parametrize("quote", ["عليه 100 درهم", "عليه ١٠٠ درهم", "عليه ۱۰۰ درهم"])
def test_a_numeral_is_matched_across_digit_scripts(quote):
    assert gate.check_quote(NUMERAL_TEXT, quote, "v01:p001") is None


@pytest.mark.parametrize("quote", ["عليه 999 درهم", "عليه ٩٩٩ درهم", "عليه 10 درهم", "عليه 1 00 درهم", "عليه درهم"])
def test_a_changed_or_dropped_numeral_fails(quote):
    """Audit: letters-only comparison accepted «عليه 999 درهم» against «عليه 100 درهم»."""
    assert "absent" in gate.check_quote(NUMERAL_TEXT, quote, "v01:p001")


def test_footnote_anchors_and_page_markers_are_markup():
    """Shamela footnote anchors are digits glued to a word (`علماء1`); page markers carry digits too."""
    text = "# قال أكثر العلماء1 بثبوته2 في 3 مواضع\nPageV01P007\n# وبه قال الموفق\nPageV01P008\n"
    assert gate.check_quote(text, "قال أكثر العلماء بثبوته في 3 مواضع", "v01:p007") is None
    assert gate.check_quote(text, "قال أكثر العلماء١ بثبوته في 3 مواضع", "v01:p007") is None
    assert gate.check_quote(text, "في 3 مواضع وبه قال", "v01:p008") is None
    assert "absent" in gate.check_quote(text, "قال أكثر العلماء بثبوته في 4 مواضع", "v01:p007")


def test_negated_parenthesised_footnote_anchors_are_markup():
    """al-Furūʿ's Shamela witness marks footnotes «(¬7)», with or without them in the excerpt."""
    text = "# خلافا للحلواني (¬7) وبعض الشافعية\n~~(¬8)؛ لأن الله حكى عنهم\nPageV03P1011\n"
    for quote in ("خلافا للحلواني وبعض الشافعية؛ لأن الله حكى عنهم", "خلافا للحلواني (¬7) وبعض الشافعية (¬8)؛ لأن الله حكى عنهم"):
        assert gate.check_quote(text, quote, "v03:p1011") is None


def test_page_break_does_not_hide_a_qualifier():
    text = "# هذا الحكم ثابت\nPageV01P001\n# إلا عند الضرورة\nPageV01P002\n"
    assert "qualifier" in gate.check_quote(text, "هذا الحكم ثابت", "v01:p001")


LA_TEXT = "# قال لا يجوز البيع إلا بالقبض\nPageV01P001\n"


def test_a_presentation_form_ligature_keys_as_its_letters():
    """Audit PR-35: «ﻻ» (U+FEFB) carried no key, so «قال ﻻ يجوز البيع» matched «قال يجوز البيع»."""
    assert "absent" in gate.check_quote("# قال يجوز البيع\nPageV01P001\n", "قال ﻻ يجوز البيع", "v01:p001")
    assert gate.check_quote("# قال ﻻ يجوز البيع\nPageV01P001\n", "قال لا يجوز البيع", "v01:p001") is None


def test_an_arabic_letter_outside_the_key_is_rejected():
    """A letter the key does not carry would be skipped by the comparison, so the excerpt may not hold one."""
    assert gate.check_quote(LA_TEXT, "قال لا يجوز ٻالبيع", "v01:p001") == "letters outside the quotation key: ٻ"


def test_a_quotation_cannot_drop_a_negation_just_before_it():
    """Audit PR-35: «يجوز البيع» passed against «قال لا يجوز البيع»."""
    assert gate.check_quote(LA_TEXT, "يجوز البيع إلا بالقبض", "v01:p001") == "quotation drops the negation «لا» before it"
    assert gate.check_quote("# (لم\n~~يلزمه) شيء\nPageV01P001\n", "يلزمه) شيء", "v01:p001") == \
        "quotation drops the negation «لم» before it"
    # Punctuation ends the negation's clause: «أم لا؟ الأظهر …» starts a new sentence.
    assert gate.check_quote("# هل يسترد أم لا؟ الأظهر استرداده\nPageV01P001\n", "الأظهر استرداده", "v01:p001") is None


def test_a_quotation_starts_and_ends_on_word_boundaries():
    """Audit PR-35: «يجوز البي» passed against «يجوز البيع إلا …», hiding the qualifier after the word."""
    assert gate.check_quote(LA_TEXT, "لا يجوز البي", "v01:p001") == "quotation ends mid-word"
    assert gate.check_quote(LA_TEXT, "ال لا يجوز البيع إلا بالقبض", "v01:p001") == "quotation starts mid-word"
    assert gate.check_quote(LA_TEXT, "قال لا يجوز البيع إلا بالقبض", "v01:p001") is None


def test_markup_inside_a_word_is_not_a_word_boundary():
    """Review (#95): a page marker inside a word must not let a quotation start or end there."""
    assert gate.check_quote("# قال الPageV01P001بيع جائز\nPageV01P002\n", "بيع جائز", "v01:p002") == "quotation starts mid-word"
    assert gate.check_quote("# قال البيPageV01P001ع جائز\nPageV01P002\n", "قال البي", "v01:p001") == "quotation ends mid-word"


def test_a_quotation_wholly_in_presentation_forms_is_not_empty():
    """Review (#95): emptiness is judged on the key, after presentation forms unfold."""
    assert gate.check_quote("# ﻗﺎﻝ ﻻ ﻳﺠﻮﺯ\nPageV01P001\n", "ﻗﺎﻝ ﻻ ﻳﺠﻮﺯ", "v01:p001") is None
    assert gate.check_quote(LA_TEXT, "12", "v01:p001") == "empty Arabic quotation"


@pytest.mark.parametrize("tail", ["الا عند الضرورة", "- لكن قال الموفق", "«إلا عند الضرورة»", "— إلا عند الضرورة",
                                  "غير ان الموفق قال", "اذا لم يضطر"])
def test_a_qualifier_is_found_across_hamza_dashes_and_quotation_marks(tail):
    """Audit PR-35: al-Iqnāʿ v04:p060 stops before «- لكن قال الموفق …»; hamza-less «الا» was missed too."""
    assert "qualifier" in gate.check_quote(f"# هذا الحكم ثابت {tail}\nPageV01P001\n", "هذا الحكم ثابت", "v01:p001")


def test_a_word_that_merely_starts_like_a_qualifier_is_not_one():
    assert gate.check_quote("# هذا الحكم ثابت الاستثناء نادر\nPageV01P001\n", "هذا الحكم ثابت", "v01:p001") is None


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


@pytest.mark.parametrize("mutation", ["missing", "stale"])
def test_bad_position_receipt_cannot_be_hidden_by_verified_source(fixture, mutation):
    corpus, cache = fixture
    path = corpus / "reconciliation/ledger.json"
    ledger = json.loads(path.read_text())
    if mutation == "missing":
        del ledger["entries"][0][position_receipts.FIELD]
    else:
        ledger["entries"][0][position_receipts.FIELD] = "0" * 64
    path.write_text(json.dumps(ledger))
    report = gate.verify(corpus, cache)
    assert report["status"] == "failed"
    assert any("positions receipt" in error for error in report["errors"])


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
    (fragments / "new.json").write_text(json.dumps({"entries": [{"far": "shard-case",
        position_receipts.FIELD: position_receipts.digest(receipt_case("shard-case")), "evidence": [
        {"ref": "src:shard-source/v01:p002", "excerpt_ar": QUOTE}]}]}))
    assert gate.required_witnesses(corpus) == {"test-source", "shard-source"}
    report = gate.verify(corpus, cache)
    assert report["status"] == "failed" and report["counts"] == {"failed": 1, "verified": 1}
    (cache / "shard-source.txt").write_text(TEXT)
    assert gate.verify(corpus, cache)["counts"] == {"verified": 2}


def _foundation(corpus, wid="test-source"):
    (corpus / "nusus").mkdir(exist_ok=True)
    (corpus / "nusus/foundation.json").write_text(json.dumps({"ayat": [{"witness": wid}], "ahadith": [
        {"sources": [{"witness": wid}], "albani": {"witness": wid}}], "athar": [{"witness": wid}]}))


def test_foundation_witnesses_are_required(fixture):
    """The foundation's āyāt, ḥadīth collections and al-Albānī works are provisioned fail-closed too."""
    corpus, cache = fixture
    _foundation(corpus, "foundation-source")
    assert "foundation-source" in gate.required_witnesses(corpus)
    report = gate.verify(corpus, cache)
    assert report["status"] == "failed"
    assert any(e.startswith("foundation-source:") for e in report["errors"])
