"""Shard rajab-a8: readings of Ibn Rajab's qawāʿid 104 and 105 (Usul.Readings.RajabA8)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA8"

ENCODERS: dict[str, dict] = {
    "unknown_consent_binds": dict(
        sadi=[], qawaid=[RAJAB.format(104)], facts={"vagueness_admitted": B},
        out=B, lean=f"{_NS}.unknownConsentBinds {{vagueness_admitted}}",
        py=lambda f: f["vagueness_admitted"]),
    "vague_insha_valid": dict(
        sadi=[], qawaid=[RAJAB.format(105)], facts={"binding_transfer": B, "equal_mixed": B},
        out=B, lean=f"{_NS}.vagueInshaValid {{binding_transfer}} {{equal_mixed}}",
        py=lambda f: not f["binding_transfer"] or f["equal_mixed"]),
    "vague_report_accepted": dict(
        sadi=[], qawaid=[RAJAB.format(105)], facts={"religious_or_against_self": B},
        out=B, lean=f"{_NS}.vagueReportAccepted {{religious_or_against_self}}",
        py=lambda f: f["religious_or_against_self"]),
    "shared_name_insha_valid": dict(
        sadi=[], qawaid=[RAJAB.format(105)],
        facts={"vague_valid": B, "intended_specific": B, "witnessing_required": B},
        out=B, lean=f"{_NS}.sharedNameValid {{vague_valid}} {{intended_specific}} {{witnessing_required}}",
        py=lambda f: (not f["witnessing_required"]) if f["intended_specific"] else f["vague_valid"]),
    "lot_distinguishes_hidden_entitled": dict(
        sadi=[], qawaid=[RAJAB.format(105)], facts={"specific_in_fact": B},
        out=B, lean=f"{_NS}.lotDistinguishes {{specific_in_fact}}",
        py=lambda f: f["specific_in_fact"]),
}
