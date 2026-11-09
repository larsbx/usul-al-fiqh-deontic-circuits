import Usul.Cat.IDASubstitution
import UsulTest.IDAContext

/-! The comparison uses a synthetic repayment signature and two formal person
positions. A rigid debt, occurrence, and clock are fixed by the fixture. -/

namespace UsulTest.IDASubstitution

open Usul Usul.IDA Usul.IDA.Substitution
open IDAActRegistry (payer recipient baseSnapshot baseEnvelope)

abbrev people : Variables := [.person, .person]
def x : Term people .person := .var .here
def y : Term people .person := .var (.there .here)

def debt : EntityRef := ⟨.obligation, ⟨"synthetic.debt", "d1"⟩⟩
def otherAlice : EntityRef := ⟨.person, ⟨"other.person", "alice"⟩⟩

def repayment : ActRegistry.Definition :=
  ⟨⟨⟨"synthetic.act", "repay"⟩, 1⟩, List.replicate 32 1,
    [⟨"debtor", some .person⟩, ⟨"creditor", some .person⟩, ⟨"debt", some .obligation⟩]⟩

def registry : ActRegistry.Registry := ⟨1, [repayment]⟩

def referenceEnvelope : ActRegistry.Envelope :=
  { baseEnvelope with
    key := repayment.key
    definitionDigest := repayment.digest
    qualifications := []
    action := ⟨⟨repayment.key.symbol, [⟨"debtor", .person⟩, ⟨"creditor", .person⟩, ⟨"debt", .obligation⟩]⟩,
      [⟨"debtor", payer⟩, ⟨"creditor", recipient⟩, ⟨"debt", debt⟩]⟩ }

def schema : Schema registry := Schema.ofResolved (e := referenceEnvelope) (d := repayment) (by decide)
def description : Description registry people :=
  ⟨schema, .cons x (.cons y (.cons (.rigid ⟨debt, by decide⟩) .nil))⟩

def inquiry : Inquiry registry people :=
  ⟨⟨1, .wadi .shart, 42, ⟨true, true⟩, .ada, baseSnapshot,
    ⟨1, 20, .retrospective⟩, IDAContext.base.admissionPolicy,
    some IDAContext.opportunity, "debtor"⟩, description, y, x⟩

def pair (a b : Term Δ .person) : Sub people Δ :=
  fun _ var => match var with
    | .here => a
    | .there .here => b

def grounding : Grounding people :=
  pair (.rigid ⟨payer, by decide⟩) (.rigid ⟨recipient, by decide⟩)

def raw : Nat → RawTerm
  | 0 => .var 0
  | 1 => .var 1
  | 2 => .rigid payer
  | 3 => .rigid recipient
  | 4 => .rigid debt
  | 5 => .var 2
  | _ => .rigid otherAlice

def substitution (a b : Nat) : Option (Sub people people) :=
  pair <$> Term.decode people .person (raw a) <*> Term.decode people .person (raw b)

def predicateDefinition : Context.PredicateDefinition := IDAContext.predicate
def revisedDefinition : Context.PredicateDefinition :=
  { predicateDefinition with key := { predicateDefinition.key with version := 2 } }
def vocabulary : Context.Vocabulary :=
  { IDAContext.vocabulary with definitions := [predicateDefinition, revisedDefinition] }
def predicate : Predicate vocabulary := ⟨predicateDefinition, by decide⟩
def revised : Predicate vocabulary := ⟨revisedDefinition, by decide⟩

def atom (term : Term people .person) (polarity : Bool := true) : Formula vocabulary people :=
  .atom predicate (.cons term .nil) polarity

def compound : Formula vocabulary people := .both (atom x) (atom y)
def targetContext : PremiseContext vocabulary := ⟨people, [atom x, atom y]⟩

def support (mode : Nat) : PremiseContext vocabulary :=
  ⟨people, match mode with
    | 0 => [compound]
    | 1 => [atom x]
    | 2 => [atom y]
    | 3 => []
    | 4 => [atom y, atom x]
    | 5 => [atom x, atom y false]
    | 6 => [atom x, .atom revised (.cons y .nil) true]
    | 7 => [atom x false, atom x]
    | _ => [atom (.rigid ⟨payer, by decide⟩), atom (.rigid ⟨recipient, by decide⟩)]⟩

def referenceCode (r : EntityRef) : Nat :=
  if r = payer then 1 else if r = recipient then 2
  else if r = otherAlice then 3 else if r = debt then 4 else 0

def argumentCodes (args : Args [] sorts) : List Nat :=
  match args with
  | .nil => []
  | .cons t rest => referenceCode t.reference.val :: argumentCodes rest

def formulaCodes : Formula vocabulary [] → List Nat
  | .atom _ args _ => argumentCodes args
  | .both a b => formulaCodes a ++ formulaCodes b

def syntaxCase (a b c d : Nat) : List Nat :=
  match substitution a b, substitution c d with
  | some σ, some τ =>
    let direct := inquiry.ground (σ.then (τ.then grounding))
    let staged := ((inquiry.subst σ).subst τ).ground grounding
    let roles := direct.description.action.operands.map fun o => referenceCode o.referent
    let φ := compound.subst (σ.then (τ.then grounding))
    let φstaged := ((compound.subst σ).subst τ).subst grounding
    [if direct.toGround = staged.toGround ∧ φ = φstaged then 1 else 0] ++ roles ++
      [referenceCode direct.toGround.accountable, referenceCode direct.toGround.performer.referent] ++
      formulaCodes φ
  | _, _ => List.replicate 8 0

def premiseCase (mode a b : Nat) : Nat :=
  match substitution a b with
  | none => 0
  | some σ => if (PremiseArrow.check (support mode) targetContext σ).isSome then 2 else 1

theorem controls :
    syntaxCase 0 1 0 1 = [1, 1, 2, 4, 2, 1, 1, 2] ∧
    syntaxCase 1 0 0 1 = [1, 2, 1, 4, 1, 2, 2, 1] ∧
    syntaxCase 4 1 0 1 = [0, 0, 0, 0, 0, 0, 0, 0] ∧
    syntaxCase 0 1 0 5 = [0, 0, 0, 0, 0, 0, 0, 0] ∧
    syntaxCase 6 1 0 1 = [1, 3, 2, 4, 2, 3, 3, 2] ∧
    syntaxCase 1 0 2 1 = [1, 2, 1, 4, 1, 2, 2, 1] ∧
    premiseCase 0 1 0 = 2 ∧ premiseCase 1 0 1 = 1 ∧ premiseCase 1 0 0 = 2 ∧
    premiseCase 5 0 1 = 1 ∧ premiseCase 6 0 1 = 1 ∧ premiseCase 7 0 1 = 1 ∧
    premiseCase 8 2 3 = 2 := by decide

def groundedSnapshot : Context.Snapshot :=
  let g := inquiry.ground grounding
  { IDAContext.base with
    envelope := { referenceEnvelope with action := g.description.action, context := g.frame.snapshot }
    time := g.frame.timeView
    admissionPolicy := g.frame.admissionPolicy
    inquiry := g.toGround
    opportunity := g.frame.opportunity }

theorem grounded_inquiry_checked :
    Context.resolve registry [groundedSnapshot] groundedSnapshot = .ok groundedSnapshot := by decide

theorem composed_nonidentity_arrows :
    let a : PremiseContext vocabulary := support 0
    let b : PremiseContext vocabulary := support 4
    let c : PremiseContext vocabulary := ⟨people, [compound]⟩
    let swap : Sub people people := pair y x
    ∃ (f : PremiseArrow a b) (g : PremiseArrow b c),
      f.substitution = swap ∧ g.substitution = swap ∧
      (f.comp g).substitution = Sub.id := by
  let f : PremiseArrow (support 0) (support 4) := ⟨pair y x, by decide⟩
  let g : PremiseArrow (support 4) ⟨people, [compound]⟩ := ⟨pair y x, by decide⟩
  refine ⟨f, g, rfl, rfl, ?_⟩
  funext k var
  cases var with
  | here => rfl
  | there rest => cases rest with
    | here => rfl
    | there impossible => cases impossible

theorem opposing_atoms_do_not_supply_another_atom :
    ¬ Derives (support 7).premises (atom y) := by
  change ¬ Derives [atom x false, atom x] (atom y)
  decide

end UsulTest.IDASubstitution
