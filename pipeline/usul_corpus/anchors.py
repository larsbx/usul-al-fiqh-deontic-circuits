"""Field anchors: every fact a qāʿida type declares, defined by a verbatim phrase of its source (PR-48).

A typed situation settles facts named by fields (``Usul.Typing.Qaida``). A field's name is the bank's;
its meaning must be the source's. Each declared field therefore carries a gloss and an **anchor**: the
phrase of its qāʿida (statement or body) that states the fact, verbatim, located in the pinned witness.
A field no phrase states is recorded ``unanchored`` with the reason: a fact the bank reads that its
source does not state.

Entries live in write-isolated fragments, ``corpus/types/anchors/<shard>.json``, keyed ``type.field``.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

from . import nusus, source_verify

DIR = "types/anchors"
REF = re.compile(r"^src:([a-z0-9-]+)(?:/(v\d+:p\d+)|#(q\d{3}))$")
MAX = 200


def declared(export: str) -> list[tuple[str, str]]:
    """Every (type, field) the Lean export declares, a field at the type that declares it."""
    return re.findall(r"^type_field\((\w+), (\w+), ", export, re.M)


def load(corpus: Path) -> list[dict]:
    """The anchor entries of every fragment; a ``type.field`` given twice is an error."""
    seen, out = {}, []
    for p in sorted((corpus / DIR).glob("*.json")):
        for e in json.loads(p.read_text(encoding="utf-8"))["entries"]:
            k = f"{e['type']}.{e['field']}"
            if k in seen:
                raise ValueError(f"{k}: {seen[k]} and {p.name}")
            seen[k] = p.name
            out.append(e)
    return out


def check(entries: list[dict], export: str) -> list[str]:
    """Structure: known fields, a gloss, exactly one of anchor and unanchored, a well-formed ref."""
    known = set(declared(export))
    errs = []
    for e in entries:
        k = f"{e['type']}.{e['field']}"
        if (e["type"], e["field"]) not in known:
            errs.append(f"{k}: not a declared field")
        if not str(e.get("gloss", "")).strip():
            errs.append(f"{k}: no gloss")
        if ("anchor" in e) == ("unanchored" in e):
            errs.append(f"{k}: needs exactly one of anchor and unanchored")
        elif "anchor" in e:
            a = e["anchor"]
            if not REF.fullmatch(a.get("ref", "")):
                errs.append(f"{k}: bad ref {a.get('ref')!r}")
            if not 2 <= len(a.get("excerpt_ar", "").split()) or len(a["excerpt_ar"]) > MAX:
                errs.append(f"{k}: an excerpt is two words to {MAX} characters")
        elif not str(e["unanchored"]).strip():
            errs.append(f"{k}: unanchored without a reason")
    return errs


def missing(entries: list[dict], export: str) -> list[str]:
    """Declared fields no entry covers."""
    have = {(e["type"], e["field"]) for e in entries}
    return [f"{t}.{f}" for t, f in declared(export) if (t, f) not in have]


def verify(anchor: dict, text: str) -> str | None:
    """None when the excerpt is verbatim in the witness ``text`` where its ref says: at the declared
    closing page, whole words, no dropped negation or cut qualifier (``source_verify.check_quote``);
    for a witness without page markers (``#qNNN``), exactly once."""
    m = REF.fullmatch(anchor["ref"])
    if m[2]:
        return source_verify.check_quote(text, anchor["excerpt_ar"], m[2])
    n = nusus.key(text).count(nusus.key(anchor["excerpt_ar"]))
    return None if n == 1 else f"occurs {n} times in an unpaged witness"
