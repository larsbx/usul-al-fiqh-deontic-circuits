# Usul.Agency in Plain English

Source: [`formal/lean/Usul/Agency.lean`](../../../formal/lean/Usul/Agency.lean)

This module models one principal appointing A and B for one fixed task. It proves properties of
complete event histories: acceptance happens at most once, every accepted act stays within the
mandate, joint-only appointments never produce a solo receipt, and each accepted execution has
the required authority at its actual point in the history.

The readings remain **candidates**. The source is *al-Mughnī*, registered work
`ibn_qudama.mughni`, pinned witness `openiti-ibnqudama-mughni-shamela8463`: §3747, printed
5:70, for joint agents, and §3776, printed 5:88–89, for revocation and knowledge. The
[source profile](../../research/agency-source-profile.md) records the passages, competing
positions, and interpretive choices. Requiring both joint actors to remain effective when
only one has learned of revocation is a documented composition of the passages, not an
additional quotation from the source.

## 1. The fixed setting

There are two configuration choices, fixed throughout a run:

| Choice | Meaning |
| --- | --- |
| `immediate` | Issuing revocation ends both agents' authority immediately. |
| `onKnowledge` | Each agent loses authority when that agent learns of the revocation. |
| `independent = false` | A and B can execute only jointly. |
| `independent = true` | Both agents have explicit permission to execute alone; joint execution remains available. |

The independent-permission flag is symmetric. It does not encode an asymmetric grant to only
one agent. The principal, two agents, and scoped task are fixed. Appointment is assumed valid
and known to both when the appointment event occurs. The model allows one appointment, no
reappointment, and at most one accepted execution of this task. The last two restrictions are
implementation assumptions, not general rulings about every agency contract.

## 2. State and events

Six flags record whether appointment has occurred, whether revocation has been issued, whether
each agent knows of that revocation, and whether each agent has withdrawn. The `appointed`
flag means **ever appointed in this run**; it is not a claim that authority remains effective.
A receipt is either empty or records A, B, or both as the accepted actors.

Events appoint, revoke, inform either agent, withdraw either agent, execute alone or jointly,
or stutter. Three additional events represent attempts outside the task's scope and are always
disabled. A disabled attempt has no successor state. `replay` returns failure at the first such
attempt; successful `Run` histories contain enabled events only.

Scope and knowledge are explicit inputs. This pilot does not extract a mandate from contract
language or establish that someone actually received notice. A future application must justify
how its evidence maps to these events before the formal results apply to its operations.

Both execution profiles also require appointment, no withdrawal by a participating agent, and
an empty receipt. The executable knowledge-dependent guard is `!knownA` or `!knownB`.
Knowledge can arise only after revocation in reachable states, so this equals
`!(revoked && known)` on those states. The equivalence is not claimed for malformed raw wire
states, which are included in the finite comparison to test both implementations consistently.

Revocation, notice, and withdrawal may occur after acceptance. They do not erase the historical
receipt. Consequently, a valid invariant is authority **at the accepted event**, not authority
in every subsequent state. Receipt persistence does not decide whether the underlying act is void
(al-bāṭil, الباطل). The model does not decide restitution, third-party effects, or the
continuing legal consequences of a completed transaction.

## 3. History and reachability theorems

`Step` is one enabled transition. `Run` links any finite list of transitions; there is no fixed
trace-length bound in these Lean theorems. `Reachable` means a run starts from the empty initial
state. `Coherent` expresses the causal facts: notice implies revocation, and revocation,
withdrawal, or acceptance implies prior appointment.

| Theorem | Plain English |
| --- | --- |
| `step_eq_some_iff` | Executable success is equivalent to the specified one-step relation. |
| `replay_eq_some_iff` | Executable replay succeeds exactly for histories described by `Run`. |
| `run_deterministic` | A configuration, starting state, and event list determine at most one final state. |
| `initial_coherent` | The empty initial state satisfies the causal conditions. |
| `step_coherent` | Each enabled event preserves those conditions. |
| `run_invariant` | Any state property preserved by every step is preserved by an arbitrary run. |
| `reachable_coherent` | All states reachable from the initial state satisfy the causal conditions. |
| `step_receipt_persistent` | One later enabled step cannot change an already accepted receipt. |
| `run_receipt_persistent` | Any number of later enabled steps preserves that receipt. |
| `acceptedCount_le_one` | The state records zero or one accepted execution. |
| `step_execution_count` | A successful execution adds exactly one to the recorded acceptance count; other events add zero. |
| `run_execution_count` | The final acceptance count equals the starting count plus the number of execution events in the entire history. |
| `run_at_most_once` | A successful history from the initial state contains at most one execution. This follows from the conservation law and the explicit one-task assumption. |
| `run_accepted_iff_one_execution` | A history has a nonempty final receipt exactly when it contains one execution. |
| `step_in_scope` | An enabled event cannot be an outside-scope attempt. |
| `run_in_scope` | Every event in every successful history respects the fixed mandate. |
| `step_joint_only` | Without independent permission, a step preserves an empty-or-joint receipt. |
| `reachable_joint_only` | Without independent permission, no reachable receipt names only A or only B. |

## 4. Termination and historical authority

`AuthorizedExecution` explicitly requires an execution event, a prior appointment, an empty
receipt, correct scope, effective authority for every participant, and joint participation when
independent permission is absent. It cannot certify a stutter or an administrative event.

| Theorem | Plain English |
| --- | --- |
| `step_revoked_persistent` | Revocation cannot be forgotten or undone by a later step. |
| `step_knownA_persistent` | A's knowledge of revocation persists. |
| `step_knownB_persistent` | B's knowledge of revocation persists. |
| `step_immediate_revoked_no_execution` | Under the immediate profile, an issued revocation blocks the next execution. |
| `run_immediate_revoked_no_execution` | Under that profile, every subsequent successful history contains zero executions. |
| `step_fully_notified_no_execution` | Under the knowledge-dependent profile, notice to both agents blocks the next execution. |
| `run_fully_notified_no_execution` | Once both know, no later successful history contains an execution. |
| `step_execution_authorized` | A successful execution satisfies the historical authority conditions. |
| `step_execution_receipt` | A successful execution produces the corresponding nonempty actor receipt. |
| `run_append_iff` | A run can be split at any event-list boundary, with a connecting intermediate state. |
| `run_execution_witness` | An execution anywhere in a history has a reachable pre-state with the required authority, followed by a valid suffix; its actor receipt survives to the final state. |

## 5. Finite wire format and Quint comparison

The state encoder uses six Boolean bits and two receipt bits, giving 256 raw states. Four
configuration codes and thirteen event codes give **13,312 transition inputs**. The exporter
evaluates every one, including disabled inputs; `-1` means disabled, otherwise the result is
the encoded successor. Raw states with notice before revocation are included in this comparison
but are not reachable from the initial state.

| Theorem | Plain English |
| --- | --- |
| `encodeState_lt` | Every semantic state encodes below 256. |
| `decodeState_encodeState` | Decoding an encoded state recovers the original state. |
| `encodeConfig_lt` | Every configuration encodes below 4. |
| `decodeConfig_encodeConfig` | Configuration encoding loses no information. |
| `encodeEvent_lt` | Every event encodes below 13. |
| `decodeEvent_encodeEvent` | Event encoding loses no information. |

These bounds and round trips establish that the finite comparison omits no state, configuration,
or event of this model. The comparison independently evaluates the Lean and Quint relations.
It checks finite executable conformance; it is not a kernel-checked proof of the Quint runtime,
the Lean compiler, a future application, or the correctness of the source interpretation.

Delegation, asymmetric grants, multiple tasks, partial revocation, third-party rights, death,
incapacity, financial liability and compensation (al-ḍamān, الضمان), and open or disputed
factual evidence remain outside this pilot.
