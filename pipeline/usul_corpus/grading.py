"""al-Albānī's verdicts on the maḥall anchors (PR-51).

A ḥadīth or athar anchors a maḥall label only as well as it is established. Each such anchor is
graded from al-Albānī's own works, by its wording: the entries of his works that contain the
anchor's excerpt (letters only, at least ``MIN`` letters) give his verdict on that ḥadīth.

The works, each with per-entry verdicts:

- Ṣaḥīḥ wa-Ḍaʿīf Sunan al-Tirmidhī (al-Tirmidhī's text, his verdict on each number);
- al-Irwāʾ al-Ghalīl, his takhrīj of the Ḥanbalī *Manār al-Sabīl*;
- Ṣaḥīḥ Abī Dāwūd and Ḍaʿīf Abī Dāwūd (his numbering).

A matn may be found in several entries. In his Sunan books al-Albānī grades each route (riwāya)
apart, and in al-Irwāʾ the ḥadīth with all its routes: a ḥadīth established by any route he grades
ṣaḥīḥ or ḥasan is established. The verdict is therefore the strongest he gives any entry that holds
the wording; the anchor's own collection's work is preferred among equals, then al-Irwāʾ. His weaker
verdicts on other routes are kept beside it (``weaker_routes``). An anchor of the Ṣaḥīḥayn that no
work grades keeps the Ṣaḥīḥayn's own standing (``sahihayn``), which is not a verdict of his; so does
one whose excerpt is too short to find in his works. An athar the Ṣaḥīḥayn quote does not.

Each graded anchor carries ``albani: {work, witness, number, verdict}`` in
``corpus/mahall/labels/all.json``. ``test_mahall_grades.py`` re-reads every entry: the verdict is
his, and the ḥadīth the entry grades (its head, before his verdict line) holds the excerpt.
"""

from __future__ import annotations

import bisect
import re
from functools import cache
from pathlib import Path

from . import mahall, nusus

WORKS = {"albani.sahih_daif_tirmidhi": "openiti-albani-sdtirmidhi-shamela782",
         "albani.irwa": "shamela-22592",
         "albani.sahih_abi_dawud": "shamela-25881",
         "albani.daif_abi_dawud": "shamela-5914"}
OWN = {"openiti-tirmidhi-shamela7895": ("albani.sahih_daif_tirmidhi",),
       "openiti-abudawud-shamela1726": ("albani.sahih_abi_dawud", "albani.daif_abi_dawud")}
SAHIHAYN = {"openiti-bukhari-shamela1681", "openiti-muslim-shamela1727"}
HUJJA = {"sahih", "hasan"}
MIN = 15


@cache
def text(cache_dir: Path, witness: str) -> str:
    return (cache_dir / f"{witness}.txt").read_text(encoding="utf-8")


@cache
def heads(work: str, body: str) -> list[tuple[int, int]]:
    """(entry number, offset) of every entry of an al-Albānī work, in offset order."""
    if work == "albani.irwa":
        return nusus.irwa_heads(body)
    if work == "albani.sahih_daif_tirmidhi":
        return [(int(m.group(1)), m.start()) for m in re.finditer(r"^# (\d+) ", body, re.M)]
    return nusus.dawud_heads(body)


def occurrences(body: str, excerpt: str) -> list[int]:
    """Raw offsets of every letters-only occurrence of the excerpt."""
    idx, flat = nusus._flat(body)
    k, out = nusus.key(excerpt), []
    i = flat.find(k)
    while i >= 0:
        out.append(idx[i])
        i = flat.find(k, i + 1)
    return out


VERDICT_LINE = {"albani.irwa": r"^# \* ", "albani.sahih_daif_tirmidhi": r"تحقيق الألباني",
                "albani.sahih_abi_dawud": r"\(قلت: ", "albani.daif_abi_dawud": r"\(قلت: "}


def head(work: str, entry: str) -> str:
    """The ḥadīth an entry grades: its text up to al-Albānī's verdict line. The rest of an entry is his
    takhrīj, which quotes other narrations his verdict is not on."""
    m = re.search(VERDICT_LINE[work], entry, re.M)
    return entry[: m.start()] if m else entry


def entries(work: str, body: str, excerpt: str) -> list[tuple[int, str | None]]:
    """(entry number, verdict) of each entry of ``work`` whose head holds the excerpt."""
    hs = heads(work, body)
    at = [p for _, p in hs]
    near = {hs[i][0] for o in occurrences(body, excerpt) if (i := bisect.bisect_right(at, o) - 1) >= 0}
    k = nusus.key(excerpt)
    out = []
    for n in sorted(near):
        verdict, entry = nusus.albani_verdict(work, body, n)
        if k in nusus.key(head(work, entry)):
            out.append((n, verdict))
    return out


RANK = {"mawdu": 0, "daifJiddan": 1, "daif": 2, "hasan": 3, "sahih": 4}   # Hadith.Verdict.rank


def grade(nass: dict, cache_dir: Path) -> dict:
    """``{"albani": {...}, "weaker_routes"?: [...]}``, ``{"sahihayn": True}`` or ``{"ungraded": reason}``."""
    witness = mahall.REF.fullmatch(nass["ref"])[1]
    # The Ṣaḥīḥayn's standing is that of their Prophetic ḥadīth, not of the athar they quote.
    sahihayn = witness in SAHIHAYN and nass["kind"] == "sunnah"
    if len(nusus.key(nass["excerpt_ar"])) < MIN:
        return {"sahihayn": True} if sahihayn else \
            {"ungraded": f"excerpt under {MIN} letters: too short to identify an entry"}
    order = OWN.get(witness, ()) + tuple(w for w in WORKS if w not in OWN.get(witness, ()))
    found = [(w, n, v) for w in order for n, v in entries(w, text(cache_dir, WORKS[w]), nass["excerpt_ar"]) if v]
    if found:
        w, n, v = max(found, key=lambda f: RANK[f[2]])          # the first among the strongest
        weaker = [{"work": x, "number": m, "verdict": u} for x, m, u in found if RANK[u] < RANK[v]]
        return {"albani": {"work": w, "witness": WORKS[w], "number": n, "verdict": v},
                **({"weaker_routes": weaker} if weaker else {})}
    if sahihayn:
        return {"sahihayn": True}
    return {"ungraded": "no entry of al-Albānī's pinned works contains the excerpt"}


def hujja(nass: dict) -> bool:
    """The naṣṣ is proof: the Qurʾān, a reported ijmāʿ, a ḥadīth of the Ṣaḥīḥayn no work of his
    grades, or one al-Albānī grades ṣaḥīḥ or ḥasan."""
    if nass["kind"] in ("quran", "ijma"):
        return True
    return bool(nass.get("sahihayn")) or nass.get("albani", {}).get("verdict") in HUJJA


def witnesses(corpus: Path) -> set[str]:
    """The al-Albānī witnesses the committed grades cite (required, so CI fetches them). Empty when
    the corpus has no maḥall layer."""
    if not (corpus / mahall.DIR / "abwab.json").exists():
        return set()
    return {n["albani"]["witness"] for l in mahall.load(corpus)[1] for n in l.get("nass", []) if "albani" in n}
