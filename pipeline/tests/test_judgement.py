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
    qs = {"a": "هل خروج الدم يبطل الصلاة؟", "b": "ما صحة حديث من زار قبري", "c": "هل يبطل الصلاة"}
    rep = judgement.label_flags(labels, qs)
    assert rep["taklifi_labels"] == 2 and rep["flagged"] == 2 and rep["riwaya"] == ["b"]
    assert rep["by_cue"] == {"riwaya": 1, "wadi:validity": 1}
    assert rep["by_cue_set"] == {"riwaya": 1, "wadi:validity": 1}


def test_cue_sets_count_each_flagged_question_once():
    labels = [{"id": "a", "hukm": "haram"}, {"id": "b", "hukm": "haram"}]
    qs = {"a": "ما صحة حديث: هل يبطل الصيام", "b": "هل يبطل الصيام"}
    rep = judgement.label_flags(labels, qs)
    assert rep["by_cue"] == {"riwaya": 1, "wadi:validity": 2}
    assert rep["by_cue_set"] == {"riwaya+wadi:validity": 1, "wadi:validity": 1}
    assert sum(rep["by_cue_set"].values()) == rep["flagged"]


@pytest.mark.parametrize("text", ["هل يصح أن أسافر غدا", "سأل عن الصحة النفسية", "الاتجاه الصحيح للقبلة",
                                  "حكم تجزئة المساحة", "أرض زراعية يملكها", "يضمن له مستقبلا", "هدية للعروس",
                                  "شركة ضامنة", "بعد انعقاد الخطبة", "ما صحة هذا المقال"])
def test_cues_do_not_fire_on_the_false_hits_found_in_review(text):
    assert not any(rx.search(text) for rx in judgement._FLAG_RX.values())


@pytest.mark.parametrize("text, cue", [("هل يبطل الصيام", "wadi:validity"), ("فهل عمرتها صحيحة", "wadi:validity"),
                                       ("شروط صحة الصلاة", "wadi:validity"), ("فهل يضمن", "wadi:sabab/daman"),
                                       ("هل تجب الدية", "wadi:sabab/daman"), ("فهل يقع الطلاق", "wadi:sabab/milk"),
                                       ("ما صحة حديث", "riwaya")])
def test_cues_fire_on_their_questions(text, cue):
    assert judgement._FLAG_RX[cue].search(text)


def test_flag_precision_uses_the_evaluation_sample_and_reports_a_floor():
    sample = {"judge": "j", "evaluation": {"items": [{"cue": "riwaya", "asks_that": True}] * 9 +
                                                     [{"cue": "riwaya", "asks_that": False}]}}
    rep = judgement.flag_precision(sample, {"taklifi_labels": 100, "by_cue": {"riwaya": 10}, "by_cue_set": {"riwaya": 10}})
    # One cue: the joint bound is the one-sided 95% Wilson bound (z = 1.645).
    assert rep["per_cue"]["riwaya"] == {"sample": 10, "correct": 9, "precision": 0.9, "lower95": 0.596,
                                        "lower_joint": 0.652}
    assert rep["mismatch_floor"] == 0.065


def _two_cue_sample():
    return {"judge": "j", "evaluation": {"items": [{"cue": c, "asks_that": True} for c in ("a", "b") for _ in range(20)]}}


def test_overlapping_flags_count_each_question_once():
    """Audit: summing per-cue hits double-counted questions with two cues (a 192.6% "floor")."""
    rep = judgement.flag_precision(_two_cue_sample(), {"taklifi_labels": 100, "by_cue": {"a": 100, "b": 100},
                                                       "by_cue_set": {"a+b": 100}})
    assert 0 < rep["mismatch_floor"] <= 1
    assert rep["mismatch_floor"] == rep["per_cue"]["a"]["lower_joint"]


def test_distinct_floor_holds_under_the_pooled_cue_bounds():
    """Review: a bound is on a cue's pooled flags, not on each overlap stratum. With 100 a-only, 100 b-only and
    100 a+b flags at bounds 0.9 and 0.8, the bounds allow 240 distinct mismatches (100 overlap, 80 a, 60 b), not 260."""
    sets = {"a": 100, "b": 100, "a+b": 100}
    assert judgement._distinct_floor({"a": 0.9 * 200, "b": 0.8 * 200}, sets) == pytest.approx(240)
    # One cue's own requirement is always a floor, however much the cues overlap.
    assert judgement._distinct_floor({"a": 90, "b": 10}, {"a+b": 100}) == 90


def test_the_floor_bound_is_joint_over_the_cues_used():
    """Bonferroni: k cues each at one-sided 0.05/k, so every bound holds together with probability ≥ 0.95."""
    from statistics import NormalDist
    rep = judgement.flag_precision(_two_cue_sample(), {"taklifi_labels": 10, "by_cue": {"a": 1}, "by_cue_set": {"a": 1}})
    z = NormalDist().inv_cdf(1 - 0.05 / 2)
    assert rep["per_cue"]["a"]["lower_joint"] == round(judgement._wilson_low(20, 20, z), 3)
    assert rep["confidence"] == 0.95


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
