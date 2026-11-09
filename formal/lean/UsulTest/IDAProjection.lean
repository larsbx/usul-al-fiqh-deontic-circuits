import Usul.Cat.IDAProjection
import UsulTest.IDASubstitution

/-! Synthetic guard observations over the ACT-02 grounded repayment. Every
input in the finite matrix satisfies ACT-01 snapshot shape. -/

namespace UsulTest.IDAProjection

open Usul Usul.IDA Usul.IDA.Projection
open IDAActRegistry (payer recipient)
open IDASubstitution (groundedSnapshot repayment)

def nextDefinition : ActRegistry.Definition :=
  { repayment with key := { repayment.key with version := 2 } }

def registry : ActRegistry.Registry := ⟨1, [repayment, nextDefinition]⟩

def supportDef : Context.PredicateDefinition := IDAContext.predicate

def exceptionDef : Context.PredicateDefinition :=
  ⟨⟨⟨"synthetic.predicate", "guard"⟩, 1⟩, [.person]⟩

def otherVersion : Context.PredicateDefinition :=
  { exceptionDef with key := { exceptionDef.key with version := 2 } }

def unrelatedDef : Context.PredicateDefinition :=
  ⟨⟨⟨"synthetic.predicate", "unrelated"⟩, 1⟩, [.person]⟩

def vocabulary : Context.Vocabulary :=
  { IDASubstitution.vocabulary with definitions := [supportDef, exceptionDef, otherVersion, unrelatedDef] }

def base : Context.Snapshot := { groundedSnapshot with vocabulary := vocabulary }

def rule (enabled : Bool) : Rule :=
  ⟨scope base, ⟨⟨supportDef, by decide⟩, rfl⟩, ⟨⟨exceptionDef, by decide⟩, rfl⟩, by decide, enabled⟩

def report (d : Context.PredicateDefinition) (person : EntityRef) (positive : Bool)
    (mention : String := "m1") : ActRegistry.Qualification :=
  ⟨d.key.symbol, d.key.version, [person], positive, ⟨"synthetic.mention", mention⟩⟩

def rowMask (mask : Nat) : List ActRegistry.Qualification :=
  ([report supportDef recipient true, report supportDef recipient false,
    report exceptionDef payer true, report exceptionDef payer false].zipIdx).filterMap
      fun (q, i) => if mask.testBit i then some q else none

def rows (mask noise : Nat) : List ActRegistry.Qualification :=
  let qs := rowMask mask
  match noise with
  | 1 => qs ++ [report unrelatedDef recipient true]
  | 2 => qs ++ [report otherVersion payer true]
  | 3 => qs ++ [report exceptionDef recipient true]
  | 4 => qs ++ qs.map (fun q => { q with mention := ⟨"synthetic.mention", "m2"⟩ })
  | 5 => qs.reverse
  | _ => qs

def scopeVariant (shape : Fin 15) : Context.Snapshot := match shape.val with
  | 1 =>
    let other := base.opportunity.map fun o => { o with occurrence := ⟨"synthetic.event", "two"⟩ }
    IDAContext.synchronize { base with opportunity := other }
  | 2 => { base with inquiry := { base.inquiry with questionId := 2 } }
  | 3 => IDAContext.setMetadata base fun m => { m with profileVersion := 2 }
  | 4 => { base with admissionPolicy := { base.admissionPolicy with version := 2 } }
  | 5 => { base with time := { base.time with cutoff := 21 } }
  | 6 => { base with inquiry := { base.inquiry with accountable := payer } }
  | 7 => { base with inquiry := { base.inquiry with performer := ⟨"creditor", recipient⟩ } }
  | 8 => IDAContext.setMetadata base fun m => { m with interpretationVersion := 2 }
  | 9 => { base with envelope := { base.envelope with key := nextDefinition.key } }
  | 10 => IDAContext.setMetadata base fun m => { m with contextId := 2 }
  | 11 => { base with time := { base.time with clockVersion := 2 } }
  | 12 => { base with vocabulary := { vocabulary with pin := { vocabulary.pin with version := 2 } } }
  | 13 =>
    let action := { base.envelope.action with
      operands := [⟨"debtor", recipient⟩, ⟨"creditor", payer⟩, ⟨"debt", IDASubstitution.debt⟩] }
    IDAContext.synchronize { base with
      envelope := { base.envelope with action := action }
      inquiry := { base.inquiry with performer := ⟨"debtor", recipient⟩ } }
  | 14 => IDAContext.setMetadata base fun m => { m with effectiveAt := 11 }
  | _ => base

def snapshot (shape : Fin 15) (mask noise : Nat) : Context.Snapshot :=
  let s := scopeVariant shape
  let updated := if noise = 0 then s else
    { s with
      key := { s.key with version := s.key.version + 1 }
      envelope := { s.envelope with context := { s.envelope.context with evidenceRevision := 2 } } }
  { updated with envelope := { updated.envelope with qualifications := rows mask noise } }

/-- The exporter reports invalid shape explicitly. Named controls and the
independent table require the specified finite domain to be well formed. -/
def input (shape : Fin 15) (mask noise : Nat) : Option (Input registry) :=
  let s := snapshot shape mask noise
  if h : s.WellFormed registry then some ⟨s, h⟩ else none

def baseline (mask : Nat) : Option (Input registry) := input 0 mask 0

def code : Outcome → Nat
  | .outsideScope => 0 | .unresolved => 1 | .fallback => 2 | .negativeSupport => 3
  | .positiveSupport => 4 | .contestedSupport => 5 | .exception => 6 | .contestedException => 7

def caseCells (enabled : Bool) (shape : Fin 15) (mask noise : Nat) : List Nat :=
  match input shape mask noise, baseline mask with
  | some x, some y =>
    let r := rule enabled
    let p := project r x
    [1, code (evaluate r x), code (evaluateProjected r p),
     p.support.positive.toNat, p.support.negative.toNat,
     p.exception.positive.toNat, p.exception.negative.toNat,
     (decide (Equivalent r x y)).toNat, (decide (core x = core y)).toNat,
     (decide (kind x = kind y)).toNat]
  | _, _ => List.replicate 10 0

def pairCells (enabled : Bool) (left right : Nat) : List Nat :=
  match baseline left, input 0 right 1 with
  | some a, some b =>
    let r := rule enabled
    [(decide (Equivalent r a b)).toNat, (decide (evaluate r a = evaluate r b)).toNat,
     (decide (core a = core b)).toNat, (decide (kind a = kind b)).toNat]
  | _, _ => List.replicate 4 0

def supportOnly : Input registry := ⟨snapshot 0 1 0, by decide⟩
def supportPlusException : Input registry := ⟨snapshot 0 5 0, by decide⟩
def irrelevantAddition : Input registry := ⟨snapshot 0 1 1, by decide⟩
def distinctOccurrence : Input registry := ⟨snapshot 1 1 0, by decide⟩
def sameAnswerExtraRead : Input registry := ⟨snapshot 0 7 0, by decide⟩

theorem hidden_exception :
    supportPlusException.val.envelope.qualifications =
      supportOnly.val.envelope.qualifications ++ [report exceptionDef payer true] ∧
    (project (rule true) supportOnly).support = (project (rule true) supportPlusException).support ∧
    evaluate (rule true) supportOnly = .positiveSupport ∧
    evaluate (rule true) supportPlusException = .exception := by decide

theorem core_loses_relevant_reports :
    ¬ Schema.Factors (evaluate (r := registry) (rule true)) core := by
  intro h
  have he := h supportOnly supportPlusException (by decide)
  rw [hidden_exception.2.2.1, hidden_exception.2.2.2] at he
  contradiction

theorem kind_loses_occurrence :
    kind supportOnly = kind distinctOccurrence ∧
    core supportOnly ≠ core distinctOccurrence ∧
    evaluate (rule true) distinctOccurrence = .outsideScope := by decide

theorem kind_does_not_factor :
    ¬ Schema.Factors (evaluate (r := registry) (rule true)) kind := by
  intro h
  have he := h supportOnly distinctOccurrence kind_loses_occurrence.1
  rw [hidden_exception.2.2.1, kind_loses_occurrence.2.2] at he
  contradiction

theorem equivalent_receipt_can_be_stale :
    Equivalent (rule true) supportOnly irrelevantAddition ∧
    Context.resolve registry [irrelevantAddition.val] supportOnly.val = .error .stale := by decide

theorem equal_answers_do_not_imply_equivalence :
    evaluate (rule true) supportPlusException = evaluate (rule true) sameAnswerExtraRead ∧
    ¬ Equivalent (rule true) supportPlusException sameAnswerExtraRead := by decide

theorem explicit_negative_only :
    caseCells true 0 0 0 = [1,1,1,0,0,0,0,1,1,1] ∧
    caseCells true 0 8 0 = [1,2,2,0,0,0,1,1,1,1] ∧
    caseCells false 0 8 0 = [1,1,1,0,0,0,1,1,1,1] := by decide

end UsulTest.IDAProjection
