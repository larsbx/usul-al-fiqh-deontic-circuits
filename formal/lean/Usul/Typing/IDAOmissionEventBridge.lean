import Usul.Typing.IDAOmissionSemantics
import Usul.Typing.IDAOmissionWire

/-! A finite, independently pinned event snapshot for omission review.
The snapshot and its trusted pin are separate inputs from the observation batch.
Correspondence of these rows to occurrences outside the source is a separate
contract. -/

namespace Usul.IDA.Omission.EventBridge

open Semantics

structure Row where
  id : Nat
  mode : Mode
  occurredAt : Nat
  capturedAt : Nat
  deriving DecidableEq

def Row.event (row : Row) (scope : Scope) : Event :=
  ⟨scope, row.mode, row.occurredAt⟩

/-- A full, single-scope synthetic checkpoint. The seal is an exclusive
occurrence watermark, expressed in the clock of the scope. -/
structure Checkpoint where
  sourceId : String
  revision : Nat
  scope : Scope
  cutoff : Nat
  sealedThrough : Nat
  rows : List Row
  deriving DecidableEq

def Checkpoint.history (checkpoint : Checkpoint) : History :=
  fun e => ∃ row ∈ checkpoint.rows, row.event checkpoint.scope = e

private def Row.valid (row : Row) (s : Scope) (cutoff : Nat) : Bool :=
  decide (s.opportunity.opensAt ≤ row.occurredAt ∧
    row.occurredAt < s.opportunity.closesAt ∧
    row.occurredAt ≤ row.capturedAt ∧ row.capturedAt ≤ cutoff)

private instance (r : Completion) (e : Event) : Decidable (Represents r e) :=
  inferInstanceAs (Decidable (eventOf r = e))

/-- Link a report to exact event content with a recording time at or after
source capture. The native batch has no source row ID. -/
private def Row.supports (row : Row) (s : Scope) (r : Completion) : Bool :=
  decide (Represents r (row.event s) ∧ row.capturedAt ≤ r.recordedAt)

/-- The active pin comes from trusted configuration. In this bounded model
a revoked or unavailable source has no active pin. Compare the whole ordered
checkpoint so a partial snapshot cannot pass against an unchanged pin. -/
def check (active : Option Checkpoint) (checkpoint : Checkpoint)
    (s : Scope) (cutoff : Nat) (reports : List Completion) : Bool :=
  decide (active = some checkpoint ∧ checkpoint.scope = s ∧ checkpoint.cutoff = cutoff ∧
    s.opportunity.closesAt ≤ checkpoint.sealedThrough ∧ checkpoint.sealedThrough ≤ cutoff ∧
    (checkpoint.rows.map Row.id).Nodup) &&
  checkpoint.rows.all (·.valid s cutoff) &&
  checkpoint.rows.all (fun row =>
    reports.any (fun r => row.supports s r && r.recordedAt ≤ cutoff)) &&
  (reports.all fun r =>
    !r.matches s s.opportunity.closesAt cutoff ||
      checkpoint.rows.any (fun row => row.supports s r)) &&
  !(reports.any (·.malformed s cutoff))

theorem check_correspondence {active : Option Checkpoint} {checkpoint : Checkpoint}
    {s : Scope} {cutoff : Nat} {reports : List Completion}
    (checked : check active checkpoint s cutoff reports = true) :
    active = some checkpoint ∧
      Exhaustive checkpoint.history s cutoff reports ∧
      (∀ effective, SoundFor checkpoint.history s effective cutoff reports) ∧
      reports.any (·.malformed s cutoff) = false := by
  simp only [check, Bool.and_eq_true, decide_eq_true_eq, List.all_eq_true,
    Bool.or_eq_true, Bool.not_eq_true', List.any_eq_true] at checked
  rcases checked with ⟨⟨⟨⟨⟨pin, scope, _, _, _, _⟩, valid⟩, submitted⟩, backed⟩, chronology⟩
  refine ⟨pin, ?_, ?_, chronology⟩
  · intro e qualifies
    obtain ⟨row, member, he⟩ := qualifies.1
    obtain ⟨r, hr, supports, timely⟩ := submitted row member
    obtain ⟨represents, captured⟩ := (show Represents r (row.event s) ∧
      row.capturedAt ≤ r.recordedAt from of_decide_eq_true supports)
    have rowValid : s.opportunity.opensAt ≤ row.occurredAt ∧
        row.occurredAt < s.opportunity.closesAt ∧
        row.occurredAt ≤ row.capturedAt ∧ row.capturedAt ≤ cutoff :=
      of_decide_eq_true (valid row member)
    have occurs := ((represents_iff r (row.event s)).mp represents).2.2
    refine ⟨r, hr, ?_, ?_, timely⟩
    · unfold Represents at represents ⊢
      rw [scope] at he
      exact represents.trans he
    · exact Nat.le_trans (occurs ▸ rowValid.2.2.1) captured
  · intro effective r hr matching
    obtain ⟨rs, visible, ordered, opens, closes, _⟩ :=
      (completion_matches_iff r s effective cutoff).mp matching
    have full : r.matches s s.opportunity.closesAt cutoff = true :=
      (completion_matches_iff r s s.opportunity.closesAt cutoff).mpr
        ⟨rs, visible, ordered, opens, closes, Nat.le_of_lt closes⟩
    obtain ⟨row, member, supports⟩ := (backed r hr).resolve_left (by simp [full])
    simp only [Row.supports, decide_eq_true_eq] at supports
    exact ⟨row, member, by rw [scope]; exact supports.1.symm⟩

/-- These contracts concern the intake of events by the source, independently
of how the observation batch is formed. -/
def CaptureComplete (checkpoint : Checkpoint) (h : History) (s : Scope) : Prop :=
  ∀ e, Qualifies h s e → checkpoint.history e

def CaptureSound (checkpoint : Checkpoint) (h : History) : Prop :=
  ∀ e, checkpoint.history e → h e

theorem exhaustive_of_capture {active : Option Checkpoint} {checkpoint : Checkpoint}
    {h : History} {s : Scope} {cutoff : Nat} {reports : List Completion}
    (checked : check active checkpoint s cutoff reports = true)
    (capture : CaptureComplete checkpoint h s) : Exhaustive h s cutoff reports := by
  intro e qualifies
  exact (check_correspondence checked).2.1 e ⟨capture e qualifies, qualifies.2⟩

theorem sound_of_capture {active : Option Checkpoint} {checkpoint : Checkpoint}
    {h : History} {s : Scope} {effective cutoff : Nat} {reports : List Completion}
    (checked : check active checkpoint s cutoff reports = true)
    (capture : CaptureSound checkpoint h) : SoundFor h s effective cutoff reports := by
  intro r member matching
  exact capture _ ((check_correspondence checked).2.2.1 effective r member matching)

theorem covered_no_completion_iff_of_capture
    {active : Option Checkpoint} {checkpoint : Checkpoint} {h : History}
    {s : Scope} {effective cutoff : Nat} {reports : List Completion} {coverage : Option Coverage}
    (checked : check active checkpoint s cutoff reports = true)
    (complete : CaptureComplete checkpoint h s) (sound : CaptureSound checkpoint h)
    (closed : s.opportunity.closesAt ≤ effective)
    (structuralCoverage : Coverage.Complete s cutoff coverage) :
    evaluate s effective cutoff reports coverage = .coveredNoCompletion ↔ NoQualifying h s :=
  covered_no_completion_iff (exhaustive_of_capture checked complete)
    (sound_of_capture checked sound) (check_correspondence checked).2.2.2 closed structuralCoverage

/-- Compare only the batch decoded for the exact snapshot's scope and cutoff.
Current snapshot resolution and byte authentication belong to existing adapters. -/
def checkView (active : Option Checkpoint) (checkpoint : Checkpoint)
    (expected : Context.Snapshot) (view : Wire.View) : Bool :=
  match Scope.fromSnapshot expected with
  | none => false
  | some s =>
    match Wire.decodeView s view with
    | .error _ => false
    | .ok bound => check active checkpoint s expected.time.cutoff bound.reports

theorem wire_covered_no_completion_sound
    {registry : ActRegistry.Registry} {catalog : Context.Catalog}
    {expected : Context.Snapshot} {view : Wire.View}
    {active : Option Checkpoint} {checkpoint : Checkpoint}
    (reviewed : Wire.review registry catalog expected view = .ok .coveredNoCompletion)
    (checked : checkView active checkpoint expected view = true) :
    Context.resolve registry catalog expected = .ok expected ∧
      ∃ s, Scope.fromSnapshot expected = some s ∧ NoQualifying checkpoint.history s ∧
        ∀ h, CaptureComplete checkpoint h s → NoQualifying h s := by
  obtain ⟨current, s, bound, scope, _, _, decoded, covered⟩ := Wire.review_exact reviewed
  have accepted : check active checkpoint s expected.time.cutoff bound.reports = true := by
    simpa [checkView, scope, decoded] using checked
  exact ⟨current, s, scope,
    covered_no_completion_sound covered (check_correspondence accepted).2.1,
    fun _ complete => covered_no_completion_sound covered (exhaustive_of_capture accepted complete)⟩

#print axioms check_correspondence
#print axioms exhaustive_of_capture
#print axioms sound_of_capture
#print axioms covered_no_completion_iff_of_capture
#print axioms wire_covered_no_completion_sound

end Usul.IDA.Omission.EventBridge
