"""Replay the lane-B semantic receipts without modifying source typing or the type kernel.

The report separates whole-unit obligations from the few component guards. A missing tool or
source is never reported as a successful Lean build or source replay.
"""
from collections import Counter
import hashlib
import json
from pathlib import Path

from . import takhrij
from .units import UNIT_SEGMENTERS

BASE = "9862c8d3f8ef2603209c8faa4b074631f285ab92"
AUDIT = "corpus/routing/r2_sample1_semantic_audit.json"
SUITE = "corpus/takhrij/r2_sample1_lane_b.json"
REPORT = "corpus/routing/r2_sample1_lane_b_report.json"


def read(root: Path, path: str):
    return json.loads((root / path).read_text(encoding="utf-8"))


def replay(root: Path) -> dict:
    audit = read(root, AUDIT)
    cases = read(root, SUITE)["cases"]
    expected = {u["unit"] for u in audit["units"]}
    registry = read(root, "corpus/registry.json")
    lock = read(root, "corpus/lock.json")["witnesses"]
    records = {}
    texts = {}
    missing = []
    witnesses = {u["locator"].split("/")[0].split("#")[0][4:] for u in audit["units"]}
    for work in registry["works"]:
        for witness in work["witnesses"]:
            wid = witness["id"]
            if wid not in witnesses:
                continue
            raw = (root / "corpus/records" / f"{wid}.jsonl").read_text(encoding="utf-8")
            committed = [json.loads(line) for line in raw.splitlines()]
            records.update({r["id"]: r for r in committed if r["id"] in expected})
            paths = [root / ".cache/corpus" / f"{wid}.txt", root / "corpus/texts" / f"{wid}.txt"]
            source = next((p for p in paths if p.exists() and hashlib.sha256(p.read_bytes()).hexdigest() == lock[wid]["sha256"]), None)
            if source is None:
                missing.append(wid)
                continue
            config = witness.get("segmenter", work.get("segmenter", {}))
            cut, record = UNIT_SEGMENTERS[config["kind"]]
            units = cut(source.read_text(encoding="utf-8"), config)
            regenerated = [record(work, wid, i, unit) for i, unit in enumerate(units, 1)]
            if regenerated != committed:
                raise ValueError(f"{wid}: source segmentation drift")
            texts.update({r["id"]: u.text for r, u in zip(regenerated, units) if r["id"] in expected})
    if len(cases) != 40 or {c["far"] for c in cases} != expected or len(expected) != 40:
        raise ValueError("sample inventory changed or duplicated")
    by = {c["far"]: c for c in cases}
    for unit in audit["units"]:
        uid = unit["unit"]
        rec = records[uid]
        if rec["sha256"] != unit["unit_sha256"] or lock[rec["witness"]]["sha256"] != unit["source_sha256"]:
            raise ValueError(f"{uid}: receipt drift")
        if unit["locator"] != rec["locator"] or unit["page_span"] != rec["page_span"]:
            raise ValueError(f"{uid}: invented page or locator")
        if uid in texts and unit["quote"] not in texts[uid]:
            raise ValueError(f"{uid}: nonverbatim quotation")
        if takhrij.check_case(by[uid]):
            raise ValueError(f"{uid}: malformed case")
        if unit["classification"] != by[uid]["class"]:
            raise ValueError(f"{uid}: class drift")
    if takhrij.revisit_queue(cases):
        raise ValueError("the bank already supplies an unrevisited need")
    return dict(status="candidate", base_commit=BASE, units=40, source_replayed=len(texts),
                missing_witnesses=sorted(missing), classes=dict(sorted(Counter(c["class"] for c in cases).items())),
                initially_untyped=sum(not u["blind_typed"] for u in audit["units"]),
                gap_diagnoses=dict(sorted(Counter(u["gap_diagnosis"] for u in audit["units"]).items())),
                incomplete_page_numbering=[u["unit"] for u in audit["units"] if u["page_evidence"] != "numbered"],
                boundary_reviews=[u["unit"] for u in audit["units"] if u["segmentation"] != "replay_stable"],
                guard_scope="Three component guards; not complete derivations of the chapters or procedural branches.",
                lean_verification="Requires make lean; report generation is not Lean verification.",
                reconciliation="Attributed disagreements retained as pending evidence; no unexpressible position is forced into the typed ledger.",
                later_side_verification="Pending al-Insaf/mutamad audit; no matches_madhhab assertion added.")


if __name__ == "__main__":
    root = Path(__file__).resolve().parents[2]
    result = replay(root)
    (root / REPORT).write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False))
