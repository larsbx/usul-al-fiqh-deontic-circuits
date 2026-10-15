"""Regressions for candidate-only field routing and separated evaluation."""
import json
from pathlib import Path

import pytest

from usul_corpus import routing, takhrij, signature_routing as typed

ROOT = Path(__file__).resolve().parents[2]


def test_partial_observations_are_strictly_typed_and_do_not_fill_unknowns():
    schema = {"necessary": [False, True], "count": [1, 2]}
    assert typed.compatible({}, schema)
    assert typed.compatible({"necessary": False}, schema)
    assert not typed.compatible({"necessary": 1}, schema)
    assert not typed.compatible({"count": True}, schema)
    assert not typed.compatible({"unknown": True}, schema)
    assert not typed.compatible({"count": 3}, schema)


def test_schemas_preserve_the_registry_domains():
    for name, schema in typed.signatures().items():
        assert schema == {k: list(v) for k, v in takhrij.ENCODERS[name]["facts"].items()}


def test_training_fields_use_only_passed_classical_records(monkeypatch):
    monkeypatch.setattr(typed, "signatures", lambda: {"a": {"first": [True]}, "b": {"second": [True]}})
    monkeypatch.setattr(takhrij, "load", lambda _: [
        {"far": "train", "encoder": "a", "facts": {"first": True}},
        {"far": "heldout", "encoder": "b", "facts": {"second": False}},
    ])
    monkeypatch.setattr(routing, "qawaid", lambda _: [("b", "وديعة")])
    model = typed.Model.fit(Path("unused"), [("train", "a", "صلاة مسجد")])
    assert set(model.fields.profiles) == {"first"}
    assert model.rank("صلاة", 1)[0] == "a"
    assert model.rank("لا توجد إشارة", 1) == ["a", "b"]
    # Neither the rule mirror nor any annotation fact value participates in ranking.
    assert typed.compatible({"second": False}, model.schemas["b"]) is False


def test_lexical_zero_weight_matches_original_model():
    corpus = ROOT / "corpus"
    cases = routing.cases(corpus)
    train = [c for c in cases if routing._fold(c[0]) != 0]
    model = typed.Model.fit(corpus, train)
    for _, _, text in cases[:10]:
        assert model.rank(text, 0) == model.lexical.rank(text)


def test_generated_classical_report_replays():
    assert typed.render(ROOT, classical_only=True) == (ROOT / typed.OUTPUT).read_text()


def test_partial_report_preserves_original_ood_and_has_no_modern_metrics():
    report = json.loads((ROOT / typed.OUTPUT).read_text())
    assert report["status"] == "candidate"
    assert report["ood"]["evaluation_status"] == "blocked_missing_questions"
    assert report["ood"]["original_lexical"] == json.loads((ROOT / "corpus" / routing.OOD).read_text())
    assert report["ood"]["rows"] == []
    assert all(v == {} for v in report["ood"]["recall"].values())
    assert report["bab"]["accuracy"] is None
    assert report["classical"]["recall"]["lexical"] == json.loads(
        (ROOT / "corpus" / routing.INDEX).read_text())["recall"]["held_out"]


def test_inner_selection_prefers_less_structure_on_ties(monkeypatch):
    class Same:
        def rank(self, text, weight):
            return ["a"]
    monkeypatch.setattr(typed.Model, "fit", lambda *args: Same())
    assert typed.select_weight(Path("unused"), [("record", "a", "text")]) == 0


def test_original_questions_require_pinned_source_and_exact_membership(tmp_path, monkeypatch):
    import gzip
    import hashlib
    path = tmp_path / routing.ANSWERS
    path.parent.mkdir(parents=True)
    path.write_text("version https://git-lfs.github.com/spec/v1\n")
    with pytest.raises(ValueError, match="pinned SHA-256"):
        typed.questions(tmp_path, {"q1"})
    with gzip.open(path, "wt", encoding="utf-8") as fh:
        fh.write(json.dumps({"id": "q1", "title": "title", "question": "question"}) + "\n")
    monkeypatch.setattr(typed, "ANSWERS_SHA256", hashlib.sha256(path.read_bytes()).hexdigest())
    assert typed.questions(tmp_path, {"q1"}) == {"q1": "title question"}
    with pytest.raises(ValueError, match="Missing or duplicated"):
        typed.questions(tmp_path, {"q1", "q2"})
