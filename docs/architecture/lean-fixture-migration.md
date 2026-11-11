# Native Lean fixture expectations

The default fixture command is `make fixtures` (also `tests/run_all.sh`). It
runs contextual/sheaf, fatwa, and typed-routing expectations in Lean 4.34.1.
Python coordinates compilation, compares the migration inventory, executes
semantic controls, and writes receipts; it does not answer the fixture queries.
The default gate does not need SWI-Prolog.

Fixture models are downstream consumers of the existing kernel, typed, and
categorical layers. The import-layer checks allow that reuse and explicitly
forbid production kernel modules from importing fixture models. The root
`Usul` aggregator includes them for compiled audit coverage.

## Scope and preserved inventory

The migration starts from main `128f7b92dab524dffbbbe5ea9f2f9318bf2199c9`, after
the M16 roadmap merge. The original Prolog runner was replayed before translation.

| Suite | Original specification | Native implementation / suite | Cases |
|---|---|---|---:|
| Contextual/sheaf | v38 bridge, four v39 concerns, and v39 aggregator | `Usul.Fixtures.Sheaf` / `UsulTest.Fixtures.Sheaf` | 58 |
| Fatwa rule ordering | v40 rules, generated cases, and precedence fixtures | `Usul.Fixtures.Fatwa` / `UsulTest.Fixtures.Fatwa` | 300 |
| Typed routing | v41 typing rules, exported types, and typing fixtures | `Usul.Fixtures.Typing` / `UsulTest.Fixtures.Typing` | 31 |
| Runner controls | Former runner behavior and explicit name/export checks | `Usul.Fixtures.Runner` / `UsulTest.Fixtures.Runner` | 18 |

The [migration reference](../../tests/lean-fixture-reference.json) binds each
legacy fixture's name, polarity, query result, and premise results to SHA-256
hashes of its inputs. The gate compares exact named inventories and values.
Missing/duplicate cases, changed polarity, missing premises, source drift, and
truncated exports fail. Aggregate counts are insufficient. The 389 legacy cases
remain separate from the 18 runner controls.

Reference validation requires the complete 16-file source inventory, exact row
fields, genuine Boolean values, and unique JSON keys. Every source hash must
also match its blob at the recorded reference commit. Missing fields cannot
silently narrow the comparison. Eleven reference-corruption controls exercise
these checks independently of the six export-corruption controls.

Generated data contains inputs to native Lean evaluation, not precomputed
successful Lean query results. Generators have `--check` modes: verification
checks committed outputs without rewriting them. Changed legacy inputs require
an explicit reference replay and corresponding Lean changes.

## Operational behavior retained

### Errors and premises

A `Fixture` contains a name, expected Boolean, total query returning
`Except String Bool`, and premise computations. Typed functions replace
arbitrary predicate calls. Undefined functions fail to compile; modeled
input/evaluation failures are explicit errors. An error cannot satisfy a
negative expectation. Every premise must hold, and negative cases require at
least one premise. Duplicate/invalid names and empty suites fail.

Fixed proposition witnesses pin the runner's important boundaries. The
executable controls also check errors or false premises after an earlier
successful premise. Typed Lean functions have explicit argument binding, so
Prolog's caller-module lookup cannot redirect an unqualified query.

### Context, claims, and membership

The sheaf model separates affect facts, contexts, observations, claims, and
path realizations. Claims cannot create source facts or sections. Alias
ambiguity, object/subject mismatch, inactive modality, lack of control,
quarantined evidence, missing observation, and missing context retain separate
diagnoses. A context failure prevents a second misleading observation diagnosis.
Determined obstructions take precedence over unresolved membership.

Known non-membership differs from unknown membership; unknown remains
undetermined and cannot be reported as gluable. An absent world argument is
rejected, corresponding to the original instantiation-error fixture. Path
checks retain forbidden realization, missing required realization, and
anti-pair reasons independently.

Finite result sets use a deterministic ordering of Lean representations. The
fixtures preserve the tested reason structures and sets; they do not establish
equivalence to Prolog's term ordering for arbitrary conflict orientations.

### Fatwa ordering and routing

The fatwa port evaluates rules in their existing order and retains the selected
rule. Precedence cases distinguish a specific rule from a general fallback.
The bank reuses existing Lean kernel functions. Corpus agreement, documented
oracle gaps, and membership among reported positions remain different tests.
The model does not resolve a disputed case into a universally admitted position.

The routing port preserves declared-field checks, extension reachability,
shared-field restrictions, missing facts, coverage, and relation direction.
Stated facts take precedence over derived facts. Safekeeping negligence does
not settle inquiry negligence. Relation premises must hold; one-way relations
do not become equivalences. Finite traversal has an explicit bound, and
unresolved facts remain unresolved.

Multiple competing derived values remain available to later rules. Only an
originally stated field blocks further derivation for that field. Fixed contracts
check this distinction, the complete typing inventory, and preservation of
existing facts throughout closure. Fatwa contracts also pin first-applicable
rule priority and require every selected decision to be an actual candidate.

## Acceptance gates

`formal/check-lean-fixtures.py` freshly compiles the scoped source dependency
graph into a temporary directory. Stale project build products cannot satisfy
this gate. It verifies the toolchain pin, generator checks, the 407-row execution
table, and the 389-row migration reference.

Every fixture is then challenged with reversed polarity. A newly negative case
receives a true premise when necessary; it must fail for an answer mismatch,
not merely for missing premises. Export-corruption controls exercise absent
headers, missing suites/cases, duplicate rows, invalid answers, and changed
polarity.

All **61 original semantic mutation names** remain required: 25 sheaf guards
or emitters, 29 fatwa rules/equivalences, and seven typing guards. Each mutation
is an exact, uniquely located change in a temporary Lean source copy. Affected
modules must compile before the executable expectations reject the mutant.
Syntax errors, missing imports, timeouts, and compilation failures do not count
as killed semantic mutants. The receipt identifies the failing cases.

The compiled environment is audited using the repository's axiom inventory.
Project axioms and `sorryAx` are forbidden; the allowed foundational axioms
remain `Classical.choice`, `Quot.sound`, and `propext`. Unused private axioms and
admitted-proof probes must be rejected. Fixed contract types prevent a weakened
theorem from satisfying a proof obligation merely by keeping its name.

Compilation rejects unexpected diagnostics. The unchanged `Usul.Refinements`
dependency alone receives `-Dlinter.deprecated=false` for two existing deprecated
lemma names; this advisory-linter option is recorded in the receipt. The kernel
and axiom checks remain enabled.

## Reproduce and inspect

```sh
# Native gate: pinned Lean and Python; no SWI-Prolog required.
make fixtures

# Optional independent legacy replay, including its original 61 mutants.
make fixtures-legacy

# Compare the committed reference with live Prolog.
python3 tests/export_fixture_reference.py

# Explicit maintenance operation after committing an intentional legacy input change.
python3 tests/export_fixture_reference.py --write
```

Reference verification needs the recorded commit in local Git history. Shallow
clones must fetch that history first; verification never silently fetches it.
The fixture workflow checks out full history. Refreshing the reference requires
its 16 legacy inputs to match committed source blobs, so uncommitted input edits
cannot be attributed to an unrelated revision.

Successful native verification writes `.cache/lean-fixtures/report.json`
(revision, source hashes, toolchain, coverage, and controls), `lean.tsv`
(every named query, premise, and result), and `compiled-axioms.json`
(scoped declarations and their axiom dependencies).

Receipts are published only when every gate passes. A modified local working
tree can be checked, but reports `inputs_match_head=false`. Hosted acceptance
checks out the exact PR head, requires that flag to be true, and rejects runtime
overrides. Toolchain installation output is consumed before audit-output parsing.

## Independent references and remaining boundaries

The workflow's Lean job is the default fixture gate. A separate reference job
replays the legacy migration reference and independent Prolog oracles under
`formal/oracle/`. The Prolog sources remain available for differential checking
and existing corpus/routing consumers; this change does not remove those tools.

Acceptance establishes preservation of the declared finite fixture domain and
the listed Lean contracts. It does not establish equivalence for arbitrary
Prolog queries, validate a juristic interpretation, authenticate source passages,
or turn synthetic conflict facts into source-derived rulings. The boundaries in
the [concern separation](separated-concerns.md), [fatwa oracle](fatawa-oracle.md),
and [act-classification roadmap](../research/ida-act-classification-roadmap.md)
remain in force. This migration supplies a Lean test substrate; it does not
complete ACT-00 or any categorical work package.
