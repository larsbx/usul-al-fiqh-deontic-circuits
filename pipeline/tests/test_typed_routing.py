"""T3/T4: blind-typed test sets, routed by type (Prolog over the Lean export)."""

import json
import re
from pathlib import Path

import pytest

from usul_corpus import typed_routing as tr

ROOT = Path(__file__).resolve().parents[2]
EXPORT = (ROOT / "examples/v41_types.pl").read_text(encoding="utf-8")
SETS = tr.present(ROOT)
ids = [ts.name for ts in SETS]
TYPED = [*SETS, *tr.present(ROOT, tr.PROPOSALS)]
typed_ids = [ts.name for ts in TYPED]


def allowed(lean_type: str) -> set:
    """The values a field of this Lean type takes: Bool, or the kernel's constructors (type_value/2)."""
    inner, nested = lean_type, 0
    while inner.startswith("Option "):
        inner, nested = inner[len("Option "):].strip("()"), nested + 1
    if inner == "Bool":
        return {True, False}
    ctors = set(re.findall(rf"^type_value\('{re.escape(inner)}', (\w+)\)\.", EXPORT, re.M))
    return ctors | ({"none"} if nested > 1 else set())


def _data(ts):
    return json.loads((ROOT / ts.situations).read_text(encoding="utf-8"))


def test_allowed_values_come_from_the_kernel():
    assert allowed("Option Usul.Grade") == {"wahm", "shakk", "zann", "qat"}
    assert "none" in allowed("Option (Option Usul.Hukm)") and "wajib" in allowed("Option (Option Usul.Hukm)")


@pytest.mark.parametrize("ts", TYPED, ids=typed_ids)
def test_situations_use_only_exported_fields_and_rights_capped_quotes(ts):
    fields = dict(re.findall(r"^type_field\(\w+, (\w+), '([^']*)'\)\.", EXPORT, re.M))
    for a in _data(ts)["answers"]:
        for s in a["situations"]:
            assert set(s["facts"]) <= set(fields), (a["answer"], set(s["facts"]) - set(fields))
            assert set(s["evidence"]) == set(s["facts"]), a["answer"]
            assert all(v in allowed(fields[f]) for f, v in s["facts"].items()), a["answer"]
            assert all(0 < len(q) <= 160 for q in s["evidence"].values()), a["answer"]


@pytest.mark.parametrize("ts", SETS, ids=ids)
def test_every_case_unit_is_typed(ts):
    assert {u for u, _, _ in ts.cases(ROOT)} == {a["answer"] for a in _data(ts)["answers"]}


@pytest.mark.parametrize("ts", TYPED, ids=typed_ids)
def test_the_prolog_situations_are_current(ts):
    assert tr.prolog_file(ts, _data(ts)) == (ROOT / ts.prolog).read_text(encoding="utf-8")


@pytest.mark.parametrize("ts", [pytest.param(ts, id=ts.name,
                         marks=[pytest.mark.external_source] if ts.name == "islamqa_tranche1" else [])
                         for ts in SETS])
def test_the_report_is_current(ts, swipl, request):
    if ts.name == "islamqa_tranche1":
        request.getfixturevalue("islamqa_answers")
    assert json.dumps(tr.report(ROOT, ts, tr.coverage(ROOT, ts)), ensure_ascii=False, indent=2) + "\n" == \
        (ROOT / ts.report).read_text(encoding="utf-8")


def test_hybrid_puts_types_first_and_words_break_ties():
    assert tr.hybrid({"b": 1.0, "c": 0.5, "d": 1.0}, ["a", "b", "c", "d"]) == ["b", "d", "c", "a"]
    assert tr.hybrid({}, ["a", "b"]) == ["a", "b"]


@pytest.mark.parametrize("ps", tr.present(ROOT, tr.PROPOSALS), ids=lambda ps: ps.name)
def test_a_proposal_set_is_its_deterministic_sample_of_r2_units(ps):
    """The draw is fixed: a sampled unit later annotated in lane B stays in it, its proposal consumed."""
    from usul_corpus import units
    inv = json.loads((ROOT / "corpus" / units.INVENTORY).read_text(encoding="utf-8"))
    inventoried = units.pending(ROOT / "corpus") | {i for r in inv["witnesses"] for i in r["annotated_ids"]}
    sample = ps.units(ROOT)
    assert [a["answer"] for a in _data(ps)["answers"]] == sample
    assert set(sample) <= inventoried


@pytest.mark.parametrize("ps", tr.present(ROOT, tr.PROPOSALS), ids=lambda ps: ps.name)
def test_the_proposals_are_current(ps, swipl):
    assert json.dumps(tr.proposals(ROOT, ps, tr.coverage(ROOT, ps)), ensure_ascii=False, indent=2) + "\n" == \
        (ROOT / ps.proposals).read_text(encoding="utf-8")
