"""The ``abwab`` segmenter: the kitāb › bāb › faṣl units of a matn.

A heading's rank comes from its first word («كتاب», «باب», «فصل»), not its mARkdown level, since
witnesses disagree on levels (*Zād* puts all at «|», *al-Muqniʿ* nests them). Any other heading
(«الشرط الأول», «مقدمة» …) ranks as a faṣl. A body line beginning with the word «فصل» also opens a
faṣl, as *Zād*, *Muntahā* and *al-Iqnāʿ* print them. «مدخل» and headings without letters are
Shamela navigation, not openings; a heading that is only a rank word («باب») takes the next heading
as its title. A heading matching the work's ``end`` pattern closes the matn, so an editor's closing
matter and bibliography are not absorbed by its last faṣl. A unit runs from one opening to the next and carries its path: the titles
of the kitāb and bāb it sits in. Text before the first kitāb or bāb is front matter, and a heading
with no text of its own is a unit of no text: both are dropped, though the heading stays in the path.
Lines and pages are cleaned as in ``qa`` (OpenITI: a page marker closes its page).

The unit is a routing unit for R2 (docs/roadmap-parallel-derivation.md, Part II): it fixes where a
masʾala of the matn sits. ``segment_masail`` splits each unit into its masāʾil: a masʾala is a
paragraph, a body line beginning with ``# `` and the ``~~`` lines continuing it, so every paragraph
sits in exactly one unit. The unit's opening line (its heading, or a body «فصل» line) is not a
paragraph; any continuation line before the unit's first paragraph is returned as loose text, so no
text of the unit is lost (docs/architecture/mutun-masail.md).
"""

from __future__ import annotations

import hashlib
import re
from dataclasses import dataclass

from .qa import Page, _marked_lines

_TAG = re.compile(r"^(?:(?:AUTO|CHECK|EDITOR)\|?\s*)+")
_RANK = re.compile(r"^(كتاب|باب|فصل)(?![^\W\d_])")  # the word itself: «فصلت» is not «فصل»
_RANKS = {"كتاب": "kitab", "باب": "bab", "فصل": "fasl"}
_LETTER = re.compile(r"[^\W\d_]")


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


@dataclass(frozen=True)
class Paragraph:
    """One paragraph of a unit: a masʾala of the matn."""
    text: str
    page: Page | None
    end_page: Page | None

    @property
    def sha256(self) -> str:
        return hashlib.sha256(self.text.encode()).hexdigest()


@dataclass(frozen=True)
class Masail:
    """A unit, its opening line, its paragraphs in text order, and its continuation lines that precede
    any paragraph."""
    bab: Bab
    opening: str
    paragraphs: tuple[Paragraph, ...]
    loose: tuple[str, ...]


def _navigation(line: str) -> bool:
    return line == "مدخل" or not _LETTER.search(line)


def _matn(text: str, end: str | None) -> list[tuple[str, Page | None, bool, bool]]:
    """The cleaned lines up to the end heading, navigation dropped and bare rank headings titled;
    the last flag marks a line that opens a paragraph."""
    out: list[tuple[str, Page | None, bool, bool]] = []
    for line, page, heading, para in _marked_lines(text):
        line = _TAG.sub("", line) if heading else line
        if heading and end and re.search(end, line):
            break
        if heading and _navigation(line):
            continue
        if heading and out and out[-1][2] and out[-1][0] in _RANKS and not _RANK.match(line):
            out[-1] = (f"{out[-1][0]} {line}", out[-1][1], True, False)
        else:
            out.append((line, page, heading, para))
    return out


def _opening(line: str, heading: bool) -> tuple[str, str] | None:
    """(heading, rank) when the line opens a unit."""
    m = _RANK.match(line)
    if heading:
        return line, _RANKS[m[1]] if m else "fasl"
    return ("فصل", "fasl") if m and m[1] == "فصل" else None


def _units(text: str, end: str | None) -> list[tuple[tuple[str, str, tuple[str, ...]], list[tuple[str, Page | None, bool]]]]:
    """(heading, rank, path) and the unit's lines (line, page, opens a paragraph), opening line first."""
    units: list[tuple[tuple[str, str, tuple[str, ...]], list[tuple[str, Page | None, bool]]]] = []
    kitab = bab = None
    cur: tuple[str, str, tuple[str, ...]] | None = None
    body: list[tuple[str, Page | None, bool]] = []

    def close() -> None:
        if cur and len(body) > 1:
            units.append((cur, body))

    for line, page, heading, para in _matn(text, end):
        if opened := _opening(line, heading):
            title, rank = opened
            if rank == "fasl" and kitab is None and bab is None:
                continue  # front matter
            close()
            path = () if rank == "kitab" else tuple(t for t in ((kitab,) if rank == "bab" else (kitab, bab)) if t)
            kitab, bab = (title, None) if rank == "kitab" else (kitab, title) if rank == "bab" else (kitab, bab)
            cur, body = (title, rank, path), []
        if cur:
            body.append((line, page, para))
    close()
    return units


def _bab(cur: tuple[str, str, tuple[str, ...]], body: list[tuple[str, Page | None, bool]]) -> Bab:
    return Bab(*cur, " ".join(l for l, _, _ in body), body[0][1], body[-1][1])


def segment_abwab(text: str, end: str | None = None) -> tuple[Bab, ...]:
    """Every unit with text, in order; the path is the enclosing kitāb and bāb titles."""
    return tuple(_bab(cur, body) for cur, body in _units(text, end))


def segment_masail(text: str, end: str | None = None) -> tuple[Masail, ...]:
    """Every unit of ``segment_abwab``, in the same order, with its paragraphs. The unit's text is its
    opening line, its loose lines and its paragraphs' texts, joined in that order."""
    out = []
    for cur, body in _units(text, end):
        paras: list[list[tuple[str, Page | None]]] = []
        loose: list[str] = []
        for line, page, para in body[1:]:  # body[0] opens the unit: its heading, not a masʾala
            if para:
                paras.append([(line, page)])
            elif paras:
                paras[-1].append((line, page))
            else:
                loose.append(line)
        out.append(Masail(_bab(cur, body), body[0][0],
                          tuple(Paragraph(" ".join(l for l, _ in p), p[0][1], p[-1][1]) for p in paras),
                          tuple(loose)))
    return tuple(out)
