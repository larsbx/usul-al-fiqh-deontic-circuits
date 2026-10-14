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
    cases = fatawa_takhrij.load(CORPUS)
    assert fatawa_prolog.check(cases, fatawa_prolog.load_facts(CORPUS)) == []


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
