import Usul.Typing.IDAAdmission
import Usul.Typing.IDAProjection

/-! The bounded ACT-08 policy combines an exact destination admission, explicit
guard reports, and a compatible-history assessment. Report lists, semantic
histories, and the certificate authority remain independent inputs. -/

namespace Usul.IDA.Pilot

open Admission Projection Semantics

def guard (rule : Rule) (d : Dependencies) : Bool :=
  d.scope == rule.scope && d.support.positive && !d.support.negative &&
    d.exception.negative && !d.exception.positive

def destinationPoints (p : Plan r v) (histories : List (History v)) :
    List (Point v p.destination.variables) :=
  histories.map (⟨·, p.destinationValuation⟩)

def assessment (p : Plan r v) (histories : List (History v)) : Assessment :=
  assess (destinationPoints p histories) p.destination.premises
    (p.conclusion.subst p.arrow.substitution)

structure Receipt (p : Plan r v) (rule : Rule) (histories : List (History v)) where
  admission : Admission.Receipt p
  input : Projection.Input r
  exactSnapshot : input.val = admission.destination.application.snapshot
  guardPassed : guard rule (project rule input) = true
  robust : assessment p histories = .robust

inductive Failure (v : Context.Vocabulary) where
  | admission (reason : Rejection v)
  | guardRejected
  | assessmentRejected (result : Assessment)
  deriving DecidableEq

def run (p : Plan r v) (rule : Rule) (histories : List (History v))
    (authority : Authority v) (source destination : Side v) :
    Except (Failure v) (Receipt p rule histories) := do
  let admitted ← (reconstruct p authority source destination).mapError Failure.admission
  let s := admitted.destination.application.snapshot
  have valid := (Context.resolve_iff r admitted.authority.contexts s s).mp
    admitted.destinationValid.currentSnapshot
  let input : Projection.Input r := ⟨s, valid.2.2.1⟩
  if hg : guard rule (project rule input) = true then
    if ha : assessment p histories = .robust then
      return ⟨admitted, input, rfl, hg, ha⟩
    else throw (.assessmentRejected (assessment p histories))
  else throw .guardRejected

theorem Receipt.explicit_guard (receipt : Receipt p rule histories) :
    let d := project rule receipt.input
    d.scope = rule.scope ∧ d.support.positive = true ∧ d.support.negative = false ∧
      d.exception.negative = true ∧ d.exception.positive = false := by
  have h := receipt.guardPassed
  simpa [guard, Bool.and_eq_true, and_assoc] using h

theorem Receipt.compatible_history (receipt : Receipt p rule histories) :
    compatible (destinationPoints p histories) p.destination.premises ≠ [] := by
  exact ((robust_iff _ _ _).mp receipt.robust).1

theorem Receipt.conditional_sound {p : Plan r v} (receipt : Receipt p rule histories) (h : History v) (empty : Valuation [])
    (hp : ModelsPremises h p.destinationValuation p.destination.premises) :
    Satisfies h empty receipt.admission.destination.application.conclusion :=
  receipt.admission.conditional_sound h empty hp

theorem guard_frame (rule : Rule) {a b : Projection.Input r} (h : Equivalent rule a b) :
    guard rule (project rule a) = guard rule (project rule b) :=
  congrArg (guard rule) h

end Usul.IDA.Pilot
