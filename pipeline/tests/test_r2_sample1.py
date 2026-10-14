import copy
import json
from pathlib import Path

import pytest

from usul_corpus import r2_sample1, takhrij

ROOT = Path(__file__).resolve().parents[2]


def test_r2_inventory_source_receipts_and_cases():
    result = r2_sample1.replay(ROOT)
    for case in r2_sample1.read(ROOT, r2_sample1.SUITE)["cases"]:
        assert set(case["facts"]) <= set(takhrij.ENCODERS[case["encoder"]]["facts"])
    committed = r2_sample1.read(ROOT, r2_sample1.REPORT)
    # CI may have LFS pointers. All source-independent receipts still run; source replay is
    # explicitly missing rather than counted as successful when actual bytes are unavailable.
    for key in result.keys() - {"source_replayed", "missing_witnesses"}:
        assert result[key] == committed[key]
    assert result["source_replayed"] == 40 or result["missing_witnesses"]


def test_harb_chronology_does_not_fill_structural_priority():
    cases = r2_sample1.read(ROOT, r2_sample1.SUITE)["cases"]
    c = next(c for c in cases if c["far"].endswith("shamela12527.m00014"))
    assert c["class"] == "missing_rule" and "has_precedence" not in c["facts"]
    assert c["needs"] == ["rule:chronological_marriage_priority"]
    blind = r2_sample1.read(ROOT, "corpus/typing/r2_sample1_situations.json")
    original = next(a for a in blind["answers"] if a["answer"] == c["far"])
    assert original["situations"][0]["facts"] == {"has_precedence": True}


def test_unknown_lot_divisibility_is_not_invented():
    c = next(c for c in r2_sample1.read(ROOT, r2_sample1.SUITE)["cases"] if c["far"].endswith("shamela11315.b00196"))
    assert "divisible" not in c["facts"] and c["class"] == "missing_rule"
    for divisible in (False, True):
        assert takhrij.ENCODERS["lots"]["py"]({**c["facts"], "divisible": divisible}) == "lot"


def test_each_original_proposal_is_accounted_for():
    proposals = r2_sample1.read(ROOT, "corpus/routing/r2_sample1_proposals.json")
    audit = r2_sample1.read(ROOT, r2_sample1.AUDIT)
    by = {u["unit"]: u for u in audit["units"]}
    for p in proposals["units_detail"]:
        assert {x["encoder"] for x in p["proposals"]} == {x["encoder"] for x in by[p["unit"]]["proposal_review"]}


def test_pending_disagreements_are_retained_without_adoption():
    pending = r2_sample1.read(ROOT, "corpus/reconciliation/r2_sample1_pending.json")
    assert pending["status"] == "candidate"
    assert len(pending["entries"]) >= 5
    assert all(e["resolution"] == "pending_vocabulary" and len(e["positions"]) >= 2 for e in pending["entries"])
    from usul_corpus.arabic import locate
    for entry in pending["entries"]:
        assert len(entry["evidence"]) == len(entry["positions"])
        for evidence in entry["evidence"]:
            wid, page = evidence["ref"][4:].split("/")
            source = ROOT / ".cache/corpus" / f"{wid}.txt"
            if source.exists():
                assert locate(source.read_text(encoding="utf-8"), evidence["excerpt_ar"]) == page


def test_triage_does_not_train_on_its_own_routing_proposals():
    from usul_corpus import routing
    cases = r2_sample1.read(ROOT, r2_sample1.SUITE)["cases"]
    ids = {c["far"] for c in cases}
    assert all(c["routing_label"] is False for c in cases)
    assert not ids & {uid for uid, _, _ in routing.cases(ROOT / "corpus")}


def test_replay_rejects_edited_receipt(monkeypatch):
    original = r2_sample1.read
    altered = copy.deepcopy(original(ROOT, r2_sample1.AUDIT))
    altered["units"][0]["unit_sha256"] = "0" * 64
    monkeypatch.setattr(r2_sample1, "read", lambda root, path: altered if path == r2_sample1.AUDIT else original(root, path))
    with pytest.raises(ValueError, match="receipt drift"):
        r2_sample1.replay(ROOT)
