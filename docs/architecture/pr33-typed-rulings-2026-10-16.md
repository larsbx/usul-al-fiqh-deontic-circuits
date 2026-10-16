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
before the correction. Both validators now reject that mutation. Direct calls to `resolve` and `attribution` reject the invalid case with
`ValueError` before ranking. The pure kernel retains separate typed sides;
integer zero cannot borrow the Boolean false position's identity.

`takhrij.position_errors` is shared by both validators and checks every supplied
position, including cases outside the reconciliation ledger. A position ruling
must belong to the encoder's declared `out` by PR #90's canonical JSON identity,
or carry an explicit `outside` explanation for a nonempty textual alternative.
`outside` must be a nonblank string. It cannot license numeric/Boolean type
errors, nulls, containers, empty rulings or values already in the output domain.
An exception records an expressiveness gap; it does not extend `out`, alter
`expected`, or turn an annotation into a verified derivation. The explanation
remains candidate scholarly metadata, not proof of its own truth.

All ruling comparisons use the single implementation in `values.py`, re-exported
unchanged as `takhrij.code/among` for compatibility. `reconciliation_kernel.py`
imports only this dependency-free identity module. This covers
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


## Integration of PR #92 and PR #93

PR #92 is the sole integration vehicle. Its pure kernel and compatibility facade
remain; PR #93 contributes the pinned migration, independent Lean guards, stronger
schema check, and adversarial tests. Do not merge the original branches separately.
Once the consolidated #92 passes every acceptance gate, merge it into main and
close #93 as superseded, retaining its discussion and evidence. Until then both
remain drafts; no auto-merge is enabled.

| Boundary | Consolidated decision |
|---|---|
| Identity | `values.code`, using PR #90's canonical sorted JSON encoding; `takhrij.code/among` are aliases. Non-finite floats are rejected by `allow_nan=False`. |
| Architecture | Pure proof/attribution ranking in `reconciliation_kernel`; corpus validation, loading and generation in the `reconcile` facade. Existing imports remain available. |
| Invalid direct calls | #92's fail-closed `ValueError` contract; #93's synthetic comparison tests declare their test domains explicitly. |
| Validation | Shared `position_errors`; reconciliation checks all supplied cases, including those outside its ledger; schema requires a nonblank explanation. |
| Migration | Exactly #93's pinned, idempotent migration: 36 + 17 positions, copying existing case notes. Replaces #92's alternate explanation wording, never applies both. |
| Lean | Unchanged formal kernels; identical generated String identities; retain #93's independent fixed guards and import them from `UsulTest`. |
| Compatibility | Differential replay preserves 2,384 individual policy resolutions and 596 attributions against main `57a3b1c`; both ordered digests are regression-pinned. Reports and historical receipts remain unchanged. |

PR-34 through PR-40 in #91 remain open obligations: this integration does not
repair evidence admission, source adequacy, position-reference stability or the
other audited boundaries. R1–R6 and the existing scholarly review requirements
remain in force. No source locks, exclusions, workflow requirements or acceptance
states are changed.


### Consolidated verification (2026-10-16)

- Python 3.11.17: 112 focused structural/adversarial checks passed, with 3,987
  quotation cases explicitly deselected (`-k 'not verbatim'`), zero skips.
- `make integration`: 69 passed, zero skips; `make integration-external`: 3
  passed, zero skips, using the pinned answer and label archives.
- `make validate`: 52,637 records passed. `make generated`: passed after
  committing the migrated suite receipts; generated artifacts stayed identical.
- Prolog fixture/runner tests, all 61 fixture mutants and all 33 oracle mutants
  passed with SWI-Prolog 10.0.0. All five TLA+ models passed.
- Direct differential replay against the unmodified main resolver confirmed all
  2,384 policy outcomes and 596 attributions, not merely aggregate counts.
- `make source-verify` failed closed: 4,444 verified, 542 excluded, 23 failed;
  required pinned `shamela-11122` and `shamela-22592` are absent. A full-suite
  diagnostic also reached foundation failures; isolated replay of
  `test_albani_verdict_is_his[H-ali-madhy]` fails explicitly for missing
  `shamela-22592`. No full-suite pass is claimed.
- `make lean` fails before elaboration: the installed pinned 4.34.1 toolchain
  reports `could not detect the configuration of the Lake installation`;
  `lean --version` reports `failed to locate application`. Independent guards
  are retained but compilation is not certified.
- Original CI attempts for #92/#93 report failure with no executed step records;
  sampled log retrievals return HTTP 404 `BlobNotFound` and #92 has no retained
  artifacts. #93's second formalization attempt is queued with no steps at the
  last inspection. These observations do not establish the cause of CI failure.

Acceptance requires a successful full required-source replay, complete corpus
suite with the declared exclusions, Lean build/export/no-sorry gate, and green
workflow executions on the consolidated head (including Prolog and TLA+).
Unprotected main is not permission to bypass those declared gates. No merge or
human scholarly acceptance is claimed.


## Subsequent R1 integrity gate

The continuation after integration commit `a41612ff` preserves that consolidation
and adds mandatory ordered-position receipts for every active ledger and weighing
entry. This implements the interim PR-37 integrity gate; stable position IDs and
the remaining evidence-admission work are still open. See the updated
[authority boundaries](separated-concerns.md#remaining-structural-work) and the
[existing roadmap](../roadmap-hanbali-usul-formalization.md#first-principles-refactor).
The earlier validation record above applies to its named integration commit;
subsequent validation is recorded in PR #92. No source, runtime or CI blocker is
closed merely by preserving that record.

## Validation continuation and routing receipt repair

The complete collection at `a41612ff` ran in fresh Python 3.11 processes per
test file, with `USUL_REQUIRE=swipl,islamqa`. All 6,092 collected node IDs
were matched against the resulting JUnit cases: 5,490 passed, 574 explicitly
skipped under existing source rules, and 28 failed. Twenty-seven failures were
missing required witnesses; the remaining failure was a stale generated
classical routing report. This is a completed diagnostic, not a passing suite.
An earlier combined-process run terminated with exit 137; no pass is inferred
from that termination.

Replaying `signature_routing.render(root, classical_only=True)` changes only
three `inputs_sha256` receipts in `corpus/routing/type-aware.json`: the two
migrated suites and `takhrij.py`. Every other report field is identical,
including rankings, metrics, candidate status and blocked modern evaluation.
The original failing replay test remains unchanged. Against `3d4d5d8d` plus
this receipt repair, 69 tests passed across signature routing, typed rulings,
the ruling boundary and position receipts. Schema and generated checks passed.

`make lean` now passes all 111 jobs and the exported-type drift check on both
`a41612ff` and `3d4d5d8d`. The local Lean 4.34.1 launcher needed a container
compatibility shim: only `readlink("/proc/<getpid()>/exe", ...)` is redirected
to the equivalent `/proc/self/exe`. No Lean source, kernel, elaborator, proof
or build target was changed. `UsulTest.TypedRulings` and the generated
reconciliation guards compiled. CI must still execute its ordinary build.

The required `shamela-11122` source was recovered: 832,240 bytes, SHA-256
`38c8158ec7222b650e99db50b0d185fd75663af7d15edbe75a255e9a3ac4f2c9`, exactly
the existing lock. Recovery of `shamela-22592` remains in progress at this
checkpoint. Partial pages are not evidence, and full required-source replay,
the final corpus run and CI remain acceptance gates. Current results and any
subsequent source recovery are recorded in PR #92; no source pin or exclusion
has been changed.

The complete `a57d4a1` collection then executed all 6,110 collected node IDs:
5,520 passed, 555 explicitly skipped and 35 failed. Twenty-six failures require
the remaining `shamela-22592` witness. Nine failures exposed source-verification
test fixtures that predated the new ordered-position receipt requirement.
Those fixtures now supply their case subjects and matching receipts, and assert
a successful source replay before each negative control. All original source
assertions remain; two additional controls reject missing/stale position receipts
even when the source bytes are valid. The source-verification and receipt suites
pass all 52 tests after this fixture repair. Production source verification,
the receipt gate, locks and exclusion rules are unchanged.
