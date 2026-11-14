import Usul.Typing.IDACaseWorkbench
import UsulTest.IDAPremiseIngestion

/-! The accepted ACT-08 synthetic fixture supplies all authorities. These
fixtures establish modeled checking, not external source authentication. -/

namespace UsulTest.IDACaseWorkbench

open Usul.IDA CaseWorkbench
open IDAPilot (plan rule histories)

def sourceBoundTrial (revision : String) := Pilot.run plan rule (histories 2)
  (PremiseIngestion.scopedAuthority (IDAPremiseIngestion.authority revision)
    IDAPremiseIngestion.certificates IDAPremiseIngestion.sources)
  IDAPremiseIngestion.source IDAPremiseIngestion.destination

def sourceBoundCode : Nat := match sourceBoundTrial "synthetic-case-workbench" with
  | .ok _ => 0
  | .error _ => 1

theorem source_bound_baseline_checked : sourceBoundCode = 0 := by decide

theorem source_bound_destination_unchanged :
    IDAPremiseIngestion.destination.application.snapshot = IDAPilot.destinationSnapshot 9 := rfl

theorem four_report_states :
    ([⟨false, false⟩, ⟨true, false⟩, ⟨false, true⟩, ⟨true, true⟩] : List Projection.Signs).map
      reportStatus = [.unknown, .supported, .refuted, .conflicted] := by decide

theorem missing_and_conflicting_reports_block :
    IDAPilot.resultCode 1 2 0 = 5 ∧ IDAPilot.resultCode 11 2 0 = 5 ∧
      IDAPilot.resultCode 13 2 0 = 5 ∧ IDAPilot.resultCode 15 2 0 = 5 := by decide

theorem nonvacuity_controls :
    IDAPilot.resultCode 9 0 0 = 6 ∧ IDAPilot.resultCode 9 1 0 = 7 ∧
      IDAPilot.resultCode 9 2 0 = 0 ∧ IDAPilot.resultCode 9 3 0 = 0 := by decide

theorem current_authority_controls :
    (List.range 6).map (IDAPilot.resultCode 9 2) = [0, 1, 1, 2, 3, 4] := by decide

theorem kind_does_not_transfer_guard :
    (IDAPilot.destinationSnapshot 9).envelope.key =
      (IDAPilot.destinationSnapshot 13).envelope.key ∧
      IDAPilot.resultCode 9 2 0 = 0 ∧ IDAPilot.resultCode 13 2 0 = 5 := by decide


/-- The source-bound baseline has a compatible candidate, while a history
outside the candidate population falsifies its exact recorded conclusion. -/
theorem admission_and_robustness_do_not_imply_truth :
    ∃ receipt : Pilot.Receipt plan rule (histories 2),
      sourceBoundTrial "synthetic-case-workbench" = .ok receipt ∧
      Semantics.compatible (Pilot.destinationPoints plan (histories 2))
        plan.destination.premises ≠ [] ∧
      ¬ Semantics.Satisfies (IDASemantics.history 0)
        (show Semantics.Valuation [] from fun _ x => nomatch x)
        (present receipt).conclusion := by
  cases h : sourceBoundTrial "synthetic-case-workbench" with
  | error reason =>
    have impossible := source_bound_baseline_checked
    simp [sourceBoundCode, h] at impossible
  | ok receipt =>
    refine ⟨receipt, rfl, receipt.compatible_history, ?_⟩
    change ¬ Semantics.Satisfies (IDASemantics.history 0)
      (show Semantics.Valuation [] from fun _ x => nomatch x)
      receipt.admission.destination.application.conclusion
    rw [receipt.admission.destinationValid.exactApplication]
    change Semantics.evaluate (IDASemantics.history 0)
      (show Semantics.Valuation [] from fun _ x => nomatch x)
      ((plan.conclusion.subst plan.arrow.substitution).subst
        plan.destinationValuation.grounding) ≠ true
    decide

end UsulTest.IDACaseWorkbench
