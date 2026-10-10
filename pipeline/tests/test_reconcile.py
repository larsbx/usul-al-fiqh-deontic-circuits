"""Reconciliation: the bank's apparent contradictions run through its own taʿāruḍ procedure."""

import json
import re
from pathlib import Path

import jsonschema

from usul_corpus import reconcile, takhrij

ROOT = Path(__file__).parents[2]
CASES = takhrij.load(ROOT / "corpus")
LEDGER = reconcile.load(ROOT / "corpus")
DOSSIER = json.loads((ROOT / "corpus/dossier/refinements.json").read_text())


def test_grade_order_mirrors_the_kernel():
    lean = (ROOT / "formal/lean/Usul/Reconcile.lean").read_text()
    assert {g: int(n) for g, n in re.findall(r"\.(\w+) => (\d+)", lean)} == reconcile.RANK
    assert reconcile.MARKED == {"tashih", "nass", "zahir", "qiyas", "jazm"}


def test_prevail_mirrors_the_kernel_guards():
    assert reconcile.prevail([("a", "nass"), ("b", "nass"), ("b", "tashih")]) == "b"
    assert reconcile.prevail([("a", "wajh"), ("b", "wajh")]) is None
    assert reconcile.prevail([("a", "nass"), ("a", "nass"), ("b", "nass")]) == "a"
    assert reconcile.prevail([("a", "zahir"), ("b", "jazm"), ("b", "jazm"), ("b", "ashab")]) == "a"
    assert reconcile.prevail([]) is None


def _ikh(far, expected, rulings, matches=False, encoder="successive_contracts", facts=None):
    return {"far": far, "encoder": encoder, "class": "genuine_ikhtilaf", "facts": facts or {"successive": True},
            "expected": expected, "matches_madhhab": matches, "note": "n",
            "positions": [{"who": str(i), "ruling": r} for i, r in enumerate(rulings)]}


def _entry(far, grades, jam=None):
    return {"far": far, "grades": grades, "jam": jam, "naskh": None}


def test_resolution_stages_and_standing():
    c = _ikh("x", True, [True, False])
    assert reconcile.resolve(c, _entry("x", ["ashab", "zahir"])) == ("tarjih", False)
    assert reconcile.standing(c, _entry("x", ["ashab", "zahir"])) == "against_reading"
    assert reconcile.standing(c, _entry("x", [["ashab", "takhrij"], "ashab"])) == "for_reading"
    assert reconcile.standing(c, _entry("x", ["wajh", "wajh"])) == "tawaqquf"
    naskh = {**_entry("x", ["nass", "nass"]), "naskh": {"ruling": False, "ref": "r", "note": "rujūʿ"}}
    assert reconcile.resolve(c, naskh) == ("naskh", False)


def test_check_demands_every_contradiction_and_a_grade_per_position():
    c = _ikh("x", True, [True, False])
    assert reconcile.check([c], {"entries": []}, DOSSIER) == ["x: apparent contradiction not in the ledger"]
    assert reconcile.check([c], {"entries": [_entry("x", ["ashab"])]}, DOSSIER) == [
        f"x: one grade per position, from {reconcile.GRADES}"]
    assert reconcile.check([c], {"entries": [_entry("x", ["ashab", "wajh"])]}, DOSSIER) == []


def test_jam_must_be_conservative_and_land_on_the_prevailing_side():
    jam = {"encoder": "successive_by_binding", "from": "successive_contracts", "farq": "r"}
    f = lambda e, l: {"successive": True, "earlier_binding": e, "later_binding": l}
    unbound = _ikh("x", False, [True, False], True, "successive_by_binding", f(True, False))
    assert reconcile.check([unbound], {"entries": [_entry("x", ["ashab", "zahir"], jam)]}, DOSSIER) == []
    # The flip lands on the weaker side: not a jamʿ.
    assert reconcile.check([unbound], {"entries": [_entry("x", ["zahir", "ashab"], jam)]}, DOSSIER) == [
        "x: the refinement departs from successive_contracts other than to the prevailing side"]
    # A derivable farʿ the refinement changes breaks conservativity.
    derivable = {**unbound, "far": "y", "class": "derivable"}
    assert "y: the refinement departs from successive_contracts other than to the prevailing side" in reconcile.check(
        [unbound, derivable], {"entries": [_entry("x", ["ashab", "zahir"], jam)]}, DOSSIER)
    # No refinement without a conservativity theorem in the dossier.
    other = {**jam, "encoder": "successive_contracts"}
    assert reconcile.check([_ikh("x", True, [True, False])], {"entries": [_entry("x", ["ashab", "zahir"], other)]}, DOSSIER) == [
        "x: jamʿ needs the case under a refinement with a conservativity theorem"]


def test_the_bank_reconciles_itself_and_stays_generated():
    jsonschema.validate(LEDGER, json.loads((ROOT / "schemas/reconciliation.schema.json").read_text()))
    assert reconcile.check(CASES, LEDGER, DOSSIER) == []
    assert (ROOT / "formal/lean/UsulTest/Reconcile.lean").read_text() == reconcile.lean_file(CASES, LEDGER)
    assert json.loads((ROOT / "corpus" / reconcile.REPORT).read_text()) == reconcile.report(CASES, LEDGER)


def test_draft_grades_from_the_annotation():
    assert [reconcile.draft_grade(w) for w in ("al-mashhūr", "riwāya: x", "ẓāhir kalām Aḥmad", "wajh: x", "al-Mughnī")] == [
        "tashih", "nass", "zahir", "wajh", "ashab"]
