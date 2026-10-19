import copy
import json
from pathlib import Path

import pytest

from usul_corpus import semantic_propositions as p, semantic_tags as tags, takhrij


@pytest.fixture
def sample():
    text = "عنوان رأيت مالا أمانة. ثم سافر شخص آخر."
    start, end = text.index("رأيت"), text.index(".")
    scope = tags.span("q", text, start, end)
    roles = {r: {"status": "unknown", "value": None, "evidence": []} for r in p.ROLES}
    roles["act"] = {"status": "candidate", "value": "receive trust", "evidence": [scope]}
    prop = {"id": "p1", "status": "candidate", "modality": "asserted", "polarity": "positive", "scope": scope, "roles": roles}
    facts = {f: {"proposition_id": "p1", "status": "unknown", "value": None, "evidence": None, "rationale": "not stated"}
             for f in takhrij.ENCODERS["trust_loss"]["facts"]}
    facts["hand"].update(status="candidate", value="trustee", evidence=scope, rationale="Explicit entrustment")
    row = {"source_id": "q", "text_sha256": tags.digest(text), "status": "candidate", "propositions": [prop],
           "bank_mappings": [{"proposition_id": "p1", "encoder": "trust_loss", "facts": facts}]}
    return row, {"q": {"text": text, "body_start": start}}


def test_candidate_mapping_holds_without_execution(sample, monkeypatch):
    monkeypatch.setitem(takhrij.ENCODERS["trust_loss"], "py", lambda _: pytest.fail("execution"))
    row, sources = sample
    result = p.validate_record(row, sources)
    assert result["mappings"][0]["status"] == "hold"
    assert set(result["mappings"][0]["missing_facts"]) == {"hand", "transgressed", "negligent"}


@pytest.mark.parametrize("modality", ["hypothetical", "uncertain", "questioned"])
def test_nonasserted_branch_cannot_supply_factual_binding(sample, modality):
    row, sources = sample
    row["propositions"][0]["modality"] = modality
    with pytest.raises(ValueError, match="Non-asserted"):
        p.validate_record(row, sources)


def test_negation_cannot_be_dropped_to_fill_positive_fact(sample):
    row, sources = sample
    row["propositions"][0]["polarity"] = "negative"
    with pytest.raises(ValueError, match="Non-asserted"):
        p.validate_record(row, sources)


def test_actor_events_cannot_share_fact_bindings(sample):
    row, sources = sample
    row["bank_mappings"][0]["facts"]["hand"]["proposition_id"] = "other_actor_event"
    with pytest.raises(ValueError, match="pool facts"):
        p.validate_record(row, sources)


def test_body_evidence_cannot_be_replaced_with_editorial_title(sample):
    row, sources = sample
    row["propositions"][0]["scope"] = tags.span("q", sources["q"]["text"], 0, 5)
    with pytest.raises(ValueError, match="Editorial title"):
        p.validate_record(row, sources)


def test_same_question_evidence_from_another_event_is_rejected(sample):
    row, sources = sample
    text = sources["q"]["text"]
    row["bank_mappings"][0]["facts"]["hand"]["evidence"] = tags.span("q", text, text.index("ثم"), len(text))
    with pytest.raises(ValueError, match="crosses proposition scope"):
        p.validate_record(row, sources)


def test_duplicate_ids_and_forged_review_status_rejected(sample):
    row, sources = sample
    duplicate = copy.deepcopy(row)
    duplicate["propositions"].append(copy.deepcopy(duplicate["propositions"][0]))
    with pytest.raises(ValueError, match="duplicate proposition"):
        p.validate_record(duplicate, sources)
    row["bank_mappings"][0]["facts"]["hand"]["status"] = "reviewed"
    with pytest.raises(ValueError, match="cannot assert review"):
        p.validate_record(row, sources)


def test_real_development_batch_pins_all_spans_to_committed_workset(monkeypatch):
    root = Path(__file__).resolve().parents[2]
    data = json.loads((root / p.ANNOTATIONS).read_text())
    workset = json.loads((root / "corpus/fatawa/semantic-tags-development.json").read_text())
    # This offline check pins spans to committed text. The full CLI also verifies
    # the original archive and independently derives the title/body boundary.
    sources = {r["source_id"]: {"text": r["text"], "body_start": 0} for r in workset["records"]}
    assert len(data["records"]) == len(sources) == 53
    assert {r["source_id"] for r in data["records"]} == set(sources)
    # Candidate development mappings must never call an executable mirror.
    for encoder in takhrij.ENCODERS.values():
        monkeypatch.setitem(encoder, "py", lambda _: pytest.fail("development kernel execution"))
    for row in data["records"]:
        result = p.validate_record(row, sources)
        assert all(m["status"] == "hold" and m["output"] is None for m in result["mappings"])


@pytest.mark.parametrize("probe_value", [False, True])
def test_tawaf_doubt_mapping_contains_uncertainty_without_asserting_it(monkeypatch, probe_value):
    root = Path(__file__).resolve().parents[2]
    data = json.loads((root / p.ANNOTATIONS).read_text())
    workset = json.loads((root / "corpus/fatawa/semantic-tags-development.json").read_text())
    row = next(r for r in data["records"] if r["source_id"] == "islamqa.128887")
    text = next(r["text"] for r in workset["records"] if r["source_id"] == row["source_id"])
    # The offline workset lacks the independently derived title/body boundary.
    # This narrower, known body-only interval contains every annotation here.
    sources = {row["source_id"]: {"text": text, "body_start": 177}}
    props = {q["id"]: q for q in row["propositions"]}
    act = props["islamqa.128887.p1"]
    mapping, = row["bank_mappings"]
    assert mapping["proposition_id"] == act["id"]
    assert mapping["encoder"] == "doubt_in_condition"
    assert (act["modality"], act["polarity"]) == ("asserted", "positive")
    assert act["roles"]["act"]["evidence"] == [tags.span(row["source_id"], text, 177, 208)]
    uncertain = [props[f"islamqa.128887.p{i}"] for i in (3, 4, 6)]
    assert all(q["modality"] == "uncertain" for q in uncertain)
    assert act["roles"]["condition"]["status"] == "candidate"
    assert act["roles"]["condition"]["evidence"] == [q["scope"] for q in uncertain]
    assert all(f["status"] == "unknown" and f["value"] is None and f["evidence"] is None
               for f in mapping["facts"].values())
    monkeypatch.setitem(takhrij.ENCODERS["doubt_in_condition"], "py",
                        lambda _: pytest.fail("development kernel execution"))
    assert p.validate_record(row, sources)["mappings"][0]["status"] == "hold"

    # Both Boolean probes deliberately pass: this tests scope, NOT entailment.
    # Neither value is a claim about ghalaba or a committed annotation.
    probe = copy.deepcopy(row)
    probe["bank_mappings"][0]["facts"]["ghalaba"].update(
        status="candidate", value=probe_value, evidence=uncertain[2]["scope"],
        rationale="Test-only structural probe; no semantic entailment claimed.")
    result = p.validate_record(probe, sources)["mappings"][0]
    assert result["status"] == "hold" and result["output"] is None
    assert set(result["missing_facts"]) == set(mapping["facts"])

    # Restore the old act-only scope: the same fact evidence cannot be pooled.
    narrow = copy.deepcopy(probe)
    narrow["propositions"][0]["scope"] = act["roles"]["act"]["evidence"][0]
    narrow["propositions"][0]["roles"]["condition"] = {
        "status": "unknown", "value": None, "evidence": []}
    with pytest.raises(ValueError, match="Fact evidence crosses proposition scope"):
        p.validate_record(narrow, sources)

    # The separate uncertain proposition still cannot supply factual bindings.
    target = uncertain[2]["id"]
    probe["bank_mappings"][0]["proposition_id"] = target
    for fact in probe["bank_mappings"][0]["facts"].values():
        fact["proposition_id"] = target
    with pytest.raises(ValueError, match="Non-asserted"):
        p.validate_record(probe, sources)


@pytest.mark.external_source
def test_development_artifacts_replay_from_pinned_archive(islamqa_answers, monkeypatch):
    root = Path(__file__).resolve().parents[2]
    for encoder in takhrij.ENCODERS.values():
        monkeypatch.setitem(encoder, "py", lambda _: pytest.fail("development kernel execution"))
    assert tags.build(root) == json.loads((root / "corpus/fatawa/semantic-tags-development.json").read_text())
    report = p.evaluate(root)
    assert report == json.loads((root / p.REPORT).read_text())
    assert report["annotated_questions"] == report["available_questions"] == 53
    assert report["new_kernel_executions"] == 0
