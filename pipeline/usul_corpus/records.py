"""Map segmentation output onto usul_rule records (pure functions)."""

from __future__ import annotations

import hashlib

from .hudud import Hadd
from .segment import Unit, source_excerpt

PIPELINE = "usul_corpus/1"
EXCERPT_LEN = {"public_domain_text": 400, "modern_cache_only": 160}


def _loc(witness: str, page: tuple[int, int] | None, anchor: str) -> str:
    where = f"/v{page[0]:02d}:p{page[1]:03d}" if page else ""
    return f"src:{witness}{where}#{anchor}"


def unit_tags(units: tuple[Unit, ...], prefix: str = "q") -> list[str]:
    """Stable per-witness tags: q015 for qāʿida 15, q015_2 for a repeated heading
    (OCR or table of contents), u007 for the 7th unit when its number is unparsed."""
    base = [f"{prefix}{u.number:03d}" if u.number else f"u{i:03d}" for i, u in enumerate(units, 1)]
    return [t if base[:i].count(t) == 0 else f"{t}_{base[:i].count(t) + 1}" for i, t in enumerate(base)]


def qaida_records(work: dict, witness: str, method: str, tag: str, u: Unit) -> list[dict]:
    """A qāʿida record followed by one candidate test record per farʿ (M4 seed)."""
    qid = f"{work['id']}.{witness.replace('-', '_')}.{tag}"
    cap = EXCERPT_LEN[work["rights"]]
    furu = [
        {
            "id": f"{qid}.f{k:03d}",
            "work": work["id"],
            "witness": witness,
            "record_type": "far",
            "qaida": qid,
            "locator": _loc(witness, u.page, f"{tag}.f{k:03d}"),
            "case_ar": case[:cap],
            "status": "candidate",
            "extraction": {"pipeline": PIPELINE, "method": f"{method}+furu_minha"},
        }
        for k, case in enumerate(u.furu, 1)
    ]
    opening = [
        {
            "id": f"{qid}.{opening_tag(k)}",
            "work": work["id"],
            "witness": witness,
            "record_type": "far",
            "qaida": qid,
            "locator": _loc(witness, u.page, f"{tag}.{opening_tag(k)}"),
            "case_ar": source_excerpt(u.body[case.start:case.end])[:cap],
            "status": "candidate",
            "extraction": {
                "pipeline": "usul_corpus/opening-furu-1",
                "method": f"{method}+{case.method}",
                "source_span": {
                    "basis": "headed_unit_body/v1",
                    "body_sha256": hashlib.sha256(u.body.encode()).hexdigest(),
                    "start": case.start,
                    "end": case.end,
                    "sha256": hashlib.sha256(u.body[case.start:case.end].encode()).hexdigest(),
                },
            },
        }
        for k, case in enumerate(u.opening)
    ]
    return [_qaida(work, witness, method, qid, tag, u)] + opening + furu


def opening_tag(index: int) -> str:
    """Reserve zero for recovered examples; never consume a legacy positive index."""
    return "f000" if index == 0 else f"f000_{index + 1}"


def _qaida(work: dict, witness: str, method: str, qid: str, tag: str, u: Unit) -> dict:
    return {
        "id": qid,
        "work": work["id"],
        "witness": witness,
        "record_type": "qaida",
        "number": u.number,
        "locator": _loc(witness, u.page, tag),
        "heading_ar": u.heading,
        "excerpt_ar": u.statement[: EXCERPT_LEN[work["rights"]]],
        "kind": "unclassified",
        "furu_count": len(u.furu) + len(u.opening),
        "ocr_corrected": u.ocr_corrected,
        "status": "candidate",
        "extraction": {"pipeline": PIPELINE, "method": method},
    }


def hadd_record(work: dict, witness: str, idx: int, h: Hadd) -> dict:
    cap = EXCERPT_LEN[work["rights"]]
    return {
        "id": f"{work['id']}.{witness.replace('-', '_')}.h{idx:03d}",
        "work": work["id"],
        "witness": witness,
        "record_type": "hadd",
        "locator": _loc(witness, h.page, f"h{idx:03d}"),
        "term_ar": h.term,
        "lughatan_ar": h.lughatan[:cap] if h.lughatan else None,
        "istilahan_ar": h.istilahan[:cap],
        "kind": "definition",
        "status": "candidate",
        "extraction": {"pipeline": PIPELINE, "method": "hudud_brackets"},
    }


def sharh_record(work: dict, witness: str, link) -> dict:
    """The commentary on one verse, linked to that verse's record (``bayt``)."""
    cap = EXCERPT_LEN[work["rights"]]
    tag = f"q{link.number:03d}"
    bayt = f"{work['id']}.{witness.replace('-', '_')}.{tag}"
    return {
        "id": f"{bayt}.sharh",
        "work": work["id"],
        "witness": witness,
        "record_type": "sharh",
        "bayt": bayt,
        "number": link.number,
        "locator": _loc(witness, link.page, f"{tag}.sharh"),
        "page_span": [p[1] for p in (link.page, link.end_page) if p],
        "quoted_ar": link.quoted[:cap],
        "excerpt_ar": link.commentary[:cap],
        "similarity": link.similarity,
        "status": "candidate",
        "extraction": {"pipeline": PIPELINE, "method": "verse_trigram_chain"},
    }
