"""PR-50: agreement of independent typings on the set of qawāʿid a case touches."""

from pathlib import Path

import pytest

from usul_corpus import agreement as ag

ROOT = Path(__file__).resolve().parents[2]
F = frozenset


def test_masi_ranks_equal_nested_overlapping_disjoint():
    assert ag.masi(F("a"), F("a")) == 0 and ag.masi(F(), F()) == 0
    assert ag.masi(F("a"), F("ab")) == pytest.approx(1 - 1 / 2 * 2 / 3)
    assert ag.masi(F("ab"), F("bc")) == pytest.approx(1 - 1 / 3 * 1 / 3)
    assert ag.masi(F("a"), F("b")) == 1


def test_alpha_is_one_on_agreement_and_below_zero_on_systematic_disagreement():
    assert ag.alpha([(F("a"), F("a")), (F("b"), F("b"))]) == 1
    assert ag.alpha([(F("a"), F("b")), (F("b"), F("a"))]) < 0


def test_alpha_without_variation_is_full_accord():
    assert ag.alpha([(F("a"), F("a")), (F("a"), F("a"))]) == 1
    assert ag.alpha([(F(), F()), (F(), F())]) == 1


def test_a_type_touches_the_qawaid_its_statement_cites():
    export = ("qaida_type(sadi32, 'al-Saʿdī Q32 «…»; Ibn Rajab 75 «…»').\n"
              "type_field(sadi32, returns, 'Option Bool').\nqaida_type(amana, '').\ntype_field(amana, held, 'Option Bool').\n")
    q = ag.Qawaid(export)
    assert q.touched([{"facts": {"returns": True}}, {"facts": {"held": False}}]) \
        == F({"al-Saʿdī 32", "Ibn Rajab 75", "amana"})


def test_the_reproduction_figures():
    r = ag.report(ROOT)
    assert {c: (v["identical"], v["disjoint"], v["alpha_masi"], v["own_found"]) for c, v in r.items()} == {
        "plain": (63, 8, 0.82, [65, 63]),
        "anchors": (62, 6, 0.827, [66, 62]),
        "scope": (65, 11, 0.826, [67, 66])}
