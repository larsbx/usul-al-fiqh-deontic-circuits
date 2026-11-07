import Usul.AgencyMask

namespace UsulTest.AgencyMask

open Usul.Agency (Event State initial)
open Usul.AgencyMask

def onlyA : Config := ⟨.onKnowledge, true, false⟩
def onlyB : Config := ⟨.onKnowledge, false, true⟩

theorem singleton_masks_block_the_other_actor :
    replay onlyA initial [.appoint, .executeB] = none ∧
    replay onlyB initial [.appoint, .executeA] = none :=
  ⟨rfl, rfl⟩

theorem actor_swap_yields_feasible_withdrawal_histories :
    Run onlyA initial [.appoint, .withdrawB, .executeA]
      { initial with appointed := true, withdrawnB := true, accepted := .a } ∧
    Run onlyB initial [.appoint, .withdrawA, .executeB]
      { initial with appointed := true, withdrawnA := true, accepted := .b } :=
  ⟨replay_run rfl, replay_run rfl⟩

theorem actor_swap_yields_feasible_mixed_knowledge_histories :
    Run onlyA initial [.appoint, .revoke, .notifyB, .executeA]
      { initial with appointed := true, revoked := true, knownB := true, accepted := .a } ∧
    Run onlyB initial [.appoint, .revoke, .notifyA, .executeB]
      { initial with appointed := true, revoked := true, knownA := true, accepted := .b } :=
  ⟨replay_run rfl, replay_run rfl⟩

theorem withdrawn_holder_cannot_transfer_permission :
    replay onlyA initial [.appoint, .withdrawA, .executeA] = none ∧
    replay onlyA initial [.appoint, .withdrawA, .executeB] = none ∧
    replay onlyB initial [.appoint, .withdrawB, .executeB] = none ∧
    replay onlyB initial [.appoint, .withdrawB, .executeA] = none :=
  ⟨rfl, rfl, rfl, rfl⟩

theorem informed_holder_cannot_transfer_permission :
    replay onlyA initial [.appoint, .revoke, .notifyA, .executeA] = none ∧
    replay onlyA initial [.appoint, .revoke, .notifyA, .executeB] = none ∧
    replay onlyB initial [.appoint, .revoke, .notifyB, .executeB] = none ∧
    replay onlyB initial [.appoint, .revoke, .notifyB, .executeA] = none :=
  ⟨rfl, rfl, rfl, rfl⟩

theorem mixed_knowledge_blocks_the_joint_attempt :
    replay onlyA initial [.appoint, .revoke, .notifyB, .executeJoint] = none ∧
    replay onlyB initial [.appoint, .revoke, .notifyA, .executeJoint] = none :=
  ⟨rfl, rfl⟩

end UsulTest.AgencyMask
