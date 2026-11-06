# UsulTest.Agency in Plain English

Source: [`formal/lean/UsulTest/Agency.lean`](../../../formal/lean/UsulTest/Agency.lean)

These scenarios exercise the joint-agency transition model over complete histories. They use
the same two candidate profiles and restricted setting described in
[Usul.Agency](../Usul/Agency.md) and the [source profile](../../research/agency-source-profile.md).
They test interpretation choices and implementation boundaries without selecting an authoritative
juristic position.

## 1. Scenario coverage

| Theorem | Plain English |
| --- | --- |
| `joint_appointment_blocks_solo` | Without explicit independent permission, neither profile accepts a solo execution. |
| `joint_appointment_accepts_joint` | A joint-only appointment permits a joint execution while both agents are effective. |
| `explicit_permission_accepts_solo` | Explicit independent permission permits a solo execution. |
| `candidate_profiles_diverge` | After revocation but before either agent learns, the immediate profile blocks the joint act and the knowledge-dependent profile permits it. |
| `mixed_knowledge_blocks_joint` | If either participating agent knows of revocation, the knowledge-dependent profile blocks a joint execution. |
| `mixed_knowledge_allows_uninformed_permitted_solo` | With independent permission, B may still execute after A learns but B has not learned. |
| `mixed_knowledge_blocks_informed_solo` | The informed agent cannot use that same permission to execute. |
| `full_notice_blocks_remaining_actor` | After both agents know, the remaining actor cannot execute. |
| `withdrawal_blocks_joint_but_preserves_other_solo` | A's withdrawal prevents the joint act, while B's separate explicit permission still supports B's solo act. This is a documented composition of permission and personal withdrawal. |
| `outside_scope_never_accepts` | Solo and joint attempts outside the fixed mandate fail. |
| `duplicate_task_acceptance_is_blocked` | A second execution of the fixed task fails after a first acceptance. This checks the explicit implementation assumption. |
| `no_notice_before_revocation` | The model cannot deliver notice of a revocation that has not occurred. |
| `no_reappointment` | Withdrawal does not create a fresh appointment cycle in this single-appointment pilot. |
| `acceptance_survives_later_termination` | A proved history accepts jointly, then revokes, informs A, and withdraws B while retaining the joint receipt. |
| `historical_execution_count` | The acceptance/count theorem proves that this historical scenario contains exactly one execution. |

## 2. What these checks mean

Positive examples produce explicit successor states. Negative examples replay to `none`, meaning
the first disabled attempt prevents a successful history. They are useful guards against losing
the independent-permission condition, treating notice to A as notice to B, accepting a joint act
with one ineffective participant, or silently resetting a completed task.

The general results are proved separately in `Usul.Agency`: these examples do not substitute
for its arbitrary-length history theorems or the exhaustive Lean/Quint transition comparison.
