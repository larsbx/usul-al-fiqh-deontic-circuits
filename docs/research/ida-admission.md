# ACT-05 contextual premise admission

This bounded implementation follows the accepted [context theory](ida-context-theory.md#3-conditional-derivation-and-premise-admission)
and builds on [ACT-04](ida-semantics.md). The pilot reconstructs formulas of
typed signed atoms and conjunctions under the same interpretation. It
allows an explicit destination subject ID, context ID, and admission policy.
The question, profile, temporal frame, and registered definition stay fixed
within the route. The synthetic witness swaps two person slots in a repayment
inquiry and requires independently admitted destination evidence.

The plan retains the original derivation, the typed premise arrow, and both
valuations. Substitution followed by cut reconstructs the conclusion using
destination assumptions. The fixed-history soundness proof applies only to
histories satisfying those assumptions. The checked receipt also identifies
the exact grounded formula to which that theorem applies.

Both ends are checked against one current authority. Each side binds the full
ACT-01 snapshot, all typed valuation slots, ordered grounded premise
occurrences, and grounded conclusion. For each certificate, exact membership
under a unique authenticated token precedes source evaluation in
`Derivation.Environment`. That evaluator checks the existing judgment registry,
source catalog, interpretation pins and exact evidence decision. A grant for
the exact application and certificate list is separately required. Failure records the stage and both submitted certificate lists and
keeps the existing source admission reason where applicable.

The Lean boundary consumes a trusted authenticated certificate catalog.
A token is a handle for an externally authenticated payload. The ACT-05
model checks equality against the entire payload, including the exact
source-bound premise, and rejects attaching an existing token to changed
content. The existing signed source-catalog verifier can authenticate source
references used by the judgment environment. A production verifier and
canonical signing format for the new contextual certificates and grants
remain outside this tranche.

Reconstruction produces an in-memory, plan-indexed receipt retaining both
applications, both certificate lists and the authority that checked them.
Replay requires equality of the complete authority and recomputes admission.
A new context or authority requires a fresh checked receipt. The formula
language has no bridge to publishing a concrete juristic ruling and the
pilot adds no write path to the judgment registry. The scope excludes
cross-profile and cross-time transport, conflict resolution across
alternatives, and persistent receipt serialization.

Run `npm ci` in `formal/quint`, then `make ida-admission` from the repository
root with the pinned Lean toolchain. The gate audits compiled transitive
axioms, compares the exact control codes with an independent Quint model,
checks 32 bounded authority combinations, and requires weakened-model
controls to fail their assertions.
