"""Shard rajab-a2 (lane A): readings of Ibn Rajab's qawāʿid 72, 73, 74, 79 and 80 (Usul.Readings.RajabA2)."""

from ..takhrij import B, RAJAB

_NS = "Usul.Readings.RajabA2"

ENCODERS: dict[str, dict] = {
    "nafaqa_stipulated_in_contract": dict(
        sadi=[], qawaid=[RAJAB.format(72)], facts={"muawada": B, "binding_contract": B},
        out=B, lean=f"{_NS}.nafaqaStipulable {{muawada}} {{binding_contract}}",
        py=lambda f: not f["muawada"] or f["binding_contract"]),
    "nafaqa_taken_owned": dict(
        sadi=[], qawaid=[RAJAB.format(72)], facts={"muawada": B, "spent_in_purpose": B},
        out=B, lean=f"{_NS}.nafaqaOwned {{muawada}} {{spent_in_purpose}}",
        py=lambda f: f["muawada"] or f["spent_in_purpose"]),
    "benefit_condition_against_compensation": dict(
        sadi=[], qawaid=[RAJAB.format(73)], facts={"against_compensation": B},
        out=B, lean=f"{_NS}.benefitConditionValid {{against_compensation}}",
        py=lambda f: f["against_compensation"]),
    "wage_without_stipulation": dict(
        sadi=[], qawaid=[RAJAB.format(74)], facts={"professional": B, "public_or_rescue": B},
        out=B, lean=f"{_NS}.wageWithoutStipulation {{professional}} {{public_or_rescue}}",
        py=lambda f: f["professional"] or f["public_or_rescue"]),
    "crop_without_valid_permission": dict(
        sadi=[], qawaid=[RAJAB.format(79)], facts={"valid_permission": B},
        out=B, lean=f"{_NS}.ownerTakesCrop {{valid_permission}}",
        py=lambda f: not f["valid_permission"]),
    "repeat_bearing_roots_as_trees": dict(
        sadi=[], qawaid=[RAJAB.format(80)], facts={"repeated_bearing": B},
        out=B, lean=f"{_NS}.asTree {{repeated_bearing}}",
        py=lambda f: f["repeated_bearing"]),
}
