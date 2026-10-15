"""Reconciliation: the bank's apparent contradictions run through its own taʿāruḍ procedure."""

import functools
import json
import re
from pathlib import Path

import jsonschema
import pytest

from usul_corpus import reconcile, takhrij
from usul_corpus.__main__ import load_dossier

ROOT = Path(__file__).parents[2]
CASES = takhrij.load(ROOT / "corpus")
LEDGER = reconcile.load(ROOT / "corpus")
DOSSIER = load_dossier()  # shard entries included


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
        "x: a jamʿ must land on the prevailing side",
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


def test_author_preference_is_not_automatically_a_madhhab_tashih():
    for who in ("Ibn Rajab (al-aẓhar)", "one author: azhar", "al-Mughnī (al-ṣawāb)"):
        assert reconcile.draft_grade(who) == "ashab"


def test_non_ijmal_is_only_indirect_support_for_generality():
    case = next(c for c in CASES if c["far"].endswith("lahham_shamela8526.q052.f001"))
    entry = next(e for e in LEDGER["entries"] if e["far"] == case["far"])
    assert entry["grades"] == ["ashab", "wajh"]
    assert [v["grade"] for v in entry["evidence"]] == ["takhrij", "takhrij", "ashab"]
    assert reconcile.resolve(case, entry) == ("tarjih", True)
    assert not reconcile.marked_for_reading(case, entry)
    assert not case["matches_madhhab"]


def _sans_english(case: dict) -> dict:
    return {**{k: v for k, v in case.items() if k != "note"},
            "positions": [{k: v for k, v in p.items() if k != "who"} for p in case["positions"]]}


def test_review_audit_retains_originals_and_tracks_current_candidates():
    audit = json.loads((ROOT / "corpus/reconciliation/review-audit-2026-10-10.json").read_text())
    assert audit["cohort_size"] == len(audit["cases"]) == 48
    assert len({row["far"] for row in audit["cases"]}) == 48
    cases = {c["far"]: c for c in CASES}
    entries = {e["far"]: e for e in LEDGER["entries"]}
    locks = json.loads((ROOT / "corpus/lock.json").read_text())["witnesses"]
    for receipt in audit["source_receipts"]:
        assert all(receipt[k] == locks[receipt["witness"]][k] for k in ("url", "bytes", "sha256"))
    for row in audit["cases"]:
        c, e = cases[row["far"]], entries[row["far"]]
        assert row["scholarly_status"] == "open"
        assert row["grades"] == e["grades"]
        assert row["imported_evidence"] == e.get("evidence", [])
        assert row["current_resolution"] == list(reconcile.resolve(c, e))
        assert row["current_review_member"] == reconcile.marked_for_reading(c, e)
        if row["far"].endswith("q159.f035"):
            assert "a man of unknown lineage commits qadhf" in row["original_annotation"]["note"]
            assert "the accused person is enslaved" in c["note"]
        # Later English-only revisions (term guards) touch the note and a position's `who`;
        # everything the kernel reads is the audited original.
        assert _sans_english(row["original_annotation"]) == _sans_english(c)


def test_imported_evidence_adds_a_graded_holder():
    c = _ikh("x", True, [True, False])
    e = _entry("x", ["ashab", "ashab"])
    assert reconcile.standing(c, e) == "tawaqquf"
    insaf = {**e, "evidence": [{"position": 1, "grade": "tashih"}]}
    assert reconcile.resolve(c, insaf) == ("tarjih", False)
    bad = {**e, "evidence": [{"position": 2, "grade": "tashih"}]}
    assert reconcile.check([c], {"entries": [bad]}, DOSSIER) == ["x: evidence must name a listed position and a grade"]


# Grouped by witness: `arabic._indexed` caches only a few texts, so interleaving re-indexes each book.
EVIDENCE = sorted((v for e in LEDGER["entries"] for v in e.get("evidence", [])), key=lambda v: v["ref"].split("/")[0])


@functools.cache
def _witness(w: str) -> str | None:
    """One text object per witness, so the index cache hits on identity, not a full comparison."""
    src = ROOT / ".cache/corpus" / f"{w}.txt"
    return src.read_text(encoding="utf-8") if src.exists() else None


def test_evidence_cites_registered_witnesses_within_their_limits():
    from usul_corpus.records import EXCERPT_LEN
    works = json.loads((ROOT / "corpus/registry.json").read_text())["works"]
    rights = {w["id"]: work["rights"] for work in works for w in work["witnesses"]}
    for v in EVIDENCE:
        w = v["ref"][4:].split("/")[0]
        assert w in rights and len(v["excerpt_ar"]) <= EXCERPT_LEN[rights[w]], v["ref"]


@pytest.mark.parametrize("v", EVIDENCE, ids=lambda v: v["ref"])
def test_evidence_is_verbatim(v):
    """Required reconciliation evidence: a missing witness is a failure, including offline."""
    from usul_corpus.arabic import locate
    w, loc = v["ref"][4:].split("/")
    if (text := _witness(w)) is None:
        pytest.fail(f"required witness {w} not cached; run make source-verify-fetch")
    assert locate(text, v["excerpt_ar"]) == loc, v["ref"]


def test_named_companions_count_once_per_ruling():
    """Unmarked holders (one companion, a takhrīj, a wajh) do not weigh by number; marked ones do."""
    assert reconcile.support([("a", "ashab"), ("a", "ashab"), ("a", "ashab")], "a") == [2]
    assert reconcile.prevail([("a", "ashab"), ("a", "ashab"), ("b", "ashab")]) is None
    assert reconcile.prevail([("a", "nass"), ("a", "nass"), ("b", "nass")]) == "a"


def test_every_jam_lands_on_the_prevailing_side():
    jam = {"encoder": "successive_by_binding", "from": "successive_contracts", "farq": "r"}
    f = lambda e, l: {"successive": True, "earlier_binding": e, "later_binding": l}
    moved = _ikh("x", False, [True, False], True, "successive_by_binding", f(True, False))
    kept = _ikh("y", True, [True, False], False, "successive_by_binding", f(False, False))
    ledger = {"entries": [_entry("x", ["ashab", "zahir"], jam), _entry("y", ["ashab", "zahir"], jam)]}
    assert reconcile.check([moved, kept], ledger, DOSSIER) == ["y: a jamʿ must land on the prevailing side"]


def _side_fixture():
    case = {**_ikh("x", True, [True, False]), "side_check": {
        "from_matches": True, "refs": ["src:w/v01:p001"], "contradictions": [{
            "evidence_index": 0, "case_facts": {"successive": True},
            "rationale": "The later explicit ruling concerns this successive-contract case."}]}}
    ev = [{"ref": "src:w/v01:p001", "excerpt_ar": "source passage", "position": 1,
           "grade": "tashih", "who": "later work", "note": "case-specific"}]
    return case, {"entries": [{**_entry("x", ["ashab", "ashab"]), "evidence": ev}]}


def test_a_failed_side_check_enters_the_ledger_with_its_evidence():
    case, ledger = _side_fixture()
    assert reconcile.check([case], {"entries": []}, DOSSIER) == [
        "x: apparent contradiction not in the ledger", "x: a failed side check must enter the ledger"]
    assert reconcile.check([case], ledger, DOSSIER) == []
    assert reconcile.check([case], {"entries": [_entry("x", ["ashab", "ashab"])]}, DOSSIER) == [
        "x: a side check cites only the ledger's own evidence"]


@pytest.mark.parametrize("original", [False, None, 1, "true"])
def test_failed_side_check_requires_original_true(original):
    case, ledger = _side_fixture()
    case["side_check"]["from_matches"] = original
    assert any("true original annotation" in e for e in reconcile.check([case], ledger, DOSSIER))


@pytest.mark.parametrize("mutation", ["outside_ref", "wrong_case_facts", "agreeing", "identical_positions",
    "unmarked", "ambiguous", "full_ledger_tie", "missing_items", "bad_index", "duplicate_index",
    "unselected_ref", "missing_rationale", "current_true", "original_not_listed"])
def test_failed_side_check_rejects_adversarial_evidence(mutation):
    from copy import deepcopy
    case, ledger = _side_fixture()
    sc = case["side_check"]
    entry = ledger["entries"][0]
    if mutation == "outside_ref": sc["refs"] = ["src:other/v01:p001"]
    elif mutation == "wrong_case_facts": sc["contradictions"][0]["case_facts"] = {"successive": False}
    elif mutation == "agreeing": entry["evidence"][0]["position"] = 0
    elif mutation == "identical_positions": case["positions"][1]["ruling"] = True
    elif mutation == "unmarked": entry["evidence"][0]["grade"] = "ashab"
    elif mutation == "ambiguous":
        case["positions"].append({"who": "third", "ruling": "other"})
        entry["grades"].append("ashab")
        entry["evidence"].append({**entry["evidence"][0], "position": 2})
        sc["contradictions"].append({**sc["contradictions"][0], "evidence_index": 1})
    elif mutation == "full_ledger_tie": entry["evidence"].append({**entry["evidence"][0], "position": 0})
    elif mutation == "missing_items": sc["contradictions"] = []
    elif mutation == "bad_index": sc["contradictions"][0]["evidence_index"] = True
    elif mutation == "duplicate_index": sc["contradictions"].append(deepcopy(sc["contradictions"][0]))
    elif mutation == "unselected_ref":
        entry["evidence"].append({**entry["evidence"][0], "ref": "src:w/v01:p002"})
        sc["refs"].append("src:w/v01:p002")
    elif mutation == "missing_rationale": sc["contradictions"][0]["rationale"] = " "
    elif mutation == "current_true": case["matches_madhhab"] = True
    elif mutation == "original_not_listed": case["expected"] = "not a position"
    assert reconcile.check([case], ledger, DOSSIER), mutation


def test_same_page_opposing_evidence_requires_exact_item_selection():
    case, ledger = _side_fixture()
    entry = ledger["entries"][0]
    entry["evidence"].append({**entry["evidence"][0], "position": 0, "grade": "ashab"})
    assert reconcile.check([case], ledger, DOSSIER) == []
    case["side_check"]["contradictions"][0]["evidence_index"] = 1
    assert reconcile.check([case], ledger, DOSSIER)


def test_six_reviewed_disagreements_preserve_their_original_annotations():
    checked = [c for c in CASES if "side_check" in c]
    assert len(checked) == 6
    assert reconcile.check(CASES, LEDGER, DOSSIER) == []
    assert all(c["side_check"]["from_matches"] is True and c["matches_madhhab"] is False for c in checked)
    assert all(reconcile.standing(c, next(e for e in LEDGER["entries"] if e["far"] == c["far"])) == "against_reading" for c in checked)


def test_every_ikhtilaf_has_a_tarjih():
    """The owner's rule: an on-madhhab ikhtilāf is in the ledger too, and its tarjīḥ confirms the
    annotated side unless the entry cites an open research question."""
    c = _ikh("x", True, [True, False], matches=True)
    assert reconcile.check([c], {"entries": []}, DOSSIER) == ["x: an ikhtilāf without a tarjīḥ in the ledger"]
    assert reconcile.check([c], {"entries": [_entry("x", ["tashih", "ashab"])]}, DOSSIER) == []
    against = _entry("x", ["ashab", "nass"])
    assert reconcile.check([c], {"entries": [against]}, DOSSIER) == [
        "x: the tarjīḥ goes against the annotated madhhab side without an open research question"]
    assert reconcile.check([c], {"entries": [{**against, "register": "RQ-03"}]}, DOSSIER) == []
    assert reconcile.check([c], {"entries": [{**against, "register": "RQ-99"}]}, DOSSIER) == [
        "x: RQ-99 is not an open research question",
        "x: the tarjīḥ goes against the annotated madhhab side without an open research question"]


def test_only_undecided_questions_license(monkeypatch, tmp_path):
    """A withdrawn or decided question licenses nothing; a confirming count counts confirmations only."""
    (tmp_path / "corpus" / "review").mkdir(parents=True)
    (tmp_path / "corpus" / "review" / "research_questions.json").write_text(json.dumps({"questions": [
        {"id": f"RQ-0{i}", "status": s} for i, s in
        enumerate(["open-research", "ready-for-decision", "withdrawn", "decided"], 1)]}))
    monkeypatch.setattr(reconcile, "__file__", str(tmp_path / "pipeline" / "usul_corpus" / "reconcile.py"))
    assert reconcile._open_research_questions() == {"RQ-01", "RQ-02"}
    c = _ikh("x", True, [True, False], matches=True)
    against = {**_entry("x", ["ashab", "nass"]), "register": "RQ-01"}
    assert reconcile.report([c], {"entries": [against]})["confirming"] == 0


def test_the_ledger_holds_every_ikhtilaf():
    """Every ikhtilāf has a tarjīḥ: in the active ledger, or in the history a resolution retired it to."""
    entries = {e["far"] for e in LEDGER["entries"]} | set(reconcile._archived_tarjih())
    assert {c["far"] for c in CASES if c["class"] == "genuine_ikhtilaf"} <= entries


def test_a_position_is_one_attributed_view():
    """q160.f031: Ibn Rajab gives Abū Bakr's and Ibn Ḥāmid's wujūh under the mashhūr («على وجهين»).
    Al-Inṣāf and the muʿtamad pick the first against the second, so a tarjīḥ on the two glued
    together would credit a disjunction with what the evidence gave one disjunct."""
    far = "ibn_rajab.taqrir_qawaid.openiti_rajab_shamela21730.q160.f031"
    case = next(c for c in CASES if c["far"] == far)
    entry = next(e for e in LEDGER["entries"] if e["far"] == far)
    lost, puberty = (next(p for p in case["positions"] if name in p["who"]) for name in ("Abū Bakr", "Ibn Ḥāmid"))
    assert lost is not puberty
    assert reconcile.resolve(case, entry) == ("tarjih", lost["ruling"])
