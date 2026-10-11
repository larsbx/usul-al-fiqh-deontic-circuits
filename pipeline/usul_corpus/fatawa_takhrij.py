"""Takhrīj over modern fatāwā: IslamQA answers as cases for the bank's encoders.

Cases live in ``corpus/fatawa/takhrij/*.json`` in the takhrīj case schema, keyed
``islamqa.<answer>.fNNN``, each with the answer's own words for its ruling (``quote``).
Classification, kernel checks and Lean guards are takhrīj's; this module adds the
link to the source: the answer must exist and contain the quote verbatim.
"""

from __future__ import annotations

import json
import re
from collections import Counter
from collections.abc import Mapping
from pathlib import Path

from . import takhrij
from .labels import normalize_ar

_FAR = re.compile(r"^(islamqa\.\d+)\.f\d{3}$")


def load(corpus: Path) -> list[dict]:
    return takhrij.load_dir(corpus / "fatawa" / "takhrij")


def _flat(s: str | None) -> str:
    return " ".join(normalize_ar(s or "").split())


def check(cases: list[dict], answers: Mapping[str, Mapping]) -> dict[str, list[str]]:
    """Problems per case: takhrīj's own checks, plus the answer and its verbatim quote."""
    seen = Counter(c["far"] for c in cases)
    out: dict[str, list[str]] = {}
    for c in cases:
        errs = ["duplicate case"] if seen[c["far"]] > 1 else []
        m = _FAR.match(c["far"])
        if not m:
            errs.append("far is not islamqa.<answer>.fNNN")
        elif m.group(1) not in answers:
            errs.append(f"unknown answer {m.group(1)}")
        elif not c.get("quote"):
            errs.append("quote missing")
        else:
            a = answers[m.group(1)]
            source = _flat(" ".join(a.get(k) or "" for k in ("title", "question", "summary", "answer")))
            if _flat(c["quote"]) not in source:
                errs.append(f"quote not found in {m.group(1)}")
        errs += takhrij.check_case(c)
        if errs:
            out[c["far"]] = errs
    return out


def compare(corpus: Path) -> dict[str, dict]:
    """Each takhrīj bank, classical and fatwa, summarised on takhrīj's own report.

    Decided coverage is the kernel's share of the cases that state one ruling with its reason; disputed cases
    are counted apart, since which position is right is settled by its proof, not by who holds it.
    """
    files = sorted((corpus / "takhrij").glob("*_furu.json")) + sorted(
        f for f in (corpus / "fatawa" / "takhrij").glob("*.json") if f.name != "report.json")
    out = {}
    for f in files:
        cases = json.loads(f.read_text(encoding="utf-8"))["cases"]
        r = takhrij.report(cases)
        decided = r["classes"].get("derivable", 0)
        gaps = sum(r["classes"].get(k, 0) for k in takhrij.GAPS)
        out[f.stem] = {k: r[k] for k in ("total", "coverage", "encoding_error", "gaps_open")} | {
            "decided_coverage": round(decided / (decided + gaps), 3) if decided + gaps else 0.0,
            "disputed": r["classes"].get("genuine_ikhtilaf", 0), "encoders": len(r["per_encoder"])}
    return out


def lean_file(cases: list[dict]) -> str:
    return takhrij.lean_file(cases, command="fatawa-takhrij", source="corpus/fatawa/takhrij/*.json")
