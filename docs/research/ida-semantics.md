# ACT-04 fixed-history semantics

This is the first interpreted fragment of the [ACT-04 contract](ida-act-classification-roadmap.md#act-04--interpret-supported-fragments-and-migrate-schemas).
It reuses the typed syntax and premise arrows from [ACT-02](ida-substitution.md)
and the synthetic repayment inquiry from [ACT-03](ida-projection.md). The
pure interpretation and soundness implementation is in
[`Usul.Typing.IDASemantics`](../../formal/lean/Usul/Typing/IDASemantics.lean).
The downstream [`Usul.Cat.IDASemantics`](../../formal/lean/Usul/Cat/IDASemantics.lean)
packages its valuation and meaning functors and naturality laws. Contextual
admission imports the pure module, so it does not depend on the categorical
layer. The split preserves the existing declaration names and proofs.

## Domain and interpretation

A valuation assigns a rigid well-formed reference of the declared sort to
each formal variable. A history independently assigns a truth value to every
ground atom in the fixed vocabulary. Satisfaction interprets a signed atom
by comparing its sign to that truth value and interprets conjunction by
Boolean conjunction. Opposite reports remain report rows. They supply
neither a truth assignment nor contradictory Lean hypotheses. If opposing
signed atoms are selected as premises, no history and valuation satisfy both.

The synthetic description interpreter reads the exact registered repayment
definition and its resolved role signature. Its denotation records the
debtor, creditor, and obligation in their declared positions. An unsupported
definition produces an explicit empty result, including a different version
with the same symbol. No source text or juristic rule supplies this synthetic
denotation.

## Semantic laws

For a substitution from a context Δ to a context Γ, the valuation map
evaluates the replacement terms in a Δ-valuation to produce a Γ-valuation.
Lean proves its identity and composition laws. The valuation functor is
covariant on the context category. Functions from valuations to a fixed
meaning type reindex contravariantly by precomposition.

Lean proves naturality of description meanings and Boolean formula
evaluation into those presheaves. The support condition is preserved and
reflected by substitution, so both sides of the description equation are
defined on the same supported fragment. Formula satisfaction and satisfaction
of a premise list commute with valuation pullback at the same history.
The inquiry theorem compares the complete grounded inquiry, including its
frame, schema, accountable subject, and performer.

The ACT-02 assumption and conjunction rules are sound for these semantics.
For a premise-context arrow, soundness of its premise witnesses supplies
the interpreted premises needed to apply the original derivation. A
nonidentity witness swaps two formal person positions and establishes the
substituted formula in a specific history. This is conditional semantic
soundness. It carries no evidence or judgment receipt.

## Finite assessment

The finite checker filters a supplied list of history–valuation points by all
selected premises. It distinguishes an empty candidate list, incompatible
selected premises in a nonempty list, a counterexample, and a robust outcome.
Lean proves that robustness requires at least one compatible point and
satisfaction at every compatible point. The conclusion is relative to the
supplied population. Model coverage for an external history class is a
separate obligation.

A fixture reuses ACT-03’s missing and contested report statuses alongside
a fixed truth assignment about the same participant. The report and semantic
results are separate observations. Changed evidence, source admission and
translation between profile versions require their own operations and laws.

## Replay

```sh
npm --prefix formal/quint ci
make ida-semantics
```

The gate compiles fixed Lean statements, audits compiled axiom dependencies,
and compares an independent [Quint interpretation](../../formal/quint/ida-semantics.qnt).
It checks 12,800 formula cases, 200 description and inquiry cases, and 280
finite assessments for 27,680 output cells. The seven weakened models reverse
the assignment map, ignore predicate version, conflate rigid namespaces,
ignore sign, change the history during substitution, accept an unsupported
schema, or make inconsistent premises vacuously robust. Exact-head receipts
record the inputs and both output tables.

Cross-profile migration, source-backed semantic interpretation, and admission
of transported concrete evidence have separate contracts. ACT-05 can use the
proved same-history premise transport when it supplies the source derivation
and revalidates the destination evidence and scope.
