/-!
# Ḥukm taklīfī (roadmap §2.1, M2)

Source: Ibn ʿUthaymīn, *al-Uṣūl min ʿIlm al-Uṣūl* — the ḥukm is
«ما اقتضاه خطاب الشرع المتعلق بأفعال المكلفين من طلب، أو تخيير، أو وضع»
(`src:shamela-9942/v01:p010`). The taklīfī part is the five-way partition below.

The partition is read as a *valence* scale, and the status of an act's omission is
given by the involution `σ` (*al-amr bi'l-shayʾ nahy ʿan ḍiddih*).
-/

namespace Usul

/-- The five taklīfī statuses. -/
inductive Hukm where
  | wajib    -- W  obligatory
  | mandub   -- N  recommended
  | mubah    -- M  permitted
  | makruh   -- K  disliked
  | haram    -- Ḥ  forbidden
  deriving DecidableEq, Repr, Inhabited

namespace Hukm

/-- Valence: Ḥ < K < M < N < W. -/
def valence : Hukm → Nat
  | haram => 0 | makruh => 1 | mubah => 2 | mandub => 3 | wajib => 4

instance : LE Hukm := ⟨fun a b => a.valence ≤ b.valence⟩
instance (a b : Hukm) : Decidable (a ≤ b) := inferInstanceAs (Decidable (a.valence ≤ b.valence))

theorem valence_injective {a b : Hukm} (h : a.valence = b.valence) : a = b := by
  cases a <;> cases b <;> simp_all [valence]

theorem valence_le_four (a : Hukm) : a.valence ≤ 4 := by cases a <;> decide

/-- Status of the omission (*tark*) of an act with status `h`. -/
def σ : Hukm → Hukm
  | wajib => haram | mandub => makruh | mubah => mubah | makruh => mandub | haram => wajib

@[simp] theorem σ_σ (h : Hukm) : σ (σ h) = h := by cases h <;> rfl

theorem σ_involutive : ∀ h, σ (σ h) = h := σ_σ

theorem σ_valence (h : Hukm) : (σ h).valence = 4 - h.valence := by cases h <;> rfl

theorem σ_antitone {a b : Hukm} (h : a ≤ b) : σ b ≤ σ a := by
  show (σ b).valence ≤ (σ a).valence
  have := valence_le_four b
  simp only [σ_valence]; exact Nat.sub_le_sub_left h 4

/-- *Al-amr bi'l-shayʾ nahy ʿan ḍiddih*: commanding an act forbids its omission. -/
theorem amr_nahy_didd {h : Hukm} (hw : h = wajib) : σ h = haram := by subst hw; rfl

/-- The only fixed point of `σ` is ibāḥa: no other status is indifferent to omission. -/
theorem σ_fixed_iff (h : Hukm) : σ h = h ↔ h = mubah := by cases h <;> decide

/-! ## Ṭalab / takhyīr: the definition's three-way split, proved exhaustive and disjoint -/

/-- Demand to do, demand to refrain, or choice (*takhyīr*). -/
inductive Mode where
  | talabFil | talabTark | takhyir
  deriving DecidableEq, Repr

def mode : Hukm → Mode
  | wajib | mandub => .talabFil
  | haram | makruh => .talabTark
  | mubah => .takhyir

/-- Binding (*ilzām*) vs preferential (*afḍaliyya*) demand. -/
def binding : Hukm → Bool
  | wajib | haram => true
  | _ => false

/-- The pair (mode, binding) determines the status: the partition is faithful. -/
theorem mode_binding_injective (a b : Hukm)
    (hm : a.mode = b.mode) (hb : a.binding = b.binding) : a = b := by
  cases a <;> cases b <;> simp_all [mode, binding]

theorem σ_swaps_mode (h : Hukm) :
    (σ h).mode = match h.mode with
      | .talabFil => .talabTark | .talabTark => .talabFil | .takhyir => .takhyir := by
  cases h <;> rfl

theorem σ_preserves_binding (h : Hukm) : (σ h).binding = h.binding := by cases h <;> rfl

end Hukm
end Usul
