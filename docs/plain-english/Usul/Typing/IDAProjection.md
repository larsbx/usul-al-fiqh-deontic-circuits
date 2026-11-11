# Usul.Typing.IDAProjection in Plain English

Source: [`formal/lean/Usul/Typing/IDAProjection.lean`](../../../../formal/lean/Usul/Typing/IDAProjection.lean)

This module proves that a synthetic report evaluator factors through a scope
key and four report existence observations. Its input uses the existing ACT-01
well-formed snapshot type. Scope includes the complete inquiry, registered
definition, vocabulary, policy, context coordinates, and time view specified
by the evaluator.

The declarations retain the `Usul.IDA.Projection` namespace. The module imports
typed syntax and the foundation's ordinary `Schema.Factors` invariance
predicate, without importing a categorical module. The downstream
[`Usul.Cat.IDAProjection`](../Cat/IDAProjection.md) adapter gives the proven
factorization its categorical form.

| Theorem | What it establishes |
|---|---|
| `signs_positive`, `signs_negative` | Each projected sign agrees with the corresponding search over the full report list. |
| `projection_exact`, `factors`, `frame` | The complete projection gives the same outcome as the direct evaluator, and equal dependencies preserve that outcome. |
| `equivalence`, `same_scope`, `projection_preserves_target` | Dependency equality is an equivalence and preserves the scoped inquiry, including its exact structured target. |
| `signs_append_irrelevant`, `irrelevant_append` | Appending reports outside both queries preserves the observations when the scope is fixed. |
| `classify_fallback_iff`, `fallback_requires_negative` | The fallback needs an explicit negative exception report along with the rule's other stated conditions. |

The outcomes describe the report observations. Snapshot well-formedness does
not authenticate the reports, and equality of projected dependencies does not
authorize reuse of a receipt bound to a different snapshot.
