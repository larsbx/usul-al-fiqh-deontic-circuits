"""M4 takhrīj suite: the classification logic, and the annotated cases against the corpus."""

import json
from pathlib import Path

import jsonschema

from usul_corpus import takhrij

ROOT = Path(__file__).parents[2]


def _case(cls, facts, expected, **kw):
    return {"far": "x.q001.f001", "encoder": "lots", "class": cls, "facts": facts, "expected": expected, "note": "n", **kw}


def test_check_case_accepts_agreement_and_recorded_disagreement():
    unknown = {"entitled_known": False, "divisible": False}
    assert takhrij.check_case(_case("derivable", unknown, "lot")) == []
    assert takhrij.check_case(_case("encoding_error", unknown, "divide")) == []


def test_check_case_rejects_a_class_the_kernel_contradicts():
    unknown = {"entitled_known": False, "divisible": False}
    assert takhrij.check_case(_case("derivable", unknown, "divide")) == ["class contradicts the kernel's output"]
    assert takhrij.check_case(_case("encoding_error", unknown, "lot")) == ["class contradicts the kernel's output"]


def test_check_case_rejects_bad_facts_domains_and_thin_ikhtilaf():
    assert takhrij.check_case(_case("derivable", {"entitled_known": True}, "toEntitled")) == ["facts do not match the encoder"]
    assert takhrij.check_case(_case("derivable", {"entitled_known": True, "divisible": True}, "x")) == ["expected outside the encoder's output domain"]
    one = [{"who": "madhhab", "ruling": "lot"}]
    facts = {"entitled_known": False, "divisible": False}
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
    far = {}
    for f in (ROOT / "corpus/records").glob("*.jsonl"):
        for line in f.read_text().splitlines():
            r = json.loads(line)
            if r["record_type"] == "far":
                far[r["id"]] = r["qaida"]
    ids = [c["far"] for c in cases]
    assert len(ids) == len(set(ids)) and set(ids) <= set(far)
    home = {c["far"]: c.get("revisit", {}).get("from_encoder", c["encoder"]) for c in cases}
    for c in cases:
        assert far[c["far"]] in takhrij.ENCODERS[home[c["far"]]]["qawaid"], c["far"]
    annotated = set(home.values())
    expected = {i for e in annotated for i, q in far.items() if q in takhrij.ENCODERS[e]["qawaid"]}
    assert set(ids) == expected
    tests = ROOT / "formal/lean/UsulTest"
    assert (tests / "Takhrij.lean").read_text() == takhrij.lean_file(cases)
    assert (tests / "TakhrijMirror.lean").read_text() == takhrij.mirror_file()
    assert json.loads((ROOT / "corpus/takhrij/report.json").read_text()) == takhrij.report(cases)


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
