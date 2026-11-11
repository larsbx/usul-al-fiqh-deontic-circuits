import Usul.Typing.IDAPilot

/-! A presentation boundary over checked contextual applications. Report signs
describe the supplied observation rows; they do not assert actual-world truth.
The checked view contains the existing proof-carrying receipt, never a supplied
"verified" flag or agent-authored ruling. -/

namespace Usul.IDA.CaseWorkbench

open Admission Projection Semantics

variable {r : ActRegistry.Registry} {v : Context.Vocabulary}

inductive ReportStatus where
  | unknown | supported | refuted | conflicted
  deriving DecidableEq, Repr

/-- Both signs survive presentation. Absence is not a negative report. -/
def reportStatus (signs : Signs) : ReportStatus :=
  match signs.positive, signs.negative with
  | false, false => .unknown
  | true, false => .supported
  | false, true => .refuted
  | true, true => .conflicted

theorem unknown_iff (s : Signs) :
    reportStatus s = .unknown ↔ s.positive = false ∧ s.negative = false := by
  cases s with
  | mk p n => cases p <;> cases n <;> decide

theorem supported_iff (s : Signs) :
    reportStatus s = .supported ↔ s.positive = true ∧ s.negative = false := by
  cases s with
  | mk p n => cases p <;> cases n <;> decide

theorem refuted_iff (s : Signs) :
    reportStatus s = .refuted ↔ s.positive = false ∧ s.negative = true := by
  cases s with
  | mk p n => cases p <;> cases n <;> decide

theorem conflicted_iff (s : Signs) :
    reportStatus s = .conflicted ↔ s.positive = true ∧ s.negative = true := by
  cases s with
  | mk p n => cases p <;> cases n <;> decide

/-- A summary is reversible to its two existence signs, not to source rows. -/
def reportSigns : ReportStatus → Signs
  | .unknown => ⟨false, false⟩
  | .supported => ⟨true, false⟩
  | .refuted => ⟨false, true⟩
  | .conflicted => ⟨true, true⟩

theorem signs_roundtrip (s : Signs) : reportSigns (reportStatus s) = s := by
  cases s with
  | mk p n => cases p <;> cases n <;> rfl

theorem status_roundtrip (s : ReportStatus) : reportStatus (reportSigns s) = s := by
  cases s <;> rfl

theorem status_injective {a b : Signs} (h : reportStatus a = reportStatus b) : a = b := by
  have hs := congrArg reportSigns h
  simpa [signs_roundtrip] using hs

theorem guard_requires_supported_refuted (rule : Rule) (d : Dependencies)
    (h : Pilot.guard rule d = true) :
    d.scope = rule.scope ∧ reportStatus d.support = .supported ∧
      reportStatus d.exception = .refuted := by
  have exactSigns : d.scope = rule.scope ∧ d.support.positive = true ∧
      d.support.negative = false ∧ d.exception.negative = true ∧ d.exception.positive = false := by
    simpa [Pilot.guard, Bool.and_eq_true, and_assoc] using h
  exact ⟨exactSigns.1, (supported_iff _).mpr ⟨exactSigns.2.1, exactSigns.2.2.1⟩,
    (refuted_iff _).mpr ⟨exactSigns.2.2.2.2, exactSigns.2.2.2.1⟩⟩

theorem support_conflict_blocks (rule : Rule) (d : Dependencies)
    (h : reportStatus d.support = .conflicted) : Pilot.guard rule d = false := by
  have hn := ((conflicted_iff _).mp h).2
  simp [Pilot.guard, hn]

theorem exception_conflict_blocks (rule : Rule) (d : Dependencies)
    (h : reportStatus d.exception = .conflicted) : Pilot.guard rule d = false := by
  have hp := ((conflicted_iff _).mp h).1
  simp [Pilot.guard, hp]

theorem unknown_exception_blocks (rule : Rule) (d : Dependencies)
    (h : reportStatus d.exception = .unknown) : Pilot.guard rule d = false := by
  have hn := ((unknown_iff _).mp h).2
  simp [Pilot.guard, hn]

/-- Constructing a checked view requires the existing contextual receipt.
Draft narrative, imported labels, and report summaries have no such coercion. -/
structure View (p : Plan r v) (rule : Rule) (histories : List (History v)) where
  receipt : Pilot.Receipt p rule histories

variable {p : Plan r v} {rule : Rule} {histories : List (History v)}

def present (receipt : Pilot.Receipt p rule histories) : View p rule histories := ⟨receipt⟩

def View.snapshot (view : View p rule histories) : Context.Snapshot := view.receipt.input.val
def View.dependencies (view : View p rule histories) : Dependencies :=
  project rule view.receipt.input
def View.premises (view : View p rule histories) : List (Substitution.Formula v []) :=
  view.receipt.admission.destination.application.premises
def View.conclusion (view : View p rule histories) : Substitution.Formula v [] :=
  view.receipt.admission.destination.application.conclusion
def View.certificates (view : View p rule histories) : List (Certificate v) :=
  view.receipt.admission.source.certificates ++ view.receipt.admission.destination.certificates

theorem View.exact_snapshot (view : View p rule histories) :
    view.snapshot = view.receipt.admission.destination.application.snapshot :=
  view.receipt.exactSnapshot

theorem View.current_snapshot (view : View p rule histories) :
    Context.resolve r view.receipt.admission.authority.contexts view.snapshot =
      .ok view.snapshot := by
  rw [view.exact_snapshot]
  exact view.receipt.admission.destinationValid.currentSnapshot

theorem View.exact_premises (view : View p rule histories) :
    view.premises = p.destination.premises.map (·.subst p.destinationValuation.grounding) := by
  have h := congrArg Application.premises view.receipt.admission.destinationValid.exactApplication
  exact h

theorem View.exact_certificates (view : View p rule histories) :
    view.receipt.admission.destination.certificates.map Certificate.formula = view.premises := by
  rw [view.exact_premises]
  exact view.receipt.admission.destination_certificates

theorem View.all_source_occurrences (view : View p rule histories) :
    view.certificates = view.receipt.admission.source.certificates ++
      view.receipt.admission.destination.certificates := rfl

theorem View.explicit_report_states (view : View p rule histories) :
    view.dependencies.scope = rule.scope ∧
      reportStatus view.dependencies.support = .supported ∧
      reportStatus view.dependencies.exception = .refuted :=
  guard_requires_supported_refuted rule view.dependencies view.receipt.guardPassed

theorem View.nonvacuous (view : View p rule histories) :
    compatible (Pilot.destinationPoints p histories) p.destination.premises ≠ [] :=
  view.receipt.compatible_history

/-- This theorem deliberately retains the premise-satisfaction hypothesis. -/
theorem View.conditional_sound (view : View p rule histories) (h : History v)
    (empty : Valuation []) (hp : ModelsPremises h p.destinationValuation p.destination.premises) :
    Satisfies h empty view.conclusion := view.receipt.conditional_sound h empty hp

end Usul.IDA.CaseWorkbench
