"""Case-level controls for the unblinded audit, separate from frozen blind inputs."""
import copy
import json
from pathlib import Path

import pytest

from usul_corpus import itlaf_audit as audit, typed_routing as tr

ROOT = Path(__file__).resolve().parents[2]
TS = tr.by_name("islamqa_tranche1")
MANIFEST = json.loads((ROOT / audit.MANIFEST).read_text())
DATA = json.loads((ROOT / TS.situations).read_text())
CASES = json.loads((ROOT / tr.routing.TRANCHE).read_text())["cases"]
ITLAF = [c for c in CASES if c["encoder"] == "itlaf"]


@pytest.fixture(scope="module")
def sources():
    return audit.load_sources(ROOT, {c["far"].rsplit(".", 1)[0] for c in ITLAF})


@pytest.mark.external_source
@pytest.mark.parametrize("case", ITLAF, ids=lambda c: c["far"])
def test_each_case_has_canonical_evidence_and_preserves_its_gap(case, sources):
    entries = [r for r in MANIFEST["cases"] if r["case_id"] == case["far"]]
    assert len(entries) == 1
    decision = entries[0]
    unit = case["far"].rsplit(".", 1)[0]
    assert decision["source_excerpt"] in sources[unit]["answer"]
    assert decision["remaining_need"] == case["needs"]
    assert case["facts"] is None and case["expected"] is None
    assert decision["primary"] == ("encoder_field_coverage" if case["class"] == "missing_fact"
                                   else "legitimate_encoder_mismatch")


@pytest.mark.external_source
def test_withdrawals_keep_unknown_unknown_and_preserve_all_other_assignments(sources):
    original = copy.deepcopy(DATA)
    new = audit.corrected(DATA, MANIFEST, sources)
    changes = {(e["answer"], e["situation"], e["field"]) for e in MANIFEST["corrections"]}
    assert len(changes) == 16
    for a, b in zip(DATA["answers"], new["answers"]):
        for i, (s, t) in enumerate(zip(a["situations"], b["situations"]), 1):
            removed = {f for u, n, f in changes if u == a["answer"] and n == i}
            assert t["facts"] == {f: v for f, v in s["facts"].items() if f not in removed}
            assert t["evidence"] == {f: v for f, v in s["evidence"].items() if f not in removed}
    assert DATA == original
    # Genuine custody remains distinct from negligence in a road collision.
    guest = next(a for a in new["answers"] if a["answer"] == "islamqa.164604")
    assert guest["situations"][1]["facts"]["negligent"] is True
    assert "held_by_consent" not in guest["situations"][2]["facts"]
    healer = next(a for a in new["answers"] if a["answer"] == "islamqa.223512")
    assert "udwan_in_mubashara" not in healer["situations"][2]["facts"]
    assert healer["situations"][3]["facts"]["udwan_in_mubashara"] is False


@pytest.mark.external_source
@pytest.mark.parametrize("mutation", ["stale_value", "forged_receipt", "duplicate", "insert"])
def test_stale_or_forged_corrections_fail_closed(mutation, sources):
    manifest = copy.deepcopy(MANIFEST)
    e = manifest["corrections"][0]
    if mutation == "stale_value":
        e["old_value"] = not e["old_value"]
    elif mutation == "forged_receipt":
        e["evidence"] = "unsupported replacement text"
    elif mutation == "duplicate":
        manifest["corrections"].append(copy.deepcopy(e))
    else:
        e["action"] = "insert"
    with pytest.raises(ValueError):
        audit.corrected(DATA, manifest, sources)


def test_hybrid_does_not_receive_gold_or_candidate_conclusions():
    altered = copy.deepcopy(DATA)
    altered["provenance"] = "changed metadata"
    for a in altered["answers"]:
        for s in a["situations"]:
            s["label"] = "itlaf must win; reviewed; liable"
            s["evidence"] = {f: "different metadata" for f in s["evidence"]}
    assert tr.prolog_file(TS, altered) == tr.prolog_file(TS, DATA)
    # Named alternatives and labels are scoring metadata, not arguments to hybrid.
    assert tr.hybrid({"trust_loss": 0.5}, ["itlaf", "trust_loss"]) == ["trust_loss", "itlaf"]


def test_null_typed_rank_is_not_null_hybrid_rank_and_cases_are_distinct():
    report = json.loads((ROOT / TS.report).read_text())
    rows = [r for r in report["cases_detail"] if r["encoder"] == "itlaf"]
    assert len({r["case_id"] for r in rows}) == 27
    assert sum(r["rank"] is None for r in rows) == 25
    assert all(r["hybrid_rank"] is not None for r in rows)
    assert all(r["gold_qawaid_basis"] == "encoder_fallback" for r in rows)
    assert {r["annotation_class"] for r in rows} == {"missing_fact", "missing_rule"}
    family = [r for r in rows if r["case"] == "islamqa.223512"]
    assert len(family) == 2
    assert family[0]["best_rank_with_named"] == 2
    assert "best_rank_with_named" not in family[1]


@pytest.mark.external_source
def test_full_audit_replays_with_real_prolog_and_pinned_sources(swipl, islamqa_answers):
    report = audit.build(ROOT)
    assert report == json.loads((ROOT / audit.REPORT).read_text())
    assert report["status"] == "candidate" and report["human_reviewed"] is False
    for row in report["cases"]:
        assert row["after"]["settled"] < 1
        if row["baseline_unrouted"]:
            assert row["after"]["settled"] == 0
    # No non-itlaf family metric can be omitted from the comparison.
    assert set(report["by_encoder"]) == {c["encoder"] for c in CASES}
    assert report["before"]["hybrid_recall"] == report["after"]["hybrid_recall"]
    assert report["before"]["hybrid_recall_by_qaida"] == report["after"]["hybrid_recall_by_qaida"]
