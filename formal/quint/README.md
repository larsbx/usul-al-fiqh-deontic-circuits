# Joint agency in Quint

This finite pilot models two agents appointed together for one scoped act. It
keeps the default joint requirement distinct from explicit independent
permission, and keeps actual revocation distinct from each agent's knowledge.
The source selections, alternative narration, and interpretive limits are in
[the source profile](../../docs/research/agency-source-profile.md). The broader
implementation and proof account is in
[the pilot report](../../docs/research/agency-pilot.md).

`agency.qnt` implements its transition function independently of
[`Usul/Agency.lean`](../lean/Usul/Agency.lean). Neither implementation is generated
from the other. A small shared **wire contract** allows their outputs to be
compared without sharing transition logic.

## Run the model checks

Install Node.js 22 or later and the Lean toolchain pinned by
[`../lean/lean-toolchain`](../lean/lean-toolchain). From this directory:

```sh
npm ci --ignore-scripts --no-fund --no-audit
npm run check
```

The check uses the locally pinned **Quint 0.33.1** and its TypeScript evaluator;
it does not download the Rust evaluator, Apalache, or TLC. It builds
`Usul.Agency`, runs `lake env lean --run scripts/ExportAgency.lean`, evaluates
the independent Quint model, and fails if either executable is unavailable.
There is no cached-export or JavaScript-transition fallback. The checker inherits
the invoking environment, so `lake` must be on `PATH`.

`npm run typecheck` and `npm test` are narrower development commands.
`npm run check` runs the model scenarios, cross-language parity, graph checks,
and negative controls. The repository's **complete** `make agency` gate also
runs the separate locked-source checker and Lean axiom audit; direct
`npm run check` does not claim to have run those two checks. See the
[pilot report](../../docs/research/agency-pilot.md#reproduce) for the full command.
Set `AGENCY_KEEP_CHECK=1` to retain temporary diagnostics after a run; normal
runs remove their temporary files.

## What the gate establishes

| Check | Coverage | Meaning |
|---|---|---|
| Quint typecheck | Both specification files | Parsing, types, and effects are checked by the pinned tool. |
| Deterministic unit tests | 9 tests | Includes stateful execution, rejection, history, and complete codec round trips. |
| Declared scenarios | 26 cases in `scenarios.json` | Manually written expected outcomes are checked in Quint and against both exported tables. |
| One-step parity | **13,312 inputs** | Every one of 4 configurations × 256 raw state codes × 13 event codes is compared, including disabled transitions. |
| Complete reachable graph | **244 configuration/state pairs and 750 enabled edges** | Starting from state 0 in each configuration, breadth-first traversal checks every reachable edge and state against the stated safety requirements. Stuttering edges are included. |
| Negative controls | 5 deliberately faulty Quint models | Declared scenarios reject dropping the joint requirement, conflating revocation with knowledge in either direction, ignoring personal withdrawal, and erasing a receipt on revocation. |
| Sampled action smoke check | 100 runs of at most 20 steps, seed `20261106` | Exercises the stateful wrapper and its safety monitor. This is sampling; the exhaustive checks above do not rely on its coverage. |

The reachable graph has 41 states/123 enabled edges for immediate revocation
with joint permission; 81/247 for immediate revocation with independent
permission; 41/124 for the knowledge profile with joint permission; and 81/256
for the knowledge profile with independent permission.

The graph requirements include well-formed lifecycle states, preservation of an
already accepted execution, rejection of every later execution event (even one
that would leave the same receipt), the joint requirement, rejection outside scope,
and each participating agent's authority **in the state before execution**.
Checking current authority after a later revocation would incorrectly reject a
valid historical execution.

The one-step table is evaluated by `table.qnt`: its deterministic initialization
computes the complete vector using `range(...).foldl(...)`. A single zero-step
`quint run` serializes that already complete vector in ITF format. The CLI's
`--max-samples 1` is an export mechanism here; it does not sample the 13,312
inputs. `check.mjs` checks the export's dimensions, ordering, and range before
comparison. It does not implement a third transition function.

No result here establishes that the chosen reading exhausts Hanbali doctrine,
that an arbitrary real-world transaction is valid, or that a general translation
from Lean to Quint is sound. Agreement can preserve a shared interpretive
mistake; the source profile and manually declared cases remain reviewable
obligations. No `quint verify` or external model-checker result is claimed.

### Verification receipts

After all model checks pass, `.out/` contains `report.json`, the independently
exported `lean-transitions.csv` and `quint-transitions.csv`, and the Quint
vector in `quint-transitions.itf.json`. The report records actual tool versions,
domain and scenario counts, graph counts, mutant names and assertion diagnostics,
and the explicitly sampled smoke-check bounds. It includes SHA-256 hashes and
byte counts for both model implementations, their export and check code,
fixtures, tool pins, the source profile, the registry/lock files, and the three
export artifacts.

The ITF state vector is retained unchanged; volatile top-level CLI timestamps
and description are normalized so that receipts are deterministic for the same
inputs and tool versions. No wall-clock timestamp or checkout-specific absolute
path is recorded. Input hashes are rechecked before publication, so an edit
during a running check requires a rerun. A fresh run removes an older `.out` and
publishes the replacement atomically only after success. Source-check and Lean
axiom-audit receipts are separate artifacts produced by `make agency`; they are
not inferred from this model-conformance report.

## Wire contract

There are four fixed configurations. The independent-permission flag applies
symmetrically to both agents and does not change during a run.

| Code | Revocation profile | Independent permission |
|---:|---|---|
| 0 | Immediate | No |
| 1 | Immediate | Yes |
| 2 | On the individual agent's knowledge | No |
| 3 | On the individual agent's knowledge | Yes |

The six lifecycle fields occupy bits 0–5:

| Weight | Field |
|---:|---|
| 1 | Appointed |
| 2 | Revoked by the principal |
| 4 | Agent A knows of revocation |
| 8 | Agent B knows of revocation |
| 16 | Agent A withdrew |
| 32 | Agent B withdrew |

The historical acceptance field contributes `64 × ordinal`, where `none = 0`,
`A = 1`, `B = 2`, and `joint = 3`. Thus all raw states have codes 0–255.
The initial state is 0. Some raw states are unreachable; comparing them is
useful for implementation parity and is separate from reachable-state safety.

| Event code | Event | Required precondition |
|---:|---|---|
| 0 | Appoint | Not previously appointed |
| 1 | Revoke | Appointed and not already revoked |
| 2 | Notify A | Revoked and A does not yet know |
| 3 | Notify B | Revoked and B does not yet know |
| 4 | A withdraws | Appointed and A has not withdrawn |
| 5 | B withdraws | Appointed and B has not withdrawn |
| 6 | A executes within scope | No prior execution; A has authority; independent permission |
| 7 | B executes within scope | No prior execution; B has authority; independent permission |
| 8 | Joint execution within scope | No prior execution; both agents have authority |
| 9 | Stutter | Always enabled |
| 10 | A attempts execution outside scope | Disabled |
| 11 | B attempts execution outside scope | Disabled |
| 12 | Joint attempt outside scope | Disabled |

An agent has modeled authority when appointed, not withdrawn, and not cut off
by the chosen revocation profile. The immediate profile checks the principal's
revocation; the alternative profile checks the participating agent's knowledge.
The table returns a next-state code, or **−1** when a transition is disabled.
Its row ordering is configuration, then state, then event, all ascending.

## Rejected attempts and histories

`scenarios.json` declares each attempted event and its expected output code.
The scenario runner records `-1` for a rejected attempt and lets the next
attempt use the last successfully reached state. This is an explicit test-runner
convention. A rejected attempt is **not** an enabled transition, and does not
become a stutter event in the model. Lean's replay function instead aborts on a
disabled event; the parity gate compares the one-step relation, and applies the
same stated test-runner convention to each exported table.

For example, configuration 3 with attempts
`appoint, revoke, notifyA, executeA, executeB` has outputs
`1, 3, 7, -1, 135`: A's attempt is rejected, and B can still execute under
independent permission in the knowledge profile.

Only one appointment and one accepted execution are modeled. Lifecycle flags
are monotone. Administrative events can occur after acceptance so that later
revocation, notice, or withdrawal can be checked for preservation of history.
There is no reappointment, restoration of authority, changing scope, repeated
transaction, agent death/incapacity, subdelegation, or adjudication of disputed
facts in this pilot. The source profile separates sourced rules from these
deliberate modeling bounds.

## Negative controls

The harness creates temporary copies of the actual `agency.qnt`, changes one
identified clause, typechecks the mutant, and reruns a named scenario:

| Deliberate defect | Scenario that must fail |
|---|---|
| Remove independent permission from the solo guard | `jointSoloARejected` |
| Replace immediate revocation with the agent's knowledge | `immediateRevocationBeforeNotice` |
| Replace the knowledge profile with immediate revocation | `knowledgeJointBeforeNotice` |
| Ignore personal withdrawal in the authority guard | `withdrawalDespiteAbsentNotice` |
| Clear the recorded execution on revocation | `acceptedHistoryPersists` |

The gate requires the expected scenario to report Quint's assertion-failure
diagnostic, not merely a nonzero process exit. A parser error, failed tool
startup, or unrelated runtime error does not count as detecting a defect.
No repository file is mutated by these controls.

## Files

- `agency.qnt`: typed operational model, stateful wrapper, and unit tests.
- `table.qnt`: deterministic full-table evaluation using the actual Quint model.
- `scenarios.json`: independently declared scenario expectations.
- `check.mjs`: required checks, independent executable comparison, graph traversal,
  and deliberately faulty variants.
- `package.json` / `package-lock.json`: exact Quint version and locked dependencies.

Tool behavior is documented in the official
[Quint CLI reference](https://quint.sh/docs/quint) and
[built-in operators reference](https://quint.sh/docs/builtin). The package pin
is authoritative for this pilot's executable behavior.
