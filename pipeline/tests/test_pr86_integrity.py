"""Adversarial review regressions: source occurrences, required evidence, and disagreements."""
import hashlib
import json

import pytest

from usul_corpus import units, reconcile, qawaid_adilla, source_verify

WORK = {"id": "a.b", "rights": "public_domain_text"}


def records(body):
    return units.paragraph_records(WORK, "test-w", "#META#Header#End#\n" + body, {})


def test_identical_words_are_distinct_obligations_even_in_one_bab():
    rows, audit = records("### | باب الأول\n# وهي نوعان\n# وهي نوعان\nPageV01P001\n"
                          "### | باب الثاني\n# وهي نوعان\nPageV01P002\n")
    assert len(rows) == 3
    assert len({r["id"] for r in rows}) == 3
    assert [r["bab"].split(".")[-1] for r in rows] == ["b00001", "b00001", "b00002"]
    assert audit["duplicates"] == []


def test_body_title_assigns_both_sale_occurrences_to_the_matching_bab():
    rows, audit = records("### | باب البيع\n# حكم سابق\n# باب بيع الأصول والثمار\n"
                          "# يدخل البناء في البيع\nPageV01P109\n"
                          "### | باب بيع الأصول والثمار\n# يدخل البناء في البيع\nPageV01P109\n")
    sales = [r for r in rows if r["excerpt_ar"] == "يدخل البناء في البيع"]
    assert len(sales) == 2
    assert all(r["heading_ar"] == "باب بيع الأصول والثمار" for r in sales)
    assert [r["id"].split(".")[-1] for r in sales] == ["p01", "p02"]
    assert len(audit["reattributions"]) == 1


@pytest.mark.parametrize("cls", ["derivable", "genuine_ikhtilaf", "segmentation_error", "encoding_error"])
def test_only_unresolved_rule_or_fact_gaps_need_between_work_reconciliation(cls):
    c = {"far": "f", "class": cls, "aligned": [{"far": "g", "relation": "same"}],
         "positions": [{"ruling": "allowed"}, {"ruling": "forbidden"}]}
    assert reconcile.disagreements([c]) == []


@pytest.mark.parametrize("cls", ["missing_rule", "missing_fact"])
def test_distinct_rulings_not_position_count_make_a_disagreement(cls):
    c = {"far": "f", "class": cls, "aligned": [{"far": "g", "relation": "same"}],
         "positions": [{"ruling": "allowed"}, {"ruling": "allowed"}]}
    assert reconcile.disagreements([c]) == []
    c["positions"][1]["ruling"] = "forbidden"
    assert reconcile.disagreements([c]) == [c]
    c["positions"] = [{"ruling": True}, {"ruling": 1}]
    assert reconcile.disagreements([c]) == [c]  # use the typed ruling identity from main


@pytest.mark.parametrize("source,quote", [(None, "قول صحيح"), ("قول صحيح", "..."), ("قول صحيح", "قول مختلق")])
def test_istidlal_missing_empty_or_forged_fails(source, quote):
    es = [{"qaida": "q", "adilla": [{"ref": "Q1", "relation": "stated", "istidlal": {
        "witness": "test-source", "ref": "src:test-source/v01:p001", "excerpt_ar": quote}}]}]
    assert qawaid_adilla.errors(es, {"q": {"record_type": "qaida"}}, {"Q1"}, lambda _: source)


@pytest.mark.parametrize("mutation", ["valid", "missing", "corrupt", "forged", "page", "witness_mismatch"])
def test_dossier_only_witness_is_required_and_replayed(tmp_path, mutation):
    corpus, cache = tmp_path / "corpus", tmp_path / "cache"
    (corpus / "dossier").mkdir(parents=True)
    cache.mkdir()
    text = "# قول صحيح\nPageV01P001\n"
    w = {"id": "test-source", "kind": "openiti", "repo": "test", "commit": "a" * 40, "path": "source"}
    lock = {"url": source_verify.fetch.witness_url(w), "bytes": len(text.encode()),
            "sha256": hashlib.sha256(text.encode()).hexdigest()}
    ist = {"witness": w["id"], "ref": "src:test-source/v01:p001", "excerpt_ar": "قول صحيح"}
    if mutation == "forged": ist["excerpt_ar"] = "قول مختلق"
    if mutation == "page": ist["ref"] = "src:test-source/v01:p002"
    if mutation == "witness_mismatch": ist["witness"] = "other-source"
    for name, obj in [("registry.json", {"works": [{"witnesses": [w]}]}),
                      ("lock.json", {"witnesses": {w["id"]: lock}}),
                      ("dossier/qawaid_adilla.json", {"entries": [{"adilla": [{"istidlal": ist}]}]})]:
        (corpus / name).write_text(json.dumps(obj))
    if mutation != "missing": (cache / "test-source.txt").write_text(text + (" " if mutation == "corrupt" else ""))
    result = source_verify.verify(corpus, cache)
    assert result["status"] == ("verified_required_subset" if mutation == "valid" else "failed")
    if mutation == "valid": assert result["counts"] == {"verified": 1}


@pytest.mark.parametrize("mutation", ["valid", "missing", "corrupt", "pointer", "missing_pin", "wrong_url"])
def test_pdf_istidlal_requires_the_existing_ocr_hash_without_repinning(tmp_path, mutation):
    text = "# قول صحيح\nPageV01P001\n"
    w = {"id": "ocr-source", "kind": "url", "url": "https://example.org/source.pdf", "format": "pdf"}
    lock = {"url": w["url"], "sha256": "a" * 64, "bytes": 42,
            "ocr_sha256": hashlib.sha256(text.encode()).hexdigest()}
    p = tmp_path / "ocr-source.txt"
    if mutation != "missing": p.write_text(text)
    if mutation == "corrupt": p.write_text(text + " ")
    if mutation == "pointer": p.write_text("version https://git-lfs.github.com/spec/v1\noid sha256:" + lock["ocr_sha256"])
    if mutation == "missing_pin": del lock["ocr_sha256"]
    if mutation == "wrong_url": lock["url"] += "/changed"
    before = dict(lock)
    if mutation == "valid":
        assert source_verify.locked_text(w["id"], w, lock, tmp_path, tmp_path, True) == text
    else:
        with pytest.raises(ValueError):
            source_verify.locked_text(w["id"], w, lock, tmp_path, tmp_path, True)
    assert lock == before


def test_missing_dossier_witness_cannot_hide_behind_valid_ledger_evidence(tmp_path):
    corpus, cache = tmp_path / "corpus", tmp_path / "cache"
    (corpus / "reconciliation").mkdir(parents=True)
    (corpus / "dossier").mkdir()
    cache.mkdir()
    text = "# قول صحيح\nPageV01P001\n"
    w = {"id": "ledger-source", "kind": "url", "url": "https://example.org/text"}
    lock = {"url": w["url"], "bytes": len(text.encode()), "sha256": hashlib.sha256(text.encode()).hexdigest()}
    quote = {"ref": "src:ledger-source/v01:p001", "excerpt_ar": "قول صحيح"}
    for name, obj in [("registry.json", {"works": [{"witnesses": [w]}]}),
                      ("lock.json", {"witnesses": {w["id"]: lock}}),
                      ("reconciliation/ledger.json", {"entries": [{"far": "f", "evidence": [quote]}]}),
                      ("dossier/qawaid_adilla.json", {"entries": [{"adilla": [{"istidlal": {
                          **quote, "ref": "src:dossier-source/v01:p001", "witness": "dossier-source"}}]}]})]:
        (corpus / name).write_text(json.dumps(obj))
    (cache / "ledger-source.txt").write_text(text)
    result = source_verify.verify(corpus, cache)
    assert result["status"] == "failed"
    assert result["counts"] == {"failed": 1, "verified": 1}


def test_no_fallback_from_missing_proofs_to_attribution_or_foundation_refs():
    case = {"class": "missing_rule", "positions": [{"ruling": "a"}, {"ruling": "b"}]}
    entry = {"grades": ["tashih", "wajh"], "adilla": [{"position": 0, "ref": "Q005:006"}]}
    assert reconcile.attribution(case, entry) == ("tarjih", "a")
    assert reconcile.resolve(case, entry) == ("unweighed", None)
    assert reconcile.attribution_standing(case, entry) == "no_reading"


def test_agreement_does_not_require_a_ledger_entry_but_disagreement_does():
    case = {"far": "f", "class": "missing_rule", "aligned": [{"far": "g", "relation": "same"}],
            "positions": [{"ruling": "a"}, {"ruling": "a"}]}
    assert reconcile.check([case], {"entries": []}, {"entries": []}) == []
    case["positions"][1]["ruling"] = "b"
    assert any("disagreement between works" in e for e in reconcile.check([case], {"entries": []}, {"entries": []}))
