"""Shard rajab-a18: readings of Ibn Rajab's qawāʿid 137 and 138 (Usul.Readings.RajabA18)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA18"

ENCODERS: dict[str, dict] = {
    "qawad_choice_forfeits_attached_right": dict(
        sadi=[], qawaid=[RAJAB.format(137)], facts={"either_of_two": B, "victim_encumbered": B},
        out=B, lean=f"{_NS}.forfeitsAttachedRight {{either_of_two}} {{victim_encumbered}}",
        py=lambda f: f["either_of_two"] and f["victim_encumbered"]),
    "sulh_replaces_owned_wealth": dict(
        sadi=[], qawaid=[RAJAB.format(137)], facts={"either_of_two": B, "victim_owned": B},
        out=B, lean=f"{_NS}.sulhReplacesWealth {{either_of_two}} {{victim_owned}}",
        py=lambda f: f["either_of_two"] and f["victim_owned"]),
    "burdened_thing_compensated": dict(
        sadi=[], qawaid=[RAJAB.format(138)],
        facts={"guaranteed": B, "destroyed": B, "claimant_exists": B},
        out=B, lean=f"{_NS}.mustCompensate {{guaranteed}} {{destroyed}} {{claimant_exists}}",
        py=lambda f: f["guaranteed"] or (f["destroyed"] and f["claimant_exists"])),
}
