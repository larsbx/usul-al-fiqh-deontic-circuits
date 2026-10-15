"""The textual foundation: āyāt and ḥadīth the bank rests on (`corpus/nusus/foundation.json`).

Every āya is checked against the pinned muṣḥaf at its sūra and āya; every marfūʿ ḥadīth against
each pinned collection at its number, and against al-Irwāʾ for al-Albānī's verdict. Comparison
is letters-only after normalization; the stored text is never normalized. Terms of the glossary
that carry rulings cite these ids; `table_lean` emits guards tying those rulings to
`Usul.Tahara` and each cited ḥadīth to the ḥujja gate (`Usul.Seam.admitted`).
"""

from __future__ import annotations

import bisect
import json
import re
from functools import lru_cache
from pathlib import Path

from .arabic import _LETTERS, _DIACRITICS, _INVISIBLE

VERDICT = {"صحيح": "sahih", "حسن": "hasan", "ضعيف جدا": "daifJiddan", "ضعيف": "daif", "موضوع": "mawdu"}
_NUM = re.compile(r"### \|+ ([0-9٠-٩]+) -|# \((\d+)\)")
_AR_DIGITS = str.maketrans("0123456789", "٠١٢٣٤٥٦٧٨٩")


def key(s: str) -> str:
    """Letters only, normalized: the comparison key."""
    return re.sub(r"[^ء-ي]", "", _INVISIBLE.sub("", _DIACRITICS.sub("", s)).translate(_LETTERS))


@lru_cache(maxsize=16)
def _flat(text: str) -> tuple[list[int], str]:
    idx = [i for i, ch in enumerate(text) if "ء" <= ch.translate(_LETTERS) <= "ي" and not _DIACRITICS.match(ch)]
    return idx, "".join(text[i].translate(_LETTERS) for i in idx)


def find(text: str, excerpt: str) -> int | None:
    """Raw offset of the first verbatim (letters-only) occurrence."""
    idx, flat = _flat(text)
    k = flat.find(key(excerpt))
    return idx[k] if k >= 0 else None


def span(text: str, excerpt: str) -> tuple[int, int] | None:
    """Raw [start, end) of the first verbatim (letters-only) occurrence."""
    idx, flat = _flat(text)
    e = key(excerpt)
    k = flat.find(e)
    if k < 0 or not e:
        return None
    end = idx[k + len(e) - 1] + 1
    while end < len(text) and _DIACRITICS.match(text[end]):     # keep the last letter's marks
        end += 1
    return idx[k], end


QUALIFIER = re.compile(r"^[\s،,:؛.()0-9٠-٩]*(إلا|ما لم|بشرط|لكن|إن لم|بخلاف|غير أن|إذا لم)")


def cut_before_qualifier(text: str, excerpt: str) -> bool:
    """The excerpt stops where its witness goes on with an exception or condition."""
    sp = span(text, excerpt)
    return bool(sp and QUALIFIER.match(text[sp[1]:sp[1] + 40]))


def aya(quran: str, sura: int, n: int) -> str | None:
    m = re.search(rf"^{sura}\|{n}\|(.*)$", quran, re.M)
    return m.group(1) if m else None


def in_heading(text: str, pos: int) -> bool:
    """The offset falls on a heading line (a bāb title), not in a ḥadīth."""
    return text[text.rfind("\n", 0, pos) + 1:].startswith("###")


def number_at(text: str, pos: int) -> int | None:
    """The ḥadīth number under which an offset falls: the last number marker before it."""
    nums = [int((m.group(1) or m.group(2)).translate(str.maketrans("٠١٢٣٤٥٦٧٨٩", "0123456789"))) for m in _NUM.finditer(text, 0, pos)]
    return nums[-1] if nums else None


_IRWA_HEAD = re.compile(r"^# \[?\(([٠-٩]+)\)\]?\s*(?:[-ـ]\s*)?", re.M)   # «# (٦) - حديث», «# [(٢٠) - (», «# (١٤٣) (حديث»


def irwa_heads(irwa: str) -> list[tuple[int, int]]:
    """(entry number, offset) of every al-Irwāʾ entry header. Headers run in order, so the entries are
    the longest strictly increasing run of candidate headers (by offset): a cross-reference or a
    misnumbered header (Shamela prints «(٣٣٨)» for 238) is one outlier, not a reset (PR-26)."""
    cands = [(int(m.group(1).translate(str.maketrans("٠١٢٣٤٥٦٧٨٩", "0123456789"))), m.start())
             for m in _IRWA_HEAD.finditer(irwa)]
    tails: list[int] = []          # tails[k]: the candidate ending the best run of length k+1
    ends: list[int] = []           # its entry number, kept sorted for bisection
    prev = [-1] * len(cands)
    for i, (n, _) in enumerate(cands):
        k = bisect.bisect_left(ends, n)
        prev[i] = tails[k - 1] if k else -1
        tails[k:k + 1], ends[k:k + 1] = [i], [n]
    out, i = [], tails[-1] if tails else -1
    while i >= 0:
        out.append(cands[i]); i = prev[i]
    return out[::-1]


def irwa_entry(irwa: str, n: int) -> tuple[str | None, str]:
    """al-Albānī's verdict on al-Irwāʾ's entry n, and the entry's text."""
    heads = irwa_heads(irwa)
    k = next((i for i, (m, _) in enumerate(heads) if m == n), None)
    if k is None:
        return None, ""
    end = heads[k + 1][1] if k + 1 < len(heads) else heads[k][1] + 4000
    body = irwa[heads[k][1]: end]
    v = re.search(r"# \* (" + "|".join(sorted(VERDICT, key=len, reverse=True)) + ")", body)
    return (VERDICT[v.group(1)] if v else None), body


def irwa_coverage(irwa: str) -> dict:
    """Which of al-Irwāʾ's entries the pinned witness carries. Shamela 22592 has blank pages (much of
    vol. 6 onward), so some entries are absent from the source itself (problem register PR-16)."""
    found = sorted({n for n, _ in irwa_heads(irwa)})
    return {"entries_found": len(found), "last": found[-1],
            "missing": [n for n in range(1, found[-1] + 1) if n not in set(found)]}


def albani_verdict(work: str, text: str, n: int) -> tuple[str | None, str]:
    """al-Albānī's verdict on entry n of one of his pinned works, and the entry's text."""
    if work == "albani.irwa":
        return irwa_entry(text, n)
    if work == "albani.sahih_daif_tirmidhi":
        m = re.search(rf"^# {n} ", text, re.M)
        if not m:
            return None, ""
        nxt = re.search(r"^# \d+ ", text[m.end():], re.M)
        body = text[m.start(): m.end() + (nxt.start() if nxt else 4000)]
        v = re.search(r"# تحقيق الألباني:\s*\n# ([^\n،,]+)", body)
        word = v.group(1).strip() if v else ""
        tag = next((VERDICT[k] for k in sorted(VERDICT, key=len, reverse=True) if word.startswith(k)), None)
        return tag, body
    raise ValueError(work)


def load(corpus: Path) -> dict:
    return json.loads((corpus / "nusus" / "foundation.json").read_text(encoding="utf-8"))


def witnesses(corpus: Path) -> set[str]:
    """Every witness the foundation is checked against: the āyāt, athar, ḥadīth collections, al-Albānī's
    works, and the pinned al-Irwāʾ coverage. Empty when the corpus has no foundation."""
    if not (corpus / "nusus" / "foundation.json").exists():
        return set()
    f = load(corpus)
    irwa = corpus / "hadith" / "irwa_coverage.json"
    return ({x["witness"] for k in ("ayat", "athar") for x in f.get(k, [])}
            | {h["albani"]["witness"] for h in f.get("ahadith", [])}
            | {s["witness"] for h in f.get("ahadith", []) for s in h["sources"]}
            | ({json.loads(irwa.read_text(encoding="utf-8"))["witness"]} if irwa.exists() else set()))


def table_lean(foundation: dict, glossary: dict, furuq_items: list[dict] = ()) -> str:
    """Guards: each ḥadīth a term or a farq rests on passes the gate in the naṣṣ slot; each ḥadīth a
    farq names as not sound fails it; each term's rulings are the Lean ones."""
    cited = {i for t in glossary["terms"] for i in t.get("nusus", [])}
    cited |= {c for it in furuq_items if it["basis"] == "nass" for c in it.get("nusus", [])}
    rejected = {c for it in furuq_items if it["basis"] == "no_sound_hadith" for c in it.get("nusus", [])}
    lines = ["-- GENERATED by `python -m usul_corpus signature` from corpus/nusus/foundation.json and",
             "-- corpus/dossier/glossary.json. Do not edit.", "import Usul", ""]
    for h in foundation["ahadith"]:
        if h["id"] in rejected:
            lines += [f"-- {h['id']}: named not sound by al-Saʿdī; {h['albani']['work']} {h['albani']['number']}",
                      f"#guard Usul.Seam.admitted ⟨.nass, .{h['albani']['verdict']}⟩ == false"]
        if h["id"] in cited:
            lines += [f"-- {h['id']}: {', '.join(s['work'] + ' ' + str(s['number']) for s in h['sources'])}; Irwāʾ {h['albani']['number']}",
                      f"#guard Usul.Seam.admitted ⟨.nass, .{h['albani']['verdict']}⟩ == true"]
    for t in glossary["terms"]:
        for name, v in t.get("rulings", {}).items():
            lit = str(v).lower() if isinstance(v, bool) else f".{v}"
            lines += [f"-- {t['key']} ({t['ar']}): {name}", f"#guard {t['lean_value']}.{name} == {lit}"]
    return "\n".join(lines) + "\n"
