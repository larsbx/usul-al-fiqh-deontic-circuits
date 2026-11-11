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

## Authenticated batch replay

The host reuses the [signed source catalog](ida-source-auth.md). Its caller
supplies the current manifest hash, trusted issuer ID and public key,
designated source ID, source root, and trusted Lean evaluator independently
of the candidate bytes. The catalog must contain one whole-file reference
for that source ID. The submitted batch must match its length and both
SHA-256 digests. Authentication and canonical UTF-8 JSON validation finish
before the host calls the evaluator with the exact verified text. The
result carries the manifest hash, issuer and key fingerprint, catalog
version, and authenticated source reference.

The wire version is `usul.ida.omission-observations.v1`. The batch contains
`schema`, `scope`, `reports`, and `coverage`. Reports and coverage inherit
the single batch scope after exact comparison with the resolved current
snapshot. Lean proves the scope encoding has a left inverse and is
injective. A successful typed review requires the exact current snapshot,
the supported wire version, and the exact encoded omission scope. The
current snapshot supplies the effective time and recording cutoff. The
signed batch can therefore be replayed at different valid cutoffs within
the same opportunity scope while its catalog pin is current.

Authentication identifies the issuer's exact submission, including its
coverage claim. The truth and exhaustiveness of that claim, the issuer's
authority to supply observations, production key enrollment and revocation,
and actual opportunity and capacity require separate evidence. The replay
returns an observation assessment. Ruling interpretation and judgment
admission remain separate.

## Replay

Run `npm --prefix formal/quint ci` and `make ida-context`. The gate compares
3,024 omission observations across 18 effective-time and cutoff pairs,
14 report scenarios, and 12 coverage scenarios. It retains the existing
context and agency comparisons. Nine omission mutations challenge coverage,
time and interval boundaries, and exact report scope.

Run `make ida-omission-auth` for the host replay and compiled wire proof
audit. The gate uses the repository's explicitly test-only Ed25519 keys
and synthetic snapshots. Controls include stripped completion, same-length
byte substitution, stale catalog, wrong signer, partial passage, stale
snapshot, changed scope, and unexpected JSON fields. It writes a
revision-bound report and compiled axiom inventory in
`.cache/ida-omission-auth/`.
