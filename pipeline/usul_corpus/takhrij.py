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
        sadi=[32], qawaid=[RAJAB.format(75)],
        facts={"gift": B, "owed_by_other": B, "permission": B, "permission_unobtainable": B},
        out=B, lean="Usul.Refinements.recourseNec {gift} {owed_by_other} {permission} {permission_unobtainable}",
        py=lambda f: not f["gift"] and (f["owed_by_other"] or f["permission"] or f["permission_unobtainable"])),
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
    "unknown_as_nonexistent": dict(
        sadi=[20], qawaid=[RAJAB.format(106)], facts={"unknown": B, "despair": B, "hardship": B},
        out=B, lean="Usul.Refinements.treatedAsAbsent {unknown} {despair} {hardship}",
        py=lambda f: f["unknown"] and (f["despair"] or f["hardship"])),
    "haml_ala_adna": dict(
        sadi=[], qawaid=[LAHHAM.format(52)], facts={"unspecified": B, "ranked": B},
        out=B, lean="Usul.Refinements.hamlAlaAdna {unspecified} {ranked}",
        py=lambda f: f["unspecified"] and f["ranked"]),
    "trust_voidance": dict(
        sadi=[14], qawaid=[RAJAB.format(45)], facts={"pure_trust": B, "transgressed": B},
        out=B, lean="Usul.Refinements.trustVoided {pure_trust} {transgressed}",
        py=lambda f: f["pure_trust"] and f["transgressed"]),
    "abstention_under_possible_condition": dict(
        sadi=[11], qawaid=[RAJAB.format(160)], facts={"suspended": B, "possible": B, "absence_known": B},
        out=B, lean="Usul.Refinements.abstains {suspended} {possible} {absence_known}",
        py=lambda f: f["suspended"] and f["possible"] and not f["absence_known"]),
    "ghulul_forfeiture": dict(
        sadi=[35], qawaid=[RAJAB.format(140)], facts={"as_ghulul": B},
        out=B, lean="Usul.Refinements.ghululForfeits {as_ghulul}",
        py=lambda f: f["as_ghulul"]),
    "right_for_or_against_self": dict(
        sadi=[55], qawaid=[LAHHAM.format(54)], facts={"for_himself": B},
        out=B, lean="Usul.Refinements.heardAfterDenial {for_himself}",
        py=lambda f: not f["for_himself"]),
    "fay_tie_break": dict(
        sadi=[25], qawaid=[RAJAB.format(160)], facts={"tie_break_criteria": B},
        out=("byCriteria", "rulerChoice"), lean="Usul.Refinements.fayTieBreak [{tie_break_criteria}]",
        py=lambda f: "byCriteria" if f["tie_break_criteria"] else "rulerChoice"),
    "luqata": dict(
        sadi=[20], qawaid=[RAJAB.format(106)], facts={"year_passed": B, "ownable": B},
        out=("hold", "finderOwns", "charity"), lean="Usul.Refinements.luqata {year_passed} {ownable}",
        py=lambda f: "hold" if not f["year_passed"] else "finderOwns" if f["ownable"] else "charity"),
    "ihram_specification": dict(
        sadi=[11], qawaid=[RAJAB.format(106)], facts={"component": ("hajj", "umra")},
        out=B, lean="Usul.Refinements.validOnEvery {component} Usul.Refinements.Nusuk.all",
        lits={"component": {"hajj": "Usul.Refinements.hajjValid", "umra": "Usul.Refinements.umraValid"}},
        py=lambda f: f["component"] == "hajj"),
    "residual_jawaz_after_sarf": dict(
        sadi=[50], qawaid=[LAHHAM.format(43)], facts={"sarf": B},
        out=B, lean="Usul.Refinements.jawazAfterSarf {sarf}",
        py=lambda f: not f["sarf"]),
    "amr_mixed": dict(
        sadi=[], qawaid=[LAHHAM.format(43)], facts={"per_item_status": ("wajib", "mandub")},
        out=HUKM, lean="Usul.Refinements.amrPerItem (fun _ : Unit => {per_item_status}) ()",
        py=lambda f: f["per_item_status"]),
    "excused_error": dict(
        sadi=[11], qawaid=[RAJAB.format(6)], facts={"others_right": B, "negligent": B},
        out=B, lean="Usul.Refinements.errorExcused {others_right} {negligent}",
        py=lambda f: not f["others_right"] and not f["negligent"]),
    "istihlak": dict(
        sadi=[20], qawaid=[RAJAB.format(22)], facts={"consumed": B},
        out=B, lean="Usul.Refinements.istihlak {consumed}",
        py=lambda f: f["consumed"]),
    "doubt_in_condition": dict(
        sadi=[11, 52], qawaid=[RAJAB.format(68)], facts={"needs_firm_intention": B, "ghalaba": B, "asl_mustashab": B},
        out=B, lean="Usul.Refinements.validUnderDoubt {needs_firm_intention} {ghalaba} {asl_mustashab}",
        py=lambda f: not f["needs_firm_intention"] or f["ghalaba"] or f["asl_mustashab"]),
    "switch_to_original": dict(
        sadi=[28], qawaid=[RAJAB.format(7)], facts={"necessity": B},
        out=B, lean="Usul.Refinements.mustSwitch {necessity}",
        py=lambda f: f["necessity"]),
    "benefit_to_other": dict(
        sadi=[], qawaid=[RAJAB.format(27)], facts={"benefits_other": B},
        out=B, lean="Usul.Refinements.liableForOthersBenefit {benefits_other}",
        py=lambda f: f["benefits_other"]),
    "concurrent_causes": dict(
        sadi=[], qawaid=[RAJAB.format(28)], facts={"other_act_permitted": B},
        out=("full", "half"), lean="Usul.Refinements.concurrentShare {other_act_permitted}",
        py=lambda f: "full" if f["other_act_permitted"] else "half"),
    "unknown_condition": dict(
        sadi=[], qawaid=[RAJAB.format(64), RAJAB.format(65)], facts={"knew": B, "liability_only": B},
        out=B, lean="Usul.Refinements.countsAsMet {knew} {liability_only}",
        py=lambda f: f["knew"] or f["liability_only"]),
    "running_water": dict(
        sadi=[], qawaid=[RAJAB.format(1)], facts={"running": B},
        out=("perJirya", "whole"), lean="Usul.Refinements.runningBody {running}",
        py=lambda f: "perJirya" if f["running"] else "whole"),
    "many_over_noble": dict(
        sadi=[], qawaid=[RAJAB.format(17)], facts={"same_cost": B},
        out=B, lean="Usul.Refinements.preferMany {same_cost}",
        py=lambda f: f["same_cost"]),
    "mistaken_basis": dict(
        sadi=[], qawaid=[RAJAB.format(66)], facts={"believed_basis": B, "actual_basis": B},
        out=B, lean="Usul.Refinements.validWithBasis {believed_basis} {actual_basis}",
        py=lambda f: f["believed_basis"] and f["actual_basis"]),
    "hand_liability": dict(
        sadi=[], qawaid=[RAJAB.format(91)], facts={"property_like": B},
        out=B, lean="Usul.Refinements.handLiable {property_like}",
        py=lambda f: f["property_like"]),
    "taker_from_usurper": dict(
        sadi=[], qawaid=[RAJAB.format(93)], facts={"entered_on_liability": B},
        out=B, lean="Usul.Refinements.takerRecourse {entered_on_liability}",
        py=lambda f: not f["entered_on_liability"]),
    "hukm_against_own_ijtihad": dict(
        sadi=[], qawaid=[RAJAB.format(68)], facts={"contradicts_nass": B},
        out=B, lean="Usul.Refinements.rulingUndone {contradicts_nass}",
        py=lambda f: f["contradicts_nass"]),
    "ayman_by_urf": dict(
        sadi=[9], qawaid=[RAJAB.format(1)], facts={"custom_one_body": B},
        out=("perJirya", "whole"), lean="Usul.Refinements.oathBody {custom_one_body}",
        py=lambda f: "whole" if f["custom_one_body"] else "perJirya"),
    "khalt_as_shirka": dict(
        sadi=[], qawaid=[RAJAB.format(22)], facts={"same_kind": B, "indistinct": B},
        out=("shared", "consumed", "separate"), lean="Usul.Refinements.mixedOutcome {same_kind} {indistinct}",
        py=lambda f: "separate" if not f["indistinct"] else "shared" if f["same_kind"] else "consumed"),
    "mixed_haram_by_proportion": dict(
        sadi=[], qawaid=[RAJAB.format(22)], facts={"lawful_many": B},
        out=("suspend", "takeOut"), lean="Usul.Refinements.mixedHaram {lawful_many}",
        py=lambda f: "takeOut" if f["lawful_many"] else "suspend"),
    "rukhsa_under_doubt": dict(
        sadi=[11], qawaid=[RAJAB.format(68)], facts={"rukhsa_needs_certainty": B, "permission_established": B},
        out=B, lean="Usul.Refinements.rukhsaValid {rukhsa_needs_certainty} {permission_established}",
        py=lambda f: not f["rukhsa_needs_certainty"] or f["permission_established"]),
    "taliq_al_bay": dict(
        sadi=[], qawaid=[RAJAB.format(68)], facts={"conditional": B, "known_to_hold": B},
        out=B, lean="Usul.Refinements.conditionedSaleValid {conditional} {known_to_hold}",
        py=lambda f: not f["conditional"] or f["known_to_hold"]),
    "qisas_belongs_to_whom": dict(
        sadi=[], qawaid=[RAJAB.format(65)], facts={"right_is_victims": B},
        out=B, lean="Usul.Refinements.pardonOfSpreadValid {right_is_victims}",
        py=lambda f: f["right_is_victims"]),
    "makeup_after_failure": dict(
        sadi=[], qawaid=[RAJAB.format(31)],
        facts={"failure": ("corruption", "prevention", "lossWithFault", "lossWithoutFault")},
        out=("asBegun", "baseline"), lean="Usul.Refinements.makeupAfterFailure {failure}",
        py=lambda f: "asBegun" if f["failure"] in ("corruption", "lossWithFault") else "baseline"),
    "defective_compensation": dict(
        sadi=[], qawaid=[RAJAB.format(47)], facts={"contract_liability": B},
        out=("agreed", "equivalent"), lean="Usul.Refinements.defectiveCompensationBasis {contract_liability}",
        py=lambda f: "agreed" if f["contract_liability"] else "equivalent"),
    "hair_detached": dict(
        sadi=[], qawaid=[RAJAB.format(2)], facts={"hair_or_nail": B},
        out=("attached", "detached"), lean="Usul.Refinements.hairStatus {hair_or_nail}",
        py=lambda f: "detached" if f["hair_or_nail"] else "attached"),
    "growth_from_substance": dict(
        sadi=[], qawaid=[RAJAB.format(20), RAJAB.format(21)], facts={"from_substance": B},
        out=("part", "separate"), lean="Usul.Refinements.growthKind {from_substance}",
        py=lambda f: "part" if f["from_substance"] else "separate"),
    "right_after_transfer": dict(
        sadi=[], qawaid=[RAJAB.format(24)], facts={"on_property": B, "reason_ceases": B},
        out=B, lean="Usul.Refinements.rightSurvivesTransfer {on_property} {reason_ceases}",
        py=lambda f: f["on_property"] or not f["reason_ceases"]),
    "follows_proven_ownership": dict(
        sadi=[], qawaid=[RAJAB.format(25)], facts={"follows_in_sale": B},
        out=B, lean="Usul.Refinements.followsProven {follows_in_sale}",
        py=lambda f: f["follows_in_sale"]),
    "tolerance_exceeded": dict(
        sadi=[], qawaid=[RAJAB.format(29)], facts={"at_fault": B},
        out=("all", "excess"), lean="Usul.Refinements.toleranceLapse {at_fault}",
        py=lambda f: "all" if f["at_fault"] else "excess"),
    "failed_obligation_returns": dict(
        sadi=[], qawaid=[RAJAB.format(30)], facts={"failed_to_count": B},
        out=B, lean="Usul.Refinements.returnsToOwner {failed_to_count}",
        py=lambda f: f["failed_to_count"]),
    "benefit_exception": dict(
        sadi=[], qawaid=[RAJAB.format(32)], facts={"known_period": B, "tolerates_uncertainty": B},
        out=B, lean="Usul.Refinements.benefitExceptionValid {known_period} {tolerates_uncertainty}",
        py=lambda f: f["known_period"] or f["tolerates_uncertainty"]),
    "implicit_exception": dict(
        sadi=[], qawaid=[RAJAB.format(33)], facts={"implicit": B},
        out=B, lean="Usul.Refinements.uncertainExceptionValid {implicit}",
        py=lambda f: f["implicit"]),
    "manumission_spread": dict(
        sadi=[], qawaid=[RAJAB.format(34)], facts={"binding_contract": B},
        out=B, lean="Usul.Refinements.manumissionReachesBenefits {binding_contract}",
        py=lambda f: not f["binding_contract"]),
    "benefit_then_thing": dict(
        sadi=[], qawaid=[RAJAB.format(35)], facts={"perpetual_commutative": B},
        out=B, lean="Usul.Refinements.priorContractDissolves {perpetual_commutative}",
        py=lambda f: f["perpetual_commutative"]),
    "successive_contracts": dict(
        sadi=[], qawaid=[RAJAB.format(37)], facts={"successive": B},
        out=B, lean="Usul.Refinements.laterContractGoverns {successive}",
        py=lambda f: f["successive"]),
    "successive_by_binding": dict(
        sadi=[], qawaid=[RAJAB.format(37)],
        facts={"successive": B, "earlier_binding": B, "later_binding": B}, out=B,
        lean="Usul.Refinements.laterBindingGoverns {successive} {earlier_binding} {later_binding}",
        py=lambda f: f["successive"] and (f["later_binding"] or not f["earlier_binding"])),
    "words_out_of_nature": dict(
        sadi=[], qawaid=[RAJAB.format(38)], facts={"other_contract_possible": B},
        out=B, lean="Usul.Refinements.asKinayaValid {other_contract_possible}",
        py=lambda f: f["other_contract_possible"]),
    "contract_by_kinaya": dict(
        sadi=[], qawaid=[RAJAB.format(39)], facts={"needs_witnessing": B},
        out=B, lean="Usul.Refinements.kinayaConcludes {needs_witnessing}",
        py=lambda f: not f["needs_witnessing"]),
    "right_to_substitute": dict(
        sadi=[], qawaid=[RAJAB.format(41)], facts={"bound_to_thing": B},
        out=B, lean="Usul.Refinements.rightPassesToSubstitute {bound_to_thing}",
        py=lambda f: f["bound_to_thing"]),
    "umum_lafz": dict(
        sadi=[], qawaid=[LAHHAM.format(61)], facts={"in_occasion": B, "general_wording": B},
        out=B, lean="Usul.Dalala.coversBeyondSabab true {in_occasion} {general_wording}",
        py=lambda f: f["in_occasion"] or f["general_wording"]),
    # Candidate capability fixtures; the six live case gaps are not reclassified.
    "command_nonverbal_usage": dict(
        sadi=[], qawaid=[LAHHAM.format(43)],
        facts={"reading": ("qadiReported", "jamiWriting"), "form": ("writing", "gesture")},
        out=("literal", "notLiteral", "unsettled"),
        lean="Usul.CommandSchemata.nonverbalUsage {reading} {form}",
        py=lambda f: "notLiteral" if f["reading"] == "qadiReported" else
            "literal" if f["form"] == "writing" else "unsettled"),
    "command_prophetic_act_usage": dict(
        sadi=[], qawaid=[LAHHAM.format(43)],
        facts={"reading": ("abuBarakat", "literalReport", "authorConditional"), "imitation_established": B},
        out=("literal", "figurative", "unsettled"),
        lean="Usul.CommandSchemata.propheticActUsage {reading} {imitation_established}",
        py=lambda f: "figurative" if f["reading"] == "abuBarakat" else
            "literal" if f["reading"] == "literalReport" or f["imitation_established"] else "unsettled"),
    "command_obligation_status": dict(
        sadi=[], qawaid=[LAHHAM.format(43)],
        facts={"reading": ("qadi", "abuBarakat"),
               "expression": ("bareCommand", "unqualifiedThreat", "wujubLabel", "fardLabel"),
               "qarina": ("none",) + HUKM},
        out=HUKM,
        lean="Usul.CommandSchemata.obligationStatus {reading} {expression} {qarina}",
        lits={"qarina": {"none": "none", **{h: f"(some .{h})" for h in HUKM}}},
        py=lambda f: "wajib" if f["reading"] == "abuBarakat" and f["expression"] != "bareCommand" else
            "wajib" if f["qarina"] == "none" else f["qarina"]),
    "command_intended_usage": dict(
        sadi=[], qawaid=[LAHHAM.format(43)],
        facts={"reading": ("qadiReport", "karkhiRazi", "abuBarakat", "qadiArgument"),
               "intended": ("recommendation", "permission")},
        out=("literal", "figurative", "unsettled"),
        lean="Usul.CommandSchemata.intendedUsage {reading} {intended}",
        py=lambda f: {
            ("qadiReport", "recommendation"): "literal", ("qadiReport", "permission"): "literal",
            ("karkhiRazi", "recommendation"): "figurative", ("karkhiRazi", "permission"): "unsettled",
            ("abuBarakat", "recommendation"): "unsettled", ("abuBarakat", "permission"): "figurative",
            ("qadiArgument", "recommendation"): "literal", ("qadiArgument", "permission"): "figurative",
        }[(f["reading"], f["intended"])]),
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
