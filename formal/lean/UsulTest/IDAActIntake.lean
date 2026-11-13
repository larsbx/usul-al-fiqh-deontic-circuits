import Usul.Typing.IDAActIntake
import UsulTest.IDAActRegistry

/-! Synthetic candidate-intake fixtures reuse the ACT-01 inputs and independently
state the expected diagnostic table. Changed metadata is retained in successful
drafts; structural preparation confers no fiqh ruling or source admission. -/

namespace UsulTest.IDAActIntake

open Usul Usul.IDA Usul.IDA.ActRegistry Usul.IDA.ActIntake

/-- Legacy ACT-01 fixtures supply data, never a caller-defined intake signature. -/
def fromEnvelope (e : Envelope) : ActIntake.Input :=
  ⟨e.key, e.definitionDigest, e.registrySnapshot, e.qualifications, e.context, e.action.operands⟩

def inputCase (n : Nat) : ActIntake.Input := fromEnvelope (IDAActRegistry.envelopeCase n)
def registryCase := IDAActRegistry.registryCase

def preparationCode (r i : Nat) : Nat := prepareCode (registryCase r) (inputCase i)

/-- Literal priority oracle. No declaration-mismatch branch exists: the operation
is derived from the selected definition instead of accepted from the caller. -/
def expectedPreparation (r i : Nat) : Nat :=
  if r ∈ [2, 3, 4, 5] then 1
  else if r ∈ [7, 8, 9, 10, 12] then 2
  else if i = 4 then 3
  else if r = 1 then 4
  else if i ∈ [2, 29] then 4
  else if i = 1 then if r = 13 then 5 else 4
  else if i = 3 then 5
  else if r = 6 then 6
  else if i ∈ [7, 8, 33, 35] then 8
  else if i ∈ [24, 25, 26, 27, 28, 30, 31, 32] then 9
  else 0

def draftEnvelope (r i : Nat) : Option Envelope :=
  match prepare (registryCase r) (inputCase i) with
  | .error _ => none
  | .ok draft => some draft.envelope

set_option maxRecDepth 8192 in
set_option maxHeartbeats 0 in
theorem preparation_matrix : ∀ r : Fin 14, ∀ i : Fin 36,
    preparationCode r.val i.val = expectedPreparation r.val i.val := by decide

theorem signature_is_derived :
    inputCase 0 = inputCase 5 ∧ inputCase 0 = inputCase 6 ∧
    draftEnvelope 0 0 = some IDAActRegistry.baseEnvelope ∧
    preparationCode 0 5 = 0 ∧ preparationCode 0 6 = 0 := by decide

theorem same_sort_swap_retained :
    preparationCode 0 0 = 0 ∧ preparationCode 0 9 = 0 ∧
    draftEnvelope 0 9 = some (IDAActRegistry.envelopeCase 9) ∧
    draftEnvelope 0 0 ≠ draftEnvelope 0 9 := by decide

theorem qualifications_and_context_retained :
    draftEnvelope 0 10 = some (IDAActRegistry.envelopeCase 10) ∧
    draftEnvelope 0 14 = some (IDAActRegistry.envelopeCase 14) ∧
    draftEnvelope 0 0 ≠ draftEnvelope 0 10 ∧
    draftEnvelope 0 0 ≠ draftEnvelope 0 14 := by decide

theorem unresolved_is_not_unknown :
    preparationCode 6 0 = 6 ∧ preparationCode 1 0 = 4 ∧
    draftEnvelope 6 0 = none ∧ draftEnvelope 1 0 = none := by decide

theorem malformed_operands_rejected :
    preparationCode 0 7 = 8 ∧ preparationCode 0 8 = 8 ∧
    preparationCode 0 24 = 9 ∧ preparationCode 0 35 = 8 := by decide

end UsulTest.IDAActIntake
