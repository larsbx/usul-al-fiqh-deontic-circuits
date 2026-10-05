"""Minimal OpenITI mARkdown reader: headers, page markers, paragraphs."""

from __future__ import annotations

import re
from dataclasses import dataclass

Page = tuple[int, int]

_PAGE = re.compile(r"PageV(\d+)P(\d+)")
_HEADER = re.compile(r"^###\s*(\|+)\s*(.*)$")


@dataclass(frozen=True)
class Section:
    level: int
    title: str
    text: str
    page: Page | None
    end_page: Page | None


def _clean(line: str) -> str:
    line = _PAGE.sub("", line)
    for prefix in ("~~", "#"):
        if line.startswith(prefix):
            line = line[len(prefix):]
    return line.strip()


def parse_markdown(source: str) -> tuple[Section, ...]:
    """Split an OpenITI text into header-delimited sections with page spans.

    OpenITI page markers *close* a page: text before ``PageV01P007`` is on page 7.
    A section's ``page`` is the first marker at or after its header; ``end_page``
    the first marker at or after its last line (None if the text ends unmarked).
    Continuation lines (``~~``) join their paragraph; paragraphs are newline-separated.
    """
    body = source.split("#META#Header#End#", 1)[-1]
    titles: list[tuple[int, str]] = []
    texts: list[list[str]] = []
    pages: list[Page | None] = []
    ends: list[Page | None] = []
    awaiting_start: set[int] = set()
    awaiting_end: set[int] = set()

    for raw in body.splitlines():
        header = _HEADER.match(raw)
        if header:
            titles.append((len(header.group(1)), _clean(header.group(2))))
            texts.append([])
            pages.append(None)
            ends.append(None)
            awaiting_start.add(len(titles) - 1)
            awaiting_end.add(len(titles) - 1)
        elif titles and _clean(raw):
            paras = texts[-1]
            if raw.startswith("~~") and paras:
                paras[-1] = f"{paras[-1]} {_clean(raw)}"
            else:
                paras.append(_clean(raw))
            awaiting_end.add(len(titles) - 1)
        for m in _PAGE.finditer(raw):
            page = (int(m.group(1)), int(m.group(2)))
            for i in awaiting_start:
                pages[i] = page
            for i in awaiting_end:
                ends[i] = page
            awaiting_start, awaiting_end = set(), set()

    return tuple(
        Section(level, title, "\n".join(text), page, end)
        for (level, title), text, page, end in zip(titles, texts, pages, ends)
    )
