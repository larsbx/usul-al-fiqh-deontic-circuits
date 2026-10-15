"""Shard rajab-a25: the reading of Ibn Rajab's qāʿida 158 (Usul.Readings.RajabA25)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA25"

ENCODERS: dict[str, dict] = {
    "two_usul_reinforced_governs": dict(
        sadi=[], qawaid=[RAJAB.format(158)],
        facts={"first_asl_reinforced": B, "second_asl_reinforced": B},
        out=B, lean=f"{_NS}.firstAslGoverns {{first_asl_reinforced}} {{second_asl_reinforced}}",
        py=lambda f: f["first_asl_reinforced"] or not f["second_asl_reinforced"]),
}
