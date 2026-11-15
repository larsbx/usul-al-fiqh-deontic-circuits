# UsulTest.IDAGuardedContext in Plain English

Source: [`formal/lean/UsulTest/IDAGuardedContext.lean`](../../../formal/lean/UsulTest/IDAGuardedContext.lean)

This paper supplement characterizes when a representation can forget information
while preserving every comparison with a complete contextual key. The key must
be recoverable from the representation on its image. Preserving an evaluator's
output requires a separate condition. The module contains 26 named theorems in
the namespace `IDAContextDescent` and is included in the `UsulTest` compiled audit.
The [guarded-context manuscript](../../research/ida-guarded-context-preservation.md)
explains the paper argument and its relation to the accepted context theory.

## 1. What the criterion compares

An input `X` may carry more information than its guarded key `κ x`. A projection
`e` maps inputs to a simpler representation. `FiberConstant e κ` says that inputs
with the same representation have the same key. `AllScopeTestsPreserved e κ`
says that any two such inputs agree on every test of the form “is the key exactly
q?” These conditions are equivalent.

`DescendsToImage e κ` expresses the same fact as a factorization: there is a
function from the values actually attained by `e` that reconstructs the key.
Restricting that function to the image avoids assigning unsupported values
outside the represented domain. Constructing it uses classical choice;
agreement on fibers makes its value independent of the chosen preimage.

This is a criterion for the supplied projection and key. It does not prove that
an arbitrary serializer, display, context identifier, or digest satisfies it.
Inputs may be restricted to a subtype representing a chosen supported domain.
For question-indexed outputs, the output theorem requires a fixed answer type
or an explicit tagged carrier containing the question and its answer.

## 2. General theorems

All names below are in `IDAContextDescent`.

| Theorem | Plain English |
|---|---|
| `descends_iff_fiberConstant` | An output can be reconstructed from the projection's image exactly when it agrees on each projection fiber. |
| `descended_map_unique` | Two reconstructions agreeing on every projected input are the same function on the image. |
| `all_scope_tests_iff_key_fiberConstant` | Preserving every exact-key test is equivalent to retaining the key on each fiber. |
| `scope_guard_descent_criterion` | Every exact-key test is preserved exactly when the complete key can be reconstructed from the projected representation. |
| `paired_fiberConstant_iff` | A pair consisting of a key and an output is constant on fibers exactly when each component is. |
| `guarded_output_descent_criterion` | Reconstructing both the key and the output requires both exact-key preservation and output agreement on fibers. |
| `descended_guard_exact` | A reconstructed key preserves and reflects equality between any two original keys. |
| `identity_key_descent_iff_injective` | When the input consists only of the key, recovering that key is equivalent to injectivity of the projection. |
| `no_descent_of_fiber_counterexample` | Two inputs with equal projections but unequal outputs rule out a reconstruction of those outputs. |

The injectivity condition applies to inputs that are themselves keys. It is
unnecessarily strong for richer snapshots that also contain irrelevant
annotations; the final two controls below demonstrate this distinction.

## 3. Typed target model and seven coordinates

The example language has a repayment action with two person arguments and one
obligation argument, an omission carrying a named occurrence and clock with
opening and closing bounds, and an affect carrying a quality and typed object.
These are separate constructors. No constructor assigns a ruling.

A scope retains question, accountable subject, target, context, time view,
interpretive profile, and profile version. String identities and the simple
time view in this model are declared representations, not fully interpreted
juristic concepts. This small model is separate from `Usul.IDA`'s actual target
and key types; the companion [native omission witness](IDAOmissionGuardWitness.md)
uses those repository types directly.

| Theorem | Plain English |
|---|---|
| `exact_guard_iff_seven_coordinates` | Exact scope equality is equivalent to agreement in all seven represented coordinates. |
| `perform_ne_omit` | A performance target cannot equal an omission target. |
| `perform_ne_affect` | A performance target cannot equal an affect target. |
| `omit_ne_affect` | An omission target cannot equal an affect target. |

## 4. A complete-history window counterexample

The synthetic history is stipulated to contain one matching repayment at tick
7. The two candidate descriptions use the same action, occurrence and clock,
but their windows are `[0,5)` and `[0,10)`. Both windows have closed by the
retrospective observation cutoff 10. The first contains no matching event;
the second contains the event at 7. Erasing the window bounds identifies their
otherwise equal scopes while their evaluated omission values differ.

| Theorem | Plain English |
|---|---|
| `short_window_wellFormed` | The shorter opportunity has strictly ordered bounds. |
| `long_window_wellFormed` | The longer opportunity has strictly ordered bounds. |
| `windows_closed_at_observation` | Both opportunities close no later than the observation cutoff. |
| `erased_scope_collision` | The two scopes become equal after their window bounds are erased. |
| `complete_scopes_differ` | Their complete scopes are distinct. |
| `short_window_omission` | The fixed complete history contains no matching event in the shorter window. |
| `long_window_non_omission` | The same history contains a matching event in the longer window. |
| `omission_value_differs` | The two omission evaluations differ. |
| `omission_erasure_breaks_exact_guard` | Erasing these bounds fails to preserve all exact-key tests. |
| `omission_key_does_not_descend` | The full key cannot be recovered from this erasure for every input. |
| `omission_truth_does_not_descend` | The stipulated-history omission value cannot be recovered from this erasure for every input. |

The last result is conditional on the explicitly defined complete toy history.
It does not infer real nonperformance from an empty event log, claim that the
candidate descriptions are admitted by the repository, or determine which
description is factually correct.

## 5. Harmless information loss and the proof boundary

| Theorem | Plain English |
|---|---|
| `annotation_erasure_preserves_scope_tests` | Dropping a Boolean annotation attached to a scope preserves every exact scope comparison. |
| `annotation_erasure_not_injective` | That safe projection is nevertheless noninjective on the annotated input type. |

The module proves an abstract preservation criterion and explicit controls.
It supplies no premise authentication, authority decision, source interpretation,
cross-profile migration, actual omission assessment, or juristic ruling.
The separate repository-native witness checks information loss against the
implemented observation evaluator. Each new integration requires its own
compiled acceptance receipt; the earlier standalone audit remains evidence
only for the source and toolchain it recorded.
