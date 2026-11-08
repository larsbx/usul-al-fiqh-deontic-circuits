import Usul.IDA

namespace UsulTest.IDA
open Usul.IDA

/-- Wire order is H,K,M,N,W. -/
theorem wire_tags :
    encodeHukm .haram = 0 ∧ encodeHukm .makruh = 1 ∧ encodeHukm .mubah = 2 ∧
    encodeHukm .mandub = 3 ∧ encodeHukm .wajib = 4 := by decide

theorem all_masks_decode : ∀ n : Fin 31, (decodeConstraint (n.val + 1)).isSome = true := by
  decide

theorem all_inputs_decode : ∀ n : Fin 33, (decodeInput n.val).isSome = true := by decide

theorem all_key_variants_decode : ∀ n : Fin 8, (keyVariant n.val).isSome = true := by decide

theorem missing_required : refineCode 0 0 31 = some 0 ∧ refineCode 0 31 0 = some 0 := by decide

theorem suspension_priority :
    refineCode 0 0 32 = some 32 ∧ refineCode 0 32 0 = some 32 := by decide

theorem key_priority : ∀ k : Fin 7,
    refineCode (k.val + 1) 32 32 = some 34 ∧
    refineCode (k.val + 1) 0 0 = some 34 := by decide

theorem intersect_compatible : refineCode 0 7 6 = some 6 := by decide

theorem intersect_conflict : refineCode 0 1 16 = some 33 := by decide

theorem all_constraint_identity_on_known : ∀ n : Fin 31,
    refineCode 0 31 (n.val + 1) = some (n.val + 1) := by decide

theorem mubah_explicit : refineCode 0 4 31 = some 4 := by decide

theorem invalid_codes :
    meetCode 5 0 = none ∧ meetCode 0 5 = none ∧
    joinCode 5 0 = none ∧ sigmaCode 5 = none ∧
    refineCode 8 1 1 = none ∧ refineCode 0 33 1 = none ∧
    refineCode 0 1 33 = none ∧ refineCode 100 100 100 = none := by decide

/-! ## Structured targets; fixture codes select full expressions. -/

theorem target_fixture_admission : ∀ code : Fin 28,
    targetAdmitCode code.val = some (if code.val < 20 then 1 else 0) := by decide

theorem target_reconstruction :
    targetRefineCode 0 1 0 = some 16 ∧ targetRefineCode 1 0 5 = some 4 := by decide

theorem target_distinctions :
    targetRefineCode 0 2 0 = some 34 ∧
    targetRefineCode 0 5 0 = some 34 ∧
    targetRefineCode 0 6 0 = some 34 ∧
    targetRefineCode 0 7 0 = some 34 ∧
    targetRefineCode 0 8 0 = some 34 ∧
    targetRefineCode 8 9 0 = some 34 ∧
    targetRefineCode 8 10 0 = some 34 ∧
    targetRefineCode 8 11 0 = some 34 ∧
    targetRefineCode 8 12 0 = some 34 ∧
    targetRefineCode 8 13 0 = some 34 ∧
    targetRefineCode 0 14 0 = some 34 ∧
    targetRefineCode 14 17 0 = some 34 ∧
    targetRefineCode 0 18 0 = some 34 ∧
    targetRefineCode 0 19 0 = some 34 := by decide

theorem malformed_targets_rejected : ∀ code : Fin 8,
    targetRefineCode (code.val + 20) 0 5 = some 35 ∧
    targetRefineCode 0 (code.val + 20) 4 = some 35 := by decide

theorem target_selector_bounds :
    targetAdmitCode 28 = none ∧ targetAdmitCode 100 = none ∧
    targetRefineCode 28 0 0 = none ∧ targetRefineCode 0 28 0 = none ∧
    targetRefineCode 0 0 6 = none := by decide

end UsulTest.IDA
