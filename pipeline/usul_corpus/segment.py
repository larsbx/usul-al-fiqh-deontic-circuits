"""Segment texts into numbered units (qāʿida, aṣl, …) and audit their numbering."""

from __future__ import annotations

import re
from dataclasses import dataclass
from itertools import groupby

from typing import Callable

from .arabic import normalize, parse_ordinal, parse_ordinal_span
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
    covers: tuple[int, ...] = ()  # rule numbers under a joint heading, e.g. (22, 23)

    @property
    def numbers(self) -> tuple[int, ...]:
        return self.covers or ((self.number,) if self.number is not None else ())


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


RULE_STEP = 4   # rule headings: tolerate up to three consecutive headings lost to OCR
VERSE_STEP = 3  # verse numbers are dense and digit-repaired, so allow less slack

# A candidate resolves, given the last number of the chain so far, to
# (first, last, ocr_corrected) — or None when it cannot follow.
Resolve = Callable[[int], "tuple[int, int, bool] | None"]
Link = tuple[int, int, int, bool]  # (line position, first, last, corrected)


def _chain(cands: list[tuple[int, Resolve]], min_lines: int, max_step: int, late_start: bool = True) -> list[Link]:
    """Longest numbering chain over candidates in document order.

    Each step advances by 1..max_step and spans at least ``min_lines`` lines
    (so a table of contents, one heading per line, cannot form a chain).
    Ties go to the tighter chain (smaller final number), then to the later start
    (a table of contents precedes the body it lists) — or, with ``late_start=False``,
    to the earlier one (a first quotation opens the commentary; re-quotes follow).
    """
    def tightness(chain: list[Link]) -> tuple[int, int, int]:
        return (len(chain), -chain[-1][2], chain[0][0] if late_start else -chain[0][0]) if chain else (0, 0, 0)

    best: list[list[Link]] = []
    for pos, resolve in cands:
        start = resolve(0)
        options = [[(pos, *start)]] if start and start[0] <= max_step else []
        for chain in (c for c in best if c and pos - c[-1][0] >= min_lines):
            nxt = resolve(chain[-1][2])
            if nxt and 0 < nxt[0] - chain[-1][2] <= max_step:
                options.append(chain + [(pos, *nxt)])
        best.append(max(options, key=tightness, default=[]))
    return max(best, key=tightness, default=[])


def _units(lines: list[tuple[str, Page | None]], chain: list[Link], heading: Callable[[str], str],
           furu: bool) -> tuple[Unit, ...]:
    ends = [pos for pos, *_ in chain[1:]] + [len(lines)]

    def unit(link: Link, end: int) -> Unit:
        pos, first, last, corrected = link
        body = "\n".join(line for line, _ in lines[pos + 1:end])
        covers = tuple(range(first, last + 1)) if last > first else ()
        return Unit(first, heading(lines[pos][0]), _statement(body), lines[pos][1],
                    _furu(body) if furu else (), corrected, covers)

    return tuple(unit(c, e) for c, e in zip(chain, ends))


def _heading_span(line: str, key: str) -> tuple[tuple[int, int], bool] | None:
    """«القاعدة الثانية» or a bare «الثانية» (the word itself may be a graphic lost to OCR),
    optionally followed by one stray glyph of at most two letters."""
    words = normalize(line).replace("(", " ").replace(")", " ").replace(":", " ").replace(".", " ").split()
    words = words[1:] if words[:1] == [key] else words
    if words and len(words[-1]) <= 2 and len(words) > 1:
        words = words[:-1]
    return parse_ordinal_span(" ".join(words)) if 0 < len(words) <= 6 else None


def segment_lines(text: str, marker: str) -> tuple[Unit, ...]:
    """Rule headings in line-oriented (OCR) text: «القاعدة <ordinal>» or a bare ordinal line,
    chained by number. Accepts plain text or mARkdown with closing page markers."""
    key = normalize(marker)
    lines = _paged_lines(text)
    cands = [
        (i, (lambda sp: lambda _prev: (sp[0][0], sp[0][1], sp[1]))(span))
        for i, (line, _) in enumerate(lines)
        if (span := _heading_span(line, key))
    ]
    return _units(lines, _chain(cands, min_lines=2, max_step=RULE_STEP), lambda l: " ".join(l.split()), furu=True)


def segment_index(text: str, marker: str) -> tuple[Unit, ...]:
    """Index entries «القاعدة <ordinal>: <statement>» (a book's closing list of its rules).

    Joint entries are skipped here: an index restates each rule, so a fused entry is
    an OCR merge, not a joint rule. The statement is the text after the colon.
    """
    key = normalize(marker)
    lines = _paged_lines(text)

    def entry(line: str) -> tuple[int, str] | None:
        head, sep, statement = line.partition(":")
        span = _heading_span(head, key) if sep and normalize(head).startswith(key + " ") else None
        return (span[0][0], statement.strip()) if span and span[0][0] == span[0][1] and statement.strip() else None

    entries = [(i, e) for i, (line, _) in enumerate(lines) if (e := entry(line))]
    chain = _chain([(i, (lambda n: lambda _p: (n, n, False))(n)) for i, (n, _) in entries], 1, RULE_STEP)
    by_pos = dict(entries)
    return tuple(
        Unit(n, lines[pos][0].partition(":")[0].strip(), by_pos[pos][1], lines[pos][1], (), False)
        for pos, n, _, _ in chain
    )


_VERSE = re.compile(r"^([0-9٠-٩۰-۹]{1,3})\s*[-–—.۔ـ]\s*(\S.*)$")


def _repair(obs: str, prev: int) -> int:
    """Smallest n > prev whose trailing digits equal the observed ones (OCR drops leading digits)."""
    m, o = 10 ** len(obs), int(obs)
    return prev + ((o - prev) % m or m)


def segment_numbered(text: str) -> tuple[Unit, ...]:
    """Numbered verses («١ - …», «۹۔ …») as the longest plausible numbering chain.

    Footnotes «(١) …» never match; stray numbers fall outside the chain; lost
    leading digits are repaired and flagged ``ocr_corrected``.
    """
    lines = _paged_lines(text)

    def resolve(obs: str) -> Resolve:
        return lambda prev: (n := _repair(obs, prev), n, n != int(obs))

    cands = [(i, resolve(normalize(m.group(1)))) for i, (line, _) in enumerate(lines) if (m := _VERSE.match(line))]
    return _units(lines, _chain(cands, min_lines=1, max_step=VERSE_STEP),
                  lambda l: _VERSE.match(l).group(2).strip(), furu=False)


def consensus_numbering(witnesses: dict[str, tuple[Unit, ...]], expected: int | None) -> dict:
    """Union unit numbers across independent witnesses (e.g. two OCR engines).

    Numbers above the expected count are reported apart (``beyond_expected``):
    they are witness errors, not evidence about the count.
    """
    found = {
        n: sorted(w for w, us in witnesses.items() if any(n in u.numbers for u in us))
        for n in sorted({n for us in witnesses.values() for u in us for n in u.numbers})
    }
    top = expected or max(found, default=0)
    within = [n for n in found if n <= top]
    return {
        "expected": expected,
        "found_by_any": within,
        "missing_in_all": [n for n in range(1, top + 1) if n not in found],
        "beyond_expected": {str(n): ws for n, ws in found.items() if n > top},
        "found_by": {str(n): found[n] for n in within},
        "complete": expected is not None and within == list(range(1, expected + 1)),
    }


def audit_numbering(units: tuple[Unit, ...], expected: int | None) -> dict:
    """Compare found unit numbers with the claimed count (edition verification, M0)."""
    nums = sorted(n for u in units for n in u.numbers)
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
