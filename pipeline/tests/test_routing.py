"""P0.6, the routing index: encoder profiles derived from the bank's own evidence (annotated cases and
the encoders' qawāʿid), never hand-written lexicons; recall is measured on held-out cases."""

import json
from pathlib import Path

import pytest

from usul_corpus import routing

ROOT = Path(__file__).resolve().parents[2]
CORPUS = ROOT / "corpus"
INDEX = json.loads((CORPUS / routing.INDEX).read_text(encoding="utf-8"))


def test_the_committed_index_is_current():
    assert routing.render(CORPUS) == (CORPUS / routing.INDEX).read_text(encoding="utf-8")


def test_held_out_cases_route_to_their_encoder_far_above_the_prior():
    """Audit PR-38: the headline folds whole qawāʿid, so no sibling of a test farʿ trains the model."""
    r = INDEX["recall"]
    head, within = r["by_qaida"], r["within_qaida"]
    assert head["recall"]["5"] >= 0.5 and head["recall"]["5"] > 2 * head["prior"]["5"]
    assert within["recall"]["5"] >= 0.8 and within["recall"]["5"] > 2 * within["prior"]["5"]
    # Siblings in training inflate recall; a qāʿida the bank has not formalised is routed near the prior.
    assert within["recall"]["1"] > head["recall"]["1"] > r["unseen_qaida"]["recall"]["1"]


def test_every_lexicon_word_occurs_in_that_encoders_own_evidence():
    model = routing.Model.fit(routing.evidence(CORPUS))
    for name, e in INDEX["encoders"].items():
        assert set(e["lexicon"]) <= model.vocabulary[name], name


def test_routed_babs_are_committed_bab_records():
    ids = {json.loads(l)["id"] for p in (CORPUS / "records").glob("*.jsonl")
           for l in p.read_text(encoding="utf-8").splitlines() if '"record_type": "bab"' in l}
    assert all(b["id"] in ids for e in INDEX["encoders"].values() for b in e["babs"])


def test_a_text_routes_by_its_words():
    model = routing.Model.fit([("luqata", "من وجد لقطة عرفها سنة"), ("tabaa", "يتبع الولد أمه في الحرية والرق")])
    assert model.rank("وجد لقطة في الطريق")[0] == "luqata"


@pytest.mark.external_source
def test_the_out_of_domain_report_is_current(islamqa_answers):
    assert routing.render_ood(ROOT) == (CORPUS / routing.OOD).read_text(encoding="utf-8")
