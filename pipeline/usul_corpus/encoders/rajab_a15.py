"""Shard rajab-a15: readings of Ibn Rajab's qawāʿid 125 and 128 (Usul.Readings.RajabA15)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA15"

ENCODERS: dict[str, dict] = {
    "intention_shapes_wording": dict(
        sadi=[], qawaid=[RAJAB.format(125)],
        facts={"restricts_absolute": B, "excepts_from_text": B},
        out=B, lean=f"{_NS}.intentionGoverns {{restricts_absolute}} {{excepts_from_text}}",
        py=lambda f: not f["restricts_absolute"] and not f["excepts_from_text"]),
    "spread_follows_injury": dict(
        sadi=[], qawaid=[RAJAB.format(128)],
        facts={"guaranteed_at_injury": B, "guaranteed_at_spread": B},
        out=B, lean=f"{_NS}.spreadFollowsInjury {{guaranteed_at_injury}} {{guaranteed_at_spread}}",
        py=lambda f: f["guaranteed_at_injury"]),
    "injury_state_measures": dict(
        sadi=[], qawaid=[RAJAB.format(128)],
        facts={"guaranteed_at_injury": B, "guaranteed_at_spread": B},
        out=B, lean=f"{_NS}.measuredAtInjury {{guaranteed_at_injury}} {{guaranteed_at_spread}}",
        py=lambda f: f["guaranteed_at_injury"] and f["guaranteed_at_spread"]),
}
