"""PR #49: composite abstention removes contradictions without losing evidence."""

import json
from pathlib import Path

from usul_corpus import reconcile, takhrij

ROOT = Path(__file__).parents[2]
PREFIX = "ibn_rajab.taqrir_qawaid.openiti_rajab_shamela21730."
HISTORY = ROOT / "corpus/reconciliation/history/pr49-q014-resolved.json"


def test_pr49_resolved_cases_retain_positions_sources_and_guards():
    archive = json.loads(HISTORY.read_text())
    cases = takhrij.load(ROOT / "corpus")
    by = {c["far"]: c for c in cases}
    ledger = reconcile.load(ROOT / "corpus")
    active = {e["far"] for e in ledger["entries"]}
    candidates = {c["far"] for c in reconcile.candidates(cases)}
    records = {
        r["id"]: r
        for r in map(json.loads, filter(None, (ROOT / "corpus/records/openiti-rajab-shamela21730.jsonl").read_text().splitlines()))
    }
    assert {e["far"] for e in archive["entries"]} == {PREFIX + "q014.f001", PREFIX + "q014.f002"}
    assert [len(e["evidence"]) for e in archive["entries"]] == [5, 4]
    for entry in archive["entries"]:
        far = entry["far"]
        case = by[far]
        assert far in records
        assert case["class"] == "genuine_ikhtilaf"
        assert case["facts"] == {"harmless": False}
        assert case["expected"] == "abstain"
        assert case["matches_madhhab"] is True
        assert takhrij.check_case(case) == []
        rulings = [p["ruling"] for p in case["positions"]]
        assert rulings == (["neither", "lot", "each", "abstain"] if far.endswith("f001") else ["neither", "lot", "abstain"])
        assert len(entry["grades"]) == len(rulings)
        assert reconcile.attribution(case, entry) == ("tarjih", "abstain")  # the labels' record; unweighed by proof
        assert reconcile.attribution_standing(case, entry) == "for_reading"
        assert far not in active and far not in candidates
        assert far in takhrij.lean_file([case])
        assert "#guard (Usul.Refinements.attachTo false) == .abstain" in takhrij.lean_file([case])
        assert far not in reconcile.lean_file(cases, ledger)
        # Changing only the expected reading back recreates the original residue.
        old = {**case, "expected": "neither", "matches_madhhab": False}
        assert reconcile.attribution_standing(old, entry) == "against_reading"
    # The harmless purification case was a distinct residue; PR-28 closed it by jamʿ
    # (`cause_on_certainty`), and its pre-jamʿ reading still stands against the evidence.
    far = PREFIX + "q014.f000"
    entry = next(e for e in ledger["entries"] if e["far"] == far)
    assert by[far]["expected"] == "neither" and entry["jam"]["from"] == "cause_from_one_of_two"
    assert reconcile.resolve(by[far], entry) == ("jam", "neither")
    assert reconcile.standing(by[far], entry) == "for_reading"
    pre = {**by[far], "encoder": "cause_from_one_of_two", "expected": "each", "matches_madhhab": False}
    assert reconcile.attribution_standing(pre, {k: v for k, v in entry.items() if k != "jam"}) == "against_reading"


def test_pr49_tranche_and_current_generated_reports_are_consistent():
    tranche = json.loads((ROOT / "corpus/takhrij/rajab_m8_tranche8_furu.json").read_text())["cases"]
    report = takhrij.report(tranche)
    assert report["total"] == 27
    assert report["classes"] == {"derivable": 15, "genuine_ikhtilaf": 12}
    # 8 on the madhhab's marked side at the PR #49 merge; q014.f000's jamʿ (PR-28) adds one. The side
    # describes the text and is no longer scored (madhhab coverage is retired for decided coverage).
    assert sum(1 for c in tranche if c["class"] == "genuine_ikhtilaf" and c.get("matches_madhhab")) == 9
    assert report["decided_coverage"] == 1.0 and report["disputed"] == 12
    assert report["encoding_error"] == report["gaps_open"] == 0
    cases = takhrij.load(ROOT / "corpus")
    ledger = reconcile.load(ROOT / "corpus")
    assert reconcile.report(cases, ledger) == json.loads((ROOT / "corpus/reconciliation/report.json").read_text())
    assert reconcile.lean_file(cases, ledger) == (ROOT / "formal/lean/UsulTest/Reconcile.lean").read_text()
