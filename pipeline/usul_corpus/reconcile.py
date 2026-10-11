"""Reconciliation: the bank works through its own apparent contradictions by its own kernel.

An apparent contradiction is an ikhtilāf farʿ on which the reading does not land on the
madhhab's marked side (`matches_madhhab` false). Each is entered in the ledger with a grade for
every reported position, and resolved by `Usul.Reconcile.reconcile` (= `Usul.resolve`): jamʿ by
a conservative refinement whose farq the source cites, naskh by a reported later riwāya or
retraction, tarjīḥ by the graded support, else tawaqquf. `lean_file` emits a guard per entry,
so the Lean procedure is the authority over this mirror.

A resolution against the reading is a residue: the reading is marjūḥ on that farʿ, and the
encoder's residues are the next refinement's worklist.
"""

from __future__ import annotations

import json
import re
from collections import Counter
from pathlib import Path

from .shards import with_fragments

from . import takhrij

LEDGER = Path("reconciliation") / "ledger.json"
REPORT = Path("reconciliation") / "report.json"
# Strongest first; mirrors `Usul.Reconcile.Grade.rank`.
GRADES = ("tashih", "nass", "zahir", "qiyas", "jazm", "ashab", "takhrij", "wajh")
RANK = {g: len(GRADES) - 1 - i for i, g in enumerate(GRADES)}
MARKED = frozenset(g for g in GRADES if RANK[g] >= RANK["jazm"])
STAGES = ("jam", "naskh", "tarjih", "tawaqquf")


def candidates(cases: list[dict]) -> list[dict]:
    return [c for c in cases if c["class"] == "genuine_ikhtilaf" and not c.get("matches_madhhab")]


def support(ps: list[tuple[object, str]], p: object) -> list[int]:
    """Ranks for ruling `p`, strongest first; an unmarked grade counts once however many hold it."""
    rs = [RANK[g] for r, g in ps if r == p]
    return sorted([x for x in rs if x >= RANK["jazm"]] + list(dict.fromkeys(x for x in rs if x < RANK["jazm"])), reverse=True)


def prevail(ps: list[tuple[object, str]]) -> object | None:
    """The ruling whose support (ranks, strongest first, compared lexicographically, longer
    beating its own prefix) strictly exceeds every other ruling's."""
    rulings = list(dict.fromkeys(r for r, _ in ps))
    return next((p for p in rulings if all(q == p or support(ps, p) > support(ps, q) for q in rulings)), None)


def _grades(g: str | list[str]) -> list[str]:
    return [g] if isinstance(g, str) else g


def graded(case: dict, entry: dict) -> list[tuple[object, str]]:
    """One (ruling, grade) per distinct grade among each position's holders, then one per item
    of evidence imported from a later work (al-Inṣāf's taṣḥīḥ, the muʿtamad's jazm)."""
    ps = case["positions"]
    return ([(p["ruling"], x) for p, g in zip(ps, entry["grades"]) for x in _grades(g)]
            + [(ps[v["position"]]["ruling"], v["grade"]) for v in entry.get("evidence", [])])


def resolve(case: dict, entry: dict) -> tuple[str, object | None]:
    """Mirror of `Usul.Reconcile.reconcile`: the first stage that offers a ruling."""
    if entry.get("jam"):
        return "jam", case["expected"]
    if entry.get("naskh"):
        return "naskh", entry["naskh"]["ruling"]
    p = prevail(graded(case, entry))
    return ("tarjih", p) if p is not None else ("tawaqquf", None)


def standing(case: dict, entry: dict) -> str:
    stage, r = resolve(case, entry)
    return "tawaqquf" if stage == "tawaqquf" else "for_reading" if r == case["expected"] else "against_reading"


def _old(case: dict, frm: str) -> object:
    enc = takhrij.ENCODERS[frm]
    return enc["py"]({k: case["facts"][k] for k in enc["facts"]})


def check(cases: list[dict], ledger: dict, dossier: dict) -> list[str]:
    by = {c["far"]: c for c in cases}
    entries = {e["far"]: e for e in ledger["entries"]}
    errs = [f"{f}: apparent contradiction not in the ledger" for f in (c["far"] for c in candidates(cases)) if f not in entries]
    if len(entries) != len(ledger["entries"]):
        errs.append("duplicate ledger entries")
    conservative = {e["id"]: e["conservative"] for e in dossier["entries"]}
    jams: dict[str, list[dict]] = {}
    for f, e in entries.items():
        c = by.get(f)
        if c is None or c["class"] != "genuine_ikhtilaf":
            errs.append(f"{f}: not an ikhtilāf case")
            continue
        if len(e["grades"]) != len(c["positions"]) or not {x for g in e["grades"] for x in _grades(g)} <= set(GRADES):
            errs.append(f"{f}: one grade per position, from {GRADES}")
            continue
        if any(not 0 <= v["position"] < len(c["positions"]) or v["grade"] not in GRADES for v in e.get("evidence", [])):
            errs.append(f"{f}: evidence must name a listed position and a grade")
            continue
        if j := e.get("jam"):
            if c["encoder"] != j["encoder"] or not conservative.get(j["encoder"]) or j["from"] not in takhrij.ENCODERS:
                errs.append(f"{f}: jamʿ needs the case under a refinement with a conservativity theorem")
                continue
            jams.setdefault(j["encoder"], []).append(c)
            if prevail(graded(c, e)) != c["expected"]:
                errs.append(f"{f}: a jamʿ must land on the prevailing side")
        if c.get("matches_madhhab") and not e.get("jam"):
            errs.append(f"{f}: matches the madhhab without a jamʿ; nothing to reconcile")
    for c in cases:
        if sc := c.get("side_check"):
            e = entries.get(c["far"])
            if e is None:
                errs.append(f"{c['far']}: a failed side check must enter the ledger")
            elif not set(sc["refs"]) <= {v["ref"] for v in e.get("evidence", [])}:
                errs.append(f"{c['far']}: a side check cites only the ledger's own evidence")
    for enc, cs in jams.items():
        frm = {entries[c["far"]]["jam"]["from"] for c in cs}
        if len(frm) != 1:
            errs.append(f"{enc}: one earlier reading per refinement")
            continue
        frm = frm.pop()
        home = [c for c in cases if c["encoder"] == enc]
        for c in home:
            flipped = _old(c, frm) != c["expected"]
            if flipped and (c["far"] not in entries or prevail(graded(c, entries[c["far"]])) != c["expected"]):
                errs.append(f"{c['far']}: the refinement departs from {frm} other than to the prevailing side")
        if all(_old(c, frm) == c["expected"] for c in cs):
            errs.append(f"{enc}: a jamʿ must carry some farʿ to the prevailing side")
    return errs


def _str(v: object) -> str:
    return json.dumps(v if isinstance(v, str) else takhrij._lit(v) if isinstance(v, bool) else str(v), ensure_ascii=False)


def _opt(v: object | None) -> str:
    return "none" if v is None else f"(some {_str(v)})"


def lean_file(cases: list[dict], ledger: dict) -> str:
    by = {c["far"]: c for c in cases}
    lines = ["-- GENERATED by `python -m usul_corpus reconcile` from corpus/reconciliation/ledger.json. Do not edit.",
             "-- Each guard runs one apparent contradiction through the kernel's taʿāruḍ procedure.",
             "import Usul", "", "open Usul.Reconcile", ""]
    for e in ledger["entries"]:
        c = by[e["far"]]
        stage, r = resolve(c, e)
        jam = c["expected"] if e.get("jam") else None
        naskh = e["naskh"]["ruling"] if e.get("naskh") else None
        ps = ", ".join(f"({_str(p)}, .{g})" for p, g in graded(c, e))
        out = ".tawaqquf" if stage == "tawaqquf" else f"(.{stage} {_str(r)})"
        lines.append(f"-- {e['far']}")
        lines.append(f"#guard reconcile (P := String) {_opt(jam)} {_opt(naskh)} [{ps}] == {out}")
    return "\n".join(lines) + "\n"


def report(cases: list[dict], ledger: dict) -> dict:
    by = {c["far"]: c for c in cases}
    rows = [(e, by[e["far"]]) for e in ledger["entries"]]
    residues: dict[str, list[str]] = {}
    for e, c in rows:
        if standing(c, e) == "against_reading":
            residues.setdefault(c["encoder"], []).append(c["far"])
    return {"entries": len(rows),
            "stages": dict(sorted(Counter(resolve(c, e)[0] for e, c in rows).items())),
            "standing": dict(sorted(Counter(standing(c, e) for e, c in rows).items())),
            "worklist": dict(sorted(residues.items(), key=lambda kv: (-len(kv[1]), kv[0]))),
            "review": [c["far"] for e, c in rows if marked_for_reading(c, e)]}


def marked_for_reading(case: dict, entry: dict) -> bool:
    """Tarjīḥ gives the reading a marked side while the annotation says no madhhab matches:
    a question for the human reviewer, never rewritten here."""
    stage, r = resolve(case, entry)
    top = max((RANK[g] for q, g in graded(case, entry) if q == r), default=-1)
    return stage == "tarjih" and r == case["expected"] and top >= RANK["jazm"] and not case.get("matches_madhhab")


# Drafting aid for new tranches: a grade proposed from the annotator's `who`, for review.
_DRAFT = (("tashih", r"madhhab|mashh|ashhar|aṣaḥḥ|ṣaḥīḥ|sahih|aẓhar|azhar"),
          ("nass", r"naṣṣ|nass|manṣūṣ|mansus|riwāya|riwaya|Aḥmad \(|^Aḥmad"),
          ("zahir", r"ẓāhir (of|kalām) Aḥmad|zahir kalam Ahmad|apparent text of Ahmad"),
          ("qiyas", r"qiyās al-madhhab"),
          ("jazm", r"al-Qāḍī.*(Ibn ʿAqīl|followers)|most aṣḥāb|al-ashab|al-aṣḥāb|ẓāhir of the aṣḥāb|many later|jumhur"),
          ("takhrij", r"takhrīj|takhrij|iḥtimāl|possibility"),
          ("wajh", r"^(the )?(other |second |first |one |another )?wajh|^other|^some"))


def draft_grade(who: str) -> str:
    return next((g for g, pat in _DRAFT if re.search(pat, who, re.I)), "ashab")


def draft(cases: list[dict], ledger: dict) -> list[dict]:
    have = {e["far"] for e in ledger["entries"]}
    return [{"far": c["far"], "grades": [draft_grade(p["who"]) for p in c["positions"]], "jam": None, "naskh": None, "note": ""}
            for c in candidates(cases) if c["far"] not in have]


def load(corpus: Path) -> dict:
    """The committed ledger plus every shard's entries (``reconciliation/entries/*.json``)."""
    p = corpus / LEDGER
    base = json.loads(p.read_text(encoding="utf-8")) if p.exists() else {"entries": []}
    return with_fragments(base, p.parent / "entries", key="far")
