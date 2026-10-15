"""Extract ḥudūd (lughatan / iṣṭilāḥan definitions) from bracket-headed sections."""

from __future__ import annotations

import re
from dataclasses import dataclass

from .openiti import Page, Section

_MARKS = "[ً-ٰٟـ]*"


def _loose(word: str) -> str:
    """Regex matching ``word`` with any diacritics/tatweel between its letters."""
    return _MARKS.join(re.escape(c) for c in word) + _MARKS


_LUGHA = re.compile(_loose("لغة") + r"\s*:\s*([^.]+)")
_ISTILAH = re.compile("و?" + _loose("اصطلاحا") + r"\s*:\s*([^.]+)")
_ENUM = re.compile(r"^[\d٠-٩]+\s*-\s*")
_CONJ_DEF = re.compile(r"^[فو](?=ال)")
_MAX_TERM_WORDS = 2


@dataclass(frozen=True)
class Hadd:
    term: str
    lughatan: str | None
    istilahan: str
    page: Page | None


def _title_term(title: str) -> str:
    t = title.strip().strip("[]").strip()
    return t.removeprefix("تعريف ").strip() or t


def _lugha_term(para: str, at: int) -> str | None:
    """«١ - فالواجب لغة: …» → «الواجب»; None when the prefix is not a bare term."""
    prefix = _CONJ_DEF.sub("", _ENUM.sub("", para[:at].strip(" :،")))
    return prefix if prefix and len(prefix.split()) <= _MAX_TERM_WORDS else None


def _section_hudud(s: Section) -> list[Hadd]:
    """One ḥadd per iṣṭilāḥī definition, paired with the nearest preceding lughawī one."""
    out: list[Hadd] = []
    lugha: tuple[str | None, str] | None = None  # (term, lughatan) awaiting its iṣṭilāḥ
    for para in s.text.split("\n"):
        istilah = _ISTILAH.search(para)
        lm = _LUGHA.search(para[: istilah.start()] if istilah else para)
        if lm:
            lugha = (_lugha_term(para, lm.start()), lm.group(1).strip())
        if istilah:
            term = (lugha and lugha[0]) or _title_term(s.title)
            out.append(Hadd(term, lugha[1] if lugha else None, istilah.group(1).strip(), s.page))
            lugha = None
    return out


def extract_hudud(sections: tuple[Section, ...]) -> tuple[Hadd, ...]:
    return tuple(h for s in sections for h in _section_hudud(s))
