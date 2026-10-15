import Usul.Cat.Institution

/-!
# M11: the carriers as institutions, on the shared Boolean-state fragment

The three carriers agree on one fragment: finitely many Boolean state variables. TLA+ specs such
as `Taklif.tla` and `Istishab.tla` are written over it, the Lean kernel states its predicates
over it, and Haskell checks executable predicates on it. Signatures are variable counts `n`;
a signature morphism `Fin m → Fin n` renames variables (`finSet`).

| Institution | Sentences | Models | Carrier |
|---|---|---|---|
| `propI` | Boolean formulas `Form n` | valuations | Lean state predicates |
| `traceI` | `now φ`, `always φ` (`□φ`), `step ψ` (`[][ψ]`, `ψ` over primed and unprimed vars) | finite behaviours | TLA+ under TLC's bounds |
| `execI` | arbitrary `(Fin n → Bool) → Bool` | valuations | Haskell / `#eval` |

Comorphisms, both with surjective model maps so that borrowing applies in both directions
(`Comorphism.entails_iff`):

* `compile : propI ⥤ execI` sends a formula to its evaluator. What Haskell tests is the image.
* `initial : propI ⥤ traceI` sends a formula to its truth in the initial state (TLA+'s `Init`).

An invariant `□φ` is not the image of a comorphism from `propI`: no single valuation can stand for
a whole behaviour. It reduces to `propI` statewise instead (`always_iff`). That is what TLC does
when it checks an invariant at every reachable state.
-/

namespace Usul.Cat.Carriers

open Usul.Cat

/-- Finite sets of variables and renamings. -/
abbrev finSet : Cat where
  Obj := Nat
  Hom m n := Fin m → Fin n
  id _ := id
  comp f g := g ∘ f
  id_comp _ := rfl
  comp_id _ := rfl
  assoc _ _ _ := rfl

/-! ## Formulas over `n` Boolean variables -/

inductive Form (n : Nat) where
  | var (i : Fin n)
  | tt
  | not (φ : Form n)
  | and (φ ψ : Form n)
  | or (φ ψ : Form n)
  | imp (φ ψ : Form n)
  deriving Repr

namespace Form

variable {m n k : Nat}

def eval (v : Fin n → Bool) : Form n → Bool
  | var i => v i
  | tt => true
  | not φ => !φ.eval v
  | and φ ψ => φ.eval v && ψ.eval v
  | or φ ψ => φ.eval v || ψ.eval v
  | imp φ ψ => !φ.eval v || ψ.eval v

def rename (σ : Fin m → Fin n) : Form m → Form n
  | var i => var (σ i)
  | tt => tt
  | not φ => not (φ.rename σ)
  | and φ ψ => and (φ.rename σ) (ψ.rename σ)
  | or φ ψ => or (φ.rename σ) (ψ.rename σ)
  | imp φ ψ => imp (φ.rename σ) (ψ.rename σ)

@[simp] theorem eval_rename (σ : Fin m → Fin n) (v : Fin n → Bool) (φ : Form m) :
    (φ.rename σ).eval v = φ.eval (v ∘ σ) := by
  induction φ <;> simp_all [eval, rename]

@[simp] theorem rename_id (φ : Form n) : φ.rename id = φ := by
  induction φ <;> simp_all [rename]

theorem rename_comp (f : Fin m → Fin n) (g : Fin n → Fin k) (φ : Form m) :
    φ.rename (g ∘ f) = (φ.rename f).rename g := by
  induction φ <;> simp_all [rename]

end Form

/-! ## Lean state predicates -/

abbrev propI : Institution where
  Sig := finSet
  Sen := Form
  sen σ φ := φ.rename σ
  Mod n := Fin n → Bool
  red σ M := M ∘ σ
  Sat _ M φ := φ.eval M = true
  sen_id := Form.rename_id
  sen_comp f g := Form.rename_comp f g
  red_id _ := rfl
  red_comp _ _ _ := rfl
  satisfaction σ M φ := by rw [Form.eval_rename]

/-! ## Executable predicates -/

abbrev execI : Institution where
  Sig := finSet
  Sen n := (Fin n → Bool) → Bool
  sen σ p v := p (v ∘ σ)
  Mod n := Fin n → Bool
  red σ M := M ∘ σ
  Sat _ M p := p M = true
  sen_id _ := rfl
  sen_comp _ _ _ := rfl
  red_id _ := rfl
  red_comp _ _ _ := rfl
  satisfaction _ _ _ := Iff.rfl

/-- A formula compiles to its evaluator. -/
def compile : Comorphism propI execI where
  sig := Functor.id finSet
  α _ φ := φ.eval
  β _ M := M
  α_natural σ φ := funext fun v => (Form.eval_rename σ v φ).symm
  β_natural _ _ := rfl
  satisfaction _ _ _ := Iff.rfl

/-! ## Bounded behaviours (TLA+) -/

/-- A finite behaviour: an initial state and its successors (TLC explores bounded prefixes). -/
structure Trace (n : Nat) where
  init : Fin n → Bool
  rest : List (Fin n → Bool)

namespace Trace

variable {m n : Nat}

def states (t : Trace n) : List (Fin n → Bool) := t.init :: t.rest

/-- Consecutive pairs `(s, s')`. -/
def steps (t : Trace n) : List ((Fin n → Bool) × (Fin n → Bool)) := t.states.zip t.rest

def map (σ : Fin m → Fin n) (t : Trace n) : Trace m := ⟨t.init ∘ σ, t.rest.map (· ∘ σ)⟩

theorem states_map (σ : Fin m → Fin n) (t : Trace n) : (t.map σ).states = t.states.map (· ∘ σ) := rfl

theorem steps_map (σ : Fin m → Fin n) (t : Trace n) :
    (t.map σ).steps = t.steps.map (Prod.map (· ∘ σ) (· ∘ σ)) := by
  simp only [steps, states_map]; exact List.zip_map

end Trace

/-- A pair of states as one valuation: unprimed variables first, then primed. -/
def join {n : Nat} (s s' : Fin n → Bool) : Fin (n + n) → Bool := Fin.addCases s s'

/-- A renaming acting on both copies. -/
def lift2 {m n : Nat} (σ : Fin m → Fin n) : Fin (m + m) → Fin (n + n) :=
  Fin.addCases (fun i => Fin.castAdd n (σ i)) (fun i => Fin.natAdd n (σ i))

theorem join_lift2 {m n : Nat} (σ : Fin m → Fin n) (s s' : Fin n → Bool) :
    join s s' ∘ lift2 σ = join (s ∘ σ) (s' ∘ σ) := by
  funext i
  refine Fin.addCases (fun j => ?_) (fun j => ?_) i <;>
    simp only [join, lift2, Function.comp, Fin.addCases_left, Fin.addCases_right]

theorem lift2_id {n : Nat} : lift2 (id : Fin n → Fin n) = id := by
  funext i
  refine Fin.addCases (fun j => ?_) (fun j => ?_) i <;>
    simp only [lift2, id, Fin.addCases_left, Fin.addCases_right]

theorem lift2_comp {m n k : Nat} (f : Fin m → Fin n) (g : Fin n → Fin k) :
    lift2 (g ∘ f) = lift2 g ∘ lift2 f := by
  funext i
  refine Fin.addCases (fun j => ?_) (fun j => ?_) i <;>
    simp only [lift2, Function.comp, Fin.addCases_left, Fin.addCases_right]

/-- TLA+ sentences: a state predicate at `Init`, an invariant `□φ`, an action property `[][ψ]`. -/
inductive TSen (n : Nat) where
  | now (φ : Form n)
  | always (φ : Form n)
  | step (ψ : Form (n + n))
  deriving Repr

namespace TSen

variable {m n k : Nat}

def rename (σ : Fin m → Fin n) : TSen m → TSen n
  | now φ => now (φ.rename σ)
  | always φ => always (φ.rename σ)
  | step ψ => step (ψ.rename (lift2 σ))

def holds (t : Trace n) : TSen n → Bool
  | now φ => φ.eval t.init
  | always φ => t.states.all φ.eval
  | step ψ => t.steps.all fun p => ψ.eval (join p.1 p.2)

theorem rename_id (φ : TSen n) : φ.rename id = φ := by
  cases φ <;> simp [rename, lift2_id]

theorem rename_comp (f : Fin m → Fin n) (g : Fin n → Fin k) (φ : TSen m) :
    φ.rename (g ∘ f) = (φ.rename f).rename g := by
  cases φ <;> simp [rename, Form.rename_comp, lift2_comp]

theorem holds_rename (σ : Fin m → Fin n) (t : Trace n) (φ : TSen m) :
    (φ.rename σ).holds t = φ.holds (t.map σ) := by
  cases φ with
  | now φ => simp [rename, holds, Trace.map]
  | always φ => simp [rename, holds, Trace.states_map, List.all_map, Function.comp_def]
  | step ψ =>
    simp only [rename, holds, Trace.steps_map, List.all_map]
    congr 1; funext p
    simp [← join_lift2]

end TSen

abbrev traceI : Institution where
  Sig := finSet
  Sen := TSen
  sen σ φ := φ.rename σ
  Mod := Trace
  red σ t := t.map σ
  Sat _ t φ := φ.holds t = true
  sen_id := TSen.rename_id
  sen_comp f g := TSen.rename_comp f g
  red_id t := by cases t; simp only [Trace.map, Function.comp_id, List.map_id_fun', id]
  red_comp _ _ t := by cases t; simp only [Trace.map, List.map_map]; rfl
  satisfaction σ t φ := by rw [TSen.holds_rename]

/-- A state predicate read at the initial state: TLA+'s `Init`. -/
def initial : Comorphism propI traceI where
  sig := Functor.id finSet
  α _ φ := .now φ
  β _ t := t.init
  α_natural _ _ := rfl
  β_natural _ _ := rfl
  satisfaction _ _ _ := Iff.rfl

/-- Invariants reduce to propositional truth at every state of the behaviour. -/
theorem always_iff {n : Nat} (t : Trace n) (φ : Form n) :
    traceI.Sat n t (.always φ) ↔ ∀ s ∈ t.states, propI.Sat n s φ := by
  simp [TSen.holds]

/-- Both comorphisms have surjective model maps, so checks in either carrier are exact. -/
theorem compile_onto (n : Nat) (M : propI.Mod n) : ∃ M', compile.β n M' = M := ⟨M, rfl⟩

theorem initial_onto (n : Nat) (M : propI.Mod n) : ∃ t, initial.β n t = M := ⟨⟨M, []⟩, rfl⟩

/-! ## Deciding the fragment -/

/-- Extend a valuation by a value for a new variable `0`. -/
def cons {n : Nat} (b : Bool) (v : Fin n → Bool) : Fin (n + 1) → Bool := fun i => Fin.cases b v i

theorem cons_self_tail {n : Nat} (v : Fin (n + 1) → Bool) : cons (v 0) (fun i => v i.succ) = v := by
  funext i; refine Fin.cases ?_ (fun j => ?_) i <;> rfl

/-- Every valuation of `n` variables. -/
def allVals : (n : Nat) → List (Fin n → Bool)
  | 0 => [Fin.elim0]
  | n + 1 => (allVals n).flatMap fun v => [cons false v, cons true v]

theorem mem_allVals : ∀ {n : Nat} (v : Fin n → Bool), v ∈ allVals n
  | 0, v => by simp only [allVals, List.mem_singleton]; funext i; exact i.elim0
  | n + 1, v => by
    rw [← cons_self_tail v]
    simp only [allVals, List.mem_flatMap, List.mem_cons, List.not_mem_nil, or_false]
    exact ⟨fun i => v i.succ, mem_allVals _, by cases v 0 <;> simp⟩

/-- Propositional consequence, decided by truth tables. -/
def entailsB (n : Nat) (Γ : List (Form n)) (φ : Form n) : Bool :=
  (allVals n).all fun v => !(Γ.all (·.eval v)) || φ.eval v

theorem entailsB_iff {n : Nat} {Γ : List (Form n)} {φ : Form n} :
    entailsB n Γ φ = true ↔ propI.Entails n Γ φ := by
  simp only [entailsB, List.all_eq_true, Bool.or_eq_true, Bool.not_eq_true', Institution.Entails]
  constructor
  · intro h M hM
    rcases h M (mem_allVals M) with h | h
    · simp only [List.all_eq_false] at h
      obtain ⟨ψ, hψ, hf⟩ := h
      exact absurd (hM ψ hψ) (by simpa using hf)
    · exact h
  · intro h v _
    by_cases hv : Γ.all (·.eval v) = true
    · exact .inr (h v fun ψ hψ => List.all_eq_true.1 hv ψ hψ)
    · exact .inl (by simpa using hv)

end Usul.Cat.Carriers
