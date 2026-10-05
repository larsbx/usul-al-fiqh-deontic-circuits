"""Arabic normalization and ordinal parsing for qāʿida headers.

Normalization is lossy by design: it exists for matching and segmentation,
never for the stored text of a record.
"""

from __future__ import annotations

import re
from functools import reduce

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
