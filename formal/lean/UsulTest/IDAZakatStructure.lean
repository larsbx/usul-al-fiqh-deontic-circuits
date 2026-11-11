import UsulTest.IDASubstitution

/-! A local structural fixture for the restricted candidate in the corpus.
Its registry is confined to this fixture. Resolution witnesses shape only. -/
namespace UsulTest.IDAZakatStructure

open Usul Usul.IDA ActRegistry Substitution
open IDASubstitution (people x y pair grounding)
open IDAActRegistry (payer recipient property baseEnvelope)

def definition : Definition :=
  ⟨⟨⟨"fiqh.act.candidate.v1", "transfer.pay_zakat"⟩, 1⟩, List.replicate 32 7,
   [⟨"payer", some .person⟩, ⟨"recipient", some .person⟩, ⟨"transferred_property", some .asset⟩]⟩

def registry : Registry := ⟨1, [definition]⟩

def operation : Operation :=
  ⟨definition.key.symbol, [⟨"payer", .person⟩, ⟨"recipient", .person⟩,
    ⟨"transferred_property", .asset⟩]⟩

def envelope : Envelope :=
  { baseEnvelope with
    key := definition.key
    definitionDigest := definition.digest
    qualifications := []
    action := ⟨operation, [⟨"payer", payer⟩, ⟨"recipient", recipient⟩,
      ⟨"transferred_property", property⟩]⟩ }

theorem resolves : resolve registry envelope = .ok definition := by decide

def schema : Schema registry := Schema.ofResolved resolves
def description : Description registry people :=
  ⟨schema, .cons x (.cons y (.cons (.rigid ⟨property, by decide⟩) .nil))⟩

def swap : Sub people people := pair y x
def selected (b : Bool) : Sub people people := if b then swap else Sub.id

theorem two_stage (a b : Bool) :
    (((description.subst (selected a)).subst (selected b)).subst grounding).action =
      (description.subst ((selected a).then ((selected b).then grounding))).action := by
  simp [Sub.assoc]

theorem swapped_roles :
    (description.subst (swap.then grounding)).action.operands =
      [⟨"payer", recipient⟩, ⟨"recipient", payer⟩, ⟨"transferred_property", property⟩] := by
  decide

def controlEnvelope (n : Nat) : Envelope :=
  match n with
  | 1 => { envelope with key := { definition.key with version := 2 } }
  | 2 => { envelope with definitionDigest := List.replicate 32 8 }
  | 3 => { envelope with action := { envelope.action with operands := envelope.action.operands.take 2 } }
  | 4 => { envelope with action := { envelope.action with operands :=
      [⟨"payer", payer⟩, ⟨"recipient", recipient⟩, ⟨"transferred_property", payer⟩] } }
  | _ => envelope

def resolutionCells : List Nat := (List.range 5).map fun n => resolveCode registry (controlEnvelope n)

theorem resolution_controls : resolutionCells = [0, 4, 5, 8, 8] := by decide

def substitutionCells (a b : Bool) : List Nat :=
  let direct := (description.subst ((selected a).then ((selected b).then grounding))).action
  let staged := (((description.subst (selected a)).subst (selected b)).subst grounding).action
  [if direct = staged then 1 else 0] ++ direct.operands.map (fun operand =>
    if operand.referent = payer then 1 else if operand.referent = recipient then 2
    else if operand.referent = property then 3 else 0)

def cells : List Nat :=
  resolutionCells ++ [false, true].flatMap fun a => [false, true].flatMap (substitutionCells a)

end UsulTest.IDAZakatStructure
