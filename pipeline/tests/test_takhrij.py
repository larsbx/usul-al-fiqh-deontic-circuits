"""M4 takhrīj suite: the classification logic, and the annotated cases against the corpus."""

import json
from pathlib import Path

import jsonschema

from usul_corpus import takhrij

ROOT = Path(__file__).parents[2]


def _case(cls, facts, expected, **kw):
    return {"far": "x.q001.f001", "encoder": "lots", "class": cls, "facts": facts, "expected": expected, "note": "n", **kw}


def test_check_case_accepts_agreement_and_recorded_disagreement():
    unknown = {"entitled_known": False, "divisible": False, "confusion_category": False}
    assert takhrij.check_case(_case("derivable", unknown, "lot")) == []
    assert takhrij.check_case(_case("encoding_error", unknown, "divide")) == []


def test_check_case_rejects_a_class_the_kernel_contradicts():
    unknown = {"entitled_known": False, "divisible": False, "confusion_category": False}
    assert takhrij.check_case(_case("derivable", unknown, "divide")) == ["class contradicts the kernel's output"]
    assert takhrij.check_case(_case("encoding_error", unknown, "lot")) == ["class contradicts the kernel's output"]


def test_check_case_rejects_bad_facts_domains_and_thin_ikhtilaf():
    assert takhrij.check_case(_case("derivable", {"entitled_known": True}, "toEntitled")) == ["facts do not match the encoder"]
    assert takhrij.check_case(_case("derivable", {"entitled_known": True, "divisible": True, "confusion_category": False}, "x")) == ["expected outside the encoder's output domain"]
    one = [{"who": "madhhab", "ruling": "lot"}]
    facts = {"entitled_known": False, "divisible": False, "confusion_category": False}
    assert takhrij.check_case(_case("genuine_ikhtilaf", facts, "lot", positions=one, matches_madhhab=True)) == ["ikhtilāf needs at least two positions"]
    assert takhrij.check_case(_case("missing_fact", None, None)) == []


def test_report_coverage_excludes_segmentation_errors():
    cases = [_case("derivable", {}, None), _case("missing_fact", None, None), _case("segmentation_error", None, None)]
    rep = takhrij.report(cases)
    assert rep["coverage"] == 0.5 and rep["total"] == 3


def test_annotated_cases_cover_their_qawaid_exactly_once_and_stay_generated():
    files = sorted(f for f in (ROOT / "corpus/takhrij").glob("*.json") if f.name != "report.json")
    if not files:
        import pytest
        pytest.skip("no annotated cases yet")
    schema = json.loads((ROOT / "schemas/takhrij_cases.schema.json").read_text())
    for f in files:
        jsonschema.validate(json.loads(f.read_text()), schema)
    cases = takhrij.load(ROOT / "corpus")
    assert cases and all(takhrij.check_case(c) == [] for c in cases)
    records = [json.loads(line) for f in (ROOT / "corpus/records").glob("*.jsonl") for line in f.read_text().splitlines()]
    assert takhrij.annotation_errors(cases, records) == []
    tests = ROOT / "formal/lean/UsulTest"
    assert (tests / "Takhrij.lean").read_text() == takhrij.lean_file(cases)
    assert (tests / "TakhrijMirror.lean").read_text() == takhrij.mirror_file()
    assert json.loads((ROOT / "corpus/takhrij/report.json").read_text()) == takhrij.report(cases, takhrij.load_co(ROOT / "corpus"))
    for f in sorted((ROOT / "corpus/takhrij/co").glob("*.json")):
        jsonschema.validate(json.loads(f.read_text()), schema)


def test_case_findings_point_at_register_questions_on_their_rule():
    """An encoding error tagged with a register question must be about the encoder's own rule."""
    reg = {q["id"]: q for q in json.loads((ROOT / "corpus/review/sadi_interpretive_questions.json").read_text())["questions"]}
    for c in takhrij.load(ROOT / "corpus"):
        if "iq" in c:
            assert c["iq"] in reg and set(reg[c["iq"]]["rules"]) & set(takhrij.ENCODERS[c["encoder"]]["sadi"]), c["far"]


def test_bank_is_applied_to_itself():
    """No gap may stay open once the bank provides everything it needs: each extension of the
    bank is run back over the earlier gaps (revisited cases keep their history)."""
    cases = takhrij.load(ROOT / "corpus")
    assert takhrij.revisit_queue(cases) == []
    for c in cases:
        if "revisit" in c:
            assert set(c["revisit"]["closed_by"]) <= takhrij.provides(), c["far"]


RECORDS = [{"id": "w.x.q001.f001", "record_type": "far", "qaida": "w.x.q001"},
           {"id": "w.x.q001.f002", "record_type": "far", "qaida": "w.x.q001"},
           {"id": "w.y.qa00001", "record_type": "fatwa"}, {"id": "w.z.b00001", "record_type": "bab"}]


def _annotation(i, encoder="itlaf"):
    return {"far": i, "encoder": encoder}


def test_a_unit_record_is_annotated_once_with_no_qaida_to_own():
    """Fatwā, masʾala and bāb units are claimable obligations (units.json): an annotation of one is
    valid once, and the qāʿida checks of furūʿ do not apply to it (routing assigns its encoder)."""
    assert takhrij.annotation_errors([_annotation("w.y.qa00001"), _annotation("w.z.b00001", "tabaa")], RECORDS) == []
    assert takhrij.annotation_errors([_annotation("w.y.qa00001")] * 2, RECORDS) == ["w.y.qa00001: annotated twice"]
    assert takhrij.annotation_errors([_annotation("w.y.qa00009")], RECORDS) == ["w.y.qa00009: not a committed farʿ or unit record"]


def test_furu_keep_their_qaida_ownership_and_completeness(monkeypatch):
    monkeypatch.setitem(takhrij.ENCODERS, "t", {"qawaid": ["w.x.q001"]})
    assert takhrij.annotation_errors([_annotation("w.x.q001.f001", "itlaf")], RECORDS)[0] == "w.x.q001.f001: its qāʿida is not its home encoder's"
    assert takhrij.annotation_errors([_annotation("w.x.q001.f001", "t")], RECORDS) == ["w.x.q001.f002: unannotated farʿ of an annotated encoder's qāʿida"]


def test_the_case_schema_admits_unit_ids():
    pattern = json.loads((ROOT / "schemas/takhrij_cases.schema.json").read_text())["properties"]["cases"]["items"]["properties"]["far"]["pattern"]
    import re
    assert all(re.search(pattern, i) for i in ("a.b.q001.f001", "a.b.qa00001", "a.b.m00001", "a.b.b00001"))
    assert not re.search(pattern, "a.b.q001")
