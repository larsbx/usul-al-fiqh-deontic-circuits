"""The ``abwab`` segmenter: the kitāb › bāb › faṣl units of a matn.

A heading's rank comes from its first word («كتاب», «باب», «فصل»), not its mARkdown level, since
witnesses disagree on levels (*Zād* puts all at «|», *al-Muqniʿ* nests them). Any other heading
(«الشرط الأول», «مقدمة» …) ranks as a faṣl. A body line beginning with the word «فصل» also opens a
faṣl, as *Zād*, *Muntahā* and *al-Iqnāʿ* print them. «مدخل» and headings without letters are
Shamela navigation, not openings; a heading that is only a rank word («باب») takes the next heading
as its title. A heading matching the work's ``end`` pattern closes the matn, so an editor's closing
matter and bibliography are not absorbed by its last faṣl. With ``body_headings``, a witness that prints its
headings as body lines (*al-Ghurar al-Naqiyya*: «# كتاب الطهارة», «# باب المياه») opens a unit at a
short body line beginning «كتاب» or «باب», and ``end`` is matched on body lines too, since such a
witness also prints the marker of its closing endnotes as one. A unit runs from one opening to the next and carries its path: the titles
of the kitāb and bāb it sits in. Text before the first kitāb or bāb is front matter, and a heading
with no text of its own is a unit of no text: both are dropped, though the heading stays in the path.
Lines and pages are cleaned as in ``qa`` (OpenITI: a page marker closes its page).

The unit is a routing unit for R2 (docs/roadmap-parallel-derivation.md, Part II): it fixes where a
masʾala of the matn sits. Splitting a unit into its masāʾil is a later step.
"""

from __future__ import annotations

import hashlib
import re
from dataclasses import dataclass

from .qa import Page, _lines

_TAG = re.compile(r"^(?:(?:AUTO|CHECK|EDITOR)\|?\s*)+")
_RANK = re.compile(r"^(كتاب|باب|فصل)(?![^\W\d_])")  # the word itself: «فصلت» is not «فصل»
_RANKS = {"كتاب": "kitab", "باب": "bab", "فصل": "fasl"}
_LETTER = re.compile(r"[^\W\d_]")
_BODY_TITLE_WORDS = 6  # longest body heading in al-Ghurar al-Naqiyya; a longer line is prose


@dataclass(frozen=True)
class Bab:
    heading: str
    rank: str
    path: tuple[str, ...]
    text: str
    page: Page | None
    end_page: Page | None

    @property
    def sha256(self) -> str:
        return hashlib.sha256(self.text.encode()).hexdigest()


def _navigation(line: str) -> bool:
    return line == "مدخل" or not _LETTER.search(line)


def _matn(text: str, end: str | None, body_headings: bool = False) -> list[tuple[str, Page | None, bool]]:
    """The cleaned lines up to the end heading, navigation dropped and bare rank headings titled."""
    out: list[tuple[str, Page | None, bool]] = []
    for line, page, heading in _lines(text):
        line = _TAG.sub("", line) if heading else line
        if (heading or body_headings) and end and re.search(end, line):
            break
        if heading and _navigation(line):
            continue
        if heading and out and out[-1][2] and out[-1][0] in _RANKS and not _RANK.match(line):
            out[-1] = (f"{out[-1][0]} {line}", out[-1][1], True)
        else:
            out.append((line, page, heading))
    return out


def _opening(line: str, heading: bool, body_headings: bool = False) -> tuple[str, str] | None:
    """(heading, rank) when the line opens a unit."""
    m = _RANK.match(line)
    if heading:
        return line, _RANKS[m[1]] if m else "fasl"
    if m and m[1] == "فصل":
        return "فصل", "fasl"
    return (line, _RANKS[m[1]]) if body_headings and m and len(line.split()) <= _BODY_TITLE_WORDS else None


def segment_abwab(text: str, end: str | None = None, body_headings: bool = False) -> tuple[Bab, ...]:
    """Every unit with text, in order; the path is the enclosing kitāb and bāb titles."""
    units: list[Bab] = []
    kitab = bab = None
    cur: tuple[str, str, tuple[str, ...]] | None = None
    body: list[tuple[str, Page | None]] = []

    def close() -> None:
        if cur and len(body) > 1:
            units.append(Bab(*cur, " ".join(l for l, _ in body), body[0][1], body[-1][1]))

    for line, page, heading in _matn(text, end, body_headings):
        if opened := _opening(line, heading, body_headings):
            title, rank = opened
            if rank == "fasl" and kitab is None and bab is None:
                continue  # front matter
            close()
            path = () if rank == "kitab" else tuple(t for t in ((kitab,) if rank == "bab" else (kitab, bab)) if t)
            kitab, bab = (title, None) if rank == "kitab" else (kitab, title) if rank == "bab" else (kitab, bab)
            cur, body = (title, rank, path), []
        if cur:
            body.append((line, page))
    close()
    return tuple(units)
