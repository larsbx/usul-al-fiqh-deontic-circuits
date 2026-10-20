"""Adversarial checks at the interpretation → reconciliation boundary."""
from copy import deepcopy
import json
from pathlib import Path

import pytest

from usul_corpus import reconcile, takhrij

ROOT = Path(__file__).resolve().parents[2]


def disputed():
    case = next(c for c in takhrij.load(ROOT / "corpus") if c["far"].endswith("q043.f005"))
    entry = next(e for e in reconcile.load(ROOT / "corpus")["entries"] if e["far"] == case["far"])
    return deepcopy(case), deepcopy(entry)


@pytest.mark.parametrize("bad", [0, 1, "true", None, [], {}])
def test_wrong_type_cannot_reach_resolution(bad):
    case, entry = disputed()
    case["positions"][0]["ruling"] = bad
    assert any("position" in e for e in takhrij.check_case(case))
    assert any("position" in e for e in reconcile.check([case], {"entries": [entry]}, {"entries": []}))
    with pytest.raises(ValueError, match="position"):
        reconcile.resolve(case, entry)


def test_an_outside_marker_cannot_disguise_a_numeric_boolean():
    case, entry = disputed()
    case["positions"][0].update(ruling=0, outside="reported alternative")
    assert takhrij.check_case(case)
    with pytest.raises(ValueError):
        reconcile.resolve(case, entry)


def test_recorded_range_gaps_survive_without_becoming_encoder_outputs():
    cases = takhrij.load(ROOT / "corpus")
    outside = [(c, p) for c in cases for p in c.get("positions", [])
               if not takhrij.among(p["ruling"], takhrij.ENCODERS[c["encoder"]]["out"])]
    assert len(outside) == 57  # 53 before lane A round 7, which recorded 4 more, each with its `outside`
    assert all(p.get("outside") for _, p in outside)
    assert all(not takhrij.check_case(c) for c, _ in outside)
    case, position = outside[0]
    position.pop("outside")
    assert takhrij.check_case(case)


def test_reconciliation_never_merges_boolean_numeric_or_text_values():
    case = {"positions": [{"ruling": x} for x in [False, 0, "false", True, 1, "true"]]}
    assert len(reconcile.rulings(case)) == 6
    assert reconcile.top([(False, "ijma")], 0) is None
    assert reconcile.support([(True, "nass")], 1) == []
    assert not reconcile.favours([(False, True, "muthbit", "stated")], reconcile.TIER_RANK["zanni"], 0, 1)
    assert reconcile.weigh([False, 0], [(False, "qiyas"), (0, "qiyas")], []) is None
    assert reconcile.prevail([(False, "nass"), (0, "nass")]) is None


def test_lean_export_preserves_the_same_identity_as_python():
    values = [False, 0, "false", True, 1, "true", "1"]
    codes = [json.loads(reconcile._str(v)) for v in values]
    assert len(set(codes)) == len(values)
    assert codes == [takhrij.code(v) for v in values]


def test_committed_reconciliation_outcomes_are_preserved():
    cases = takhrij.load(ROOT / "corpus")
    ledger = reconcile.load(ROOT / "corpus")
    assert reconcile.report(cases, ledger) == json.loads((ROOT / "corpus/reconciliation/report.json").read_text())


def test_pure_kernel_dependency_direction():
    import ast
    package = ROOT / "pipeline/usul_corpus"
    for name, allowed in {"values": {"json"}, "reconciliation_kernel": {"values"}}.items():
        tree = ast.parse((package / f"{name}.py").read_text())
        imports = {node.module for node in ast.walk(tree) if isinstance(node, ast.ImportFrom)}
        imports |= {alias.name for node in ast.walk(tree) if isinstance(node, ast.Import) for alias in node.names}
        assert imports <= allowed


def test_distinct_preserves_first_occurrence_and_type():
    from usul_corpus.values import distinct
    assert list(map(takhrij.code, distinct([False, 0, False, "false", 0]))) == ["false", "0", '\"false\"']


# The receipts below cover the ledger the refactor saw: its 596 entries, listed here so that later
# entries (lane A round 7 on) leave them meaning what they meant. Those are pinned by the report.
PRE_REFACTOR = set(json.loads((Path(__file__).parent / "pre_refactor_ledger.json").read_text()))


def _pre_refactor_entries(ledger):
    entries = [e for e in ledger["entries"] if e["far"] in PRE_REFACTOR]
    assert {e["far"] for e in entries} == PRE_REFACTOR
    return entries


def test_all_policy_outcomes_match_the_pre_refactor_receipt():
    # Computed from the unmodified 57a3b1c resolver, ordered by the committed ledger.
    # Individual results are pinned: unchanged aggregates cannot hide swaps.
    import hashlib
    cases = {c["far"]: c for c in takhrij.load(ROOT / "corpus")}
    ledger = reconcile.load(ROOT / "corpus")
    rows = [[e["far"], policy, reconcile.resolve(cases[e["far"]], e, policy)]
            for e in _pre_refactor_entries(ledger) for policy in reconcile.POLICIES]
    # Audit PR-36 tied each murajjiḥ to its domain: the one intended change is q159.f035 under `all`, whose rejected
    # `dariHadd` (a report's advantage) was applied between two qiyāsāt. Undo exactly it, and every other result holds.
    changed = {("ibn_rajab.taqrir_qawaid.openiti_rajab_shamela21730.q159.f035", "all"): (("tawaqquf", None), ("tarjih", False))}
    assert [(r[0], r[1]) for r in rows if (r[0], r[1]) in changed and r[2] == changed[(r[0], r[1])][0]] == list(changed)
    before = [[f, p, changed[(f, p)][1] if (f, p) in changed else r] for f, p, r in rows]
    receipt = hashlib.sha256(json.dumps(before, ensure_ascii=False, sort_keys=True).encode()).hexdigest()
    assert len(rows) == 2384
    assert receipt == "05ce01715f4945eee8ed9c004fd7aabdbff7af15d8684cf33f6a4ece2edb1585"


def test_all_attribution_outcomes_match_the_pre_refactor_receipt():
    import hashlib
    cases = {c["far"]: c for c in takhrij.load(ROOT / "corpus")}
    ledger = reconcile.load(ROOT / "corpus")
    rows = [[e["far"], reconcile.attribution(cases[e["far"]], e)]
            for e in _pre_refactor_entries(ledger)]
    assert len(rows) == 596
    receipt = hashlib.sha256(json.dumps(rows, ensure_ascii=False, sort_keys=True).encode()).hexdigest()
    assert receipt == "6ce40ff5e69386698ca9d1aebe705b75d94ffe700116de360011ce279af83ea7"
