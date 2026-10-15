"""Shard rajab-a11: readings of Ibn Rajab's qawāʿid 112–115 (Usul.Readings.RajabA11)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA11"

ENCODERS: dict[str, dict] = {
    "necessity_spares_lighter": dict(
        sadi=[], qawaid=[RAJAB.format(112)], facts={"heavier": B},
        out=B, lean=f"{_NS}.necessityPermits {{heavier}}",
        py=lambda f: not f["heavier"]),
    "distribution_each_over_whole": dict(
        sadi=[], qawaid=[RAJAB.format(113)], facts={"qarina_one_to_one": B},
        out=B, lean=f"{_NS}.eachOverWhole {{qarina_one_to_one}}",
        py=lambda f: not f["qarina_one_to_one"]),
    "unqualified_sharika_halves": dict(
        sadi=[], qawaid=[RAJAB.format(114)], facts={"is_iqrar": B},
        out=B, lean=f"{_NS}.sharikaHalves {{is_iqrar}}",
        py=lambda f: not f["is_iqrar"]),
    "shared_right_accrues_to_rest": dict(
        sadi=[], qawaid=[RAJAB.format(115)], facts={"each_entitled_whole": B},
        out=B, lean=f"{_NS}.accruesToRest {{each_entitled_whole}}",
        py=lambda f: f["each_entitled_whole"]),
}
