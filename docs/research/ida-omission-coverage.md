# ACT-08 bounded omission observation

This slice implements the observation-coverage obligation in the
[accepted context theory](ida-context-theory.md#8-omission-capacity-and-resources)
and [ACT-08 pilot](ida-act-classification-roadmap.md#act-08--run-the-first-complete-pilot).
It complements the separate candidate agency replay.

## Scope and time

The review first resolves the exact current ACT-01 snapshot. A current
snapshot with no omission opportunity yields no omission assessment. The
observation scope binds the structured action and named operands, accountable
person, performer, definition version and digest, occurrence, clock and
clock version, and both opportunity bounds.

An opportunity is half-open, with the opening tick included and the closing
tick excluded. Effective time governs both closure and which performances can
answer the inquiry. The recording cutoff governs what the evaluator can see.
Later evidence can change a retrospective answer about a past tick. A later
effective performance cannot answer an earlier inquiry even if its report is
visible retrospectively.

## Coverage and outcomes

The fixture recognizes direct and alternate performance. A completion report
of either mode can establish an observed completion when it matches the exact
scope and its chronology is valid. Duplicate reports contribute the same
existence observation. A visible in-scope report that claims a performance
after its own recording tick makes the observation input invalid.

A coverage claim names the exact scope, declares both modeled performance
modes, and was recorded at or after closure and by the current cutoff.
An empty list, a claim for one mode, repeated entries for one mode, or an
otherwise mismatched claim supplies insufficient coverage.

| Status | Meaning in this observation model |
|---|---|
| `invalidObservation` | A visible in-scope report has impossible chronology. |
| `completionObserved` | At least one matching completion is visible and effective in the queried window. |
| `pending` | No matching completion is visible yet and the effective window is open. |
| `coverageMissing` | The effective window is closed and the supplied coverage is insufficient. |
| `coveredNoCompletion` | The effective window is closed and the complete supplied observation view has no matching completion. |

Lean proves the exact conditions for the covered result, both boundary
laws, precedence of a visible completion, and invariance under appending
an unseen report. The snapshot adapter proves current snapshot resolution
on successful review. Its compiled controls cover a stale snapshot and a
current non-omission inquiry.

The completeness claim is a supplied premise of this bounded observation
model. Authenticating that claim, establishing actual opportunity and
capacity, and interpreting unobserved performance or deliberate abstention
have separate obligations. The review issues an observation status and
does not publish a ruling or write a judgment registry entry.

## Replay

Run `npm --prefix formal/quint ci` and `make ida-context`. The gate compares
3,024 omission observations across 18 effective-time and cutoff pairs,
14 report scenarios, and 12 coverage scenarios. It retains the existing
context and agency comparisons. Nine omission mutations challenge coverage,
time and interval boundaries, and exact report scope.
