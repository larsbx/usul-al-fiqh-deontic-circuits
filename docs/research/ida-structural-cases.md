# ACT-08 structural cases: unresolved roles, qualifications, and occurrences

**Design status: accepted. Implementation scope: bounded structural integration.**
This component connects three remaining examples from the
[accepted M16 roadmap](ida-act-classification-roadmap.md#act-08--run-the-first-complete-pilot)
to the existing registry, substitution, report interpretation, context resolution,
and application-admission functions. It extends the integrated ACT-01 through
ACT-05 baseline inspected at main
[`87d1ab58eb098a0bdc8c861542184cd896b012a6`](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/commit/87d1ab58eb098a0bdc8c861542184cd896b012a6).

Run `make ida-structural-cases` for this component. The
`make ida-pilot` index requires its receipt alongside context, admission,
signed omission, shared repayment, and structural zakat receipts at the same
Git revision. A successful component receipt does not close the full ACT-08 exit.

## 1. What the examples establish

| Example | Positive evidence | Required refusal or distinction |
| --- | --- | --- |
| Unresolved agency revocation | The exact candidate key and ordered roles are read from the same Lean definition that the resolver checks and compared with the source-linked corpus entry | Supplying an obligation, proposition, asset, or person as the mandate operand cannot resolve an undefined mandate role |
| Qualified descriptions sharing a core | Current qualified snapshots are structurally valid; the complete scoped projection agrees with the direct report evaluator | A matching exception changes the observation result even when kind and structured target agree; an old receipt does not certify changed authority |
| Distinct omission occurrences | Each occurrence has its own positive native application and typed substitution, with a compatible-history witness | Full inquiries, projections, and certificates retain occurrence identity; a certificate from the other occurrence is rejected |

The Lean fixture is
[`UsulTest.IDAStructuralCases`](../../formal/lean/UsulTest/IDAStructuralCases.lean).
Its independent finite model is
[`ida-structural-cases.qnt`](../../formal/quint/ida-structural-cases.qnt).
The fixture calls the existing resolvers and admission checker. It does not
replace those checks with a caller-supplied acceptance flag.

## 2. Preserve the actual unresolved candidate

The catalogue entry is `fiqh.act.candidate.v1 / agency.revoke`, version 1.
Its ordered role declarations are:

| Role | Current reference sort |
| --- | --- |
| `revoking_party` | `person` |
| `mandate_reference` | unresolved |
| `manifestation` | unresolved |

The host checker compares the exported definition signature with
[`corpus/proposals/fiqh-acts/reference.json`](../../corpus/proposals/fiqh-acts/reference.json),
retains its source loci in the receipt, and requires candidate, unadmitted,
nonrepresentable status. The source catalogue is fingerprinted with the code.
It is not rewritten by this example.

Nine registry rows cover several attempted operand sorts, an empty registry,
duplicate definitions, a mismatched digest, a requested unsupported version,
and a fixture in which only manifestation is resolved. The latter still leaves
the mandate role unresolved. A proposed operand cannot supply missing meaning
in the registered role declaration.

The existing bounded agency chronology model remains separately indexed through
the context component. Its as-known and retrospective revocation results do not
construct an admitted `agency.revoke` description. The two models have
different supported domains.

## 3. Qualifications, observations, and a fixed history

For each of two occurrences, all 16 combinations of four report signs are
checked: positive and negative support, and positive and negative exception.
The selected toy observation rule uses the same support/exception convention as
the existing [scoped projection](ida-projection.md).

Each row records structural validity, direct and projected observation results,
the projected occurrence, equality of the target and kind with the baseline,
evaluation in an independently supplied fixed history, and old-receipt replay.
The baseline report mask is 9: positive support and explicit negative exception.
A changed report list does not mutate the supplied history.

The positive fresh-authority witnesses matter. Every report mask has a current,
well-formed snapshot and can pass the structural application checker under
matching supplied test authority. This says nothing about a later guard's
success or the truth of the reports. A contradictory report set can remain
ordinary data while a separately defined observation guard reports conflict.

Replaying the earlier receipt under changed authority returns
`changedAuthority`. That result requires a fresh application check; it does
not assert that all changed evidence is semantically relevant. Even an
observation-preserving change can require a new exact receipt.

## 4. Occurrence-preserving reindexing and admission

The two omission opportunities share the same underlying kind, role schema,
clock, and interval. Their occurrence symbols differ. Each has its own
inquiry frame, snapshot keys, context identifiers, source and destination
certificates, and grants. Distinct context identifiers prevent catalogue
ambiguity from hiding an intended certificate-scope rejection.

Identity and participant-swap substitutions are tested within each occurrence.
The substitution changes participant terms while retaining the fixed inquiry
frame. It does not rename one occurrence into another. Full interpreted
inquiries and scoped projections preserve this identity. A narrow meaning
that intentionally records only repayment participants and debt may agree for
the two occurrences; that agreement cannot replace the full application binding.

For each occurrence and substitution, the following ten cases use the actual
application-admission path:

| Mutation | New side / reconstruction outcome | Replay of the original receipt |
| --- | --- | --- |
| Native matching inputs | accepted | accepted |
| Missing submitted certificate | premise-list rejection | accepted under unchanged original authority |
| Wrong submitted formula | premise-list rejection | accepted under unchanged original authority |
| Other occurrence's certificate, with an explicit proposed grant | certificate-scope rejection | changed authority |
| Current catalogue changed at the same snapshot identity | stale snapshot | changed authority |
| Duplicate authenticated token | certificate-authentication rejection | changed authority |
| Missing destination source evidence | source-evidence rejection | changed authority |
| Missing independent destination grant | policy rejection | changed authority |
| Missing authenticated source | source-authentication rejection | changed authority |
| Native certificate with the other occurrence's token and a proposed grant | certificate-authentication rejection | changed authority |

The replay column uses the stored original receipt. Merely submitting a bad new
side does not alter that receipt or its original authority. The first two
negative submissions therefore coexist with a valid historical replay. The
remaining cases explicitly change the authority input.

The full certificate comparison includes its application, formula and premise.
A token identifies a certificate; it does not authorize replacing its payload.
The underlying source evaluator and independent application grant remain
necessary after the structural context checks.

## 5. Comparison and proof contract

The finite comparison has exactly 81 ordered rows and 585 output cells:

| Family | Coordinates | Rows | Cells per row |
| --- | --- | ---: | ---: |
| Registry | 9 variants | 9 | 1 |
| Qualification | 2 occurrences × 16 report masks | 32 | 8 |
| Occurrence | 2 occurrences × 2 substitutions × 10 authority/submission cases | 40 | 8 |

The host parser requires every named coordinate in order, exact row widths,
canonical natural numbers, and declared result ranges. Truncated, duplicate,
reordered, malformed, or unsuccessful exports are rejected before comparison.
The independent Quint model computes the same observables from its own
bounded records and checking functions; it does not read a Lean answer table.

Seventeen named Lean contracts pin nine general obligations and eight finite
fixture witnesses used by the component. The compiled
audit rejects extra axioms and `sorry` dependencies. An explicit control
weakens an occurrence-distinction theorem to `True`; its fixed typed contract must fail.
Model controls weaken unresolved-role, qualification, occurrence, and admission
guards and must fail at their intended assertions, rather than at typechecking.

The bounded claim is also registered in
[`formal/lean-proof-claims.json`](../../formal/lean-proof-claims.json). The whole-core
audit resolves its theorem references; this component fingerprints the register
without treating unrelated proof-bank entries as part of its import inventory.

Theorems quantify over their stated Lean inputs. The comparison covers only
the finite domain above. Neither enlarges the supported interpretation or
authenticates an external event.

## 6. Reproduction, receipts, and remaining work

Use the repository's pinned Lean 4.34.1 and Quint 0.33.1:

```sh
npm --prefix formal/quint ci
make ida-structural-cases
make ida-pilot
```

The component writes `.cache/ida-structural-cases/report.json`, the exported
Lean table, Quint trace and test results, rejected-mutant evidence, and the
compiled declaration inventory. It requires every fingerprinted input to be
tracked and byte-equal to the named Git revision, and checks that source inputs
and runtime overrides remain unchanged during verification. The dedicated
workflow also checks that the receipt names the revision actually checked out.

The authorities and histories used by these new examples are explicit synthetic
inputs. This component does not add signatures for their new certificates.
The existing [authenticated repayment adapter](ida-premise-ingestion.md) and
[signed omission adapter](ida-omission-coverage.md) retain their separate gates.

The extension covers same-profile typed substitution, context reconstruction,
and scoped projection. General schema migration, cross-profile transport,
real evidence admission, and juristic authorization remain separate obligations.
The broader ACT-08 exit still needs an explicit review of the integrated
receipts, supported bounds, interpretation decisions, and repository acceptance
results. Conditional ACT-06, ACT-07, and ACT-09 work keeps its accepted triggers.

