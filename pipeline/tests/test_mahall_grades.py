"""PR-51: al-Albānī's verdicts on the ḥadīth and athar anchors of the maḥall labels."""

from pathlib import Path

import pytest

from usul_corpus import grading, mahall, nusus
from witnesses import cached

ROOT = Path(__file__).resolve().parents[2]
CORPUS = ROOT / "corpus"
HADITH = [dict(n, label=l["id"]) for l in mahall.load(CORPUS)[1] for n in l.get("nass", [])
          if n["kind"] in ("sunnah", "athar")]


def test_every_hadith_anchor_is_graded_or_says_why_not():
    assert all(sum(k in n for k in ("albani", "sahihayn", "ungraded")) == 1 for n in HADITH)


CITED = [(n, c) for n in HADITH for c in ([n["albani"]] if "albani" in n else []) + n.get("weaker_routes", [])]


@pytest.mark.parametrize("n,c", CITED, ids=lambda x: f"{x['work']}:{x['number']}" if "work" in x else x["label"])
def test_each_cited_verdict_is_al_albanis_on_an_entry_that_holds_the_excerpt(n, c):
    verdict, entry = nusus.albani_verdict(c["work"], cached(c["witness"]).read_text(encoding="utf-8"), c["number"])
    assert c["witness"] == grading.WORKS[c["work"]] and verdict == c["verdict"]
    assert nusus.key(n["excerpt_ar"]) in nusus.key(grading.head(c["work"], entry)), "not the ḥadīth the entry grades"


def test_every_text_but_a_verse_cites_its_number_in_its_witness():
    """Sources are always cited: a ḥadīth or athar its ḥadīth number, an ijmāʿ the Mughnī's masʾala."""
    anchors = [n for l in mahall.load(CORPUS)[1] for n in l.get("nass", []) if n["kind"] != "quran"]
    assert all(n["number"] == nusus.locus(cached(mahall.REF.fullmatch(n["ref"])[1]).read_text(encoding="utf-8"),
                                          n["excerpt_ar"]) for n in anchors)


def test_grading_replays():
    """Regrading from the pinned works gives the committed grades."""
    for w in grading.WORKS.values():
        cached(w)
    cache = cached(grading.WORKS["albani.irwa"]).parent
    assert [grading.grade(n, cache) for n in HADITH] == \
        [{k: n[k] for k in ("albani", "weaker_routes", "sahihayn", "ungraded") if k in n} for n in HADITH]


def test_hujja_follows_the_grade():
    assert all(grading.hujja(n) == (n.get("albani", {}).get("verdict") in grading.HUJJA or bool(n.get("sahihayn")))
               for n in HADITH)


def _anchor(excerpt: str) -> dict:
    return next(n for n in HADITH if n["excerpt_ar"] == excerpt)


def test_the_sahihayn_standing_cites_their_hadith_short_or_not_and_never_an_athar():
    cache = cached("openiti-bukhari-shamela1681").parent
    short = {"kind": "sunnah", "ref": "src:openiti-bukhari-shamela1681", "excerpt_ar": "وفي الركاز الخمس"}
    short["number"] = nusus.locus(cached("openiti-bukhari-shamela1681").read_text(encoding="utf-8"), short["excerpt_ar"])
    assert grading.grade(short, cache) == {"sahihayn": {"witness": "openiti-bukhari-shamela1681", "number": short["number"]}}
    assert "sahihayn" not in grading.grade({**short, "kind": "athar"}, cache)
    assert not any(n.get("sahihayn") for n in HADITH if n["kind"] == "athar")


def test_a_weak_route_elsewhere_does_not_unseat_the_sahihayn():
    """al-Bukhārī's ḥadīth qudsī of the three adversaries is found by wording only in Ibn Māja's route,
    which al-Albānī grades weak: a verdict on that route, not on al-Bukhārī's."""
    n = _anchor("ورجل باع حرا فأكل ثمنه")
    assert n["sahihayn"]["witness"] == "openiti-bukhari-shamela1681" and grading.hujja(n)
    assert [(c["work"], c["verdict"]) for c in n["weaker_routes"]] == [("albani.sahih_daif_ibn_maja", "daif")]


def test_a_recurring_short_wording_is_graded_when_he_grades_every_recurrence_alike():
    assert {(n["albani"]["work"], n["albani"]["verdict"]) for n in HADITH if n["excerpt_ar"] == "الخراج بالضمان"} == \
        {("albani.sahih_daif_abi_dawud", "hasan"), ("albani.sahih_daif_tirmidhi", "hasan")}


MUKHTASAR = "\n".join([
    "#META#Header#End#",
    "# ٢١ - بابُ حُكْمِ الْمَفْقُودِ",
    "# ١١٩٣ - وَقَالَ ابْنُ الْمُسَيَّبِ: إِذَا فُقِدَ فِى الصَّفِّ عِنْدَ الْقِتَالِ تَرَبَّصُ امْرَأَتُهُ سَنَةً.",
    "# ١١٩٦ - وَقَالَ الزُّهْرِىُّ: فَإِذَا انْقَطَعَ خَبَرُهُ؛ فَسُنَّتُهُ",
    "# [هامش] ١١٩٣ - وصله عبد الرزاق بسند صحيح عنه.",
    "# [هامش] ١١٩٦ - وصله ابن أبي شيبة دون قوله: \"فإذا انقطع ... \" بأسانيد صحيحة عن عمر.",
    "PageV01P407",
    "# سُنَّةُ الْمَفْقُودِ.",
    "# ١١٩٣ - عن أبي هريرة: حديث مسند بالرقم نفسه في سلسلة أخرى.",
    "# ١١٥٤ - وَقَالَ عُقْبَةُ: لَا يَجُوزُ طَلَاقُ الْمُوَسْوِسِ.",
    "# [هامش] ١١٥٤ - ١١٥٦ - لم يخرجها الحافظ.",
    "PageV01P408", ""])


def test_the_mukhtasar_grades_an_athar_by_his_note_on_its_page():
    """An athar's entry is the one his note on that page is keyed to: the musnad series reuses numbers."""
    assert nusus.albani_verdict("albani.mukhtasar_bukhari", MUKHTASAR, 1193)[0] == "sahih"
    assert grading.heads("albani.mukhtasar_bukhari", MUKHTASAR) == [(1193, MUKHTASAR.find("# ١١٩٣")),
                                                                  (1196, MUKHTASAR.find("# ١١٩٦")),
                                                                  (1154, MUKHTASAR.find("# ١١٥٤"))]


def test_an_entry_runs_on_over_the_page_without_its_notes():
    _, entry = nusus.albani_verdict("albani.mukhtasar_bukhari", MUKHTASAR, 1196)
    assert nusus.key("فإذا انقطع خبره فسنته سنة المفقود") in nusus.key(entry) and "هامش" not in entry


def test_a_note_without_a_sanad_verdict_or_short_of_the_wording_grades_nothing():
    assert nusus.albani_verdict("albani.mukhtasar_bukhari", MUKHTASAR, 1196)[0] is None   # «دون قوله»
    assert nusus.albani_verdict("albani.mukhtasar_bukhari", MUKHTASAR, 1154)[0] is None   # «لم يخرجها»
