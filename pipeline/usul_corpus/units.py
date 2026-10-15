"""Line-segmented units: the segmenters that cut them, and their obligation inventory.

Every record of a witness segmented by one of ``UNIT_SEGMENTERS`` is an obligation, to be annotated
exactly once (docs/architecture/derivation-method.md §3 S0, §4 invariant 5). The generated inventory
``corpus/worklists/units.json`` pins each witness's records file by sha256 and lists the ids already
annotated; pending ids are derived from the records file, so tens of thousands of ids are not
duplicated into a generated file. A records file that no longer matches its pin is refused.

A matn opted in with ``"paragraphs": true`` on its ``abwab`` segmenter also has its masāʾil: each
unit split into paragraphs (``abwab.segment_masail``), written to ``records/<witness>.masail.jsonl``
as children of the bāb records and inventoried as rows of their own kind (``PARAGRAPHS``). The bāb
records and their file are untouched (docs/architecture/mutun-masail.md).
"""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

from .abwab import segment_abwab, segment_masail
from .arabic import letters
from .qa import segment_entries, segment_qa
from .records import _span, bab_record, fatwa_record, masala_record, paragraph_record

# kind ↦ (cut the witness text into units, the record for unit i), records numbered from 1.
UNIT_SEGMENTERS = {
    "qa": (lambda text, seg: segment_qa(text, seg.get("question"), seg["answer"], seg.get("question_heading", False)), fatwa_record),
    "masail": (lambda text, seg: segment_entries(text, seg["start"], seg.get("ordered", False)), masala_record),
    "abwab": (lambda text, seg: segment_abwab(text, seg.get("end")), bab_record),
}
INVENTORY = "worklists/units.json"
PARAGRAPHS = "abwab_paragraphs"  # the inventory kind of a matn's masāʾil
_TITLE = re.compile(r"^(?:كتاب|باب)(?![^\W\d_])")  # a kitāb or bāb title printed as a body line
_TERMINAL = re.compile(r"[.:؟?!][\s\d\"'«»()\[\]{}]*$")
_EXCERPT = 60  # characters of a dropped duplicate quoted in the audit


def masail_path(witness: str) -> str:
    return f"records/{witness}.masail.jsonl"


def paragraph_records(work: dict, witness: str, text: str, seg: dict) -> tuple[list[dict], dict]:
    """The masʾala records of a matn and their audit. Every paragraph of every unit is either a record,
    numbered .p01, .p02 … within its bāb in text order, or reported in the audit: a duplicate (same
    Arabic letters as an earlier paragraph of the witness, which is kept), a title (a kitāb or bāb
    heading printed as a body line), or a paragraph with no Arabic letters («...», a footnote number).
    Continuation lines before a unit's first paragraph are reported as loose text. A kept paragraph
    that opens on a later page than the previous paragraph of its unit, which ends unpunctuated, is
    listed as a page-break candidate: possibly the same sentence, split by the page."""
    records: list[dict] = []
    seen: dict[str, str] = {}
    audit = {"units": 0, "paragraphs": 0, "masail": 0, "duplicates": [], "titles": [], "no_letters": [], "loose": [],
             "page_break_candidates": []}
    for i, unit in enumerate(segment_masail(text, seg.get("end")), 1):
        parent = bab_record(work, witness, i, unit.bab)
        audit["units"] += 1
        audit["paragraphs"] += len(unit.paragraphs)
        audit["loose"] += [{"bab": parent["id"], "text_ar": line} for line in unit.loose]
        n, prev = 0, None
        for k, p in enumerate(unit.paragraphs, 1):
            key, where = letters(p.text), {"bab": parent["id"], "paragraph": k}
            if not key:
                audit["no_letters"].append({**where, "text_ar": p.text})
            elif _TITLE.match(p.text):
                audit["titles"].append({**where, "text_ar": p.text})
            elif key in seen:
                audit["duplicates"].append({**where, "duplicates": seen[key], "page_span": _span(p),
                                            "excerpt_ar": p.text[:_EXCERPT]})
            else:
                n += 1
                r = paragraph_record(work, witness, parent, n, p)
                seen[key] = r["id"]
                records.append(r)
                if prev and prev.end_page != p.page and not _TERMINAL.search(prev.text):
                    audit["page_break_candidates"].append(r["id"])
            prev = p
    audit["masail"] = len(records)
    return records, audit


def _ids(raw: bytes) -> list[str]:
    return [json.loads(line)["id"] for line in raw.decode("utf-8").splitlines()]


def inventory(corpus: Path, annotated: set[str]) -> dict:
    """One row per unit witness, in id order: its pins, counts, and the ids already annotated."""
    reg = json.loads((corpus / "registry.json").read_text(encoding="utf-8"))
    lock = json.loads((corpus / "lock.json").read_text(encoding="utf-8"))["witnesses"]
    rows = []
    for work in reg["works"]:
        for x in work["witnesses"]:
            kind = x.get("segmenter", work.get("segmenter", {})).get("kind")
            if kind not in UNIT_SEGMENTERS:
                continue
            seg = x.get("segmenter", work.get("segmenter", {}))
            paths = [(kind, f"records/{x['id']}.jsonl")] + [(PARAGRAPHS, masail_path(x["id"]))] * bool(seg.get("paragraphs"))
            for k, path in paths:
                raw = (corpus / path).read_bytes()
                ids = _ids(raw)
                done = sorted(annotated.intersection(ids))
                rows.append({"work": work["id"], "witness": x["id"], "kind": k, "source_sha256": lock[x["id"]]["sha256"],
                             "records": path, "records_sha256": hashlib.sha256(raw).hexdigest(),
                             "units": len(ids), "annotated": len(done), "pending": len(ids) - len(done), "annotated_ids": done})
    rows.sort(key=lambda r: (r["witness"], r["records"]))
    totals = {k: sum(r[k] for r in rows) for k in ("units", "annotated", "pending")}
    return {"schema_version": 1, "status": "candidate",
            "unit": "one committed fatwa, masala or bab record; obligations are its record ids",
            "summary": {"witnesses": len({r["witness"] for r in rows}), **totals}, "witnesses": rows}


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
