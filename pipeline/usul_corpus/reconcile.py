"""Reconciliation: the bank works through its own disputed furūʿ by its own kernel.

Every ikhtilāf farʿ has a ledger entry, and is resolved by `Usul.Tarjih.reconcile` (= `Usul.resolve`):
jamʿ by a conservative refinement whose farq the source cites, naskh by a reported later riwāya or
retraction, tarjīḥ by the *proofs* the positions cite (``proofs``, ``advantages``), else tawaqquf. A
ruling stands by its proof, not by who holds it: an entry whose proofs are not yet recorded is
``unweighed``, never resolved by its holders.

Who holds each position is kept as a record (``grades``, ``evidence``: the madhhab's labels, graded by
`Usul.Reconcile`), and `attribution` reports what those labels favour, for comparison only. `lean_file`
emits a guard per entry for both, so the Lean procedure is the authority over this mirror.

A resolution by proof against the reading is a residue: the reading is marjūḥ on that farʿ, and the
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
# Attribution grades, strongest first; mirrors `Usul.Reconcile.Grade.rank`. A record, not a weight.
GRADES = ("tashih", "nass", "zahir", "qiyas", "jazm", "ashab", "takhrij", "wajh")
RANK = {g: len(GRADES) - 1 - i for i, g in enumerate(GRADES)}
MARKED = frozenset(g for g in GRADES if RANK[g] >= RANK["jazm"])
STAGES = ("jam", "naskh", "tarjih", "tawaqquf", "unweighed")
# Proof tiers, weakest first; mirrors `Usul.Tarjih.Tier.rank` (Rawḍa v02 p389–390, Aḥmad's order of resort).
TIERS = ("istishab", "qiyas", "mursalDaif", "aqrabSahabi", "fatwaSahabi", "zanni", "qati", "ijma")
TIER_RANK = {t: i for i, t in enumerate(TIERS)}
# The advantages the Rawḍa (v02 p391–401), al-Kawkab (v04 p650–703) and al-Ṭūfī (v03 p729–746) state between proofs of one tier;
# mirrors `Usul.Tarjih.Murajjih`.
MURAJJIH = ("kathratRuwat", "tayaqquz", "wara", "sahibWaqia", "mubashir",
            "corroborated", "marfu", "consistentNarrator", "muttasil", "naqil", "muthbit",
            "usulMany", "tardAks", "mutaaddiya", "wasf", "ithbat", "aslShari", "aslAgreed", "aslStronger",
            "muaththira", "mulaima", "munasaba",
            "sahihayn", "masmu", "qawl", "fil", "nahy", "amr", "khass", "ammMahfuz", "iqtida", "ima", "muwafaqa",
            "muallal", "hazir",
            "mantuq", "nass", "mubayyan", "haqiqa", "ashhar", "siyaq", "afqah",
            "khiffa", "hissiyya", "fewerAwsaf", "dariHadd")
# Each advantage's standing in the cited sources; mirrors `Usul.Tarjih.Murajjih.standing`.
STANDING = {m: "asserted" for m in MURAJJIH} | dict.fromkeys(
    ("kathratRuwat", "mutaaddiya", "hazir", "qawl", "amr", "naqil"), "disputed") | dict.fromkeys(
    ("khiffa", "hissiyya", "fewerAwsaf"), "weak") | {"dariHadd": "rejected"}
# Which advantages decide: (standings counted, whether the bank's applied advantages count). Mirrors
# `Usul.Tarjih.Policy`; the bank resolves under `sources`, which counts only what a source states.
_STANDINGS = ("asserted", "disputed", "weak", "rejected")
POLICIES = {"strict": (frozenset({"asserted"}), False), "sources": (frozenset({"asserted", "disputed"}), False),
            "applying": (frozenset({"asserted", "disputed"}), True), "all": (frozenset(_STANDINGS), True)}
BASES = ("stated", "applied")
DEFAULT = "sources"


def candidates(cases: list[dict]) -> list[dict]:
    """The disputed furūʿ the ledger must hold: every ikhtilāf not retired to the history."""
    archived = _archived()
    return [c for c in cases if c["class"] == "genuine_ikhtilaf" and c["far"] not in archived]


# --- tarjīḥ by proof (`Usul.Tarjih`) ---------------------------------------------------------------

def weighed(entry: dict) -> bool:
    """The entry records the proofs its positions cite (possibly none for some position)."""
    return "proofs" in entry


def rulings(case: dict) -> list[object]:
    return list(dict.fromkeys(p["ruling"] for p in case["positions"]))


def proved(case: dict, entry: dict) -> list[tuple[object, str]]:
    """One (ruling, tier) per proof cited for a position."""
    ps = case["positions"]
    return [(ps[x["position"]]["ruling"], x["tier"]) for x in entry.get("proofs", [])]


def stated(case: dict, entry: dict) -> list[tuple[object, object, str, str]]:
    """One (winner, loser, murajjiḥ, basis) per advantage recorded between two positions' proofs."""
    ps = case["positions"]
    return [(ps[a["for"]]["ruling"], ps[a["over"]]["ruling"], a["by"], a["basis"]) for a in entry.get("advantages", [])]


def top(ps: list[tuple[object, str]], p: object) -> int | None:
    return max((TIER_RANK[t] for r, t in ps if r == p), default=None)


def favours(adv: list[tuple[object, object, str, str]], p: object, q: object, policy: str = DEFAULT) -> bool:
    counted, applied = POLICIES[policy]
    return any(w == p and l == q and STANDING[m] in counted and (b == "stated" or applied) for w, l, m, b in adv)


def beats(ps: list[tuple[object, str]], adv: list[tuple[object, object, str]], p: object, q: object,
          policy: str = DEFAULT) -> bool:
    """`p` outweighs `q`: a higher tier, or the same tier with a counted advantage and none back."""
    a, b = top(ps, p), top(ps, q)
    return a is not None and (b is None or a > b or (
        a == b and favours(adv, p, q, policy) and not favours(adv, q, p, policy)))


def weigh(rs: list[object], ps: list[tuple[object, str]], adv: list[tuple[object, object, str]],
          policy: str = DEFAULT) -> object | None:
    """Mirror of `Usul.Tarjih.prevail`: the reported ruling that outweighs every other, if any."""
    return next((p for p in rs if all(q == p or beats(ps, adv, p, q, policy) for q in rs)), None)


def support(ps: list[tuple[object, str]], p: object) -> list[int]:
    """Ranks for ruling `p`, strongest first; an unmarked grade counts once however many hold it."""
    rs = [RANK[g] for r, g in ps if r == p]
    return sorted([x for x in rs if x >= RANK["jazm"]] + list(dict.fromkeys(x for x in rs if x < RANK["jazm"])), reverse=True)


def prevail(ps: list[tuple[object, str]]) -> object | None:
    """The ruling whose support (ranks, strongest first, compared lexicographically, longer
    beating its own prefix) strictly exceeds every other ruling's."""
    rulings = list(dict.fromkeys(r for r, _ in ps))
    return next((p for p in rulings if all(q == p or support(ps, p) > support(ps, q) for q in rulings)), None)


def _same(a: object, b: object) -> bool:
    """Ruling equality without Python's `True == 1`."""
    return type(a) is type(b) and a == b


def _grades(g: str | list[str]) -> list[str]:
    return [g] if isinstance(g, str) else g


def graded(case: dict, entry: dict) -> list[tuple[object, str]]:
    """One (ruling, grade) per distinct grade among each position's holders, then one per item
    of evidence imported from a later work (al-Inṣāf's taṣḥīḥ, the muʿtamad's jazm)."""
    ps = case["positions"]
    return ([(p["ruling"], x) for p, g in zip(ps, entry["grades"]) for x in _grades(g)]
            + [(ps[v["position"]]["ruling"], v["grade"]) for v in entry.get("evidence", [])])


def resolve(case: dict, entry: dict, policy: str = DEFAULT) -> tuple[str, object | None]:
    """Mirror of `Usul.Tarjih.reconcile`: the first stage that offers a ruling; ``unweighed`` while
    no proof is recorded, since holders alone decide nothing."""
    if entry.get("jam"):
        return "jam", case["expected"]
    if entry.get("naskh"):
        return "naskh", entry["naskh"]["ruling"]
    if not weighed(entry):
        return "unweighed", None
    p = weigh(rulings(case), proved(case, entry), stated(case, entry), policy)
    return ("tarjih", p) if p is not None else ("tawaqquf", None)


def standing(case: dict, entry: dict) -> str:
    stage, r = resolve(case, entry)
    if stage in ("tawaqquf", "unweighed"):
        return stage
    if case["class"] != "genuine_ikhtilaf":
        return "no_reading"
    return "for_reading" if r == case["expected"] else "against_reading"


# --- the attribution record (`Usul.Reconcile`): what the labels favour, never a resolution ----------

def attribution(case: dict, entry: dict) -> tuple[str, object | None]:
    """Mirror of `Usul.Reconcile.byAttribution`: what the procedure would give if attribution were proof."""
    if entry.get("jam"):
        return "jam", case["expected"]
    if entry.get("naskh"):
        return "naskh", entry["naskh"]["ruling"]
    p = prevail(graded(case, entry))
    return ("tarjih", p) if p is not None else ("tawaqquf", None)


def attribution_standing(case: dict, entry: dict) -> str:
    stage, r = attribution(case, entry)
    if stage == "tawaqquf":
        return stage
    if case["class"] != "genuine_ikhtilaf":
        return "no_reading"
    return "for_reading" if r == case["expected"] else "against_reading"


def foundation_ids() -> set[str]:
    """Validate foundation references as metadata, never as an alternative resolver."""
    path = Path(__file__).resolve().parents[2] / "corpus/nusus/foundation.json"
    d = json.loads(path.read_text(encoding="utf-8"))
    return {a["id"] for k in ("ayat", "ahadith", "athar") for a in d.get(k, [])}


def disagreements(cases: list[dict]) -> list[dict]:
    """Cases where aligned works state different rulings that no reading decides: each needs a tarjīḥ too."""
    return [c for c in cases if c.get("aligned") and c["class"] in ("missing_rule", "missing_fact")
            and len({takhrij.code(p["ruling"]) for p in c.get("positions") or []}) >= 2]



def _old(case: dict, frm: str) -> object:
    enc = takhrij.ENCODERS[frm]
    return enc["py"]({k: case["facts"][k] for k in enc["facts"]})


def _proof_errors(f: str, case: dict, entry: dict) -> list[str]:
    n = len(case["positions"])
    ok = lambda i: type(i) is int and 0 <= i < n
    errs = []
    if any(not ok(x.get("position")) or x.get("tier") not in TIERS or not x.get("ref") or not x.get("excerpt_ar")
           for x in entry.get("proofs", [])):
        errs.append(f"{f}: a proof names a listed position, a tier from {TIERS}, a ref and its excerpt")
    if any(not ok(a.get("for")) or not ok(a.get("over")) or a["for"] == a["over"] or a.get("by") not in MURAJJIH
           or a.get("basis") not in BASES or not a.get("ref") or not a.get("excerpt_ar")
           for a in entry.get("advantages", [])):
        errs.append(f"{f}: an advantage names two listed positions, a murajjiḥ, its basis, a ref and its excerpt")
    elif not weighed(entry) and entry.get("advantages"):
        errs.append(f"{f}: advantages weigh proofs; record the proofs")
    if weighed(entry) and not entry["proofs"] and not str(entry.get("searched", "")).strip():
        errs.append(f"{f}: weighed with no proof: say where the proofs were searched for")
    return errs


def check(cases: list[dict], ledger: dict, dossier: dict) -> list[str]:
    by = {c["far"]: c for c in cases}
    entries = {e["far"]: e for e in ledger["entries"]}
    errs = [f"{c['far']}: an ikhtilāf not in the ledger" for c in candidates(cases) if c["far"] not in entries]
    between = {c["far"] for c in disagreements(cases)}
    errs += [f"{f}: a disagreement between works without a tarjīḥ in the ledger" for f in sorted(between) if f not in entries]
    open_rq = _open_research_questions()
    found = foundation_ids()
    for f, e in entries.items():
        for d in e.get("adilla", []):
            if d["ref"] not in found:
                errs.append(f"{f}: dalīl {d['ref']} is not in the textual foundation")
            elif f in by and (type(d["position"]) is not int or not 0 <= d["position"] < len(by[f].get("positions") or [])):
                errs.append(f"{f}: dalīl {d['ref']} names no listed position")
    if len(entries) != len(ledger["entries"]):
        errs.append("duplicate ledger entries")
    conservative = {e["id"]: e["conservative"] for e in dossier["entries"]}
    jams: dict[str, list[dict]] = {}
    for f, e in entries.items():
        c = by.get(f)
        if c is None or (c["class"] != "genuine_ikhtilaf" and f not in between):
            errs.append(f"{f}: not an ikhtilāf case")
            continue
        if f in between and (e.get("jam") or e.get("naskh")):
            errs.append(f"{f}: no reading decides it, so no jamʿ or naskh of a reading")
            continue
        if len(e["grades"]) != len(c["positions"]) or not {x for g in e["grades"] for x in _grades(g)} <= set(GRADES):
            errs.append(f"{f}: one grade per position, from {GRADES}")
            continue
        if any(not 0 <= v["position"] < len(c["positions"]) or v["grade"] not in GRADES for v in e.get("evidence", [])):
            errs.append(f"{f}: evidence must name a listed position and a grade")
            continue
        # A marked grade counts per holder in the attribution record, so a repeated report would weigh twice.
        if len({(v["ref"], v["position"]) for v in e.get("evidence", [])}) != len(e.get("evidence", [])):
            errs.append(f"{f}: evidence cites one page once per position")
            continue
        if (n := e.get("naskh")) and not any(
                v["ref"] == n["ref"] and _same(c["positions"][v["position"]]["ruling"], n["ruling"])
                for v in e.get("evidence", [])):
            errs.append(f"{f}: naskh needs a reported ruling and a cited evidence item attesting it")
            continue
        if pe := _proof_errors(f, c, e):
            errs += pe
            continue
        if j := e.get("jam"):
            if c["encoder"] != j["encoder"] or not conservative.get(j["encoder"]) or j["from"] not in takhrij.ENCODERS:
                errs.append(f"{f}: jamʿ needs the case under a refinement with a conservativity theorem")
                continue
            jams.setdefault(j["encoder"], []).append(c)
            if _against_proofs(c, e):
                errs.append(f"{f}: a jamʿ must not land against the side the proofs favour")
        if (rq := e.get("register")) is not None and rq not in open_rq:
            errs.append(f"{f}: {rq} is not an open research question")
    for c in cases:
        if "side_check" not in c:
            continue
        sc = c["side_check"]
        f = c["far"]
        if sc.get("from_matches") is not True or c.get("matches_madhhab") is not False or c["class"] != "genuine_ikhtilaf":
            errs.append(f"{f}: a failed side check preserves a true original annotation and a false current match")
        e = entries.get(f)
        if e is None:
            errs.append(f"{f}: a failed side check must enter the ledger")
            continue
        ev = e.get("evidence", [])
        refs = sc.get("refs", [])
        if not refs or len(set(refs)) != len(refs) or not set(refs) <= {v["ref"] for v in ev}:
            errs.append(f"{f}: a side check cites only the ledger's own evidence")
            continue
        witnesses = sc.get("contradictions", [])
        indices = [w.get("evidence_index") for w in witnesses]
        if (not witnesses or any(type(i) is not int or not 0 <= i < len(ev) for i in indices)
                or len(set(indices)) != len(indices)):
            errs.append(f"{f}: a side check needs distinct exact evidence items")
            continue
        selected = [ev[i] for i in indices]
        if set(refs) != {v["ref"] for v in selected}:
            errs.append(f"{f}: side-check refs must identify exactly the selected evidence")
        if any(w.get("case_facts") != c["facts"] or not isinstance(w.get("rationale"), str)
               or not w["rationale"].strip() for w in witnesses):
            errs.append(f"{f}: contradiction evidence needs case-specific facts and an applicability rationale")
        ps = c["positions"]
        if any(type(v.get("position")) is not int or not 0 <= v["position"] < len(ps)
               or v.get("grade") not in {"tashih", "jazm"} for v in selected):
            errs.append(f"{f}: contradiction evidence needs a listed position and later tashih or jazm")
            continue
        rulings = [p["ruling"] for p in ps]
        pairs = [(ps[v["position"]]["ruling"], v["grade"]) for v in selected]
        winner = prevail(pairs)
        if (c["expected"] not in rulings or any(r == c["expected"] for r, _ in pairs)
                or winner is None):
            errs.append(f"{f}: cited evidence must establish an unambiguous ruling against the original side")
        # A selected subset cannot override a tie or a contrary outcome in the full ledger.
        if (len(e["grades"]) == len(ps) and all(g in GRADES for gs in e["grades"] for g in _grades(gs))
                and all(type(v.get("position")) is int and 0 <= v["position"] < len(ps)
                        and v.get("grade") in GRADES for v in ev)):
            stage, ruling = attribution(c, e)
            if stage != "tarjih" or ruling != winner or ruling == c["expected"]:
                errs.append(f"{f}: the full ledger must confirm the cited contradiction by tarjih")
    for enc, cs in jams.items():
        frm = {entries[c["far"]]["jam"]["from"] for c in cs}
        if len(frm) != 1:
            errs.append(f"{enc}: one earlier reading per refinement")
            continue
        frm = frm.pop()
        for c in (c for c in cases if c["class"] in ("derivable", "genuine_ikhtilaf") and c["encoder"] == enc and _old(c, frm) != c["expected"]):
            e = entries.get(c["far"])
            if e is None or _against_proofs(c, e):
                errs.append(f"{c['far']}: the refinement departs from {frm} against the side the proofs favour")
        if all(_old(c, frm) == c["expected"] for c in cs):
            errs.append(f"{enc}: a jamʿ must move some farʿ off {frm}")
    return errs


def _by_proof(case: dict, entry: dict) -> object | None:
    return weigh(rulings(case), proved(case, entry), stated(case, entry))


def _against_proofs(case: dict, entry: dict) -> bool:
    """The proofs favour a ruling other than the one the jamʿ gives. Tawaqquf does not refute a jamʿ: the
    proofs leave the farʿ open, and jamʿ comes before tarjīḥ."""
    return weighed(entry) and (p := _by_proof(case, entry)) is not None and p != case["expected"]


def jam_pending(cases: list[dict], ledger: dict) -> list[str]:
    """Furūʿ a jamʿ moves off its earlier reading whose proofs are not yet weighed: the move is
    conservative by theorem, but which side the proofs favour is still open."""
    entries = {e["far"]: e for e in ledger["entries"]}
    frm = {e["jam"]["encoder"]: e["jam"]["from"] for e in ledger["entries"] if e.get("jam")}
    return sorted(c["far"] for c in cases if c["encoder"] in frm and c["far"] in entries
                  and not weighed(entries[c["far"]]) and _old(c, frm[c["encoder"]]) != c["expected"])


def _str(v: object) -> str:
    return json.dumps(v if isinstance(v, str) else takhrij._lit(v) if isinstance(v, bool) else str(v), ensure_ascii=False)


def _opt(v: object | None) -> str:
    return "none" if v is None else f"(some {_str(v)})"


def lean_file(cases: list[dict], ledger: dict) -> str:
    by = {c["far"]: c for c in cases}
    lines = ["-- GENERATED by `python -m usul_corpus reconcile` from corpus/reconciliation/ledger.json. Do not edit.",
             "-- Each guard runs one disputed farʿ through the kernel's taʿāruḍ procedure: by proof (`Usul.Tarjih`)",
             "-- where its proofs are recorded, and by attribution (`Usul.Reconcile`, a record) for every entry.",
             "import Usul", "", "open Usul.Reconcile", ""]
    for e in ledger["entries"]:
        c = by[e["far"]]
        jam = c["expected"] if e.get("jam") else None
        naskh = e["naskh"]["ruling"] if e.get("naskh") else None
        lines.append(f"-- {e['far']}")
        if weighed(e):
            rs = ", ".join(map(_str, rulings(c)))
            ps = ", ".join(f"({_str(p)}, .{t})" for p, t in proved(c, e))
            adv = ", ".join(f"⟨{_str(w)}, {_str(l)}, .{m}, .{b}⟩" for w, l, m, b in stated(c, e))
            for pol in POLICIES:
                stage, r = resolve(c, e, pol)
                out = ".tawaqquf" if stage == "tawaqquf" else f"(.{stage} {_str(r)})"
                lines.append(f"#guard Usul.Tarjih.reconcile Usul.Tarjih.Policy.{pol} (P := String) {_opt(jam)} {_opt(naskh)} "
                             f"[{rs}] ([{ps}] : List (String × Usul.Tarjih.Tier)) [{adv}] == {out}")
        stage, r = attribution(c, e)
        ps = ", ".join(f"({_str(p)}, .{g})" for p, g in graded(c, e))
        out = ".tawaqquf" if stage == "tawaqquf" else f"(.{stage} {_str(r)})"
        lines.append(f"#guard byAttribution (P := String) {_opt(jam)} {_opt(naskh)} [{ps}] == {out}")
    return "\n".join(lines) + "\n"


def _archived() -> dict[str, dict]:
    """Entries a resolution retired from the active ledger (``reconciliation/history/*.json``, e.g.
    PR #49's composite abstention): kept there, and still the farʿ's entry."""
    d = Path(__file__).resolve().parents[2] / "corpus" / "reconciliation" / "history"
    return {e["far"]: e for p in sorted(d.glob("*.json")) for e in json.loads(p.read_text(encoding="utf-8")).get("entries", [])}


OPEN = frozenset({"open-research", "ready-for-decision"})


def _open_research_questions() -> set[str]:
    """Ids of the research register's questions not yet decided by a human: the only licence an entry's
    ``register`` may cite."""
    p = Path(__file__).resolve().parents[2] / "corpus" / "review" / "research_questions.json"
    return {q["id"] for q in json.loads(p.read_text(encoding="utf-8"))["questions"] if q["status"] in OPEN} if p.exists() else set()


def report(cases: list[dict], ledger: dict) -> dict:
    """The procedure by proof, and the attribution record beside it (never a resolution)."""
    by = {c["far"]: c for c in cases}
    rows = [(e, by[e["far"]]) for e in ledger["entries"]]
    residues: dict[str, list[str]] = {}
    for e, c in rows:
        if standing(c, e) == "against_reading":
            residues.setdefault(c["encoder"], []).append(c["far"])
    unweighed = Counter(c["encoder"] for e, c in rows if resolve(c, e)[0] == "unweighed")
    return {"entries": len(rows),
            "weighed": sum(1 for e, _ in rows if weighed(e)),
            "proofs": sum(len(e.get("proofs", [])) for e, _ in rows),
            "advantages": sum(len(e.get("advantages", [])) for e, _ in rows),
            "stages": dict(sorted(Counter(resolve(c, e)[0] for e, c in rows).items())),
            "standing": dict(sorted(Counter(standing(c, e) for e, c in rows).items())),
            "worklist": dict(sorted(residues.items(), key=lambda kv: (-len(kv[1]), kv[0]))),
            "weighing_worklist": dict(sorted(unweighed.items(), key=lambda kv: (-kv[1], kv[0]))),
            "jam_pending": jam_pending(cases, ledger),
            "policies": {pol: {"counts": sorted(POLICIES[pol][0]), "applied": POLICIES[pol][1],
                               "differs_from_default": sorted(c["far"] for e, c in rows
                                                              if resolve(c, e, pol) != resolve(c, e))}
                         for pol in POLICIES if pol != DEFAULT},
            "attribution": {
                "note": "what the reported holders' labels favour (Usul.Reconcile); a record, not a tarjīḥ",
                "evidence_items": sum(len(e.get("evidence", [])) for e, _ in rows),
                "side_checks": sorted(c["far"] for _, c in rows if "side_check" in c),
                "stages": dict(sorted(Counter(attribution(c, e)[0] for e, c in rows).items())),
                "standing": dict(sorted(Counter(attribution_standing(c, e) for e, c in rows).items())),
                "labels_agree_with_proofs": sum(1 for e, c in rows if weighed(e) and resolve(c, e)[0] == "tarjih"
                                                and attribution(c, e) == resolve(c, e)),
                "review": [c["far"] for e, c in rows if marked_for_reading(c, e)]}}


def marked_for_reading(case: dict, entry: dict) -> bool:
    """The labels give the reading a marked side while the annotation says no madhhab matches: a
    question about the annotation's description, for the human reviewer, never rewritten here."""
    stage, r = attribution(case, entry)
    top_ = max((RANK[g] for q, g in graded(case, entry) if q == r), default=-1)
    return case["class"] == "genuine_ikhtilaf" and stage == "tarjih" and r == case["expected"] and top_ >= RANK["jazm"] and not case.get("matches_madhhab")


# Drafting aid for new tranches: a grade proposed from the annotator's `who`, for review.
_DRAFT = (("tashih", r"madhhab|mashh|ashhar|aṣaḥḥ|ṣaḥīḥ|sahih"),
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


WEIGHED = ("proofs", "advantages", "searched")


def load(corpus: Path) -> dict:
    """The committed ledger plus every shard's entries (``reconciliation/entries/*.json``), with the
    proofs of ``reconciliation/weighing/*.json`` laid over them: the weighing is kept apart from the
    attribution record, each farʿ weighed in one file."""
    p = corpus / LEDGER
    base = json.loads(p.read_text(encoding="utf-8")) if p.exists() else {"entries": []}
    ledger = with_fragments(base, p.parent / "entries", key="far")
    over = with_fragments({"entries": []}, p.parent / "weighing", key="far")["entries"]
    by = {e["far"]: {k: e[k] for k in WEIGHED if k in e} for e in over}
    if missing := sorted(set(by) - {e["far"] for e in ledger["entries"]}):
        raise ValueError(f"weighed but not in the ledger: {', '.join(missing)}")
    return {**ledger, "entries": [{**e, **by.get(e["far"], {})} for e in ledger["entries"]]}
