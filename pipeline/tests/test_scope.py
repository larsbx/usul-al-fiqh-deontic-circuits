"""PR-50: a qāʿida type's scope is the furūʿ its source text places under it, verbatim."""

import json
from pathlib import Path

from usul_corpus import scope, typed_routing as tr

ROOT = Path(__file__).resolve().parents[2]
CORPUS = ROOT / "corpus"
CATALOGUE = tr.catalogue(ROOT)


def test_sources_are_the_cited_segmented_qawaid():
    assert scope.sources("rajab87", "Ibn Rajab 87 «…»") == [("Ibn Rajab", 87)]
    assert scope.sources("rajab14_certainty", "") == [("Ibn Rajab", 14)]
    assert scope.sources("sadi32", "al-Saʿdī Q32 «…»; Ibn Rajab 75 «…»") == [("Ibn Rajab", 75)]
    assert scope.sources("zann_error", "Ibn Rajab Q6: …") == [("Ibn Rajab", 6)]
    assert scope.sources("lahham43", "Ibn al-Laḥḥām 43 «…»") == [("Ibn al-Laḥḥām", 43)]
    assert scope.sources("badal", "al-Saʿdī Q28 «…»") == []


def test_a_head_is_the_question_before_the_ruling():
    assert scope.head("إذا نذر صوم شهر يقدم فيه فلان فقدم في أول رمضان، هل يجزئه") \
        == "إذا نذر صوم شهر يقدم فيه فلان فقدم في أول رمضان"
    assert scope.head("لو سمع سجدتين معا فهل يسجد سجدتين") == "لو سمع سجدتين معا"
    assert len(scope.head(" ".join(["كلمة"] * 30)).split()) == scope.WORDS


def test_every_head_is_verbatim_from_a_farʿ_the_text_places_under_its_qaida():
    for (author, n), furu in scope.furu(CORPUS).items():
        w = scope.WITNESSES[author]
        recs = {r["id"]: r for r in map(json.loads, (CORPUS / "records" / f"{w}.jsonl").read_text(encoding="utf-8").splitlines())}
        for i, h in furu:
            assert recs[i]["qaida"].endswith(f".q{n:03d}")
            assert recs[i]["case_ar"].strip().startswith(h)


def test_the_catalogue_carries_scope_and_withholds_the_cases_under_evaluation():
    assert sum(bool(v["scope"]) for v in CATALOGUE.values()) >= 158
    (author, n), furu = next(iter(scope.furu(CORPUS).items()))
    name = f"rajab{n}" if author == "Ibn Rajab" else f"lahham{n}"
    whole = scope.scope(CORPUS, name, "")
    held = scope.scope(CORPUS, name, "", frozenset({furu[0][0]}))
    assert whole == [h for _, h in furu] and held == whole[1:]
