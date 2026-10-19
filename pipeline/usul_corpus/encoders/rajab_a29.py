"""Shard rajab-a29: readings of Ibn Rajab's qawāʿid 84 and 86 (Usul.Readings.RajabA29)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA29"

_KINDS = ("aynAndManfaa", "aynWithoutManfaa", "manfaaWithoutAyn", "intifaOnly")

ENCODERS: dict[str, dict] = {
    "a29_haml_hukm_before_separation": dict(
        sadi=[], qawaid=[RAJAB.format(84)],
        facts={"haml_ruling_for_another": B, "haml_amara_evident": B},
        out=B, lean=f"{_NS}.hamlHukm {{haml_ruling_for_another}} {{haml_amara_evident}}",
        py=lambda f: f["haml_amara_evident"]),
    "a29_four_kinds_of_milk": dict(
        sadi=[], qawaid=[RAJAB.format(86)],
        facts={"milk_holds_ayn": B, "milk_benefit_by_tamlik": B},
        out=_KINDS, lean=f"{_NS}.milkKind {{milk_holds_ayn}} {{milk_benefit_by_tamlik}}",
        py=lambda f: _KINDS[2 * (not f["milk_holds_ayn"]) + (not f["milk_benefit_by_tamlik"])]),
}
