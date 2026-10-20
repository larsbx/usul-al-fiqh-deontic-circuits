"""Line-segmented units: the segmenters that cut them, and their obligation inventory.

Every record of a witness segmented by one of ``UNIT_SEGMENTERS`` is an obligation, to be annotated
exactly once (docs/architecture/derivation-method.md §3 S0, §4 invariant 5). The generated inventory
``corpus/worklists/units.json`` pins each witness's records file by sha256 and lists the ids already
annotated; pending ids are derived from the records file, so tens of thousands of ids are not
duplicated into a generated file. A records file that no longer matches its pin is refused.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

from .abwab import segment_abwab
from .qa import segment_entries, segment_qa
from .records import bab_record, fatwa_record, masala_record

# kind ↦ (cut the witness text into units, the record for unit i), records numbered from 1.
UNIT_SEGMENTERS = {
    "qa": (lambda text, seg: segment_qa(text, seg.get("question"), seg["answer"], seg.get("question_heading", False)), fatwa_record),
    "masail": (lambda text, seg: segment_entries(text, seg["start"], seg.get("ordered", False)), masala_record),
    "abwab": (lambda text, seg: segment_abwab(text, seg.get("end"), seg.get("body_headings", False), seg.get("kitab_headings", ())), bab_record),
}
INVENTORY = "worklists/units.json"


def segmenter_of(work: dict, witness: dict) -> dict | None:
    """The witness's segmenter config: its own, else its work's, else none (the witness is not cut)."""
    return witness.get("segmenter", work.get("segmenter"))


def _ids(raw: bytes) -> list[str]:
    return [json.loads(line)["id"] for line in raw.decode("utf-8").splitlines()]


def inventory(corpus: Path, annotated: set[str]) -> dict:
    """One row per unit witness, in id order: its pins, counts, and the ids already annotated."""
    reg = json.loads((corpus / "registry.json").read_text(encoding="utf-8"))
    lock = json.loads((corpus / "lock.json").read_text(encoding="utf-8"))["witnesses"]
    rows = []
    for work in reg["works"]:
        for x in work["witnesses"]:
            kind = (segmenter_of(work, x) or {}).get("kind")
            if kind not in UNIT_SEGMENTERS:
                continue
            path = f"records/{x['id']}.jsonl"
            raw = (corpus / path).read_bytes()
            ids = _ids(raw)
            done = sorted(annotated.intersection(ids))
            rows.append({"work": work["id"], "witness": x["id"], "kind": kind, "source_sha256": lock[x["id"]]["sha256"],
                         "records": path, "records_sha256": hashlib.sha256(raw).hexdigest(),
                         "units": len(ids), "annotated": len(done), "pending": len(ids) - len(done), "annotated_ids": done})
    rows.sort(key=lambda r: r["witness"])
    totals = {k: sum(r[k] for r in rows) for k in ("units", "annotated", "pending")}
    return {"schema_version": 1, "status": "candidate",
            "unit": "one committed fatwa, masala or bab record; obligations are its record ids",
            "summary": {"witnesses": len(rows), **totals}, "witnesses": rows}


def render(corpus: Path, annotated: set[str]) -> str:
    return json.dumps(inventory(corpus, annotated), ensure_ascii=False, indent=2) + "\n"


def pending(corpus: Path) -> set[str]:
    """The unit ids awaiting annotation, from the committed inventory and the pinned records files."""
    path = corpus / INVENTORY
    if not path.exists():
        return set()
    out: set[str] = set()
    for r in json.loads(path.read_text(encoding="utf-8"))["witnesses"]:
        raw = (corpus / r["records"]).read_bytes()
        if hashlib.sha256(raw).hexdigest() != r["records_sha256"]:
            raise ValueError(f"{r['records']} drifted from {INVENTORY}: run python -m usul_corpus worklist")
        out |= set(_ids(raw)) - set(r["annotated_ids"])
    return out
