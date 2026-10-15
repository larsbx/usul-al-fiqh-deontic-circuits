import Usul.Grounded

/-!
# End-to-end correctness of the finite grounded runner

`grounded` already executes `n + 1` characteristic-function steps. The proof below
establishes that this bound suffices, then connects its output to the least complete
Dung extension on `Fin n`. The semantic bridge requires well-formed edges; silently
discarding an out-of-range attacker would otherwise change the framework.
-/

namespace Usul.Grounded

def iterate (n : Nat) (att : List (Nat × Nat)) : Nat → List Nat
  | 0 => []
  | k + 1 => step n att (iterate n att k)

theorem grounded_eq_iterate (n : Nat) (att : List (Nat × Nat)) :
    grounded n att = iterate n att (n + 1) := by
  have aux : ∀ k, (List.range k).foldl (fun S _ => step n att S) [] = iterate n att k := by
    intro k
    induction k with
    | zero => rfl
    | succ k ih => simp [List.range_succ, List.foldl_append, ih, iterate]
  exact aux (n + 1)

theorem step_mono (n : Nat) (att : List (Nat × Nat)) {S T : List Nat}
    (h : S ⊆ T) : List.Sublist (step n att S) (step n att T) := by
  have hf : (step n att S).filter (defended att T) = step n att S := by
    apply List.filter_eq_self.mpr
    intro a ha
    have hd := (mem_step_iff n att S a).1 ha
    exact (defended_iff att T a).2 (Dung.F_mono h a hd.2)
  rw [← hf]
  exact List.filter_sublist.filter (defended att T)

theorem iterate_increasing (n : Nat) (att : List (Nat × Nat)) :
    ∀ k, List.Sublist (iterate n att k) (iterate n att (k + 1))
  | 0 => List.nil_sublist _
  | k + 1 => step_mono n att (iterate_increasing n att k).subset

theorem iterate_bounded (n : Nat) (att : List (Nat × Nat)) (k : Nat) :
    (iterate n att k).length ≤ n := by
  cases k with
  | zero => simp [iterate]
  | succ k => exact Nat.le_trans List.filter_sublist.length_le (by simp)

/-- Before stability, each step adds a new vertex. The chain cannot grow past `n`. -/
theorem stable_or_growing (n : Nat) (att : List (Nat × Nat)) : ∀ k,
    iterate n att (k + 1) = iterate n att k ∨ k + 1 ≤ (iterate n att (k + 1)).length := by
  intro k
  induction k with
  | zero =>
    by_cases h : iterate n att 1 = iterate n att 0
    · exact .inl h
    · right
      have hn : iterate n att 1 ≠ [] := h
      exact List.length_pos_iff.mpr hn
  | succ k ih =>
    rcases ih with hs | hg
    · left; exact congrArg (step n att) hs
    · by_cases hs : iterate n att (k + 2) = iterate n att (k + 1)
      · exact .inl hs
      · right
        change k + 2 ≤ (iterate n att (k + 2)).length
        have hlt : (iterate n att (k + 1)).length < (iterate n att (k + 2)).length := by
          apply Nat.lt_of_not_ge
          intro hle
          exact hs ((iterate_increasing n att (k + 1)).eq_of_length_le hle).symm
        omega

theorem iterate_stable (n : Nat) (att : List (Nat × Nat)) :
    iterate n att (n + 1) = iterate n att n := by
  rcases stable_or_growing n att n with h | h
  · exact h
  · have hb := iterate_bounded n att (n + 1); omega

theorem grounded_fixed (n : Nat) (att : List (Nat × Nat)) :
    step n att (grounded n att) = grounded n att := by
  rw [grounded_eq_iterate]
  have h := congrArg (step n att) (iterate_stable n att)
  exact h

def WellFormed (n : Nat) (att : List (Nat × Nat)) : Prop :=
  ∀ e ∈ att, e.1 < n ∧ e.2 < n

def wellFormed (n : Nat) (att : List (Nat × Nat)) : Bool :=
  att.all fun e => e.1 < n && e.2 < n

theorem wellFormed_iff (n : Nat) (att : List (Nat × Nat)) :
    wellFormed n att = true ↔ WellFormed n att := by
  simp [wellFormed, WellFormed, List.all_eq_true, Bool.and_eq_true]

/-- The checked public boundary rejects malformed edges, rather than dropping them. -/
def checkedGrounded (n : Nat) (att : List (Nat × Nat)) : Option (List Nat) :=
  if wellFormed n att then some (grounded n att) else none

theorem checkedGrounded_some_iff (n : Nat) (att : List (Nat × Nat)) (S : List Nat) :
    checkedGrounded n att = some S ↔ WellFormed n att ∧ grounded n att = S := by
  cases hw : wellFormed n att <;> simp [checkedGrounded, hw, ← wellFormed_iff n att]

theorem checkedGrounded_rejects {n : Nat} {att : List (Nat × Nat)}
    (bad : ¬ WellFormed n att) : checkedGrounded n att = none := by
  have hw : wellFormed n att = false := by
    cases h : wellFormed n att with
    | false => rfl
    | true => exact (bad ((wellFormed_iff n att).1 h)).elim
  simp [checkedGrounded, hw]

def attack (att : List (Nat × Nat)) (a b : Fin n) : Prop := (a.val, b.val) ∈ att

def extension (S : List Nat) : Dung.ASet (Fin n) := fun a => a.val ∈ S

theorem finite_step_iff {n : Nat} {att : List (Nat × Nat)} (wf : WellFormed n att)
    (S : List Nat) (a : Fin n) :
    extension (step n att S) a ↔ Dung.F (attack att) (extension S) a := by
  rw [extension, mem_step_iff]
  constructor
  · rintro ⟨_, hd⟩ b hb
    obtain ⟨c, hc, hcb⟩ := hd b.val hb
    exact ⟨⟨c, (wf (c, b.val) hcb).1⟩, hc, hcb⟩
  · intro hd
    refine ⟨a.isLt, ?_⟩
    intro b hb
    obtain ⟨c, hc, hcb⟩ := hd ⟨b, (wf (b, a.val) hb).1⟩ hb
    exact ⟨c.val, hc, hcb⟩

/-- Every iteration agrees with the abstract semantics, not only the fixture cases. -/
theorem iterate_iff_approx {n : Nat} {att : List (Nat × Nat)} (wf : WellFormed n att) :
    ∀ (k : Nat) (a : Fin n), extension (iterate n att k) a ↔ Dung.approx (attack att) k a := by
  intro k
  induction k with
  | zero => intro a; simp [iterate, extension, Dung.approx]
  | succ k ih =>
    intro a
    rw [iterate, finite_step_iff wf]
    change (∀ b, attack att b a → ∃ c, extension (iterate n att k) c ∧ attack att c b) ↔ _
    simp only [ih, Dung.approx, Dung.F, Dung.Defends]

theorem grounded_complete {n : Nat} {att : List (Nat × Nat)} (wf : WellFormed n att) :
    Dung.Complete (attack (n := n) att) (extension (grounded n att)) := by
  have he : extension (n := n) (grounded n att) = Dung.approx (attack att) (n + 1) := by
    funext a
    exact propext (by rw [grounded_eq_iterate]; exact iterate_iff_approx wf (n + 1) a)
  refine ⟨?_, ?_⟩
  · rw [he]; exact Dung.approx_admissible (n + 1)
  intro a ha
  have hs := (finite_step_iff wf (grounded n att) a).2 ha
  rwa [grounded_fixed] at hs

theorem grounded_least {n : Nat} {att : List (Nat × Nat)} (wf : WellFormed n att)
    {E : Dung.ASet (Fin n)} (hc : Dung.Complete (attack att) E) :
    Dung.Subset (extension (grounded n att)) E := by
  intro a ha
  have hd : Dung.approx (attack att) (n + 1) a :=
    (iterate_iff_approx wf (n + 1) a).1 (by rwa [← grounded_eq_iterate])
  exact Dung.approx_sub_complete hc (n + 1) a hd

theorem grounded_conflictFree {n : Nat} {att : List (Nat × Nat)} (wf : WellFormed n att) :
    Dung.ConflictFree (attack (n := n) att) (extension (grounded n att)) :=
  (grounded_complete wf).1.1

/-- The least complete extension exists and is unique on every well-formed finite AF. -/
theorem grounded_exists_unique {n : Nat} {att : List (Nat × Nat)} (wf : WellFormed n att) :
    ∃ E : Dung.ASet (Fin n),
      (Dung.Complete (attack att) E ∧
        ∀ T, Dung.Complete (attack att) T → Dung.Subset E T) ∧
      ∀ T, (Dung.Complete (attack att) T ∧
        ∀ U, Dung.Complete (attack att) U → Dung.Subset T U) → T = E := by
  refine ⟨extension (grounded n att), ⟨grounded_complete wf, fun _ hc => grounded_least wf hc⟩, ?_⟩
  intro T ht
  funext a
  exact propext ⟨fun ha => ht.2 _ (grounded_complete wf) a ha,
    fun ha => grounded_least wf ht.1 a ha⟩

theorem checkedGrounded_complete {n : Nat} {att : List (Nat × Nat)} {S : List Nat}
    (ok : checkedGrounded n att = some S) :
    Dung.Complete (attack (n := n) att) (extension S) := by
  obtain ⟨wf, rfl⟩ := (checkedGrounded_some_iff n att S).1 ok
  exact grounded_complete wf

theorem checkedGrounded_least {n : Nat} {att : List (Nat × Nat)} {S : List Nat}
    (ok : checkedGrounded n att = some S) {E : Dung.ASet (Fin n)}
    (hc : Dung.Complete (attack att) E) : Dung.Subset (extension S) E := by
  obtain ⟨wf, rfl⟩ := (checkedGrounded_some_iff n att S).1 ok
  exact grounded_least wf hc

end Usul.Grounded
