from pathlib import Path

import pytest

from usul_corpus import judgement, takhrij

ROOT = Path(__file__).parents[2]
ENC = {"trust_loss": takhrij.ENCODERS["trust_loss"], "amr": takhrij.ENCODERS["amr"],
       "unknown_owner": takhrij.ENCODERS["unknown_owner"]}


def t(**kw):
    return {"sort": "judgement", "question": "wadi:sabab", "reason": "r"} | kw


def test_a_judgement_question_must_fit_the_output_domain():
    assert judgement.check({"trust_loss": t(), "amr": t(question="taklifi")}, ENC) == []
    assert judgement.check({"amr": t()}, ENC) == ["amr: a yes/no question needs a Bool output, not "
                                                  "['haram', 'makruh', 'mandub', 'mubah', 'wajib']"]
    assert judgement.check({"trust_loss": t(question="taklifi")}, ENC)[0].startswith("trust_loss: a taklīfī answer is a Hukm")


def test_other_sorts_answer_no_question_and_every_entry_is_reasoned():
    assert judgement.check({"unknown_owner": {"sort": "effect", "reason": "to whom"}}, ENC) == []
    assert judgement.check({"unknown_owner": {"sort": "effect", "question": "taklifi", "reason": "r"}}, ENC) == \
        ["unknown_owner: only a judgement answers a question"]
    assert judgement.check({"x": t()}, ENC) == ["x: not an encoder"]
    assert judgement.check({"trust_loss": t(reason=" ")}, ENC) == ["trust_loss: no reason"]
    assert judgement.check({"trust_loss": t(bool_as_validity=True)}, ENC) == \
        ["trust_loss: bool_as_validity is for wadi:validity only"]


def test_lean_guards_ascribe_the_answer_type():
    lean = judgement.lean_file({"trust_loss": t(), "amr": t(question="taklifi"),
                                "unknown_owner": {"sort": "effect", "reason": "r"}})
    assert "example : Usul.Question.Answer (.wadi .sabab) := Usul.Muamalat.lossLiable" in lean
    assert "example : Usul.Question.Answer .taklifi := Usul.Dalala.amrStatus" in lean
    assert "recipient" not in lean
    v = judgement.lean_file({"trust_loss": t(question="wadi:validity", bool_as_validity=True)})
    assert "example : Usul.Question.Answer (.wadi .validity) := Usul.Validity.ofEffects (Usul.Muamalat.lossLiable" in v
    n = judgement.lean_file({"trust_loss": t(question="wadi:validity", bool_as_validity=True, negated=True)})
    assert ":= (Usul.Validity.ofEffects ∘ (!·)) (Usul.Muamalat.lossLiable" in n
    typed = judgement.lean_file({"trust_loss": t(negated=True)}, {"trust_loss": "Usul.Typing.trustLoss"})
    assert ("example : Usul.Typing.Typed Usul.Typing.Situation (Usul.Question.Answer (.wadi .sabab)) := "
            "Usul.Typing.trustLoss.mapRun (!·)") in typed
    assert judgement.check({"amr": t(question="taklifi", negated=True)}, ENC) == ["amr: only a yes/no answer can be negated"]


def test_report_lists_the_untyped_and_never_guesses():
    cases = [{"encoder": "trust_loss", "class": "derivable"}, {"encoder": "unknown_owner", "class": "derivable"},
             {"encoder": "amr", "class": "segmentation_error"}]
    rep = judgement.report({"trust_loss": t()}, ENC, cases)
    assert rep["cases"] == {"judgement/wadi:sabab": 1, "untyped": 1} and rep["cases_typed_by_judgement"] == 0.5
    assert rep["untyped"] == ["amr", "unknown_owner"]


def test_label_flags_count_taklifi_labels_whose_question_is_wadi_or_riwaya():
    labels = [{"id": "a", "hukm": "haram"}, {"id": "b", "hukm": "mubah"}, {"id": "c", "hukm": None}]
    qs = {"a": "هل خروج الدم يبطل الصلاة؟", "b": "ما صحة حديث من زار قبري", "c": "هل يبطل"}
    rep = judgement.label_flags(labels, qs)
    assert rep["taklifi_labels"] == 2 and rep["flagged"] == 2 and rep["riwaya"] == ["b"]
    assert rep["by_cue"] == {"riwaya": 1, "wadi:validity": 2}


def test_committed_types_are_checked_and_generated():
    path = ROOT / "corpus" / judgement.TYPES
    if not path.exists():
        pytest.skip("no encoder types yet")
    types = judgement.load(ROOT / "corpus")
    assert judgement.check(types, takhrij.ENCODERS) == []
    typed = judgement.typed_names(ROOT)
    assert set(typed) == set(takhrij.ENCODERS)
    assert (ROOT / "formal/lean/UsulTest/EncoderTypes.lean").read_text(encoding="utf-8") == judgement.lean_file(types, typed)
    assert "import UsulTest.EncoderTypes" in (ROOT / "formal/lean/UsulTest.lean").read_text()
