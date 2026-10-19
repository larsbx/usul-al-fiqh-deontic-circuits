"""Scope: which furūʿ fall under a qāʿida type, defined by the texts' own placement (PR-50).

A qāʿida type is read from one or more source qawāʿid, the ones its statement cites. In the
texts each qāʿida is followed by its furūʿ, so the text itself fixes a qāʿida's extension: the
furūʿ the author put under it. A type's **scope** is the opening clause (the question, before the
ruling) of every farʿ the segmented witness places under a qāʿida the type cites, verbatim.

Ibn Rajab and Ibn al-Laḥḥām are segmented into furūʿ; al-Saʿdī's qawāʿid are not, so a type read
only from al-Saʿdī has no scope beyond its statement.
"""

from __future__ import annotations

import json
import re
from functools import cache
from pathlib import Path

WITNESSES = {"Ibn Rajab": "openiti-rajab-shamela21730", "Ibn al-Laḥḥām": "openiti-lahham-shamela8526"}
CITE = re.compile(r"(Ibn Rajab|Ibn al-Laḥḥām) Q?(\d+)")
STOP = re.compile(r"[؟،.:;]| فهل | هل | على (?:روايتين|وجهين|ثلاثة)")
WORDS = 14


def sources(name: str, statement: str) -> list[tuple[str, int]]:
    """The segmented qawāʿid a type is read from: those its statement cites, and its own number
    for an ``rajabN`` type."""
    own = [("Ibn Rajab", int(m[1]))] if (m := re.fullmatch(r"rajab(\d+)(?:_\w+)?", name)) else []
    return sorted(set(own + [(a, int(n)) for a, n in CITE.findall(statement)]))


def head(case: str) -> str:
    """A farʿ's opening clause: up to its first question mark, clause mark or question particle,
    at most ``WORDS`` words. A prefix of the witness text, so verbatim by construction."""
    words = STOP.split(case.strip(), maxsplit=1)[0].split()
    return " ".join(words[:WORDS])


@cache
def furu(corpus: Path) -> dict[tuple[str, int], list[tuple[str, str]]]:
    """(author, qāʿida number) → [(farʿ id, head)], every farʿ the witness places under it."""
    out: dict[tuple[str, int], list[tuple[str, str]]] = {}
    for author, w in WITNESSES.items():
        for line in (corpus / "records" / f"{w}.jsonl").read_text(encoding="utf-8").splitlines():
            r = json.loads(line)
            if r.get("record_type") == "far" and (h := head(r["case_ar"])):
                out.setdefault((author, int(r["qaida"].rsplit(".q", 1)[1])), []).append((r["id"], h))
    return out


def scope(corpus: Path, name: str, statement: str, withheld: frozenset[str] = frozenset()) -> list[str]:
    """A type's scope: the heads of its cited qawāʿid's furūʿ, in text order, without those
    ``withheld`` (the cases under evaluation)."""
    table = furu(corpus)
    return [h for s in sources(name, statement) for i, h in table.get(s, []) if i not in withheld]
