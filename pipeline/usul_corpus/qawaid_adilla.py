"""The adilla of the qawāʿid (``corpus/dossier/qawaid_adilla.json``).

The basis is the Qurʾān and the Sunna. For each qāʿida this records the texts of the foundation it
is derived from, and for each one the istidlāl: a verbatim excerpt of the work that states the
derivation (the qāʿida's own author, or a commentator), with its relation to the qāʿida:
``stated`` (the source names it as the qāʿida's dalīl) or ``indicated`` (the source adduces it for
the qāʿida's ruling without naming it its dalīl). A qāʿida with no dalīl found records the works
searched, so absence is a result, not a gap. Nothing here decides a case.
"""

from __future__ import annotations

import json
from collections import Counter
from collections.abc import Callable
from pathlib import Path

from .arabic import letters

PATH = Path("dossier") / "qawaid_adilla.json"
RELATIONS = ("stated", "indicated")


def load(root: Path) -> dict:
    p = root / "corpus" / PATH
    return json.loads(p.read_text(encoding="utf-8")) if p.exists() else {"entries": []}


def foundation_ids(root: Path) -> set[str]:
    d = json.loads((root / "corpus/nusus/foundation.json").read_text(encoding="utf-8"))
    return {x["id"] for k in ("ayat", "ahadith", "athar") for x in d.get(k, [])}


def errors(entries: list[dict], records: dict, found: set[str], text: Callable[[str], str | None]) -> list[str]:
    """Each entry names a committed qāʿida once; every dalīl is in the foundation; every istidlāl is
    verbatim (Arabic letters) in its cached witness; a qāʿida without a dalīl names where it looked."""
    errs = [f"{q}: annotated twice" for q, n in Counter(e["qaida"] for e in entries).items() if n > 1]
    for e in entries:
        q = e["qaida"]
        if records.get(q, {}).get("record_type") != "qaida":
            errs.append(f"{q}: not a committed qāʿida record")
        if not e["adilla"] and not e.get("searched"):
            errs.append(f"{q}: no dalīl found must name the works searched")
        for d in e["adilla"]:
            if d["ref"] not in found:
                errs.append(f"{q}: {d['ref']} is not in the textual foundation")
            if d["relation"] not in RELATIONS:
                errs.append(f"{q}: relation {d['relation']!r} not in {RELATIONS}")
            src = text(d["istidlal"]["witness"])
            if src is not None and letters(d["istidlal"]["excerpt_ar"]) not in letters(src):
                errs.append(f"{q}: istidlāl for {d['ref']} is not verbatim in {d['istidlal']['witness']}")
    return errs


def report(entries: list[dict]) -> dict:
    by_work = Counter(e["qaida"].split(".")[0] + "." + e["qaida"].split(".")[1] for e in entries)
    with_dalil = Counter(e["qaida"].split(".")[0] + "." + e["qaida"].split(".")[1] for e in entries if e["adilla"])
    return {"qawaid": dict(by_work), "with_dalil": dict(with_dalil),
            "relations": dict(Counter(d["relation"] for e in entries for d in e["adilla"])),
            "adilla": dict(Counter(d["ref"][0] for e in entries for d in e["adilla"]))}
