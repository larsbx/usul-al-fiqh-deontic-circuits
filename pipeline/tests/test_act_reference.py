"""The act reference preserves candidate evidence and refuses false completion."""

import copy
import csv
import hashlib
import json
import subprocess

import pytest

from usul_corpus.act_reference import (
    REPO, ReferenceError, audit, load_inputs, provenance, topic_roots, validate,
    witness_observations,
)


@pytest.fixture
def data():
    return load_inputs(REPO)[0]


def test_current_reference_keeps_the_legacy_inventory_and_explicit_gaps(data):
    original = copy.deepcopy(data)
    checked = validate(data)
    assert checked["inventory_counts"] == {
        "concepts": 537, "act_labels": 293, "item_labels": 173, "issue_labels": 71, "topics": 57}
    assert checked["proposal_counts"] == {"total": 34, "representable": 1, "unresolved": 33}
    assert checked["normalization_cases"] == 12
    ready = [p for p in data["reference"]["proposals"] if p["ida_bridge"]["representable"]]
    assert [p["proposed_kind_id"] for p in ready] == ["transfer.pay_zakat"]
    assert [(p["role"], p["ref_kind"]) for p in ready[0]["ida_bridge"]["parameters"]] == [
        ("payer", "person"), ("recipient", "person"), ("transferred_property", "asset")]
    assert data == original


def test_topics_follow_all_graph_edges_across_kinds_not_identifier_prefixes():
    topics = {"abwab": [{"id": "one"}, {"id": "two"}]}
    labels = {"labels": [{"id": "unrelated.act", "kind": "act", "broader": ["bridge"]},
                         {"id": "bridge", "kind": "issue", "broader": ["one", "two"]}]}
    assert topic_roots(labels, topics)["unrelated.act"] == ["one", "two"]
    labels["labels"][1]["broader"] = ["unrelated.act"]
    with pytest.raises(ReferenceError, match="cycle"):
        topic_roots(labels, topics)
    labels["labels"][1]["broader"] = ["absent"]
    with pytest.raises(ReferenceError, match="unresolved broader"):
        topic_roots(labels, topics)
    labels["labels"][1]["broader"] = []
    with pytest.raises(ReferenceError, match="no reachable topic"):
        topic_roots(labels, topics)


@pytest.mark.parametrize("path,value,error", [
    (("admitted",), True, "candidate boundary"),
    (("compiled",), True, "candidate boundary"),
    (("mappings_admitted",), True, "candidate boundary"),
    (("proposals", 0, "admitted"), True, "candidate boundary"),
    (("proposals", 0, "ida_bridge", "profile_admitted"), True, "candidate boundary"),
    (("proposals", 0, "ida_bridge", "representable"), True, "unresolved roles"),
    (("proposals", 0, "ida_bridge", "parameters", 0, "ref_kind"), "text", "unsupported RefKind"),
    (("proposals", 0, "ida_bridge", "parameters", 0, "unresolved_reason"), "", "lacks a reason"),
    (("proposals", 0, "ida_bridge", "parameters", 0, "role"), "agent", "role order"),
    (("proposals", 0, "parameter_roles_proposed"), ["agent", "agent"], "duplicate name"),
    (("proposals", 0, "proposed_definition_version"), 2, "definition version"),
    (("proposals", 0, "source_loci", 0, "locator"), "src:invented", "source record locator"),
    (("proposals", 0, "source_loci", 0, "mapping_status"), "admitted", "source mapping boundary"),
    (("source_pins", 0, "sha256"), "0" * 64, "source pin sha256"),
    (("methodological_loci", 0, "work"), "another.work", "work/witness"),
    (("methodological_loci", 0, "page_span"), [174, 173], "invalid page span"),
    (("normalization_cases", 0, "preserve_label"), False, "normalization boundary"),
])
def test_corrupted_candidate_evidence_is_rejected(data, path, value, error):
    target = data["reference"]
    for key in path[:-1]:
        target = target[key]
    target[path[-1]] = value
    with pytest.raises(ReferenceError, match=error):
        validate(data)


def test_missing_role_legacy_kind_and_topic_mismatches_are_rejected(data):
    proposal = data["reference"]["proposals"][0]
    parameter = proposal["ida_bridge"]["parameters"].pop()
    with pytest.raises(ReferenceError, match="role order"):
        validate(data)
    proposal["ida_bridge"]["parameters"].append(parameter)
    legacy = proposal["legacy_concept_ids"][0]
    proposal["legacy_kinds"][legacy] = "act"
    with pytest.raises(ReferenceError, match="legacy kind"):
        validate(data)
    proposal["legacy_kinds"][legacy] = "issue"
    proposal["legacy_topic_ids"] = ["not.a.topic"]
    with pytest.raises(ReferenceError, match="unknown topic"):
        validate(data)


def test_exports_preserve_all_records_references_and_unanchored_reasons(data, tmp_path):
    report = audit(REPO, output=tmp_path)
    concepts = json.loads((tmp_path / "fiqh-concept-catalogue.json").read_text())["concepts"]
    acts = json.loads((tmp_path / "fiqh-act-catalogue.json").read_text())["acts"]
    source = {entry["id"]: entry for entry in data["labels"]["labels"]}
    assert len(concepts) == len(source)
    for concept in concepts:
        original = source[concept["id"]]
        assert concept["legacy_record"] == original
        assert concept["source_references_as_recorded"] == original.get("nass", [])
        assert concept["unanchored_reason_as_recorded"] == original.get("unanchored")
        assert concept["status"] == "candidate" and not concept["admitted_by_this_reference"]
    assert {entry["id"] for entry in acts} == {ident for ident, entry in source.items() if entry["kind"] == "act"}
    with (tmp_path / "fiqh-act-catalogue.csv").open(encoding="utf-8-sig", newline="") as handle:
        rows = list(csv.DictReader(handle))
    assert len(rows) == len(acts)
    assert all(json.loads(row["source_references_as_recorded"]) == source[row["id"]].get("nass", []) for row in rows)
    topics = json.loads((tmp_path / "fiqh-topic-index.json").read_text())["topics"]
    assert sum(topic["reachable_legacy_act_labels"] for topic in topics) == 294
    assert json.loads((tmp_path / "fiqh-act-type-proposals.json").read_text()) == data["reference"]
    assert json.loads((tmp_path / "source-verification.json").read_text()) == report
    assert all(row["byte_identity_status"] == "not_checked" for row in report["source_observations"])
    assert not report["mappings_admitted"] and not report["all_catalogue_source_passages_reverified"]


def test_receipt_distinguishes_committed_inputs_from_changed_or_untracked_bytes(tmp_path):
    def git(*args):
        return subprocess.run(["git", "-C", str(tmp_path), *args], check=True, capture_output=True)

    git("init", "--quiet")
    (tmp_path / "input.json").write_bytes(b"original")
    git("add", "input.json")
    git("-c", "user.name=ActReferenceTest", "-c", "user.email=test@example.invalid",
        "commit", "--quiet", "-m", "fixture")
    matched = provenance(tmp_path, {"input.json": b"original"})
    assert matched["inputs_match_head"]
    changed = provenance(tmp_path, {"input.json": b"changed", "untracked.json": b"new"})
    assert changed["repository_revision"] == matched["repository_revision"]
    assert not changed["inputs_match_head"]
    assert not any(entry["matches_head"] for entry in changed["input_files"])
    assert changed["input_files"][0]["sha256"] == hashlib.sha256(b"changed").hexdigest()


def test_source_bytes_require_explicit_evidence_and_match_the_exact_pin(tmp_path):
    content = b"one source\n"
    pin = {"witness": "fixture", "bytes": len(content), "sha256": hashlib.sha256(content).hexdigest()}
    assert witness_observations([pin], None)[0]["byte_identity_status"] == "not_checked"
    with pytest.raises(ReferenceError, match="missing requested witness"):
        witness_observations([pin], tmp_path)
    (tmp_path / "fixture.txt").write_bytes(content)
    checked = witness_observations([pin], tmp_path)[0]
    assert checked["byte_identity_status"] == "matches_existing_lock"
    assert not checked["source_interpretation_admitted"]
    (tmp_path / "fixture.txt").write_bytes(b"changed bytes")
    with pytest.raises(ReferenceError, match="differ from lock"):
        witness_observations([pin], tmp_path)
