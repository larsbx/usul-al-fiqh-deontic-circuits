"""Deduction to the qāʿida (``Usul.Cat.Deduction``): the verdicts a partial situation can reach.

A partial situation settles some of an encoder's facts. Its completions range the unsettled facts over
their domains; ``reach`` is the set of verdicts they give, the presheaf ``Reach`` of the Lean module,
computed exhaustively. An encoder is admissible for an established conclusion when the conclusion is in
reach; a refinement only shrinks the set (``reach_antitone``), so an exclusion is final.
"""

from __future__ import annotations

import re
from itertools import product

from . import takhrij

_READS = re.compile(r"^encoder_reads\((\w+), (\d+), (\w+)\)\.", re.M)
_PLACE = re.compile(r"\{(\w+)\}")


def reads(export: str) -> dict[str, list[str]]:
    """Encoder ↦ the situation fields it reads, in argument order (``examples/v41_types.pl``)."""
    by: dict[str, dict[int, str]] = {}
    for e, i, f in _READS.findall(export):
        by.setdefault(e, {})[int(i)] = f
    return {e: [fs[i] for i in sorted(fs)] for e, fs in by.items()}


def names(encoder: str) -> list[str]:
    """The encoder's own fact names, in the argument order of its Lean expression."""
    return _PLACE.findall(takhrij.ENCODERS[encoder]["lean"])


def reach(encoder: str, settled: dict, read: list[str]) -> set:
    """The verdicts of every completion of ``settled`` (situation field ↦ value) under the encoder."""
    enc, ns = takhrij.ENCODERS[encoder], names(encoder)
    options = []
    for field, name in zip(read, ns):
        dom = enc["facts"][name]
        if field in settled:
            if not takhrij.among(settled[field], dom):
                return set()
            options.append([settled[field]])
        else:
            options.append(list(dom))
    return {enc["py"](dict(zip(ns, combo))) for combo in product(*options)}
