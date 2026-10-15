"""Map segmentation output onto usul_rule records (pure functions)."""

from __future__ import annotations

from .hudud import Hadd
from .segment import Unit

PIPELINE = "usul_corpus/1"
EXCERPT_LEN = {"public_domain_text": 400, "modern_cache_only": 160, "cc_by_verbatim": 400}


def _loc(witness: str, page: tuple[int, int] | None, anchor: str) -> str:
    where = f"/v{page[0]:02d}:p{page[1]:03d}" if page else ""
    return f"src:{witness}{where}#{anchor}"


def _span(u) -> list[int] | None:
    """The first and last page of a line-segmented unit; none when it sits on no numbered page."""
    return [p[1] for p in (u.page, u.end_page) if p] or None


def unit_tags(units: tuple[Unit, ...], prefix: str = "q") -> list[str]:
    """Stable per-witness tags: q015 for qāʿida 15, q015_2 for a repeated heading
    (OCR or table of contents), u007 for the 7th unit when its number is unparsed."""
    base = [f"{prefix}{u.number:03d}" if u.number else f"u{i:03d}" for i, u in enumerate(units, 1)]
    return [t if base[:i].count(t) == 0 else f"{t}_{base[:i].count(t) + 1}" for i, t in enumerate(base)]


def qaida_records(work: dict, witness: str, method: str, tag: str, u: Unit) -> list[dict]:
    """A qāʿida record followed by one candidate test record per farʿ (M4 seed)."""
    qid = f"{work['id']}.{witness.replace('-', '_')}.{tag}"
    cap = EXCERPT_LEN[work["rights"]]
    cases = ([(0, u.opening, "opening_example")] if u.opening else []) + [
        (k, case, "furu_minha") for k, case in enumerate(u.furu, 1)]
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
            "extraction": {"pipeline": PIPELINE, "method": f"{method}+{how}"},
        }
        for k, case, how in cases
    ]
    return [_qaida(work, witness, method, qid, tag, u)] + furu


def with_recovered(records: list[dict], recovered: list[dict]) -> list[dict]:
    """Recovered opening furūʿ (``corpus/segmentation/<witness>-opening.json``) placed after their
    qāʿida's own .f000 (or the qāʿida, when it has none), each counted in its furu_count. No
    existing id moves."""
    extra: dict[str, list[dict]] = {}
    for r in recovered:
        extra.setdefault(r["qaida"], []).append(r)
    opened = {r["qaida"] for r in records if r["id"].endswith(".f000")}
    out: list[dict] = []
    for r in records:
        q = r["id"] if r["record_type"] == "qaida" else r.get("qaida")
        if r["record_type"] == "qaida" and q in extra:
            r = {**r, "furu_count": r["furu_count"] + len(extra[q])}
        out.append(r)
        if q in extra and r["id"] == (f"{q}.f000" if q in opened else q):
            out += extra.pop(q)
    if extra:
        raise ValueError(f"recovered furūʿ without their qāʿida: {sorted(extra)}")
    return out


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
        "furu_count": len(u.furu) + bool(u.opening),
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


def fatwa_record(work: dict, witness: str, idx: int, u) -> dict:
    """One question-and-answer unit (``qa.QA``) of a fatāwā collection: excerpts within the
    work's rights, the page span, and the sha256 receipt of the full unit text."""
    cap = EXCERPT_LEN[work["rights"]]
    tag = f"qa{idx:05d}"
    return {
        "id": f"{work['id']}.{witness.replace('-', '_')}.{tag}",
        "work": work["id"],
        "witness": witness,
        "record_type": "fatwa",
        "number": u.number,
        "locator": _loc(witness, u.page, tag),
        "page_span": _span(u),
        "question_ar": u.question[:cap],
        "answer_ar": u.answer[:cap] if u.answer else None,
        "sha256": u.sha256,
        "status": "candidate",
        "extraction": {"pipeline": PIPELINE, "method": "qa"},
    }


def masala_record(work: dict, witness: str, idx: int, u) -> dict:
    """One entry (``qa.Entry``) of a *Masāʾil* collection: its excerpt within the work's rights,
    printed number, page span and the sha256 receipt of the whole entry."""
    tag = f"m{idx:05d}"
    return {
        "id": f"{work['id']}.{witness.replace('-', '_')}.{tag}",
        "work": work["id"],
        "witness": witness,
        "record_type": "masala",
        "number": u.number,
        "locator": _loc(witness, u.page, tag),
        "page_span": _span(u),
        "excerpt_ar": u.text[:EXCERPT_LEN[work["rights"]]],
        "sha256": u.sha256,
        "status": "candidate",
        "extraction": {"pipeline": PIPELINE, "method": "masail"},
    }


def bab_record(work: dict, witness: str, idx: int, u) -> dict:
    """One unit (``abwab.Bab``) of a matn: its heading, rank, path, excerpt within the work's rights,
    page span and the sha256 receipt of the whole unit."""
    tag = f"b{idx:05d}"
    return {
        "id": f"{work['id']}.{witness.replace('-', '_')}.{tag}",
        "work": work["id"],
        "witness": witness,
        "record_type": "bab",
        "rank": u.rank,
        "heading_ar": u.heading[:EXCERPT_LEN[work["rights"]]],
        "path_ar": list(u.path),
        "locator": _loc(witness, u.page, tag),
        "page_span": _span(u),
        "excerpt_ar": u.text[:EXCERPT_LEN[work["rights"]]],
        "sha256": u.sha256,
        "status": "candidate",
        "extraction": {"pipeline": PIPELINE, "method": "abwab"},
    }


def paragraph_record(work: dict, witness: str, bab: dict, n: int, p) -> dict:
    """The ``n``-th masʾala (``abwab.Paragraph``) of a matn unit, a child of that unit's ``bab``
    record: the parent's heading and path, the paragraph's page span, its excerpt within the work's
    rights and the sha256 receipt of the whole paragraph."""
    cap = EXCERPT_LEN[work["rights"]]
    tag = f"{bab['id'].rsplit('.', 1)[1]}.p{n:02d}"
    return {
        "id": f"{bab['id']}.p{n:02d}",
        "work": work["id"],
        "witness": witness,
        "record_type": "masala",
        "bab": bab["id"],
        "heading_ar": bab["heading_ar"],
        "path_ar": bab["path_ar"],
        "locator": _loc(witness, p.page, tag),
        "page_span": _span(p),
        "excerpt_ar": p.text[:cap],
        "sha256": p.sha256,
        "status": "candidate",
        "extraction": {"pipeline": PIPELINE, "method": "abwab_paragraphs"},
    }
