"""Shard: Ibn Rajab qāʿida 127, the direct act and the cause (formal/lean/Usul/Readings/Mubashara.lean).

Closes the need `rule:mubashara_tasabbub` the IslamQA tranche recorded on its itlāf cases. A new
encoder beside `itlaf`, which is unchanged: Q127 answers on whom the ḍamān falls.
"""

from usul_corpus.takhrij import B, RAJAB

ENCODERS = {
    "mubashara_tasabbub": dict(
        sadi=[], qawaid=[RAJAB.format(127)],
        facts={"arising_from_sabab": B, "udwan_in_mubashara": B},
        out=("mubashir", "sabab", "shared"),
        lean="Usul.Readings.Mubashara.damanOn {arising_from_sabab} {udwan_in_mubashara}",
        py=lambda f: "mubashir" if not f["arising_from_sabab"] else "shared" if f["udwan_in_mubashara"] else "sabab"),
}
