"""IslamQA.info (al-Munajjid) fatāwā → normalised JSONL for the oracle.

The source is a community scrape pinned in ``corpus/fatawa/sources.json``; the
parquet and the JSONL live in the cache only (CC BY-NC 4.0, never committed).
One record per IslamQA answer id: its topics plus, per language, the first
non-empty title/question/answer/url found among the duplicate rows.
"""

from __future__ import annotations

from collections.abc import Iterable, Mapping
from itertools import groupby

FIELDS = (("title", "title"), ("question", "question"), ("answer", "answer"), ("url", "link"))


def _text(v: object) -> str | None:
    return v.strip() or None if isinstance(v, str) else None


def _lang(rows: list[Mapping], lang: str) -> dict | None:
    """First row whose answer in ``lang`` is non-empty, reduced to FIELDS."""
    row = next((r for r in rows if _text(r.get(f"answer_{lang}"))), None)
    return row and {k: _text(row.get(f"{col}_{lang}")) for k, col in FIELDS}


def normalize(rows: Iterable[Mapping], langs: tuple[str, ...]) -> list[dict]:
    key = lambda r: int(r["original_id"])  # noqa: E731
    out = []
    for oid, group in groupby(sorted(rows, key=key), key):
        group = list(group)
        texts = {l: t for l in langs if (t := _lang(group, l))}
        if texts:
            out.append({"id": f"islamqa.{oid}", "topics": sorted({r["topic"] for r in group}), **texts})
    return out
