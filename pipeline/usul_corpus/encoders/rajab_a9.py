"""Shard rajab-a9: readings of Ibn Rajab's qawāʿid 107, 108 and 110 (Usul.Readings.RajabA9)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA9"

ENCODERS: dict[str, dict] = {
    "maadum_grant_valid": dict(
        sadi=[], qawaid=[RAJAB.format(107)],
        facts={"by_origin": B, "explicit_inclusion": B, "object_entails": B},
        out=B, lean=f"{_NS}.maadumGrantValid {{by_origin}} {{explicit_inclusion}} {{object_entails}}",
        py=lambda f: not f["by_origin"] and (f["explicit_inclusion"] or f["object_entails"])),
    "unknown_order_judged_sequential": dict(
        sadi=[], qawaid=[RAJAB.format(108)],
        facts={"known_simultaneous": B, "known_sequential": B},
        out=B, lean=f"{_NS}.judgedSequential {{known_simultaneous}} {{known_sequential}}",
        py=lambda f: f["known_sequential"] or not f["known_simultaneous"]),
    "other_option_stands": dict(
        sadi=[], qawaid=[RAJAB.format(110)], facts={"chose_one": B},
        out=B, lean=f"{_NS}.otherOptionStands {{chose_one}}",
        py=lambda f: not f["chose_one"]),
    "refusal_exacted_for_him": dict(
        sadi=[], qawaid=[RAJAB.format(110)],
        facts={"harms_other": B, "financial": B, "established": B},
        out=B, lean=f"{_NS}.refusalExactedForHim {{harms_other}} {{financial}} {{established}}",
        py=lambda f: f["harms_other"] and f["financial"] and f["established"]),
    "refusal_right_falls": dict(
        sadi=[], qawaid=[RAJAB.format(110)], facts={"harms_other": B, "established": B},
        out=B, lean=f"{_NS}.refusalRightFalls {{harms_other}} {{established}}",
        py=lambda f: f["harms_other"] and not f["established"]),
    "refusal_compelled_to_choose": dict(
        sadi=[], qawaid=[RAJAB.format(110)],
        facts={"harms_other": B, "financial": B, "established": B},
        out=B, lean=f"{_NS}.refusalCompelledToChoose {{harms_other}} {{financial}} {{established}}",
        py=lambda f: f["harms_other"] and not f["financial"] and f["established"]),
    "right_on_refuser_exacted": dict(
        sadi=[], qawaid=[RAJAB.format(110)], facts={"right_on_him": B, "exactable": B},
        out=B, lean=f"{_NS}.rightOnRefuserExacted {{right_on_him}} {{exactable}}",
        py=lambda f: f["right_on_him"] and f["exactable"]),
    "substitute_refusal_judged_by_original": dict(
        sadi=[], qawaid=[RAJAB.format(110)], facts={"refused_substitute": B},
        out=B, lean=f"{_NS}.substituteRefusalJudgedByOriginal {{refused_substitute}}",
        py=lambda f: f["refused_substitute"]),
}
