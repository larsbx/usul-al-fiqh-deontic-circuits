"""Source contrasts, candidate governance and provenance for M5 command capabilities."""

import copy
import json
from itertools import product
from pathlib import Path

import pytest

from usul_corpus import m5_commands as m5, takhrij
from usul_corpus import __main__ as cli

ROOT = Path(__file__).parents[2]
CORPUS = ROOT / "corpus"


def _plan():
    return json.loads((CORPUS / m5.PLAN).read_text())


def _source():
    path = cli.CACHE / f"{m5.WITNESS}.txt"
    if not path.exists():
        pytest.skip("full locked Ibn al-Lahham witness is not cached; CI restores it")
    return path.read_bytes()


def test_candidate_receipts_preserve_the_four_live_gaps():
    plan = _plan()
    m5.validate(plan, CORPUS)
    assert plan["status"] == "candidate"
    assert all(q["status"] == "open" for q in plan["review_questions"])
    assert all(r["gap_status"] == "open" for r in plan["case_receipts"])
    cases = {c["far"]: c for c in takhrij.load(CORPUS)}
    for r in plan["case_receipts"]:
        assert r["original_case"] == cases[r["far"]]
        assert cases[r["far"]]["class"] == "missing_rule"
        assert not set(cases[r["far"]]["needs"]) <= takhrij.provides()


def test_all_six_gaps_and_aggregate_are_unchanged():
    cases = takhrij.load(CORPUS)
    report = takhrij.report(cases)
    expected_gaps = m5.FARS | {
        takhrij.LAHHAM.format(52) + ".f007", takhrij.RAJAB.format(22) + ".f000",
    }
    assert {c["far"] for c in cases if c["class"] in takhrij.GAPS} == expected_gaps
    assert (report["total"], report["coverage"], report["madhhab_coverage"],
            report["classes"].get("encoding_error", 0)) == (303, 0.980, 0.659, 0)
    assert json.loads((CORPUS / "takhrij/report.json").read_text()) == report


def test_source_distinguishes_writing_from_gesture_and_naming_from_ruling():
    fixtures = {f["id"]: f for f in _plan()["fixtures"]}
    controls = {
        "001-qadiReported-writing": "notLiteral", "001-qadiReported-gesture": "notLiteral",
        "001-jamiWriting-writing": "literal", "001-jamiWriting-gesture": "unsettled",
        "003-authorConditional-false": "unsettled", "003-authorConditional-true": "literal",
        "007-qadiReport-permission": "literal", "007-qadiArgument-permission": "figurative",
        "007-karkhiRazi-permission": "unsettled", "007-abuBarakat-recommendation": "unsettled",
    }
    for suffix, expected in controls.items():
        f = fixtures["M5-CMD-" + suffix]
        assert f["expected"] == expected
        assert takhrij.ENCODERS[f["encoder"]]["py"](f["facts"]) == expected
    # Classification of command usage is not a five-fold act ruling.
    assert set(takhrij.ENCODERS["command_intended_usage"]["out"]).isdisjoint(takhrij.HUKM)


def test_bare_commands_preserve_the_old_default_and_nass_is_reading_specific():
    new = takhrij.ENCODERS["command_obligation_status"]["py"]
    old = takhrij.ENCODERS["amr"]["py"]
    for reading, qarina in product(("qadi", "abuBarakat"), ("none",) + takhrij.HUKM):
        assert new(dict(reading=reading, expression="bareCommand", qarina=qarina)) == old(dict(qarina=qarina))
    for expression, qarina in product(("unqualifiedThreat", "wujubLabel", "fardLabel"), takhrij.HUKM):
        assert new(dict(reading="qadi", expression=expression, qarina=qarina)) == qarina
        assert new(dict(reading="abuBarakat", expression=expression, qarina=qarina)) == "wajib"


def test_generated_mirror_exhausts_all_66_new_domain_combinations_and_checks_the_plan():
    mirror = takhrij.mirror_file()
    assert (ROOT / "formal/lean/UsulTest/TakhrijMirror.lean").read_text() == mirror
    new_guards = [line for line in mirror.splitlines() if line.startswith("#guard (Usul.CommandSchemata.")]
    assert len(new_guards) == 66
    checked = (ROOT / "formal/lean/UsulTest/SignatureMap.lean").read_text()
    for selection in _plan()["selection"]:
        assert all(f"#check @{name}\n" in checked for name in selection["reading"])


@pytest.mark.parametrize("mutation,message", [
    ("status", "candidate plan"), ("scope", "scope changed"),
    ("witness", "wrong source witness"), ("source_hash", "source lock"),
    ("records_hash", "source record receipt"), ("case_hash", "original case hash"),
    ("rewrite_case", "live case changed"), ("promote_gap", "gap was promoted"),
    ("drop_receipt", "case receipt set"), ("duplicate_receipt", "case receipt set"),
    ("locator", "record locator"), ("case_excerpt", "case excerpt"),
    ("encoder", "wrong capability encoder"), ("question_status", "human review"),
    ("question_link", "review link has another case"), ("reading_status", "reading status"),
    ("duplicate_fixture", "duplicate fixture"), ("fixture_encoder", "another case's encoder"),
    ("extra_fact", "fixture fact keys"), ("boolean_as_integer", "typed domain"),
    ("unknown_reading", "typed domain"), ("gesture_literal", "contradicts the candidate"),
    ("missing_evidence", "lacks source evidence"), ("evidence_hash", "evidence hash"),
])
def test_receipt_validation_rejects_unrecorded_changes_and_premature_promotion(mutation, message):
    plan = _plan()
    receipt = plan["case_receipts"][0]
    fixture = plan["fixtures"][0]
    if mutation == "status":
        plan["status"] = "accepted"
    elif mutation == "scope":
        plan["scope"] = "four gaps closed"
    elif mutation == "witness":
        plan["source"]["witness"] = "another-witness"
    elif mutation == "source_hash":
        plan["source"]["sha256"] = "0" * 64
    elif mutation == "records_hash":
        plan["records_sha256"] = "0" * 64
    elif mutation == "case_hash":
        receipt["original_case_sha256"] = "0" * 64
    elif mutation == "rewrite_case":
        receipt["original_case"]["note"] = "a silently replaced interpretation"
        receipt["original_case_sha256"] = m5.case_sha256(receipt["original_case"])
    elif mutation == "promote_gap":
        receipt["gap_status"] = "closed"
    elif mutation == "drop_receipt":
        plan["case_receipts"].pop()
    elif mutation == "duplicate_receipt":
        plan["case_receipts"][-1] = copy.deepcopy(receipt)
    elif mutation == "locator":
        receipt["record_locator"] = "src:another-location"
    elif mutation == "case_excerpt":
        receipt["case_ar_sha256"] = "0" * 64
    elif mutation == "encoder":
        receipt["capability_encoder"] = "command_intended_usage"
    elif mutation == "question_status":
        plan["review_questions"][0]["status"] = "accepted"
    elif mutation == "question_link":
        receipt["review_questions"] = [plan["review_questions"][1]["id"]]
    elif mutation == "reading_status":
        plan["selection"][0]["status"] = "accepted"
    elif mutation == "duplicate_fixture":
        plan["fixtures"].append(copy.deepcopy(fixture))
    elif mutation == "fixture_encoder":
        fixture["encoder"] = "amr"
    elif mutation == "extra_fact":
        fixture["facts"]["accepted"] = True
    elif mutation == "boolean_as_integer":
        next(f for f in plan["fixtures"] if f["encoder"] == "command_prophetic_act_usage")["facts"]["imitation_established"] = 0
    elif mutation == "unknown_reading":
        fixture["facts"]["reading"] = "adopted"
    elif mutation == "gesture_literal":
        next(f for f in plan["fixtures"] if f["id"] == "M5-CMD-001-jamiWriting-gesture")["expected"] = "literal"
    elif mutation == "missing_evidence":
        fixture["source_evidence"] = []
    else:
        fixture["source_evidence"][0]["excerpt_sha256"] = "0" * 64
    with pytest.raises(ValueError, match=message):
        m5.validate(plan, CORPUS)


def test_full_source_replays_all_evidence_with_closing_page_markers():
    plan = _plan()
    m5.validate_source(plan, _source())
    refs = {e["ref"] for f in plan["fixtures"] for e in f["source_evidence"]}
    assert f"src:{m5.WITNESS}/v01:p224" in refs
    assert f"src:{m5.WITNESS}/v01:p227" in refs
    # The immutable case locators carry the parent's opening page. Full evidence
    # supplies the actual later pages instead of rewriting historical records.
    assert all("/v01:p221#q043." in r["record_locator"] for r in plan["case_receipts"])


@pytest.mark.parametrize("mutation", ["source_bytes", "page", "quote", "empty_arabic"])
def test_source_replay_rejects_hash_or_source_location_drift(mutation):
    plan, data = _plan(), _source()
    e = plan["fixtures"][0]["source_evidence"][0]
    if mutation == "source_bytes":
        data += b"\n"
    elif mutation == "page":
        e["ref"] = f"src:{m5.WITNESS}/v01:p221"
    elif mutation == "quote":
        e["excerpt_ar"] = "عبارة ليست في القاعدة الثالثة والأربعين"
    else:
        e["excerpt_ar"] = "123"
    e["excerpt_sha256"] = m5.sha256(e["excerpt_ar"].encode())
    with pytest.raises(ValueError, match="full source hash|source evidence or page|no Arabic letters"):
        m5.validate_source(plan, data)


def test_cli_fails_closed_when_full_source_is_missing(monkeypatch, tmp_path, capsys):
    monkeypatch.setattr(cli, "CACHE", tmp_path)
    assert cli.main(["m5-commands"]) == 1
    assert "m5-commands:" in capsys.readouterr().err


def test_fetch_rejects_changed_download_without_repinning(monkeypatch, tmp_path):
    from usul_corpus import fetch

    plan = _plan()
    old_lock = (CORPUS / "lock.json").read_bytes()

    def changed_download(witness, cache):
        (cache / f"{m5.WITNESS}.txt").write_bytes(b"different content")
        return {**plan["source"], "sha256": "0" * 64}

    monkeypatch.setattr(fetch, "fetch", changed_download)
    with pytest.raises(ValueError, match="download differs from locked source"):
        m5.fetch_locked_source(plan, CORPUS, tmp_path)
    assert (CORPUS / "lock.json").read_bytes() == old_lock
