# Usul.Typing.IDASemantics in Plain English

Source: [`formal/lean/Usul/Typing/IDASemantics.lean`](../../../../formal/lean/Usul/Typing/IDASemantics.lean)

This module interprets the ACT-02 syntax over typed rigid valuations and a
fixed truth assignment. Its conditional interpretation and finite candidate
checker are separate from report rows and evidence admission. It imports the
type-layer substitution module and has no categorical dependency.

The declarations retain the `Usul.IDA.Semantics` namespace. The downstream
[`Usul.Cat.IDASemantics`](../Cat/IDASemantics.md) module packages their laws as
functors and naturality results; admission can use the pure semantics directly.

| Theorem | What it establishes |
|---|---|
| `grounding_pull`, `pull_id`, `pull_comp` | Valuations pull back by evaluating replacements, with identity and composition laws. |
| `evaluate_subst`, `satisfaction_subst`, `premises_subst` | Substitution commutes with truth evaluation of formulas and with satisfaction of premise lists at the same history. |
| `sound`, `sound_along` | The assumption and conjunction calculus and its premise arrows are semantically sound when their premises hold. |
| `supported_subst`, `read_isSome_iff`, `interpretation_supported`, `interpret_subst` | Support is exact to the registered definition and signature; supported descriptions have meanings, and interpretation commutes with reindexing. |
| `groundInquiry_subst`, `inquiry_subst` | The complete grounded inquiry and its concrete projection agree along both paths. |
| `opposing_premises_incompatible`, `mem_compatible`, `robust_iff` | Opposite signed premises are incompatible, compatible points satisfy the selected premises, and robustness requires a nonempty compatible population. |

The assessment is relative to the supplied finite candidate points. A nonempty
compatible population establishes internal consistency within that population;
it does not establish that the supplied history describes the actual case.
