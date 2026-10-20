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
witness also prints the marker of its closing endnotes as one. ``kitab_headings`` corrects an edition
that prints a kitāb as a bāb («باب النكاح» in *al-Ghurar*, «كتاب النكاح» in the matn's other witnesses):
those exact headings open a kitāb. Such a witness may number its body headings («2 - باب الأذان»,
«[1 - باب مواقيت الصلاة]», «5 - فصل»): the title then starts at the rank word. A unit runs from one opening to the next and carries its path: the titles
of the kitāb and bāb it sits in. Text before the first kitāb or bāb is front matter, and a heading
with no text of its own is a unit of no text: both are dropped, though the heading stays in the path.
Lines and pages are cleaned as in ``qa`` (OpenITI: a page marker closes its page).

The unit is a routing unit for R2 (docs/roadmap-parallel-derivation.md, Part II): it fixes where a
masʾala of the matn sits. With ``masail``, ``split_masail`` cuts a unit into the masāʾil a witness prints
one per line (*al-Ghurar*): «- …» or a plain statement opens a masʾala; numbered items «N - …» belong
to it; after an item ending «:» its «- …» lines are sub-items; a plain line continues a masʾala whose
last line has no sentence end (the manāsik break a sentence across lines); a bracketed subtitle «[…]»,
or an unpunctuated plain line before the first masʾala, is part of the heading. «~~» continuation lines are first joined to the line they continue, unless they open a
masʾala or an item themselves.
"""

from __future__ import annotations

import hashlib
import re
from collections.abc import Iterable
from dataclasses import dataclass, field

from .qa import Page, _lines

_TAG = re.compile(r"^(?:(?:AUTO|CHECK|EDITOR)\|?\s*)+")
_RANK = re.compile(r"^(كتاب|باب|فصل)(?![^\W\d_])")  # the word itself: «فصلت» is not «فصل»
_RANKS = {"كتاب": "kitab", "باب": "bab", "فصل": "fasl"}
_LETTER = re.compile(r"[^\W\d_]")
_BODY_TITLE_WORDS = 6  # longest body heading in al-Ghurar al-Naqiyya; a longer line is prose
_BODY_RANK = re.compile(r"^\[?\s*(?:[0-9٠-٩]+\s*-\s*)?((?:كتاب|باب|فصل)(?![^\W\d_]).*?)\s*\]?$")
_ITEM = re.compile(r"^[0-9٠-٩]+\s*-\s")
_SUBTITLE = re.compile(r"^\[.*\]$")
_SENTENCE_END = re.compile(r"[.:؛!؟]\s*(?:\(¬\d+\)\s*)*$")  # a final footnote marker does not hide it
# a «~~» line continues the line before, unless it opens a masʾala or an item itself (OpenITI also wraps a
# heading that carries a page marker together with the first masʾala after it)
_CONTINUATION = re.compile(r"\n~~(?!(?:[0-9٠-٩]+\s*)?-\s)")


@dataclass(frozen=True)
class Bab:
    heading: str
    rank: str
    path: tuple[str, ...]
    text: str
    page: Page | None
    end_page: Page | None
    body: tuple[tuple[str, Page | None], ...] = field(default=(), compare=False, repr=False)

    @property
    def sha256(self) -> str:
        return hashlib.sha256(self.text.encode()).hexdigest()


@dataclass(frozen=True)
class Masala:
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


def _opening(line: str, heading: bool, body_headings: bool = False,
             kitab_headings: frozenset[str] = frozenset()) -> tuple[str, str] | None:
    """(heading, rank) when the line opens a unit."""
    if line in kitab_headings:
        return line, "kitab"
    m = _RANK.match(line)
    if heading:
        return line, _RANKS[m[1]] if m else "fasl"
    if m and m[1] == "فصل":
        return "فصل", "fasl"
    b = _BODY_RANK.match(line) if body_headings else None
    if not b or len(b[1].split()) > _BODY_TITLE_WORDS:
        return None
    rank = _RANKS[_RANK.match(b[1])[1]]
    return ("فصل" if rank == "fasl" else b[1]), rank


def segment_abwab(text: str, end: str | None = None, body_headings: bool = False,
                  kitab_headings: Iterable[str] = (), masail: bool = False) -> tuple[Bab, ...]:
    """Every unit with text, in order; the path is the enclosing kitāb and bāb titles."""
    promoted = frozenset(kitab_headings)
    text = _CONTINUATION.sub(" ", text) if masail else text
    units: list[Bab] = []
    kitab = bab = None
    cur: tuple[str, str, tuple[str, ...]] | None = None
    body: list[tuple[str, Page | None]] = []

    def close() -> None:
        if cur and len(body) > 1:
            units.append(Bab(*cur, " ".join(l for l, _ in body), body[0][1], body[-1][1], tuple(body)))

    for line, page, heading in _matn(text, end, body_headings):
        if opened := _opening(line, heading, body_headings, promoted):
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


def split_masail(unit: Bab) -> tuple[Masala, ...]:
    """The masāʾil of a unit, after its opening heading, in order."""
    groups: list[list[tuple[str, Page | None]]] = []
    sub = False  # the last numbered item ended «:», so its «- …» lines are sub-items
    for line, page in unit.body[1:]:
        item, dash = _ITEM.match(line), line.startswith("- ")
        plain = not (item or dash)
        if _SUBTITLE.match(line) or (plain and not groups and not _SENTENCE_END.search(line)):
            continue
        open_sentence = groups and not _SENTENCE_END.search(groups[-1][-1][0])
        if groups and (item or (sub and dash) or (plain and open_sentence)):
            groups[-1].append((line, page))
        else:
            groups.append([(line, page)])
        sub = line.endswith(":") if item else sub and line.startswith("- ")
    return tuple(Masala(" ".join(l for l, _ in g), g[0][1], g[-1][1]) for g in groups)
