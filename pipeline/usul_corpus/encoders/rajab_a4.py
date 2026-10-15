"""Shard rajab-a4: readings of Ibn Rajab's qawāʿid 77, 81, 90 and 92 (Usul.Readings.RajabA4)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA4"

ENCODERS: dict[str, dict] = {
    "attached_takeover_at_value": dict(
        sadi=[], qawaid=[RAJAB.format(77)], facts={"wrongful": B, "separable_without_harm": B},
        out=B, lean=f"{_NS}.takenOverAtValue {{wrongful}} {{separable_without_harm}}",
        py=lambda f: not f["wrongful"] and not f["separable_without_harm"]),
    "attached_growth_follows": dict(
        sadi=[], qawaid=[RAJAB.format(81)], facts={"reverts_to_transferor": B, "security_or_liability": B},
        out=B, lean=f"{_NS}.attachedGrowthFollows {{reverts_to_transferor}} {{security_or_liability}}",
        py=lambda f: f["reverts_to_transferor"] or f["security_or_liability"]),
    "cut_sale_left_to_ripen": dict(
        sadi=[], qawaid=[RAJAB.format(81)], facts={"left_until_ripe": B},
        out=B, lean=f"{_NS}.cutSaleVoid {{left_until_ripe}}",
        py=lambda f: f["left_until_ripe"]),
    "seizing_hand_liable": dict(
        sadi=[], qawaid=[RAJAB.format(90)], facts={"can_own_by_seizure": B, "transgressing": B},
        out=B, lean=f"{_NS}.seizingHandLiable {{can_own_by_seizure}} {{transgressing}}",
        py=lambda f: not f["can_own_by_seizure"] and f["transgressing"]),
    "hand_with_owner_liable": dict(
        sadi=[], qawaid=[RAJAB.format(92)], facts={"owner_control_removed": B},
        out=B, lean=f"{_NS}.liableWithOwnerHand {{owner_control_removed}}",
        py=lambda f: f["owner_control_removed"]),
}
