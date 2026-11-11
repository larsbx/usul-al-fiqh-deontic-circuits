import Usul.Typing.IDAPilot
import Usul.Typing.IDAOmissionWire
import UsulTest.IDAAdmission

/-! Two people, one rigid debt, one clock, one omission opportunity. The
repayment classification and all authority inputs are synthetic. -/

namespace UsulTest.IDAPilot

open Usul.IDA Usul.IDA.Substitution Usul.IDA.Semantics
open IDASubstitution (people vocabulary x y atom revised)
open IDASemantics (registry history valuation)
open IDAActRegistry (payer recipient)

def excluded (person : Term people .person) : Formula vocabulary people :=
  .atom revised (.cons person .nil) false

def sourcePremises : PremiseContext vocabulary := ⟨people, [atom y, excluded x]⟩
def destinationPremises : PremiseContext vocabulary := ⟨people, [atom x, excluded y]⟩

def plan : Admission.Plan registry vocabulary :=
  let base := IDAAdmission.plan
  { destination := destinationPremises
    source := sourcePremises
    arrow := ⟨IDASemantics.substitution 1 0, by decide⟩
    inquiry := { base.inquiry with frame := { base.inquiry.frame with
      snapshot := { base.inquiry.frame.snapshot with effectiveAt := 12 } } }
    conclusion := .both (atom y) (excluded x)
    derivation := .both (.assume (List.Mem.head _))
      (.assume (List.Mem.tail _ (List.Mem.head _)))
    sourceValuation := valuation 0
    destinationValuation := valuation 0
    destinationSubjectId := base.destinationSubjectId
    destinationContextId := base.destinationContextId
    destinationPolicy := base.destinationPolicy }

def reportRows (accountable performer : EntityRef) (mask : Nat) : List ActRegistry.Qualification :=
  let report := IDAProjection.report
  ([report IDASubstitution.predicateDefinition accountable true,
    report IDASubstitution.predicateDefinition accountable false,
    report IDASubstitution.revisedDefinition performer true,
    report IDASubstitution.revisedDefinition performer false].zipIdx).filterMap
      fun (row, index) => if mask.testBit index then some row else none

def reported (s : Context.Snapshot) (mask : Nat) : Context.Snapshot :=
  let qualifications := reportRows s.inquiry.accountable s.inquiry.performer.referent mask
  { s with envelope := { s.envelope with qualifications := qualifications } }

def sourceSnapshot := reported (IDAAdmission.snapshot 1 plan.inquiry plan.sourceValuation) 9
def destinationSnapshot (mask : Nat) :=
  reported (IDAAdmission.snapshot 2 plan.destinationInquiry plan.destinationValuation) mask

def rule : Projection.Rule :=
  ⟨Projection.scope (destinationSnapshot 9), ⟨IDASubstitution.predicate, rfl⟩,
    ⟨revised, rfl⟩, by decide, false⟩

def side (application : Admission.Application vocabulary) (first : Nat) : Admission.Side vocabulary :=
  ⟨application, application.premises.zipIdx |>.map
    fun (formula, index) => IDAAdmission.certificate (first + index) application formula⟩

def source := side (plan.sourceApplication sourceSnapshot) 1
def destination (mask : Nat) := side (plan.destinationApplication (destinationSnapshot mask)) 3

def authority (mask : Nat) : Admission.Authority vocabulary :=
  let d := destination mask
  let certs := source.certificates ++ d.certificates
  let env := IDADerivation.E (certs.map Admission.Certificate.premise)
  ⟨{ env with currentVersions := env.currentVersions.eraseDups },
    [sourceSnapshot, destinationSnapshot mask], certs, [source, d]⟩

def histories (n : Nat) : List (History vocabulary) :=
  (match n with
    | 0 => []
    | 1 => [0]
    | 2 => [1]
    | _ => List.range 16).map history

def trial (mask population mode : Nat) :
    Except (Pilot.Failure vocabulary) (Pilot.Receipt plan rule (histories population)) :=
  let a := authority mask
  let d := destination mask
  let (a, d) := match mode with
    | 1 => (a, { d with certificates := [] })
    | 2 => (a, { d with certificates := d.certificates.map fun cert =>
        if cert.token = 3 then { cert with formula := (atom y).subst (valuation 0).grounding }
        else cert })
    | 3 => ({ a with environment := { a.environment with
        evidence := a.environment.evidence.take 2 } }, d)
    | 4 => ({ a with contexts := [sourceSnapshot, IDAContext.differentKey (destinationSnapshot mask)] }, d)
    | 5 => ({ a with grants := [source] }, d)
    | _ => (a, d)
  Pilot.run plan rule (histories population) a source d

def resultCode (mask population mode : Nat) : Nat :=
  match trial mask population mode with
  | .ok _ => 0
  | .error (.admission r) => match r.stage, r.reason with
    | .destination, .premiseList => 1
    | .destination, (.sourceAdmission .missingEvidence) => 2
    | .destination, (.snapshot .stale) => 3
    | .destination, .policy => 4
    | _, _ => 99
  | .error .guardRejected => 5
  | .error (.assessmentRejected .noCandidates) => 6
  | .error (.assessmentRejected .inconsistent) => 7
  | .error (.assessmentRejected _) => 99

def cells (mask population mode : Nat) : List Nat :=
  let snapshot := destinationSnapshot mask
  let guard := if h : snapshot.WellFormed registry then
    let input : Projection.Input registry := ⟨snapshot, h⟩
    [(Pilot.guard rule (Projection.project rule input)).toNat,
      IDAProjection.code (Projection.evaluate rule input)]
  else [99, 99]
  guard ++ [IDASemantics.assessmentCode (Pilot.assessment plan (histories population)),
    resultCode mask population mode]

def omissionBatch (n : Nat) : Option Omission.Wire.View := do
  let scope ← Omission.Scope.fromSnapshot (destinationSnapshot 9)
  let coverage := if n = 1 then none else some (⟨["direct", "alternate"], 12⟩ : Omission.Wire.CoverageWire)
  let reports := if n = 2 then [⟨"alternate", 11, 14⟩] else []
  let scope := if n = 3 then { scope with opportunity := { scope.opportunity with
      occurrence := ⟨"synthetic.event", "other"⟩ } } else scope
  pure ⟨Omission.Wire.schema, Omission.Wire.encodeScope scope, reports, coverage⟩

def omissionCell (n : Nat) : Nat :=
  match omissionBatch n with
  | none => 99
  | some batch =>
    match Omission.Wire.review registry (authority 9).contexts (destinationSnapshot 9) batch with
    | .ok .coveredNoCompletion => 0
    | .ok .coverageMissing => 1
    | .ok .completionObserved => 2
    | .error .wrongScope => 3
    | _ => 99

theorem nonidentity_admitted :
    resultCode 9 2 0 = 0 ∧ sourceSnapshot.target ≠ (destinationSnapshot 9).target ∧
      source.application.conclusion ≠ (destination 9).application.conclusion ∧
      sourceSnapshot.opportunity = (destinationSnapshot 9).opportunity ∧
      sourceSnapshot.envelope.action.operands[2]? =
        some ⟨"debt", IDASubstitution.debt⟩ ∧
      (destinationSnapshot 9).envelope.action.operands[2]? =
        some ⟨"debt", IDASubstitution.debt⟩ := by decide

theorem exact_application_controls :
    (List.range 6).map (resultCode 9 2) = [0, 1, 1, 2, 3, 4] ∧
      resultCode 9 0 0 = 6 ∧ resultCode 9 1 0 = 7 ∧
      resultCode 1 2 0 = 5 ∧ resultCode 11 2 0 = 5 ∧ resultCode 13 2 0 = 5 := by decide

theorem same_snapshot_omission_controls :
    (List.range 4).map omissionCell = [0, 1, 2, 3] := by decide

def baseline : Projection.Input registry := ⟨destinationSnapshot 9, by decide⟩

def irrelevantRow : ActRegistry.Qualification :=
  IDAProjection.report IDASubstitution.revisedDefinition payer true

def extendedSnapshot : Context.Snapshot :=
  let s := baseline.val
  let envelope := { s.envelope with
    qualifications := s.envelope.qualifications ++ [irrelevantRow]
    context := { s.envelope.context with evidenceRevision := 2 } }
  { s with key := { s.key with version := 3 }, envelope := envelope }

def extended : Projection.Input registry := ⟨extendedSnapshot, by decide⟩

theorem irrelevant_frame :
    Pilot.guard rule (Projection.project rule baseline) =
      Pilot.guard rule (Projection.project rule extended) ∧ baseline.val ≠ extended.val := by
  refine ⟨Pilot.guard_frame rule (Projection.irrelevant_append rule [irrelevantRow] ?_ ?_ ?_ ?_), by decide⟩
  all_goals decide

theorem hidden_exception_changes_guard :
    (destinationSnapshot 9).target = (destinationSnapshot 13).target ∧
      (cells 9 2 0)[0]? = some 1 ∧ (cells 13 2 0)[0]? = some 0 := by decide

end UsulTest.IDAPilot
