"""Reconciliation: the bank's apparent contradictions run through its own taʿāruḍ procedure."""

import json
import re
from pathlib import Path

import jsonschema
import pytest

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
    case = next(c for c in CASES if c["far"].endswith("q052.f001"))
    entry = next(e for e in LEDGER["entries"] if e["far"] == case["far"])
    assert entry["grades"] == ["ashab", "wajh"]
    assert [v["grade"] for v in entry["evidence"]] == ["takhrij", "takhrij", "ashab"]
    assert reconcile.resolve(case, entry) == ("tarjih", True)
    assert not reconcile.marked_for_reading(case, entry)
    assert not case["matches_madhhab"]


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
            assert {k: v for k, v in row["original_annotation"].items() if k != "note"} == {
                k: v for k, v in c.items() if k != "note"}
        else:
            assert row["original_annotation"] == c


def test_locked_replay_rejects_missing_tampered_and_wrong_location(tmp_path):
    import hashlib
    wid = "test-source"
    text = "# لا إجمال في البيع\nPageV01P001\n"
    data = text.encode()
    witness = {"id": wid, "kind": "openiti", "repo": "test", "commit": "pin", "path": "source"}
    from usul_corpus.fetch import witness_url
    corpus, cache = tmp_path / "corpus", tmp_path / "cache"
    corpus.mkdir(); cache.mkdir()
    (corpus / "registry.json").write_text(json.dumps({"works": [{"witnesses": [witness]}]}))
    (corpus / "lock.json").write_text(json.dumps({"witnesses": {wid: {
        "url": witness_url(witness), "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}}}))
    item = {"ref": f"src:{wid}/v01:p001", "excerpt_ar": "لا إجمال في البيع"}
    ledger = {"entries": [{"evidence": [item]}]}
    assert reconcile.verify_evidence(ledger, corpus, cache) == [f"{wid}: locked witness not cached"]
    source = cache / f"{wid}.txt"
    source.write_bytes(data)
    assert reconcile.verify_evidence(ledger, corpus, cache) == []
    source.write_bytes(data + b" ")
    assert reconcile.verify_evidence(ledger, corpus, cache) == [f"{wid}: full source differs from lock"]
    source.write_bytes(data)
    item["ref"] = f"src:{wid}/v01:p002"
    assert reconcile.verify_evidence(ledger, corpus, cache) == [
        f"src:{wid}/v01:p002: excerpt or location differs from locked witness"]


def test_imported_evidence_adds_a_graded_holder():
    c = _ikh("x", True, [True, False])
    e = _entry("x", ["ashab", "ashab"])
    assert reconcile.standing(c, e) == "tawaqquf"
    insaf = {**e, "evidence": [{"position": 1, "grade": "tashih"}]}
    assert reconcile.resolve(c, insaf) == ("tarjih", False)
    bad = {**e, "evidence": [{"position": 2, "grade": "tashih"}]}
    assert reconcile.check([c], {"entries": [bad]}, DOSSIER) == ["x: evidence must name a listed position and a grade"]


EVIDENCE = [v for e in LEDGER["entries"] for v in e.get("evidence", [])]


def test_evidence_cites_registered_witnesses_within_their_limits():
    from usul_corpus.records import EXCERPT_LEN
    works = json.loads((ROOT / "corpus/registry.json").read_text())["works"]
    rights = {w["id"]: work["rights"] for work in works for w in work["witnesses"]}
    for v in EVIDENCE:
        w = v["ref"][4:].split("/")[0]
        assert w in rights and len(v["excerpt_ar"]) <= EXCERPT_LEN[rights[w]], v["ref"]


@pytest.mark.parametrize("v", EVIDENCE, ids=lambda v: v["ref"])
def test_evidence_is_verbatim(v):
    """Letters-only comparison against the cached witness; skipped where it is not cached (CI)."""
    from usul_corpus.arabic import locate
    w, loc = v["ref"][4:].split("/")
    src = ROOT / ".cache/corpus" / f"{w}.txt"
    if not src.exists():
        pytest.skip(f"{w} not cached")
    assert locate(src.read_text(encoding="utf-8"), v["excerpt_ar"]) == loc, v["ref"]


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
