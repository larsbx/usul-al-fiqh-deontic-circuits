# ACT-01: versioned act registry and bound source admission

**Design status: accepted. Implementation: minimal ACT-01 fragment.** This slice
implements the first package of the [M16 roadmap](ida-act-classification-roadmap.md)
on the accepted [context design](ida-context-theory.md). Its reproducible gate is
`make ida-registry`; verification claims belong to the revision and input hashes
recorded by that gate and the corresponding hosted run.

The fragment resolves performed-action descriptions against a versioned registry
and associates the complete description with an existing admitted source premise.
It supplies the registry interface needed by ACT-02. Existing omission, affect,
and legacy targets remain in their original representation; this resolver does
not convert them into performed actions or supply interpretations for them.

## 1. Registry authority and typed descriptions

The implementation is in
[`Usul.Typing.IDAActRegistry`](../../formal/lean/Usul/Typing/IDAActRegistry.lean).
Its independent executable counterpart is
[`ida-act-registry.qnt`](../../formal/quint/ida-act-registry.qnt).

| Object | Implemented contents | What a successful check establishes |
|---|---|---|
| `KindKey` | Qualified symbol and positive definition version | Exact identity of the requested definition |
| `Definition` | Key, 32-byte digest pin, ordered named role schema | A well-shaped structural definition; a role may remain explicitly unresolved |
| `Registry` | Snapshot identifier and complete definition list | All versioned keys are unique before any lookup; conflicting and identical duplicate rows are rejected |
| `CheckedDescription registry` | Exact envelope, resolved definition, and resolution proof | Declared operation and ordered operand parameters match the registry definition |
| `Qualification` | Predicate symbol/version, rigid typed arguments, polarity, source-mention identifier | A well-shaped attributed candidate assertion; no truth or predicate-signature theorem |
| `Snapshot` | Context/time IDs, profile and interpretation pins, evidence revision, clock, effective and recorded times | Exact metadata; semantic relationships between these coordinates still require ACT-02 and later contracts |

`resolve` checks the entire registry before choosing a requested key. It does not
turn the first matching row into uniqueness evidence. Unknown keys and unresolved
roles have explicit failure outcomes. An unresolved mandate is not converted into
an obligation merely because the existing reference vocabulary contains that sort.

The universal Lean contracts show that successful resolution identifies a unique
registered definition, fixes the complete ordered role schema, and produces a
structurally valid target. These statements quantify over arbitrary finite
registries and descriptions; the separate Quint comparisons have declared finite
bounds.

## 2. Preserve the full envelope

The existing `Target` remains unchanged. `project envelope` retains the performed
action's operation, ordered role schema, and every named, typed operand. It omits
the definition version/digest, registry snapshot, qualifications, and context
metadata. This is an explicitly **lossy projection**.

Consequently, equal projected targets do not establish equal descriptions. A
changed reported qualification, evidence revision, or definition version can leave
the action unchanged. The implementation retains those fields in the complete
envelope and tests same-target mutations against existing bindings.

The identifier positions remain distinct: a kind key names a versioned definition;
a qualification's mention names an attributed report; a description consists of
the full envelope; occurrence identifiers stay in the existing omission/event
representation. No identifier equality supplies an occurrence or truth witness.

## 3. Bind to the actual source-admission machinery

`Authority` contains three explicit trusted inputs: the definition registry, a
binding table, and the existing `Derivation.Environment`. A binding contains the
exact envelope and complete `Derivation.Premise`. Binding keys are source entry
IDs. Every entry ID must be unique; different source entries may support the same
envelope.

`admit authority request` performs these checks in order:

1. Resolve the description against the supplied registry.
2. Reject ambiguous binding identities and locate the exact source entry.
3. Compare the whole bound envelope and whole premise with the request.
4. Compare the projected target with the premise's complete structured target.
5. Match the six repeated context/time/profile/interpretation coordinates.
6. Call the existing `Derivation.evaluateSource` and require its known-result
   acceptance.

The last step inherits the existing exact registry admission, source-rule,
authenticated-reference, current-interpretation, evidence, and known-answer
requirements. The theorem `admitted_source_authority` derives the existing
`Derivation.AdmissibleLeaf` obligation through that actual evaluator. Candidate
lookup alone cannot construct an admitted source result.

A receipt contains the whole authority, request, definition, and actual source
evaluation. Revalidation recomputes acceptance against the supplied current
inputs. Changing any retained environment/request field invalidates reuse of the
old receipt, even when the projected target is unchanged. Source ancestry remains
the exact original premise.

The binding table is supplied authority. It must be produced independently of the
submitted request; creating a trusted row from the request would discard this
boundary. The source premise alone does not certify omitted qualification truth.
The wrapper proves an exact authorized association under these supplied inputs.
Publishing/authenticating this new binding authority is not implemented by the
canonical structural-data adapter. The existing source-authentication contract
continues to cover its own [source boundary](ida-source-auth.md).

## 4. Canonical definitions and wire

[`ida-act-registry-wire.py`](../../formal/ida-act-registry-wire.py) implements the
host data boundary. A bundle has exactly `format`, `registry`, and `envelope`,
with format `usul.ida.act-registry.v1`. The checked
[synthetic fixture](../../formal/fixtures/ida-act-registry/description.json) is a
complete example.

The canonical definition payload is exactly:

```json
{"key":{"symbol":{"name":"repay","space":"test.act"},"version":1},"roles":[{"kind":"person","role":"debtor"},{"kind":"person","role":"creditor"},{"kind":"obligation","role":"debt"}]}
```

SHA-256 covers the UTF-8 bytes of the payload with sorted object keys, compact
separators, ASCII escaping of Unicode strings, no trailing whitespace, and array
order preserved. The digest field itself is excluded. The payload covers every
current structural definition field; it does not purport to hash a juristic
interpretation or the semantics of a qualification.

The host recomputes every definition digest. It rejects duplicate JSON keys,
unknown/missing fields, unknown sort tags, malformed digest bytes, noncanonical
bytes, invalid UTF-8, surrogate code points, and non-integral or unsafe numeric
values. Wire naturals range from zero through `2^53 - 1`; Lean's structural
theorems quantify over its unbounded natural-number carrier. Role sorts use the
five existing names; JSON `null` preserves an unresolved role.

The structural wire's definition/envelope round-trip and successful-decode
reencoding laws are proved in Lean. The textual JSON consumer independently
parses and emits every semantic field, then calls the actual resolver. Its
outputs are compared with the original bundle and independently instantiated
Quint inputs. General correctness of JSON parsing and SHA-256 is an explicit
host boundary, not a proved refinement theorem.

This JSON format covers registry/envelope structural data. It does not serialize
`Authority`, source `Request`, or the new `Receipt`; those remain typed formal
objects. The preexisting source-premise wire retains its own contract.

## 5. Candidate catalogue and relation vocabulary

The original [candidate reference](ida-act-reference.md) and
[source catalogue](../../corpus/proposals/fiqh-acts/reference.json) are retained.
The gate constructs all 34 candidate definitions without changing their status,
source loci, legacy links, or normalization alternatives. One restricted zakat
signature is representable; 33 kinds retain 64 explicitly unresolved role slots.
The generated `candidate-worklist.json` includes each missing sort's stated
reason and source loci. It is an implementation worklist, with no source
interpretation promoted by structural resolution.

The existing [relation contracts](ida-act-classification-roadmap.md#distinct-relation-vocabulary)
continue to govern composition independently:

| Relation | Endpoints and permitted use in ACT-01 | Further law required |
|---|---|---|
| Topic membership | Mention/concept to topic; catalogue navigation | No refinement or ruling transport is inferred |
| Interpretation | Source mention to versioned candidate definition | Supported meaning and admission remain separately evidenced |
| Specialization | Compatible schemas or predicates | ACT-02/ACT-03 must establish actual refinement and its preservation claims |
| Component membership | Component description to a specified composite position | ACT-06 typed assembly/substitution |
| Realization | Description to a profile-specific manifestation | Explicit interpretation and realization conditions |
| Equivalence | Descriptions under a stated profile/context/question | ACT-03 equivalence and relevant congruence laws |

No heterogeneous graph path is treated as a general inference rule. The registry
contains structural definitions; it does not turn topics, mentions, components,
or equivalence candidates into interchangeable kinds.

## 6. Verification and reproduction

```sh
npm --prefix formal/quint ci
make ida-registry
```

The gate uses the repository's pinned Lean 4.34.1 and Quint 0.33.1, builds the
actual modules and fixed theorem contracts, audits compiled declarations for
unexpected axioms, and compares 4,824 cases with two output cells each:

| Comparison | Coverage |
|---|---|
| Registry resolution | 14 registry variants × 36 envelopes = 504 cases |
| Exact bound admission | 36 envelopes × 10 binding scenarios × 12 actual source environments = 4,320 cases |
| Canonical structural wire | 44 bundles, including all 34 catalogue kinds; every Lean-decoded field is compared |
| Decoder/digest attacks | 20 hostile controls against the actual host decoder |

Guard-isolated tests keep the trusted pair valid while breaking source
authentication, evidence, current-version, or admitted-entry requirements.
Separate cases exercise target and snapshot mismatches with an otherwise exact
trusted row. Deliberately weakened models must fail when they choose the first
conflicting definition, compare only projected targets, bypass source admission,
skip snapshot binding, or skip target comparison. A named theorem weakened to
`True` must fail its fixed proposition contract. Compiled private axioms and
`sorry` are also rejected.

The hosted job checks that `.cache/ida-act-registry/report.json` records the
checked Git revision and that every recorded input matches its committed bytes.
Receipts include the full input hashes, model outputs, compiled inventory,
negative-control outcomes, and the candidate worklist. Local loader overrides,
when necessary, are recorded separately; hosted evidence uses the ordinary
toolchain.

## 7. Next package

ACT-02 can now define typed variable contexts and substitution against this
registry-indexed family. Its next obligations are identity/composition, role and
rigid-reference preservation, admissible premise substitution and cut, and
explicit grounding. The remaining context semantics and categorical transport
contracts retain their accepted roadmap status and their own implementation
and proof obligations.
