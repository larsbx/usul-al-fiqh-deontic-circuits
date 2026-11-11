import Usul.Cat.IDASemantics
import UsulTest.IDAProjection

/-! Synthetic finite histories for the already grounded repayment fragment.
No report list is used as a truth assignment. -/

namespace UsulTest.IDASemantics

open Usul Usul.IDA Usul.IDA.Substitution Usul.IDA.Semantics
open IDASubstitution (people x y atom predicate revised vocabulary pair debt otherAlice
  repayment referenceEnvelope referenceCode)
open IDAActRegistry (payer recipient)

def alice : Rigid .person := ⟨payer, by decide⟩
def bob : Rigid .person := ⟨recipient, by decide⟩
def namesake : Rigid .person := ⟨otherAlice, by decide⟩

def valuation (i : Nat) : Valuation people :=
  fun _ var => match var with
    | .here => if i.testBit 0 then bob else alice
    | .there .here => if i.testBit 1 then alice else bob

def term : Nat → Term people .person
  | 0 => x
  | 1 => y
  | 2 => .rigid alice
  | 3 => .rigid bob
  | _ => .rigid namesake

def substitution (a b : Nat) : Sub people people := pair (term a) (term b)

/-- Four independent truth bits for the two predicate versions and the two
named participants. All other ground tuples are assigned false in this model. -/
def history (mask : Nat) : History vocabulary :=
  ⟨fun p args =>
    match IDASubstitution.argumentCodes args with
    | [1] => mask.testBit (if p.val.key.version == 1 then 0 else 2)
    | [2] => mask.testBit (if p.val.key.version == 1 then 1 else 3)
    | _ => false⟩

def formula : Nat → Formula vocabulary people
  | 0 => atom x
  | 1 => atom x false
  | 2 => atom y
  | 3 => .atom revised (.cons x .nil) true
  | 4 => .both (atom x) (atom y)
  | 5 => .both (atom x) (atom x false)
  | 6 => .atom revised (.cons y .nil) false
  | _ => atom (.rigid namesake)

def formulaCells (mask assignment a b which : Nat) : List Nat :=
  let h := history mask
  let ρ := valuation assignment
  let σ := substitution a b
  let f := formula which
  [(evaluate h ρ (f.subst σ)).toNat, (evaluate h (Valuation.pull σ ρ) f).toNat]

abbrev registry := IDAProjection.registry

def schema : Schema registry :=
  Schema.ofResolved (e := referenceEnvelope) (d := repayment) (by decide)

def revisedEnvelope : ActRegistry.Envelope :=
  { referenceEnvelope with key := IDAProjection.nextDefinition.key }

def revisedSchema : Schema registry :=
  Schema.ofResolved (e := revisedEnvelope) (d := IDAProjection.nextDefinition) (by decide)

structure RepaymentMeaning where
  debtor : EntityRef
  creditor : EntityRef
  obligation : EntityRef
  deriving DecidableEq

def reader : Args [] [.person, .person, .obligation] → RepaymentMeaning
  | .cons d (.cons c (.cons o .nil)) => ⟨d.reference.val, c.reference.val, o.reference.val⟩

def interpreter : Interpreter registry RepaymentMeaning := ⟨schema, reader⟩

def pilotInquiry (version : Bool) : Inquiry registry people :=
  let description : Description registry people :=
    if version then ⟨revisedSchema, .cons x (.cons y (.cons (.rigid ⟨debt, by decide⟩) .nil))⟩
    else ⟨schema, .cons x (.cons y (.cons (.rigid ⟨debt, by decide⟩) .nil))⟩
  ⟨IDASubstitution.inquiry.frame, description, y, x⟩

def meaningCodes : Option RepaymentMeaning → List Nat
  | none => [0, 0, 0]
  | some r => [referenceCode r.debtor, referenceCode r.creditor, referenceCode r.obligation]

def meaningCells (version : Bool) (assignment a b : Nat) : List Nat :=
  let i := pilotInquiry version
  let ρ := valuation assignment
  let σ := substitution a b
  let pulled := Valuation.pull σ ρ
  let direct := interpretInquiry (i.subst σ) ρ
  let staged := interpretInquiry i pulled
  meaningCodes (interpreter.interpret (i.description.subst σ) ρ) ++
    meaningCodes (interpreter.interpret i.description pulled) ++
    [referenceCode direct.accountable, referenceCode direct.performer.referent,
      (decide (direct = staged)).toNat]

def selected : Nat → List (Formula vocabulary people)
  | 0 => []
  | 1 => [formula 0]
  | 2 => [formula 1]
  | 3 => [formula 0, formula 1]
  | 4 => [formula 4]
  | 5 => [formula 3]
  | _ => [formula 2, formula 1]

def population : Nat → List Nat
  | 0 => []
  | 1 => [0]
  | 2 => [1]
  | 3 => [0, 1, 2, 3]
  | _ => List.range 16

def assessmentCode : Assessment → Nat
  | .noCandidates => 0 | .inconsistent => 1 | .robust => 2 | .counterexample => 3

def assessmentCell (domain selection which : Nat) : Nat :=
  let points : List (Point vocabulary people) :=
    (population domain).map fun mask => ⟨history mask, valuation 0⟩
  assessmentCode (assess points (selected selection) (formula which))

theorem exact_version_and_roles :
    meaningCells false 0 1 0 = [2, 1, 4, 2, 1, 4, 1, 2, 1] ∧
    meaningCells true 0 1 0 = [0, 0, 0, 0, 0, 0, 1, 2, 1] ∧
    formulaCells 4 0 0 1 0 = [0, 0] ∧ formulaCells 4 0 0 1 3 = [1, 1] ∧
    formulaCells 1 0 4 1 0 = [0, 0] := by decide

theorem finite_nonvacuity_controls :
    assessmentCell 0 0 0 = 0 ∧ assessmentCell 4 3 0 = 1 ∧
    assessmentCell 4 1 0 = 2 ∧ assessmentCell 4 0 0 = 3 := by decide

theorem reports_are_separate :
    (IDAProjection.caseCells true 0 0 0)[1]? = some 1 ∧
    (IDAProjection.caseCells true 0 3 0)[1]? = some 5 ∧
    evaluate (history 2) (valuation 0) (atom y) = true ∧
    evaluate (history 2) (valuation 0) (atom y false) = false := by decide

def arrowSource : PremiseContext vocabulary := ⟨people, [atom y]⟩
def arrowTarget : PremiseContext vocabulary := ⟨people, [atom x]⟩
def swapArrow : PremiseArrow arrowSource arrowTarget :=
  ⟨substitution 1 0, by decide⟩

theorem nonidentity_sound_instance :
    Satisfies (history 2) (valuation 0) ((atom x).subst swapArrow.substitution) := by
  apply sound_along swapArrow (.assume (List.Mem.head []))
  intro f hf
  have he : f = atom y := List.mem_singleton.mp hf
  subst f
  change evaluate (history 2) (valuation 0) (atom y) = true
  decide

end UsulTest.IDASemantics
