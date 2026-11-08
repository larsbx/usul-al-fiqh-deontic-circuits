import Usul.Typing.IDAJudgment

/- Synthetic contract cases; these are not quotations or source admissions. -/
namespace UsulTest.IDAJudgment

open Usul Usul.IDA.Judgment

set_option maxRecDepth 8192
set_option maxHeartbeats 4000000

def expectedCodec (q a : Nat) : Nat :=
  if q < 5 ∧
      (a = 0 ∨ a = 32 ∨
        (q = 0 ∧ 1 ≤ a ∧ a ≤ 31) ∨
        (1 ≤ q ∧ q ≤ 3 ∧ (a = 33 ∨ a = 34)) ∨
        (q = 4 ∧ (a = 35 ∨ a = 36))) then a + 1 else 0

theorem codec_family_matrix : ∀ q : Fin 6, ∀ a : Fin 38,
    codecCode q.val a.val = expectedCodec q.val a.val := by decide

theorem out_of_range_codes :
    codecCode 5 0 = 0 ∧ codecCode 100 16 = 0 ∧ codecCode 0 100 = 0 ∧
      codecCode 1 100 = 0 ∧ codecCode 4 100 = 0 := by decide

theorem baseline_admitted : ∀ q : Fin 5,
    admissionCode q.val 1 0 = some 0 := by decide

theorem unadmitted_statuses : ∀ q : Fin 5,
    admissionCode q.val 0 0 = some 7 ∧ admissionCode q.val 2 0 = some 7 ∧
      admissionCode q.val 3 0 = some 7 := by decide

theorem all_metadata_bound : ∀ q : Fin 5, ∀ v : Fin 26,
    admissionCode q.val 1 (v.val + 1) ≠ some 0 := by decide

theorem duplicate_id_priority : ∀ q : Fin 5, ∀ s : Fin 4,
    admissionCode q.val s.val 29 = some 6 := by decide

theorem snapshot_binding : ∀ q : Fin 5, ∀ s : Fin 4,
    admissionCode q.val s.val 27 = some 4 := by decide

theorem missing_entry_binding : ∀ q : Fin 5, ∀ s : Fin 4,
    admissionCode q.val s.val 28 = some 5 := by decide

theorem reference_shape : ∀ q : Fin 5, ∀ s : Fin 4,
    admissionCode q.val s.val 30 = some 2 ∧
      admissionCode q.val s.val 31 = some 2 ∧
      admissionCode q.val s.val 33 = some 2 ∧
      admissionCode q.val s.val 34 = some 2 ∧
      admissionCode q.val s.val 35 = some 2 ∧
      admissionCode q.val s.val 36 = some 2 ∧
      admissionCode q.val s.val 37 = some 2 := by decide

theorem evidence_required : ∀ q : Fin 5, ∀ s : Fin 4,
    admissionCode q.val s.val 32 = some 3 := by decide

def syntheticRegistered (raw : RawRecord) : Outcome :=
  validate ⟨1, [⟨1, .admitted, raw⟩]⟩ ⟨1, 1, raw⟩

def syntheticChildRecord (q : Nat) : RawRecord :=
  let raw := syntheticBaseline q
  { raw with scope := { raw.scope with subject := ⟨false, false⟩ } }

theorem typed_capacity :
    outcomeCode (syntheticRegistered (syntheticChildRecord 0)) = 3 ∧
      (∀ q : Fin 4, outcomeCode (syntheticRegistered (syntheticChildRecord (q.val + 1))) = 0) := by
  decide

def syntheticReturnedAnswer (q a : Nat) : Option Nat :=
  let raw := { syntheticBaseline q with answerCode := a }
  match syntheticRegistered raw with
  | .accepted receipt => some (encodePayload receipt.record.question receipt.record.payload)
  | .rejected _ => none

theorem all_taklifi_payloads_preserved : ∀ a : Fin 33,
    syntheticReturnedAnswer 0 a.val = some a.val := by decide

theorem missing_and_suspension_preserved : ∀ q : Fin 5,
    syntheticReturnedAnswer q.val 0 = some 0 ∧
      syntheticReturnedAnswer q.val 32 = some 32 := by decide

theorem partial_permission_distinct :
    syntheticReturnedAnswer 0 30 = some 30 ∧
      syntheticReturnedAnswer 0 4 = some 4 ∧
      syntheticReturnedAnswer 0 31 = some 31 ∧
      syntheticReturnedAnswer 0 0 = some 0 ∧
      syntheticReturnedAnswer 0 32 = some 32 := by decide

def syntheticReturnedGrade : Option (Grade × Bool) :=
  let raw := syntheticBaseline 0
  let raw := { raw with provenance :=
    { raw.provenance with grade := .zann, rujhanKnown := false } }
  match syntheticRegistered raw with
  | .accepted receipt => some (receipt.record.provenance.grade, receipt.record.provenance.rujhanKnown)
  | .rejected _ => none

theorem grade_preserved : syntheticReturnedGrade = some (.zann, false) := by decide

theorem revalidation_cases : ∀ q : Fin 5,
    revalidationCode q.val 0 = some 0 ∧ revalidationCode q.val 1 = some 4 ∧
      revalidationCode q.val 2 = some 7 ∧ revalidationCode q.val 3 = some 7 ∧
      revalidationCode q.val 4 = some 8 ∧ revalidationCode q.val 5 = some 8 ∧
      revalidationCode q.val 6 = some 5 ∧ revalidationCode q.val 7 = some 6 := by decide

theorem export_bounds :
    admissionCode 5 1 0 = none ∧ admissionCode 0 4 0 = none ∧
      admissionCode 0 1 38 = none ∧ revalidationCode 5 0 = none ∧
      revalidationCode 0 8 = none := by decide

end UsulTest.IDAJudgment
