"""al-Albānī's verdicts on the maḥall anchors (PR-51).

A ḥadīth or athar anchors a maḥall label only as well as it is established. Each such anchor is
graded from al-Albānī's own works, and every grade cites its source.

The works, each with per-entry verdicts:

- his Ṣaḥīḥ wa-Ḍaʿīf of the Sunan of al-Tirmidhī, Abū Dāwūd, al-Nasāʾī and Ibn Māja: his verdict on
  every ḥadīth, in the Sunan's own numbering (``SERIES``);
- al-Irwāʾ al-Ghalīl, his takhrīj of the Ḥanbalī *Manār al-Sabīl*;
- Ṣaḥīḥ Abī Dāwūd and Ḍaʿīf Abī Dāwūd (al-Umm, his numbering).

An entry grades an anchor when the ḥadīth it is about (its head, before his verdict line) holds the
anchor's excerpt. It is found by wording (letters only, at least ``MIN`` letters), or by the anchor's
number in its own Sunan (``grade``).

A matn may be found in several entries. In his Sunan books al-Albānī grades each route (riwāya)
apart, and in al-Irwāʾ the ḥadīth with all its routes: a ḥadīth established by any route he grades
ṣaḥīḥ or ḥasan is established. The verdict is therefore the strongest he gives any entry that holds
the wording; the anchor's own collection's works are preferred among equals, then al-Irwāʾ. His weaker
verdicts on other routes are kept beside it (``weaker_routes``). An anchor of the Ṣaḥīḥayn that no
work grades ṣaḥīḥ or ḥasan keeps the Ṣaḥīḥayn's own standing (``sahihayn``, citing its ḥadīth there),
which is not a verdict of his: a weak verdict of his found by wording is on another collection's
route, and is kept as a weaker route. An athar the Ṣaḥīḥayn quote has no such standing.

In ``corpus/mahall/labels/all.json`` every ḥadīth, athar and ijmāʿ anchor carries ``number``, its
ḥadīth (or the Mughnī's masʾala) in its witness; a graded anchor ``albani: {work, witness, number,
verdict}``. ``test_mahall_grades.py`` re-reads every cited entry and number.
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
         "albani.daif_abi_dawud": "shamela-5914",
         "albani.sahih_daif_abi_dawud": "shamela-epub-1755",
         "albani.sahih_daif_nasai": "shamela-epub-783",
         "albani.sahih_daif_ibn_maja": "shamela-epub-810",
         nusus.MUKHTASAR: "shamela-121381"}
# The Ṣaḥīḥ wa-Ḍaʿīf Sunan work numbered as each Sunan witness is.
SERIES = {"openiti-tirmidhi-shamela7895": "albani.sahih_daif_tirmidhi",
          "openiti-abudawud-shamela1726": "albani.sahih_daif_abi_dawud",
          "openiti-nasai-shamela829": "albani.sahih_daif_nasai",
          "openiti-ibnmaja-shamela1198": "albani.sahih_daif_ibn_maja"}
OWN = {"openiti-abudawud-shamela1726": ("albani.sahih_abi_dawud", "albani.daif_abi_dawud", "albani.sahih_daif_abi_dawud")} | \
      {w: (s,) for w, s in SERIES.items() if w != "openiti-abudawud-shamela1726"}
# His takhrīj of the athar a collection quotes, consulted for that collection's athar only.
ATHAR = {"openiti-bukhari-shamela1681": nusus.MUKHTASAR}
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
    if work in nusus.SERIES:
        return [(int(m.group(1)), m.start()) for m in nusus.SERIES_HEAD.finditer(body)]
    if work == nusus.MUKHTASAR:
        return sorted(((n, at) for n, (at, _) in nusus.mukhtasar_notes(body).items()), key=lambda h: h[1])
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


VERDICT_LINE = {"albani.irwa": r"^# \* ", "albani.sahih_abi_dawud": r"\(قلت: ", "albani.daif_abi_dawud": r"\(قلت: "} | \
               dict.fromkeys(nusus.SERIES, r"تحقيق الألباني") | {nusus.MUKHTASAR: r"^# \[هامش\]"}


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


def holds(work: str, body: str, n: int, excerpt: str) -> str | None:
    """al-Albānī's verdict on entry n, if the ḥadīth it grades holds the excerpt."""
    verdict, entry = nusus.albani_verdict(work, body, n)
    return verdict if nusus.key(excerpt) in nusus.key(head(work, entry)) else None


def agreed(own: str, work: str, body: str, excerpt: str) -> str | None:
    """His one verdict on every ḥadīth of a Sunan that holds a (short) excerpt, or None: where the
    wording recurs, the anchor's number may not single out its ḥadīth, but one verdict on them all
    is the anchor's whichever it is."""
    vs = {holds(work, body, nusus.number_at(own, o), excerpt) for o in occurrences(own, excerpt)}
    return vs.pop() if len(vs) == 1 else None


def cite(w: str, n: int, v: str) -> dict:
    return {"work": w, "witness": WORKS[w], "number": n, "verdict": v}


def grade(nass: dict, cache_dir: Path) -> dict:
    """``{"albani": cite, "weaker_routes"?: [cite]}``, ``{"sahihayn": {witness, number}}`` or
    ``{"ungraded": reason}``. Every grade cites its source: the entry of al-Albānī's work, or the
    ḥadīth of the Ṣaḥīḥayn.

    Two routes find his entries. By wording: every entry of his works whose ḥadīth holds an excerpt of
    at least ``MIN`` letters. By number: the anchor's own Sunan's entry in his Ṣaḥīḥ wa-Ḍaʿīf of it,
    numbered as the Sunan is, when that entry's ḥadīth holds the excerpt; a short excerpt goes by
    number only when he grades alike every ḥadīth of the Sunan that holds it (``agreed``)."""
    witness = mahall.REF.fullmatch(nass["ref"])[1]
    excerpt, own = nass["excerpt_ar"], text(cache_dir, witness)
    longer = len(nusus.key(excerpt)) >= MIN
    first = OWN.get(witness, ()) + ((ATHAR[witness],) if nass["kind"] == "athar" and witness in ATHAR else ())
    order = first + tuple(w for w in WORKS if w not in first and w not in ATHAR.values())
    found = [(w, n, v) for w in order if longer for n, v in entries(w, text(cache_dir, WORKS[w]), excerpt) if v]
    if (s := SERIES.get(witness)) and (v := holds(s, text(cache_dir, WORKS[s]), nass["number"], excerpt)) \
            and (longer or agreed(own, s, text(cache_dir, WORKS[s]), excerpt) == v) and (s, nass["number"], v) not in found:
        found.append((s, nass["number"], v))
    sahihayn = witness in SAHIHAYN and nass["kind"] == "sunnah"    # their Prophetic ḥadīth, not an athar they quote
    best = max(found, key=lambda f: RANK[f[2]], default=None)      # the first among the strongest
    if best and not (sahihayn and best[2] not in HUJJA):
        weaker = [cite(x, m, u) for x, m, u in found if RANK[u] < RANK[best[2]]]
        return {"albani": cite(*best), **({"weaker_routes": weaker} if weaker else {})}
    if sahihayn:            # his verdict on another collection's route is not on theirs
        weaker = [cite(*f) for f in found]
        return {"sahihayn": {"witness": witness, "number": nass["number"]}, **({"weaker_routes": weaker} if weaker else {})}
    if longer and (silent := [n for w in first if w in ATHAR.values() for n, _ in entries(w, text(cache_dir, WORKS[w]), excerpt)]):
        return {"ungraded": f"al-Albānī's note on it in his Mukhtaṣar al-Bukhārī ({', '.join(map(str, silent))}) gives no verdict"}
    if longer:
        return {"ungraded": "no entry of al-Albānī's pinned works holds the excerpt"}
    if not SERIES.get(witness):
        return {"ungraded": f"excerpt under {MIN} letters: too short to identify an entry"}
    if holds(SERIES[witness], text(cache_dir, WORKS[SERIES[witness]]), nass["number"], excerpt):
        return {"ungraded": f"excerpt under {MIN} letters, in ḥadīth of its Sunan he grades differently"}
    return {"ungraded": f"excerpt under {MIN} letters, not in his entry of its number"}


def hujja(nass: dict) -> bool:
    """The naṣṣ is proof: the Qurʾān, a reported ijmāʿ, a ḥadīth of the Ṣaḥīḥayn no work of his
    grades, or one al-Albānī grades ṣaḥīḥ or ḥasan."""
    if nass["kind"] in ("quran", "ijma"):
        return True
    return bool(nass.get("sahihayn")) or nass.get("albani", {}).get("verdict") in HUJJA


def witnesses(corpus: Path) -> set[str]:
    """Every al-Albānī witness grading reads (required, so CI fetches them: replaying the grades reads
    them all). Empty when the corpus has no maḥall layer."""
    return set(WORKS.values()) if (corpus / mahall.DIR / "abwab.json").exists() else set()
