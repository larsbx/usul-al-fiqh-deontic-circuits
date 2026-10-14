"""Shard rajab-a14: readings of Ibn Rajab's qawāʿid 121, 123 and 126 (Usul.Readings.RajabA14)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA14"

ENCODERS: dict[str, dict] = {
    "urf_specialises_general": dict(
        sadi=[], qawaid=[RAJAB.format(121)],
        facts={"urfi_haqiqa": B, "only_qualified": B, "mostly_qualified": B},
        out=B, lean=f"{_NS}.urfGeneralCovers {{urfi_haqiqa}} {{only_qualified}} {{mostly_qualified}}",
        py=lambda f: not (f["urfi_haqiqa"] or f["only_qualified"] or f["mostly_qualified"])),
    "shar_specialises_general": dict(
        sadi=[], qawaid=[RAJAB.format(123)], facts={"shar_excludes": B},
        out=B, lean=f"{_NS}.sharGeneralCovers {{shar_excludes}}",
        py=lambda f: not f["shar_excludes"]),
    "unintended_instance_covered": dict(
        sadi=[], qawaid=[RAJAB.format(126)], facts={"rare_or_barred": B, "intended": B},
        out=B, lean=f"{_NS}.unintendedCovered {{rare_or_barred}} {{intended}}",
        py=lambda f: f["intended"] or not f["rare_or_barred"]),
}
