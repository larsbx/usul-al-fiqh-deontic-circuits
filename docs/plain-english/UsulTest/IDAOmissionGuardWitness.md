# UsulTest.IDAOmissionGuardWitness in Plain English

Source: [`formal/lean/UsulTest/IDAOmissionGuardWitness.lean`](../../../formal/lean/UsulTest/IDAOmissionGuardWitness.lean)

This paper supplement uses the actual `Usul.IDA` target and key types and the
actual `Usul.IDA.Omission.evaluate` observation kernel. It proves that erasing
opportunity bounds, or erasing supplied coverage, can lose distinctions needed
by that evaluator. Its 19 named theorems are in `IDAPaper.NativeOmission` and
participate in the `UsulTest` compiled audit. The general reconstruction
criterion is explained in [IDAGuardedContext](IDAGuardedContext.md), and the
paper argument is in the [guarded-context manuscript](../../research/ida-guarded-context-preservation.md).

## 1. The native interval witness

The synthetic repayment names the same debtor, creditor, and obligation in
both descriptions. It retains the same accountable person, performer role,
occurrence, clock, definition, digest, and clock version. Its two candidate
opportunities differ only in the closing bound. At effective time and recording
cutoff 15, with no completion reports and no coverage claim, the results are:

| Opportunity | State at time 15 | Repository observation result |
|---|---|---|
| `[0,10)` | Closed | `coverageMissing` |
| `[0,20)` | Still open | `pending` |

`WithoutBounds` retains every field of the omission scope except the opening
and closing times. `eraseBounds` sends both inputs to the same value. Since the
actual evaluator distinguishes them, no function of that erased value can
reproduce the evaluator on every structurally well-formed action and opportunity.

| Theorem | Plain English |
|---|---|
| `repayment_wellFormed` | The named repayment operands match the declared typed role signature. |
| `earlyOpportunity_wellFormed` | The first opportunity has valid names and strictly ordered bounds. |
| `lateOpportunity_wellFormed` | The second opportunity has valid names and strictly ordered bounds. |
| `erased_bounds_equal` | The two native scopes become equal after their bounds are erased. |
| `early_window_closed` | The first opportunity is closed at effective time 15. |
| `late_window_open` | The second opportunity remains open at effective time 15. |
| `early_observation` | The first evaluation returns `coverageMissing`. |
| `late_observation` | The second evaluation returns `pending`. |
| `observations_differ` | The implemented observation outputs are unequal. |
| `no_evaluator_after_erasing_bounds` | No evaluator of the erased scope agrees with all these native evaluations, even when inputs have well-formed actions and opportunities. |

## 2. Connection to the seven-coordinate guard

Both native keys have equal question, subject, context, time, profile, and
version coordinates. Their structured omission targets retain their different
window bounds. The existing IDA scope guard therefore rejects their combination
for every pair of premise payloads, including missing or suspended inputs.

| Theorem | Plain English |
|---|---|
| `other_six_coordinates_equal` | All six non-target key coordinates agree. |
| `target_expressions_differ` | The complete omission expressions differ. |
| `targets_differ` | Their structured key targets differ. |
| `keys_differ` | The complete seven-coordinate keys differ. |
| `guarded_combination_rejects` | Actual `Usul.IDA.combine` returns `outOfScope` for these keys, regardless of the two supplied payloads. |

## 3. Coverage is a separate evaluator dependency

Hold the first closed scope, both times, and the empty report list fixed. A
coverage claim recorded at closure that matches the exact scope and names both
modeled completion modes changes the output to `coveredNoCompletion`. Dropping
the coverage input therefore loses a distinction even while the entire
omission scope remains equal.

| Theorem | Plain English |
|---|---|
| `complete_coverage_well_scoped` | The supplied claim satisfies the evaluator's scoped, timely, two-mode coverage condition. |
| `covered_observation` | The evaluation with that claim returns `coveredNoCompletion`. |
| `coverage_changes_observation` | The no-coverage and complete-coverage outputs differ at the same scope. |
| `no_evaluator_after_erasing_coverage` | No single output at this fixed scope can reproduce the result for every supplied coverage argument. |

## 4. What the proofs establish

These are synthetic observation-kernel results with structurally well-formed
targets. They do not construct authenticated admitted `Context.Snapshot`
applications. The incompatible closing bounds are candidate descriptions of
one named occurrence; the proofs do not decide which description is correct.
The two-mode coverage claim is an input whose truth and exhaustiveness are not
proved. Consequently `coveredNoCompletion` establishes no actual nonperformance,
capacity, culpability, or juristic ruling.

The earlier local audit records the November 11 source baseline and toolchain.
This repository integration is checked through its own compiled source and
axiom inventory; a historical receipt is not fresh hosted acceptance for a
changed revision.
