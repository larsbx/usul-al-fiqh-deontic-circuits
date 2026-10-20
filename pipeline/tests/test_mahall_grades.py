"""PR-51: al-Albānī's verdicts on the ḥadīth and athar anchors of the maḥall labels."""

from pathlib import Path

import pytest

from usul_corpus import grading, mahall, nusus
from witnesses import cached

ROOT = Path(__file__).resolve().parents[2]
CORPUS = ROOT / "corpus"
HADITH = [dict(n, label=l["id"]) for l in mahall.load(CORPUS)[1] for n in l.get("nass", [])
          if n["kind"] in ("sunnah", "athar")]
GRADED = [n for n in HADITH if "albani" in n]


def test_every_hadith_anchor_is_graded_or_says_why_not():
    assert all(sum(k in n for k in ("albani", "sahihayn", "ungraded")) == 1 for n in HADITH)


@pytest.mark.parametrize("n", GRADED, ids=lambda n: f"{n['label']}:{n['albani']['work']}:{n['albani']['number']}")
def test_the_verdict_is_al_albanis_on_an_entry_that_holds_the_excerpt(n):
    a = n["albani"]
    verdict, entry = nusus.albani_verdict(a["work"], cached(a["witness"]).read_text(encoding="utf-8"), a["number"])
    assert verdict == a["verdict"]
    assert nusus.key(n["excerpt_ar"]) in nusus.key(grading.head(a["work"], entry)), "not the ḥadīth the entry grades"


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


def test_the_sahihayn_standing_is_their_hadiths_short_or_not_and_never_an_athar():
    cache = Path("/nonexistent")       # neither case reaches al-Albānī's works
    short = {"kind": "sunnah", "ref": "src:openiti-bukhari-shamela1681", "excerpt_ar": "وفي الركاز الخمس"}
    assert grading.grade(short, cache) == {"sahihayn": True}
    assert "sahihayn" not in grading.grade({**short, "kind": "athar"}, cache)
    assert not any(n.get("sahihayn") for n in HADITH if n["kind"] == "athar")
