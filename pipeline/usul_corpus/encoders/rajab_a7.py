"""Shard rajab-a7: readings of Ibn Rajab's qawāʿid 100, 101 and 102 (Usul.Readings.RajabA7)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA7"

ENCODERS: dict[str, dict] = {
    "vowed_as_shar_obligation": dict(
        sadi=[], qawaid=[RAJAB.format(100)], facts={"shar_ruling": B, "mandub_ruling": B},
        out=B, lean=f"{_NS}.vowedRuling {{shar_ruling}} {{mandub_ruling}}",
        py=lambda f: f["shar_ruling"]),
    "split_halves_suffice": dict(
        sadi=[], qawaid=[RAJAB.format(101)], facts={"common_unit": B},
        out=B, lean=f"{_NS}.splitSuffices {{common_unit}}",
        py=lambda f: f["common_unit"]),
    "forbidden_cause_voided": dict(
        sadi=[], qawaid=[RAJAB.format(102)], facts={"forbidden_manner": B, "souls_drawn": B},
        out=B, lean=f"{_NS}.causeVoided {{forbidden_manner}} {{souls_drawn}}",
        py=lambda f: f["forbidden_manner"] and f["souls_drawn"]),
    "hastened_right_forfeited": dict(
        sadi=[], qawaid=[RAJAB.format(102)], facts={"hastened_forbidden": B},
        out=B, lean=f"{_NS}.hastenedForfeited {{hastened_forbidden}}",
        py=lambda f: f["hastened_forbidden"]),
}
