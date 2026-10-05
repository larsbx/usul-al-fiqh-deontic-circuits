"""Segment texts into numbered units (qāʿida, aṣl, …) and audit their numbering."""

from __future__ import annotations

import re
from dataclasses import dataclass
from itertools import groupby

from .arabic import normalize, parse_ordinal
from .openiti import Page, Section

_FARC = re.compile(r"^\(?و?منها\)?\s*[:.]?\s*")
_NUM = re.compile(r"^\s*(\d{1,3})\b")
_TAGS = re.compile(r"<[^>]+>")
_STATEMENT_LEN = 400


@dataclass(frozen=True)
class Unit:
    number: int | None
    heading: str
    statement: str
    page: Page | None
    furu: tuple[str, ...]
    ocr_corrected: bool


def _number(after_marker: str) -> tuple[int | None, bool]:
    """Read a unit number from the text that follows the marker word."""
    m = _NUM.match(normalize(after_marker))
    if m:
        return int(m.group(1)), False
    words = normalize(after_marker).replace("(", " ").replace(")", " ").split(":")[0].split()
    # Longest ordinal prefix wins («الحادية والعشرون بعد المائة» before «الحادية»),
    # so a header fused with its statement still parses. A prefix followed by
    # another ordinal word is a merged heading and stays unparsed.
    for k in range(len(words), 0, -1):
        parsed = parse_ordinal(" ".join(words[:k]))
        if parsed:
            continues = k < len(words) and parse_ordinal(words[k]) is not None
            return (None, False) if continues else parsed
    return None, False


def _statement(text: str) -> str:
    return " ".join(_TAGS.sub("", text).split())[:_STATEMENT_LEN]


def _furu(text: str) -> tuple[str, ...]:
    """Furūʿ: paragraphs that open with «منها» / «ومنها» (optionally parenthesised)."""
    return tuple(
        _statement(_FARC.sub("", p, count=1))
        for p in text.split("\n")
        if _FARC.match(normalize(p)) and _FARC.sub("", p, count=1).strip()
    )


def segment_headed(sections: tuple[Section, ...], marker: str) -> tuple[Unit, ...]:
    """Units start at level-1 headers containing ``marker``; deeper sections fold in."""
    key = normalize(marker)
    starts = [i for i, s in enumerate(sections) if s.level == 1 and key in normalize(s.title)]
    bounds = zip(starts, starts[1:] + [_next_top(sections, starts[-1]) if starts else 0])

    def unit(i: int, j: int) -> Unit:
        head, body = sections[i], sections[i:j]
        after = normalize(head.title).split(key, 1)[1]
        number, ocr = _number(after)
        text = "\n".join(s.text for s in body)
        if number is None:  # number printed on the first body line (Shamela layout)
            number, ocr = _number(_TAGS.sub("", head.text))
            text = text.split("\n", 1)[1] if "\n" in text else text
        return Unit(number, head.title, _statement(text), head.page, _furu(text), ocr)

    return tuple(unit(i, j) for i, j in bounds)


def _next_top(sections: tuple[Section, ...], last: int) -> int:
    """End of the final unit: the next level-1 section, or the end of the text."""
    return next((k for k in range(last + 1, len(sections)) if sections[k].level == 1), len(sections))


def segment_lines(text: str, marker: str) -> tuple[Unit, ...]:
    """Segment plain (e.g. OCR) text where each unit opens with a line ``marker <ordinal>``."""
    key = normalize(marker)
    lines = text.splitlines()
    starts = [
        i for i, line in enumerate(lines)
        if normalize(line).startswith(key + " ") and len(normalize(line).split()) <= 6
    ]

    def unit(i: int, j: int) -> Unit:
        heading = " ".join(lines[i].split())
        number, ocr = _number(normalize(heading)[len(key):])
        body = "\n".join(lines[i + 1:j])
        return Unit(number, heading, _statement(body), None, _furu(body), ocr)

    return tuple(unit(i, j) for i, j in zip(starts, starts[1:] + [len(lines)]))


def audit_numbering(units: tuple[Unit, ...], expected: int | None) -> dict:
    """Compare found unit numbers with the claimed count (edition verification, M0)."""
    nums = sorted(u.number for u in units if u.number is not None)
    top = max([*nums, expected or 0], default=0)
    return {
        "found": len(units),
        "numbered": len(nums),
        "max_number": max(nums, default=None),
        "expected": expected,
        "missing": [n for n in range(1, top + 1) if n not in set(nums)],
        "duplicates": [n for n, g in groupby(nums) if len(list(g)) > 1],
        "unparsed": sum(u.number is None for u in units),
        "matches_expected": expected is not None and nums == list(range(1, expected + 1)),
    }
