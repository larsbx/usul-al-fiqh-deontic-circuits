"""Reconciliation: the bank's disputed furūʿ run through its own taʿāruḍ procedure, weighed by proof."""

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


def _proof(position, tier):
    return {"position": position, "tier": tier, "dalil": "d", "ref": "src:w/v01:p001", "excerpt_ar": "نص", "note": "n"}


def _adv(winner, loser, by, basis="stated"):
    return {"for": winner, "over": loser, "by": by, "basis": basis, "ref": "src:w/v01:p001", "excerpt_ar": "نص",
            "note": "n"}


def test_attribution_is_a_record_and_decides_nothing():
    """A ruling stands by its proof: holders and labels alone leave the farʿ unweighed."""
    c = _ikh("x", True, [True, False])
    e = _entry("x", ["ashab", "tashih"])
    assert reconcile.resolve(c, e) == ("unweighed", None) and reconcile.standing(c, e) == "unweighed"
    assert reconcile.attribution(c, e) == ("tarjih", False)
    assert reconcile.attribution_standing(c, e) == "against_reading"
    # The madhhab's label against a report: the report decides.
    weighed = {**e, "proofs": [_proof(0, "zanni"), _proof(1, "qiyas")]}
    assert reconcile.resolve(c, weighed) == ("tarjih", True)


def test_resolution_by_proof_mirrors_the_kernel_guards():
    c = _ikh("x", True, [True, False])
    w = lambda ps, adv=(): {**_entry("x", ["ashab", "ashab"]), "proofs": list(ps), "advantages": list(adv)}
    assert reconcile.resolve(c, w([_proof(0, "zanni"), _proof(1, "qiyas")], [_adv(1, 0, "muaththira")])) == ("tarjih", True)
    assert reconcile.resolve(c, w([_proof(0, "zanni"), _proof(1, "zanni")], [_adv(0, 1, "muttasil")])) == ("tarjih", True)
    assert reconcile.resolve(c, w([_proof(0, "zanni"), _proof(1, "zanni")],
                                  [_adv(0, 1, "muttasil"), _adv(1, 0, "muthbit")])) == ("tawaqquf", None)
    assert reconcile.resolve(c, w([_proof(0, "zanni"), _proof(1, "zanni")], [_adv(0, 1, "khiffa")])) == ("tawaqquf", None)
    assert reconcile.resolve(c, w([_proof(1, "istishab")])) == ("tarjih", False)
    assert reconcile.resolve(c, w([])) == ("tawaqquf", None)
    assert reconcile.standing(c, w([_proof(1, "qati"), _proof(0, "zanni")])) == "against_reading"
    naskh = {**_entry("x", ["nass", "nass"]), "naskh": {"ruling": False, "ref": "r", "note": "rujūʿ"}}
    assert reconcile.resolve(c, naskh) == ("naskh", False)


def test_tiers_and_murajjihat_mirror_the_kernel():
    lean = (ROOT / "formal/lean/Usul/Tarjih.lean").read_text()
    rank = lean[lean.index("def Tier.rank"):lean.index("/-- The kind of dalīl")]
    assert {t: int(n) for t, n in re.findall(r"\.(\w+) => (\d+)", rank)} == reconcile.TIER_RANK
    block = lean[lean.index("inductive Murajjih"):lean.index("deriving", lean.index("inductive Murajjih"))]
    names = [n for line in block.split("where", 1)[1].splitlines() if not line.strip().startswith("--")
             for n in re.findall(r"\| (\w+)", line)]
    assert tuple(names) == reconcile.MURAJJIH
    std = lean[lean.index("def Murajjih.standing"):lean.index("/-- Where an advantage comes from")]
    for line in std.splitlines():
        if "=>" in line and "_ =>" not in line:
            names, st = line.split("=>")
            assert {m: reconcile.STANDING[m] for m in re.findall(r"\.(\w+)", names)} == dict.fromkeys(
                re.findall(r"\.(\w+)", names), st.strip().lstrip("."))
    for pol in ("strict", "sources"):
        line = lean[lean.index(f"def {pol} : Policy"):].split("\n")[0]
        assert ({st for st in ("asserted", "disputed", "weak", "rejected") if f"| .{st}" in line},
                line.rstrip("⟩").rsplit(", ", 1)[1] == "true") == (set(reconcile.POLICIES[pol][0]), reconcile.POLICIES[pol][1])
    assert "def applying : Policy := ⟨sources.standing, true⟩" in lean and reconcile.POLICIES["applying"] == (
        reconcile.POLICIES["sources"][0], True)
    assert "def all : Policy := ⟨fun _ => true, true⟩" in lean


def test_weak_and_rejected_advantages_are_formalised_and_run_under_their_policy():
    """Nothing is dropped: every murajjiḥ has its standing, and each policy is run and reported."""
    c = _ikh("x", True, [True, False])
    e = {**_entry("x", ["ashab", "ashab"]), "proofs": [_proof(0, "zanni"), _proof(1, "zanni")]}
    weak, disputed = {**e, "advantages": [_adv(0, 1, "khiffa")]}, {**e, "advantages": [_adv(0, 1, "qawl")]}
    assert [reconcile.resolve(c, weak, p) for p in ("strict", "sources", "all")] == [
        ("tawaqquf", None), ("tawaqquf", None), ("tarjih", True)]
    assert [reconcile.resolve(c, disputed, p) for p in ("strict", "sources", "all")] == [
        ("tawaqquf", None), ("tarjih", True), ("tarjih", True)]
    assert reconcile.report([c], {"entries": [weak]})["policies"]["all"]["differs_from_default"] == ["x"]
    assert set(reconcile.STANDING) == set(reconcile.MURAJJIH)


def test_applied_advantages_are_kept_and_count_only_under_their_policy():
    """An advantage the bank applies, which no source states, is recorded and run, but does not decide by default."""
    c = _ikh("x", True, [True, False])
    e = {**_entry("x", ["ashab", "ashab"]), "proofs": [_proof(0, "zanni"), _proof(1, "zanni")],
         "advantages": [_adv(0, 1, "khass", "applied")]}
    assert [reconcile.resolve(c, e, p) for p in ("strict", "sources", "applying", "all")] == [
        ("tawaqquf", None), ("tawaqquf", None), ("tarjih", True), ("tarjih", True)]
    assert reconcile.check([c], {"entries": [{**e, "advantages": [{**_adv(0, 1, "khass"), "basis": "guessed"}]}]}, DOSSIER) == [
        "x: an advantage names two listed positions, a murajjiḥ, its basis, a ref and its excerpt"]


def test_proofs_name_positions_tiers_and_their_source():
    c = _ikh("x", True, [True, False])
    e = _entry("x", ["ashab", "ashab"])
    assert reconcile.check([c], {"entries": [{**e, "proofs": [_proof(0, "zanni")]}]}, DOSSIER) == []
    assert reconcile.check([c], {"entries": [{**e, "proofs": [_proof(2, "zanni")]}]}, DOSSIER) == [
        f"x: a proof names a listed position, a tier from {reconcile.TIERS}, a ref and its excerpt"]
    assert reconcile.check([c], {"entries": [{**e, "proofs": [_proof(0, "tashih")]}]}, DOSSIER) == [
        f"x: a proof names a listed position, a tier from {reconcile.TIERS}, a ref and its excerpt"]
    assert reconcile.check([c], {"entries": [{**e, "proofs": [_proof(0, "zanni")], "advantages": [_adv(0, 0, "muthbit")]}]}, DOSSIER) == [
        "x: an advantage names two listed positions, a murajjiḥ, its basis, a ref and its excerpt"]
    assert reconcile.check([c], {"entries": [{**e, "advantages": [_adv(0, 1, "muthbit")]}]}, DOSSIER) == [
        "x: advantages weigh proofs; record the proofs"]
    assert reconcile.check([c], {"entries": [{**e, "proofs": []}]}, DOSSIER) == [
        "x: weighed with no proof: say where the proofs were searched for"]
    assert reconcile.check([c], {"entries": [{**e, "proofs": [], "searched": "al-Mughnī v05:p100"}]}, DOSSIER) == []


def test_check_demands_every_contradiction_and_a_grade_per_position():
    c = _ikh("x", True, [True, False])
    assert reconcile.check([c], {"entries": []}, DOSSIER) == ["x: an ikhtilāf not in the ledger"]
    assert reconcile.check([c], {"entries": [_entry("x", ["ashab"])]}, DOSSIER) == [
        f"x: one grade per position, from {reconcile.GRADES}"]
    assert reconcile.check([c], {"entries": [_entry("x", ["ashab", "wajh"])]}, DOSSIER) == []


def test_jam_must_be_conservative_and_land_on_the_side_the_proofs_favour():
    jam = {"encoder": "successive_by_binding", "from": "successive_contracts", "farq": "r"}
    f = lambda e, l: {"successive": True, "earlier_binding": e, "later_binding": l}
    unbound = _ikh("x", False, [True, False], True, "successive_by_binding", f(True, False))
    weighed = lambda lo, hi: {**_entry("x", ["ashab", "ashab"], jam), "proofs": [_proof(0, lo), _proof(1, hi)]}
    assert reconcile.check([unbound], {"entries": [weighed("qiyas", "zanni")]}, DOSSIER) == []
    # The flip lands on the weaker proof: not a jamʿ.
    assert reconcile.check([unbound], {"entries": [weighed("zanni", "qiyas")]}, DOSSIER) == [
        "x: a jamʿ must not land against the side the proofs favour",
        "x: the refinement departs from successive_contracts against the side the proofs favour"]
    # Unweighed, the move is pending, not resolved by the labels.
    ledger = {"entries": [_entry("x", ["zahir", "ashab"], jam)]}
    assert reconcile.check([unbound], ledger, DOSSIER) == []
    assert reconcile.jam_pending([unbound], ledger) == ["x"]
    # A derivable farʿ the refinement changes breaks conservativity.
    derivable = {**unbound, "far": "y", "class": "derivable"}
    # Proofs that leave it open (tawaqquf) do not refute the jamʿ.
    assert reconcile.check([unbound], {"entries": [weighed("qiyas", "qiyas")]}, DOSSIER) == []
    assert "y: the refinement departs from successive_contracts against the side the proofs favour" in reconcile.check(
        [unbound, derivable], {"entries": [weighed("qiyas", "zanni")]}, DOSSIER)
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
    assert reconcile.attribution(case, entry) == ("tarjih", True)
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
        assert row["current_resolution"] == list(reconcile.attribution(c, e))  # graded by attribution then
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
    assert reconcile.attribution_standing(c, e) == "tawaqquf"
    insaf = {**e, "evidence": [{"position": 1, "grade": "tashih"}]}
    assert reconcile.attribution(c, insaf) == ("tarjih", False)
    assert reconcile.resolve(c, insaf) == ("unweighed", None)
    bad = {**e, "evidence": [{"position": 2, "grade": "tashih"}]}
    assert reconcile.check([c], {"entries": [bad]}, DOSSIER) == ["x: evidence must name a listed position and a grade"]


def _bank(q: str) -> tuple[dict, dict]:
    """A deep copy of the bank's case and ledger entry for question/farʿ `q` (e.g. "q121.f005")."""
    from copy import deepcopy
    e = next(e for e in LEDGER["entries"] if e["far"].endswith(q))
    return next(c for c in CASES if c["far"] == e["far"]), deepcopy(e)


def _ev(ref="src:w/v01:p001", position=1, grade="tashih"):
    return {"ref": ref, "excerpt_ar": "x" * 20, "position": position, "grade": grade, "who": "w", "note": "n"}


DUPLICATE = "x: evidence cites one page once per position"


def test_evidence_counts_each_page_once_per_position():
    c = _ikh("x", True, [True, False])
    e = _entry("x", ["ashab", "ashab"])
    assert reconcile.check([c], {"entries": [{**e, "evidence": [_ev(), _ev(position=0)]}]}, DOSSIER) == []
    for dup in ([_ev(), _ev()], [_ev(), {**_ev(), "who": "other", "note": "reworded"}], [_ev(), _ev(grade="jazm")]):
        assert reconcile.check([c], {"entries": [{**e, "evidence": dup}]}, DOSSIER) == [DUPLICATE]


@pytest.mark.parametrize("q", ["q121.f005", "q160.f014"])
def test_a_copied_evidence_item_cannot_manufacture_a_preference(q):
    """Audit mutation: copying one item turned q121.f005's tawaqquf into tarjīḥ and reversed q160.f014 (now the
    attribution record, which `report.json` and the Lean guards still carry)."""
    from copy import deepcopy
    schema = json.loads((ROOT / "schemas/reconciliation.schema.json").read_text())
    c, e = _bank(q)
    for v in e["evidence"]:
        dup = {**e, "evidence": [*e["evidence"], deepcopy(v)]}
        assert any("one page once per position" in m for m in reconcile.check([c], {"entries": [dup]}, DOSSIER))
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate({**LEDGER, "entries": [dup]}, schema)


def _naskh(ruling=False, ref="src:w/v01:p001"):
    return {"ruling": ruling, "ref": ref, "note": "a later riwāya"}


def test_naskh_names_a_reported_ruling_with_its_chronology_witness():
    c = _ikh("x", True, [True, False])
    e = {**_entry("x", ["ashab", "ashab"]), "evidence": [_ev()]}
    assert reconcile.check([c], {"entries": [{**e, "naskh": _naskh()}]}, DOSSIER) == []
    bad = {"outside_domain": _naskh(ruling="OUTSIDE_ENCODER_DOMAIN"),
           "unlinked_ref": _naskh(ref="src:w/v01:p002"),
           "not_a_source": _naskh(ref="not-a-source"),
           "witness_for_other_side": _naskh(ruling=True)}
    for k, n in bad.items():
        assert reconcile.check([c], {"entries": [{**e, "naskh": n}]}, DOSSIER) == [
            "x: naskh needs a reported ruling and a cited evidence item attesting it"], k


def test_the_audited_naskh_mutation_is_rejected():
    """Audit mutation on q100.f003: an out-of-domain ruling and a non-source reference passed both validators."""
    schema = json.loads((ROOT / "schemas/reconciliation.schema.json").read_text())
    c, e = _bank("q100.f003")
    assert reconcile.check([c], {"entries": [e]}, DOSSIER) == []
    e["naskh"] = {**e["naskh"], "ruling": "OUTSIDE_ENCODER_DOMAIN", "ref": "not-a-source"}
    assert reconcile.check([c], {"entries": [e]}, DOSSIER) == [
        f"{c['far']}: naskh needs a reported ruling and a cited evidence item attesting it"]
    with pytest.raises(jsonschema.ValidationError):
        jsonschema.validate({**LEDGER, "entries": [e]}, schema)


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
        "x: an ikhtilāf not in the ledger", "x: a failed side check must enter the ledger"]
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
    assert all(reconcile.attribution_standing(c, next(e for e in LEDGER["entries"] if e["far"] == c["far"])) == "against_reading"
               for c in checked)


def test_every_ikhtilaf_has_an_entry_and_labels_are_no_target():
    """Every ikhtilāf is in the ledger; an on-madhhab annotation is a description, so a weighing
    against it is no error, and a cited register must be an open question."""
    c = _ikh("x", True, [True, False], matches=True)
    assert reconcile.check([c], {"entries": []}, DOSSIER) == ["x: an ikhtilāf not in the ledger"]
    against = {**_entry("x", ["tashih", "ashab"]), "proofs": [_proof(1, "zanni")]}
    assert reconcile.resolve(c, against) == ("tarjih", False)
    assert reconcile.check([c], {"entries": [against]}, DOSSIER) == []
    assert reconcile.check([c], {"entries": [{**against, "register": "RQ-99"}]}, DOSSIER) == [
        "x: RQ-99 is not an open research question"]


def test_only_undecided_questions_license(monkeypatch, tmp_path):
    """A withdrawn or decided question licenses nothing."""
    (tmp_path / "corpus" / "review").mkdir(parents=True)
    (tmp_path / "corpus" / "review" / "research_questions.json").write_text(json.dumps({"questions": [
        {"id": f"RQ-0{i}", "status": s} for i, s in
        enumerate(["open-research", "ready-for-decision", "withdrawn", "decided"], 1)]}))
    monkeypatch.setattr(reconcile, "__file__", str(tmp_path / "pipeline" / "usul_corpus" / "reconcile.py"))
    assert reconcile._open_research_questions() == {"RQ-01", "RQ-02"}


def test_the_ledger_holds_every_ikhtilaf():
    """Every ikhtilāf has an entry: in the active ledger, or in the history a resolution retired it to."""
    entries = {e["far"] for e in LEDGER["entries"]} | set(reconcile._archived())
    assert {c["far"] for c in CASES if c["class"] == "genuine_ikhtilaf"} <= entries


def test_report_keeps_attribution_apart_from_the_weighing():
    rep = reconcile.report(CASES, LEDGER)
    assert sum(rep["stages"].values()) == rep["entries"] == sum(rep["standing"].values())
    assert rep["stages"].get("unweighed", 0) == sum(rep["weighing_worklist"].values())
    assert "tarjih" not in rep["attribution"] or rep["attribution"]["note"].endswith("not a tarjīḥ")


PROOFS = sorted((x for e in LEDGER["entries"] for x in e.get("proofs", []) + e.get("advantages", [])),
                key=lambda x: x["ref"].split("/")[0])


@pytest.mark.parametrize("x", PROOFS, ids=lambda x: x["ref"])
def test_proofs_are_verbatim(x):
    from usul_corpus.arabic import locate
    w, loc = x["ref"][4:].split("/")
    if (text := _witness(w)) is None:
        pytest.fail(f"required witness {w} not cached; run make source-verify-fetch")
    assert locate(text, x["excerpt_ar"]) == loc, x["ref"]


def test_a_position_is_one_attributed_view():
    """q160.f031: Ibn Rajab gives Abū Bakr's and Ibn Ḥāmid's wujūh under the mashhūr («على وجهين»).
    Al-Inṣāf and the muʿtamad pick the first against the second, so a tarjīḥ on the two glued
    together would credit a disjunction with what the evidence gave one disjunct. Each proof, too,
    weighs for the wajh it is given for (ʿUmar's «وال أيهما شئت» for the choosing one)."""
    far = "ibn_rajab.taqrir_qawaid.openiti_rajab_shamela21730.q160.f031"
    case = next(c for c in CASES if c["far"] == far)
    entry = next(e for e in LEDGER["entries"] if e["far"] == far)
    ps = case["positions"]
    lost, puberty = (next(k for k, p in enumerate(ps) if name in p["who"]) for name in ("Abū Bakr", "Ibn Ḥāmid"))
    assert lost != puberty
    assert reconcile.attribution(case, entry) == ("tarjih", ps[lost]["ruling"])
    assert [x["position"] for x in entry["proofs"] if "وال أيهما شئت" in x["excerpt_ar"]] == [puberty]
