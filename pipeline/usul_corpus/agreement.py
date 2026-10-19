"""Reproduction: do two independent readers of a farʿ touch the same qawāʿid? (PR-50)

A typing settles facts; each fact belongs to qāʿida types, and each type is read from source
qawāʿid (those its statement cites, ``scope.sources``, and al-Saʿdī's). A typing of a case
therefore touches a **set** of source qawāʿid. Two typings are compared set against set:
Krippendorff's α with the MASI distance (Passonneau 2006), the standard for set-valued labels.

The typings are ``corpus/typing/reproduction/rajab_fold1_<condition>_<a|b>.json``: two independent
blind typings of a fixed 80-case sample per condition. The first plain typing is the committed
``rajab_fold1_situations.json``.
"""

from __future__ import annotations

import itertools
import json
import re
from pathlib import Path

from . import deduction, routing, scope

DIR = "typing/reproduction"
CONDITIONS = ("plain", "anchors", "scope")
SADI = re.compile(r"al-Saʿdī Q(\d+)")


def masi(a: frozenset, b: frozenset) -> float:
    """MASI distance: 1 − Jaccard × monotonicity (1 equal, 2/3 nested, 1/3 overlapping, 0 disjoint)."""
    if not a | b:
        return 0.0
    m = 1 if a == b else 2 / 3 if a <= b or b <= a else 1 / 3 if a & b else 0
    return 1 - len(a & b) / len(a | b) * m


def alpha(pairs: list[tuple[frozenset, frozenset]]) -> float:
    """Krippendorff's α for two coders over every unit, with the MASI distance. With no variation
    at all (every set the same), α is undefined; it is taken as 1, the coders being in full accord.
    Without units there is nothing to agree on: an error."""
    if not pairs:
        raise ValueError("alpha needs at least one unit")
    vals = [v for p in pairs for v in p]
    observed = sum(masi(a, b) for a, b in pairs) / len(pairs)
    expected = sum(masi(a, b) for a, b in itertools.permutations(vals, 2)) / (len(vals) * (len(vals) - 1))
    return 1.0 if expected == 0 else 1 - observed / expected


class Qawaid:
    """Maps a typing's facts to the source qawāʿid they belong to, from the Lean export."""

    def __init__(self, export: str):
        statement = dict(re.findall(r"^qaida_type\((\w+), '((?:[^']|'')*)'\)\.", export, re.M))
        self.owner: dict[str, set[str]] = {}
        for t, f in re.findall(r"^type_field\((\w+), (\w+), ", export, re.M):
            self.owner.setdefault(f, set()).add(t)
        self.of = {t: frozenset({f"{a} {n}" for a, n in scope.sources(t, s)}
                                | {f"al-Saʿdī {n}" for n in SADI.findall(s)}) or frozenset({t})
                   for t, s in statement.items()}

    def fields(self, fs) -> frozenset[str]:
        return frozenset(q for f in fs for t in self.owner.get(f, ()) for q in self.of.get(t, {t}))

    def touched(self, situations: list[dict]) -> frozenset[str]:
        return self.fields(f for s in situations for f in s["facts"])


def typings(root: Path) -> dict[str, tuple[dict, dict]]:
    """condition → (typing a, typing b), each {unit: situations}, over the same sample."""
    read = lambda p: {a["answer"]: a["situations"] for a in json.loads(p.read_text(encoding="utf-8"))["answers"]}
    d = root / "corpus" / DIR
    out = {c: (read(d / f"rajab_fold1_{c}_a.json") if c != "plain" else None, read(d / f"rajab_fold1_{c}_b.json"))
           for c in CONDITIONS}
    first = read(root / "corpus/typing/rajab_fold1_situations.json")
    out["plain"] = ({u: first[u] for u in out["plain"][1]}, out["plain"][1])
    return out


def report(root: Path) -> dict[str, dict]:
    """Per condition: set agreement between the two typings, and how often each finds the
    qawāʿid of the case's own reading."""
    export = (root / "examples/v41_types.pl").read_text(encoding="utf-8")
    q, reads = Qawaid(export), deduction.reads(export)
    runs = typings(root)
    units = sorted(runs["plain"][1])
    gold = {u: q.fields(reads[e]) for u, e, _ in routing.cases(root / "corpus") if u in set(units)}
    out = {}
    for c, (a, b) in runs.items():
        P = [(q.touched(a[u]), q.touched(b[u])) for u in units]
        hit = lambda i: sum(bool(p[i] & gold[u]) for u, p in zip(units, P))
        out[c] = {"n": len(P), "identical": sum(x == y for x, y in P), "overlap": sum(bool(x & y) for x, y in P),
                  "disjoint": sum(bool(x | y) and not x & y for x, y in P), "both_empty": sum(not x | y for x, y in P),
                  "alpha_masi": round(alpha(P), 3), "own_found": [hit(0), hit(1)],
                  "own_found_by_either": sum(bool((x | y) & gold[u]) for u, (x, y) in zip(units, P)),
                  "mean_size": round(sum(len(x) + len(y) for x, y in P) / (2 * len(P)), 2)}
    return out
