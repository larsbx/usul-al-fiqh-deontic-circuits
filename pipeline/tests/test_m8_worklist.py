"""Scope reconciliation, immutable source receipts, and M8 tranche obligations."""

import copy
import hashlib
import json
import re
from pathlib import Path

import pytest

from usul_corpus import m8_worklist, takhrij

ROOT = Path(__file__).parents[2]
CORPUS = ROOT / "corpus"


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def test_worklist_is_generated_and_its_denominators_reconcile_independently():
    inventory = _json(CORPUS / m8_worklist.OUTPUT)
    assert (CORPUS / m8_worklist.OUTPUT).read_text(encoding="utf-8") == m8_worklist.render(CORPUS)
    records = [json.loads(l) for l in (CORPUS / m8_worklist.RECORDS).read_text().splitlines()]
    fars = {r["id"]: r["qaida"] for r in records if r["record_type"] == "far"}
    parents = {r["id"] for r in records if r["record_type"] == "qaida"}
    covered = {c["far"] for c in takhrij.load(CORPUS)} & fars.keys()
    pending = fars.keys() - covered
    summary = inventory["summary"]
    assert summary["segmented_furu"] == len(fars) == 1179
    assert summary["annotated_furu"] == len(covered)
    assert summary["pending_furu"] == len(pending)
    assert summary["qawaid_awaiting_annotation"] == len({fars[i] for i in pending})
    assert summary["qawaid_needing_source_segmentation"] == len(parents - set(fars.values())) == 6
    assert set(i for q in inventory["qawaid"] for i in q["pending_furu"]) == pending
    assert not any(q["pending_furu"] for q in inventory["qawaid"] if q["state"] == "needs_source_segmentation")
    # Annotated gaps are already inventoried, not silently counted again as new work.
    assert not {c["far"] for c in takhrij.load(CORPUS) if c.get("needs")} & pending
    report = takhrij.report(takhrij.load(CORPUS))
    assert inventory["aggregate_report"] == {k: report[k] for k in inventory["aggregate_report"]}
    suite = _json(CORPUS / "takhrij/rajab_m8_tranche3_furu.json")
    assert inventory["tranche3_report"] == takhrij.report(suite["cases"])


def _fixture():
    q = takhrij.RAJAB.format(1)
    return [{"id": q, "number": 1, "record_type": "qaida", "furu_count": 2, "locator": "src:x"},
            {"id": q + ".f000", "record_type": "far", "qaida": q},
            {"id": q + ".f001", "record_type": "far", "qaida": q}], [{"far": q + ".f000"}]


@pytest.mark.parametrize("mutation,message", [
    ("duplicate_record", "duplicate corpus"), ("duplicate_annotation", "duplicate annotation"),
    ("orphan", "orphan far"), ("wrong_parent_count", "furu_count disagrees"),
    ("annotation_missing_from_source", "annotation id absent"),
])
def test_scope_reconciliation_rejects_corrupted_inputs(mutation, message):
    records, cases = _fixture()
    if mutation == "duplicate_record":
        records.append(copy.deepcopy(records[-1]))
    elif mutation == "duplicate_annotation":
        cases.append(copy.deepcopy(cases[0]))
    elif mutation == "orphan":
        records[-1]["qaida"] = "missing"
    elif mutation == "wrong_parent_count":
        records[0]["furu_count"] = 3
    else:
        cases[0]["far"] = takhrij.RAJAB.format(1) + ".f999"
    with pytest.raises(ValueError, match=message):
        m8_worklist.reconcile(records, cases)


def test_f000_is_covered_without_changing_the_later_ids():
    records, cases = _fixture()
    rows, summary = m8_worklist.reconcile(records, cases)
    assert rows[0]["pending_furu"] == [takhrij.RAJAB.format(1) + ".f001"]
    assert summary["segmented_furu"] == 2 and summary["annotated_furu"] == 1


def test_documented_scope_is_generated_from_the_same_inventory():
    inventory = m8_worklist.build(CORPUS)
    for path, text in m8_worklist.scoped_documents(ROOT, inventory).items():
        assert path.read_text(encoding="utf-8") == text, f"stale M8 denominator: {path}"


def test_unsegmented_parent_is_separate_from_reading_workload():
    records, cases = _fixture()
    q = takhrij.RAJAB.format(2)
    records.append({"id": q, "number": 2, "record_type": "qaida", "furu_count": 0,
                    "locator": "src:x", "excerpt_ar": "مثل أن يستدل على القبلة بنجم"})
    rows, summary = m8_worklist.reconcile(records, cases)
    assert rows[-1]["state"] == "needs_source_segmentation" and rows[-1]["pending_furu"] == []
    assert summary["pending_furu"] == summary["qawaid_awaiting_annotation"] == 1
    assert summary["qawaid_needing_source_segmentation"] == 1


def test_selected_tranche_has_exact_obligations_and_open_human_review():
    plan = _json(CORPUS / "worklists/rajab_m8_tranche3_plan.json")
    suite = _json(CORPUS / "takhrij/rajab_m8_tranche3_furu.json")
    records = {r["id"]: r for r in map(json.loads, (CORPUS / m8_worklist.RECORDS).read_text().splitlines())}
    chosen = {q["qaida"] for q in plan["selection"]}
    expected = {r["id"] for r in records.values() if r.get("qaida") in chosen}
    cases = {c["far"]: c for c in suite["cases"]}
    assert set(cases) == expected == {o["far"] for o in plan["obligations"]}
    assert len(expected) == len(plan["obligations"]) == 29
    assert takhrij.RAJAB.format(47) + ".f000" in expected
    assert suite["status"] == plan["status"] == "candidate"
    assert all(q["status"] == "open" for q in plan["review_questions"])
    assert set(i for q in plan["review_questions"] for i in q["scope"]) <= expected
    assert plan["source"]["sha256"] == _json(CORPUS / "lock.json")["witnesses"][m8_worklist.WITNESS]["sha256"]
    guards = (ROOT / "formal/lean/UsulTest/M8Tranche3.lean").read_text()
    checked = (ROOT / "formal/lean/UsulTest/SignatureMap.lean").read_text()
    for q in plan["selection"]:
        assert all(f"#check @{n}\n" in checked for n in q["reading"])
    revised = {r["far"]: r for r in plan.get("revisions", []) if "closed_by" in r}
    renoted = {r["far"]: r for r in plan.get("note_revisions", [])}
    for o in plan["obligations"]:
        record, case = records[o["far"]], cases[o["far"]]
        assert o["record_locator"] == record["locator"]
        assert o["case_ar_sha256"] == hashlib.sha256(record["case_ar"].encode()).hexdigest()
        if o["far"] in revised:  # a later round re-read it under a new encoder; the obligation is its origin
            assert case["revisit"]["from_encoder"] == o["encoder"] == revised[o["far"]]["from_encoder"]
            assert case["encoder"] == revised[o["far"]]["encoder"]
        else:
            assert all(o[k] == case[k] for k in ("encoder", "facts", "expected"))
        assert o["source_evidence"] and all(0 < len(e["excerpt_ar"]) <= 400 for e in o["source_evidence"])
        assert all(g in guards for g in o["additional_guards"])


def test_both_pr_contributions_are_preserved_without_case_reinterpretation():
    """Every case equals its contribution receipt, unless a later round revised it: then the
    plan's revision ledger links the receipt to the current case and its closure."""
    plan = _json(CORPUS / "worklists/rajab_m8_tranche3_plan.json")
    cases = {c["far"]: c for c in _json(CORPUS / "takhrij/rajab_m8_tranche3_furu.json")["cases"]}
    receipts = {r["pr"]: r["case_sha256"] for r in plan["contributions"]}
    assert set(receipts) == {31, 32}
    assert len(receipts[31]) == 8 and len(receipts[32]) == 21
    assert not receipts[31].keys() & receipts[32].keys()
    assert receipts[31].keys() | receipts[32].keys() == cases.keys()
    revised = {r["far"]: r for r in plan.get("revisions", [])}
    renoted = {r["far"]: r for r in plan.get("note_revisions", [])}
    for receipt in receipts.values():
        for far, expected_hash in receipt.items():
            encoded = json.dumps(cases[far], ensure_ascii=False, sort_keys=True, separators=(",", ":"))
            current = hashlib.sha256(encoded.encode()).hexdigest()
            if far in revised:  # a revisit leaves a ledger entry from the receipt to the current case
                rev = revised[far]
                assert (rev["from_case_sha256"], rev["case_sha256"]) == (expected_hash, current), far
                if "side_check" in rev:  # lane D: the side failed verification; the case keeps its annotation
                    assert cases[far]["side_check"] == rev["side_check"], far
                else:
                    assert cases[far]["revisit"]["closed_by"] == rev["closed_by"], far
            elif far in renoted:  # only English fields changed: restoring them gives the receipt back
                rn = renoted[far]
                old = dict(cases[far], note=rn.get("from_note", cases[far].get("note")))
                if "from_who" in rn:
                    old["positions"] = [dict(p, who=w) for p, w in zip(cases[far]["positions"], rn["from_who"], strict=True)]
                was = json.dumps(old, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
                assert hashlib.sha256(was.encode()).hexdigest() == expected_hash and current == rn["case_sha256"], far
            else:
                assert current == expected_hash, far


def test_new_segmentation_preserves_every_legacy_record_and_identifier():
    """Project away just the 43 added far records and their parent count increments.
    The result must equal the hash-pinned pre-list corpus, including order and case text."""
    from collections import Counter

    plan = _json(CORPUS / "worklists/rajab_m8_tranche3_plan.json")
    receipt = plan["segmentation"]
    raw = (CORPUS / m8_worklist.RECORDS).read_bytes()
    assert hashlib.sha256(raw).hexdigest() == receipt["current_records_sha256"]
    records = [json.loads(line) for line in raw.decode().splitlines()]
    by_id = {r["id"]: r for r in records}
    added = set(receipt["added_far_ids"])
    assert len(added) == 43 and len(receipt["affected_qawaid"]) == 14
    assert all(by_id[i]["record_type"] == "far" for i in added)
    counts = Counter(by_id[i]["qaida"] for i in added)
    assert set(counts) == set(receipt["affected_qawaid"])
    legacy = [copy.deepcopy(r) for r in records if r["id"] not in added]
    for r in legacy:
        if r["record_type"] == "qaida":
            r["furu_count"] -= counts[r["id"]]
    projected = "".join(json.dumps(r, ensure_ascii=False) + "\n" for r in legacy).encode()
    assert len(records) == receipt["current_record_count"] == 1339
    assert len(legacy) == receipt["base_record_count"] == 1296
    assert hashlib.sha256(projected).hexdigest() == receipt["base_records_sha256"]


def test_full_locked_source_replays_records_and_selected_source_evidence():
    from usul_corpus.__main__ import CACHE, _segment
    from usul_corpus.segment import _number

    source = CACHE / f"{m8_worklist.WITNESS}.txt"
    if not source.exists():
        pytest.skip("full locked Ibn Rajab witness is not cached")
    plan = _json(CORPUS / "worklists/rajab_m8_tranche3_plan.json")
    raw = source.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == plan["source"]["sha256"]
    assert len(raw) == plan["source"]["bytes"]
    work = next(w for w in _json(CORPUS / "registry.json")["works"] if w["id"] == m8_worklist.WORK)
    witness = next(w for w in work["witnesses"] if w["id"] == m8_worklist.WITNESS)
    records, _ = _segment(work, witness, raw.decode("utf-8"))
    assert records == [json.loads(l) for l in (CORPUS / m8_worklist.RECORDS).read_text().splitlines()]
    text = re.sub(r"ms\d+", "", raw.decode("utf-8"))
    headers = [m for m in re.finditer(r"^###\s*(\|+)\s*(.*)$", text, re.M) if len(m[1]) == 1]
    spans = {}
    for k, header in enumerate(headers):
        if "القاعدة" in header[2]:
            number, _ = _number(header[2].split("القاعدة", 1)[1])
            spans[number] = (header.start(), headers[k + 1].start() if k + 1 < len(headers) else len(text))
    indices = [i for i, ch in enumerate(text) if "ء" <= ch <= "ي"]
    letters = "".join(text[i] for i in indices)
    for o in plan["obligations"]:
        lo, hi = spans[int(o["far"].split(".")[-2][1:])]
        for evidence in o["source_evidence"]:
            excerpt = re.sub(r"[^ء-ي]", "", evidence["excerpt_ar"])
            assert excerpt in re.sub(r"[^ء-ي]", "", text[lo:hi]), o["far"]
            start = letters.find(excerpt)
            while start >= 0 and not lo <= indices[start] < hi:
                start = letters.find(excerpt, start + 1)
            assert start >= 0, o["far"]
            marker = re.search(r"PageV(\d+)P(\d+)", text[indices[start + len(excerpt) - 1]:])
            assert evidence["ref"] == f"src:{m8_worklist.WITNESS}/v{marker[1]}:p{marker[2]}", o["far"]
