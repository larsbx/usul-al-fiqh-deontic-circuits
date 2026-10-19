"""Shard rajab-a27: readings of Ibn Rajab's qawāʿid 40 and 70 (Usul.Readings.RajabA27)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA27"

ENCODERS: dict[str, dict] = {
    "a27_ain_ruling_survives_owner_change": dict(
        sadi=[], qawaid=[RAJAB.format(40)],
        facts={"a27_tied_to_ain": B, "a27_holder_consented": B},
        out=B, lean=f"{_NS}.survivesOwnershipChange {{a27_tied_to_ain}} {{a27_holder_consented}}",
        py=lambda f: f["a27_tied_to_ain"] and not f["a27_holder_consented"]),
    "a27_specific_agent_in_general_object": dict(
        sadi=[], qawaid=[RAJAB.format(70)],
        facts={"a27_explicit_inclusion": B, "a27_qarina_inclusion": B},
        out=B, lean=f"{_NS}.agentIncluded {{a27_explicit_inclusion}} {{a27_qarina_inclusion}}",
        py=lambda f: f["a27_explicit_inclusion"] or f["a27_qarina_inclusion"]),
}
