# Usul.Typing.IDAOmissionSemantics in Plain English

Source: [`formal/lean/Usul/Typing/IDAOmissionSemantics.lean`](../../../../formal/lean/Usul/Typing/IDAOmissionSemantics.lean)

This module proves conditional adequacy of the actual omission observation
evaluator against an independently supplied event history. A covered negative
observation implies that the history contains no qualifying completion when
every qualifying completion would have a timely report. The reverse implication
requires truthful matching reports and the evaluator's remaining structural
gates. These directions have different assumptions.

The declarations use the `Usul.IDA.Omission.Semantics` namespace and import the
type-layer [omission evaluator](IDAOmission.md). They have no categorical or
fixture dependency. The twelve named theorems extend the guarded-context paper
separately from its original 26 general and 19 native counterexample theorems.

## 1. Events and reports are separate inputs

| Definition | Meaning |
|---|---|
| `Event` | One exact native omission scope, one supported performance mode, and an occurrence time. The scope retains the action, parties, opportunity, definition, digest, and clock version. |
| `History` | A predicate on events, supplied independently of the report list. It states which modeled events belong to that history. |
| `eventOf` | The event content described by a completion report. The report's recording time is not an event field. |
| `Represents` | A report and an event have exactly the same scope, mode, and occurrence time. This content correspondence alone does not make the event true in the history. |
| `Qualifies` | The event belongs to the history, has the queried exact scope, and occurs in its half-open opportunity, including the opening tick and excluding the closing tick. |
| `NoQualifying` | No event in the supplied history qualifies for that scope. |
| `Exhaustive` | Every qualifying event has a representing report in the supplied list, recorded no earlier than occurrence and by the declared cutoff. |
| `SoundFor` | Every report that actually matches this observation describes an event in the supplied history. Unrelated, future, and nonmatching reports need not satisfy this premise. |

`Qualifies` concerns the entire opportunity. Effective closure is used to show
that a timely report for any qualifying event also passes the evaluator's
effective-time bound. The recording cutoff remains a separate limit on report
visibility.

`Event` records bounded event content; it does not assign a globally unique
physical event identity. A supplied `History` may describe a stipulated model.
Interpreting it as the actual history, and justifying the scope and reporting
assumptions, requires evidence outside these definitions.

## 2. Conditional adequacy

| Theorem | What it establishes |
|---|---|
| `covered_no_completion_sound` | If the evaluator returns `coveredNoCompletion` and reporting is `Exhaustive`, there is no qualifying event in the supplied history. Report soundness is not needed for this direction. |
| `covered_no_completion_complete` | If no event qualifies, matching reports are `SoundFor` the history, no visible in-scope report is malformed, the effective window is closed, and `Coverage.Complete` holds, the evaluator returns `coveredNoCompletion`. Exhaustiveness is not needed for this direction. |
| `covered_no_completion_iff` | With both reporting assumptions and all three structural gates, the covered negative observation is equivalent to absence of qualifying events in the supplied history. |
| `review_covered_no_completion_sound` | A successful native review with a covered negative outcome resolves the exact current snapshot and entails absence in the supplied history, given the extracted scope and its independent exhaustiveness premise. |

The forward proof uses the existing evaluator theorem `covered_iff` to obtain
a closed window and absence of matching reports. Any hypothetical qualifying
event would, by exhaustiveness and closure, yield such a report, contradicting
that absence. The reverse proof uses report soundness to rule out matching
reports, then supplies the remaining structural gates to `covered_iff`.

## 3. Supporting correspondence laws

| Theorem | What it establishes |
|---|---|
| `eventOf_scope`, `eventOf_mode`, `eventOf_occurredAt` | Extracting event content preserves the three corresponding report fields. |
| `represents_iff` | Representation is exactly equality of scope, mode, and occurrence time. |
| `completion_matches_iff` | Native matching is equivalent to exact scope, cutoff visibility, valid chronology, the half-open interval bounds, and the effective-time bound. |
| `matches_of_qualifies` | A timely, chronological report representing a qualifying event matches once the entire opportunity is effectively closed. |
| `qualifies_of_matching` | A matching report describes a qualifying event under the explicit soundness premise. |
| `matching_report_of_qualifying` | Exhaustiveness and closure turn any qualifying event into a representing report that matches the native evaluator. |

## 4. What remains to justify

Native `Coverage.Complete` checks a supplied claim's exact scope, two supported
modes, and recording bounds. It does not prove `Exhaustive` or `SoundFor`.
Authentication of submitted bytes also does not prove either semantic premise.
The [synthetic controls](../../UsulTest/IDAOmissionSemantics.md) show how these
requirements can fail independently while the other assumptions hold.

The next application step is to establish the reporting assumptions for an
independently specified event source and observation adapter. Correspondence
between this event history and ACT-04's predicate truth assignment in
[IDASemantics](IDASemantics.md) is a separate interpretation obligation. The
theorems do not establish actual opportunity, capacity, culpability, an admitted
case, a juristic ruling, or the full ACT-08 exit.
