"""Shard rajab-a17: readings of Ibn Rajab's qawāʿid 132, 134, 136, 139 and 141 (Usul.Readings.RajabA17)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA17"

ENCODERS: dict[str, dict] = {
    "craft_capacity_is_wealth": dict(
        sadi=[], qawaid=[RAJAB.format(132)],
        facts={"has_wealth": B, "can_earn_by_craft": B, "beyond_own_maintenance": B},
        out=B, lean=f"{_NS}.craftCountsAsRich {{has_wealth}} {{can_earn_by_craft}} {{beyond_own_maintenance}}",
        py=lambda f: f["has_wealth"] or f["can_earn_by_craft"]),
    "prevention_easier_than_removal": dict(
        sadi=[], qawaid=[RAJAB.format(134)],
        facts={"impediment": B, "before_establishment": B},
        out=B, lean=f"{_NS}.impedimentOperates {{impediment}} {{before_establishment}}",
        py=lambda f: f["impediment"] and f["before_establishment"]),
    "supervening_bar_extends_to_preliminaries": dict(
        sadi=[], qawaid=[RAJAB.format(136)],
        facts={"weak_ownership": B, "worship": B, "bars_indulgence": B},
        out=B, lean=f"{_NS}.preliminariesForbidden {{weak_ownership}} {{worship}} {{bars_indulgence}}",
        py=lambda f: f["weak_ownership"] or (f["worship"] and f["bars_indulgence"])),
    "unfixed_right_reaches_fixed": dict(
        sadi=[], qawaid=[RAJAB.format(139)],
        facts={"takes_all_when_alone": B, "tied_to_base": B, "same_locus": B},
        out=B, lean=f"{_NS}.unfixedMayReachFixed {{takes_all_when_alone}} {{tied_to_base}} {{same_locus}}",
        py=lambda f: f["takes_all_when_alone"] or (f["tied_to_base"] and not f["same_locus"])),
    "custodian_liable_at_due_time": dict(
        sadi=[], qawaid=[RAJAB.format(141)],
        facts={"custodian_until_term": B},
        out=B, lean=f"{_NS}.dueTimeGoverns {{custodian_until_term}}",
        py=lambda f: f["custodian_until_term"]),
}
