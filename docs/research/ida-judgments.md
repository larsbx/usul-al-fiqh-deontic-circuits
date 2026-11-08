# IDA: typed, source-bound judgment replay

This is the second executable slice of the
[Islamic Deontic Algebra specification](islamic-deontic-algebra-spec.md), built
on the [algebra and partial-ruling foundation](ida-foundation.md).
It makes a source-import record replayable under an explicit trusted snapshot.
The rule proves binding and typing properties; it does not decide which legal
interpretation should be admitted.

## What the record binds

A judgment answers a particular kind of question. The implementation reuses
`Usul.Question` and `Question.Answer`: taklifi questions refer to the five
rulings; sabab, shart and mani questions have Boolean answers; validity refers
to fasid and sahih. Each may carry a nonempty set of possible answers. No ruling,
suspension, conflict and out-of-scope records remain separate alternatives.

The replay record binds the question kind, inquiry ID, and complete scope, answer, source ID,
source digest, passage locator, passage digest, interpretation ID and version,
evidence-grade label, and implementation revision. The derivation is currently
only `source_import_v1`, carrying a frozen copy of this record and a schema tag.
The two digests use SHA-256 syntax. Comparing them with a supplied reference
does not establish that a trusted provider actually hashed the claimed bytes.
The recorded implementation revision is provenance about the record's producer;
the gate separately records the actual implementation revision it executes.

The trusted snapshot is a **separate input** containing the current requested
scope, registered source, source-enabled flag, and admission entry. The entry
binds the full claim to the current authoritative admission decision, including
interpretation/version and implementation provenance. Only `admitted` permits replay;
`candidate`, `quarantined` and `revoked` do not. A submitted status label cannot
change that decision.

Rebinding a claim and its receipt together is insufficient: the admission entry
must still bind that same claim. This checks, for example, changing the answer,
question, source digest, interpretation version, implementation revision or
profile version while attempting to retain earlier admission.

Successful replay returns the decoded judgment. Successful replay of a conflict
record remains a conflict, and successful replay of a no-ruling record supplies
no known answer. The result is not a certificate that a ruling follows the
source, nor an application authorization.

## Verification contract

Lean states binding invariants over arbitrary records and snapshots. An
independently written Quint model checks the specified finite cases. The
[wire contract](ida-judgments-wire.md) fixes the tags, validation priority, and
29,376 comparison inputs: six question tags, 36 answer tags, four admission
states, and 34 base or perturbed fixtures.

The comparison includes all five question types, invalid tags, changes to every
record field, retained derivations, coherent attacker rewrites, disabled sources,
stale requested scope, malformed references and self-reported admission. It is a
complete comparison of this declared family, not enumeration of arbitrary
strings or all possible combinations of changes.

Acceptance additionally requires explicit proof-obligation names and fixed
proposition-type witnesses, compiled axiom and import auditing, parser-derived
Quint dependency inventories, independent
contract examples, malformed export controls, and semantic mutants that must
typecheck before failing their designated assertions. A parser error or an
unavailable tool does not count as rejection of a semantic mutant.

Successful export codes are computed from the decoded verdict's typed membership
decisions. Universal decoder and replay theorems preserve both the question kind
and answer code, and reject question or answer tags above the declared domains.
Separate member-semantics proofs pin the five ruling bits, false/true for each
Boolean question, and fasid/sahih; paired serialization mistakes cannot satisfy
these propositions merely by cancelling each other. Compiler rejection controls
also attempt a ruling in the validity carrier and a sabab verdict in the shart
question type.

## Reproduce

Use the repository's pinned Lean toolchain and pinned Quint dependencies:

```sh
npm --prefix formal/quint ci
make ida
make ida-judgment
```

The judgment gate writes `.cache/ida-judgment/report.json`, the compiled axiom
inventory, deterministic test results and both independent exports. Every
receipt bundle includes the revision, input hashes, tool versions, finite bounds and
runtime loader overrides, if any. The gate removes stale successful receipts
before checking and verifies that inputs do not change during replay.

`inputs_match_head: false` identifies worktree evidence. The dedicated hosted
workflow requires it to be `true` and also checks the recorded revision against
the checked-out head. Scoped acceptance remains separate from repository-wide
CI, the existing agency pilot and merge acceptance.

## Trust and remaining obligations

The snapshot's trust is a precondition: local code can construct arbitrary
snapshots. The current model has no credentials, signatures, policy for who may
admit, registry lookup, revocation transaction or durable store. It establishes
that fixed trusted inputs cannot be bypassed by modifying the submitted record.
Question-indexed typing is not `Usul.Judgement.WellTyped` or a proof of capacity,
voluntary control, premise satisfaction or source correspondence. Those require
their own admitted premises and inference rules.

The following remain separate tasks:

- Obtain source bytes and resolve each passage; verify their digests before
  constructing an enabled reference.
- Authenticate admission authority and bind its decision to the full record,
  without allowing candidate producers to supply trusted status themselves.
- Define multi-source inference and derivation graphs, premise identifiers,
  exceptions and defaults while preserving the current provenance invariants.
- Integrate a versioned snapshot and admission lifecycle with atomic revocation
  and durable receipts, then prove the application's refinement to this model.
- Establish source correspondence separately from algebraic, typing, and replay
  evidence. No formal result here adjudicates a juristic position.
