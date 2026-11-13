# Candidate act intake from the source-linked reference

## Purpose and status

The [act reference](ida-act-reference.md) is usable as a catalogue of named
candidate definitions through [`formal/ida-act-intake.py`](../../formal/ida-act-intake.py).
The command accepts a versioned kind, named operands, qualifications, and a
context snapshot. It obtains the operation and ordered signature from the
validated repository catalogue, then runs the Lean registry resolver to prepare
a structurally checked candidate description.

This is a bounded part of **CW-01: typed case intake** in the
[case workbench roadmap](ida-case-workbench.md#8-implementation-roadmap).
It adds a command-line path for structured inputs. The workbench browser
interface, general narrative extraction, evidence upload, source interpretation,
and premise admission are separate work. Every result retains `admitted: false`
and `ruling: null`; successful preparation retains `status: "candidate"`.

The input catalogue still contains **34 proposed kinds**. One, the restricted
`transfer.pay_zakat` description, has a complete signature using existing IDA
reference sorts. The other **33 kinds retain 64 unresolved role slots**. The
command exposes their source loci and recorded reasons instead of completing
their signatures from caller-supplied guesses. These are counts of the
[repository proposals](../../corpus/proposals/fiqh-acts/reference.json), not an
exhaustive classification of acts in fiqh.

## 1. Use the reference

Run from the repository root, with the repository's pinned Lean toolchain and
the IDA Lean modules built:

```sh
(cd formal/lean && lake build Usul.Typing.IDAActIntake)
python3 formal/ida-act-intake.py catalogue
python3 formal/ida-act-intake.py prepare formal/fixtures/ida-act-intake/zakat-request.json
python3 formal/ida-act-intake.py prepare formal/fixtures/ida-act-intake/unresolved-agency-request.json
```

`catalogue` is read-only and does not require running Lean. Its entries expose
the exact kind key, canonical definition digest, ordered roles, Arabic and
English labels, family tags, complete source loci, legacy identifiers, subject
binding limitation, relevant normalization cases, and unresolved-role reasons.
Its `registry.snapshot` supplies the request's `registrySnapshot`; the current
projection uses snapshot **1**. The separate `registry_sha256` identifies the
canonical contents, and provenance records the actual source input hashes.
The snapshot number alone is not a content fingerprint or an admission token.

`prepare` loads and validates that same repository catalogue. There is no CLI
option for submitting a replacement registry or signature. The production
path runs `lake env lean --run scripts/CheckIDAActIntake.lean` in `formal/lean`
and checks the returned result. A missing toolchain, Lean failure, malformed
backend output, or altered returned payload fails preparation; it does not
fall back to acceptance by a Python approximation.

The two [fixtures](../../formal/fixtures/ida-act-intake/) use hypothetical
`example.intake` reference names and copy the definition digests from the actual
catalogue. They establish no person's identity, ownership, capacity, payment,
mandate, or event. The zakat fixture has the ordered roles `payer: person`,
`recipient: person`, and `transferred_property: asset` and prepares a candidate.
The agency fixture deliberately supplies attempted `obligation` and `occurrence`
operands for `mandate_reference` and `manifestation`. Those sorts remain
unresolved in the catalogue, so the result is `unresolved_roles`, with no
envelope or target. The attempted operands do not change the registered roles.

## 2. Exact request boundary

The request is a UTF-8 JSON object with exactly these fields:

| Field | Contents |
| --- | --- |
| `format` | Exactly `"usul.ida.act-intake.request.v1"` |
| `kind` | `{ "symbol": { "space": ..., "name": ... }, "version": ... }`, copied from a catalogue definition's `key` |
| `registrySnapshot` | The catalogue registry's natural-number snapshot |
| `definitionDigest` | The selected definition's exact 32-byte digest, represented as an array of integers from 0 to 255 |
| `operands` | Ordered `{ "role": ..., "referent": { "kind": ..., "symbol": { "space": ..., "name": ... } } }` objects |
| `qualifications` | Ordered qualification objects; `[]` is allowed |
| `context` | The existing `ActRegistry.Snapshot` wire object |

A reference kind is one of `person`, `asset`, `obligation`, `occurrence`, or
`proposition`. Each qualification contains exactly `predicate` (a qualified
symbol), `version` (a natural), `arguments` (typed references), `polarity` (a
Boolean), and `mention` (a qualified symbol). The context contains exactly
`contextId`, `timeId`, `profile`, `profileVersion`, `interpretationId`,
`interpretationVersion`, `evidenceRevision`, `clock`, `effectiveAt`, and
`recordedAt`; `clock` is a qualified symbol and the other values are naturals.
These are the existing [registry wire definitions](../../formal/ida-act-registry-wire.py),
not a new interpretation of contextual authority.

All objects reject unknown or missing keys. In particular, a request cannot
supply a registry, operation, signature, authority, admission status, or ruling.
Duplicate JSON keys, invalid UTF-8, surrogate code points, non-JSON numeric
constants, unknown reference sorts, and malformed digests are rejected. Wire
naturals must be integers from 0 through `2^53 - 1`; Booleans are not accepted
as numbers. Ordinary JSON whitespace and object ordering are accepted. The
host creates canonical bytes for the Lean call.

Wire validity is followed by the Lean checks: the whole registry must be
unique and structurally shaped, the snapshot/key/digest must resolve, all
registered roles must have known sorts, and the supplied operands must match
the exact ordered signature. Reference names and qualification/context fields
must satisfy the existing structural conditions. These checks do not resolve
names to people or objects and do not prove a qualification true.

Swapping the `payer` and `recipient` reference values while retaining their
role positions is structurally valid because both are persons. It produces a
different target. Reordering the role objects so they no longer match the
registered signature is rejected. Preparation therefore preserves the described
roles without deciding whether the intended participants have been identified.

## 3. Result and diagnostics

A successful result has `outcome: "prepared_candidate"`, `code: 0`, and
`prepared: true`. It returns the original request, selected candidate metadata,
exact checked definition, complete envelope, and the `perform` target projected
from that envelope. The full envelope retains the key, definition digest,
registry snapshot, qualifications, and complete context. Keep it together with
the candidate and provenance metadata: the bare target is a lossy projection.

The selected metadata retains the source loci, legacy concept kinds and topic
identifiers, normalization cases, and unresolved reasons even when preparation
is refused. An unknown kind instead has `candidate: null`. Failed semantic
preparation returns no definition, envelope, or target. The stable codes are:

| Code | Outcome | Meaning |
| --- | --- | --- |
| 0 | `prepared_candidate` | The selected candidate and supplied description pass structural resolution |
| 1 | `registry_conflict` | The registry contains conflicting keys |
| 2 | `malformed_registry` | The registry fails its structural requirements |
| 3 | `stale_registry_snapshot` | The requested snapshot differs from the loaded registry |
| 4 | `unknown_kind` | No definition has the requested key and version |
| 5 | `definition_digest_mismatch` | The supplied digest differs from that definition |
| 6 | `unresolved_roles` | At least one registered role still has no reference sort |
| 7 | `declaration_mismatch` | The constructed declaration does not match the registered definition |
| 8 | `argument_mismatch` | The operand roles, order, or sorts do not match the signature |
| 9 | `malformed_description` | A remaining description, qualification, or context shape condition fails |

The Lean resolver defines diagnostic precedence. Registry/declaration failures
are retained in the common result model even though a validated catalogue and
host-derived operation should prevent callers from creating them through this
CLI. A semantic refusal is a successfully reported result and exits **0**;
consumers must inspect `prepared` and `outcome`. Invalid request JSON or fields
produce `outcome: "invalid_input"` and exit **2**. Backend or returned-payload
failure produces `outcome: "preparation_unavailable"` and exit **1**. Those host
errors carry `status: "rejected"`; they still carry `admitted: false` and
`ruling: null`. Command result stdout is JSON.

## 4. Sources, pins, and evidence limits

The host validates the proposal catalogue against its registered witness pins,
chapter records, legacy concept inventory, and topic index using the existing
[reference validator](../../pipeline/usul_corpus/act_reference.py). It preserves
the existing source URLs, byte lengths, and SHA-256 values. The zakat proposal
points to `src:openiti-ibnqudama-umda-shamela11315/v01:p039#b00034`; agency
revocation points to `/v01:p059#b00066` under that same witness. Both mappings
remain candidates based on chapter or passage anchors. The full pin and locus
objects are in the output and the [source-linked reference](ida-act-reference.md#4-source-passages-and-their-limits).

This CLI reports **`source_metadata_checked: true`** and
**`source_bytes_verified: false`**. It does not fetch or recheck the complete
witness texts. Earlier reference preparation or a separate full-witness receipt
does not change those fields for this run. To verify witness bytes, use the
reference exporter's `--witness-dir` mode described in its
[reproduction guide](ida-act-reference.md#9-reproduce-and-review).

The provenance distinguishes input hashes from correspondence with the checked
repository revision. Local edits can be described and fingerprinted without
being called committed verification. A host result is not a source acceptance
receipt: it mints no authenticated premise, contextual certificate, application
grant, or ruling. The definition digest pins the canonical key and proposed
roles, not the truth of their interpretation. Context and qualifications are
retained as supplied descriptions, without evidential admission.

## 5. Verification and remaining work

Run the dedicated gate from the repository root:

```sh
make ida-act-intake
```

The report is written to `.cache/ida-act-intake/report.json`. Review that
report's declared domain, input hashes, revision correspondence, and outcomes
for the actual run. The gate combines compiled Lean contracts and audits,
independent bounded Quint comparison, candidate catalogue replay, host
integration cases, and deliberate negative controls. Its job is to check the
candidate intake boundary; a result at one revision does not establish hosted
acceptance or repository-wide CI at another revision.

The [Lean preparation module](../../formal/lean/Usul/Typing/IDAActIntake.lean)
retains the input in a registry-indexed `PreparedDraft`, proves the existing
resolver accepts its exact envelope and definition, preserves all fields and
role order, and constructs a structurally well-formed target. The
[Quint model](../../formal/quint/ida-act-intake.qnt) independently executes the
same specified preparation behavior. The
[host unit tests](../../pipeline/tests/test_act_intake.py) test strict input and
returned-payload boundaries with an explicitly mocked Lean call; those unit
tests are not a substitute for the gate's actual Lean execution.

General case intake still needs source occurrence tracking, proposed
normalization review, supported narrative handling, and an evidence upload
boundary. Every unresolved role still needs a reviewed meaning and justified
sort. Even the structurally prepared zakat description leaves subject binding,
eligibility, amount, ownership, capacity, occurrence, discharge, source
interpretation, and contextual admission open. This increment makes the
reference usable for candidate descriptions while preserving those obligations
in [CW-01](ida-case-workbench.md#8-implementation-roadmap) and
[ACT-08](ida-act-classification-roadmap.md#act-08--run-the-first-complete-pilot).
