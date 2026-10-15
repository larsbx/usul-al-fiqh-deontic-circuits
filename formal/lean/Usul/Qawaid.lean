import Usul.Signature

/-!
# Qawāʿid kernel, first rules (roadmap §3 M3)

Each rule names its source locator; the statement is the formal reading.
-/

namespace Usul.Qawaid

/-! ## *al-yaqīn lā yazūl bi'l-shakk* — grade monotonicity -/

/-- A held judgement with its epistemic grade, and whether its preponderance is known on a dalīl
(meaningful for ẓann; IQ-21). -/
structure Held (V : Type) where
  value : V
  grade : Grade
  rujhanKnown : Bool

/-- The judgement is certain for acting (`Grade.YaqinFor`, IQ-21). -/
def Held.IsYaqin {V : Type} (h : Held V) : Prop := h.grade.YaqinFor h.rujhanKnown

/-- Tawaqquf (IQ-21 follow-up, human review): a ẓann whose preponderance is not known is no view.
Ibn Taymiyya (Majmūʿ v13 p119): «وحيث لا يعلم الرجحان فهو متوقف لا قول له». -/
def Held.Suspended {V : Type} (h : Held V) : Bool := h.grade == .zann && !h.rujhanKnown

/-- The strength a judgement counts at: a suspended ẓann counts as shakk, since for the one who
holds it neither side is known to outweigh the other. -/
def Held.strength {V : Type} (h : Held V) : Grade := if h.Suspended then .shakk else h.grade

/-- A challenger displaces the incumbent only at equal or higher strength; a suspended challenger,
being no view, displaces nothing. -/
def update {V : Type} (cur ev : Held V) : Held V :=
  if !ev.Suspended && decide (cur.strength ≤ ev.strength) then ev else cur

/-- The earlier, grade-only reading. -/
def updateByGrade {V : Type} (cur ev : Held V) : Held V :=
  if cur.grade ≤ ev.grade then ev else cur

theorem strength_of_not_suspended {V : Type} {h : Held V} (hs : h.Suspended = false) :
    h.strength = h.grade := by simp [Held.strength, hs]

/-- Conservative: where neither judgement is suspended, `update` is the grade-only reading. -/
theorem update_conservative {V : Type} (cur ev : Held V) (hc : cur.Suspended = false)
    (he : ev.Suspended = false) : update cur ev = updateByGrade cur ev := by
  simp [update, updateByGrade, he, strength_of_not_suspended hc, strength_of_not_suspended he]

/-- A suspended ẓann is inert as a challenger (S5): «لا قول له». -/
theorem suspended_inert {V : Type} (cur ev : Held V) (hs : ev.Suspended = true) :
    update cur ev = cur := by simp [update, hs]

/-- A suspended incumbent yields to any grounded judgement of at least shakk. -/
theorem suspended_yields {V : Type} (cur ev : Held V) (hc : cur.Suspended = true)
    (he : ev.Suspended = false) (hg : Grade.shakk ≤ ev.grade) : update cur ev = ev := by
  simp [update, Held.strength, hc, he, hg]

theorem update_strength_mono {V : Type} (cur ev : Held V) :
    cur.strength ≤ (update cur ev).strength := by
  unfold update; split
  · next h => simp only [Bool.and_eq_true, decide_eq_true_eq] at h; exact h.2
  · exact Nat.le_refl _

/-- Certainty is not removed by doubt. -/
theorem yaqin_la_yazul_bish_shakk {V : Type} (cur ev : Held V)
    (hy : cur.IsYaqin) (hs : ev.grade = .shakk) : update cur ev = cur := by
  have hn : cur.Suspended = false := by
    rcases hy with h | ⟨_, h⟩ <;> simp_all [Held.Suspended]
  have hg := Grade.YaqinFor.isYaqin hy
  have he : ev.Suspended = false := by simp [Held.Suspended, hs]
  have : ¬ cur.grade ≤ ev.grade := by
    rw [hs]; revert hg; cases cur.grade <;> decide
  simp [update, strength_of_not_suspended hn, strength_of_not_suspended he, he, this]

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
