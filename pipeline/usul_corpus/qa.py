"""The ``qa`` segmenter: question-and-answer units in fatāwā collections.

A unit starts at a line whose text begins with the witness's question marker (or, where the witness
prints questions as headings, at a section heading) and runs to the next
unit's start; it splits into question and answer at its first line beginning with the answer marker.
A question line opens a new unit only once the current unit has an answer, or once the current
unit's question has outgrown a short header (``HEADER_LINES``). So a heading that repeats the marker
(«[مسألة …]» before «مسألة:», «السؤال الثالث … من الفتوى رقم» before «س3:») stays with its question,
and an unanswered question cannot absorb the rest of the book.
Markers are anchored to the start of a line, so a quotation such as «وسئل مالك …» inside an
answer does not start a unit. Lines are cleaned of mARkdown prefixes, continuation marks, HTML
tags and milestones, and joined; page markers, on their own line or inline, close the page they follow (OpenITI); the placeholder
``PageV00P000`` closes a page the source did not number, so its lines are on no known page. A section heading (``### |``)
after the answer has begun ends the unit, so a treatise placed between fatāwā is not absorbed by
the last answer before it. A unit with no answer keeps only its question header. Each unit carries the sha256 of
its text as a receipt for stability replays (docs/architecture/derivation-method.md §3, S0).
"""

from __future__ import annotations

import hashlib
import re
from dataclasses import dataclass

Page = tuple[int, int]

_PAGE = re.compile(r"PageV(\d+)P(\d+)")
_PREFIX = re.compile(r"^(?:#+\s*\|*\s*|~~)")
_TAG = re.compile(r"<[^>]+>")
_MILESTONE = re.compile(r"\bms\d+\b")
_NUM = re.compile(r"^(?:س|ج)\s*(\d+)\s*:")
HEADER_LINES = 3


@dataclass(frozen=True)
class QA:
    question: str
    answer: str | None
    page: Page | None
    end_page: Page | None
    number: int | None

    @property
    def text(self) -> str:
        return f"{self.question} {self.answer}" if self.answer else self.question

    @property
    def sha256(self) -> str:
        return hashlib.sha256(self.text.encode()).hexdigest()


def _lines(text: str) -> list[tuple[str, Page | None, bool]]:
    """(cleaned line, the page it is on, is it a section heading) for every text line;
    a page marker closes its page."""
    body = text.split("#META#Header#End#", 1)[-1].splitlines()
    out: list[tuple[str, int, bool]] = []
    pages: list[Page | None] = []
    for raw in body:
        parts = _PAGE.split(_PREFIX.sub("", raw))  # text, (vol, page), text, …: markers may be inline
        line = " ".join(_MILESTONE.sub("", _TAG.sub("", " ".join(parts[0::3]))).split())
        if line:  # the line is on the page its next marker closes, inline or later
            out.append((line, len(pages), raw.startswith("### ")))
        pages += [(int(v), int(p)) if int(p) else None for v, p in zip(parts[1::3], parts[2::3])]  # P000: unnumbered
    pages.append(None)  # text after the last marker is on no closed page
    return [(line, pages[i], head) for line, i, head in out]


def segment_qa(text: str, question: str | None, answer: str, question_heading: bool = False) -> tuple[QA, ...]:
    """Every question-and-answer unit; text before the first question is front matter. With
    ``question_heading``, a section heading is a question line too (*Nūr ʿalā al-Darb*)."""
    q_at, a_at = re.compile(question) if question else None, re.compile(answer)
    lines = _lines(text)
    starts: list[int] = []
    answered = False
    for i, (line, _, head) in enumerate(lines):
        if starts and not answered and a_at.match(line) and i > starts[-1]:
            answered = True
        elif ((q_at and q_at.match(line)) or (question_heading and head)) and (not starts or answered or i - starts[-1] > HEADER_LINES):
            starts.append(i)
            answered = False
    units = []
    for s, e in zip(starts, starts[1:] + [len(lines)]):
        block = lines[s:e]
        k = next((j for j, (line, _, _) in enumerate(block) if j and a_at.match(line)), None)
        if k:  # a section heading after the answer begins ends the unit
            block = block[:next((j for j in range(k + 1, len(block)) if block[j][2]), len(block))]
        else:  # no answer: the unit is its question header, not the text that follows it
            block = block[:HEADER_LINES + 1]
        q, a = block[:k] if k else block, block[k:] if k else []
        number = next((int(m[1]) for line, _, _ in block if (m := _NUM.match(line))), None)
        units.append(QA(" ".join(line for line, _, _ in q), " ".join(line for line, _, _ in a) or None,
                        block[0][1], block[-1][1], number))
    return tuple(units)


@dataclass(frozen=True)
class Entry:
    """One masʾala of a *Masāʾil* collection: the whole entry, with its printed number if any."""
    text: str
    page: Page | None
    end_page: Page | None
    number: int | None

    @property
    def sha256(self) -> str:
        return hashlib.sha256(self.text.encode()).hexdigest()


def segment_entries(text: str, start: str, ordered: bool = False) -> tuple[Entry, ...]:
    """The ``masail`` segmenter: an entry starts at a line beginning with the work's opening formula
    («قلت لأحمد», «سمعت أحمد», al-Kawsaj's «[1100-]» …) and runs to the next one, or to a section
    heading that is not itself an opening. A named group ``n`` in ``start`` is the printed number.
    Answers are inline («… قال: …»), so an entry is not split into question and answer.
    With ``ordered``, only the longest increasing run of printed numbers opens entries; any other
    match (a letter's own enumeration, a reference number) stays in the text of its entry, even
    when printed as a heading."""
    from .hadith import _longest_increasing
    at = re.compile(start)
    lines = _lines(text)
    found = [(i, m) for i, (line, _, _) in enumerate(lines) if (m := at.match(line))]
    number = {i: int(m["n"]) if "n" in m.groupdict() and m["n"] else None for i, m in found}
    opens = ({i for i, _ in _longest_increasing([(i, n) for i, n in number.items() if n is not None])}
             if ordered else set(number))
    units, cur = [], None
    for i, (line, page, heading) in enumerate(lines + [("", None, True)]):
        if cur and (i in opens or (heading and i not in number)):
            units.append(Entry(" ".join(l for l, _ in cur), cur[0][1], cur[-1][1], number[first]))
            cur = None
        if i in opens:
            cur, first = [], i
        if cur is not None:
            cur.append((line, page))
    return tuple(units)
