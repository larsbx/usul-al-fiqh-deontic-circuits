# PR-33: typed rulings and explicit range gaps

Implementation against main `57a3b1c406102dd9812e20bbe08b70c9232cb551`, after
PR #90. This addresses step 1 of the audit proposed in
[PR #91](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/pull/91).
It does not close the audit's other findings or claim scholarly approval.

## Reproduction and correction

For `ibn_lahham.qawaid_fawaid.openiti_lahham_shamela8526.q043.f005`, the original
case resolves to `tawaqquf`. Replacing position 0's `true` with integer `0`
passed both `takhrij.check_case` and `reconcile.check` and resolved to
`tarjih(0)` at the baseline. The initial adversarial suite produced 23 failures
before the correction. Both validators now reject that mutation. Even direct
use of the resolver leaves those distinct, equally supported sides at
`tawaqquf`; integer zero no longer borrows the Boolean false position's identity.

`takhrij.position_errors` is shared by both validators and checks every supplied
position, including cases outside the reconciliation ledger. A position ruling
must belong to the encoder's declared `out` by PR #90's canonical JSON identity,
or carry an explicit `outside` explanation for a nonempty textual alternative.
`outside` must be a nonblank string. It cannot license numeric/Boolean type
errors, nulls, containers, empty rulings or values already in the output domain.
An exception records an expressiveness gap; it does not extend `out`, alter
`expected`, or turn an annotation into a verified derivation. The explanation
remains candidate scholarly metadata, not proof of its own truth.

All ruling comparisons in reconciliation now use `takhrij.code`, including
deduplication, proof tiers and advantages, attribution support, standing,
contradiction evidence, refinement checks and report comparisons. Metadata such
as `who`, `detail` and `outside` does not contribute to ruling identity.

## Preserved annotations

The pinned, replayable `python -m usul_corpus.migrate_pr33` migration adds only
`outside` metadata, using each case's existing note as its explanation:

| Suite | Positions | Existing scope |
|---|---:|---|
| `sadi_furu.json` | 36 | q160 `lots` alternatives outside `toEntitled`, `divide`, `lot` |
| `r2_sample1_lane_b.json` | 17 | 15 narrative positions in seven `missing_rule` cases and two in the scoped `m00518` component guard |

No ruling, holder, position order, classification, fact, expected value, proof,
source pin or historical receipt is changed. The migration checks the original
suite hashes, is idempotent on its own output, and refuses other edits. The
historical audit test verifies each new explanation against its case note and
checks the range gap before omitting this metadata from its original semantic
comparison. The original audit remains intact.

PR #90's q160.f031 split is preserved: position 0 is Abū Bakr's lineage-lost
view; position 3 is Ibn Ḥāmid's choice-at-puberty view. Attribution still favours
position 0 and proof weighing remains `tawaqquf` under all four policies.

## Lean boundary

`Usul.Tarjih` and `Usul.Reconcile` remain unchanged. Their generic equality now
receives Strings containing canonical JSON ruling keys from Python. This also
separates a Boolean `true` from the string `"true"`, which the former emitter
collapsed. Object keys are sorted as in PR #90. The generated reconciliation
guards replay all 596 entries under all four policies, with attribution guards
beside them. Independent fixed guards in `UsulTest.TypedRulings` test Boolean /
integer / string distinctions, equal-tier ties and unequal-tier winners.

The regenerated reconciliation report is unchanged: 20 jamʿ, 1 naskh, 235
tarjīḥ and 340 tawaqquf. The sheaf report remains 675 obstruction records and
36 positions outside the reading. The worklist generator refreshes only the
two changed suite hashes.

## Validation and integration boundary

Validation results and environment limits are recorded in the correction PR.
Required source replay, Lean compilation and CI are gates before integration;
neither absent pinned bytes nor a runner/toolchain startup failure is a pass.
No source exclusions, lock digests, workflow gates or evidence requirements
have been relaxed. The PR remains a draft until its unresolved gates pass.
