"""Integration: two readings of Ibn Rajab 3, 9, 14, 15 (formal/lean/Usul/Readings/Concordance.lean).

The readings of 3, 9 and 15 are proved equivalent there. For 14 the two contributions read two moves
of the text; their jamʿ is `cause_on_certainty`, conservative over `cause_from_one_of_two`
(`attachOnCertainty_conservative`): each man alone, certain of his own state and doubting only the
breach («متيقن للطهارة شاك في الحدث»), is bound to nothing harmless, as the madhhab rules
(al-Inṣāf, al-Furūʿ, Sharḥ al-Muntahā).
"""

from usul_corpus.takhrij import B, RAJAB

ENCODERS = {
    "cause_on_certainty": dict(
        sadi=[], qawaid=[RAJAB.format(14), RAJAB.format(15)],
        facts={"harmless": B, "each_certain": B},
        out=("neither", "each", "lot", "abstain"),
        lean="Usul.Readings.Concordance.attachOnCertainty {harmless} {each_certain}",
        py=lambda f: "neither" if f["harmless"] and f["each_certain"] else "each" if f["harmless"] else "abstain"),
}
