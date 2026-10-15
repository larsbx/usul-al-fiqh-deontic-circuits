"""Regression: several annotations on one encoder, and on one unit.

A classical farʿ is annotated exactly once, but an encoder carries many furūʿ. A fatwā answer
carries several cases, often on the same encoder and at times with the same facts (37 of the
first tranche's 53 answers repeat an encoder). Every consumer counts, guards and exports each
case once: none dedups by unit, encoder or facts, and none lets one case shadow another.
"""

import json
import re
import shutil
from collections import Counter
from pathlib import Path

import pytest

from usul_corpus import fatawa_prolog, fatawa_takhrij, takhrij
from usul_corpus import typed_routing as tr

ROOT = Path(__file__).resolve().parents[2]
CORPUS = ROOT / "corpus"
LEAN = ROOT / "formal/lean/UsulTest"
ENC = "asl_zahir"
LANES = {"furu": (takhrij.load(CORPUS), LEAN / "Takhrij.lean", CORPUS / "takhrij/report.json"),
         "fatawa": (fatawa_takhrij.load(CORPUS), LEAN / "FatawaTakhrij.lean", CORPUS / "fatawa/takhrij/report.json")}


def _facts(i: int = 0) -> dict:
    """The i-th input of ENC's domain, in its declared order."""
    from itertools import product
    dom = takhrij.ENCODERS[ENC]["facts"]
    return dict(zip(dom, list(product(*dom.values()))[i]))


def _case(far: str, facts: dict, cls: str = "derivable", **kw) -> dict:
    return {"far": far, "encoder": ENC, "class": cls, "facts": facts,
            "expected": takhrij.ENCODERS[ENC]["py"](facts), **kw}


# One answer, three cases on one encoder: two with the same facts, one a gap.
SAME = [_case("islamqa.1.f000", _facts()), _case("islamqa.1.f001", _facts()),
        _case("islamqa.1.f002", _facts(1), "missing_rule", needs=["rule:x"])]


def _guarded(cases: list[dict]) -> list[str]:
    return [c["far"] for c in cases if c["class"] in takhrij.GUARDED]


def _guards(lean: str) -> list[str]:
    """The case each #guard checks, from the comment line the generator writes above it."""
    lines = lean.splitlines()
    return [re.match(r"-- (\S+) \(", lines[i - 1]).group(1) for i, l in enumerate(lines) if l.startswith("#guard")]


# --- kernel checks and guards -------------------------------------------------------------

def test_cases_on_one_encoder_are_checked_independently():
    """Same unit, same encoder, same facts or a different class: each case stands on its own."""
    assert [takhrij.check_case(c) for c in SAME] == [[], [], []]


def test_each_annotation_gets_its_own_guard():
    assert _guards(takhrij.lean_file(SAME)) == ["islamqa.1.f000", "islamqa.1.f001"]


@pytest.mark.parametrize("lane", LANES)
def test_committed_guards_are_one_per_guarded_case(lane):
    cases, lean, _ = LANES[lane]
    assert Counter(_guards(lean.read_text(encoding="utf-8"))) == Counter(_guarded(cases))


# --- identity ----------------------------------------------------------------------------

def test_a_unit_carries_several_cases_but_a_case_id_only_one():
    answers = {"islamqa.1": {"answer": "نص"}}
    with_quote = [{**c, "quote": "نص"} for c in SAME]
    assert fatawa_takhrij.check(with_quote, answers) == {}
    assert fatawa_takhrij.check(with_quote + with_quote[:1], answers) == {"islamqa.1.f000": ["duplicate case"]}


@pytest.mark.parametrize("lane", LANES)
def test_committed_case_ids_are_unique(lane):
    cases, _, _ = LANES[lane]
    assert [f for f, n in Counter(c["far"] for c in cases).items() if n > 1] == []


def test_the_lanes_share_no_case_id():
    assert not {c["far"] for c in LANES["furu"][0]} & {c["far"] for c in LANES["fatawa"][0]}


# --- reports ----------------------------------------------------------------------------

def test_the_report_counts_every_annotation_on_an_encoder():
    rep = takhrij.report(SAME)
    assert rep["total"] == 3 and rep["per_encoder"] == {ENC: {"derivable": 2, "missing_rule": 1}}


@pytest.mark.parametrize("lane", LANES)
def test_committed_reports_count_each_case_once_per_encoder(lane):
    cases, _, report = LANES[lane]
    rep = json.loads(report.read_text(encoding="utf-8"))
    assert {e: sum(v.values()) for e, v in rep["per_encoder"].items()} == dict(Counter(c["encoder"] for c in cases))
    assert rep["total"] == len(cases)


def test_the_revisit_queue_lists_each_case_whose_needs_are_met():
    have = sorted(takhrij.provides())[:1]
    twice = [_case(f"islamqa.1.f00{i}", _facts(), "missing_rule", needs=have) for i in range(2)]
    assert takhrij.revisit_queue(twice) == ["islamqa.1.f000", "islamqa.1.f001"]


# --- the fatāwā Prolog export -------------------------------------------------------------

def test_prolog_export_keeps_each_case_of_an_answer():
    facts = {c["far"]: {"far": c["far"], "facts": {}, "ruling": "x"} for c in SAME}
    records = fatawa_prolog.merge(SAME, facts)
    pl = fatawa_prolog.prolog_file(records)
    assert [r["far"] for r in records] == [c["far"] for c in SAME if c["class"] not in fatawa_prolog.SKIP]
    assert Counter(re.findall(r"^encoder\(([^,]+), ", pl, re.M)) == Counter(fatawa_prolog.atom(r["far"]) for r in records)


def test_facts_for_one_case_in_two_files_are_refused(tmp_path):
    d = tmp_path / "fatawa" / "prolog"
    d.mkdir(parents=True)
    for name, ruling in (("a_facts.json", "x"), ("b_facts.json", "y")):
        (d / name).write_text(json.dumps({"cases": [{"far": "islamqa.1.f000", "facts": {}, "ruling": ruling}]}))
    with pytest.raises(ValueError, match="islamqa.1.f000"):
        fatawa_prolog.load_facts(tmp_path)


def test_committed_facts_are_one_per_case():
    facts = fatawa_prolog.load_facts(CORPUS)  # the tranche and the classical held-out cases
    assert fatawa_prolog.check(fatawa_prolog.load_cases(CORPUS, facts), facts) == []


# --- routing ----------------------------------------------------------------------------

@pytest.mark.parametrize("ts", tr.present(ROOT), ids=lambda ts: ts.name)
def test_typed_routing_reports_one_row_per_case(ts):
    """Recall is over cases: an answer with four asl_zahir cases weighs four times, as labelled."""
    rep = json.loads((ROOT / ts.report).read_text(encoding="utf-8"))
    rows = rep["cases_detail"]
    assert Counter((r["case"], r["encoder"]) for r in rows) == Counter((u, e) for u, e, _ in ts.cases(ROOT))
    assert rep["cases"] == len(rows)
    for k, v in rep["recall"].items():
        assert v == round(sum(r["rank"] is not None and r["rank"] <= int(k) for r in rows) / len(rows), 4)


def test_out_of_domain_routing_counts_every_case_of_the_tranche():
    from usul_corpus import routing
    ood = json.loads((CORPUS / routing.OOD).read_text(encoding="utf-8"))
    tranche = json.loads((ROOT / routing.TRANCHE).read_text(encoding="utf-8"))["cases"]
    assert ood["cases"] == len(tranche)


@pytest.mark.skipif(shutil.which("swipl") is None, reason="swipl not installed")
def test_typed_coverage_is_per_unit_and_shared_by_its_cases():
    """Coverage is computed once per unit; every case of that unit reads the same scores."""
    ts = tr.present(ROOT)[0]
    cov = tr.coverage(ROOT, ts)
    rep = json.loads((ROOT / ts.report).read_text(encoding="utf-8"))
    for r in rep["cases_detail"]:
        k, n = cov.get(r["case"], {}).get(r["encoder"], (0, 1))
        assert r["settled"] == round(k / n, 4)


# --- invariant 5 under scrutiny: home annotations exactly once, co-annotations beside them ---
#
# A farʿ keeps exactly one home annotation (method §4, invariant 5). A co-annotation records that
# a second encoder derives the same stated ruling, on the farʿ's own words (``basis``). It lives
# apart (``corpus/takhrij/co``), so every far-keyed consumer still sees one case per farʿ.

FAR = "w.r.openiti_w.q001.f000"
TEXT = "إذا أقر الشهود أنهم تعمدوا الكذب فالضمان عليهم دون الحاكم"
RECORDS = [{"id": FAR, "record_type": "far", "qaida": "w.r.openiti_w.q001", "case_ar": TEXT}]
OTHER = "luqata"


def _co(**kw) -> dict:
    facts = dict(zip(takhrij.ENCODERS[OTHER]["facts"], (v[0] for v in takhrij.ENCODERS[OTHER]["facts"].values())))
    return {"far": FAR, "encoder": OTHER, "class": "derivable", "facts": facts,
            "expected": takhrij.ENCODERS[OTHER]["py"](facts), "basis": "أقر الشهود أنهم تعمدوا الكذب", **kw}


HOME = [_case(FAR, _facts())]


def test_a_well_founded_co_annotation_passes():
    assert takhrij.co_errors([_co()], HOME, RECORDS) == []
    milestoned = [{**RECORDS[0], "case_ar": TEXT.replace("أنهم ", "أنهم ms283 ")}]
    assert takhrij.co_errors([_co()], HOME, milestoned) == []


@pytest.mark.parametrize("co, home, err", [
    (_co(), [], "no home annotation"),
    (_co(encoder=ENC, facts=_facts(), expected=takhrij.ENCODERS[ENC]["py"](_facts())), HOME, "repeats its home encoder"),
    (_co(basis="نص ليس في الفرع"), HOME, "basis is not the farʿ's own words"),
    (_co(basis=None), HOME, "basis is not the farʿ's own words"),
    (_co(**{"class": "missing_rule"}, needs=["rule:x"]), HOME, "a co-annotation records a derivation"),
    (_co(), [_case(FAR, _facts(), "missing_rule", needs=["rule:x"])], "its home is a gap"),
])
def test_an_unfounded_co_annotation_is_refused(co, home, err):
    assert any(err in e for e in takhrij.co_errors([co], home, RECORDS)), takhrij.co_errors([co], home, RECORDS)


def test_a_co_annotation_is_once_per_encoder_and_checked_by_the_kernel():
    assert any("annotated twice" in e for e in takhrij.co_errors([_co(), _co()], HOME, RECORDS))
    wrong = _co(expected=next(o for o in takhrij.ENCODERS[OTHER]["out"] if o != _co()["expected"]))
    assert any("class contradicts the kernel" in e for e in takhrij.co_errors([wrong], HOME, RECORDS))


def test_co_annotations_never_enter_the_home_bank(tmp_path):
    """Invariant 5 is counted on home annotations: loading the bank does not read co/."""
    (tmp_path / "takhrij" / "co").mkdir(parents=True)
    suite = lambda cs: json.dumps({"suite": "s", "status": "candidate", "provenance": "p", "cases": cs})
    (tmp_path / "takhrij" / "a.json").write_text(suite(HOME))
    (tmp_path / "takhrij" / "co" / "b.json").write_text(suite([_co()]))
    assert [c["far"] for c in takhrij.load(tmp_path)] == [FAR]
    assert [c["encoder"] for c in takhrij.load_co(tmp_path)] == [OTHER]
    assert takhrij.annotation_errors(takhrij.load(tmp_path) * 2, RECORDS)[0] == f"{FAR}: annotated twice"


def test_co_annotations_are_guarded_apart_and_leave_coverage_alone():
    lean = takhrij.lean_file(takhrij.keyed(co := [_co()]), source=str(takhrij.CO))
    assert _guards(lean) == [f"{FAR}@{OTHER}"]
    plain, with_co = takhrij.report(HOME), takhrij.report(HOME, co)
    assert {k: v for k, v in with_co.items() if k != "co_annotations"} == plain
    assert with_co["co_annotations"] == {"total": 1, "per_encoder": {OTHER: 1}}


def test_committed_co_annotations_are_founded_and_generated():
    co, cases = takhrij.load_co(CORPUS), takhrij.load(CORPUS)
    records = [json.loads(line) for f in (CORPUS / "records").glob("*.jsonl") for line in f.read_text().splitlines()]
    assert takhrij.co_errors(co, cases, records) == []
    assert (LEAN / "TakhrijCo.lean").read_text() == takhrij.lean_file(takhrij.keyed(co), source=str(takhrij.CO))
    assert json.loads((CORPUS / "takhrij/report.json").read_text())["co_annotations"]["total"] == len(co)
