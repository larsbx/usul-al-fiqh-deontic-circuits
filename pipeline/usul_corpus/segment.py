"""Segment texts into numbered units (qāʿida, aṣl, …) and audit their numbering."""

from __future__ import annotations

import re
from dataclasses import dataclass
from itertools import groupby

from .arabic import normalize, parse_ordinal
from .openiti import _PAGE, Page, Section, clean_md_line

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


def _paged_lines(text: str) -> list[tuple[str, Page | None]]:
    """Non-empty content lines, each with the page its closing marker assigns."""
    page: Page | None = None
    out: list[tuple[str, Page | None]] = []
    for raw in reversed(text.splitlines()):
        m = _PAGE.search(raw)
        page = (int(m.group(1)), int(m.group(2))) if m else page
        if line := clean_md_line(raw):
            out.append((line, page))
    return out[::-1]


def segment_lines(text: str, marker: str) -> tuple[Unit, ...]:
    """Segment line-oriented (OCR) text where each unit opens with a line ``marker <ordinal>``.

    Accepts plain text or mARkdown with closing ``PageVxxPyyy`` markers.
    """
    key = normalize(marker)
    lines = _paged_lines(text)
    starts = [
        i for i, (line, _) in enumerate(lines)
        if normalize(line).startswith(key + " ") and len(normalize(line).split()) <= 6
    ]

    def unit(i: int, j: int) -> Unit:
        heading, page = " ".join(lines[i][0].split()), lines[i][1]
        number, ocr = _number(normalize(heading)[len(key):])
        body = "\n".join(line for line, _ in lines[i + 1:j])
        return Unit(number, heading, _statement(body), page, _furu(body), ocr)

    return tuple(unit(i, j) for i, j in zip(starts, starts[1:] + [len(lines)]))


_VERSE = re.compile(r"^([0-9٠-٩۰-۹]{1,3})\s*[-–—.۔]\s*(\S.*)$")


MAX_VERSE_GAP = 3  # tolerate up to two verses missed by OCR between accepted ones


def _repair(obs: str, prev: int) -> int:
    """Smallest n > prev whose trailing digits equal the observed ones (OCR drops leading digits)."""
    m, o = 10 ** len(obs), int(obs)
    return prev + ((o - prev) % m or m)


def _verse_chain(cands: list[tuple[int, str]]) -> list[tuple[int, int, bool]]:
    """Longest chain of (line, repaired number, corrected?) with steps in 1..MAX_VERSE_GAP.

    Dynamic programme over candidates in document order; ties go to the chain
    with the smaller final number (the tighter run).
    """
    best: list[list[tuple[int, int, bool]]] = []
    for pos, obs in cands:
        options = [[(pos, int(obs), False)]] if 0 < int(obs) <= MAX_VERSE_GAP else []
        options += [
            chain + [(pos, v, v != int(obs))]
            for chain in best
            if chain
            and 0 < (v := _repair(obs, chain[-1][1])) - chain[-1][1] <= MAX_VERSE_GAP
        ]
        best.append(max(options, key=_tightness, default=[]))
    return max(best, key=_tightness, default=[])


def _tightness(chain: list[tuple[int, int, bool]]) -> tuple[int, int]:
    return (len(chain), -chain[-1][1]) if chain else (0, 0)


def segment_numbered(text: str) -> tuple[Unit, ...]:
    """Numbered verses («١ - …», «۹۔ …») as the longest plausible numbering chain.

    Footnotes «(١) …» never match; stray numbers fall outside the chain; lost
    leading digits are repaired and flagged ``ocr_corrected``.
    """
    lines = _paged_lines(text)
    cands = [(i, normalize(m.group(1))) for i, (line, _) in enumerate(lines) if (m := _VERSE.match(line))]
    chain = _verse_chain(cands)
    ends = [pos for pos, _, _ in chain[1:]] + [len(lines)]

    def unit(start: tuple[int, int, bool], end: int) -> Unit:
        i, n, corrected = start
        body = "\n".join(line for line, _ in lines[i + 1:end])
        return Unit(n, _VERSE.match(lines[i][0]).group(2).strip(), _statement(body), lines[i][1], (), corrected)

    return tuple(unit(c, e) for c, e in zip(chain, ends))


def consensus_numbering(witnesses: dict[str, tuple[Unit, ...]], expected: int | None) -> dict:
    """Union unit numbers across independent witnesses (e.g. two OCR engines)."""
    found = {
        n: sorted(w for w, us in witnesses.items() if any(u.number == n for u in us))
        for n in sorted({u.number for us in witnesses.values() for u in us if u.number is not None})
    }
    top = max([*found, expected or 0], default=0)
    return {
        "expected": expected,
        "found_by_any": list(found),
        "missing_in_all": [n for n in range(1, top + 1) if n not in found],
        "found_by": {str(n): ws for n, ws in found.items()},
        "complete": expected is not None and list(found) == list(range(1, expected + 1)),
    }


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
