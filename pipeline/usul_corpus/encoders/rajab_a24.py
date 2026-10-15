"""Shard rajab-a24: the reading of Ibn Rajab's qāʿida 156 (Usul.Readings.RajabA24)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA24"

ENCODERS: dict[str, dict] = {
    "mahr_halved_by_separation": dict(
        sadi=[], qawaid=[RAJAB.format(156)],
        facts={"sep_by_husband": B, "sep_by_stranger": B, "sep_by_wife": B,
               "husband_fasakh_for_her_harm": B},
        out=B,
        lean=(f"{_NS}.mahrHalved {{sep_by_husband}} {{sep_by_stranger}} {{sep_by_wife}} "
              "{husband_fasakh_for_her_harm}"),
        py=lambda f: (not f["husband_fasakh_for_her_harm"])
        and (f["sep_by_husband"] or f["sep_by_stranger"])),
}
