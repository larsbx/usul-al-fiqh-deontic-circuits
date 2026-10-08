"""Opening recovery is additive, source-backed, replayable and still review-gated."""

import argparse
import copy
import hashlib
import json
from pathlib import Path

import jsonschema
import pytest

from usul_corpus import __main__ as cli, opening, takhrij
from usul_corpus.openiti import Section, parse_markdown
from usul_corpus.records import qaida_records
from usul_corpus.segment import segment_headed, source_excerpt

ROOT = Path(__file__).parents[2]
WITNESS = "openiti-rajab-shamela21730"
WORK = "ibn_rajab.taqrir_qawaid"
RECORDS = ROOT / f"corpus/records/{WITNESS}.jsonl"
RECEIPT = ROOT / f"corpus/segmentation/{WITNESS}-opening.json"
FIXTURE = json.loads((Path(__file__).parent / "fixtures/rajab_opening.json").read_text())


def _records():
    return [json.loads(line) for line in RECORDS.read_text().splitlines()]


def _receipt():
    return json.loads(RECEIPT.read_text())


def _lock():
    return json.loads((ROOT / "corpus/lock.json").read_text())["witnesses"][WITNESS]


def _unit(text, number=6, enabled=True):
    section = Section(1, f"القاعدة {number}", text, (1, 8), (1, 8))
    return segment_headed((section,), "القاعدة", enabled)[0]


@pytest.mark.parametrize("fixture", FIXTURE["units"], ids=lambda f: f"q{f['number']:03d}")
def test_pinned_short_source_fixtures_recover_opening_and_inline_forms(fixture):
    body = "\n".join(f["text"] for f in fixture["fragments"])
    unit = _unit(body, fixture["number"])
    snippets = [source_excerpt(unit.body[e.start:e.end]) for e in unit.opening]
    assert len(snippets) == len(fixture["opening_prefixes"])
    assert all(text.startswith(prefix) for text, prefix in zip(snippets, fixture["opening_prefixes"]))
    assert all(0 <= e.start < e.end <= len(unit.body) for e in unit.opening)


def test_opening_after_400_characters_is_recovered_without_normalizing_source():
    prose = "هذا شرح للمبدأ العام. " * 30
    text = prose + "وله صُوَرٌ: مِنهَا إِذَا أحجّ المعضوب ثم برئ.\n(ومنها) مثال تال."
    u = _unit(text)
    assert len(u.statement) == 400 and u.opening[0].start > 400
    q, f0, f1 = qaida_records({"id": WORK, "rights": "public_domain_text"}, WITNESS, "headed", "q006", u)
    assert f0["case_ar"] == "إِذَا أحجّ المعضوب ثم برئ."
    assert f1["id"].endswith(".f001") and f1["case_ar"] == "مثال تال."
    assert q["furu_count"] == 2


@pytest.mark.parametrize("text,number", [
    ("من قدر على بعض العبادة وعجز عن باقيها هل يلزمه الإتيان بما قدر عليه منها أم لا؟", 8),
    ("يمكن فهم مسائل العلم وأخذ منها معنى عاما.", 6),
    ("هذا شرح مثل أن نفهم الشرط على وجه آخر.", 66),
    ("له قولان: (إحداهما) الصحة. (والثانية) البطلان.", 14),
    ("الاستناد له نوعان: وهذا مثل سابق وليس مثالا مصرحا به.", 66),
    ("له صور: منها", 6),
    ("له صور: منها   ", 6),
    ("له صور: (إحداها)", 14),
    ("هذا تفسير.\n(ومنها) إذا كفر بالإطعام.\nوله صور: منها شرح داخل حالة سبق عدها.", 6),
])
def test_explanatory_prose_empty_markers_and_existing_paragraphs_are_not_new_furu(text, number):
    assert _unit(text, number).opening == ()


def test_legacy_ids_excerpts_and_extraction_are_byte_stable():
    text = "ولذلك صور: منها إذا أحج المعضوب.\n(ومنها) إذا كفر بالإطعام.\n(ومنها) إذا عاد الحيض."
    work = {"id": WORK, "rights": "public_domain_text"}
    old = qaida_records(work, WITNESS, "headed", "q006", _unit(text, enabled=False))
    new = qaida_records(work, WITNESS, "headed", "q006", _unit(text))
    assert old[1:] == new[2:]
    assert {k: v for k, v in old[0].items() if k != "furu_count"} == {
        k: v for k, v in new[0].items() if k != "furu_count"}


def test_multiple_inline_examples_reserve_zero_without_using_positive_ids():
    text = "له صور: (منها) صوم يوم العيد. (ومنها) الصلاة في أوقات النهي.\nومنها مثال آخر."
    work = {"id": WORK, "rights": "public_domain_text"}
    q, f0, f02, f1 = qaida_records(work, WITNESS, "headed", "q009", _unit(text, 9))
    assert [f["id"].rsplit(".", 1)[1] for f in (f0, f02, f1)] == ["f000", "f000_2", "f001"]
    assert f0["case_ar"] == "صوم يوم العيد." and f02["case_ar"] == "الصلاة في أوقات النهي."
    assert q["furu_count"] == 3


def test_receipts_cover_every_recovered_candidate_and_pin_every_legacy_record():
    records, saved = _records(), _receipt()
    opening.validate_receipt(saved, records, _lock())
    assert saved["source"]["sha256"] == FIXTURE["source_sha256"]
    assert saved["legacy"]["far_records"] == 1056
    assert saved["summary"]["revised_far"] == sum(r["record_type"] == "far" for r in records)
    schema = json.loads((ROOT / "schemas/usul_rule.schema.json").read_text())
    for r in saved["records"]:
        jsonschema.validate(r, schema)
        assert r["status"] == "candidate" and len(r["case_ar"]) <= 400
        span = r["extraction"]["source_span"]
        assert 0 <= span["start"] < span["end"]
        assert not {"facts", "expected", "positions", "encoder"} & r.keys()
    for q in (r for r in records if r["record_type"] == "qaida"):
        assert q["furu_count"] == sum(r.get("qaida") == q["id"] for r in records)


@pytest.mark.parametrize("mutation", ["legacy", "legacy_far_count", "receipt_record", "source", "promotion", "count"])
def test_offline_receipt_gate_rejects_mutations(mutation):
    saved, records, lock = _receipt(), _records(), _lock()
    if mutation == "legacy":
        next(r for r in records if r["id"].endswith(".f001"))["case_ar"] += "x"
    elif mutation == "legacy_far_count":
        next(r for r in records if r["id"].endswith(".f001"))["furu_count"] = 1
    elif mutation == "receipt_record":
        saved["records"][0]["extraction"]["source_span"]["start"] += 1
    elif mutation == "source":
        saved["source"]["sha256"] = "0" * 64
    elif mutation == "promotion":
        next(r for r in records if opening.is_recovered(r))["status"] = "accepted"
    else:
        saved["summary"]["recovered"] += 1
    with pytest.raises(ValueError):
        opening.validate_receipt(saved, records, lock)


def test_annotation_coverage_allows_only_receipted_recovery_gaps():
    records = _records()
    cases = [c for c in takhrij.load(ROOT / "corpus") if c["far"].startswith(WORK)]
    recovered = {r["id"] for r in _receipt()["records"]}
    assert takhrij.check_annotation_coverage(cases, records, recovered) == []
    removed = next(c for c in cases if c["far"].endswith("q006.f001"))
    assert any(removed["far"] in e for e in takhrij.check_annotation_coverage(
        [c for c in cases if c is not removed], records, recovered))
    assert takhrij.check_annotation_coverage(cases + [cases[0]], records, recovered)
    unreceipted = copy.deepcopy(next(r for r in records if r["id"].endswith("q006.f001")))
    unreceipted["id"] = unreceipted["id"].replace("f001", "f999")
    assert any(unreceipted["id"] in e for e in takhrij.check_annotation_coverage(
        cases, records + [unreceipted], recovered))


def test_revised_m8_denominator_includes_all_three_unannotated_openings():
    records = [json.loads(line) for p in (ROOT / "corpus/records").glob("*.jsonl")
               for line in p.read_text().splitlines()]
    coverage = takhrij.corpus_coverage(takhrij.load(ROOT / "corpus"), records)["m8_tranche_1"]
    assert coverage["segmented_far"] == coverage["denominator"] == 26
    assert coverage["annotated"] == 23 and coverage["unannotated"] == 3
    assert coverage["coverage"] == round(20 / 26, 3)
    assert coverage["madhhab_coverage"] == round(14 / 26, 3)
    assert not coverage["annotation_complete"]


def test_full_pinned_source_receipt_and_short_fixture_replay():
    source = ROOT / f".cache/corpus/{WITNESS}.txt"
    if not source.exists():
        pytest.skip("pinned witness not cached; make opening-replay requires it and CI fetches it")
    assert hashlib.sha256(source.read_bytes()).hexdigest() == FIXTURE["source_sha256"]
    units = {u.number: u for u in segment_headed(parse_markdown(source.read_text()), "القاعدة", True)}
    records = {r["id"]: r for r in _records()}
    for fixture in FIXTURE["units"]:
        body = units[fixture["number"]].body
        assert hashlib.sha256(body.encode()).hexdigest() == fixture["body_sha256"]
        for fragment in fixture["fragments"]:
            literal = body[fragment["start"]:fragment["end"]]
            assert literal == fragment["text"] and len(literal) <= 400
            assert hashlib.sha256(literal.encode()).hexdigest() == fragment["sha256"]
    for r in _receipt()["records"]:
        number = int(r["qaida"].rsplit("q", 1)[1])
        body = units[number].body
        span = r["extraction"]["source_span"]
        literal = body[span["start"]:span["end"]]
        assert hashlib.sha256(body.encode()).hexdigest() == span["body_sha256"]
        assert hashlib.sha256(literal.encode()).hexdigest() == span["sha256"]
        assert source_excerpt(literal)[:400] == records[r["id"]]["case_ar"]
    assert cli.cmd_opening_replay(argparse.Namespace(work=WORK)) == 0


def test_changed_source_fails_before_artifacts_are_written(tmp_path, monkeypatch):
    monkeypatch.setattr(cli, "CACHE", tmp_path)
    (tmp_path / f"{WITNESS}.txt").write_text("source changed")
    before = RECORDS.read_bytes(), RECEIPT.read_bytes(), (ROOT / "corpus/audit.json").read_bytes()
    assert cli.cmd_build(argparse.Namespace(work=WORK)) == 1
    assert before == (RECORDS.read_bytes(), RECEIPT.read_bytes(), (ROOT / "corpus/audit.json").read_bytes())
    assert cli.cmd_opening_replay(argparse.Namespace(work=WORK)) == 1


def test_missing_targeted_source_fails_without_clearing_unrelated_audit(tmp_path, monkeypatch):
    monkeypatch.setattr(cli, "CACHE", tmp_path)
    before = (ROOT / "corpus/audit.json").read_bytes()
    assert cli.cmd_build(argparse.Namespace(work=WORK)) == 1
    assert before == (ROOT / "corpus/audit.json").read_bytes()
