"""Reading printed paragraph numbers that page-level Arabic OCR garbles.

A numbered paragraph opens «١٠٥ ـ …». The ``ara`` models misread the
Arabic-Indic digits, so the number cluster at the right edge of each such line
is cropped and read with tesseract's ``script/Arabic`` model, whose remaining
errors are the classic confusions: ٠ (a dot) read as «.», ٥ (a ring) as «0».
The digits, even partial, then feed the numbering chain's suffix repair.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

from .arabic import normalize
from .ocr import Line, parse_tsv, run_tesseract, runs

NUMBER_MODEL = "arabic_script"
_DASHED = re.compile(r"^(\S{1,5})\s*[-ـ–—]\s*(?=\S)")       # «4 - …», «بر - …»
_BARE_DASH = re.compile(r"^([-ـ–—])\s+(?=\S)")                # «- …»: digits lost, dash kept
_DIGIT_LED = re.compile(r"^([-ـ–—]?\S{0,4}[0-9٠-٩۰-۹]\S{0,4})\s+(?=\S)")  # «1١ …», «-١ …»
_ARABIC = re.compile("[ء-ي]")
_CONFUSABLE = str.maketrans({".": "0", "·": "0", "٫": "0", "0": "5", "o": "5", "O": "5"})
_INDIC = str.maketrans("0123456789", "٠١٢٣٤٥٦٧٨٩")


def read_number(raw: str) -> str | None:
    """Digits of a cropped paragraph number, or None when the crop reads as words."""
    if len(_ARABIC.findall(raw)) >= 2:
        return None
    digits = re.sub(r"\D", "", normalize(raw.translate(_CONFUSABLE)))
    return digits or None


def _number_prefix(line: str) -> re.Match | None:
    """The garbled number at the start of a line: a digit-bearing first token
    («1١ …», «-١ …»), a short non-word token before a dash («4 - …», «بر - …»),
    or a bare leading dash whose digits were lost («- …»)."""
    m = _DIGIT_LED.match(line) or _DASHED.match(line) or _BARE_DASH.match(line)
    return m if m and len(_ARABIC.findall(m.group(1))) <= 2 else None


def is_numbered_start(line: str) -> bool:
    return _number_prefix(line) is not None


def with_number(line: str, digits: str) -> str:
    """Replace the garbled number prefix with the digits read from the crop."""
    m = _number_prefix(line)
    rest = line[m.end():] if m else line
    return f"{digits.translate(_INDIC)} - {rest.lstrip('-ـ–— ')}"


# ── the number span ─────────────────────────────────────────────────────────

@dataclass(frozen=True)
class Glyph:
    """A column-run of ink on a text line: [x0, x1) and its ink height (pixels)."""
    x0: int
    x1: int
    height: int


DASH_MAX_HEIGHT = 9     # «ـ» is a flat stroke (measured 6 px at 300 dpi) …
DASH_MIN_ASPECT = 2.0   # … at least twice as wide as tall; «٠» is a square dot
NUMBER_REACH = 260      # the dash sits within this distance of the line's right edge


def _is_dash(g: Glyph) -> bool:
    return g.height <= DASH_MAX_HEIGHT and (g.x1 - g.x0) >= DASH_MIN_ASPECT * g.height


def number_span(glyphs: list[Glyph]) -> tuple[int, int] | None:
    """[dash end, right edge] for «١٠٥ ـ …»: the number is everything right of the
    first dash-shaped glyph near the right edge; None when there is no such dash."""
    if not glyphs:
        return None
    right = glyphs[-1].x1
    dash = next((g for g in reversed(glyphs[:-1]) if right - g.x0 <= NUMBER_REACH and _is_dash(g)), None)
    return (dash.x1, right) if dash else None


def line_glyphs(band) -> list[Glyph]:
    """Column-runs of a binarised line band (numpy bool array), left to right."""
    import numpy as np

    return [
        Glyph(a, b, int(ys[-1] - ys[0] + 1))
        for a, b in runs(band.any(axis=0).tolist())
        if len(ys := np.nonzero(band[:, a:b].any(axis=1))[0])
    ]


# ── digit glyphs ─────────────────────────────────────────────────────────────

GLYPH_SIZE = 16   # glyph masks are compared at 16 × 16
MIN_AREA = 50     # px at crop scale: specks measure 12–32, the smallest digit («٠», a dot) ~ 90
GLYPH_SCALE = 64  # px: all crops share dpi and scale, so absolute glyph size is a stable feature


@dataclass(frozen=True)
class Component:
    x0: int
    x1: int
    y0: int
    y1: int
    mask: "object"   # numpy bool array of the bounding box


def components(a, min_area: int = MIN_AREA) -> list[Component]:
    """8-connected components of a bool image, left to right (Arabic-Indic numbers
    are written left to right, so this is digit order)."""
    import numpy as np

    seen = np.zeros_like(a, dtype=bool)
    h, w = a.shape
    out: list[Component] = []
    for y, x in zip(*np.nonzero(a)):
        if seen[y, x]:
            continue
        stack, pts = [(y, x)], []
        seen[y, x] = True
        while stack:
            cy, cx = stack.pop()
            pts.append((cy, cx))
            for ny in range(max(cy - 1, 0), min(cy + 2, h)):
                for nx in range(max(cx - 1, 0), min(cx + 2, w)):
                    if a[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        stack.append((ny, nx))
        if len(pts) >= min_area:
            ys, xs = zip(*pts)
            y0, y1, x0, x1 = min(ys), max(ys) + 1, min(xs), max(xs) + 1
            mask = np.zeros((y1 - y0, x1 - x0), dtype=bool)
            mask[[p - y0 for p in ys], [p - x0 for p in xs]] = True
            out.append(Component(x0, x1, y0, y1, mask))
    return sorted(out, key=lambda c: c.x0)


def _vector(c: Component, line_height: int):
    """Shape (mask resized to GLYPH_SIZE²) plus relative height and width: «٠» is small."""
    import numpy as np
    from PIL import Image

    shape = np.asarray(Image.fromarray(c.mask.astype("uint8") * 255).resize((GLYPH_SIZE, GLYPH_SIZE))) > 127
    size = np.array([(c.y1 - c.y0) / line_height, (c.x1 - c.x0) / line_height]) * GLYPH_SIZE
    return np.concatenate([shape.ravel().astype(float), size])


@dataclass(frozen=True)
class Templates:
    """Nearest-neighbour digit classifier over labelled glyph exemplars."""
    vectors: "object"
    labels: tuple[str, ...]

    @classmethod
    def fit(cls, examples: list[tuple[tuple[Component, int], str]]) -> "Templates":
        import numpy as np

        return cls(np.array([_vector(c, h) for (c, h), _ in examples]), tuple(d for _, d in examples))

    def classify(self, c: Component, line_height: int) -> str:
        import numpy as np

        d = np.abs(self.vectors - _vector(c, line_height)).sum(axis=1)
        return self.labels[int(d.argmin())]


# ── shell ────────────────────────────────────────────────────────────────────

CROP_SCALE, CROP_BORDER = 2, 30


def _overlaps(l: Line, band: tuple[int, int]) -> bool:
    return l.top >= 0 and min(l.bottom, band[1]) - max(l.top, band[0]) > (band[1] - band[0]) / 2


def attach_bands(
    lines: tuple[Line, ...], alternatives: tuple[Line, ...], bands: list[tuple[int, int]],
) -> tuple[tuple[Line, ...], list[int]]:
    """Map each numbered image band to a text line: the chosen read's overlapping line,
    else the other model's (the chosen read may have dropped it), else an empty line.
    Returns the lines (in reading order) and, per band, its line index."""
    added = [
        next((a for a in alternatives if _overlaps(a, b)), Line("", 0.0, b[0], b[1]))
        for b in bands if not any(_overlaps(l, b) for l in lines)
    ]
    merged = tuple(sorted(lines + tuple(added), key=lambda l: l.top))
    return merged, [next(i for i, l in enumerate(merged) if _overlaps(l, b)) for b in bands]


def number_bands(ink) -> list[tuple[tuple[int, int], tuple[int, int]]]:
    """(band, number span) for every image line that opens «<number> ـ»."""
    from .verses import bands_from_rows

    return [
        ((y0, y1), span)
        for y0, y1 in bands_from_rows(ink.sum(axis=1).tolist())
        if (span := number_span(line_glyphs(ink[y0:y1])))
    ]


def number_crops(
    png: Path, lines: tuple[Line, ...], alternatives: tuple[Line, ...], work: Path,
) -> tuple[tuple[Line, ...], list[tuple[int, Path]]]:
    """Lines (with any numbered line the chosen read dropped restored) and (line index,
    crop) per numbered line; the crop starts just right of the dash, so it holds digits only."""
    import numpy as np
    from PIL import Image, ImageOps

    page = Image.open(png).convert("L")
    found = number_bands(np.asarray(page) < 128)
    lines, idx = attach_bands(lines, alternatives, [b for b, _ in found])
    out: list[tuple[int, Path]] = []
    for i, ((y0, y1), span) in zip(idx, found):
        crop = work / "numbers" / f"{png.stem}_y{y0:04d}.png"
        if not crop.exists():
            crop.parent.mkdir(parents=True, exist_ok=True)
            box = page.crop((span[0] + 2, max(0, y0 - 4), span[1] + 4, y1 + 4))
            box = box.resize((box.width * CROP_SCALE, box.height * CROP_SCALE))
            ImageOps.expand(box, border=CROP_BORDER, fill=255).save(crop)
        out.append((i, crop))
    return lines, out


def crop_glyphs(crop: Path) -> tuple[list[Component], int]:
    """Digit glyphs of a crop, left to right, and the (fixed) scale sizes are measured against.

    The scale is a constant: crop heights vary with neighbouring ascenders and
    descenders, but every crop shares dpi and magnification."""
    import numpy as np
    from PIL import Image

    return components(np.asarray(Image.open(crop).convert("L")) < 128), GLYPH_SCALE


def exemplar_templates(
    crops: dict[int, list[tuple[int, Path]]], exemplars: list[dict],
) -> tuple[list[tuple[tuple[Component, int], str]], dict]:
    """Labelled glyphs from pages whose printed numbers were verified by eye, with a
    leave-one-page-out accuracy estimate. A page is used only when its crop count
    matches its numbers and every crop splits into exactly as many glyphs as digits."""
    labelled: dict[int, list[tuple[tuple[Component, int], str]]] = {}
    for ex in exemplars:
        page_crops = crops.get(ex["page"], [])
        if len(page_crops) != len(ex["numbers"]):
            continue
        glyphs = [crop_glyphs(c) for _, c in page_crops]
        if all(len(g) == len(str(n)) for (g, _), n in zip(glyphs, ex["numbers"])):
            labelled[ex["page"]] = [((c, h), d) for (g, h), n in zip(glyphs, ex["numbers"]) for c, d in zip(g, str(n))]
    if not labelled:
        return [], {"exemplar_pages": []}
    held_out = [
        (Templates.fit([e for q, es in labelled.items() if q != p for e in es]).classify(*x), d)
        for p in labelled if len(labelled) > 1 for x, d in labelled[p]
    ]
    return [e for es in labelled.values() for e in es], {
        "exemplar_pages": sorted(labelled),
        "exemplar_glyphs": sum(len(es) for es in labelled.values()),
        "leave_one_page_out_digit_accuracy": round(sum(a == b for a, b in held_out) / len(held_out), 3) if held_out else None,
    }


def confirmed_labels(reads: list[str], chain: list[tuple[int, int, bool]]) -> list[tuple[int, str]]:
    """(read index, digits) where the read is exactly the chain's number — same value
    and same digit count — so each glyph's label is known."""
    return [(k, str(n)) for k, n, corrected in chain if not corrected and reads[k] == str(n)]


SELF_TRAIN_ROUNDS = 2


def self_train(
    ordered: list[Path], exemplars: list[tuple[tuple[Component, int], str]], anchor_step: int | None,
    rounds: int = SELF_TRAIN_ROUNDS,
) -> tuple[list[str | None], list[dict]]:
    """Read crops (document order) with templates refitted on chain-confirmed glyphs.

    Round 0 uses the eye-verified exemplars only; each round adds every glyph of every
    crop whose read the numbering chain confirms (``confirmed_labels``), refits, rereads.
    """
    from .segment import number_chain

    glyphs = [crop_glyphs(c) for c in ordered]
    examples = list(exemplars)
    history: list[dict] = []
    for r in range(rounds + 1):
        t = Templates.fit(examples)
        reads = ["".join(t.classify(c, h) for c in g) or None for g, h in glyphs]
        present = [k for k, d in enumerate(reads) if d]
        chain = [(present[k], n, c) for k, n, c in number_chain([reads[i] for i in present], anchor_step)]
        confirmed = confirmed_labels(reads, chain)  # type: ignore[arg-type]
        history.append({"round": r, "templates": len(examples), "chain": len(chain), "confirmed": len(confirmed)})
        examples = list(exemplars) + [
            ((c, glyphs[k][1]), d) for k, digits in confirmed for c, d in zip(glyphs[k][0], digits)
        ]
    return reads, history


def read_crop(crop: Path, templates: Templates) -> str | None:
    glyphs, height = crop_glyphs(crop)
    return "".join(templates.classify(c, height) for c in glyphs) or None


def _line_text(png: Path, tessdata: Path, out: Path) -> str:
    return " ".join(l.text for l in parse_tsv(run_tesseract(png, tessdata, 7, out)))


def renumber(lines: tuple[Line, ...], reads: dict[int, str]) -> tuple[Line, ...]:
    """Rewrite the number prefix of each line that has a read."""
    return tuple(
        Line(with_number(l.text, reads[i]), l.conf, l.top, l.bottom) if i in reads else l
        for i, l in enumerate(lines)
    )


def tesseract_read(crop: Path, tessdata: Path, work: Path) -> str | None:
    """Fallback without exemplars: tesseract (script/Arabic) on one crop."""
    return read_number(_line_text(crop, tessdata, work / "tsv-numbers"))
