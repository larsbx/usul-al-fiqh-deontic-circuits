/-!
# Abstract argumentation core (roadmap §2.3, M1)

Dung-style semantics over an arbitrary attack relation, with sets as predicates.
Results: the characteristic function is monotone; it preserves admissibility; the
grounded approximants `F^[n] ∅` form an increasing chain of admissible sets; and
every complete extension contains every approximant (grounded ⊆ complete).
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

end Usul.Dung
