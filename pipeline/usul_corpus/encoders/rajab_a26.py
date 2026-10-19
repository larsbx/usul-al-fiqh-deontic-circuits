"""Shard rajab-a26: readings of Ibn Rajab's qawāʿid 13 and 23 (Usul.Readings.RajabA26)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA26"

ENCODERS: dict[str, dict] = {
    "a26_ihala_on_known_cause": dict(
        sadi=[], qawaid=[RAJAB.format(13)],
        facts={"known_cause_fit": B, "zahir_points_elsewhere": B},
        out=B, lean=f"{_NS}.ihalaOnKnownCause {{known_cause_fit}} {{zahir_points_elsewhere}}",
        py=lambda f: f["known_cause_fit"] and not f["zahir_points_elsewhere"]),
    "a26_refused_idhn_lapses": dict(
        sadi=[], qawaid=[RAJAB.format(23)],
        facts={"refusal_forbidden": B, "mere_permission": B},
        out=B, lean=f"{_NS}.idhnLapses {{refusal_forbidden}} {{mere_permission}}",
        py=lambda f: f["refusal_forbidden"] and f["mere_permission"]),
}
