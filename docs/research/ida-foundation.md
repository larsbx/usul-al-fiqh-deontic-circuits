# IDA foundation: algebra and guarded partial rulings

This is the first executable slice of the
[Islamic Deontic Algebra specification](islamic-deontic-algebra-spec.md).
It reuses `Usul.Hukm` and adds a small algebra plus conjunction of two required
partial answers. Source interpretation, evidence admission, general inference,
and application refinement remain separate obligations. The existing agency
pilot is unchanged.

## Semantics

The carrier is the existing five constructors, whose order is derived from
doing/omitting consequences. Meet and join compute lower and upper bounds in
`haram < makruh < mubah < mandub < wajib`. They do not resolve juristic
disagreement. Omission swaps the existing doing/omitting profiles; interpreting
an actual omission still needs its action, opportunity, time, and source profile.

A known partial answer is a **nonempty set** of these constructors. No ruling
and suspension are distinct tagged inputs. In particular:

- `{mubah}` is a specific answer.
- `{makruh, mubah, mandub, wajib}` constrains the answer to non-forbidden statuses.
- The explicit all-five set is a supplied, maximally broad constraint.
- No ruling and suspension supply no such known answer.

The conjunction operation requires two premises for the same key. The key has
seven independent fields: question, subject, target, context, time, profile, and
profile version. The target is now a checked Target containing the complete
structured expression described below; the other six coordinates retain the
foundation's opaque natural-number representation. Its ordered cases are:

1. Different keys produce `OutOfScope`.
2. With equal keys, either suspended premise produces `Suspended`.
3. Otherwise, either missing ruling produces `NoRuling`.
4. Otherwise, intersect the two known sets. Empty intersection produces
   `Conflict`; nonempty intersection produces a known partial answer.

This operation combines **two required premises**. It does not treat missing
information as an identity, discard a suspending premise, or select a preferred
school position. Named alternatives must remain separate. A returned conflict
is the result of this conjunction; the function does not authenticate sources
or establish that either input represents a source faithfully.


## Structured targets

The target field contains the expression itself, with a proof of structural
wellformedness. It is no longer a natural-number identifier.

| Form | Represented information |
| --- | --- |
| Perform | Qualified operation symbol, its complete ordered signature, and named typed operands |
| Omit | An action plus a named occurrence, a named clock, and strictly increasing opening/closing bounds |
| Affect | Qualified affect quality and the typed reference it concerns |

Qualified symbols carry a nonempty namespace and name. Reference sorts in this
slice are person, asset, obligation, occurrence, and proposition. They describe
reference roles in this representation, not an enumeration of fiqh acts.
An operation's named parameters have unique nonempty roles. Its operands must
match the entire ordered parameter list, including arity, roles and reference
sorts. Every referenced symbol must be nonempty.

The operation's signature is supplied data and participates in identity.
Checking that operands fit it does not prove that it is the source-authorized
signature for that operation. In particular, a structurally wellformed synthetic
"repay debt" operation whose declared argument sort is asset remains a different
represented target; it acquires no source authority from this check.

Target equality preserves the entire expression. It distinguishes performing
from omitting, omission opportunities, affect from conduct, namespaces, operation
signatures, reference sorts, operand roles, and order. It does not identify
synonyms, normalize argument order, or prove real-world event identity.
The judgment subject is supplied by the separate subject coordinate. An
operation may also name participants, including a payer or performer; the
checker does not bind a person reference to the opaque subject identifier.
Voluntary control, capacity and intention remain contextual; an affect
description does not imply that the feeling was chosen or that a taklifi ruling
applies. `perform` describes an act; it does not prove that the act occurred.

Opportunity bounds are natural-number positions on a named clock. This use
represents a quantity, not an opaque target. Their relationship to calendar time,
subject capacity and the separate judgment-time coordinate requires a later
context interpretation contract. No rule automatically turns an omitted omission
into a performed act.

Target.validate checks raw expressions and either returns the exact same
payload with its structural proof or rejects it. Lean's Key can contain only
a checked target. Quint explicitly checks the corresponding raw structures
before conjunction. These are structural checks, not source admission.

### Candidate fiqh act reference

The [act reference](ida-act-reference.md) connects this grammar to the existing
corpus without treating its labels as admitted signatures. Its
[versioned candidate catalogue](../../corpus/proposals/fiqh-acts/reference.json)
retains 34 proposed kinds, their source loci, role order, legacy classifications,
and explicit unresolved typing decisions. The legacy graph separately contains
537 concepts, including 293 labeled `act`, under 57 reachable topic roots.
Neither those topics nor the proposal family tags are formal subtypes.

The current reference sorts can express the entire proposed role list for one
restricted illustration, `transfer.pay_zakat`: payer and recipient as person
references, and transferred property as an asset reference. The other 33
proposals retain unresolved roles. The convention `fiqh.act.candidate.v1`
places the definition version in the operation namespace. It does not authorize
the signature, prove a source interpretation, or add a registry to Lean.

Run `cd pipeline && python -m usul_corpus.act_reference --out
../.cache/fiqh-act-reference` to validate and export the reference. The separate
reference workflow checks source pins and candidate-data invariants; its receipt
does not add a Lean theorem, Quint comparison, or admitted fiqh ruling. The
existing IDA verification below remains the gate for the formal target model.

### Additional proof and adversarial obligations

The scoped gate retains all 59 foundation contracts and adds 20 universal
target contracts plus five finite scenario contracts: 84 fixed propositions.
The new universal proofs cover signature matching, unique roles, nonempty
references, opportunity bounds, distinct target constructors, exact payload
identity, validation preservation/rejection, and target preservation through
conjunction.

The target audit family contains 28 supplied expressions: 20 structurally
wellformed entries (entries 0 and 1 reconstruct the same target) and eight
malformed entries. Malformations cover arity, reference sort, duplicate roles,
empty names, empty/reversed intervals, and argument order. The fixtures are
synthetic; supplied test constraints make no source-backed assertion about the
rulings on these acts.

The independent Quint model uses explicit comparison functions; the Lean model
uses derived structural equality. New semantic mutants erase namespaces,
operations, operand roles, omitted acts, opportunity fields, affect fields,
reference sorts, signature validation, interval strictness, duplicate-role
checking, target-kind separation, or the raw admission guard. Every mutant must
typecheck and then fail its named assertion. A separate compiled control weakens
the target mismatch theorem to True; compilation of its fixed proposition
witness must reject the weakened statement.

## Components

| Component | Responsibility |
|---|---|
| `formal/lean/Usul/IDA.lean` | Algebra, typed partial answers, exact-key conjunction, and proofs |
| `formal/lean/UsulTest/IDA.lean` | Executable Lean examples and finite checks |
| `formal/lean/UsulTest/IDAContracts.lean` | Fixed proposition types for every required proof obligation |
| `formal/lean/scripts/ExportIDA.lean` | Canonical complete export of the declared finite domain |
| `formal/quint/ida.qnt` | Independently written model and deterministic assertions |
| `formal/quint/ida-table.qnt` | Deterministic complete Quint export |
| `formal/check-ida.py` | Pinned-tool gate, export comparison, compiled axiom audit, negative controls, receipts |

The new modules are imported by the existing `Usul` and `UsulTest` roots, so the
repository-wide module-coverage audit also includes them. The scoped IDA gate
builds its own dependency closure before auditing it, including on a cold cache.

## Wire contract and declared bounds

Wire integers are serialization tags, never normative magnitudes.

| Value | Encoding |
|---|---|
| `haram`, `makruh`, `mubah`, `mandub`, `wajib` | Tags `0,1,2,3,4` |
| Known set | Bit mask `1..31`, with those five tags as bit positions |
| No ruling | Input/output tag `0` |
| Suspension | Input/output tag `32` |
| Conflict | Output tag `33` |
| Out of scope | Output tag `34` |

The standalone carrier tags and partial-answer tags occupy different typed
interfaces. Input mask zero denotes the explicit no-ruling wire case; it never
constructs a known empty set. Empty *computed intersections* produce conflict.

The original finite export uses six zero coordinates plus the structured
repayment fixture as its left key. Right-key variant zero is identical.
Variants 1 through 7 change, respectively, question, subject, target, context,
time, profile, or version. The target variant changes repayment to a promise;
the other variants change their numeric coordinate to one. This covers each equality
guard individually; it is not enumeration of all pairs of arbitrary keys.
Lean's key-guard theorems quantify over the full key type.

| Export section | Inputs |
|---|---:|
| Meet | 25 ordered pairs |
| Join | 25 ordered pairs |
| Omission | 5 values |
| Required-premise conjunction | 8 key variants × 33 inputs × 33 inputs = 8,712 |
| Original foundation prefix | 8,767 |
| Structured target admission | 28 |
| Structured target conjunction | 28 × 28 × 6 premise pairs = 4,704 |
| Total independent comparisons | 13,499 |

Lean emits CSV in the order meet, join, omission, original conjunction,
target admission, target conjunction. The target fixture selectors select full
expressions, not externally assigned target identifiers. Tag 35 is rejection
of malformed target syntax at this audit boundary; it is not a sixth ruling
or a new Result constructor. Quint constructs
the same complete output vector in one deterministic initial state. The CLI's
single zero-step run serializes that vector; it does not sample its entries.
The gate rejects malformed, missing, duplicate, noncanonical, or disagreeing
exports.

The original 17 independent contract vectors are retained. Another 28 admission
expectations and 48 target conjunction vectors check both exports, including
a reconstructed equal target, each meaningful changed target field, and
malformed targets on either side or paired with themselves.

## Reproduce

Use the repository's Lean toolchain pin and Node 22 or later:

```sh
npm --prefix formal/quint ci
make ida
```

The gate requires the exact Lean pin and Quint 0.33.1. Missing tools or failed
checks fail the command. It checks deterministic Quint assertions, compares all
13,499 outputs, and audits compiled declarations in the source dependency
closure and standalone exporter. Only the repository's standard Lean axiom
allowlist is admitted. An explicit list of required theorem declarations and
fixed typed witnesses prevent acceptance after deleting a promised proof or
weakening its statement to a trivially true proposition. The compiled import
inventory rejects project dependencies outside the declared, hashed closure.
Real compiled controls include an unused private axiom, an admitted proof, and
an unlisted dependency; none may pass the audit.

Semantic mutants must typecheck and then fail a specifically named assertion.
A parser error, missing tool, or unrelated runtime error is not a mutation kill.
Export-corruption controls separately exercise the comparison gate.

Successful runs atomically create `.cache/ida/` with:

- `report.json`: exact revision, source hashes, tool versions, declared bounds,
  comparison coverage, controls, recorded loader overrides, and acceptance boundary;
- `compiled-axioms.json`: module inventory and per-declaration dependencies;
- `lean.csv` and `quint.itf.json`: the independent exports;
- `quint-tests.json`: the deterministic test results.

A fresh run removes earlier successful receipts before starting. A receipt with
`inputs_match_head: false` describes a worktree calculation, not acceptance of
the named commit. The dedicated GitHub workflow checks the PR's exact head and
retains the evidence as an artifact. Its result is scoped IDA acceptance;
repository-wide CI and the agency pilot retain their own results.

## Remaining specification obligations

The next slice is a question-indexed judgment and derivation format with
source hashes, passage locators, interpretation versions, evidence grades, and
explicit candidate/admitted status. It must preserve missing, suspended, known,
conflict, and out-of-scope outcomes while keeping validity/effect questions
separate from taklifi status.

Further obligations include source admission of operation signatures, resolution
and authenticity of reference bindings, opportunity/context consistency,
provenance preservation,
exception/default rules and re-evaluation after context changes, interpretation
of omissions and affects, alternative and collective duties, agency integration,
and a verified mapping from application data and concurrent writes to the model.
None is established merely by agreement between these two finite computations.
