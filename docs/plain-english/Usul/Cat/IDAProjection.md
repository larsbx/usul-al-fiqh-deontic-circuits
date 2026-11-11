# Usul.Cat.IDAProjection in Plain English

Source: [`formal/lean/Usul/Cat/IDAProjection.lean`](../../../../formal/lean/Usul/Cat/IDAProjection.lean)

This module gives the synthetic report evaluator a categorical factorization.
The kernel groupoid relates well-formed inputs exactly when their complete
projected dependencies agree. The evaluator maps those arrows to equality in
the discrete category of observation outcomes.

The evaluator, dependency projection, equivalence relation, and exact
factorization proofs live in
[`Usul.Typing.IDAProjection`](../Typing/IDAProjection.md). Their existing
`Usul.IDA.Projection` declaration names remain unchanged. That module uses the
foundation's ordinary `Schema.Factors` invariance predicate and imports no
categorical module.

| Theorem | What it establishes |
|---|---|
| `evaluation_functor` | There is a functor from the complete dependency projection's kernel to discrete observation outcomes whose object map is exactly the concrete evaluator. |

The proof applies the existing categorical factorization theorem to the
independently proved `Projection.factors`. It preserves observation outcomes;
it does not establish snapshot authentication, evidence truth, or ruling
admission.
