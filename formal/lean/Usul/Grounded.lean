import Usul.Dung

/-!
# Executable grounded extension (differential-testing bridge)

A computable version of `Dung.approx` over finite AFs on `0..n-1`. The bridge
lemma `defended_iff` identifies one step with the characteristic function `F`,
so the executable agrees with the proved semantics step by step.
-/

namespace Usul.Grounded

/-- `a` is defended by `S`: every attacker `b` of `a` is attacked from `S`. -/
def defended (att : List (Nat × Nat)) (S : List Nat) (a : Nat) : Bool :=
  att.all fun e => e.2 != a || att.any fun f => f.2 == e.1 && S.contains f.1

def step (n : Nat) (att : List (Nat × Nat)) (S : List Nat) : List Nat :=
  (List.range n).filter (defended att S)

/-- `n + 1` steps from `∅` suffice: the chain grows strictly until it is stable. -/
def grounded (n : Nat) (att : List (Nat × Nat)) : List Nat :=
  (List.range (n + 1)).foldl (fun S _ => step n att S) []

theorem defended_iff (att : List (Nat × Nat)) (S : List Nat) (a : Nat) :
    defended att S a = true ↔
      Dung.Defends (fun b x => (b, x) ∈ att) (fun c => c ∈ S) a := by
  simp only [defended, List.all_eq_true, List.any_eq_true, Bool.or_eq_true, bne_iff_ne, ne_eq,
    Bool.and_eq_true, beq_iff_eq, List.contains_iff_mem, Dung.Defends]
  constructor
  · intro h b hb
    rcases h (b, a) hb with h | ⟨f, hf, hfb, hfS⟩
    · exact absurd rfl h
    · exact ⟨f.1, hfS, by simp only at hfb; rw [← hfb]; exact hf⟩
  · intro h e he
    by_cases hea : e.2 = a
    · right
      obtain ⟨c, hc, hcb⟩ := h e.1 (by simpa [← hea] using he)
      exact ⟨(c, e.1), hcb, rfl, hc⟩
    · exact Or.inl hea

/-- One executable step is the characteristic function restricted to `0..n-1`. -/
theorem mem_step_iff (n : Nat) (att : List (Nat × Nat)) (S : List Nat) (a : Nat) :
    a ∈ step n att S ↔ a < n ∧ Dung.F (fun b x => (b, x) ∈ att) (fun c => c ∈ S) a := by
  simp [step, List.mem_filter, List.mem_range, defended_iff, Dung.F]

end Usul.Grounded
