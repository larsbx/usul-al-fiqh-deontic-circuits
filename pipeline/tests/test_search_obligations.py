"""PR-34 review obligations are derived views, never search or acceptance evidence."""

import json
from pathlib import Path

import pytest

from usul_corpus import position_receipts, reconcile, takhrij

ROOT = Path(__file__).parents[2]


def fixture(monkeypatch, rulings, proofs):
    monkeypatch.setitem(takhrij.ENCODERS, "search_test", {"out": [False, 0, True]})
    case = {"far": "test", "encoder": "search_test", "expected": False,
            "positions": [{"who": f"holder-{i}", "ruling": r} for i, r in enumerate(rulings)]}
    entry = {"far": "test", "proofs": [{"position": i, "tier": "qiyas"} for i in proofs],
             position_receipts.FIELD: position_receipts.digest(case)}
    return case, entry


def queue(case, entry):
    return reconcile.search_obligations([case], {"entries": [entry]})


def test_typed_sides_retain_all_position_subjects(monkeypatch):
    case, entry = fixture(monkeypatch, [False, 0, 0], [0])
    report = queue(case, entry)
    assert (report["cases"], report["rulings"], report["unrecorded_cases"]) == (1, 1, 1)
    obligation = report["entries"][0]
    assert obligation[position_receipts.FIELD] == position_receipts.digest(case)
    assert obligation["resolution"] == {"stage": "tarjih", "ruling": False}
    assert obligation["unproven_rulings"] == [
        {"ruling": 0, "ruling_code": takhrij.code(0),
         "positions": [{"index": 1, "who": "holder-1"}, {"index": 2, "who": "holder-2"}]}]
    assert obligation["entry_search_note"] is None


def test_wholly_unproven_weighed_cases_keep_each_typed_side(monkeypatch):
    case, entry = fixture(monkeypatch, [False, 0], [])
    assert reconcile.unproven(case, entry) == []  # Different from a win against an unproven side.
    report = queue(case, entry)
    assert report["rulings"] == 2
    assert [s["ruling_code"] for s in report["entries"][0]["unproven_rulings"]] == ["false", "0"]
    assert report["entries"][0]["resolution"] == {"stage": "tawaqquf", "ruling": None}


@pytest.mark.parametrize("note, status", [(None, "unrecorded"), ("  ", "unrecorded"),
                                        ("  source search note  ", "entry_note_only")])
def test_entry_note_never_claims_per_side_coverage(monkeypatch, note, status):
    case, entry = fixture(monkeypatch, [False, True], [0])
    entry["searched"] = note
    obligation = queue(case, entry)["entries"][0]
    assert obligation["search_record_status"] == status
    assert obligation["entry_search_note"] == (note if status == "entry_note_only" else None)


def test_unweighed_and_fully_proven_cases_have_no_search_obligations(monkeypatch):
    case, entry = fixture(monkeypatch, [False, True], [0, 1])
    assert queue(case, entry)["entries"] == []
    del entry["proofs"]
    assert queue(case, entry)["entries"] == []


@pytest.mark.parametrize("receipt", [None, "0" * 64])
def test_missing_or_stale_subject_receipts_fail(monkeypatch, receipt):
    case, entry = fixture(monkeypatch, [False, True], [0])
    entry[position_receipts.FIELD] = receipt
    with pytest.raises(ValueError, match="positions receipt"):
        queue(case, entry)


def test_committed_queue_replays_and_unrecorded_cases_match_pinned_obligations():
    cases, ledger = takhrij.load(ROOT / "corpus"), reconcile.load(ROOT / "corpus")
    report = reconcile.search_obligations(cases, ledger)
    committed = json.loads((ROOT / "corpus" / reconcile.REPORT).read_text())
    assert committed["search_obligations"] == report
    assert {e["far"] for e in report["entries"] if e["search_record_status"] == "unrecorded"} == reconcile._unsearched()
    assert report == reconcile.search_obligations(list(reversed(cases)),
                                                 {"entries": list(reversed(ledger["entries"]))})
