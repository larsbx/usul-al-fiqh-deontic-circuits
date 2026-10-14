/-!
# Abstract argumentation core (roadmap §2.3, M1)

Dung-style semantics over an arbitrary attack relation, with sets as predicates.
Results: the characteristic function is monotone; it preserves admissibility; the
grounded approximants `F^[n] ∅` form an increasing chain of admissible sets; and
every complete extension contains every approximant (grounded ⊆ complete); for finitary
frameworks their union, `grounded`, is the unique least complete extension; and over finite
frameworks every admissible set extends to a preferred one (the fundamental lemma).
-/

namespace Usul.Dung

variable {α : Type} (att : α → α → Prop)

abbrev ASet (α : Type) := α → Prop

def Subset (S T : ASet α) : Prop := ∀ a, S a → T a
local infix:50 " ⊆ₐ " => Subset

def ConflictFree (S : ASet α) : Prop := ∀ a b, S a → S b → ¬ att a b

/-- `S` defends `a`: every attacker of `a` is attacked by some member of `S`. -/
def Defends (S : ASet α) (a : α) : Prop := ∀ b, att b a → ∃ c, S c ∧ att c b

/-- Characteristic function. -/
def F (S : ASet α) : ASet α := Defends att S

def Admissible (S : ASet α) : Prop := ConflictFree att S ∧ S ⊆ₐ F att S

def Complete (S : ASet α) : Prop := Admissible att S ∧ F att S ⊆ₐ S

/-- `n`-th grounded approximant `F^[n] ∅`. -/
def approx : Nat → ASet α
  | 0 => fun _ => False
  | n + 1 => F att (approx n)

variable {att}

theorem F_mono {S T : ASet α} (h : S ⊆ₐ T) : F att S ⊆ₐ F att T :=
  fun _ hd b hb => let ⟨c, hc, hcb⟩ := hd b hb; ⟨c, h c hc, hcb⟩

/-- Fundamental lemma: if `S` is admissible then so is `F S`. -/
theorem admissible_F {S : ASet α} (h : Admissible att S) : Admissible att (F att S) := by
  refine ⟨?_, F_mono h.2⟩
  intro a b ha hb hab
  -- `b` is defended by `S`, so some `c ∈ S` attacks `a`;
  -- `a` is defended by `S`, so some `d ∈ S` attacks `c`; `S` is conflict-free.
  obtain ⟨c, hc, hca⟩ := hb a hab
  obtain ⟨d, hd, hdc⟩ := ha c hca
  exact h.1 d c hd hc hdc

theorem admissible_empty : Admissible att (fun _ : α => False) :=
  ⟨fun _ _ h => h.elim, fun _ h => h.elim⟩

theorem approx_admissible : ∀ n, Admissible att (approx att n)
  | 0 => admissible_empty
  | n + 1 => admissible_F (approx_admissible n)

theorem approx_conflictFree (n : Nat) : ConflictFree att (approx att n) :=
  (approx_admissible n).1

theorem approx_succ (n : Nat) : approx att n ⊆ₐ approx att (n + 1) :=
  (approx_admissible n).2

/-- Every complete extension contains every grounded approximant. -/
theorem approx_sub_complete {E : ASet α} (hE : Complete att E) :
    ∀ n, approx att n ⊆ₐ E
  | 0 => fun _ h => h.elim
  | n + 1 => fun a ha => hE.2 a (F_mono (approx_sub_complete hE n) a ha)

/-- Unattacked arguments are in the first approximant (the uncontested core). -/
theorem unattacked_in_approx_one {a : α} (h : ∀ b, ¬ att b a) : approx att 1 a :=
  fun b hb => (h b hb).elim

/-! ## The grounded extension

The union of the approximants. For finitary frameworks (finitely many attackers per argument,
as every framework the bank builds) it is complete, and it is contained in every complete
extension: the least complete extension, hence unique (roadmap M1). -/

variable (att) in
/-- The grounded extension: what some approximant `F^[n] ∅` contains. -/
def grounded : ASet α := fun a => ∃ n, approx att n a

variable (att) in
/-- Every argument has finitely many attackers, listed by some `l`. -/
def Finitary : Prop := ∀ a, ∃ l : List α, ∀ b, att b a → b ∈ l

theorem approx_mono {m n : Nat} (h : m ≤ n) : approx att m ⊆ₐ approx att n := by
  induction h with
  | refl => exact fun _ h => h
  | step _ ih => exact fun a ha => approx_succ _ a (ih a ha)

theorem approx_sub_grounded (n : Nat) : approx att n ⊆ₐ grounded att := fun _ ha => ⟨n, ha⟩

theorem grounded_conflictFree : ConflictFree att (grounded att) := by
  rintro a b ⟨m, ha⟩ ⟨n, hb⟩
  exact approx_conflictFree (Nat.max m n) a b (approx_mono (Nat.le_max_left m n) a ha)
    (approx_mono (Nat.le_max_right m n) b hb)

theorem grounded_sub_F : grounded att ⊆ₐ F att (grounded att) := by
  rintro a ⟨n, ha⟩
  exact F_mono (approx_sub_grounded n) a ((approx_admissible n).2 a ha)

theorem grounded_admissible : Admissible att (grounded att) :=
  ⟨grounded_conflictFree, grounded_sub_F⟩

/-- Finitely many attackers, each countered within some approximant: one approximant counters all. -/
theorem countered_by_one_approx {a : α} :
    ∀ l : List α, (∀ b, b ∈ l → att b a → ∃ c, grounded att c ∧ att c b) →
      ∃ N, ∀ b, b ∈ l → att b a → ∃ c, approx att N c ∧ att c b
  | [], _ => ⟨0, fun _ hb => absurd hb (List.not_mem_nil)⟩
  | b₀ :: l, h => by
    obtain ⟨N, hN⟩ := countered_by_one_approx l (fun b hb => h b (List.mem_cons_of_mem _ hb))
    by_cases h₀ : att b₀ a
    · obtain ⟨c, ⟨m, hc⟩, hcb⟩ := h b₀ List.mem_cons_self h₀
      refine ⟨Nat.max m N, fun b hb hba => ?_⟩
      rcases List.mem_cons.mp hb with rfl | hb
      · exact ⟨c, approx_mono (Nat.le_max_left m N) c hc, hcb⟩
      · obtain ⟨c', hc', hcb'⟩ := hN b hb hba
        exact ⟨c', approx_mono (Nat.le_max_right m N) c' hc', hcb'⟩
    · refine ⟨N, fun b hb hba => ?_⟩
      rcases List.mem_cons.mp hb with rfl | hb
      · exact absurd hba h₀
      · exact hN b hb hba

theorem F_grounded_sub (fin : Finitary att) : F att (grounded att) ⊆ₐ grounded att := by
  intro a ha
  obtain ⟨l, hl⟩ := fin a
  obtain ⟨N, hN⟩ := countered_by_one_approx l (fun b _ hba => ha b hba)
  exact ⟨N + 1, fun b hba => hN b (hl b hba) hba⟩

theorem grounded_complete (fin : Finitary att) : Complete att (grounded att) :=
  ⟨grounded_admissible, F_grounded_sub fin⟩

theorem grounded_sub_complete {E : ASet α} (hE : Complete att E) : grounded att ⊆ₐ E := by
  rintro a ⟨n, ha⟩
  exact approx_sub_complete hE n a ha

/-- Uniqueness: any least complete extension coincides with the grounded one. -/
theorem grounded_unique (fin : Finitary att) {G : ASet α} (hG : Complete att G)
    (least : ∀ E, Complete att E → G ⊆ₐ E) : G ⊆ₐ grounded att ∧ grounded att ⊆ₐ G :=
  ⟨least _ (grounded_complete fin), grounded_sub_complete hG⟩

/-! ## Preferred extensions and the fundamental lemma

A preferred extension is a maximal admissible set. Over a finite framework (one whose arguments are
all listed by some `U`) every admissible set is contained in a preferred one (Dung's fundamental
lemma; roadmap M1): enlarge it while it is not maximal, each step leaving fewer of `U` outside. -/

variable (att) in
def Preferred (S : ASet α) : Prop :=
  Admissible att S ∧ ∀ T, Admissible att T → S ⊆ₐ T → T ⊆ₐ S

/-- Counting the strictly larger: if `q` implies `p` everywhere and some member satisfies `p` but
not `q`, fewer members satisfy `q`. -/
theorem countP_lt_of_strict {p q : α → Bool} (hpq : ∀ x, q x = true → p x = true) {a : α}
    (hpa : p a = true) (hqa : q a = false) : ∀ {l : List α}, a ∈ l → l.countP q < l.countP p
  | x :: l, ha => by
    have mono : l.countP q ≤ l.countP p := List.countP_mono_left (fun x _ h => hpq x h)
    rw [List.countP_cons, List.countP_cons]
    rcases List.mem_cons.mp ha with rfl | ha
    · simp [hpa, hqa]; omega
    · have ih := countP_lt_of_strict hpq hpa hqa ha
      cases hq : q x
      · cases hp : p x <;> simp <;> omega
      · simp [hpq x hq]; omega

open Classical in
theorem admissible_sub_preferred (U : List α) (hU : ∀ a, a ∈ U) :
    ∀ (n : Nat) (S : ASet α), U.countP (fun a => !decide (S a)) = n → Admissible att S →
      ∃ P, Preferred att P ∧ S ⊆ₐ P := by
  intro n
  induction n using Nat.strongRecOn with
  | _ n ih =>
    intro S hn hS
    by_cases hmax : ∀ T, Admissible att T → S ⊆ₐ T → T ⊆ₐ S
    · exact ⟨S, ⟨hS, hmax⟩, fun _ h => h⟩
    · obtain ⟨T, hT⟩ := Classical.not_forall.mp hmax
      obtain ⟨hTadm, hST⟩ := Classical.not_imp.mp hT |>.imp_right Classical.not_imp.mp
        |> fun ⟨h1, h2⟩ => (⟨h1, h2.1⟩ : Admissible att T ∧ S ⊆ₐ T)
      have hTS : ¬ T ⊆ₐ S := (Classical.not_imp.mp (Classical.not_imp.mp hT).2).2
      obtain ⟨a, ha⟩ := Classical.not_forall.mp hTS
      obtain ⟨hTa, hSa⟩ := Classical.not_imp.mp ha
      have lt : U.countP (fun a => !decide (T a)) < U.countP (fun a => !decide (S a)) :=
        countP_lt_of_strict (p := fun a => !decide (S a)) (q := fun a => !decide (T a))
          (fun x hx => by
            simp only [Bool.not_eq_true', decide_eq_false_iff_not] at hx ⊢
            exact fun h => hx (hST x h))
          (by simpa using hSa) (by simpa using hTa) (hU a)
      obtain ⟨P, hP, hTP⟩ := ih _ (hn ▸ lt) T rfl hTadm
      exact ⟨P, hP, fun x hx => hTP x (hST x hx)⟩

/-- Dung's fundamental lemma over a finite framework: every admissible set extends to a preferred one;
in particular (from `∅`) a preferred extension exists. -/
theorem exists_preferred_superset (U : List α) (hU : ∀ a, a ∈ U) {S : ASet α}
    (hS : Admissible att S) : ∃ P, Preferred att P ∧ S ⊆ₐ P :=
  admissible_sub_preferred U hU _ S rfl hS

/-- A finite framework has a preferred extension (two riwāyas in mutual attack: one per side). -/
theorem exists_preferred (U : List α) (hU : ∀ a, a ∈ U) : ∃ P, Preferred att P :=
  (exists_preferred_superset U hU admissible_empty).imp fun _ h => h.1

variable (att) in
/-- Stable extensions attack every argument outside the conflict-free set.
They need not exist, even on finite frameworks. -/
def Stable (S : ASet α) : Prop :=
  ConflictFree att S ∧ ∀ a, ¬ S a → ∃ b, S b ∧ att b a

theorem stable_admissible {S : ASet α} (h : Stable att S) : Admissible att S := by
  refine ⟨h.1, ?_⟩
  intro a ha b hba
  have hb : ¬ S b := fun hb => h.1 b a hb ha hba
  exact h.2 b hb

/-- Stability implies preferredness, not conversely; no existence assumption is hidden. -/
theorem stable_preferred {S : ASet α} (h : Stable att S) : Preferred att S := by
  refine ⟨stable_admissible h, ?_⟩
  intro T hT hST a ha
  by_cases hSa : S a
  · exact hSa
  · obtain ⟨b, hb, hba⟩ := h.2 a hSa
    exact False.elim (hT.1 b a (hST b hb) ha hba)

end Usul.Dung

