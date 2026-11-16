import Usul.Typing.IDAOmissionEventBridge
import UsulTest.IDAContext
import UsulTest.IDAOmissionSemantics

/-! Kernel-checked controls for a separate synthetic source and report input.
These fixtures use the real omission evaluator and wire scope binding. -/

namespace UsulTest.IDAOmissionEventBridge

open Usul.IDA Usul.IDA.Omission Usul.IDA.Omission.Semantics Usul.IDA.Omission.EventBridge
open IDAPaper.NativeOmission (earlyScope lateScope completeCoverage covered_observation)
open UsulTest.IDAOmissionSemantics (actualEvent actualHistory actual_event_qualifies emptyHistory)

def emptyCheckpoint : Checkpoint := ⟨"synthetic.independent", 1, earlyScope, 15, 10, []⟩

def directRow : Row := ⟨1, .direct, 5, 7⟩
def alternateRow : Row := ⟨2, .alternate, 4, 8⟩

def populated : Checkpoint :=
  { emptyCheckpoint with revision := 2, rows := [directRow, alternateRow] }

def direct : Completion := ⟨earlyScope, .direct, 5, 9⟩
def alternate : Completion := ⟨earlyScope, .alternate, 4, 8⟩

theorem empty_checkpoint_clears_covered_observation :
    check (some emptyCheckpoint) emptyCheckpoint earlyScope 15 [] = true ∧
      NoQualifying emptyCheckpoint.history earlyScope := by
  have checked : check (some emptyCheckpoint) emptyCheckpoint earlyScope 15 [] = true := by decide
  exact ⟨checked, covered_no_completion_sound covered_observation (check_correspondence checked).2.1⟩

theorem two_modes_confirmed :
    check (some populated) populated earlyScope 15 [direct, alternate] = true ∧
      evaluate earlyScope 15 15 [direct, alternate] (some completeCoverage) = .completionObserved := by
  decide

theorem missing_event_report_rejected :
    check (some populated) populated earlyScope 15 [] = false ∧
      check (some populated) populated earlyScope 15 [direct] = false ∧
      evaluate earlyScope 15 15 [] (some completeCoverage) = .coveredNoCompletion := by
  decide

theorem fabricated_matching_report_rejected :
    check (some emptyCheckpoint) emptyCheckpoint earlyScope 15 [direct] = false ∧
      check (some populated) populated earlyScope 15
        [direct, alternate, { direct with occurredAt := 6 }] = false := by decide

theorem wrong_scope_rejected :
    check (some populated) populated lateScope 15 [direct, alternate] = false ∧
      check (some populated) populated earlyScope 15
        [{ direct with scope := lateScope }, alternate] = false := by decide

theorem late_report_rejected :
    check (some populated) populated earlyScope 15
      [{ direct with recordedAt := 16 }, alternate] = false := by decide

theorem cutoff_inclusive_but_not_reusable :
    check (some populated) populated earlyScope 15
      [{ direct with recordedAt := 15 }, alternate] = true ∧
      check (some populated) populated earlyScope 16 [direct, alternate] = false := by decide

theorem inconsistent_chronology_rejected :
    check (some populated) populated earlyScope 15
      [{ direct with occurredAt := 9, recordedAt := 5 }, direct, alternate] = false ∧
      check (some populated) populated earlyScope 15
        [{ direct with recordedAt := 6 }, alternate] = false := by decide

theorem source_chronology_checked_even_with_exact_pin :
    let bad := { populated with rows := [{ directRow with capturedAt := 4 }, alternateRow] }
    check (some bad) bad earlyScope 15 [direct, alternate] = false := by decide

theorem report_order_and_duplicates_preserve_existence :
    check (some populated) populated earlyScope 15 [alternate, direct, direct] = true ∧
      evaluate earlyScope 15 15 [alternate, direct, direct] (some completeCoverage) =
        .completionObserved := by decide

theorem duplicate_source_id_rejected_even_with_exact_pin :
    let repeated := { populated with rows := [directRow, directRow, alternateRow] }
    check (some repeated) repeated earlyScope 15 [direct, alternate] = false := by decide

theorem distinct_source_ids_can_project_to_one_event :
    let repeated := { populated with rows := [directRow, { directRow with id := 3 }, alternateRow] }
    check (some repeated) repeated earlyScope 15 [direct, alternate] = true := by decide

theorem revoked_or_rotated_pin_rejected :
    check none populated earlyScope 15 [direct, alternate] = false ∧
      check (some { populated with revision := 3 }) populated earlyScope 15 [direct, alternate] =
        false := by decide

theorem truncated_checkpoint_rejected :
    check (some populated) { populated with rows := [directRow] } earlyScope 15 [direct] =
      false := by decide

theorem reordered_checkpoint_rejected_against_original_pin :
    check (some populated) { populated with rows := [alternateRow, directRow] } earlyScope 15
      [direct, alternate] = false := by decide

theorem unsealed_history_rejected_even_with_exact_pin :
    let unsealed := { emptyCheckpoint with sealedThrough := 9 }
    check (some unsealed) unsealed earlyScope 15 [] = false := by decide

theorem structural_coverage_remains_separate :
    check (some emptyCheckpoint) emptyCheckpoint earlyScope 15 [] = true ∧
      evaluate earlyScope 15 15 [] none = .coverageMissing := by decide

theorem exact_pin_cannot_establish_capture_completeness :
    check (some emptyCheckpoint) emptyCheckpoint earlyScope 15 [] = true ∧
      ¬ CaptureComplete emptyCheckpoint actualHistory earlyScope := by
  refine ⟨by decide, ?_⟩
  intro captures
  obtain ⟨row, member, _⟩ := captures actualEvent actual_event_qualifies
  simp [emptyCheckpoint] at member

theorem exact_pin_cannot_establish_capture_soundness :
    check (some populated) populated earlyScope 15 [direct, alternate] = true ∧
      ¬ CaptureSound populated emptyHistory := by
  refine ⟨by decide, ?_⟩
  intro captures
  exact captures (directRow.event earlyScope) ⟨directRow, by simp [populated], rfl⟩

open UsulTest.IDAContext (base atTick omissionScope)
open UsulTest.IDAActRegistry (baseRegistry)

def wireCheckpoint : Checkpoint :=
  { emptyCheckpoint with scope := omissionScope, cutoff := 12, sealedThrough := 12 }

def closedView : Wire.View :=
  ⟨Wire.schema, Wire.encodeScope omissionScope, [], some ⟨["direct", "alternate"], 12⟩⟩

theorem current_wire_review_proves_source_relative_absence :
    Context.resolve baseRegistry [atTick 12] (atTick 12) = .ok (atTick 12) ∧
      ∃ s, Scope.fromSnapshot (atTick 12) = some s ∧ NoQualifying wireCheckpoint.history s ∧
        ∀ h, CaptureComplete wireCheckpoint h s → NoQualifying h s := by
  exact wire_covered_no_completion_sound (view := closedView)
    (active := some wireCheckpoint) (by decide) (by decide)

theorem wrong_wire_scope_or_stale_context_cannot_qualify :
    checkView (some wireCheckpoint) wireCheckpoint (atTick 12)
      { closedView with scope := Wire.encodeScope lateScope } = false ∧
      Wire.review baseRegistry [base] (atTick 12) closedView ≠ .ok .coveredNoCompletion := by decide

end UsulTest.IDAOmissionEventBridge
