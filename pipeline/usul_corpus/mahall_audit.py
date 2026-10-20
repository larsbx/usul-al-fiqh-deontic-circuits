"""Accuracy of the maḥall layer: blind re-annotation and an anchor review (PR-51).

Two studies on fixed samples (the 120 ids whose sha256 sorts lowest):

- **Identification.** Two independent blind annotators read each case and pick its maḥall from the
  label catalogue (ids, names, kinds, broader labels; no nuṣūṣ), or propose a new label. Each is
  scored against the committed annotation, and against the other.
- **Anchors.** Two independent reviewers judge each sampled (label, naṣṣ) pair on the text itself:
  the naṣṣ ``names`` the maḥall, only ``governs`` it as a broader rule, or is ``unrelated``.

Data: ``corpus/mahall/audit/identify_<a>.json`` ({far: {label, term_ar, also?}}) and
``corpus/mahall/audit/anchors_<r>.json`` ([{label, ref, excerpt_ar, verdict, weak_hint, note}]).
"""

from __future__ import annotations

import hashlib
import json
from collections import Counter
from pathlib import Path

from . import mahall

DIR = "mahall/audit"
N = 120
VERDICTS = ("names", "governs", "unrelated")


def _lowest(keys, n: int = N) -> list:
    return sorted(keys, key=lambda k: hashlib.sha256(k.encode()).hexdigest())[:n]


def sample_cases(corpus: Path) -> list[str]:
    return sorted(_lowest(e["far"] for e in mahall.load(corpus)[2]))


def sample_anchors(corpus: Path) -> list[str]:
    """``label|ref|excerpt`` of the sampled (label, naṣṣ) pairs."""
    return sorted(_lowest("|".join((l["id"], n["ref"], n["excerpt_ar"]))
                          for l in mahall.load(corpus)[1] for n in l.get("nass", [])))


def _labels(e: dict) -> list[str]:
    return [e["label"]] + [x["label"] for x in e.get("also", [])]


def _compare(mine: dict, theirs: dict, up: dict, kind: dict) -> dict:
    """Agreement of one annotation with another over their common cases."""
    rel = lambda a, b: a in up and b in up and (a in mahall.ancestors(up, b) or b in mahall.ancestors(up, a))
    bab = lambda a: mahall.roots(up, a) if a in up else {a.removeprefix("new:").split(".")[0]}
    out = Counter()
    for f in theirs:
        a, b = mine[f]["label"], theirs[f]["label"]
        out["n"] += 1
        out["new"] += a.startswith("new:")
        out["exact"] += a == b
        out["related"] += a == b or rel(a, b)
        out["any_related"] += any(x == y or rel(x, y) for x in _labels(mine[f]) for y in _labels(theirs[f]))
        out["same_bab"] += bool(bab(a) & bab(b))
        if a in kind and b in kind:
            out["kind_n"] += 1
            out["kind"] += kind[a] == kind[b]
    return dict(out)


def identification(corpus: Path) -> dict:
    """Each blind annotation against the committed one, and the two against each other."""
    abwab, labels, entries = mahall.load(corpus)
    up, kind = mahall.parents(abwab, labels), {l["id"]: l["kind"] for l in labels}
    committed = {e["far"]: e for e in entries}
    blind = {p.stem.removeprefix("identify_"): json.loads(p.read_text(encoding="utf-8"))
             for p in sorted((corpus / DIR).glob("identify_*.json"))}
    out = {k: _compare(v, {f: committed[f] for f in v}, up, kind) for k, v in blind.items()}
    if len(blind) == 2:
        (ka, a), (kb, b) = blind.items()
        out[f"{ka}~{kb}"] = _compare(a, b, up, kind)
    return out


def kappa(xs: list[str], ys: list[str]) -> float:
    """Cohen's κ for two raters over the same items."""
    n, cx, cy = len(xs), Counter(xs), Counter(ys)
    po = sum(x == y for x, y in zip(xs, ys)) / n
    pe = sum(cx[c] * cy[c] for c in cx) / n ** 2
    return 1.0 if pe == 1 else (po - pe) / (1 - pe)


def anchors(corpus: Path) -> dict:
    """Verdict counts per reviewer, their κ, and the pairs both or either call unrelated."""
    rev = {p.stem.removeprefix("anchors_"): {"|".join((r["label"], r["ref"], r["excerpt_ar"])): r
                                            for r in json.loads(p.read_text(encoding="utf-8"))}
           for p in sorted((corpus / DIR).glob("anchors_*.json"))}
    out = {k: dict(Counter(r["verdict"] for r in v.values())) | {"weak_hint": sum(r["weak_hint"] for r in v.values())}
           for k, v in rev.items()}
    if len(rev) == 2:
        (_, a), (_, b) = rev.items()
        keys = sorted(a)
        out["kappa"] = round(kappa([a[k]["verdict"] for k in keys], [b[k]["verdict"] for k in keys]), 3)
        out["both_names"] = sum(a[k]["verdict"] == b[k]["verdict"] == "names" for k in keys)
        out["both_unrelated"] = sum(a[k]["verdict"] == b[k]["verdict"] == "unrelated" for k in keys)
        out["either_unrelated"] = sum("unrelated" in (a[k]["verdict"], b[k]["verdict"]) for k in keys)
    return out
