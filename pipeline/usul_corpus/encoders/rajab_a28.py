"""Shard rajab-a28: the readings of Ibn Rajab's qāʿida 82, one per nawʿ (Usul.Readings.RajabA28)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA28"

ENCODERS: dict[str, dict] = {
    "rajab_a28_toward_ownership_growth": dict(
        sadi=[], qawaid=[RAJAB.format(82)],
        facts={"lazim": B, "from_substance": B},
        out=B, lean=f"{_NS}.towardOwnershipFollows {{lazim}} {{from_substance}}",
        py=lambda f: f["lazim"]),
    "rajab_a28_growth_in_nonownership_contract": dict(
        sadi=[], qawaid=[RAJAB.format(82)],
        facts={"on_substance": B, "lazim": B},
        out=B, lean=f"{_NS}.growthInContract {{on_substance}} {{lazim}}",
        py=lambda f: f["on_substance"] and f["lazim"]),
    "rajab_a28_growth_follows_hand": dict(
        sadi=[], qawaid=[RAJAB.format(82)],
        facts={"shares_ground": B},
        out=B, lean=f"{_NS}.growthFollowsHand {{shares_ground}}",
        py=lambda f: True),
    "rajab_a28_faskh_growth_returns": dict(
        sadi=[], qawaid=[RAJAB.format(82)],
        facts={"from_substance": B, "lifts_from_origin": B},
        out=B, lean=f"{_NS}.faskhGrowthFollows {{from_substance}} {{lifts_from_origin}}",
        py=lambda f: f["from_substance"] and f["lifts_from_origin"]),
    "rajab_a28_right_reaches_growth": dict(
        sadi=[], qawaid=[RAJAB.format(82)],
        facts={"lazim_right": B, "from_substance": B},
        out=B, lean=f"{_NS}.rightGrowthFollows {{lazim_right}} {{from_substance}}",
        py=lambda f: f["lazim_right"] and f["from_substance"]),
}
