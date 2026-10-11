"""The type system lives in Lean (formal/lean/Usul/Typing.lean). Python only mirrors it: each typed
encoder is registered with its Lean constant and local fact order, and the generated
UsulTest/TypedMirror.lean guards that the typed encoder agrees with takhrij.ENCODERS on every
combination of fact values."""

from itertools import product
from pathlib import Path

from usul_corpus import takhrij, typing as typed

ROOT = Path(__file__).resolve().parents[2]
LEAN = (ROOT / "formal/lean/Usul/Typing.lean").read_text(encoding="utf-8")


def test_every_typed_encoder_is_a_lean_constant_over_the_encoders_own_facts():
    for name, (const, order) in typed.TYPED.items():
        assert f"def {const.rsplit('.', 1)[1]} : Typed Situation" in LEAN, const
        assert sorted(order) == sorted(takhrij.ENCODERS[name]["facts"]), name


def test_the_mirror_guards_every_fact_combination():
    text = typed.lean()
    for name, (const, order) in typed.TYPED.items():
        domains = [takhrij.ENCODERS[name]["facts"][f] for f in order]
        assert text.count(f"#guard {const}.judge") == len(list(product(*domains))), name


def test_the_generated_mirror_is_current_and_built():
    assert typed.lean() == (ROOT / typed.LEAN).read_text(encoding="utf-8")
    assert "import UsulTest.TypedMirror" in (ROOT / "formal/lean/UsulTest.lean").read_text(encoding="utf-8")


def test_coverage_counts_typed_encoders():
    c = typed.coverage()
    assert c == {"typed": len(typed.TYPED), "encoders": len(takhrij.ENCODERS)}
