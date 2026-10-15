"""Shard rajab-a16: readings of Ibn Rajab's qawāʿid 129, 130 and 131 (Usul.Readings.RajabA16)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA16"

ENCODERS: dict[str, dict] = {
    "hit_state_governs": dict(
        sadi=[], qawaid=[RAJAB.format(129)], facts={"liability_ruling": B},
        out=B, lean=f"{_NS}.hitStateGoverns {{liability_ruling}}",
        py=lambda f: f["liability_ruling"]),
    "aqila_bears_across_change": dict(
        sadi=[], qawaid=[RAJAB.format(129)], facts={"member_at_shot": B, "member_at_hit": B},
        out=B, lean=f"{_NS}.aqilaBears {{member_at_shot}} {{member_at_hit}}",
        py=lambda f: f["member_at_shot"] and f["member_at_hit"]),
    "needed_item_is_surplus": dict(
        sadi=[], qawaid=[RAJAB.format(130)], facts={"needed": B},
        out=B, lean=f"{_NS}.countsAsSurplus {{needed}}",
        py=lambda f: not f["needed"]),
    "budh_capacity_is_wealth": dict(
        sadi=[], qawaid=[RAJAB.format(131)], facts={"has_wealth": B, "can_earn_by_budh": B},
        out=B, lean=f"{_NS}.countsAsRich {{has_wealth}} {{can_earn_by_budh}}",
        py=lambda f: f["has_wealth"]),
}
