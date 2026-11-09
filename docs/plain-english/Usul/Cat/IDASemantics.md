# Usul.Cat.IDASemantics in Plain English

Source: [`formal/lean/Usul/Cat/IDASemantics.lean`](../../../../formal/lean/Usul/Cat/IDASemantics.lean)

This module interprets the ACT-02 syntax over typed rigid valuations and a
fixed truth assignment. The conditional interpretation and the finite
candidate checker are separate from report rows and evidence admission.

| Theorem | What it establishes |
|---|---|
| `grounding_pull`, `pull_id`, `pull_comp` | Valuations pull back by evaluating replacements, with identity and composition laws. |
| `evaluate_subst`, `satisfaction_subst`, `premises_subst` | Substitution commutes with truth evaluation of formulas and with satisfaction of premise lists at the same history. |
| `sound`, `sound_along` | The assumption and conjunction calculus and its premise arrows are semantically sound when their premises hold. |
| `supported_subst`, `interpretation_supported`, `interpret_subst` | Support is exact to the registered definition and signature, and meanings commute with reindexing. |
| `groundInquiry_subst`, `inquiry_subst` | The complete grounded inquiry and its concrete projection agree along both paths. |
| `opposing_premises_incompatible`, `mem_compatible`, `robust_iff` | Opposite signed premises are incompatible, and robustness requires a nonempty compatible population. |
| `description_naturality`, `formula_naturality` | The two interpretations commute with the maps of their valuation-based meaning presheaves. |
