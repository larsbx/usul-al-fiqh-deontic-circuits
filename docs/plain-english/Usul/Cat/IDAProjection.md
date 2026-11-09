# Usul.Cat.IDAProjection in Plain English

Source: [`formal/lean/Usul/Cat/IDAProjection.lean`](../../../../formal/lean/Usul/Cat/IDAProjection.lean)

This module proves that a synthetic report evaluator can factor through a
scope key and four report existence observations. The input uses the existing
ACT-01 well-formed snapshot type.

| Theorem | What it establishes |
|---|---|
| `signs_positive`, `signs_negative` | Each projected sign agrees with the corresponding search over the full report list. |
| `projection_exact`, `factors`, `frame` | The complete projection gives the same outcome as the direct evaluator. |
| `equivalence`, `same_scope`, `projection_preserves_target` | Dependency equality is an equivalence and preserves the scoped inquiry, including its exact structured target. |
| `signs_append_irrelevant`, `irrelevant_append` | Appending reports outside both queries preserves the observations when the scope is fixed. |
| `classify_fallback_iff`, `fallback_requires_negative` | The fallback needs an explicit negative exception report along with the rule's other stated conditions. |
