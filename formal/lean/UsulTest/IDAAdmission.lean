import Usul.Typing.IDAAdmission
import UsulTest.IDASemantics

/-! Synthetic ACT-05 fixture. All grants and authenticated certificate entries
are test data. No source or candidate corpus judgment is changed. -/

namespace UsulTest.IDAAdmission

open Usul Usul.IDA Usul.IDA.Substitution Usul.IDA.Semantics Usul.IDA.Admission
open IDASubstitution (vocabulary atom x y referenceEnvelope)
open IDASemantics (registry valuation history swapArrow arrowSource arrowTarget)

def plan : Plan registry vocabulary where
  destination := arrowSource
  source := arrowTarget
  arrow := swapArrow
  inquiry := IDASemantics.pilotInquiry false
  conclusion := .both (atom x) (atom x)
  derivation := .both (.assume (List.Mem.head [])) (.assume (List.Mem.head []))
  sourceValuation := valuation 0
  destinationValuation := valuation 0
  destinationSubjectId := 43
  destinationContextId := 2
  destinationPolicy := ⟨⟨"synthetic.policy", "destination"⟩, 1⟩

def snapshot (id : Nat) (i : Inquiry registry Γ) (ρ : Valuation Γ) : Context.Snapshot :=
  let inquiry := interpretInquiry i ρ
  ⟨⟨⟨"synthetic.snapshot", "repayment"⟩, id⟩, vocabulary, i.frame.admissionPolicy,
    { referenceEnvelope with context := i.frame.snapshot, action := i.description.ground ρ.grounding },
    i.frame.timeView, inquiry, i.frame.opportunity⟩

def sourceSnapshot := snapshot 1 plan.inquiry plan.sourceValuation
def destinationSnapshot := snapshot 2 plan.destinationInquiry plan.destinationValuation

def certificate (id : Nat) (app : Application vocabulary)
    (formula : Formula vocabulary []) : Certificate vocabulary :=
  let premise := IDADerivation.changeSource (IDAContext.premiseFor app.snapshot)
    fun source => { source with sourceId := id }
  ⟨id, app, formula, { premise with request := { premise.request with entryId := id } }⟩

def sourceApplication := plan.sourceApplication sourceSnapshot
def destinationApplication := plan.destinationApplication destinationSnapshot
def sourceCert := certificate 1 sourceApplication ((atom x).subst (valuation 0).grounding)
def destinationCert := certificate 2 destinationApplication ((atom y).subst (valuation 0).grounding)
def sourceSide : Side vocabulary := ⟨sourceApplication, [sourceCert]⟩
def destinationSide : Side vocabulary := ⟨destinationApplication, [destinationCert]⟩

def authority : Authority vocabulary :=
  let env := IDADerivation.E [sourceCert.premise, destinationCert.premise]
  ⟨{ env with currentVersions := [Derivation.expectedVersion sourceCert.premise] },
    [sourceSnapshot, destinationSnapshot], [sourceCert, destinationCert],
    [sourceSide, destinationSide]⟩

def code : Except (Rejection vocabulary) (Receipt plan) → Nat
  | .ok _ => 0
  | .error rejected => match rejected.reason with
    | .premiseList => 1
    | (.snapshot .stale) => 2
    | (.sourceAdmission .sourceUnauthenticated) => 3
    | .certificateAuthentication => 4
    | .policy => 5
    | .inquiry => 6
    | (.sourceAdmission .missingEvidence) => 7
    | .changedAuthority => 8
    | (.sourceAdmission (.registryRejected .staleSnapshot)) => 9
    | .changedApplication => 10
    | .frame => 11
    | _ => 99

def attempt (a : Authority vocabulary := authority) (d : Side vocabulary := destinationSide) :=
  reconstruct plan a sourceSide d

def control (n : Nat) : Nat :=
  code <| match n with
  | 0 => attempt authority destinationSide
  | 1 => attempt authority { destinationSide with certificates := [] }
  | 2 => attempt { authority with contexts := [sourceSnapshot,
      IDAContext.differentKey destinationSnapshot] } destinationSide
  | 3 => attempt { authority with environment := { authority.environment with
      authenticatedSources := [sourceCert.premise.request.record.provenance.source] } } destinationSide
  | 4 => attempt authority { destinationSide with certificates :=
      [{ destinationCert with formula := sourceCert.formula }] }
  | 5 =>
    let proposed := { destinationSide with certificates :=
      [{ destinationCert with token := sourceCert.token }] }
    attempt { authority with grants := [sourceSide, proposed] } proposed
  | 6 => attempt { authority with grants := [sourceSide] } destinationSide
  | 7 =>
    let changed := { destinationSnapshot with inquiry :=
      { destinationSnapshot.inquiry with accountable := sourceSnapshot.inquiry.accountable } }
    attempt { authority with contexts := [sourceSnapshot, changed] }
      { destinationSide with application := plan.destinationApplication changed }
  | 8 => attempt { authority with environment := { authority.environment with
      evidence := [⟨sourceCert.premise, .supported⟩] } } destinationSide
  | 9 =>
    match attempt authority destinationSide with
    | .error why => .error why
    | .ok receipt => replay plan { authority with grants := [sourceSide] } receipt
  | 10 => attempt { authority with environment := { authority.environment with
      registry := { authority.environment.registry with snapshot := 2 } } } destinationSide
  | 11 => attempt authority { destinationSide with application :=
      { destinationApplication with grounding := sourceApplication.grounding.reverse } }
  | _ =>
    let changed := { destinationSnapshot with admissionPolicy := sourceSnapshot.admissionPolicy }
    attempt { authority with contexts := [sourceSnapshot, changed] }
      { destinationSide with application := plan.destinationApplication changed }

theorem nonidentity_admission :
    control 0 = 0 ∧ sourceSnapshot.target ≠ destinationSnapshot.target ∧
    sourceApplication.conclusion ≠ destinationApplication.conclusion ∧
    sourceSnapshot.admissionPolicy ≠ destinationSnapshot.admissionPolicy := by decide

theorem current_receipt_replays :
    (match attempt authority destinationSide with
     | .ok receipt => code (replay plan authority receipt)
     | .error _ => 99) = 0 := by decide

theorem nonidentity_semantics :
    Satisfies (history 2) plan.destinationValuation
      (plan.conclusion.subst plan.arrow.substitution) := by
  apply plan.conditional_sound (history 2)
  intro f hf
  have he : f = atom y := List.mem_singleton.mp hf
  subst f
  change evaluate (history 2) (valuation 0) (atom y) = true
  decide

theorem adverse_controls :
    (List.range 13).map control = [0, 1, 2, 3, 1, 4, 5, 6, 7, 8, 9, 10, 11] := by decide

end UsulTest.IDAAdmission
