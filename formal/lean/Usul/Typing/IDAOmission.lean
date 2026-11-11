import Usul.Typing.IDAContext

/-! A bounded observation review of an omission opportunity. Completion
reports and coverage are inputs from a supplied observation view. Neither
their shape nor the resulting status authenticates those inputs. -/

namespace Usul.IDA.Omission

inductive Mode where
  | direct | alternate
  deriving DecidableEq, Repr

/-- One clock version and one exact description with its named parties. -/
structure Scope where
  action : Action
  opportunity : Opportunity
  accountable : EntityRef
  performer : Operand
  definition : ActRegistry.KindKey
  definitionDigest : List Nat
  clockVersion : Nat
  deriving DecidableEq, Repr

def Scope.fromSnapshot (s : Context.Snapshot) : Option Scope :=
  s.opportunity.map fun o =>
    ⟨s.envelope.action, o, s.inquiry.accountable, s.inquiry.performer,
      s.envelope.key, s.envelope.definitionDigest, s.time.clockVersion⟩

structure Completion where
  scope : Scope
  mode : Mode
  occurredAt : Nat
  recordedAt : Nat
  deriving DecidableEq, Repr

structure Coverage where
  scope : Scope
  modes : List Mode
  recordedAt : Nat
  deriving DecidableEq, Repr

def Completion.visible (r : Completion) (s : Scope) (cutoff : Nat) : Bool :=
  r.scope == s && r.recordedAt ≤ cutoff

def Completion.malformed (r : Completion) (s : Scope) (cutoff : Nat) : Bool :=
  r.visible s cutoff && r.recordedAt < r.occurredAt

/-- The opportunity is half-open. Effective time limits the observed event,
and recording time limits its visibility to the evaluator. -/
def Completion.matches (r : Completion) (s : Scope) (effective cutoff : Nat) : Bool :=
  r.visible s cutoff && r.occurredAt ≤ r.recordedAt &&
    s.opportunity.opensAt ≤ r.occurredAt && r.occurredAt < s.opportunity.closesAt &&
    r.occurredAt ≤ effective

/-- This bounded model recognizes exactly two performance modes. A coverage
claim must name both modes and be recorded at or after closure. -/
def Coverage.Complete (s : Scope) (cutoff : Nat) : Option Coverage → Prop
  | none => False
  | some c =>
    c.scope = s ∧ s.opportunity.closesAt ≤ c.recordedAt ∧ c.recordedAt ≤ cutoff ∧
      Mode.direct ∈ c.modes ∧ Mode.alternate ∈ c.modes

instance (s : Scope) (cutoff : Nat) (coverage : Option Coverage) :
    Decidable (Coverage.Complete s cutoff coverage) := by
  cases coverage <;> unfold Coverage.Complete <;> infer_instance

inductive Outcome where
  | invalidObservation | completionObserved | pending | coverageMissing | coveredNoCompletion
  deriving DecidableEq, Repr

def evaluate (s : Scope) (effective cutoff : Nat) (reports : List Completion)
    (coverage : Option Coverage) : Outcome :=
  if reports.any (·.malformed s cutoff) then .invalidObservation
  else if reports.any (·.matches s effective cutoff) then .completionObserved
  else if s.opportunity.closesAt ≤ effective then
    if Coverage.Complete s cutoff coverage then .coveredNoCompletion else .coverageMissing
  else .pending

theorem covered_iff (s : Scope) (effective cutoff : Nat) (reports : List Completion)
    (coverage : Option Coverage) :
    evaluate s effective cutoff reports coverage = .coveredNoCompletion ↔
      reports.any (·.malformed s cutoff) = false ∧
      reports.any (·.matches s effective cutoff) = false ∧
      s.opportunity.closesAt ≤ effective ∧ Coverage.Complete s cutoff coverage := by
  cases hm : reports.any (·.malformed s cutoff) <;>
    cases hr : reports.any (·.matches s effective cutoff) <;>
    by_cases ht : s.opportunity.closesAt ≤ effective <;>
    by_cases hc : Coverage.Complete s cutoff coverage <;>
    simp [evaluate, hm, hr, ht, hc]

theorem observed_precedes_coverage (s : Scope) (effective cutoff : Nat)
    (reports : List Completion) (coverage : Option Coverage)
    (hm : reports.any (·.malformed s cutoff) = false)
    (hr : reports.any (·.matches s effective cutoff) = true) :
    evaluate s effective cutoff reports coverage = .completionObserved := by
  simp [evaluate, hm, hr]

theorem closing_boundary_excluded (r : Completion) (s : Scope) (effective cutoff : Nat)
    (h : r.occurredAt = s.opportunity.closesAt) :
    r.matches s effective cutoff = false := by
  simp [Completion.matches, h]

theorem opening_boundary_included (r : Completion) (s : Scope) (effective cutoff : Nat)
    (h : r.occurredAt = s.opportunity.opensAt) (hs : s.opportunity.WellFormed)
    (hv : r.visible s cutoff = true) (hr : r.occurredAt ≤ r.recordedAt)
    (he : r.occurredAt ≤ effective) : r.matches s effective cutoff = true := by
  rw [h] at hr he
  simp [Completion.matches, hv, hr, he, h, hs.2.2]

theorem unseen_append (s : Scope) (effective cutoff : Nat) (reports : List Completion)
    (coverage : Option Coverage) (r : Completion) (h : cutoff < r.recordedAt) :
    evaluate s effective cutoff (reports ++ [r]) coverage =
      evaluate s effective cutoff reports coverage := by
  simp [evaluate, Completion.malformed, Completion.matches, Completion.visible, Nat.not_le.mpr h]

/-- Resolve the current full snapshot first. A current snapshot without an
omission opportunity has no omission assessment. -/
def review (r : ActRegistry.Registry) (catalog : Context.Catalog) (expected : Context.Snapshot)
    (reports : List Completion) (coverage : Option Coverage) :
    Except Context.Failure (Option Outcome) :=
  match Context.resolve r catalog expected with
  | .error why => .error why
  | .ok actual =>
    .ok ((Scope.fromSnapshot actual).map fun s =>
      evaluate s actual.envelope.context.effectiveAt actual.time.cutoff reports coverage)

theorem review_current {r : ActRegistry.Registry} {catalog : Context.Catalog}
    {expected : Context.Snapshot} {reports : List Completion} {coverage : Option Coverage}
    {result : Option Outcome} (h : review r catalog expected reports coverage = .ok result) :
    Context.resolve r catalog expected = .ok expected := by
  cases hc : Context.resolve r catalog expected with
  | error why => simp [review, hc] at h
  | ok actual =>
    have he := ((Context.resolve_iff r catalog expected actual).mp hc).2.2.2
    subst actual
    rfl

end Usul.IDA.Omission
