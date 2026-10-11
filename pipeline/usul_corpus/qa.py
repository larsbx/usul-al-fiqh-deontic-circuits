"""The ``qa`` segmenter: question-and-answer units in fatāwā collections.

A unit starts at a line whose text begins with the witness's question marker and runs to the next
unit's start; it splits into question and answer at its first line beginning with the answer marker.
A question line opens a new unit only once the current unit has an answer, or once the current
unit's question has outgrown a short header (``HEADER_LINES``). So a heading that repeats the marker
(«[مسألة …]» before «مسألة:», «السؤال الثالث … من الفتوى رقم» before «س3:») stays with its question,
and an unanswered question cannot absorb the rest of the book.
Markers are anchored to the start of a line, so a quotation such as «وسئل مالك …» inside an
answer does not start a unit. Lines are cleaned of mARkdown prefixes, continuation marks and HTML
tags, and joined; page markers close the page they follow (OpenITI). A section heading (``### |``)
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
        if m := _PAGE.fullmatch(_PREFIX.sub("", raw).strip()):
            pages.append((int(m[1]), int(m[2])))
            continue
        line = " ".join(_TAG.sub("", _PREFIX.sub("", raw)).split())
        if line:
            out.append((line, len(pages), raw.startswith("### ")))
    pages.append(None)  # text after the last marker is on no closed page
    return [(line, pages[i], head) for line, i, head in out]


def segment_qa(text: str, question: str, answer: str) -> tuple[QA, ...]:
    """Every question-and-answer unit; text before the first question is front matter."""
    q_at, a_at = re.compile(question), re.compile(answer)
    lines = _lines(text)
    starts: list[int] = []
    answered = False
    for i, (line, _, _) in enumerate(lines):
        if starts and not answered and a_at.match(line) and i > starts[-1]:
            answered = True
        elif q_at.match(line) and (not starts or answered or i - starts[-1] > HEADER_LINES):
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
