"""Shard rajab-a12: readings of Ibn Rajab's qawāʿid 116, 117 and 118 (Usul.Readings.RajabA12)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA12"

ENCODERS: dict[str, dict] = {
    "ownership_relates_back": dict(
        sadi=[], qawaid=[RAJAB.format(116)], facts={"settled_cause": B},
        out=B, lean=f"{_NS}.ruledFromCause {{settled_cause}}",
        py=lambda f: f["settled_cause"]),
    "worship_ruled_from_start": dict(
        sadi=[], qawaid=[RAJAB.format(116)], facts={"condition_within_time": B},
        out=B, lean=f"{_NS}.worshipFromStart {{condition_within_time}}",
        py=lambda f: f["condition_within_time"]),
    "occurrence_state_governs": dict(
        sadi=[], qawaid=[RAJAB.format(117)], facts={"suspension_barred": B, "occurrence_barred": B},
        out=B, lean=f"{_NS}.occurrenceGoverns {{suspension_barred}} {{occurrence_barred}}",
        py=lambda f: not f["occurrence_barred"]),
    "cancel_on_existence_valid": dict(
        sadi=[], qawaid=[RAJAB.format(118)], facts={"legitimate_purpose": B},
        out=B, lean=f"{_NS}.cancelOnExistenceValid {{legitimate_purpose}}",
        py=lambda f: f["legitimate_purpose"]),
}
