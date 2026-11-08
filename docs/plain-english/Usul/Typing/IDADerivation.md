# Usul.Typing.IDADerivation in Plain English

Source: [`formal/lean/Usul/Typing/IDADerivation.lean`](../../../../formal/lean/Usul/Typing/IDADerivation.lean)

This module evaluates source-bound derivation trees using the existing
[typed judgment records](IDAJudgment.md) and [IDA algebra](../IDA.md). The Lean
implementation and its proofs do not import Quint, consume Quint results, or
depend on a finite replay being successful.

## Claims and authority are separate inputs

A submitted `Premise` contains an arbitrary natural-number question identity and
the complete earlier judgment `Request`. This identity is separate from the
question family: two different questions can both ask for a taklifi answer.
The request retains its source and passage hashes, byte range, interpretation
identity/version, evidence grade, complete scope, and source implementation
revision.

An `Environment` separately supplies the registry, authenticated source catalog,
current interpretation pins, evidence decisions, and verifier implementation
revision. Candidates do not supply admission or authentication flags. A pin is
selected by profile plus interpretation identity and must be unique and exactly
match both the profile and interpretation versions. An evidence decision is
selected by entry identity, must be unique, and must bind the complete premise,
including the question identity and every request field. Identical duplicate
decisions or pins are rejected as ambiguous.

For a source leaf, the evaluator checks these conditions in order:

1. The verifier revision is nonempty.
2. The existing registry validator returns an accepted typed receipt.
3. The source rule has rule identity 1 and no claimed premise identities.
4. The complete source reference occurs in the authenticated catalog.
5. Exactly one current interpretation pin matches.
6. Exactly one evidence decision binds the complete premise and is supported.
7. The typed payload is known.

Missing, suspended, disputed, and unauthenticated evidence are separate blockers.
Missing and suspended payloads remain separate blockers even when their registry
record is admitted and their evidence decision is supported. Registry failures
retain the earlier validator's reason. The source rule check prevents a submitted
leaf from claiming that a derivation has already occurred; the `Tree.both`
constructor supplies the actual derivation structure.

## What conjunction establishes

`Tree.source` and `Tree.both` form arbitrary finite trees. Every evaluation keeps
the exact ordered list of source premises, including all metadata, blocked
leaves, and repeated occurrences. Conjunction concatenates these lists. It does
not replace them with a set or retain only the first successful source.

Before considering inherited blockers, conjunction checks that every source has
the same question identity, question-family code, and complete scope. Scope
equality includes subject identity and both capacity bits, target identity and
kind, context, time, profile/version, and domain. An incompatible combination
prepends an out-of-scope issue to the inherited issue list. Existing blockers are
never silently discarded.

With compatible, known inputs, taklifi answers use the accepted IDA nonempty-set
intersection. A disjoint intersection is a conflict. Cause, condition,
impediment, and validity answers combine only when equal. A result cannot create
a ruling value outside either taklifi premise. No aggregate evidence grade is
invented: every original grade remains attached to its original premise.

Alternative trees are evaluated as an ordered list with the same length. Two
conflicting interpretations can remain two distinct accepted alternatives under
the supplied environment; conjoining them can be a conflict. This API contains
no rule selecting a preferred alternative.

## Acceptance and replay

An `Evaluation` is structurally accepted when it has a typed known conclusion
and no issues. Its classification is then admitted; otherwise it is candidate.
An arbitrary caller can construct an `Evaluation`, so this structural predicate
alone is not authorization. Consumers must obtain a result from `evaluate` or
verify the complete receipt with `verifyReceipt`.

A receipt stores the complete environment, tree, and evaluation. `ValidAt` checks
environment equality and equality with a fresh evaluation under the current
environment; it can describe an accurately recorded blocked evaluation.
`AcceptedAt` additionally requires acceptance. `verifyReceipt_sound` proves that
a successful verifier returned the exact newly computed, accepted result under
the exact current environment. A changed answer, scope, source list, blocker,
tree, evidence decision, registry, or revision cannot reuse an unchanged receipt.

## Kernel-checked guarantees

The fixed contract module separately checks 34 public proof requirements. The
implementation also contains the helper theorems needed to connect these claims.

| Theorems | Meaning |
|---|---|
| `version_issue_none_iff`, `evidence_issue_none_iff`, `authorized_iff` | Authorization requires exact singleton pins and complete supported evidence bindings, in addition to the registry and source checks. |
| `source_accepted_iff`, `admissible_known_payload` | An accepted source has an authorized receipt and a known answer in the correct family. |
| `source_provenance`, `both_provenance`, `provenance_exact`, `leaves_nonempty` | Every finite tree retains exactly its nonempty ordered source-occurrence list. |
| `both_accepted_inputs`, `accepted_every_source`, `accepted_leaf_authority`, `accepted_leaf_admitted` | An accepted root implies that every required leaf passed every authority and known-payload condition. |
| `accepted_homogeneous`, `homogeneous_pairwise`, `incompatible_scopes_rejected` | Any two source occurrences in an accepted tree have equal complete keys. |
| `question_identity_guard`, `context_guard` | Different question identities or contexts cannot be combined into an accepted result. |
| `rejected_leaf_blocks_tree` | A blocked required leaf blocks every enclosing tree. |
| `missing_ruling_blocks_tree`, `suspended_ruling_blocks_tree` | Missing information and suspended judgment cannot become accepted normative answers. |
| `unauthenticated_source_blocks_tree`, `stale_interpretation_blocks_tree` | Authentication and current-version checks cannot be bypassed by a derivation. |
| `non_admitted_leaf_blocks_tree`, `substituted_record_blocks_tree` | Candidate, quarantined, revoked, or substituted records cannot be promoted by conjunction. |
| `unsupported_evidence_blocks_tree`, `unauthorized_evidence_promotion` | Unsupported or incompletely bound evidence cannot become an accepted root. |
| `provenance_grades_preserved` | The full ordered list of source grades is unchanged. |
| `taklifi_intersection_exact`, `taklifi_subset_both`, `sign_agreement` | Known conjunction uses exact intersection or exact agreement, as appropriate to the answer type. |
| `source_conclusion_key`, `combine_conclusion_keys`, `both_conclusion_left`, `conclusion_has_source_key`, `accepted_conclusion_scope` | A returned accepted conclusion has the exact question and scope of every source. |
| `isAccepted_iff`, `classification_admitted_iff` | The Boolean and classification accessors agree with the structural acceptance predicate. |
| `alternative_order`, `alternatives_length`, `alternatives_provenance` | Alternatives and their source lists retain their original order without selection. |
| `receipt_valid_original`, `replay_recalculates`, `receipt_accepted_iff` | Original receipts replay and acceptance is recomputed. |
| `valid_receipt_binds_environment`, `valid_receipt_binds_output`, `changed_revision_rejects_receipt`, `changed_result_rejects_receipt` | Receipt integrity binds the full authority environment and complete derived output. |
| `accepted_receipt_sources`, `verifyReceipt_sound` | Successful receipt verification implies fresh accepted evaluation and all-source admissibility. |

## Conditional boundary

Catalog membership is a formal authentication assumption about a separately
supplied environment. This module does not implement SHA-256, verify a catalog
signature, identify an authorized issuer, or prove that a revision string names
the executing Git commit. The external source adapter and revision-bound gate
record those additional checks, including the exact synthetic bytes used by the
finite replay. The formal receipts alone make none of those claims.

Evidence classifications and registry admission remain supplied decisions.
Formal derivation validity does not establish that a juristic interpretation is
correct, settle disagreement, or admit a real legal interpretation. The model
has no agency integration. See the
[source derivation contract](../../../research/ida-source-derivations.md) for the
review scope and remaining obligations.

`target_guard` rejects required leaves with different tagged targets.
`accepted_leaf_target` establishes structural validity for each accepted leaf.
The existing authority and conclusion-scope theorems apply to the full target.
