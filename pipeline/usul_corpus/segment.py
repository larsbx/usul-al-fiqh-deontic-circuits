"""Segment texts into numbered units (qāʿida, aṣl, …) and audit their numbering."""

from __future__ import annotations

import re
from dataclasses import dataclass
from itertools import groupby

from typing import Callable

from .arabic import normalize, parse_ordinal, parse_ordinal_span
from .openiti import _PAGE, Page, Section, clean_md_line

_FARC = re.compile(r"^\(?و?منها\)?\s*[:.]?\s*")
# A case by ordinal, «(الصورة الثانية)» / «المسألة الثالثة:» (a folio marker may sit inside).
_ORD_CASE = re.compile(r"^\(?(?:الصور[ةه]|المس[أا]ل[ةه])\s+(?:ms\d+\s+)?([^\s():.]+)\)?\s*[:.]?\s*")
# The first example, given inline after «صور:» / «مسائل:» («منها», «(ومنها)», «(إحداها)»), after
# «… مسائل إحداها:», or as a paragraph opening «ومن أمثلة ذلك» / «فمن ذلك» / «فمن صور المسألة», before any farʿ.
_OPENING = re.compile(r":\s*\(?(?:و?منها|إحداها)\)?\s*[:.]?\s*(?=\S)"
                      r"|(?:مسائل|صور)\s+\(?إحداها\)?\s*:\s*(?:ms\d+\s+)?(?=\S)"
                      r"|^\(?(?:ومن أمثلة ذلك|فمن ذلك|فمن صور (?:المسألة|ذلك))\)?\s*[:.]?\s*(?=\S)")
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
    opening: str | None = None  # the first example, inline before the «(و)منها» paragraphs

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


@dataclass(frozen=True)
class _Marker:
    """A farʿ marker: which lines open a case, and the prefix to strip from them."""
    opens: Callable[[str], bool]
    prefix: re.Pattern

    def strip(self, line: str) -> str:
        return self.prefix.sub("", line, count=1)


_PARAGRAPH = _Marker(lambda line: bool(_FARC.match(normalize(line))), _FARC)
_ORDINAL = _Marker(lambda line: bool((m := _ORD_CASE.match(line)) and parse_ordinal(normalize(m[1]), fuzzy=False)), _ORD_CASE)

# The list layouts of a qāʿida with neither: cases by feminine ordinal («(أحدها)», «(والثانية)»,
# «(اليد السادسة)»), or divisions («النوع/القسم/الضرب/الحالة/المقرر <ordinal>», or a bare
# «(و)الثاني:» once the qāʿida announces them: «نوعان:», «على قسمين:», «ثلاثة أشياء:»).
_CASE_LIST = re.compile(r"^[\[(]?و?(?:اليد\s+)?(أحدها(?!م)|إحداها(?!م)|الأولى|ال[^\s():.\]]+[ةه])[)\]]?\s*[:.]?\s*")
_DIVISION = re.compile(r"^[\[(]?و?(?:ال)?(نوع|قسم|ضرب|حال[ةه]|مقرر)\s+(?:ms\d+\s+)?(ال[^\s():.\]]+)[)\]]?\s*[:.]?\s*")
_BARE_DIVISION = re.compile(r"^\(?و?(ال(?:أول|ثاني|ثالث|رابع|خامس|سادس|سابع|ثامن|تاسع|عاشر))\)?\s*:\s*")
_ANNOUNCE = re.compile(r"(?:نوعان|نوعين|أنواع|قسمان|قسمين|أقسام|ضربان|ضربين|أضرب|أشياء)\s*:\s*")
_LIST_OPENING = re.compile(f"{_OPENING.pattern}|" r":\s*\(?أحدها(?!م)\)?\s*[:.]?\s*(?=\S)")
_DUAL = re.compile(r"\(?(?:أحدهما|إحداهما)\)?")
_FIRST = re.compile(r"^\(?(?:أحدهما|إحداهما|أحدها|إحداها|الأول|الأولى)\)?\s*[:.]?\s*")


def _ordinal(word: str) -> int | None:
    if normalize(word) in (normalize("أحدها"), normalize("إحداها")):
        return 1
    parsed = parse_ordinal(normalize(word), fuzzy=False)
    return parsed[0] if parsed else None


def _ordinal_chain(marks: list[tuple[int, int]], start: int) -> list[int]:
    """Line indices of the consecutive ordinals start, start+1, …: each k cuts at its last mark
    before the first (k+1)-mark (an inner «والثانية», a second riwāya, stays in its case); the
    final k cuts at its first."""
    out: list[int] = []
    k, lo = start, -1
    while ks := [i for i, v in marks if v == k and i > lo]:
        nxt = [i for i, v in marks if v == k + 1 and i > ks[0]]
        lo = max(i for i in ks if i < nxt[0]) if nxt else ks[0]
        out.append(lo)
        k += 1
    return out


def _inline_opening(prelude: tuple[str, ...], rx: re.Pattern = _OPENING) -> str | None:
    """The text after the first inline marker with something after it, to the end of the prelude."""
    for k, line in enumerate(prelude):
        m = rx.search(line)
        if m and line[m.end():].strip():
            return _statement(" ".join([line[m.end():], *prelude[k + 1:]]))
    return None


def _announced_opening(prelude: tuple[str, ...]) -> str | None:
    """An announced first division: after «نوعان:» … , opening with its own «أحدهما:» / «الأول:»
    on the same line or the next, to the end of the prelude."""
    for k, line in enumerate(prelude):
        if m := _ANNOUNCE.search(line):
            body = " ".join([line[m.end():], *prelude[k + 1:]]).strip()
            if f := _FIRST.match(body):
                return _statement(body[f.end():])
    return None


@dataclass(frozen=True)
class _Cut:
    """A unit's text cut into farʿ blocks, with its opening example."""
    lines: tuple[str, ...]
    starts: tuple[int, ...]
    strip: Callable[[str], str]
    opening: str | None

    @property
    def blocks(self) -> list[tuple[str, ...]]:
        """One block per start, running to the next: a case that crosses a line break (a page
        marker) keeps its continuation."""
        return [self.lines[i:j] for i, j in zip(self.starts, (*self.starts[1:], len(self.lines)))]


def _marked(lines: tuple[str, ...], starts: tuple[int, ...], strip: Callable[[str], str]) -> _Cut:
    return _Cut(lines, starts, strip, _inline_opening(lines[: starts[0]] if starts else lines))


def _list_cut(lines: tuple[str, ...]) -> _Cut | None:
    """Feminine-ordinal cases if they form a list, else divisions: a labelled level (one label
    noun) before bare «والثاني:», which counts only after an announcement. A list starts at 1,
    or at 2 when its first item is the opening."""
    def strip_by(*rxs: re.Pattern) -> Callable[[str], str]:
        def strip(line: str) -> str:
            m = next(filter(None, (rx.match(line) for rx in rxs)), None)
            return line[m.end():] if m else line
        return strip

    def chained(ms: list[tuple[int, int]], first: Callable[[tuple[str, ...]], str | None], strip) -> _Cut | None:
        if len(c := _ordinal_chain(ms, 1)) >= 2:
            return _Cut(lines, tuple(c), strip, None)
        c = _ordinal_chain(ms, 2)
        return _Cut(lines, tuple(c), strip, o) if c and (o := first(lines[: c[0]])) else None

    cases = [(i, v) for i, l in enumerate(lines) if (m := _CASE_LIST.match(l)) and (v := _ordinal(m[1]))]
    pos = {i: k for k, (i, _) in enumerate(cases)}
    # a 2 after a dual «أحدهما/إحداهما» (since the last mark) is the second of a pair, not a case
    cases = [(i, v) for i, v in cases
             if not (v == 2 and any(_DUAL.search(l) for l in lines[(cases[pos[i] - 1][0] if pos[i] else 0):i]))]
    labelled = [(i, normalize(m[1]).replace("ه", "ة"), v) for i, l in enumerate(lines)
                if (m := _DIVISION.match(l)) and (v := _ordinal(m[2]))]
    bare = [(i, v) for i, l in enumerate(lines) if (m := _BARE_DIVISION.match(l)) and (v := _ordinal(m[1]))]
    levels = [[(i, v) for i, n, v in labelled if n == noun] for noun in dict.fromkeys(n for _, n, _ in labelled)]
    options = [
        lambda: chained(cases, lambda p: _inline_opening(p, _LIST_OPENING), strip_by(_CASE_LIST)),
        *(lambda ms=ms: chained(ms, _announced_opening, strip_by(_DIVISION)) for ms in levels),
        lambda: chained(sorted(bare + [(i, v) for i, _, v in labelled]), _announced_opening, strip_by(_DIVISION, _BARE_DIVISION)),
    ]
    return next(filter(None, (o() for o in options)), None)


def _cut(text: str) -> _Cut:
    """«(و)منها» paragraphs where the unit has any; else «الصورة/المسألة» ordinal cases; else,
    where the unit has no opening example either, a list of cases or divisions. A layer applies
    only where the ones before it find nothing, so no existing farʿ id moves."""
    lines = tuple(text.split("\n"))
    for marker in (_PARAGRAPH, _ORDINAL):
        if starts := tuple(i for i, l in enumerate(lines) if marker.opens(l)):
            return _marked(lines, starts, marker.strip)
    bare = _marked(lines, (), _PARAGRAPH.strip)
    return bare if bare.opening else _list_cut(lines) or bare


def _furu(text: str) -> tuple[str, ...]:
    """Furūʿ: the unit's blocks. A marker line with nothing after it opens no farʿ (as it never
    did), so farʿ ids do not shift."""
    cut = _cut(text)
    return tuple(
        _statement(" ".join([cut.strip(b[0]), *b[1:]]))
        for b in cut.blocks
        if cut.strip(b[0]).strip()
    )


def _opening(text: str) -> str | None:
    """The opening example, farʿ 0, so the paragraph furūʿ keep their numbers."""
    return _cut(text).opening


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
        return Unit(number, head.title, _statement(text), head.page, _furu(text), ocr, opening=_opening(text))

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


CHAIN_WINDOW = 100  # a chain step may skip at most this many candidate lines


@dataclass(frozen=True)
class _State:
    """A chain ending at one (candidate, number) state, kept as aggregates plus a parent pointer."""
    length: int
    exact: int
    start: int
    link: Link
    parent: "_State | None"


def _chain(cands: list[tuple[int, Resolve]], min_lines: int, max_step: int, late_start: bool = True) -> list[Link]:
    """Best numbering chain over candidates in document order.

    Each step advances by 1..max_step and spans at least ``min_lines`` lines
    (so a table of contents, one heading per line, cannot form a chain). Score:
    length, with exact reads (no repair) counted double. Ties go to the tighter
    chain (smaller final number), then to the later start (a table of contents
    precedes the body it lists) — or, with ``late_start=False``, to the earlier one
    (a first quotation opens the commentary; re-quotes follow).

    The DP keeps the best chain per (candidate, number) state: a line's number
    depends on the path, and a shifted path that leads at one line must not
    evict the path that later agrees with the exact reads.
    """
    def key(st: _State) -> tuple[int, int, int]:
        return (st.length + st.exact, -st.link[2], st.start if late_start else -st.start)

    def step(parent: _State | None, pos: int, r: tuple[int, int, bool]) -> _State:
        link = (pos, *r)
        return _State((parent.length if parent else 0) + 1, (parent.exact if parent else 0) + (not r[2]),
                      parent.start if parent else pos, link, parent)

    layers: list[dict[int, _State]] = []   # per candidate: last number → best state
    for k, (pos, resolve) in enumerate(cands):
        layer: dict[int, _State] = {}

        def offer(st: _State) -> None:
            if st.link[2] not in layer or key(st) > key(layer[st.link[2]]):
                layer[st.link[2]] = st

        start = resolve(0)
        if start and start[0] <= max_step:
            offer(step(None, pos, start))
        for prev in layers[max(0, k - CHAIN_WINDOW):k]:
            for st in prev.values():
                if pos - st.link[0] >= min_lines and (nxt := resolve(st.link[2])) and 0 < nxt[0] - st.link[2] <= max_step:
                    offer(step(st, pos, nxt))
        layers.append(layer)

    best = max((st for layer in layers for st in layer.values()), key=key, default=None)
    chain: list[Link] = []
    while best:
        chain.append(best.link)
        best = best.parent
    return chain[::-1]


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


_VERSE = re.compile(r"^([0-9٠-٩۰-۹]{1,4})\s*[-–—.۔ـ]\s*(\S.*)$")


def _repair(obs: str, prev: int, max_step: int = VERSE_STEP, anchor_step: int | None = None) -> int:
    """Smallest n > prev whose trailing digits match the observed ones (OCR drops digits).

    Longer suffixes are tried first; the first that lands within ``max_step`` wins,
    so «١٩» read for ١٠٩ (its ٠ lost) resolves to 109 after 108, not to 119.
    A full-length read (as many digits as prev + 1) within ``anchor_step`` is taken
    as-is: it re-anchors the chain after a run of numbers lost to OCR.
    """
    if anchor_step and len(obs) >= len(str(prev + 1)) and prev < int(obs) <= prev + anchor_step:
        return int(obs)

    def nxt(suffix: str) -> int:
        m = 10 ** len(suffix)
        return prev + ((int(suffix) - prev) % m or m)

    fits = [n for k in range(len(obs), 0, -1) if (n := nxt(obs[-k:])) - prev <= max_step]
    return fits[0] if fits else nxt(obs)


def number_chain(reads: list[str], anchor_step: int | None = None) -> list[tuple[int, int, bool]]:
    """The longest plausible numbering over printed-number reads in document order:
    (index into ``reads``, number, repaired?) — see ``_repair`` for digit repair and anchors."""
    def resolve(obs: str) -> Resolve:
        def at(prev: int) -> tuple[int, int, bool] | None:
            n = _repair(obs, prev, VERSE_STEP, anchor_step)
            anchored = anchor_step and n == int(obs) and len(obs) >= len(str(prev + 1))
            return (n, n, n != int(obs)) if n - prev <= VERSE_STEP or anchored else None
        return at

    chain = _chain([(i, resolve(r)) for i, r in enumerate(reads)], min_lines=1,
                   max_step=max(VERSE_STEP, anchor_step or 0))
    return [(i, n, corrected) for i, n, _, corrected in chain]


def segment_numbered(text: str, anchor_step: int | None = None) -> tuple[Unit, ...]:
    """Numbered verses or paragraphs («١ - …», «۹۔ …», «١٠٥ ـ …») as the longest
    plausible numbering chain. Footnotes «(١) …» never match; stray numbers fall
    outside the chain; lost digits are repaired and flagged ``ocr_corrected``.
    """
    lines = _paged_lines(text)
    starts = [(i, normalize(m.group(1))) for i, (line, _) in enumerate(lines) if (m := _VERSE.match(line))]
    chain = [(starts[k][0], n, n, c) for k, n, c in number_chain([r for _, r in starts], anchor_step)]
    return _units(lines, chain, lambda l: _VERSE.match(l).group(2).strip(), furu=False)


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
