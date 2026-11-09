import Usul.Typing.IDAContext

/-! ACT-02 syntax over fixed ACT-01 registries. The conditional calculus
uses assumptions and conjunction. It has no evidence or ruling constructor. -/

namespace Usul.IDA.Substitution

abbrev Variables := List RefKind

/-- Positions carry their declared sort. Two positions of one sort can differ. -/
inductive Var : Variables → RefKind → Type where
  | here : Var (k :: Γ) k
  | there : Var Γ k → Var (j :: Γ) k
  deriving DecidableEq

abbrev Rigid (k : RefKind) := {r : EntityRef // r.kind = k ∧ r.WellFormed}

inductive Term (Γ : Variables) (k : RefKind) where
  | var (x : Var Γ k)
  | rigid (r : Rigid k)
  deriving DecidableEq

inductive RawTerm where
  | var (position : Nat)
  | rigid (reference : EntityRef)

/-- Read an untrusted position at its requested sort. -/
def Var.lookup : (Γ : Variables) → (k : RefKind) → Nat → Option (Var Γ k)
  | [], _, _ => none
  | j :: _, k, 0 => if h : j = k then some (h ▸ Var.here) else none
  | _ :: tail, k, n + 1 => (lookup tail k n).map Var.there

def Term.decode (Γ : Variables) (k : RefKind) : RawTerm → Option (Term Γ k)
  | .var n => (Var.lookup Γ k n).map .var
  | .rigid r =>
    if h : r.kind = k ∧ r.WellFormed then some (.rigid ⟨r, h⟩) else none

theorem Term.decode_wrong_sort (Γ : Variables) (k : RefKind) (r : EntityRef)
    (h : r.kind ≠ k) : Term.decode Γ k (.rigid r) = none := by
  simp [decode, h]

abbrev Sub (Γ Δ : Variables) := (k : RefKind) → Var Γ k → Term Δ k

def Sub.id : Sub Γ Γ := fun _ x => .var x

def Term.subst (t : Term Γ k) (σ : Sub Γ Δ) : Term Δ k :=
  match t with
  | .var x => σ k x
  | .rigid r => .rigid r

/-- First instantiate from Γ into Δ, then from Δ into Θ. -/
def Sub.then (σ : Sub Γ Δ) (τ : Sub Δ Θ) : Sub Γ Θ :=
  fun k x => (σ k x).subst τ

@[simp] theorem Term.subst_id (t : Term Γ k) : t.subst Sub.id = t := by
  cases t <;> rfl

@[simp] theorem Term.subst_comp (t : Term Γ k) (σ : Sub Γ Δ) (τ : Sub Δ Θ) :
    (t.subst σ).subst τ = t.subst (σ.then τ) := by
  cases t <;> rfl

@[simp] theorem Term.rigid_preserved (r : Rigid k) (σ : Sub Γ Δ) :
    (Term.rigid r).subst σ = .rigid r := rfl

@[simp] theorem Sub.id_then (σ : Sub Γ Δ) : Sub.id.then σ = σ := rfl

@[simp] theorem Sub.then_id (σ : Sub Γ Δ) : σ.then Sub.id = σ := by
  funext k x
  exact (σ k x).subst_id

theorem Sub.assoc (σ : Sub Γ Δ) (τ : Sub Δ Θ) (υ : Sub Θ Ξ) :
    (σ.then τ).then υ = σ.then (τ.then υ) := by
  funext k x
  exact (σ k x).subst_comp τ υ

abbrev Grounding (Γ : Variables) := Sub Γ []

def Term.reference : Term [] k → Rigid k
  | .rigid r => r

def Term.ground (t : Term Γ k) (ρ : Grounding Γ) : Rigid k :=
  (t.subst ρ).reference

inductive Args (Γ : Variables) : List RefKind → Type where
  | nil : Args Γ []
  | cons : Term Γ k → Args Γ ks → Args Γ (k :: ks)
  deriving DecidableEq

def Args.subst (args : Args Γ ks) (σ : Sub Γ Δ) : Args Δ ks :=
  match args with
  | .nil => .nil
  | .cons t rest => .cons (t.subst σ) (rest.subst σ)

@[simp] theorem Args.subst_id (args : Args Γ ks) : args.subst Sub.id = args := by
  induction args with
  | nil => rfl
  | cons t rest ih => simp [subst, ih]

@[simp] theorem Args.subst_comp (args : Args Γ ks) (σ : Sub Γ Δ) (τ : Sub Δ Θ) :
    (args.subst σ).subst τ = args.subst (σ.then τ) := by
  induction args with
  | nil => rfl
  | cons t rest ih => simp [subst, ih]

def Args.get (args : Args Γ ks) (slot : Var ks k) : Term Γ k :=
  match args, slot with
  | .cons t _, .here => t
  | .cons _ rest, .there i => rest.get i

theorem Args.get_subst (args : Args Γ ks) (slot : Var ks k) (σ : Sub Γ Δ) :
    (args.subst σ).get slot = (args.get slot).subst σ := by
  induction slot with
  | here => cases args; rfl
  | there inner ih =>
    cases args with
    | cons t rest => exact ih rest

theorem Args.shared_image (args : Args Γ ks) (left right : Var ks k)
    (h : args.get left = args.get right) (σ : Sub Γ Δ) :
    (args.subst σ).get left = (args.subst σ).get right := by
  simp [get_subst, h]

/-- Every use of a variable reads the same image, even across different roles
and formulas. The dependency is a shared variable position. -/
theorem shared_variable_ground (x : Var Γ k) (ρ : Grounding Γ) :
    (Term.var x).ground ρ = (ρ k x).reference := rfl

structure Schema (registry : ActRegistry.Registry) where
  definition : ActRegistry.Definition
  parameters : List Parameter
  member : definition ∈ registry.definitions
  unique : registry.Unique
  shaped : registry.Shaped
  resolved : ActRegistry.resolveRoles definition.roles = some parameters

def Schema.ofResolved {r : ActRegistry.Registry} {e : ActRegistry.Envelope}
    {d : ActRegistry.Definition} (h : ActRegistry.resolve r e = .ok d) : Schema r where
  definition := d
  parameters := e.action.operation.parameters
  member := (ActRegistry.resolve_registered h).1
  unique := ((ActRegistry.resolve_iff r e d).mp h).1
  shaped := ((ActRegistry.resolve_iff r e d).mp h).2.1
  resolved := by
    obtain ⟨ps, hp, ho, _⟩ := ActRegistry.resolve_schema h
    simpa [ho] using hp

def Schema.operation (schema : Schema r) : Operation :=
  ⟨schema.definition.key.symbol, schema.parameters⟩

structure Description (r : ActRegistry.Registry) (Γ : Variables) where
  schema : Schema r
  arguments : Args Γ (schema.parameters.map Parameter.kind)

def Description.subst (d : Description r Γ) (σ : Sub Γ Δ) : Description r Δ :=
  ⟨d.schema, d.arguments.subst σ⟩

@[simp] theorem Description.subst_id (d : Description r Γ) : d.subst Sub.id = d := by
  cases d
  simp [subst]

@[simp] theorem Description.subst_comp (d : Description r Γ) (σ : Sub Γ Δ) (τ : Sub Δ Θ) :
    (d.subst σ).subst τ = d.subst (σ.then τ) := by
  cases d
  simp [subst]

theorem Description.schema_preserved (d : Description r Γ) (σ : Sub Γ Δ) :
    (d.subst σ).schema = d.schema := rfl

def operands : (ps : List Parameter) → Args [] (ps.map Parameter.kind) → List Operand
  | [], .nil => []
  | p :: ps, .cons t rest => ⟨p.role, t.reference.val⟩ :: operands ps rest

theorem operands_signature (ps : List Parameter) (args : Args [] (ps.map Parameter.kind)) :
    (operands ps args).map Operand.parameter = ps := by
  induction ps with
  | nil => cases args; rfl
  | cons p ps ih =>
    cases args with
    | cons t rest =>
      have hs : (⟨p.role, t.reference.val.kind⟩ : Parameter) = p := by
        cases p
        simp only [Parameter.mk.injEq, true_and]
        exact t.reference.property.1
      simpa [operands, Operand.parameter, ih rest] using hs

theorem operands_references (ps : List Parameter) (args : Args [] (ps.map Parameter.kind)) :
    (operands ps args).all (fun o => decide o.referent.WellFormed) = true := by
  induction ps with
  | nil => cases args; rfl
  | cons p ps ih =>
    cases args with
    | cons t rest => simp [operands, t.reference.property.2, ih rest]

def Description.action (d : Description r []) : Action :=
  ⟨d.schema.operation, operands d.schema.parameters d.arguments⟩

theorem Description.action_wellFormed (d : Description r []) : d.action.WellFormed := by
  have hd := d.schema.shaped d.schema.definition d.schema.member
  have hr := ActRegistry.resolved_roles_exact d.schema.resolved
  have names : d.schema.definition.roles.map ActRegistry.RoleSpec.role =
      d.schema.parameters.map Parameter.role := by
    rw [hr, List.map_map]
    rfl
  refine ⟨⟨hd.1, ?_, names ▸ hd.2.2.2.2⟩, operands_signature _ _, operands_references _ _⟩
  rw [List.all_eq_true]
  intro p hp
  have hm : (⟨p.role, some p.kind⟩ : ActRegistry.RoleSpec) ∈ d.schema.definition.roles := by
    rw [hr]
    exact List.mem_map.mpr ⟨p, hp, rfl⟩
  exact decide_eq_true (hd.2.2.2.1 _ hm)

def Description.ground (d : Description r Γ) (ρ : Grounding Γ) : Action :=
  (d.subst ρ).action

/-- The composed substitution is executable grounding with the registered role
signature and well-formed rigid operands. -/
theorem Description.subst_wellFormed (d : Description r Γ) (σ : Sub Γ Δ) (ρ : Grounding Δ) :
    ((d.subst σ).ground ρ).WellFormed :=
  (d.subst σ |>.subst ρ).action_wellFormed

structure InquiryFrame where
  questionId : Nat
  question : Question
  subjectId : Nat
  subject : Usul.Subject
  domain : Usul.Domain
  snapshot : ActRegistry.Snapshot
  timeView : Context.TimeView
  admissionPolicy : ActRegistry.KindKey
  opportunity : Option Opportunity
  performerRole : String

/-- The terms in the subject and performer positions are independent of one
another. ACT-01 checks the grounded performer's declared role membership. -/
structure Inquiry (r : ActRegistry.Registry) (Γ : Variables) where
  frame : InquiryFrame
  description : Description r Γ
  accountable : Term Γ .person
  performer : Term Γ .person

def Inquiry.subst (i : Inquiry r Γ) (σ : Sub Γ Δ) : Inquiry r Δ :=
  ⟨i.frame, i.description.subst σ, i.accountable.subst σ, i.performer.subst σ⟩

@[simp] theorem Inquiry.subst_id (i : Inquiry r Γ) : i.subst Sub.id = i := by
  cases i
  simp [subst]

@[simp] theorem Inquiry.subst_comp (i : Inquiry r Γ) (σ : Sub Γ Δ) (τ : Sub Δ Θ) :
    (i.subst σ).subst τ = i.subst (σ.then τ) := by
  cases i
  simp [subst]

theorem Inquiry.frame_preserved (i : Inquiry r Γ) (σ : Sub Γ Δ) :
    (i.subst σ).frame = i.frame := rfl

def Inquiry.toGround (i : Inquiry r []) : Context.Inquiry :=
  let f := i.frame
  let action := i.description.action
  let target := match f.opportunity with
    | none => TargetExpr.perform action
    | some o => .omit action o
  ⟨f.questionId, f.question,
   ⟨f.subjectId, f.subject, .structured target, f.snapshot.contextId, f.snapshot.timeId,
    f.snapshot.profile, f.snapshot.profileVersion, f.domain⟩,
   i.accountable.reference.val, ⟨f.performerRole, i.performer.reference.val⟩⟩

def Inquiry.ground (i : Inquiry r Γ) (ρ : Grounding Γ) : Inquiry r [] :=
  i.subst ρ

theorem Inquiry.ground_comp (i : Inquiry r Γ) (σ : Sub Γ Δ) (ρ : Grounding Δ) :
    (i.subst σ).ground ρ = i.ground (σ.then ρ) := by
  simp [ground]

abbrev Predicate (v : Context.Vocabulary) :=
  {d : Context.PredicateDefinition // v.WellFormed ∧ d ∈ v.definitions}

inductive Formula (v : Context.Vocabulary) (Γ : Variables) where
  | atom (predicate : Predicate v) (arguments : Args Γ predicate.val.arguments) (polarity : Bool)
  | both (left right : Formula v Γ)
  deriving DecidableEq

def Formula.subst (f : Formula v Γ) (σ : Sub Γ Δ) : Formula v Δ :=
  match f with
  | .atom p args polarity => .atom p (args.subst σ) polarity
  | .both a b => .both (a.subst σ) (b.subst σ)

@[simp] theorem Formula.subst_id (f : Formula v Γ) : f.subst Sub.id = f := by
  induction f <;> simp_all [subst]

@[simp] theorem Formula.subst_comp (f : Formula v Γ) (σ : Sub Γ Δ) (τ : Sub Δ Θ) :
    (f.subst σ).subst τ = f.subst (σ.then τ) := by
  induction f <;> simp_all [subst]

/-- A proof-irrelevant conditional entailment relation. Both polarities are
ordinary atoms, so the calculus has no explosion rule. -/
inductive Derives (premises : List (Formula v Γ)) : Formula v Γ → Prop where
  | assume : f ∈ premises → Derives premises f
  | both : Derives premises a → Derives premises b → Derives premises (.both a b)
  | left : Derives premises (.both a b) → Derives premises a
  | right : Derives premises (.both a b) → Derives premises b

theorem Derives.subst {premises : List (Formula v Γ)} {f : Formula v Γ}
    (h : Derives premises f) (σ : Sub Γ Δ) :
    Derives (premises.map (·.subst σ)) (f.subst σ) := by
  induction h with
  | assume hm => exact .assume (List.mem_map_of_mem hm)
  | both _ _ hl hr => exact .both hl hr
  | left _ ih => exact .left ih
  | right _ ih => exact .right ih

theorem Derives.cut {premises support : List (Formula v Γ)} {f : Formula v Γ}
    (h : Derives premises f) (replacement : ∀ q ∈ premises, Derives support q) :
    Derives support f := by
  induction h with
  | assume hm => exact replacement _ hm
  | both _ _ hl hr => exact .both hl hr
  | left _ ih => exact .left ih
  | right _ ih => exact .right ih

/-- Retain complete atoms, including all reference arguments and polarity. -/
def Formula.atoms (f : Formula v Γ) : List (Formula v Γ) :=
  match f with
  | .atom .. => [f]
  | .both a b => a.atoms ++ b.atoms

theorem Derives.of_atom {p q : Formula v Γ} {premises : List (Formula v Γ)}
    (h : Derives premises p) (hq : q ∈ p.atoms) : Derives premises q := by
  induction p with
  | atom predicate args polarity =>
    have he := List.mem_singleton.mp hq
    subst q
    exact h
  | both a b ha hb =>
    rcases List.mem_append.mp hq with hqa | hqb
    · exact ha (.left h) hqa
    · exact hb (.right h) hqb

theorem Derives.iff_atoms {premises : List (Formula v Γ)} {f : Formula v Γ} :
    Derives premises f ↔ ∀ a ∈ f.atoms, a ∈ premises.flatMap Formula.atoms := by
  constructor
  · intro h
    induction h with
    | assume hm => exact fun _ ha => List.mem_flatMap.mpr ⟨_, hm, ha⟩
    | both _ _ hl hr =>
      intro a ha
      rcases List.mem_append.mp ha with h | h
      · exact hl a h
      · exact hr a h
    | left _ ih => exact fun a ha => ih a (List.mem_append_left _ ha)
    | right _ ih => exact fun a ha => ih a (List.mem_append_right _ ha)
  · intro h
    induction f with
    | atom p args polarity =>
      have hm := h (.atom p args polarity) (by simp [Formula.atoms])
      obtain ⟨source, hs, ha⟩ := List.mem_flatMap.mp hm
      exact (Derives.assume hs).of_atom ha
    | both a b ha hb =>
      exact .both (ha (fun q hq => h q (List.mem_append_left _ hq)))
        (hb (fun q hq => h q (List.mem_append_right _ hq)))

instance (premises : List (Formula v Γ)) (f : Formula v Γ) :
    Decidable (Derives premises f) :=
  decidable_of_iff _ Derives.iff_atoms.symm

structure PremiseContext (v : Context.Vocabulary) where
  variables : Variables
  premises : List (Formula v variables)

structure PremiseArrow {v : Context.Vocabulary} (source target : PremiseContext v) where
  substitution : Sub target.variables source.variables
  admissible : ∀ f ∈ target.premises, Derives source.premises (f.subst substitution)

def PremiseArrow.check (x y : PremiseContext v)
    (σ : Sub y.variables x.variables) : Option (PremiseArrow x y) :=
  if h : ∀ f ∈ y.premises, Derives x.premises (f.subst σ) then some ⟨σ, h⟩ else none

theorem PremiseArrow.check_iff (x y : PremiseContext v) (σ : Sub y.variables x.variables) :
    (PremiseArrow.check x y σ).isSome ↔
      ∀ f ∈ y.premises, Derives x.premises (f.subst σ) := by
  unfold check
  split <;> simp_all

def PremiseArrow.id (x : PremiseContext v) : PremiseArrow x x :=
  ⟨Sub.id, fun _ hf => by simpa using Derives.assume hf⟩

/-- Diagrammatic order, so the first arrow has source x. Substitution and
simultaneous cut compose the conditional premise witnesses. -/
def PremiseArrow.comp (f : PremiseArrow x y) (g : PremiseArrow y z) : PremiseArrow x z where
  substitution := g.substitution.then f.substitution
  admissible q hq := by
    have h := (g.admissible q hq).subst f.substitution
    rw [Formula.subst_comp] at h
    exact h.cut (fun p hp => by
      obtain ⟨prior, hm, rfl⟩ := List.mem_map.mp hp
      exact f.admissible prior hm)

theorem PremiseArrow.ext {x y : PremiseContext v} {f g : PremiseArrow x y}
    (h : f.substitution = g.substitution) : f = g := by
  cases f
  cases g
  cases h
  rfl

@[simp] theorem PremiseArrow.id_comp (f : PremiseArrow x y) : (id x).comp f = f :=
  ext f.substitution.then_id

@[simp] theorem PremiseArrow.comp_id (f : PremiseArrow x y) : f.comp (id y) = f :=
  ext (Sub.id_then f.substitution)

theorem PremiseArrow.assoc (f : PremiseArrow x y) (g : PremiseArrow y z)
    (h : PremiseArrow z w) : (f.comp g).comp h = f.comp (g.comp h) :=
  ext (Sub.assoc h.substitution g.substitution f.substitution).symm

end Usul.IDA.Substitution
