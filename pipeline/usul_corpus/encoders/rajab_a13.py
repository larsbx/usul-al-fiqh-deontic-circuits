"""Shard rajab-a13: readings of Ibn Rajab's qawāʿid 119, 120, 122 and 124 (Usul.Readings.RajabA13)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA13"

ENCODERS: dict[str, dict] = {
    "specific_singled_out": dict(
        sadi=[], qawaid=[RAJAB.format(119)], facts={"connected": B, "revocable": B},
        out=B, lean=f"{_NS}.specificSingledOut {{connected}} {{revocable}}",
        py=lambda f: f["connected"] or f["revocable"]),
    "takes_only_by_special": dict(
        sadi=[], qawaid=[RAJAB.format(119)], facts={"special_title": B},
        out=B, lean=f"{_NS}.takesOnlyBySpecial {{special_title}}",
        py=lambda f: f["special_title"]),
    "entitlement_multiplies": dict(
        sadi=[], qawaid=[RAJAB.format(119)], facts={"combined_attributes": B, "single_jiha": B},
        out=B, lean=f"{_NS}.entitlementMultiplies {{combined_attributes}} {{single_jiha}}",
        py=lambda f: f["combined_attributes"] and not f["single_jiha"]),
    "double_kinship_preferred": dict(
        sadi=[], qawaid=[RAJAB.format(120)], facts={"double_kinship": B},
        out=B, lean=f"{_NS}.doubleKinshipPreferred {{double_kinship}}",
        py=lambda f: f["double_kinship"]),
    "custom_restricts_general": dict(
        sadi=[], qawaid=[RAJAB.format(122)], facts={"customary_usage": B},
        out=B, lean=f"{_NS}.customRestricts {{customary_usage}}",
        py=lambda f: f["customary_usage"]),
    "cause_restricts_general": dict(
        sadi=[], qawaid=[RAJAB.format(124)], facts={"prompting_cause": B},
        out=B, lean=f"{_NS}.causeRestricts {{prompting_cause}}",
        py=lambda f: f["prompting_cause"]),
}
