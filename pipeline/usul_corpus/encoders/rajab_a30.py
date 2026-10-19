"""Shard rajab-a30: the reading of Ibn Rajab's qāʿida 85, the five kinds of right (Usul.Readings.RajabA30)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA30"
_Q = [RAJAB.format(85)]

ENCODERS: dict[str, dict] = {
    "rajab_a30_tamalluk_awaits_choice": dict(
        sadi=[], qawaid=_Q, facts={"cause_concluded": B, "cause_completes_milk": B},
        out=B, lean=f"{_NS}.awaitsChoice {{cause_concluded}} {{cause_completes_milk}}",
        py=lambda f: f["cause_concluded"] and not f["cause_completes_milk"]),
    "rajab_a30_use_right_not_passed": dict(
        sadi=[], qawaid=_Q, facts={"use_right_only": B},
        out=B, lean=f"{_NS}.mayPassBenefit {{use_right_only}}",
        py=lambda f: not f["use_right_only"]),
    "rajab_a30_use_right_for_need": dict(
        sadi=[], qawaid=_Q, facts={"needed": B, "harmful": B},
        out=B, lean=f"{_NS}.useRightForNeed {{needed}} {{harmful}}",
        py=lambda f: f["needed"] and not f["harmful"]),
    "rajab_a30_ikhtisas_hand_stands": dict(
        sadi=[], qawaid=_Q, facts={"permitted_benefit": B, "may_become_mal": B},
        out=B, lean=f"{_NS}.handStands {{permitted_benefit}} {{may_become_mal}}",
        py=lambda f: f["permitted_benefit"] or f["may_become_mal"]),
    "rajab_a30_ikhtisas_first_comer": dict(
        sadi=[], qawaid=_Q, facts={"preceded": B, "left_by_choice": B},
        out=B, lean=f"{_NS}.firstComerAhaqq {{preceded}} {{left_by_choice}}",
        py=lambda f: f["preceded"] and not f["left_by_choice"]),
    "rajab_a30_tie_binds_whole": dict(
        sadi=[], qawaid=_Q, facts={"pledge_tie": B, "jinaya_tie": B},
        out=B, lean=f"{_NS}.wholeBound {{pledge_tie}} {{jinaya_tie}}",
        py=lambda f: f["pledge_tie"] or f["jinaya_tie"]),
    "rajab_a30_tie_for_recovery": dict(
        sadi=[], qawaid=_Q, facts={"tied": B},
        out=B, lean=f"{_NS}.recoverFrom {{tied}}",
        py=lambda f: f["tied"]),
    "rajab_a30_tied_right_precedes": dict(
        sadi=[], qawaid=_Q, facts={"tied": B, "rival_in_dhimma_only": B},
        out=B, lean=f"{_NS}.tiedPrecedes {{tied}} {{rival_in_dhimma_only}}",
        py=lambda f: f["tied"] and f["rival_in_dhimma_only"]),
}
