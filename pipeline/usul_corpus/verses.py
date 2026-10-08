"""Verse-line detection for printed manẓūmāt.

A bayt is printed as one line with its two hemistichs separated by a wide,
roughly central blank gap; justified prose has only word gaps. Detected lines
are cropped per hemistich and OCR-ed as single lines (psm 7), which recovers
the vocalised verse text that page-level layout analysis garbles.

Pure core (bands_from_rows, inner_gap, is_verse, verse_line, merge_verses);
the numpy/PIL shell (measure_bands, ocr_verses) only measures and crops.
"""

from __future__ import annotations

import re
import statistics
from dataclasses import dataclass
from pathlib import Path

from .arabic import normalize
from .ocr import Line, clean_line, is_noise, parse_tsv, run_tesseract, runs
from .openiti import Page
from .segment import Unit, _paged_lines

HEMISTICH_SEP = " * "
FULL_WIDTH = 0.8            # a verse line spans ≥ 80% of the text block
GAP_SHARE = (0.04, 0.25)    # hemistich gap, as a share of the line width
GAP_POSITION = (0.3, 0.7)   # gap start, relative to the line (roughly central)
MIN_INK, MIN_HEIGHT, PAD = 5, 20, 8


@dataclass(frozen=True)
class Band:
    """A text line on the page: vertical extent, ink extent and widest inner gap (pixels)."""
    y0: int
    y1: int
    x0: int
    x1: int
    gap0: int
    gap1: int

    @property
    def width(self) -> int:
        return self.x1 - self.x0


def bands_from_rows(rows: list[int], min_ink: int = MIN_INK, min_height: int = MIN_HEIGHT) -> list[tuple[int, int]]:
    """Runs of rows with ink (≥ ``min_ink`` dark pixels) at least ``min_height`` tall."""
    return [(a, b) for a, b in runs([r >= min_ink for r in rows]) if b - a >= min_height]


def inner_gap(cols: list[bool]) -> tuple[int, int, int, int] | None:
    """(left ink, right ink, gap start, gap end) for the widest blank run inside the ink extent."""
    ink = [i for i, c in enumerate(cols) if c]
    if not ink:
        return None
    runs = [(b - a, a, b) for a, b in zip(ink, ink[1:]) if b - a > 1]
    _, g0, g1 = max(runs, default=(0, ink[0], ink[0]))
    return ink[0], ink[-1], g0 + 1, g1


def is_verse(b: Band, text_width: int) -> bool:
    gap = b.gap1 - b.gap0
    return (
        b.width >= FULL_WIDTH * text_width
        and GAP_SHARE[0] * b.width <= gap <= GAP_SHARE[1] * b.width
        and GAP_POSITION[0] <= (b.gap0 - b.x0) / b.width <= GAP_POSITION[1]
    )


def verse_line(right: Line, left: Line, top: int, bottom: int) -> Line:
    """Arabic reads right to left: the right crop is the first hemistich (and carries the number)."""
    return Line(f"{right.text}{HEMISTICH_SEP}{left.text}", round(statistics.fmean([right.conf, left.conf]), 2), top, bottom)


def merge_verses(lines: tuple[Line, ...], verses: tuple[Line, ...]) -> tuple[Line, ...]:
    """Replace page-level lines that overlap a verse band by more than half their height."""

    def covered(l: Line) -> bool:
        return any(min(l.bottom, v.bottom) - max(l.top, v.top) > (l.bottom - l.top) / 2 for v in verses)

    kept = tuple(l for l in lines if l.top < 0 or not covered(l))
    return tuple(sorted(kept + verses, key=lambda l: l.top))


# ── shell ────────────────────────────────────────────────────────────────────

def measure_bands(png: Path) -> tuple[list[Band], int]:
    """Bands on a page plus the text-block width (the widest band's ink extent)."""
    import numpy as np
    from PIL import Image

    ink = np.asarray(Image.open(png).convert("L")) < 128
    bands = [
        Band(y0, y1, *g)
        for y0, y1 in bands_from_rows(ink.sum(axis=1).tolist())
        if (g := inner_gap(ink[y0:y1].any(axis=0).tolist()))
    ]
    return bands, max((b.width for b in bands), default=0)


def _read(crop: Path, tessdata: Path, out: Path) -> Line:
    """A hemistich crop as one line (psm 7); tesseract may still split it, so rejoin."""
    lines = parse_tsv(run_tesseract(crop, tessdata, 7, out))
    return Line(clean_line(" ".join(l.text for l in lines)), statistics.fmean([l.conf for l in lines] or [-1.0]))


def _best_crop_line(crop: Path, engines: dict[str, Path], out: Path) -> Line:
    return max((_read(crop, td, out / name) for name, td in engines.items()), key=lambda l: l.conf)


def ocr_verses(png: Path, engines: dict[str, Path], work: Path) -> tuple[Line, ...]:
    """Detect verse lines on a rendered page and OCR each hemistich as a single line."""
    from PIL import Image

    bands, text_width = measure_bands(png)
    verses = [b for b in bands if is_verse(b, text_width)]
    if not verses:
        return ()
    page = Image.open(png)
    out: list[Line] = []
    for b in verses:
        y0, y1 = max(0, b.y0 - PAD), b.y1 + PAD
        halves = {"r": (b.gap1 - PAD, b.x1 + PAD), "l": (b.x0 - PAD, b.gap0 + PAD)}
        crops = {}
        for side, (x0, x1) in halves.items():
            crop = work / "crops" / f"{png.stem}_y{b.y0:04d}_{side}.png"
            if not crop.exists():
                crop.parent.mkdir(parents=True, exist_ok=True)
                page.crop((max(0, x0), y0, x1, y1)).save(crop)
            crops[side] = _best_crop_line(crop, engines, work / "tsv-verse")
        line = verse_line(crops["r"], crops["l"], b.y0, b.y1)
        if not is_noise(line.text):
            out.append(line)
    return tuple(out)


# ── numbering ───────────────────────────────────────────────────────────────

MAX_BLOCK_BREAK = 2  # non-verse lines tolerated inside a verse block (running heads, folios)
_ARABIC = re.compile("[ء-ي]")
_DIGIT = re.compile("[0-9٠-٩۰-۹]")


# Genuine two-letter words that may open a verse; any other ≤ 2-letter opener is a misread number.
SHORT_WORDS = frozenset(normalize(w) for w in "ثم من في إن أن لا ما أو قد لم لن هو هي ذا عن إذ بل لو يا كم".split())


def verse_text(line: str) -> tuple[str, str]:
    """Split OCR'd «٨٩ - والأصل …» into (verse text, printed digits as read).

    The bold printed number reads as digits, dashes or short junk («بر», «4 -»).
    Tokens with digits or no Arabic letters are dropped, then at most one short
    opener that is not a known two-letter word.
    """
    toks = line.split()
    k = next((i for i, t in enumerate(toks) if _ARABIC.search(t) and not _DIGIT.search(t)), len(toks))
    if k < len(toks) - 1 and len(_ARABIC.findall(toks[k])) <= 2 and normalize(toks[k]) not in SHORT_WORDS:
        k += 1
    digits = normalize("".join(_DIGIT.findall("".join(toks[:k]))))
    return " ".join(toks[k:]), digits


def _blocks(idx: list[int]) -> list[list[int]]:
    """Group line indices into blocks broken by more than MAX_BLOCK_BREAK other lines."""
    cuts = [k for k in range(1, len(idx)) if idx[k] - idx[k - 1] - 1 > MAX_BLOCK_BREAK]
    return [idx[a:b] for a, b in zip([0, *cuts], [*cuts, len(idx)])] if idx else []


_BAR = re.compile(r"\s+[|]\s+")


def as_verse(line: str) -> str | None:
    """The line as a verse («… * …»), or None. Besides our own separator, accept the
    page-level reading where tesseract kept the hemistich gap as «|» — provided
    each side has at least two Arabic words (a two-column index row does not)."""
    if HEMISTICH_SEP.strip() in line.split():
        return line
    parts = _BAR.split(line)
    words = lambda t: sum(bool(_ARABIC.search(w)) for w in t.split())  # noqa: E731
    return HEMISTICH_SEP.join(parts) if len(parts) == 2 and min(map(words, parts)) >= 2 else None


def _matn(lines: list[tuple[str, "Page | None"]]) -> tuple[dict[int, str], list[int]]:
    """Verse lines by position, and the matn: the longest contiguous verse block."""
    verses = {i: v for i, (line, _) in enumerate(lines) if (v := as_verse(line))}
    return verses, max(_blocks(sorted(verses)), key=len, default=[])


def segment_verse_block(text: str) -> tuple[Unit, ...]:
    """Number the longest contiguous block of verse lines (the matn) by position.

    Shorter blocks (gapped lines in front matter, verses quoted in the commentary)
    are ignored; ties go to the earliest block.

    The printed number is a check, not the source: a unit is flagged
    ``ocr_corrected`` unless its readable printed digits agree with its position.
    """
    lines = _paged_lines(text)
    verses, block = _matn(lines)

    def unit(n: int, i: int) -> Unit:
        body, printed = verse_text(verses[i])
        agrees = bool(printed) and int(printed) % 10 ** len(printed) == n % 10 ** len(printed)
        return Unit(n, body, "", lines[i][1], (), not agrees)

    return tuple(unit(n, i) for n, i in enumerate(block, 1))


# ── commentary links ────────────────────────────────────────────────────────

LINK_THRESHOLD = 0.3   # trigram Jaccard; measured: quotations ≥ 0.3 (mostly 0.7–1.0), other text ≤ 0.2
LINK_STEP = 10         # consecutive linked verses may skip a few whose quotation OCR lost
INDEX_MARK = normalize("فهرس")  # the book's index ends the last verse's commentary
_NON_LETTER = re.compile("[^\u0621-\u064a ]")


def _trigrams(text: str) -> frozenset[str]:
    t = " ".join(_NON_LETTER.sub("", normalize(text)).split())
    return frozenset(t[k:k + 3] for k in range(len(t) - 2))


def similarity(a: str, b: str) -> float:
    """Character-trigram Jaccard similarity after normalisation (diacritics, OCR marks)."""
    ga, gb = _trigrams(a), _trigrams(b)
    return round(len(ga & gb) / len(ga | gb), 2) if ga | gb else 0.0


@dataclass(frozen=True)
class CommentaryLink:
    number: int            # verse number in the matn
    page: "Page | None"    # where the commentary starts (the quoted verse)
    end_page: "Page | None"
    quoted: str            # the verse as quoted in the commentary
    similarity: float      # against the matn verse
    commentary: str        # running commentary until the next linked verse


def link_commentary(text: str) -> tuple[CommentaryLink, ...]:
    """Align verse quotations after the matn to matn verses (best trigram match above
    LINK_THRESHOLD), keep the longest increasing chain, and attach the commentary that
    runs until the next linked quotation."""
    from .segment import _chain

    lines = _paged_lines(text)
    verses, block = _matn(lines)
    matn = [verse_text(verses[i])[0] for i in block]
    if not matn:
        return ()

    def best(i: int) -> tuple[int, float]:
        sims = [similarity(verse_text(verses[i])[0], m) for m in matn]
        n = max(range(len(sims)), key=sims.__getitem__)
        return n + 1, sims[n]

    scored = {i: best(i) for i in sorted(verses) if i > block[-1]}
    cands = [(i, (lambda n: lambda _p: (n, n, False))(n)) for i, (n, s) in scored.items() if s >= LINK_THRESHOLD]
    chain = _chain(cands, min_lines=1, max_step=LINK_STEP, late_start=False)
    tail = chain[-1][0] if chain else len(lines)
    index = next((k for k in range(tail + 1, len(lines)) if normalize(lines[k][0]).startswith(INDEX_MARK)), len(lines))
    ends = [pos for pos, *_ in chain[1:]] + [index]

    def link(pos: int, n: int, end: int) -> CommentaryLink:
        body = [line for line, _ in lines[pos + 1:end]]
        last = next((lines[k][1] for k in range(end - 1, pos, -1) if lines[k][1]), lines[pos][1])
        return CommentaryLink(n, lines[pos][1], last, verse_text(verses[pos])[0], scored[pos][1], "\n".join(body))

    return tuple(link(pos, n, end) for (pos, n, _, _), end in zip(chain, ends))
