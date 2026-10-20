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


def _source_text(ts) -> dict[str, str]:
    """Each unit's own text: the committed record for classical sets, the question and answer for IslamQA."""
    import gzip
    units = {a["answer"] for a in _data(ts)["answers"]}
    if ts.name.startswith("islamqa"):
        with gzip.open(ROOT / tr.routing.ANSWERS, "rt", encoding="utf-8") as fh:
            return {r["id"]: f"{r.get('question') or ''}\n{r.get('answer') or ''}" for r in map(json.loads, fh) if r["id"] in units}
    return {i: tr.routing._text(r) for i, r in tr.routing._records(ROOT / "corpus", units).items()}


# IslamQA's own text is the separately pinned LFS archive: its receipts replay in the external gate.
RECEIPTED = [pytest.param(ts, marks=pytest.mark.external_source) if ts.name.startswith("islamqa") else ts for ts in SETS]


@pytest.mark.parametrize("ts", RECEIPTED, ids=ids)
def test_every_fact_is_receipted_by_a_verbatim_quote_of_its_own_text(ts):
    """Replay: each settled fact can be re-checked against the text it was read from."""
    text = _source_text(ts)
    bad = [(a["answer"], q) for a in _data(ts)["answers"] for s in a["situations"] for q in s["evidence"].values()
           if q not in text[a["answer"]]]
    assert bad == []


def test_the_reading_list_is_regenerated_from_the_corpus():
    """The typist's shortlist is a function of the corpus: the strict router's best-ranked qāʿida types."""
    ts = tr.by_name("rajab_fold1")
    assert tr.render_shortlist(ROOT, ts) == (ROOT / ts.shortlist).read_text(encoding="utf-8")


def test_the_strict_ranker_never_saw_the_cases_qaida():
    """Each case is ranked by a model fitted without any farʿ of its qāʿida (the statements kept)."""
    from usul_corpus import routing
    ts = tr.by_name("rajab_fold1")
    assert {routing._fold(u) for u, _, _ in ts.cases(ROOT)} == {1}
    ranked, corpus = ts.ranker(ROOT), ROOT / "corpus"
    cs, qs = routing.cases(corpus), routing.qawaid(corpus)
    u = sorted(ranked)[0]
    model = routing.Model.fit(qs + [(e, t) for i, e, t in cs if routing._qaida(i) != routing._qaida(u)
                                    and routing._fold(routing._qaida(i)) != routing._fold(routing._qaida(u))])
    assert ranked[u] == model.rank(dict((i, t) for i, _, t in cs)[u])


def test_shortlist_typing_routes_held_out_qawaid_far_above_the_router():
    """PR-48: frozen before fold 1 was typed; whole qawāʿid held out from the lexical ranking."""
    r = json.loads((ROOT / tr.by_name("rajab_fold1").report).read_text(encoding="utf-8"))
    assert r["hybrid_recall"]["5"] >= 0.85 and r["lexical_recall"]["5"] < 0.6


@pytest.mark.parametrize("ts", tr.SETS, ids=ids)
def test_routing_to_a_tied_qaida_never_scores_below_routing_to_the_encoder(ts):
    """By qāʿida, a top-k encoder counts when it reads any qāʿida the bank ties the case to; the
    case's own encoder is always one of those, so the qāʿida recall bounds the encoder recall."""
    rep = json.loads((ROOT / ts.report).read_text(encoding="utf-8"))
    assert all(rep["hybrid_recall_by_qaida"][k] >= rep["hybrid_recall"][k] for k in rep["hybrid_recall"])
