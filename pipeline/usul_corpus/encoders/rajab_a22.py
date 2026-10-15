"""Shard rajab-a22: readings of Ibn Rajab's qawāʿid 151 and 154 (Usul.Readings.RajabA22)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA22"

ENCODERS: dict[str, dict] = {
    "dalalat_hal_carries_claim": dict(
        sadi=[], qawaid=[RAJAB.format(151)],
        facts={"hal_supports_claim": B, "hal_belies_claim": B},
        out=B, lean=f"{_NS}.halCarriesClaim {{hal_supports_claim}} {{hal_belies_claim}}",
        py=lambda f: f["hal_supports_claim"] and not f["hal_belies_claim"]),
    "bud_exit_charged": dict(
        sadi=[], qawaid=[RAJAB.format(154)],
        facts={"charged_unconsummated_mahr": B, "husband_elects_mahr": B, "wife_bears_exit": B},
        out=B, lean=f"{_NS}.budExitCharged {{charged_unconsummated_mahr}} {{husband_elects_mahr}} {{wife_bears_exit}}",
        py=lambda f: (f["charged_unconsummated_mahr"] or f["husband_elects_mahr"]) and not f["wife_bears_exit"]),
}
