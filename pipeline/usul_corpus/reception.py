"""Reception: how often the modern citers (Ibn Bāz, Ibn ʿUthaymīn, al-Albānī, al-Saʿdī) cite each registered work.

A cited work declares its citation forms (``reception.cite_as``) and the longer phrases that shadow
them (``reception.not``). Matching runs on normalised text, page by page:

* a single-word form («المغني») counts only after a citation cue (في, صاحب, كتاب, انظر …);
* a multi-word form («زاد المعاد») counts as written;
* overlapping hits resolve leftmost-longest, so each span counts once and an exclusion that covers
  a title (الذهبي في المغني) silences it; on an identical span a named work beats an exclusion.

A second pass counts author mentions from ``corpus/reception/authors.json`` the same way, except that
a single-word form (النووي) needs no cue.

The counts are evidence for the corpus selection, not a bibliometric truth: forms are heuristic,
and each work keeps a few page locators so a reviewer can spot-check its hits.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Iterable

from .arabic import normalize

_PAGE = re.compile(r"(PageV\d+P\d+)")
_MARKUP = re.compile(r"~~|\bms\d+\b|^#+\s*\|*\s*", re.M)
_CUE = "(?:" + "|".join(map(normalize, ("في", "صاحب", "كتاب", "كتابه", "انظر", "ينظر", "راجع"))) + ")"
_QUOTES = re.compile(r"[«»\"“”'()\[\]{}﴿﴾:]")

Hit = tuple[str, "str | None"]  # (cited work, closing page marker)


@dataclass(frozen=True)
class Cited:
    work: str
    cite_as: tuple[str, ...]
    shadowed_by: tuple[str, ...] = ()


def pages(text: str) -> tuple[tuple[str | None, str], ...]:
    """(closing page marker, plain text) per page; OpenITI markers close the page they follow."""
    body = text.split("#META#Header#End#", 1)[-1]
    parts = _PAGE.split(body)
    plain = lambda s: " ".join(_MARKUP.sub("", s).split())
    pairs = [(parts[i + 1] if i + 1 < len(parts) else None, plain(parts[i])) for i in range(0, len(parts), 2)]
    return tuple((loc, t) for loc, t in pairs if t)


def _pattern(form: str, cue: bool) -> re.Pattern[str]:
    title = r"\s+".join(map(re.escape, normalize(form).split()))
    lead = rf"[وف]?{_CUE}\s*" if cue else "و?"
    return re.compile(rf"(?<!\w){lead}(?P<t>{title})(?!\w)")


Span = tuple[int, int, "str | None"]  # [start, end) in normalised text; None = a shadowing phrase


def plain(text: str) -> str:
    """The normalised text that matching runs on (and that span offsets index)."""
    return normalize(_QUOTES.sub(" ", text))


def _compile(cited: Iterable[Cited], cue_single: bool) -> list[tuple[str | None, re.Pattern[str]]]:
    cited = tuple(cited)
    return ([(c.work, _pattern(f, cue_single and len(f.split()) == 1)) for c in cited for f in c.cite_as]
            + [(None, _pattern(f, False)) for c in cited for f in c.shadowed_by])


def resolve(found: Iterable[Span]) -> tuple[Span, ...]:
    """Leftmost-longest; on an identical span a named work beats a shadowing phrase."""
    kept: list[Span] = []
    for s, e, w in sorted(found, key=lambda x: (x[0], -x[1], x[2] is None, x[2] or "")):
        if not kept or s >= kept[-1][1]:
            kept.append((s, e, w))
    return tuple(kept)


def _spans(t: str, pats: list[tuple[str | None, re.Pattern[str]]]) -> tuple[Span, ...]:
    return resolve((m.start("t"), m.end("t"), w) for w, p in pats for m in p.finditer(t))


def spans(text: str, cited: Iterable[Cited], cue_single: bool = True) -> tuple[Span, ...]:
    """Resolved spans over ``plain(text)``, shadowing phrases included."""
    return _spans(plain(text), _compile(cited, cue_single))


def matcher(cited: Iterable[Cited], cue_single: bool = True) -> Callable[[str], tuple[str, ...]]:
    """text → the works (or authors) it names, in reading order. With ``cue_single=False`` a
    single-word form counts as written (author nisbas: النووي)."""
    pats = _compile(cited, cue_single)
    return lambda text: tuple(w for _, _, w in _spans(plain(text), pats) if w is not None)


def lexicon(works: Iterable[dict]) -> tuple[Cited, ...]:
    """The title lexicon of the registry's cited works."""
    return tuple(Cited(w["id"], tuple(w["reception"]["cite_as"]), tuple(w["reception"].get("not", ())))
                 for w in works if w.get("reception", {}).get("role") == "cited")


def authors(path: Path) -> tuple[Cited, ...]:
    """The author lexicon (``corpus/reception/authors.json``)."""
    data = json.loads(path.read_text(encoding="utf-8"))
    return tuple(Cited(a["id"], tuple(a["cite_as"]), tuple(a.get("not", ()))) for a in data["authors"])


def citations(text: str, match: Callable[[str], tuple[str, ...]]) -> tuple[Hit, ...]:
    return tuple((w, loc) for loc, body in pages(text) for w in match(body))


def report(hits: dict[str, tuple[Hit, ...]], scholar: dict[str, str], samples: int = 3) -> dict[str, dict]:
    """Per cited work: total, by scholar, by witness, and the first ``samples`` locators."""
    out: dict[str, dict] = {}
    for wit in sorted(hits):
        for work, loc in hits[wit]:
            c = out.setdefault(work, {"total": 0, "by_scholar": {}, "by_witness": {}, "sample": []})
            c["total"] += 1
            c["by_scholar"][scholar[wit]] = c["by_scholar"].get(scholar[wit], 0) + 1
            c["by_witness"][wit] = c["by_witness"].get(wit, 0) + 1
            if len(c["sample"]) < samples:
                c["sample"].append(f"src:{wit}" + (f"/{loc}" if loc else ""))
    return {w: {**c, "by_scholar": dict(sorted(c["by_scholar"].items()))} for w, c in sorted(out.items())}


def _role(works: list[dict], role: str) -> list[dict]:
    return [w for w in works if w.get("reception", {}).get("role") == role]


def build(registry: dict, cache: Path, author_lexicon: tuple[Cited, ...]) -> dict:
    """The committed reception report: title and author counts over every cached citer witness."""
    titles = lexicon(registry["works"])
    citers = {x["id"]: (w, cache / f"{x['id']}.txt") for w in _role(registry["works"], "citer") for x in w["witnesses"]}
    present = {wid: (w, p.read_text(encoding="utf-8")) for wid, (w, p) in citers.items() if p.exists()}
    scholar = {wid: w["reception"]["scholar"] for wid, (w, _) in present.items()}
    zero = {"total": 0, "by_scholar": {}, "by_witness": {}, "sample": []}

    def count(lex: tuple[Cited, ...], cue_single: bool) -> dict[str, dict]:
        match = matcher(lex, cue_single)
        counts = report({wid: citations(text, match) for wid, (_, text) in present.items()}, scholar)
        return {c.work: counts.get(c.work, zero) for c in sorted(lex, key=lambda c: c.work)}

    return {
        "method": __doc__.strip().split("\n\n")[1],
        "citers": {wid: {"work": w["id"], "scholar": w["reception"]["scholar"], "pages": len(pages(text))}
                   for wid, (w, text) in sorted(present.items())},
        "missing": sorted(set(citers) - set(present)),
        "counts": count(titles, True),
        "authors": count(author_lexicon, False),
    }


SCHOLARS = {"ibn_baz": "Ibn Bāz", "ibn_uthaymin": "Ibn ʿUthaymīn", "albani": "al-Albānī", "sadi": "al-Saʿdī"}


def render_counts(rep: dict, titles: dict[str, tuple[str, str]]) -> str:
    """The committed report as a Markdown page; ``titles`` maps work id → (title, genre)."""
    cols = " | ".join(SCHOLARS.values())
    row = lambda w, c: (f"| {titles[w][0]} | `{w}` | {titles[w][1]} | {c['total']} | "
                        + " | ".join(str(c["by_scholar"].get(s, "")) for s in SCHOLARS)
                        + f" | {' '.join(f'`{x}`' for x in c['sample'])} |")
    ranked = lambda counts: sorted(counts.items(), key=lambda kv: (-kv[1]["total"], kv[0]))
    citers = [f"| {titles[c['work']][0]} | `{w}` | {SCHOLARS[c['scholar']]} | {c['pages']} |" for w, c in rep["citers"].items()]
    return "\n".join([
        "<!-- GENERATED by `python -m usul_corpus docs` from corpus/reception/report.json. Do not edit. -->", "",
        "# Reception counts", "",
        "How often each cited work is named in the citers' own texts; method in [`reception.md`](reception.md).", "",
        "## Citer witnesses", "", "| Work | Witness | Scholar | Pages |", "|---|---|---|---|", *citers, "",
        *([f"Not cached when the report was built: {', '.join(f'`{m}`' for m in rep['missing'])}.", ""] if rep["missing"] else []),
        "## Cited works", "", f"| Work | Id | Genre | Total | {cols} | Sample hits |",
        "|---|---|---|---:|" + "---:|" * len(SCHOLARS) + "---|", *(row(w, c) for w, c in ranked(rep["counts"])), "",
        "## Cited authors", "", "Mentions by name (قال النووي, شيخ الإسلام ابن تيمية), counted separately from titles.", "",
        f"| Author | Id | | Total | {cols} | Sample hits |",
        "|---|---|---|---:|" + "---:|" * len(SCHOLARS) + "---|", *(row(w, c) for w, c in ranked(rep.get("authors", {}))), "",
    ])
