/-!
# Ḥukm taklīfī (roadmap §2.1, M2)

Source: Ibn ʿUthaymīn, *al-Uṣūl min ʿIlm al-Uṣūl* — the ḥukm is
«ما اقتضاه خطاب الشرع المتعلق بأفعال المكلفين من طلب، أو تخيير، أو وضع»
(`src:shamela-9942/v01:p010`). The taklīfī part is the five-way partition below.

Each status is defined by what follows on doing the act (fiʿl) and on leaving it (tark)
(`src:shamela-9942/v01:p010`–`p011`):

| Status | Doing (`fil`) | Leaving (`tark`) |
|---|---|---|
| wājib | «يثاب فاعله امتثالاً» | «يستحق العقاب تاركُه» |
| mandūb | «يثاب فاعله امتثالاً» | «لا يعاقب تاركه» |
| mubāḥ | «لا يترتب عليه ثواب ولا عقاب» | the same |
| makrūh | «لا يعاقب فاعله» | «يثاب تاركه امتثالاً» |
| ḥarām | «يستحق العقاب فاعله» | «يثاب تاركه امتثالاً» |

That pair is the semantics, and nothing here is a number. Reward is conditioned on obedience
(«امتثالاً») and punishment is liability («يستحق»), not its infliction: `Jaza` records what the
Lawgiver attaches to the act, not what befalls a given agent.

* The pair separates the five (`jaza_injective`); the mandūb is not a weaker wājib but the wājib
  without liability for leaving, and the makrūh not a weaker ḥarām but the ḥarām without
  liability for doing.
* ilzām is liability on one side (`binding_iff`); ṭalab al-fiʿl is reward for doing and ṭalab
  al-tark reward for leaving (`mode_talabFil_iff`, `mode_talabTark_iff`).
* The omission swaps doing and leaving (`σ_fil`, `σ_tark`), so `σ` (*al-amr bi'l-shayʾ nahy ʿan
  ḍiddih*, read on statuses) follows from the definitions.
* `b` favours doing at least as much as `a` when doing under `b` fares no worse and leaving no
  better (`≤`). The five form a chain Ḥ < K < M < N < W (`le_total`), but its steps differ in
  kind: W → N drops liability for leaving, N → M drops reward for doing, M → K adds reward for
  leaving, K → Ḥ adds liability for doing. Two steps are about punishment and two about reward,
  so no step is a unit and the chain has no arithmetic.

The profile does not record the khiṭāb. Khilāf al-awlā, which later Shāfiʿīs separate from the
makrūh, has the makrūh's profile (`σ mandub = makruh`) and differs in having no specific nahy.
`σ` models the omission (tark) where the maxim speaks of the contrary (ḍidd), of which an act may
have several. See `docs/architecture/hukm-interval-verdicts.md`.
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

/-- What the Lawgiver attaches to doing or to leaving an act. -/
inductive Jaza where
  | thawab   -- «يثاب … امتثالاً»: rewarded, when done or left in obedience
  | neither  -- «لا يعاقب», «لا يترتب عليه ثواب ولا عقاب»: no reward and no liability
  | iqab     -- «يستحق العقاب»: liable to punishment
  deriving DecidableEq, Repr

/-- `a` fares no better than `b`: liability, then neither, then reward. -/
def Jaza.leb : Jaza → Jaza → Bool
  | .iqab, _ | .neither, .neither | .neither, .thawab | .thawab, .thawab => true
  | _, _ => false

namespace Hukm

/-- What follows on doing the act. -/
def fil : Hukm → Jaza
  | wajib | mandub => .thawab | mubah | makruh => .neither | haram => .iqab

/-- What follows on leaving the act. -/
def tark : Hukm → Jaza
  | wajib => .iqab | mandub | mubah => .neither | makruh | haram => .thawab

/-- The definitions separate the five statuses. -/
theorem jaza_injective {a b : Hukm} (hf : a.fil = b.fil) (ht : a.tark = b.tark) : a = b := by
  cases a <;> cases b <;> simp_all [fil, tark]

/-- No status rewards both sides, and none makes both liable. -/
theorem not_both_thawab (h : Hukm) : ¬ (h.fil = .thawab ∧ h.tark = .thawab) := by cases h <;> decide
theorem not_both_iqab (h : Hukm) : ¬ (h.fil = .iqab ∧ h.tark = .iqab) := by cases h <;> decide

/-- Ibāḥa is exactly neither reward nor liability on either side. -/
theorem mubah_iff (h : Hukm) : h = mubah ↔ h.fil = .neither ∧ h.tark = .neither := by
  cases h <;> decide

/-- `b` favours doing at least as much as `a`: doing fares no worse under `b`, leaving no better. -/
instance : LE Hukm := ⟨fun a b => a.fil.leb b.fil = true ∧ b.tark.leb a.tark = true⟩
instance (a b : Hukm) : Decidable (a ≤ b) := inferInstanceAs (Decidable (_ ∧ _))

theorem le_refl (a : Hukm) : a ≤ a := by cases a <;> decide
theorem le_trans {a b c : Hukm} : a ≤ b → b ≤ c → a ≤ c := by
  cases a <;> cases b <;> cases c <;> decide
theorem le_antisymm {a b : Hukm} : a ≤ b → b ≤ a → a = b := by cases a <;> cases b <;> decide
/-- The five form a chain. -/
theorem le_total (a b : Hukm) : a ≤ b ∨ b ≤ a := by cases a <;> cases b <;> decide
theorem haram_le (a : Hukm) : haram ≤ a := by cases a <;> decide
theorem le_wajib (a : Hukm) : a ≤ wajib := by cases a <;> decide

/-- Status of the omission (*tark*) of an act with status `h`. -/
def σ : Hukm → Hukm
  | wajib => haram | mandub => makruh | mubah => mubah | makruh => mandub | haram => wajib

@[simp] theorem σ_σ (h : Hukm) : σ (σ h) = h := by cases h <;> rfl

theorem σ_involutive : ∀ h, σ (σ h) = h := σ_σ

/-- Doing the omission is leaving the act. -/
theorem σ_fil (h : Hukm) : (σ h).fil = h.tark := by cases h <;> rfl

/-- Leaving the omission is doing the act. -/
theorem σ_tark (h : Hukm) : (σ h).tark = h.fil := by cases h <;> rfl

/-- `σ` is the status whose profile is the swapped one: it is fixed by the definitions. -/
theorem σ_eq_iff {h g : Hukm} : σ h = g ↔ g.fil = h.tark ∧ g.tark = h.fil :=
  ⟨fun e => e ▸ ⟨σ_fil h, σ_tark h⟩, fun ⟨a, b⟩ => jaza_injective ((σ_fil h).trans a.symm) ((σ_tark h).trans b.symm)⟩

theorem σ_antitone {a b : Hukm} (h : a ≤ b) : σ b ≤ σ a := by
  revert h; cases a <;> cases b <;> decide

/-- σ reverses the order exactly. -/
theorem σ_le_σ {a b : Hukm} : σ a ≤ σ b ↔ b ≤ a := ⟨fun h => by simpa using σ_antitone h, σ_antitone⟩

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

/-- ilzām is liability on one side: the binding statuses are those a leaver or a doer answers for. -/
theorem binding_iff (h : Hukm) : h.binding = true ↔ (h.fil = .iqab ∨ h.tark = .iqab) := by
  cases h <;> decide

/-- Ṭalab al-fiʿl is reward for doing. -/
theorem mode_talabFil_iff (h : Hukm) : h.mode = .talabFil ↔ h.fil = .thawab := by cases h <;> decide

/-- Ṭalab al-tark is reward for leaving. -/
theorem mode_talabTark_iff (h : Hukm) : h.mode = .talabTark ↔ h.tark = .thawab := by cases h <;> decide

end Hukm
end Usul
