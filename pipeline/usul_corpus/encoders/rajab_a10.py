"""Shard rajab-a10: readings of Ibn Rajab's qawāʿid 109 and 111 (Usul.Readings.RajabA10)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA10"

ENCODERS: dict[str, dict] = {
    "vague_one_bars_all": dict(
        sadi=[], qawaid=[RAJAB.format(109)], facts={"confusion_effective": B, "distinguished": B},
        out=B, lean=f"{_NS}.vagueOneBarsAll {{confusion_effective}} {{distinguished}}",
        py=lambda f: f["confusion_effective"] and not f["distinguished"]),
    "combination_bars_its_amount": dict(
        sadi=[], qawaid=[RAJAB.format(109)], facts={"combining_amount": B},
        out=B, lean=f"{_NS}.combinationBarsItsAmount {{combining_amount}}",
        py=lambda f: f["combining_amount"]),
    "simultaneous_combination_voids": dict(
        sadi=[], qawaid=[RAJAB.format(109)], facts={"has_precedence": B},
        out=B, lean=f"{_NS}.simultaneousCombinationVoids {{has_precedence}}",
        py=lambda f: not f["has_precedence"]),
    "common_amount_general": dict(
        sadi=[], qawaid=[RAJAB.format(109)], facts={"bars_common_amount": B},
        out=B, lean=f"{_NS}.commonAmountGeneral {{bars_common_amount}}",
        py=lambda f: f["bars_common_amount"]),
    "alternative_proven_alone": dict(
        sadi=[], qawaid=[RAJAB.format(111)], facts={"proof_establishes_cause": B},
        out=B, lean=f"{_NS}.alternativeProvenAlone {{proof_establishes_cause}}",
        py=lambda f: f["proof_establishes_cause"]),
}
