"""M4 takhrīj suite: furūʿ as test cases for the formal readings.

Each encoder ties a formalised reading (al-Saʿdī's rule) to the qāʿida whose furūʿ test it
(Ibn Rajab's, which al-Saʿdī compresses; Ibn al-Laḥḥām's for generality). It fixes the facts
a case supplies, the Lean expression that computes the kernel's ruling, and a Python mirror
of that expression for annotators. Lean is the authority: `lean_file` emits a guard for every
case whose class asserts agreement or disagreement, so a wrong annotation fails the build.
"""

from __future__ import annotations

import json
from collections import Counter
from pathlib import Path

B = (False, True)
GRADES = ("wahm", "shakk", "zann", "qat")
FORMS = ("nakira", "particle", "definiteAl", "singularAnnexed")
CONTEXTS = ("affirmation", "negation", "prohibition", "condition", "question")
HUKM = ("wajib", "mandub", "mubah", "makruh", "haram")

RAJAB = "ibn_rajab.taqrir_qawaid.openiti_rajab_shamela21730.q{:03d}"
LAHHAM = "ibn_lahham.qawaid_fawaid.openiti_lahham_shamela8526.q{:03d}"


def _b(x: bool) -> str:
    return "true" if x else "false"


# name → sadi rules, qawāʿid tested, fact domains, output domain, Lean template, Python mirror
ENCODERS: dict[str, dict] = {
    "itlaf": dict(
        sadi=[36], qawaid=[RAJAB.format(26)],
        facts={"purpose": ("benefit", "repelHarm"), "mental": ("deliberate", "ignorant", "forgetful")},
        out=B, lean="Usul.Muamalat.itlafLiable (Usul.Muamalat.withRight {purpose}) {mental}",
        py=lambda f: f["purpose"] == "benefit"),
    "doubled": dict(
        sadi=[35], qawaid=[RAJAB.format(140)], facts={"lapsed": B},
        out=(1, 2), lean="Usul.Muamalat.compensationOwed 1 {lapsed}",
        py=lambda f: 2 if f["lapsed"] else 1),
    "knowledge": dict(
        sadi=[45], qawaid=[RAJAB.format(63)], facts={"consent_required": B},
        out=B, lean="(Usul.Muamalat.Requirement.normalize ⟨{consent_required}, true⟩).knowledge",
        py=lambda f: f["consent_required"]),
    "continuity": dict(
        sadi=[48], qawaid=[RAJAB.format(103)], facts={"customary_continuity": B},
        out=B, lean="Usul.Kulliyyat.continuous 1 [0, if {customary_continuity} then 1 else 5]",
        py=lambda f: f["customary_continuity"]),
    "tabaa": dict(
        sadi=[50], qawaid=[RAJAB.format(133)], facts={"independent_proof": B, "follows_established": B},
        out=B, lean="Usul.Kulliyyat.established {independent_proof} {follows_established}",
        py=lambda f: f["independent_proof"] or f["follows_established"]),
    "unknown_owner": dict(
        sadi=[20], qawaid=[RAJAB.format(106)], facts={"owner_identifiable": B},
        out=("owner", "publicInterest"), lean="Usul.Muamalat.recipient {owner_identifiable}",
        py=lambda f: "owner" if f["owner_identifiable"] else "publicInterest"),
    "partners": dict(
        sadi=[30], qawaid=[RAJAB.format(76)], facts={"necessary": B, "consents": B},
        out=B, lean="Usul.Muamalat.partnerMustJoin {necessary} {consents}",
        py=lambda f: f["necessary"] or f["consents"]),
    "recourse": dict(
        sadi=[32], qawaid=[RAJAB.format(75)], facts={"gift": B, "owed_by_other": B, "permission": B},
        out=B, lean="Usul.Refinements.recourseFull {gift} {owed_by_other} {permission}",
        py=lambda f: not f["gift"] and (f["owed_by_other"] or f["permission"])),
    "lots": dict(
        sadi=[25], qawaid=[RAJAB.format(160)], facts={"entitled_known": B, "divisible": B, "confusion_category": B},
        out=("toEntitled", "divide", "lot"),
        lean="Usul.Refinements.allocationFull {entitled_known} {divisible} {confusion_category}",
        py=lambda f: "toEntitled" if f["entitled_known"] else "lot" if f["confusion_category"] else "divide" if f["divisible"] else "lot"),
    "tadakhul": dict(
        sadi=[41], qawaid=[RAJAB.format(18)], facts={"same_kind": B, "same_purpose": B},
        out=B,
        lean="Usul.Kulliyyat.discharges (⟨0, 0, 0⟩ : Usul.Kulliyyat.Act Nat Nat Nat) "
             "⟨if {same_kind} then 0 else 1, if {same_purpose} then 0 else 1, 1⟩",
        py=lambda f: f["same_kind"] and f["same_purpose"]),
    "trust_loss": dict(
        sadi=[14], qawaid=[RAJAB.format(45)],
        facts={"hand": ("trustee", "wrongdoer"), "transgressed": B, "negligent": B},
        out=B, lean="Usul.Muamalat.lossLiable {hand} {transgressed} {negligent}",
        py=lambda f: f["hand"] == "wrongdoer" or f["transgressed"] or f["negligent"]),
    "partial_capability": dict(
        sadi=[40], qawaid=[RAJAB.format(8)], facts={"capable_of_part": B, "pure_means": B},
        out=B,
        lean="decide (0 ∈ Usul.Sadi.obligedParts [0] (fun _ => {capable_of_part}) (fun _ => {pure_means}))",
        py=lambda f: f["capable_of_part"] and not f["pure_means"]),
    "substitute": dict(
        sadi=[28], qawaid=[RAJAB.format(16)], facts={"original_possible": B},
        out=B, lean="Usul.Sadi.useSubstitute {original_possible}",
        py=lambda f: not f["original_possible"]),
    "asl_zahir": dict(
        sadi=[11, 52], qawaid=[RAJAB.format(159)], facts={"asl_grade": GRADES, "zahir_grade": GRADES, "amara": B},
        out=B, lean="Usul.Refinements.zahirPrevails {asl_grade} {zahir_grade} {amara}",
        py=lambda f: GRADES.index(f["asl_grade"]) < GRADES.index(f["zahir_grade"])
        or (f["asl_grade"] == f["zahir_grade"] and f["amara"])),
    "generality": dict(
        sadi=[59, 60], qawaid=[LAHHAM.format(n) for n in (52, 53, 54)],
        facts={"form": FORMS, "context": CONTEXTS, "ahd": B},
        out=B, lean="Usul.Dalala.IsGeneralIn {form} {context} {ahd}",
        py=lambda f: not f["ahd"] and (f["form"] != "nakira" or f["context"] in ("negation", "prohibition", "condition"))),
    "amr": dict(
        sadi=[], qawaid=[LAHHAM.format(43)], facts={"qarina": ("none",) + HUKM},
        out=HUKM, lean="Usul.Dalala.amrStatus {qarina}",
        lits={"qarina": {"none": "none", **{h: f"(some .{h})" for h in HUKM}}},
        py=lambda f: "wajib" if f["qarina"] == "none" else f["qarina"]),
    "umum_lafz": dict(
        sadi=[], qawaid=[LAHHAM.format(61)], facts={"in_occasion": B, "general_wording": B},
        out=B, lean="Usul.Dalala.coversBeyondSabab true {in_occasion} {general_wording}",
        py=lambda f: f["in_occasion"] or f["general_wording"]),
}


def provides() -> set[str]:
    """What the bank can now express: one rule per encoder and every fact field."""
    return {f"rule:{n}" for n in ENCODERS} | {f"fact:{k}" for e in ENCODERS.values() for k in e["facts"]}


def revisit_queue(cases: list[dict]) -> list[str]:
    """Gaps whose every need the bank now provides: the bank applied to itself."""
    have = provides()
    return [c["far"] for c in cases if c.get("needs") and set(c["needs"]) <= have]

CLASSES = ("derivable", "genuine_ikhtilaf", "encoding_error", "missing_fact", "missing_rule", "segmentation_error")
GUARDED = {"derivable": "==", "genuine_ikhtilaf": "==", "encoding_error": "!="}
GAPS = ("encoding_error", "missing_fact", "missing_rule")


def _lit(v) -> str:
    if isinstance(v, bool):
        return _b(v)
    if isinstance(v, int):
        return str(v)
    return f".{v}"


def lean_expr(encoder: str, facts: dict) -> str:
    lits = ENCODERS[encoder].get("lits", {})
    return ENCODERS[encoder]["lean"].format(**{k: lits[k][v] if k in lits else _lit(v) for k, v in facts.items()})


def check_case(case: dict) -> list[str]:
    """Structural problems with a case (empty when well-formed)."""
    errs = []
    enc = ENCODERS.get(case.get("encoder"))
    if enc is None:
        return [f"unknown encoder {case.get('encoder')}"]
    if case["class"] not in CLASSES:
        errs.append(f"unknown class {case['class']}")
    if case["class"] in GUARDED:
        f = case.get("facts") or {}
        if set(f) != set(enc["facts"]) or any(f[k] not in dom for k, dom in enc["facts"].items()):
            errs.append("facts do not match the encoder")
        elif case.get("expected") not in enc["out"]:
            errs.append("expected outside the encoder's output domain")
        elif (enc["py"](f) == case["expected"]) != (GUARDED[case["class"]] == "=="):
            errs.append("class contradicts the kernel's output")
    if case["class"] == "genuine_ikhtilaf" and len(case.get("positions") or []) < 2:
        errs.append("ikhtilāf needs at least two positions")
    for n in case.get("needs", []):
        if not n.startswith(("fact:", "rule:")):
            errs.append(f"need {n} is neither fact: nor rule:")
    if "needs" in case and case["class"] not in GAPS and not (case["class"] == "genuine_ikhtilaf" and not case.get("matches_madhhab")):
        errs.append("needs on a case that is not a gap")
    return errs


def lean_file(cases: list[dict]) -> str:
    lines = ["-- GENERATED by `python -m usul_corpus takhrij` from corpus/takhrij/*.json. Do not edit.",
             "-- Each guard checks one annotated farʿ against the formal reading: == for derivable and",
             "-- ikhtilāf cases (the madhhab position), != for recorded encoding errors.",
             "import Usul", ""]
    for c in cases:
        if c["class"] in GUARDED:
            lines.append(f"-- {c['far']} ({c['class']})")
            lines.append(f"#guard ({lean_expr(c['encoder'], c['facts'])}) {GUARDED[c['class']]} {_lit(c['expected'])}")
    return "\n".join(lines) + "\n"


def mirror_file() -> str:
    """Every input of every encoder: the Python mirror annotators use equals the Lean kernel."""
    from itertools import product
    lines = ["-- GENERATED by `python -m usul_corpus takhrij`. Do not edit.",
             "-- Exhaustive check that each encoder's Python mirror equals its Lean reading.",
             "import Usul", ""]
    for name, enc in ENCODERS.items():
        keys = list(enc["facts"])
        for combo in product(*(enc["facts"][k] for k in keys)):
            facts = dict(zip(keys, combo))
            lines.append(f"#guard ({lean_expr(name, facts)}) == {_lit(enc['py'](facts))}")
    return "\n".join(lines) + "\n"


def report(cases: list[dict]) -> dict:
    by = Counter(c["class"] for c in cases)
    scope = len(cases) - by["segmentation_error"]
    per = {e: dict(Counter(c["class"] for c in cases if c["encoder"] == e)) for e in ENCODERS}
    ikh = [c for c in cases if c["class"] == "genuine_ikhtilaf"]
    return {"total": len(cases), "classes": dict(sorted(by.items())),
            "coverage": round((by["derivable"] + by["genuine_ikhtilaf"]) / scope, 3) if scope else 0.0,
            "madhhab_coverage": round((by["derivable"] + sum(1 for c in ikh if c.get("matches_madhhab"))) / scope, 3) if scope else 0.0,
            "encoding_error": by["encoding_error"],
            "ikhtilaf_matching_madhhab": sum(1 for c in ikh if c.get("matches_madhhab")),
            "gaps_open": sum(1 for c in cases if c.get("needs")),
            "revisited": sum(1 for c in cases if c.get("revisit")),
            "revisit_queue": revisit_queue(cases),
            "per_encoder": {e: dict(sorted(v.items())) for e, v in per.items() if v}}


def load(root: Path) -> list[dict]:
    return [c for f in sorted((root / "takhrij").glob("*.json")) if f.name != "report.json"
            for c in json.loads(f.read_text())["cases"]]
