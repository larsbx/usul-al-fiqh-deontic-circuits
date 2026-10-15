"""Shard rajab-a21: readings of Ibn Rajab's qawāʿid 147, 149, 150, 152 and 155 (Usul.Readings.RajabA21)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA21"

ENCODERS: dict[str, dict] = {
    "woman_half_of_man": dict(
        sadi=[], qawaid=[RAJAB.format(147)],
        facts={"woman_party": B, "listed_halving_point": B},
        out=B, lean=f"{_NS}.womanHalf {{woman_party}} {{listed_halving_point}}",
        py=lambda f: f["woman_party"] and f["listed_halving_point"]),
    "determinate_holder_right": dict(
        sadi=[], qawaid=[RAJAB.format(149)],
        facts={"right_holder_determinate": B},
        out=B, lean=f"{_NS}.determinateHolderRule {{right_holder_determinate}}",
        py=lambda f: f["right_holder_determinate"]),
    "transfer_follows_cause": dict(
        sadi=[], qawaid=[RAJAB.format(150)],
        facts={"transfer_given_for_cause": B, "independent_gift_cause": B},
        out=B, lean=f"{_NS}.causeGovernsTransfer {{transfer_given_for_cause}} {{independent_gift_cause}}",
        py=lambda f: f["transfer_given_for_cause"] and not f["independent_gift_cause"]),
    "four_kinds_marriage_prohibition": dict(
        sadi=[], qawaid=[RAJAB.format(152)],
        facts={"nasab_dabit": B, "sihr_class": B, "jam_rahm_mahram": B, "rada_counterpart": B},
        out=B, lean=f"{_NS}.marriageProhibited {{nasab_dabit}} {{sihr_class}} {{jam_rahm_mahram}} {{rada_counterpart}}",
        py=lambda f: f["nasab_dabit"] or f["sihr_class"] or f["jam_rahm_mahram"] or f["rada_counterpart"]),
    "mahr_fully_established": dict(
        sadi=[], qawaid=[RAJAB.format(155)],
        facts={"intercourse_occurred": B, "khalwa_occurred": B, "husband_capable_of_intercourse": B,
               "death_before_consummation": B},
        out=B, lean=(f"{_NS}.mahrEstablished {{intercourse_occurred}} {{khalwa_occurred}} "
                     "{husband_capable_of_intercourse} {death_before_consummation}"),
        py=lambda f: (f["intercourse_occurred"] or (f["khalwa_occurred"] and f["husband_capable_of_intercourse"])
                      or f["death_before_consummation"])),
}
