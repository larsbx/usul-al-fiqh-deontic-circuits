"""Arabic normalization and ordinal parsing for qāʿida headers.

Normalization is lossy by design: it exists for matching and segmentation,
never for the stored text of a record.
"""

from __future__ import annotations

import re
import unicodedata
from functools import lru_cache, reduce

_DIACRITICS = re.compile("[ؐ-ًؚ-ٰٟۖ-ۭ]")
_INVISIBLE = re.compile("[ـ​-‏‪-‮⁦-⁩﻿]")
_LETTERS = str.maketrans(
    {"أ": "ا", "إ": "ا", "آ": "ا", "ٱ": "ا", "ى": "ي", "ة": "ه", "ؤ": "و", "ئ": "ي", "ک": "ك", "ی": "ي"}
)
_DIGITS = str.maketrans("٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹", "01234567890123456789")


def normalize(s: str) -> str:
    """Strip diacritics, tatweel and bidi marks; unify letter variants and digits."""
    s = _INVISIBLE.sub("", _DIACRITICS.sub("", s))
    return " ".join(s.translate(_LETTERS).translate(_DIGITS).split())


def _lexicon(pairs: dict[str, int]) -> dict[str, int]:
    return {normalize(k): v for k, v in pairs.items()}


# Feminine (qāʿida) and masculine (aṣl, masʾala) unit ordinals.
UNITS = _lexicon(
    {
        "الأولى": 1, "الأول": 1, "الحادية": 1, "الحادي": 1,
        "الثانية": 2, "الثاني": 2, "الثالثة": 3, "الثالث": 3,
        "الرابعة": 4, "الرابع": 4, "الخامسة": 5, "الخامس": 5,
        "السادسة": 6, "السادس": 6, "السابعة": 7, "السابع": 7,
        "الثامنة": 8, "الثامن": 8, "التاسعة": 9, "التاسع": 9,
        "العاشرة": 10, "العاشر": 10,
    }
)
TEEN = _lexicon({"عشرة": 10, "عشر": 10})
TENS = _lexicon(
    {
        "العشرون": 20, "العشرين": 20, "الثلاثون": 30, "الثلاثين": 30,
        "الأربعون": 40, "الأربعين": 40, "الخمسون": 50, "الخمسين": 50,
        "الستون": 60, "الستين": 60, "السبعون": 70, "السبعين": 70,
        "الثمانون": 80, "الثمانين": 80, "التسعون": 90, "التسعين": 90,
    }
)
HUNDRED = _lexicon({"المائة": 100, "المئة": 100})
FILLER = frozenset({normalize("بعد")})
LEXICON = {**UNITS, **TEEN, **TENS, **HUNDRED}


def _levenshtein(a: str, b: str) -> int:
    def row(prev: list[int], ca: str) -> list[int]:
        return reduce(
            lambda acc, jb: acc + [min(prev[jb[0] + 1] + 1, acc[-1] + 1, prev[jb[0]] + (ca != jb[1]))],
            enumerate(b),
            [prev[0] + 1],
        )

    return reduce(row, a, list(range(len(b) + 1)))[-1]


def _lookup(token: str, fuzzy: bool) -> tuple[str, bool] | None:
    """Resolve a token to a lexicon key; the flag says whether OCR correction was needed."""
    if token in LEXICON:
        return token, False
    if not fuzzy or len(token) < 5:
        return None
    near = sorted((_levenshtein(token, k), k) for k in LEXICON if abs(len(k) - len(token)) <= 1)
    best = [k for d, k in near if d == 1]
    return (best[0], True) if len(best) == 1 else None


def _tokens(phrase: str) -> list[str]:
    words = normalize(phrase).replace("(", " ").replace(")", " ").replace(":", " ").split()
    # Conjunctive wāw is prefixed: والعشرون → العشرون
    return [w[1:] if w.startswith("وال") else w for w in words if w not in FILLER]


def parse_ordinal(phrase: str, fuzzy: bool = True) -> tuple[int, bool] | None:
    """Parse an Arabic ordinal (1..199) into (value, ocr_corrected).

    Returns None for unknown tokens and for ambiguous phrases with more than
    one unit or tens component (e.g. a scan that merges two headings).
    """
    toks = _tokens(phrase)
    if not toks:
        return None
    resolved = [_lookup(t, fuzzy) for t in toks]
    if any(r is None for r in resolved):
        return None
    keys = [k for k, _ in resolved]  # type: ignore[misc]
    units, teen, tens, hundred = (sum(k in g for k in keys) for g in (UNITS, TEEN, TENS, HUNDRED))
    if max(units, teen, tens, hundred) > 1 or (teen and (tens or not units)):
        return None
    return sum(LEXICON[k] for k in keys), any(c for _, c in resolved)  # type: ignore[misc]


def parse_ordinal_span(phrase: str, fuzzy: bool = True) -> tuple[tuple[int, int], bool] | None:
    """Like ``parse_ordinal`` but also reads joint headings for consecutive rules:
    «الثانية والثالثة والعشرون» → (22, 23). Single ordinals give (n, n)."""
    single = parse_ordinal(phrase, fuzzy)
    if single:
        return (single[0], single[0]), single[1]
    toks = _tokens(phrase)
    resolved = [_lookup(t, fuzzy) for t in toks]
    if not toks or any(r is None for r in resolved):
        return None
    keys = [k for k, _ in resolved]  # type: ignore[misc]
    units = [UNITS[k] for k in keys if k in UNITS]
    rest = [k for k in keys if k not in UNITS]
    if len(units) != 2 or units[1] != units[0] + 1:
        return None
    base = parse_ordinal(" ".join(rest), fuzzy) if rest else (0, False)
    if base is None:
        return None
    return (base[0] + units[0], base[0] + units[1]), base[1] or any(c for _, c in resolved)  # type: ignore[misc]


_MARKERS = re.compile(r"ms\d+|PageV\d+P\d+")
_PAGE = re.compile(r"PageV(\d+)P(\d+)")


def letters(s: str) -> str:
    """Arabic letters only: the comparison key for verbatim excerpts."""
    return re.sub(r"[^ء-ي]", "", _MARKERS.sub("", s))


def words(s: str) -> list[str]:
    """The normalized words of ``s``, letters only, empty ones dropped."""
    return [w for w in (letters(x) for x in normalize(s).split()) if w]


def revolume(text: str) -> str:
    """Shamela fetches mark every page `PageV01`; Shamela numbers pages per volume, so a page number
    that goes back starts the next volume. Texts whose markers already name volumes are unchanged."""
    if any(m.group(1) != "01" for m in _PAGE.finditer(text)):
        return text
    state = {"vol": 1, "prev": -1}

    def mark(m: re.Match) -> str:
        n = int(m.group(2))
        state["vol"] += n < state["prev"]
        state["prev"] = n
        return f"PageV{state['vol']:02d}P{m.group(2)}"

    return _PAGE.sub(mark, text)


# The quotation key: Arabic letters, and each standalone numeral as a delimited token in Western
# digits. A presentation form (the ligature «ﻻ», U+FEFB) keys as its NFKC letters. Recognized markup
# carries no key: page markers, and footnote anchors (digits glued to the preceding word, Shamela's
# `العلماء1`, or negated in parentheses, `(¬7)`).
_FORMS = "\ufb50-\ufdff\ufe70-\ufefc"
_QUOTE = re.compile(rf"PageV\d+P\d+|\(¬[0-9٠-٩۰-۹]+\)|(?<![ء-ي\u064b-\u06520-9٠-٩۰-۹])([0-9٠-٩۰-۹]+)|([ء-ي])|([{_FORMS}])")
_ARABIC_BLOCKS = re.compile(rf"[\u0600-\u06ff\u0750-\u077f\u08a0-\u08ff{_FORMS}]")


def _unfold(c: str) -> str:
    return unicodedata.normalize("NFKC", c) if re.match(f"[{_FORMS}]", c) else c


def _quote_pieces(s: str):
    """(start, end, key piece) for each keyed unit of ``s``."""
    for m in _QUOTE.finditer(s):
        if m[1]:
            yield m.start(), m.end(), f"#{m[1].translate(_DIGITS)}#"
        elif m[2]:
            yield m.start(), m.end(), m[2]
        elif m[3] and (k := "".join(c for c in _unfold(m[3]) if "ء" <= c <= "ي")):
            yield m.start(), m.end(), k


def stray(s: str) -> str:
    """The Arabic letters of ``s`` the quotation key does not carry, which a comparison would skip."""
    return "".join(sorted({c for c in "".join(map(_unfold, s)) if _ARABIC_BLOCKS.match(c)
                           and unicodedata.category(c).startswith("L") and not "ء" <= c <= "ي"}))


def is_letter(c: str) -> bool:
    """An Arabic letter, in any block: what a word is made of."""
    return bool(_ARABIC_BLOCKS.match(c)) and unicodedata.category(c).startswith("L")


def quote_key(s: str) -> str:
    """The comparison key for verbatim excerpts: letters and substantive numerals."""
    return "".join(k for _, _, k in _quote_pieces(re.sub(r"ms\d+", "", s)))


@lru_cache(maxsize=4)
def _indexed(text: str) -> tuple[str, list[int], str]:
    """The revolumed text, a source position for each character of its quotation key, and the key.
    A numeral's delimiters map to its first and last digit, so a match's span covers it."""
    text = re.sub(r"ms\d+", "", revolume(text))
    pieces = list(_quote_pieces(text))
    idx = [i for a, b, k in pieces for i in ([a] if len(k) == 1 else [a] * (len(k) - 1) + [b - 1])]
    return text, idx, "".join(k for _, _, k in pieces)


def locate(text: str, excerpt: str) -> str | None:
    """`v<vol>:p<page>` of the page an excerpt ends on (the next page marker closes it), comparing
    quotation keys; None when the excerpt is not in the text."""
    text, idx, flat = _indexed(text)
    e = quote_key(excerpt)
    k = flat.find(e)
    if k < 0:
        return None
    m = _PAGE.search(text[idx[k + len(e) - 1]:])
    return f"v{m[1]}:p{m[2]}" if m else None
