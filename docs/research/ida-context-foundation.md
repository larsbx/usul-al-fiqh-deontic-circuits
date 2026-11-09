# ACT-01 ground context foundation

This slice extends the [act registry and source-binding fragment](ida-act-registry.md)
with the ground context contracts from the [accepted context theory](ida-context-theory.md).
The [Lean module](../../formal/lean/Usul/Typing/IDAContext.lean) checks a finite
catalog against the existing act registry. The [Quint model](../../formal/quint/ida-context.qnt)
implements the bounded comparison independently.

## Identity and resolution

| Coordinate | Structural contract |
|---|---|
| Predicate | A qualified symbol and positive definition version identify an ordered list of argument sorts. A qualification supplies rigid `EntityRef` constants, polarity, and an attributed mention. The checker validates the exact signature and retains opposing qualifications as data. |
| Description | The actual act-registry resolver validates the versioned kind, definition digest, and ordered named operands. One optional omission opportunity identifies the occurrence, clock, and interval. The full envelope retains qualifications that the existing target projection forgets. |
| Participant | The accountable party is an explicitly declared person reference. The performer is a named person operand of the resolved act. The existing subject ID and capacity fields remain in the exact inquiry scope. The same reference can occupy both positions if explicitly supplied. |
| Context | A versioned snapshot contains the full act envelope, the predicate vocabulary and its pin, an admission-policy pin, the temporal view, and the inquiry. The envelope carries the evidence revision and interpretation pins. Grounded references are carried directly in the object syntax. |
| Time | The clock identity includes its qualified name and positive version. A catalog assigns a legacy time ID one effective tick on one clock identity. Recording time and the evidence cutoff are separate. An as-known view cuts off at the effective tick. A retrospective view uses a later cutoff. Both require the recording tick to be no later than the cutoff. |
| Inquiry | The exact query ID, typed question, accountable reference, declared performer, complete structured target, legacy scope, and temporal view are bound together. The existing raw premise must have the same question, full scope, and interpretation pins. |

An independently supplied catalog declares the mapping from the legacy
`(contextId, timeId)` pair to a complete snapshot. Each pair and each snapshot
key must be unique. The resolver rejects identical duplicate rows as well as
conflicting ones. Reusing a vocabulary pin with different contents, a predicate
key with a different signature, or a time ID with a different effective
identity blocks resolution. A missing pair has no structured interpretation.
Historic records remain usable through the existing IDA entry points.

The caller presents an exact expected snapshot, and lookup validates the
matching row against the current act registry. A historical catalog can still
identify its old snapshot. Replaying that snapshot against a replacement row
with the same legacy coordinates produces a stale result. A revised catalog
should issue a new snapshot version for a changed payload. Exact value comparison
also detects changes when a caller incorrectly retains the same key across
separate catalogs.

The canonical typed wire has schema tag `usul.ida.context.v1`. Its fields are
the versioned key, vocabulary, admission policy, the existing
`ActRegistry.EnvelopeWire`, time, inquiry, and optional opportunity. Lists
retain order. Lean proves both round-trip directions for successful decoding
and injectivity of the encoding. This slice defines a typed wire value. The
registry fragment's JSON and SHA-256 adapter continues to cover its own
envelope format.

## Evidence and the pilot

A successful binding receipt contains the complete resolved snapshot and
unchanged `Derivation.Premise`. Its result type has structural failures and
structural success. `Derivation.evaluateSource` retains responsibility for
authenticated source and evidential admission under its separately supplied
environment. The snapshot's policy and evidence revision are identity pins.
The context layer adds neither an interpretation of the predicate's truth nor
a conditional inference rule. A candidate-source control passes structural
binding and still fails source admission.

The synthetic fixture uses two participants, one unary predicate, and one
opportunity on one clock. The interval is half-open `[opensAt, closesAt)`.
The phase calculation distinguishes before, open, and closed. It says nothing
about observation coverage, whether performance occurred, or whether an
omission is established. The separate agency fixture replays the existing
candidate immediate and on-knowledge profiles. Its historical execution
receipt survives revocation, while current authority differs by profile and
by each agent's notification history. No mandate role is resolved by this
fixture and no candidate ruling is promoted.

The kernel proves that exact structural resolution cannot factor through
the structured target when a changed qualification leaves the target equal.
This is a concrete obstruction to applying the existing
[`Factor` interface](../../formal/lean/Usul/Cat/Factor.lean) to this projection.
There is no contextual restriction, substitution, sheaf, or evidence transport
adapter in this slice.

## Replay and remaining work

```sh
npm --prefix formal/quint ci
make ida-context
```

The gate builds the Mathlib-free Lean modules and fixed statement contracts,
audits compiled axiom dependencies, and checks each row against Quint 0.33.1.
The finite abstraction pairs the fixture selectors in both models and compares
the structural result code, omission phase, and candidate agency observations.
It covers 2,800 bindings from 28 snapshot variants, ten catalog variants, and
ten premise variants, plus six omission ticks and 24 agency observations.
Named adverse tests reject deliberately weakened Quint models. The receipt
records the checked Git revision, source hashes, tool versions, local runtime
overrides, compiled declaration inventory, and the two complete output tables
under `.cache/ida-context/`.

[ACT-02](ida-substitution.md) implements a typed substitution and grounding
calculus with conditional conjunction and checked premise arrows. It preserves
the original evidence boundary. Semantic commutation, information-loss
contracts beyond the ACT-01 witness, and context-aware re-admission remain
separate later work.
