import Usul.Signature

/-!
# Qawāʿid kernel, first rules (roadmap §3 M3)

Each rule names its source locator; the statement is the formal reading.
-/

namespace Usul.Qawaid

/-! ## *al-yaqīn lā yazūl bi'l-shakk* — grade monotonicity -/

/-- A held judgement with its epistemic grade. -/
structure Held (V : Type) where
  value : V
  grade : Grade

/-- A challenger displaces the incumbent only at equal or higher grade. -/
def update {V : Type} (cur ev : Held V) : Held V :=
  if cur.grade ≤ ev.grade then ev else cur

theorem update_grade_mono {V : Type} (cur ev : Held V) : cur.grade ≤ (update cur ev).grade := by
  unfold update; split
  · assumption
  · exact Nat.le_refl _

/-- Certainty is not removed by doubt. -/
theorem yaqin_la_yazul_bish_shakk {V : Type} (cur ev : Held V)
    (hy : cur.grade.IsYaqin) (hs : ev.grade = .shakk) : update cur ev = cur := by
  have : ¬ cur.grade ≤ ev.grade := by
    rw [hs]; revert hy; cases cur.grade <;> decide
  simp [update, this]

/-! ## *mā lā yatimm al-wājib illā bihi fa-huwa wājib* ∧ *lā wājib maʿa ʿajz* -/

section Closure
variable {Act : Type} (needs : Act → Act → Prop) (base : Act → Prop)

/-- Obligation closed under necessary means. -/
inductive Wajib : Act → Prop
  | base {a} : base a → Wajib a
  | means {a b} : Wajib a → needs a b → Wajib b

/-- Joint consistency: if every base obligation is within capacity, and the necessary
means of a feasible act are feasible, the closure never obliges the impossible. -/
theorem closure_respects_capacity (can : Act → Prop)
    (hbase : ∀ a, base a → can a) (hmeans : ∀ a b, can a → needs a b → can b) :
    ∀ a, Wajib needs base a → can a := by
  intro a h
  induction h with
  | base hb => exact hbase _ hb
  | means _ hn ih => exact hmeans _ _ ih hn

end Closure

/-! ## *al-ḍarūra tubīḥ al-maḥẓūrāt* + *tuqaddar bi-qadarihā* -/

/-- An amount `taken` of a prohibited thing under need `need`: lifted only up to the need. -/
def daruraPermits (need taken : Nat) : Prop := taken ≤ need

instance (need taken : Nat) : Decidable (daruraPermits need taken) :=
  inferInstanceAs (Decidable (taken ≤ need))

theorem darura_bounded {need taken : Nat} (h : daruraPermits need taken) : taken ≤ need := h

theorem no_darura_no_permission {taken : Nat} (h : daruraPermits 0 taken) : taken = 0 :=
  Nat.le_zero.mp h

end Usul.Qawaid
