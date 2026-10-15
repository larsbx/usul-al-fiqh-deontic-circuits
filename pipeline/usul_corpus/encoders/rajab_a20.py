"""Shard rajab-a20: readings of Ibn Rajab's qawāʿid 144 and 146 (Usul.Readings.RajabA20)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA20"

ENCODERS: dict[str, dict] = {
    "heir_takes_deceased_right": dict(
        sadi=[], qawaid=[RAJAB.format(144)],
        facts={"accrues_at_death": B, "claimed_or_held": B, "attached_to_inherited_property": B},
        out=B, lean=f"{_NS}.heirInherits {{accrues_at_death}} {{claimed_or_held}} {{attached_to_inherited_property}}",
        py=lambda f: f["accrues_at_death"] or f["claimed_or_held"] or f["attached_to_inherited_property"]),
    "heir_stands_in_owed_right": dict(
        sadi=[], qawaid=[RAJAB.format(144)],
        facts={"obligation_binding": B, "tends_to_binding": B},
        out=B, lean=f"{_NS}.heirStandsIn {{obligation_binding}} {{tends_to_binding}}",
        py=lambda f: f["obligation_binding"] or f["tends_to_binding"]),
    "rajiyya_takes_wife_rule": dict(
        sadi=[], qawaid=[RAJAB.format(146)],
        facts={"rajiyya": B, "listed_difference": B},
        out=B, lean=f"{_NS}.wifeRuleApplies {{rajiyya}} {{listed_difference}}",
        py=lambda f: not (f["rajiyya"] and f["listed_difference"])),
}
