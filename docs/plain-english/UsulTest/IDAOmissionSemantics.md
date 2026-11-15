# UsulTest.IDAOmissionSemantics in Plain English

Source: [`formal/lean/UsulTest/IDAOmissionSemantics.lean`](../../../formal/lean/UsulTest/IDAOmissionSemantics.lean)

This suite checks the conditional omission-adequacy contracts against the
actual native evaluator and constructs controls that separate their assumptions.
It imports [IDAOmissionSemantics](../Usul/Typing/IDAOmissionSemantics.md) and the
earlier [native omission witness](IDAOmissionGuardWitness.md). Its 17 named
theorems are a new extension; they do not change the original paper's 26 general
and 19 native theorem counts.

## 1. A fixed scope and two independent histories

The fixture reuses the synthetic repayment scope with opportunity `[0,10)`.
`actualEvent` describes a direct completion at tick 5 in that exact scope.
`emptyHistory` contains no events, while `actualHistory` contains that event.
The identifier `actualHistory` names a stipulated test model, not an externally
verified account of a real case. Both histories are supplied independently of
the report list.

| Report | Occurrence | Recording | Role in the controls |
|---|---:|---:|---|
| `truthfulReport` | 5 | 5 | Represents the event in `actualHistory`; the same content is unsound relative to `emptyHistory`. |
| `malformedReport` | 5 | 4 | Claims occurrence after recording, so its visible chronology is invalid. |
| `lateReport` | 5 | 20 | Represents the event truthfully in `actualHistory` but is invisible at cutoff 15. |

Unless stated otherwise, both effective time and recording cutoff are 15.
`completeCoverage` is the earlier fixture's exact-scope claim, recorded at
closure and naming both native performance modes. Its structural validity is
separate from semantic exhaustiveness.

## 2. Explicit contracts and positive controls

| Theorem | What it establishes |
|---|---|
| `actual_event_qualifies` | The stipulated event belongs to `actualHistory`, has the exact scope, and lies within the opportunity. |
| `empty_no_qualifying` | The empty history has no qualifying event at any scope. |
| `empty_exhaustive` | Reporting is vacuously exhaustive for an empty history, for any supplied report list and cutoff. |
| `empty_reports_sound` | An empty report list satisfies matching-report soundness for any history. |
| `forward_statement_contract` | Restates the forward implication with the history, qualification bounds, representation equality, chronology, and cutoff assumptions written out, then invokes the production theorem. |
| `reverse_statement_contract` | Independently states absence, matching-report truth, and the three structural gates required for the reverse implication. |
| `equivalence_statement_contract` | Independently states the full equivalence, retaining both reporting assumptions and all structural gates. |
| `closed_empty_history_covered` | The empty history and empty reports satisfy the reporting assumptions and produce `coveredNoCompletion` with the complete structural coverage claim. |
| `truthful_report_observed` | The one-event history and its timely report satisfy exhaustiveness, soundness, and valid chronology; the evaluator returns `completionObserved`. |

The three contract declarations expand the convenient semantic predicates in
their statements. Their proofs must continue to elaborate against the actual
production theorems, so they check more than an additional alias for those
theorem types.

## 3. Why the assumptions are separate

Each necessity theorem proves the other relevant hypotheses in its bundle.
These are concrete counterexamples to dropping the named condition from the
stated implication.

| Theorem | Missing condition and resulting observation |
|---|---|
| `completeness_needed` | A qualifying event in `actualHistory` has no report. The structural coverage claim passes and the evaluator returns `coveredNoCompletion`, but reporting is not exhaustive. Thus the forward semantic conclusion fails without exhaustiveness. |
| `soundness_needed` | The same timely report is supplied with `emptyHistory`. Absence, exhaustiveness, chronology, closure, and structural coverage hold, but report soundness fails and the evaluator returns `completionObserved`. |
| `chronology_needed` | The malformed report is supplied with `emptyHistory`. Exhaustiveness and matching-report soundness still hold, as do closure and structural coverage, but the evaluator returns `invalidObservation`. |
| `closure_needed` | Effective time is 9 while the cutoff remains 15. Semantic absence, both reporting assumptions, valid chronology, and structural coverage hold, but the window is effectively open and the evaluator returns `pending`. |
| `structural_coverage_needed` | The history and report list are empty and the window is closed, but the coverage argument is `none`. Semantic exhaustiveness and soundness hold while the evaluator returns `coverageMissing`. |

`late_report_not_exhaustive` further checks the cutoff boundary. A report can
represent the right event and have valid chronology yet arrive too late to
provide exhaustive reporting at the queried cutoff. The existing evaluator
then returns `coveredNoCompletion` with the structural coverage claim despite
the qualifying event in the supplied history. The missing premise is timely
exhaustiveness.

## 4. A payload does not select its semantic history

| Theorem | What it establishes |
|---|---|
| `same_payload_different_histories` | The same exact scope, times, empty report list, and complete structural coverage claim produce a covered negative observation. Absence holds in `emptyHistory` and fails in `actualHistory`. |
| `payload_authentication_does_not_imply_absence` | Conditional on any payload-only authentication predicate accepting that fixed payload, there exists an independently supplied history in which the same accepted payload and observation coexist with a qualifying event. |

The authentication statement assumes acceptance by a predicate of the scope,
times, reports, and coverage. It neither constructs a newly signed batch nor
assumes a forged signature. It identifies the missing relation between the
submitted observation content and the independently supplied history.

These controls do not justify a real observation mechanism, a concrete history,
actual capacity, culpability, case admission, or a juristic ruling. The next
application obligation is to derive the production `Exhaustive` and `SoundFor`
premises from an independently specified event source and observation adapter.
