import Usul.Typing.IDASubstitution

/-! ACT-04 interpretation over fixed typed reference carriers. A history
assigns truth values to ground predicates. Report rows and evidence admission
are separate from this conditional semantics. -/

namespace Usul.IDA.Semantics

open Substitution

abbrev Valuation (Γ : Variables) := (k : RefKind) → Var Γ k → Rigid k

def Valuation.grounding (ρ : Valuation Γ) : Grounding Γ :=
  fun k x => .rigid (ρ k x)

def Valuation.pull (σ : Sub Γ Δ) (ρ : Valuation Δ) : Valuation Γ :=
  fun k x => (σ k x).ground ρ.grounding

theorem grounding_pull (σ : Sub Γ Δ) (ρ : Valuation Δ) :
    (Valuation.pull σ ρ).grounding = σ.then ρ.grounding := by
  funext k x
  change Term.rigid ((σ k x).subst ρ.grounding).reference = (σ k x).subst ρ.grounding
  cases (σ k x).subst ρ.grounding with
  | rigid _ => rfl
  | var impossible => cases impossible

@[simp] theorem pull_id (ρ : Valuation Γ) : Valuation.pull Sub.id ρ = ρ := rfl

theorem pull_comp (σ : Sub Γ Δ) (τ : Sub Δ Θ) (ρ : Valuation Θ) :
    Valuation.pull (σ.then τ) ρ = Valuation.pull σ (Valuation.pull τ ρ) := by
  funext k x
  simp [Valuation.pull, Term.ground, grounding_pull, Sub.then]

/-- The truth assignment is total on the declared vocabulary and fixed during
substitution. Signed atoms test a truth value and its explicit complement. -/
structure History (v : Context.Vocabulary) where
  truth : (p : Predicate v) → Args [] p.val.arguments → Bool

def evaluate (h : History v) (ρ : Valuation Γ) : Formula v Γ → Bool
  | .atom p args sign => h.truth p (args.subst ρ.grounding) == sign
  | .both a b => evaluate h ρ a && evaluate h ρ b

def Satisfies (h : History v) (ρ : Valuation Γ) (f : Formula v Γ) : Prop :=
  evaluate h ρ f = true

def ModelsPremises (h : History v) (ρ : Valuation Γ) (premises : List (Formula v Γ)) : Prop :=
  ∀ f ∈ premises, Satisfies h ρ f

theorem evaluate_subst (h : History v) (f : Formula v Γ) (σ : Sub Γ Δ) (ρ : Valuation Δ) :
    evaluate h ρ (f.subst σ) = evaluate h (Valuation.pull σ ρ) f := by
  induction f <;> simp [Formula.subst, evaluate, grounding_pull, *]

theorem satisfaction_subst (h : History v) (f : Formula v Γ) (σ : Sub Γ Δ) (ρ : Valuation Δ) :
    Satisfies h ρ (f.subst σ) ↔ Satisfies h (Valuation.pull σ ρ) f := by
  simp [Satisfies, evaluate_subst]

theorem premises_subst (h : History v) (premises : List (Formula v Γ))
    (σ : Sub Γ Δ) (ρ : Valuation Δ) :
    ModelsPremises h ρ (premises.map (·.subst σ)) ↔
      ModelsPremises h (Valuation.pull σ ρ) premises := by
  constructor
  · intro hm f hf
    exact (satisfaction_subst h f σ ρ).mp (hm _ (List.mem_map_of_mem hf))
  · intro hm f hf
    obtain ⟨old, ho, rfl⟩ := List.mem_map.mp hf
    exact (satisfaction_subst h old σ ρ).mpr (hm _ ho)

theorem sound {premises : List (Formula v Γ)} {f : Formula v Γ}
    (d : Derives premises f) (h : History v) (ρ : Valuation Γ)
    (hp : ModelsPremises h ρ premises) : Satisfies h ρ f := by
  induction d with
  | assume hm => exact hp _ hm
  | both _ _ ha hb => exact Bool.and_eq_true_iff.mpr ⟨ha, hb⟩
  | left _ ih => exact (Bool.and_eq_true_iff.mp ih).1
  | right _ ih => exact (Bool.and_eq_true_iff.mp ih).2

theorem opposing_premises_incompatible (h : History v) (ρ : Valuation Γ)
    (p : Predicate v) (args : Args Γ p.val.arguments) :
    ¬ ModelsPremises h ρ [.atom p args true, .atom p args false] := by
  intro hm
  have hp := hm (.atom p args true) (by simp)
  have hn := hm (.atom p args false) (by simp)
  simp [Satisfies, evaluate] at hp hn
  simp [hp] at hn

/-- Sound conditional reconstruction along an ACT-02 premise-context arrow. -/
theorem sound_along {x y : PremiseContext v} {f : Formula v y.variables}
    (arrow : PremiseArrow x y) (d : Derives y.premises f) (h : History v)
    (ρ : Valuation x.variables) (hp : ModelsPremises h ρ x.premises) :
    Satisfies h ρ (f.subst arrow.substitution) := by
  apply (satisfaction_subst h f arrow.substitution ρ).mpr
  apply sound d h (Valuation.pull arrow.substitution ρ)
  intro premise hm
  exact (satisfaction_subst h premise arrow.substitution ρ).mp
    (sound (arrow.admissible premise hm) h ρ hp)

/-- A meaning for one exact registered definition and resolved role signature.
Different definitions, including another version of the same symbol, are
outside this interpreter's domain. -/
structure Interpreter (r : ActRegistry.Registry) (B : Type) where
  schema : Schema r
  meaning : Args [] (schema.parameters.map Parameter.kind) → B

def Interpreter.supported (i : Interpreter r B) (d : Description r Γ) : Prop :=
  d.schema.definition = i.schema.definition ∧ d.schema.parameters = i.schema.parameters

instance (i : Interpreter r B) (d : Description r Γ) : Decidable (i.supported d) := by
  unfold Interpreter.supported
  infer_instance

theorem supported_subst (i : Interpreter r B) (d : Description r Γ) (σ : Sub Γ Δ) :
    i.supported (d.subst σ) ↔ i.supported d := Iff.rfl

def Interpreter.read (i : Interpreter r B) (d : Description r []) : Option B :=
  if h : i.supported d then some (i.meaning (h.2 ▸ d.arguments)) else none

theorem read_isSome_iff (i : Interpreter r B) (d : Description r []) :
    (i.read d).isSome ↔ i.supported d := by
  unfold Interpreter.read
  split <;> simp_all

def Interpreter.interpret (i : Interpreter r B) (d : Description r Γ) (ρ : Valuation Γ) : Option B :=
  i.read (d.subst ρ.grounding)

theorem interpret_subst (i : Interpreter r B) (d : Description r Γ)
    (σ : Sub Γ Δ) (ρ : Valuation Δ) :
    i.interpret (d.subst σ) ρ = i.interpret d (Valuation.pull σ ρ) := by
  simp [Interpreter.interpret, grounding_pull]

theorem interpretation_supported (i : Interpreter r B) (d : Description r Γ)
    (ρ : Valuation Γ) : (i.interpret d ρ).isSome ↔ i.supported d := by
  rw [Interpreter.interpret, read_isSome_iff, supported_subst]

theorem groundInquiry_subst (i : Inquiry r Γ) (σ : Sub Γ Δ) (ρ : Valuation Δ) :
    (i.subst σ).ground ρ.grounding = i.ground (Valuation.pull σ ρ).grounding := by
  rw [Inquiry.ground_comp, grounding_pull]

def interpretInquiry (i : Inquiry r Γ) (ρ : Valuation Γ) : Context.Inquiry :=
  (i.ground ρ.grounding).toGround

theorem inquiry_subst (i : Inquiry r Γ) (σ : Sub Γ Δ) (ρ : Valuation Δ) :
    interpretInquiry (i.subst σ) ρ = interpretInquiry i (Valuation.pull σ ρ) := by
  exact congrArg Inquiry.toGround (groundInquiry_subst i σ ρ)

structure Point (v : Context.Vocabulary) (Γ : Variables) where
  history : History v
  valuation : Valuation Γ

def compatible (cases : List (Point v Γ)) (premises : List (Formula v Γ)) : List (Point v Γ) :=
  cases.filter fun p => premises.all (evaluate p.history p.valuation)

theorem mem_compatible {cases : List (Point v Γ)} {premises : List (Formula v Γ)}
    {p : Point v Γ} :
    p ∈ compatible cases premises ↔ p ∈ cases ∧ ModelsPremises p.history p.valuation premises := by
  simp [compatible, ModelsPremises, Satisfies, List.all_eq_true]

inductive Assessment where
  | noCandidates | inconsistent | robust | counterexample
  deriving DecidableEq, Repr

/-- Assessment is relative to the supplied finite list of candidate points. -/
def assess (cases : List (Point v Γ)) (premises : List (Formula v Γ)) (f : Formula v Γ) : Assessment :=
  match cases with
  | [] => .noCandidates
  | _ :: _ =>
    match compatible cases premises with
    | [] => .inconsistent
    | p :: rest =>
      if (p :: rest).all (fun q => evaluate q.history q.valuation f) then .robust
      else .counterexample

theorem robust_iff (cases : List (Point v Γ)) (premises : List (Formula v Γ)) (f : Formula v Γ) :
    assess cases premises f = .robust ↔
      compatible cases premises ≠ [] ∧
      ∀ p ∈ compatible cases premises, Satisfies p.history p.valuation f := by
  cases cases with
  | nil => simp [assess, compatible]
  | cons p rest =>
    cases hc : compatible (p :: rest) premises with
    | nil => simp [assess, hc]
    | cons q qs =>
      simp [assess, hc, List.all_eq_true, Satisfies]

end Usul.IDA.Semantics
