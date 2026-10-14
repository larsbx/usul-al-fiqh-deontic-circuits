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


def test_real_development_batch_pins_all_spans_to_committed_workset():
    root = Path(__file__).resolve().parents[2]
    data = json.loads((root / p.ANNOTATIONS).read_text())
    workset = json.loads((root / "corpus/fatawa/semantic-tags-development.json").read_text())
    # This offline check pins spans to committed text. The full CLI also verifies
    # the original archive and independently derives the title/body boundary.
    sources = {r["source_id"]: {"text": r["text"], "body_start": 0} for r in workset["records"]}
    assert len(data["records"]) == 12
    for row in data["records"]:
        p.validate_record(row, sources)
