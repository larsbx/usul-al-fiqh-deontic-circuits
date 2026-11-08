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
profile version. Its ordered cases are:

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

The left key is fixed to seven zeros in the finite export. Right-key variant
zero is identical. Variants 1 through 7 change, respectively, question, subject,
target, context, time, profile, or version to one. This covers each equality
guard individually; it is not enumeration of all pairs of arbitrary keys.
Lean's key-guard theorems quantify over the full key type.

| Export section | Inputs |
|---|---:|
| Meet | 25 ordered pairs |
| Join | 25 ordered pairs |
| Omission | 5 values |
| Required-premise conjunction | 8 key variants × 33 inputs × 33 inputs = 8,712 |
| Total independent comparisons | 8,767 |

Lean emits CSV in the order meet, join, omission, conjunction. Quint constructs
the same complete output vector in one deterministic initial state. The CLI's
single zero-step run serializes that vector; it does not sample its entries.
The gate rejects malformed, missing, duplicate, noncanonical, or disagreeing
exports.

Seventeen independently stated contract vectors also check both exports,
including explicit mubāḥ, broad constraints, partial permission, conflict,
missing/suspended premises, and each of the seven key mismatches.

## Reproduce

Use the repository's Lean toolchain pin and Node 22 or later:

```sh
npm --prefix formal/quint ci
make ida
```

The gate requires the exact Lean pin and Quint 0.33.1. Missing tools or failed
checks fail the command. It checks deterministic Quint assertions, compares all
8,767 outputs, and audits compiled declarations in the source dependency
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

Further obligations include source admission and provenance preservation,
exception/default rules and re-evaluation after context changes, interpretation
of omissions and affects, alternative and collective duties, agency integration,
and a verified mapping from application data and concurrent writes to the model.
None is established merely by agreement between these two finite computations.
