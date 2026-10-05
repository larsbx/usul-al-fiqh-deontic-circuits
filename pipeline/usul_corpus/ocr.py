"""OCR for image-only witnesses: render → tesseract (several models) → per-page choice.

Pure core (parse_tsv, clean_line, quality, choose, page_markdown) plus a thin
subprocess shell (render, run_tesseract, ocr_pdf). Output is OpenITI-style
mARkdown with closing page markers, so the existing readers and segmenters apply.
Pages are PDF indices (``v01:pNNN`` = PDF page NNN), not printed folios.
"""

from __future__ import annotations

import hashlib
import os
import re
import statistics
import subprocess
import unicodedata
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from itertools import groupby
from pathlib import Path

LOW_CONF = 60.0

# Pinned tesseract models (LSTM). Each lives in its own tessdata dir under the cache.
MODELS = {
    "ara_std": (
        "https://raw.githubusercontent.com/tesseract-ocr/tessdata/main/ara.traineddata",
        "2005976778bbc14fc56a4ea8d43c6080847aeee72fcc2201488f240daca15c5b",
    ),
    "ara_best": (
        "https://raw.githubusercontent.com/tesseract-ocr/tessdata_best/main/ara.traineddata",
        "ab9d157d8e38ca00e7e39c7d5363a5239e053f5b0dbdb3167dde9d8124335896",
    ),
}


@dataclass(frozen=True)
class Line:
    text: str
    conf: float
    top: int = -1      # pixel extent on the rendered page (-1: unknown)
    bottom: int = -1


@dataclass(frozen=True)
class PageOCR:
    page: int
    engine: str
    lines: tuple[Line, ...]

    @property
    def mean_conf(self) -> float:
        return statistics.fmean(l.conf for l in self.lines) if self.lines else -1.0


def parse_tsv(tsv: str) -> tuple[Line, ...]:
    """Tesseract TSV → lines (word order is logical, i.e. right-to-left reading order)."""
    rows = [r.split("\t") for r in tsv.splitlines()[1:]]
    words = [
        ((int(r[2]), int(r[3]), int(r[4])), int(r[5]), float(r[10]), r[11].strip(), int(r[7]), int(r[7]) + int(r[9]))
        for r in rows
        if len(r) == 12 and r[0] == "5" and r[11].strip()
    ]
    return tuple(
        Line(
            " ".join(w[3] for w in ws),
            round(statistics.fmean(w[2] for w in ws), 2),
            min(w[4] for w in ws),
            max(w[5] for w in ws),
        )
        for _, g in groupby(sorted(words, key=lambda w: (w[0], w[1])), key=lambda w: w[0])
        for ws in [list(g)]
    )


_INVISIBLE = re.compile("[​-‏‪-‮⁦-⁩﻿]")
_LOOKALIKES = str.maketrans({"ی": "ي", "ک": "ك", "ہ": "ه", "ۀ": "ه"})
_GLUED_GUILLEMET = re.compile(r"(?<=[ء-ي])»(?=\s|$)")


def clean_line(raw: str) -> str:
    """Undo systematic OCR artifacts without touching genuine orthography."""
    s = _INVISIBLE.sub("", unicodedata.normalize("NFKC", raw)).translate(_LOOKALIKES)
    if "«" not in s:  # an unopened » glued to a word is the Arabic comma
        s = _GLUED_GUILLEMET.sub("،", s)
    return " ".join(s.split())


_ARABIC_LETTER = re.compile("[\u0621-\u064a]")
MIN_ARABIC_LETTERS = 3
MIN_ARABIC_SHARE = 0.5


def is_noise(line: str) -> bool:
    """Footnote debris, rules and stray marks: too few Arabic letters to be text."""
    letters = len(_ARABIC_LETTER.findall(line))
    visible = len(line.replace(" ", "")) or 1
    return letters < MIN_ARABIC_LETTERS or letters / visible < MIN_ARABIC_SHARE


def strip_running_heads(pages: tuple[PageOCR, ...], min_share: float = 0.2) -> tuple[PageOCR, ...]:
    """Drop lines that recur verbatim on at least ``min_share`` of pages (running heads)."""
    from collections import Counter

    counts = Counter(t for p in pages for t in {l.text for l in p.lines})
    heads = {t for t, c in counts.items() if c >= max(2, min_share * len(pages))}
    return tuple(PageOCR(p.page, p.engine, tuple(l for l in p.lines if l.text not in heads)) for p in pages)


FRAME_ZONE = 0.12      # a decorative border lies within the outer 12% of each side
FRAME_DENSITY = 0.25   # border bands: ≥ 25% ink per row/column (text columns stay ≤ ~0.1)
FRAME_RUN = 25         # … sustained over ≥ 25 px at 300 dpi
FRAME_DIP = 5          # zigzag bands dip briefly below the threshold; bridge dips ≤ 5 px


def frame_box(density: list[float], zone: float = FRAME_ZONE, min_density: float = FRAME_DENSITY,
              min_run: int = FRAME_RUN, pad: int = 10, max_dip: int = FRAME_DIP) -> tuple[int, int]:
    """Content interval [start, end) inside a decorative border along one axis.

    ``density`` is the ink share per column (or row). Within the edge zone on each
    side, the innermost run of ≥ ``min_run`` dense lines (dips ≤ ``max_dip`` bridged)
    is the border; content starts ``pad`` past it. Unframed sides keep the full extent.
    """
    n = len(density)
    dense = [d >= min_density for d in density]
    bands = [(a, b) for a, b in _bridge(runs(dense), max_dip) if b - a >= min_run]
    lead = [b for a, b in bands if b <= zone * n]
    trail = [a for a, b in bands if a >= (1 - zone) * n]
    return (max(lead) + pad if lead else 0), (min(trail) - pad if trail else n)


def _bridge(spans: list[tuple[int, int]], max_gap: int) -> list[tuple[int, int]]:
    """Merge consecutive spans separated by at most ``max_gap``."""
    merged: list[tuple[int, int]] = []
    for a, b in spans:
        merged = merged[:-1] + [(merged[-1][0], b)] if merged and a - merged[-1][1] <= max_gap else merged + [(a, b)]
    return merged


def runs(flags: list[bool]) -> list[tuple[int, int]]:
    """Maximal [start, end) runs of True."""
    edges = [i for i in range(len(flags) + 1)
             if (i < len(flags) and flags[i]) != (i > 0 and flags[i - 1])]
    return list(zip(edges[::2], edges[1::2]))


def quality(lines: tuple[Line, ...], low: float = LOW_CONF) -> dict:
    return {
        "mean_conf": round(statistics.fmean(l.conf for l in lines), 2) if lines else None,
        "low_conf_lines": sum(l.conf < low for l in lines),
        "lines": len(lines),
    }


def choose(passes: tuple[PageOCR, ...]) -> PageOCR:
    """Per-page engine choice: highest mean confidence, first on ties."""
    return max(passes, key=lambda p: p.mean_conf)


def page_markdown(p: PageOCR) -> str:
    body = "".join(f"# {l.text}\n" for l in p.lines if l.text)
    return f"{body}PageV01P{p.page:03d}\n"


# ── shell ────────────────────────────────────────────────────────────────────

def render(pdf: Path, page: int, out: Path, dpi: int) -> Path:
    png = out / f"p{page:04d}.png"
    if not png.exists():
        out.mkdir(parents=True, exist_ok=True)
        subprocess.run(
            ["pdftoppm", "-f", str(page), "-l", str(page), "-r", str(dpi), "-gray", "-png",
             "-singlefile", str(pdf), str(png.with_suffix(""))],
            check=True, capture_output=True,
        )
    return png


FRAME_PAD = 20  # clear the border band's ragged inner edge


def prepare(png: Path, frame: bool, denoise: str | None) -> Path:
    """Page image as OCR'd: optionally cropped inside its border (``frame_box`` on both
    axes) and median-filtered against scanner speckle. Cached next to the render."""
    if not (frame or denoise):
        return png
    out = png.with_name(f"{png.stem}{'c' if frame else ''}{'m' if denoise else ''}.png")
    if not out.exists():
        import numpy as np
        from PIL import Image, ImageFilter

        page = Image.open(png).convert("L")
        if frame:
            ink = np.asarray(page) < 128
            x0, x1 = frame_box(ink.mean(axis=0).tolist(), pad=FRAME_PAD)
            y0, y1 = frame_box(ink.mean(axis=1).tolist(), pad=FRAME_PAD)
            page = page.crop((x0, y0, x1, y1))
        if denoise == "median3":
            page = page.filter(ImageFilter.MedianFilter(3))
        page.save(out)
    return out


def run_tesseract(png: Path, tessdata: Path, psm: int, out: Path) -> str:
    tsv = out / f"{png.stem}.tsv"
    if not tsv.exists():
        out.mkdir(parents=True, exist_ok=True)
        r = subprocess.run(
            ["tesseract", str(png), "stdout", "--tessdata-dir", str(tessdata), "-l", "ara",
             "--psm", str(psm), "tsv"],
            check=True, capture_output=True, text=True, env={**os.environ, "OMP_THREAD_LIMIT": "1"},
        )
        tsv.write_text(r.stdout, encoding="utf-8")
    return tsv.read_text(encoding="utf-8")


def ensure_model(name: str, cache: Path) -> Path:
    """Download a pinned model into ``cache/<name>/`` (verified by sha256); return the tessdata dir."""
    from .fetch import _get

    url, sha = MODELS[name]
    tessdata = cache / name
    model = tessdata / "ara.traineddata"
    if not model.exists():
        data = _get(url)
        if hashlib.sha256(data).hexdigest() != sha:
            raise ValueError(f"model {name}: sha256 mismatch for {url}")
        (tessdata / "configs").mkdir(parents=True, exist_ok=True)
        model.write_bytes(data)
        (tessdata / "configs" / "tsv").write_text("tessedit_create_tsv 1\n")
    return tessdata


def tesseract_version() -> str:
    return subprocess.run(["tesseract", "--version"], capture_output=True, text=True).stdout.split("\n")[0]


def pdf_pages(pdf: Path) -> int:
    info = subprocess.run(["pdfinfo", str(pdf)], check=True, capture_output=True, text=True).stdout
    return int(re.search(r"^Pages:\s+(\d+)", info, re.M).group(1))


def ocr_pdf(
    pdf: Path, work: Path, engines: dict[str, Path], dpi: int = 300, psm: int = 4,
    pages: range | None = None, jobs: int = os.cpu_count() or 1, verses: range | None = None,
    frame: bool = False, denoise: str | None = None,
) -> tuple[tuple[PageOCR, ...], tuple[PageOCR, ...]]:
    """OCR every page with every engine; return (chosen pages, all passes).

    On pages in ``verses``, detected verse lines are re-read per hemistich and
    replace the page-level lines they overlap (see ``verses.py``). ``frame`` and
    ``denoise`` select the image preparation (see ``prepare``).
    """
    from .verses import merge_verses, ocr_verses

    def one(page: int) -> tuple[PageOCR, ...]:
        png = render(pdf, page, work / "png", dpi)
        png = prepare(png, frame, denoise)
        return tuple(
            PageOCR(page, name, tuple(
                Line(t, l.conf, l.top, l.bottom)
                for l in parse_tsv(run_tesseract(png, td, psm, work / "tsv" / name))
                if (t := clean_line(l.text)) and not is_noise(t)
            ))
            for name, td in engines.items()
        )

    def with_verses(page: PageOCR) -> PageOCR:
        if page.page not in verses:
            return page
        found = ocr_verses(render(pdf, page.page, work / "png", dpi), engines, work)
        return PageOCR(page.page, page.engine, merge_verses(page.lines, found)) if found else page

    with ThreadPoolExecutor(max_workers=jobs) as pool:
        passes = tuple(pool.map(one, pages or range(1, pdf_pages(pdf) + 1)))
        chosen = tuple(choose(p) for p in passes)
        if verses:
            chosen = tuple(pool.map(with_verses, chosen))
    return strip_running_heads(chosen), tuple(x for p in passes for x in p)
