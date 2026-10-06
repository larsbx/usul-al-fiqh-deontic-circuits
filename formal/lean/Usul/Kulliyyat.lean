import Usul.Sadi

/-!
# al-Saʿdī's general maxims (kulliyyāt) — formal readings (roadmap M3)

The rules that need small models of custom (Q9, Q48), intent (Q5, Q57), utterance (Q29),
cause and condition in time (Q17, Q39), and the bookkeeping of causes, choices and
acts of worship (Q15, Q31, Q34, Q41, Q50). Rule numbers as in
`corpus/proposals/sadi_qawaid.json`; every reading is a candidate until reviewed.
-/

namespace Usul.Kulliyyat

open Usul

/-! ## Q5 — worship rests on sincerity towards the One worshipped and following the Messenger -/

structure Worship where
  sincere : Bool
  follows : Bool
  deriving DecidableEq, Repr

def Worship.gate : Sadi.Gate Worship :=
  ⟨[fun w => w.sincere = true, fun w => w.follows = true], []⟩

theorem q05_both_foundations (w : Worship) : Worship.gate.Holds w ↔ w.sincere = true ∧ w.follows = true := by
  constructor
  · intro ⟨hc, _⟩
    exact ⟨hc (fun w => w.sincere = true) (by simp [Worship.gate]),
      hc (fun w => w.follows = true) (by simp [Worship.gate])⟩
  · intro ⟨hs, hf⟩
    refine ⟨?_, by simp [Worship.gate]⟩
    intro c hc
    simp [Worship.gate] at hc
    rcases hc with rfl | rfl <;> assumption

/-! ## Q9 — custom decides every ruling whose measure the Lawgiver did not define -/

/-- The measure in force: the law's, when it defines one; otherwise the custom's. -/
def measure {α : Type} (lawDefined : Option α) (custom : α) : α := lawDefined.getD custom

theorem q09_law_prevails {α : Type} (m c : α) : measure (some m) c = m := rfl
theorem q09_custom_decides {α : Type} (c : α) : measure none c = c := rfl

/-- Where the law is silent, the ruling follows custom as custom changes. -/
theorem q09_follows_custom {α : Type} {c c' : α} (h : c ≠ c') : measure none c ≠ measure none c' := h

/-! ## Q15 — no harm and no reciprocal harm -/

/-- Outside prescribed retaliation, inflicting harm is permitted only if it is none, whatever
harm one has received (the second half: *wa-lā ḍirār*). -/
def mayInflict (_received harm : Nat) : Bool := harm == 0

theorem q15_no_harm (r h : Nat) : mayInflict r h = true ↔ h = 0 := by simp [mayInflict]
theorem q15_no_reciprocal_harm (r r' h : Nat) : mayInflict r h = mayInflict r' h := rfl

/-! ## Q17 — whoever hastens a thing before its time is punished by being deprived of it -/

def obtains (entitled hastened : Bool) : Bool := entitled && !hastened

theorem q17_hastening_deprives (e : Bool) : obtains e true = false := by cases e <;> rfl
theorem q17_never_beyond_entitlement (e h : Bool) (hb : obtains e h = true) : e = true := by
  cases e <;> simp_all [obtains]

/-! ## Q29 — an utterance is qualified by its attachments (description, condition,
exception, …) -/

/-- An utterance: a base extension narrowed by its qualifiers. -/
structure Utterance (α : Type) where
  base : α → Bool
  qualifiers : List (α → Bool)

def Utterance.meaning {α : Type} (u : Utterance α) (x : α) : Bool :=
  u.base x && u.qualifiers.all (· x)

theorem q29_unqualified {α : Type} (b : α → Bool) (x : α) : (Utterance.mk b []).meaning x = b x := by
  simp [Utterance.meaning]

theorem q29_qualifiers_narrow {α : Type} (u : Utterance α) (x : α) (h : u.meaning x = true) :
    u.base x = true := by
  simp [Utterance.meaning] at h; exact h.1

theorem q29_attach_narrows {α : Type} (u : Utterance α) (q : α → Bool) (x : α)
    (h : (Utterance.mk u.base (q :: u.qualifiers)).meaning x = true) : u.meaning x = true := by
  simp [Utterance.meaning] at h ⊢; exact ⟨h.1, h.2.2⟩

/-! ## Q31 — rulings divide according to their distinct causes; each cause operates in its
own effect -/

def rulings {C R : Type} (present : C → Bool) (effect : C → R → Bool) (causes : List C) (r : R) : Bool :=
  causes.any fun c => present c && effect c r

theorem q31_each_cause_its_effect {C R : Type} (present : C → Bool) (effect : C → R → Bool)
    (causes : List C) (r : R) :
    rulings present effect causes r = true ↔ ∃ c ∈ causes, present c = true ∧ effect c r = true := by
  simp [rulings]

/-- An absent cause takes away only its own effects. -/
theorem q31_absent_cause_inert {C R : Type} (present : C → Bool) (effect : C → R → Bool)
    (c : C) (cs : List C) (r : R) (h : present c = false) :
    rulings present effect (c :: cs) r = rulings present effect cs r := by
  simp [rulings, h]

/-! ## Q34 — a choice given for one's own benefit is free preference; one given for
another's benefit obliges seeking the other's best interest -/

inductive ChoiceFor where
  | self | other
  deriving DecidableEq, Repr

def Admissible {α : Type} (f : ChoiceFor) (options : List α) (interest : α → Nat) (pick : α) : Prop :=
  pick ∈ options ∧ (f = .other → ∀ o ∈ options, interest o ≤ interest pick)

theorem q34_other_stricter {α : Type} (options : List α) (interest : α → Nat) (p : α)
    (h : Admissible .other options interest p) : Admissible .self options interest p :=
  ⟨h.1, fun h' => nomatch h'⟩

/-- Q33's `best` always discharges a guardian's choice. -/
theorem q34_best_admissible {α : Type} (options : List α) (interest : α → Nat) {b : α}
    (h : Sadi.best (fun o => (interest o : Int)) options = some b) :
    Admissible .other options interest b :=
  ⟨Sadi.best_mem _ h, fun _ => Sadi.q33_higher_benefit interest h⟩

/-! ## Q39 — worship and expiations may not precede the cause of obligation, but may precede
its condition once the cause exists -/

/-- Performance at time `t`, cause at `cause`, condition at `cond`. -/
def timelyPerformance (t cause _cond : Nat) : Bool := decide (cause ≤ t)

theorem q39_not_before_cause (t s c : Nat) (h : t < s) : timelyPerformance t s c = false := by
  simp [timelyPerformance]; omega

theorem q39_before_condition_after_cause (t s c : Nat) (hs : s ≤ t) (_ : t < c) :
    timelyPerformance t s c = true := by
  simp [timelyPerformance]; omega

/-! ## Q41 — two acts of worship of one kind and one purpose merge into one performance -/

structure Act (K P : Type) where
  kind : K
  purpose : P
  deriving DecidableEq, Repr

def discharges {K P : Type} [DecidableEq K] [DecidableEq P] (done owed : Act K P) : Bool :=
  done.kind == owed.kind && done.purpose == owed.purpose

theorem q41_one_performance {K P : Type} [DecidableEq K] [DecidableEq P] (a : Act K P)
    (owed : List (Act K P)) (h : ∀ b ∈ owed, b.kind = a.kind ∧ b.purpose = a.purpose) :
    owed.all (discharges a) = true := by
  simp only [List.all_eq_true]
  intro b hb
  obtain ⟨hk, hp⟩ := h b hb
  simp [discharges, hk, hp]

theorem q41_distinct_purposes_stay_apart {K P : Type} [DecidableEq K] [DecidableEq P]
    (a b : Act K P) (h : a.purpose ≠ b.purpose) : discharges a b = false := by
  simp [discharges, h]

/-! ## Q48 — the parts of a single act build on one another when customarily continuous -/

/-- Consecutive parts (by time) lie within the customary gap `g`. -/
def continuous (g : Nat) : List Nat → Bool
  | a :: b :: rest => decide (b - a ≤ g) && continuous g (b :: rest)
  | _ => true

/-- A more lenient custom never breaks a continuity a stricter one accepted. -/
theorem q48_custom_monotone {g g' : Nat} (hg : g ≤ g') : ∀ (ts : List Nat),
    continuous g ts = true → continuous g' ts = true
  | [], _ => rfl
  | [_], _ => rfl
  | a :: b :: rest, h => by
    simp only [continuous, Bool.and_eq_true, decide_eq_true_eq] at h ⊢
    exact ⟨by omega, q48_custom_monotone hg (b :: rest) h.2⟩

/-! ## Q50 — what is not established independently may be established as a dependent -/

def established (independentProof followsEstablished : Bool) : Bool :=
  independentProof || followsEstablished

theorem q50_dependent_suffices : established false true = true := rfl
theorem q50_independent_suffices (f : Bool) : established true f = true := by cases f <;> rfl
theorem q50_neither_fails : established false false = false := rfl

/-! ## Q57 — speakers' words are read according to their intent wherever possible -/

def reading {M : Type} (literal : M) (intended : Option M) (possible : M → Bool) : M :=
  match intended with
  | some m => if possible m then m else literal
  | none => literal

theorem q57_possible_intent_prevails {M : Type} (l m : M) (p : M → Bool) (h : p m = true) :
    reading l (some m) p = m := by simp [reading, h]

theorem q57_impossible_intent_falls_back {M : Type} (l m : M) (p : M → Bool) (h : p m = false) :
    reading l (some m) p = l := by simp [reading, h]

theorem q57_unknown_intent_literal {M : Type} (l : M) (p : M → Bool) : reading l none p = l := rfl

end Usul.Kulliyyat
