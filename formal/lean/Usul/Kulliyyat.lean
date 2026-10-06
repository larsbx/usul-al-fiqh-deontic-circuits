import Usul.Schema

/-!
# al-Saʿdī's general maxims (kulliyyāt) — formal readings (roadmap M3)

The rules that need small models of custom (Q9, Q48), intent (Q5, Q57), utterance (Q29),
cause and condition in time (Q17, Q39), and the bookkeeping of causes, choices and
acts of worship (Q15, Q31, Q34, Q41, Q50). Each reading is also proved an instance of a
schema in `Usul.Schema`, which fixes the structure that must survive when the rule is applied
outside the bāb it was stated for. Rule numbers as in
`corpus/proposals/sadi_qawaid.json`; every reading is a candidate until reviewed.
-/

namespace Usul.Kulliyyat

open Usul Usul.Schema

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

/-- Q9 is S2: the law's measure, falling back to custom. -/
theorem q09_is_priority {α : Type} (l : Option α) (c : α) : measure l c = resolveD [l] c := by
  cases l <;> rfl

/-! ## Q15 — no harm and no reciprocal harm -/

/-- Outside prescribed retaliation, inflicting harm is permitted only if it is none, whatever
harm one has received (the second half: *wa-lā ḍirār*). -/
def mayInflict (_received harm : Nat) : Bool := harm == 0

theorem q15_no_harm (r h : Nat) : mayInflict r h = true ↔ h = 0 := by simp [mayInflict]
theorem q15_no_reciprocal_harm (r r' h : Nat) : mayInflict r h = mayInflict r' h := rfl

/-- Q15 is S1: what may be inflicted ignores what was received. -/
theorem q15_ignores_received : Ignores (fun h r => mayInflict r h) := fun _ _ _ => rfl

/-! ## Q17 — whoever hastens a thing before its time is punished by being deprived of it -/

def obtains (entitled hastened : Bool) : Bool := entitled && !hastened

theorem q17_hastening_deprives (e : Bool) : obtains e true = false := by cases e <;> rfl
theorem q17_never_beyond_entitlement (e h : Bool) (hb : obtains e h = true) : e = true := by
  cases e <;> simp_all [obtains]

/-- Q17 is S3: entitlement is the condition, unlawful hastening the impediment (the heir who
kills his legator, the one who marries in the ʿidda, …). -/
theorem q17_is_gate (e h : Bool) :
    obtains e h = true ↔ (Sadi.Gate.ofBools [Prod.fst] [Prod.snd]).Holds (e, h) := by
  rw [Sadi.Gate.holds_ofBools]; cases e <;> cases h <;> simp [obtains]

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

/-- Q29 is S3: an utterance is a gate whose conditions are its base and its qualifiers, so
it inherits the gate algebra (`meet_narrows`, `holds_comap`). -/
theorem q29_is_gate {α : Type} (u : Utterance α) (x : α) :
    u.meaning x = true ↔ (Sadi.Gate.ofBools (u.base :: u.qualifiers) []).Holds x := by
  rw [Sadi.Gate.holds_ofBools]; simp [Utterance.meaning]

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

/-- Q31: rulings from a union of causes are the join of their rulings. -/
theorem q31_join {C R : Type} (present : C → Bool) (effect : C → R → Bool) (cs ds : List C) (r : R) :
    rulings present effect (cs ++ ds) r = (rulings present effect cs r || rulings present effect ds r) := by
  simp [rulings, List.any_append]

/-- Q31: more causes present, never fewer rulings. -/
theorem q31_monotone {C R : Type} {present present' : C → Bool} (effect : C → R → Bool)
    (h : ∀ c, present c = true → present' c = true) (cs : List C) (r : R)
    (hr : rulings present effect cs r = true) : rulings present' effect cs r = true := by
  simp only [rulings, List.any_eq_true, Bool.and_eq_true] at hr ⊢
  obtain ⟨c, hc, hp, he⟩ := hr
  exact ⟨c, hc, h c hp, he⟩

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

/-- Q39 ignores the condition's time (S1), and only the order of performance and cause
matters: shifting the calendar changes nothing. -/
theorem q39_ignores_condition (t s : Nat) : Ignores (fun (_ : Unit) c => timelyPerformance t s c) :=
  fun _ _ _ => rfl

theorem q39_shift_invariant (t s c k : Nat) :
    timelyPerformance (t + k) (s + k) (c + k) = timelyPerformance t s c := by
  simp [timelyPerformance]

/-! ## Q41 — two acts of worship of one kind and one purpose merge into one performance -/

/-- An owed act of worship: its kind, its purpose, and the occasion that made it owed
(two janābas, two missed prayers of one name, …). -/
structure Act (K P O : Type) where
  kind : K
  purpose : P
  occasion : O
  deriving DecidableEq, Repr

def discharges {K P O : Type} [DecidableEq K] [DecidableEq P] (done owed : Act K P O) : Bool :=
  done.kind == owed.kind && done.purpose == owed.purpose

theorem q41_one_performance {K P O : Type} [DecidableEq K] [DecidableEq P] (a : Act K P O)
    (owed : List (Act K P O)) (h : ∀ b ∈ owed, b.kind = a.kind ∧ b.purpose = a.purpose) :
    owed.all (discharges a) = true := by
  simp only [List.all_eq_true]
  intro b hb
  obtain ⟨hk, hp⟩ := h b hb
  simp [discharges, hk, hp]

theorem q41_distinct_purposes_stay_apart {K P O : Type} [DecidableEq K] [DecidableEq P]
    (a b : Act K P O) (h : a.purpose ≠ b.purpose) : discharges a b = false := by
  simp [discharges, h]

section Merge

variable {K P O : Type} [DecidableEq K] [DecidableEq P]

/-- The merge relation of Q41: same kind, same purpose, any occasion. -/
abbrev Merges (a b : Act K P O) : Prop := discharges a b = true

theorem q41_merges_refl (a : Act K P O) : Merges a a := by simp [Merges, discharges]

theorem q41_merges_symm {a b : Act K P O} (h : Merges a b) : Merges b a := by
  simp only [Merges, discharges, Bool.and_eq_true, beq_iff_eq] at h ⊢
  exact ⟨h.1.symm, h.2.symm⟩

theorem q41_merges_trans {a b c : Act K P O} (h : Merges a b) (h' : Merges b c) : Merges a c := by
  simp only [Merges, discharges, Bool.and_eq_true, beq_iff_eq] at h h' ⊢
  exact ⟨h.1.trans h'.1, h.2.trans h'.2⟩

/-- Q41 is S7: one performance per merge class discharges everything owed, never needing
more performances than owed acts. -/
theorem q41_representatives (owed : List (Act K P O)) :
    Covers Merges (reps Merges owed) owed ∧ (reps Merges owed).length ≤ owed.length ∧
      ∀ d ∈ reps Merges owed, d ∈ owed :=
  ⟨reps_covers q41_merges_refl owed, reps_length_le owed, reps_sub owed⟩

end Merge

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

/-- Q48 transported along the calendar: shifting every part by `k` preserves continuity. -/
theorem q48_shift_invariant (g k : Nat) : ∀ ts : List Nat,
    continuous g (ts.map (· + k)) = continuous g ts
  | [] => rfl
  | [_] => rfl
  | a :: b :: rest => by
    have ih := q48_shift_invariant g k (b :: rest)
    simp only [List.map] at ih ⊢
    simp only [continuous, ih, Nat.add_sub_add_right]

/-! ## Q50 — what is not established independently may be established as a dependent -/

def established (independentProof followsEstablished : Bool) : Bool :=
  independentProof || followsEstablished

theorem q50_dependent_suffices : established false true = true := rfl
theorem q50_independent_suffices (f : Bool) : established true f = true := by cases f <;> rfl
theorem q50_neither_fails : established false false = false := rfl

/-- Q50 is S4: the established are the closure of the independently proved under "follows". -/
def Established {α : Type} (follows : α → α → Prop) (proved : α → Prop) : α → Prop :=
  Closure follows proved

theorem q50_follower_established {α : Type} {follows : α → α → Prop} {proved : α → Prop} {a b : α}
    (ha : Established follows proved a) (h : follows a b) : Established follows proved b :=
  .step ha h

/-- Nothing is established from nothing: whatever holds of every proved thing and passes
along "follows" holds of everything established. -/
theorem q50_least {α : Type} {follows : α → α → Prop} {proved : α → Prop} (P : α → Prop)
    (hs : ∀ a, proved a → P a) (hc : ∀ a b, P a → follows a b → P b) :
    ∀ a, Established follows proved a → P a :=
  Closure.least P hs hc

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

/-- Q57 is S2: the intent if possible, falling back to the literal sense. -/
theorem q57_is_priority {M : Type} (l : M) (i : Option M) (p : M → Bool) :
    reading l i p = resolveD [i.bind fun m => if p m then some m else none] l := by
  cases i with
  | none => rfl
  | some m => cases h : p m <;> simp [reading, resolveD, first, h]

end Usul.Kulliyyat
