"""Source contrasts, candidate governance and provenance for M5 command capabilities."""

import copy
import json
import shutil
from itertools import product
from pathlib import Path

import pytest

from usul_corpus import m5_commands as m5, takhrij
from usul_corpus import __main__ as cli

ROOT = Path(__file__).parents[2]
CORPUS = ROOT / "corpus"

# Complete gap records independently checked at the original contribution base
# 3a9d11776eb3be21702d3624f4152e276fda00ed and integrated main 24051f90.
# Keep this preservation gate separate from the mutable work plan and live totals.
ORIGINAL_GAP_CASE_SHA256 = {
    takhrij.LAHHAM.format(43) + ".f001": "3432b0a46543ccde7f97d0893c50e4a13a3a9e89c83d20ff5bdec5e208ea37cc",
    takhrij.LAHHAM.format(43) + ".f003": "42faedea481cd1102166866a76dd6f75c8a428cdc69a74ce2cb8b5388590869e",
    takhrij.LAHHAM.format(43) + ".f004": "6c67447789d873d8dc6778ef86c92bc705baf672195282ba6782e4ef2ba8ce65",
    takhrij.LAHHAM.format(43) + ".f007": "6541542f5cd5909107f61ba24243afa448e298b15e9744ba3952d11e3abeb15c",
    takhrij.LAHHAM.format(52) + ".f007": "0ba95f474f71653933db2a1bb78fe2483a9ddac3e918abd07e98c499453b9543",
    takhrij.RAJAB.format(22) + ".f000": "ba72663774a7a84972999b44d0291ed0f05f3a5db176c740042be8d68353ec0a",
}


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
    assert set(m5.ORIGINAL_EVIDENCE_SHA256) == set(m5.required_fixtures())
    assert plan["status"] == "candidate"
    assert all(q["status"] == "open" for q in plan["review_questions"])
    assert all(r["gap_status"] == "open" for r in plan["case_receipts"])
    cases = {c["far"]: c for c in takhrij.load(CORPUS)}
    for r in plan["case_receipts"]:
        assert r["original_case"] == cases[r["far"]]
        assert cases[r["far"]]["class"] == "missing_rule"
        assert not set(cases[r["far"]]["needs"]) <= takhrij.provides()


def test_all_six_original_gaps_are_unchanged_and_the_report_counts_live_annotations():
    cases = takhrij.load(CORPUS)
    report = takhrij.report(cases)
    gaps = {c["far"]: m5.case_sha256(c) for c in cases if c["class"] in takhrij.GAPS}
    # Pin the original M5 obligations; later source-grounded tranches may add distinct gaps.
    assert {uid: gaps[uid] for uid in ORIGINAL_GAP_CASE_SHA256} == ORIGINAL_GAP_CASE_SHA256
    assert len(ORIGINAL_GAP_CASE_SHA256) == 6
    assert report["gaps_open"] == sum(bool(c.get("needs")) for c in cases)
    assert report["total"] == len(cases)
    assert report["classes"].get("encoding_error", 0) == 0
    assert not {f["id"] for f in _plan()["fixtures"]} & {c["far"] for c in cases}
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
    ("base_commit", "contribution anchor"),
    ("witness", "wrong source witness"), ("source_hash", "source lock"),
    ("records_hash", "source record receipt"), ("case_hash", "original case hash"),
    ("rewrite_case", "base anchor"), ("promote_gap", "gap was promoted"),
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
    elif mutation == "base_commit":
        plan["base_commit"] = "0" * 40
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


@pytest.mark.parametrize("field,value", [
    ("note", "a silently replaced interpretation"), ("encoder", "nahy"),
    ("needs", ["rule:another_unprovided_rule"]),
])
def test_simultaneous_live_case_and_receipt_rewrite_cannot_move_the_base_anchor(monkeypatch, field, value):
    plan = _plan()
    receipt = plan["case_receipts"][0]
    receipt["original_case"][field] = value
    receipt["original_case_sha256"] = m5.case_sha256(receipt["original_case"])
    receipt["needs"] = receipt["original_case"]["needs"]
    cases = takhrij.load(CORPUS)
    cases = [receipt["original_case"] if c["far"] == receipt["far"] else c for c in cases]
    monkeypatch.setattr(takhrij, "load", lambda corpus: cases)
    with pytest.raises(ValueError, match="original case differs from base anchor"):
        m5.validate(plan, CORPUS)


def test_live_case_change_is_rejected_with_the_original_receipt_intact(monkeypatch):
    plan = _plan()
    cases = takhrij.load(CORPUS)
    next(c for c in cases if c["far"] == plan["case_receipts"][0]["far"])["note"] = "changed live case"
    monkeypatch.setattr(takhrij, "load", lambda corpus: cases)
    with pytest.raises(ValueError, match="live case changed without an explicit revisit"):
        m5.validate(plan, CORPUS)


@pytest.mark.parametrize("fixture_id", sorted(m5.required_fixtures()))
def test_every_required_source_contrast_rejects_silent_deletion(fixture_id):
    plan = _plan()
    plan["fixtures"] = [f for f in plan["fixtures"] if f["id"] != fixture_id]
    with pytest.raises(ValueError, match="required fixture set changed"):
        m5.validate(plan, CORPUS)


def test_retaining_fixture_ids_cannot_replace_a_required_input_contrast():
    plan = _plan()
    fixture = next(f for f in plan["fixtures"] if f["id"] == "M5-CMD-004-qadi-fardLabel-mandub")
    fixture["facts"]["qarina"] = "makruh"
    fixture["expected"] = "makruh"  # a valid domain input/output, but not the required contrast
    with pytest.raises(ValueError, match="fixture input matrix changed"):
        m5.validate(plan, CORPUS)


@pytest.mark.parametrize("mutation,message", [
    ("merged_questions", "review question mapping"), ("swapped_gates", "review question mapping"),
    ("rename_gate", "review question mapping"), ("duplicate_case_link", "case-specific review link"),
    ("blank_question", "review question is empty"),
])
def test_review_gates_remain_distinct_even_when_scopes_and_links_are_edited_together(mutation, message):
    plan = _plan()
    questions, receipts = plan["review_questions"], plan["case_receipts"]
    if mutation == "merged_questions":
        questions[0]["scope"] = sorted(m5.FARS)
        for q in questions[1:]:
            q["scope"] = []
        for r in receipts:
            r["review_questions"] = [questions[0]["id"]]
    elif mutation == "swapped_gates":
        questions[0]["scope"], questions[1]["scope"] = questions[1]["scope"], questions[0]["scope"]
        receipts[0]["review_questions"], receipts[1]["review_questions"] = receipts[1]["review_questions"], receipts[0]["review_questions"]
    elif mutation == "rename_gate":
        questions[0]["id"] = "another-review-gate"
        receipts[0]["review_questions"] = [questions[0]["id"]]
    elif mutation == "duplicate_case_link":
        receipts[0]["review_questions"] *= 2
    else:
        questions[0]["question"] = " "
    with pytest.raises(ValueError, match=message):
        m5.validate(plan, CORPUS)


def _copy_receipted_corpus(target):
    (target / "records").mkdir()
    shutil.copy(CORPUS / "lock.json", target / "lock.json")
    shutil.copy(CORPUS / f"records/{m5.WITNESS}.jsonl", target / "records")
    shutil.copytree(CORPUS / "takhrij", target / "takhrij")


@pytest.mark.parametrize("field,value", [
    ("url", "https://example.invalid/replacement-source"),
    ("bytes", 722415), ("sha256", "0" * 64),
])
def test_joint_plan_and_lock_edits_cannot_replace_original_source_metadata(tmp_path, field, value):
    _copy_receipted_corpus(tmp_path)
    plan = _plan()
    lock = json.loads((tmp_path / "lock.json").read_text())
    plan["source"][field] = lock["witnesses"][m5.WITNESS][field] = value
    (tmp_path / "lock.json").write_text(json.dumps(lock))
    with pytest.raises(ValueError, match="source contribution anchor changed"):
        m5.validate(plan, tmp_path)


def test_joint_plan_and_record_edits_cannot_replace_the_base_source_records(tmp_path):
    _copy_receipted_corpus(tmp_path)
    plan = _plan()
    path = tmp_path / f"records/{m5.WITNESS}.jsonl"
    records = [json.loads(line) for line in path.read_text().splitlines()]
    records[0]["excerpt_ar"] = "تفسير بديل غير مسجل"
    raw = "".join(json.dumps(r, ensure_ascii=False) + "\n" for r in records).encode()
    path.write_bytes(raw)
    plan["records_sha256"] = m5.sha256(raw)
    with pytest.raises(ValueError, match="source record differs from base anchor"):
        m5.validate(plan, tmp_path)


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
    with pytest.raises(ValueError, match="full source hash|fixture evidence differs from original anchor"):
        m5.validate_source(plan, data)


@pytest.mark.parametrize("fixture_id", sorted(m5.required_fixtures()))
def test_an_existing_q43_quote_cannot_replace_any_fixtures_evidence(fixture_id):
    plan, data = _plan(), _source()
    fixture = next(f for f in plan["fixtures"] if f["id"] == fixture_id)
    refs = [e["ref"] for e in fixture["source_evidence"]]
    replacement = next(f for f in plan["fixtures"] if f["far"] != fixture["far"]
                       and [e["ref"] for e in f["source_evidence"]] != refs)
    fixture["source_evidence"] = copy.deepcopy(replacement["source_evidence"])
    # The substitute is valid source text from Q43, with valid page and excerpt
    # hashes, but belongs to a different command question. The fixture's original
    # ID, inputs, encoder and expected result remain intact.
    assert all(e["excerpt_sha256"] == m5.sha256(e["excerpt_ar"].encode())
               for e in fixture["source_evidence"])
    with pytest.raises(ValueError, match="fixture evidence differs from original anchor"):
        m5.validate(plan, CORPUS)
    with pytest.raises(ValueError, match="fixture evidence differs from original anchor"):
        m5.validate_source(plan, data)


def test_cli_fails_closed_when_full_source_is_missing(monkeypatch, tmp_path, capsys):
    monkeypatch.setattr(cli, "CACHE", tmp_path)
    assert cli.main(["m5-commands"]) == 1
    assert "m5-commands:" in capsys.readouterr().err


def test_fetch_rejects_changed_download_without_repinning(monkeypatch, tmp_path):
    from usul_corpus import fetch

    plan = _plan()
    old_lock = (CORPUS / "lock.json").read_bytes()

    def changed_download(witness, cache, *, refresh=False):
        assert refresh
        (cache / f"{m5.WITNESS}.txt").write_bytes(b"different content")
        return {**plan["source"], "sha256": "0" * 64}

    monkeypatch.setattr(fetch, "fetch", changed_download)
    with pytest.raises(ValueError, match="download differs from locked source"):
        m5.fetch_locked_source(plan, CORPUS, tmp_path)
    assert (CORPUS / "lock.json").read_bytes() == old_lock


def test_explicit_fetch_restores_an_invalid_cache_from_the_pinned_url(monkeypatch, tmp_path):
    from usul_corpus import fetch

    plan, data = _plan(), _source()
    old_lock = (CORPUS / "lock.json").read_bytes()
    cache_file = tmp_path / f"{m5.WITNESS}.txt"
    cache_file.write_bytes(b"truncated witness")
    requests = []

    def get_source(url):
        requests.append(url)
        return data

    monkeypatch.setattr(fetch, "_get", get_source)
    restored = m5.fetch_locked_source(plan, CORPUS, tmp_path)
    assert requests == [plan["source"]["url"]]
    assert cache_file.read_bytes() == restored == data
    m5.validate_source(plan, restored)
    assert (CORPUS / "lock.json").read_bytes() == old_lock


def test_retry_after_a_rejected_download_can_restore_the_cache_without_repinning(monkeypatch, tmp_path):
    from usul_corpus import fetch

    plan, data = _plan(), _source()
    old_lock = (CORPUS / "lock.json").read_bytes()
    replies = iter((b"changed upstream bytes", data))
    requests = []

    def get_source(url):
        requests.append(url)
        return next(replies)

    monkeypatch.setattr(fetch, "_get", get_source)
    with pytest.raises(ValueError, match="download differs from locked source"):
        m5.fetch_locked_source(plan, CORPUS, tmp_path)
    assert m5.fetch_locked_source(plan, CORPUS, tmp_path) == data
    assert requests == [plan["source"]["url"]] * 2
    assert (CORPUS / "lock.json").read_bytes() == old_lock
