"""Candidate training labels for IslamQA answers: ḥukm taklīfī, validity, domain, split.

Labels are lexical and auditable: every ``hukm`` names the text it was read from
(``basis``) and the cue span (``evidence``). They are candidates for review, not
rulings. ``hukm`` values are the constructors of ``Usul.Hukm`` (formal/lean/Usul/Hukm.lean).

Reading order per answer: the site's own summary (ملخص الجواب), else a closing
«الحاصل / الخلاصة» paragraph, else the opening lines. The first affirmative cue
there is the label; other statuses in the same passage are kept in ``also``.
"""

from __future__ import annotations

import hashlib
import re
from collections import Counter
from collections.abc import Mapping

HUKM = ("wajib", "mandub", "mubah", "makruh", "haram")

_TASHKEEL = re.compile(r"[ً-ْٰـ]")
_ALEF = str.maketrans("إأآ", "ااا")
_L = r"ء-ي"
_PRE = rf"(?:(?<![{_L}])|(?<=(?<![{_L}])[وف]))"  # word start, optionally after و/ف
_SUF = r"(?:ه|ها|هم|هما|ك|كم|كما|هن)?"            # attached object pronoun
_END = rf"(?![{_L}])"
_NEG = r"(?:لا|لم|لن)\s+"

# (hukm, polarity, pattern) — negated forms first, so they claim their span before
# the positive form inside them ("لا يجوز" before "يجوز"). Polarity "-" casts no vote.
LEXICON: tuple[tuple[str, str, str], ...] = (
    ("haram", "+", r"لا\s+[يت]جوز"), ("haram", "+", r"لم\s+[يت]جز"), ("haram", "+", _NEG + r"[يت]حل"), ("haram", "+", r"لا\s+يباح"),
    ("haram", "-", _NEG + r"[يت]حرم"), ("haram", "-", r"ليس(?:ت)?\s+(?:بحرام|حراما|بمحرم(?:ة)?|محرما|محرمة)"), ("haram", "-", r"غير\s+محرم(?:ة)?"),
    ("wajib", "-", _NEG + r"[يت]جب"), ("wajib", "-", r"ليس(?:ت)?\s+بواجب(?:ة)?"),
    ("wajib", "-", _NEG + r"[يت]لزم" + _SUF), ("wajib", "-", r"غير\s+واجب(?:ة)?"),
    ("makruh", "-", _NEG + r"[يت]كره"), ("makruh", "-", r"(?:ليس(?:ت)?|ولا|لا)\s+(?:بمكروه(?:ة)?|مكروها|مكروهة)"),
    ("mubah", "+", r"لا\s+حرج"), ("mubah", "+", r"لا\s+باس"), ("mubah", "+", r"لا\s+مانع"),
    ("haram", "+", r"[يت]حرم"), ("haram", "+", r"حرام"), ("haram", "+", r"محرم(?:ة|ات)?"),
    ("haram", "+", r"من\s+الكبائر"), ("haram", "+", r"كراهة\s+تحريم"),
    ("wajib", "+", r"[يت]جب"), ("wajib", "+", r"وجب"), ("wajib", "+", r"واجب(?:ة)?"),
    ("wajib", "+", r"[يت]لزم" + _SUF), ("wajib", "+", r"فرض\s+(?:عين|كفاية)"), ("wajib", "+", r"[يت]تعين"),
    ("mandub", "+", r"[يت]ستحب"), ("mandub", "+", r"مستحب(?:ة|ات)?"), ("mandub", "+", r"[يت]سن"),
    ("mandub", "+", r"مسنون(?:ة)?"), ("mandub", "+", r"مندوب(?:ة)?"), ("mandub", "+", r"سنة\s+مؤكدة"),
    ("mandub", "+", r"من\s+السنة\s+ان"), ("mandub", "+", r"الافضل\s+(?:ان|لك|له|لها|لكم)"),
    ("makruh", "+", r"[يت]كره\s+(?:ان|ذلك|هذا|فعل)"), ("makruh", "+", r"كراهة\s+تنزيه"), ("makruh", "+", r"مكروه(?:ة)?(?!\s+ال)"),
    ("mubah", "+", r"[يت]جوز"), ("mubah", "+", r"جائز(?:ة)?"), ("mubah", "+", r"مباح(?:ة)?"),
    ("mubah", "+", r"[يت]باح"), ("mubah", "+", r"حلال"),
)
_ACTS = r"(?:صلا|صيام|صوم|حج|عمر|عقد|بيع|نكاح|زواج|طلاق|وضوء|غسل|طهار)"
WAD: tuple[tuple[str, str], ...] = (
    ("batil", r"لا\s+[يت]صح\s+(?:ال)?" + _ACTS), ("batil", r"لا\s+[يت]جزئ"),
    ("batil", _ACTS + rf"[{_L}]*\s+(?:باطل|فاسد)(?:ة)?"), ("batil", r"[يت]بطل"),
    ("sahih", _ACTS + rf"[{_L}]*\s+صحيح(?:ة)?"), ("sahih", r"[يت]جزئ"),
)
_RX = [(h, p, re.compile(_PRE + pat + _END)) for h, p, pat in LEXICON]
_WRX = [(w, re.compile(_PRE + pat + _END)) for w, pat in WAD]
_CONCLUSION = re.compile(r"^\s*[وف]?(?:ال)?(?:حاصل|خلاصة)")
_HAMDALA = re.compile(r"^\s*الحمد لله\.?")
_COND = re.compile(_PRE + r"(?:الا\s+اذا|الا\s+ان|ان\s+كان|اذا\s+كان|بشرط)")
_GENERIC = {"الفقه"}


def normalize_ar(s: str) -> str:
    return _TASHKEEL.sub("", s).translate(_ALEF)


def _spans(rx: list, text: str) -> list[tuple[int, int, tuple]]:
    """Non-overlapping matches, earlier patterns claiming first, in text order."""
    taken: list[tuple[int, int, tuple]] = []
    for *tag, r in rx:
        for m in r.finditer(text):
            if all(m.end() <= s or m.start() >= e for s, e, _ in taken):
                taken.append((m.start(), m.end(), tuple(tag)))
    return sorted(taken)


_QUESTION = re.compile(rf"{_PRE}هل(?:\s+[{_L}]+){{0,3}}\s*$")


def cues(text: str) -> list[dict]:
    """Ruling cues in text order; a cue inside a «هل …» question is not a ruling."""
    t = normalize_ar(text)
    return [{"hukm": h, "polarity": p, "start": s, "end": e, "text": t[s:e]}
            for s, e, (h, p) in _spans(_RX, t) if not _QUESTION.search(t[max(0, s - 40):s])]


def _lines(text: str | None) -> list[str]:
    return [l for l in _HAMDALA.sub("", normalize_ar(text or "")).splitlines() if l.strip()]


def _passages(rec: Mapping) -> list[tuple[str, str]]:
    """(basis, text) in reading order: summary, conclusion, lead."""
    body = _lines(rec.get("answer"))
    concl = next((i for i, l in enumerate(body) if _CONCLUSION.match(l)), None)
    found = [("summary", "\n".join(_lines(rec.get("summary")))),
             ("conclusion", "\n".join(body[concl:concl + 3]) if concl is not None else ""),
             ("lead", "\n".join(body[:3]))]
    return [(b, t) for b, t in found if t]


def split_of(ref: int) -> str:
    """80/10/10 by hash of the site-wide answer number: one split for every language."""
    n = int(hashlib.sha1(str(ref).encode()).hexdigest(), 16) % 100
    return "train" if n < 80 else "dev" if n < 90 else "test"


def _domain(rec: Mapping) -> tuple[str | None, str | None]:
    path = next((t["path"] for t in rec.get("topics") or []), [])
    rest = [p for p in path[1:] if p not in _GENERIC]
    return (path[0] if path else None), (rest[0] if rest else None)


def label(rec: Mapping) -> dict:
    ref = int(str(rec["id"]).rsplit(".", 1)[-1])
    passages = _passages(rec)
    hit = next(((b, t, cs) for b, t in passages if (cs := [c for c in cues(t) if c["polarity"] == "+"])), None)
    domain, chapter = _domain(rec)
    out = {"id": rec["id"], "split": split_of(ref), "domain": domain, "chapter": chapter,
           "hukm": None, "basis": None, "conditional": False, "also": [], "evidence": None,
           "wad": [], "status": "candidate"}
    if passages:
        out["wad"] = list(dict.fromkeys(w for _, _, (w,) in _spans(_WRX, passages[0][1])))
    if hit:
        basis, text, cs = hit
        first = cs[0]
        also = list(dict.fromkeys(c["hukm"] for c in cs if c["hukm"] != first["hukm"]))
        out |= {"hukm": first["hukm"], "basis": basis, "also": also,
                "conditional": bool(also) or bool(_COND.search(text)),
                "evidence": {"cue": first["text"], "passage": text[max(0, first["start"] - 150):first["end"] + 250]}}
    return out


def report(labels: list[Mapping]) -> dict:
    """Label counts: overall, by basis, by split."""
    def count(xs) -> dict:
        return dict(sorted(Counter(xs).items(), key=lambda kv: -kv[1]))

    by_basis = {b: count(l["hukm"] for l in labels if l["basis"] == b) for b in ("summary", "conclusion", "lead")}
    return {
        "total": len(labels),
        "labelled": sum(l["hukm"] is not None for l in labels),
        "hukm": count(l["hukm"] or "unlabelled" for l in labels),
        "hukm_by_basis": {b: c for b, c in by_basis.items() if c},
        "conditional": sum(l["conditional"] for l in labels),
        "wad": count(w for l in labels for w in l["wad"]),
        "split": count(l["split"] for l in labels),
    }


def review_sample(labels: list[Mapping], titles: Mapping[str, str], per_class: int = 25) -> list[dict]:
    """Stratified, order-independent sample per candidate class (plus unlabelled), with an empty gold slot."""
    key = lambda l: hashlib.sha1(l["id"].encode()).hexdigest()  # noqa: E731
    out = []
    for h in (*HUKM, None):
        for l in sorted((l for l in labels if l["hukm"] == h), key=key)[:per_class]:
            ev = l["evidence"] or {}
            out.append({"id": l["id"], "title": titles[l["id"]], "candidate": h, "basis": l["basis"],
                        "cue": ev.get("cue"), "passage": ev.get("passage"), "gold": None, "note": None})
    return out
