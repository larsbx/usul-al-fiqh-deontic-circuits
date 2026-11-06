import Usul.Agency

/-!
# Joint-agency scenarios

These fixtures exercise whole histories: composition of permission with revocation, asymmetric
knowledge, withdrawal, mandate scope, and the explicit one-task acceptance assumption. Their
candidate source status is inherited from `Usul.Agency`; they do not adopt a juristic opinion.
-/

namespace UsulTest.Agency

open Usul.Agency

def jointImmediate : Config := ⟨.immediate, false⟩
def soloImmediate : Config := ⟨.immediate, true⟩
def jointOnKnowledge : Config := ⟨.onKnowledge, false⟩
def soloOnKnowledge : Config := ⟨.onKnowledge, true⟩

theorem joint_appointment_blocks_solo :
    replay jointImmediate initial [.appoint, .executeA] = none ∧
    replay jointOnKnowledge initial [.appoint, .executeB] = none := ⟨rfl, rfl⟩

theorem joint_appointment_accepts_joint :
    replay jointImmediate initial [.appoint, .executeJoint] =
      some { initial with appointed := true, accepted := .joint } := rfl

theorem explicit_permission_accepts_solo :
    replay soloImmediate initial [.appoint, .executeA] =
      some { initial with appointed := true, accepted := .a } := rfl

/-- The same post-revocation, pre-knowledge trace distinguishes the two candidate profiles. -/
theorem candidate_profiles_diverge :
    replay jointImmediate initial [.appoint, .revoke, .executeJoint] = none ∧
    replay jointOnKnowledge initial [.appoint, .revoke, .executeJoint] =
      some { initial with appointed := true, revoked := true, accepted := .joint } :=
  ⟨rfl, rfl⟩

/-- Candidate composition: one informed actor prevents their joint act. -/
theorem mixed_knowledge_blocks_joint :
    replay jointOnKnowledge initial [.appoint, .revoke, .notifyA, .executeJoint] = none ∧
    replay soloOnKnowledge initial [.appoint, .revoke, .notifyB, .executeJoint] = none :=
  ⟨rfl, rfl⟩

/-- Knowledge belongs to an actor; A's notice does not silently become B's notice. -/
theorem mixed_knowledge_allows_uninformed_permitted_solo :
    replay soloOnKnowledge initial [.appoint, .revoke, .notifyA, .executeB] =
      some { initial with
        appointed := true, revoked := true, knownA := true, accepted := .b } := rfl

theorem mixed_knowledge_blocks_informed_solo :
    replay soloOnKnowledge initial [.appoint, .revoke, .notifyA, .executeA] = none := rfl

theorem full_notice_blocks_remaining_actor :
    replay soloOnKnowledge initial [.appoint, .revoke, .notifyA, .notifyB, .executeB] =
      none := rfl

theorem withdrawal_blocks_joint_but_preserves_other_solo :
    replay jointImmediate initial [.appoint, .withdrawA, .executeJoint] = none ∧
    replay soloImmediate initial [.appoint, .withdrawA, .executeB] =
      some { initial with appointed := true, withdrawnA := true, accepted := .b } :=
  ⟨rfl, rfl⟩

theorem outside_scope_never_accepts :
    replay soloImmediate initial [.appoint, .executeAOutsideScope] = none ∧
    replay soloOnKnowledge initial [.appoint, .executeBOutsideScope] = none ∧
    replay jointImmediate initial [.appoint, .executeJointOutsideScope] = none :=
  ⟨rfl, rfl, rfl⟩

/-- This is an implementation assumption for one fixed task, not a general wakāla ruling. -/
theorem duplicate_task_acceptance_is_blocked :
    replay soloImmediate initial [.appoint, .executeA, .executeB] = none := rfl

theorem no_notice_before_revocation :
    replay soloOnKnowledge initial [.appoint, .notifyA] = none := rfl

theorem no_reappointment :
    replay soloImmediate initial [.appoint, .withdrawA, .appoint] = none := rfl

def historicalReceipt : State :=
  { initial with
    appointed := true, revoked := true, knownA := true, withdrawnB := true, accepted := .joint }

/-- A valid receipt records the time of the act; later termination does not erase history. -/
theorem acceptance_survives_later_termination :
    Run jointImmediate initial
      [.appoint, .executeJoint, .revoke, .notifyA, .withdrawB] historicalReceipt :=
  (replay_eq_some_iff _).mp rfl

theorem historical_execution_count :
    executions [.appoint, .executeJoint, .revoke, .notifyA, .withdrawB] = 1 := by
  exact (run_accepted_iff_one_execution acceptance_survives_later_termination).mp
    (by decide)

end UsulTest.Agency
