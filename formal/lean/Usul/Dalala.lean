import Usul.Schema

/-!
# Dalāla: inference schemata of the texts (roadmap M5)

* **ʿĀmm with ʿahd** (Ibn al-Laḥḥām 52: «the singular with al- is general unless there is an
  indication of ʿahd»): the M4 generality cases split on genus versus ʿahd, and a proper name
  pins an annexed singular (53.f006). `IsGeneralIn` adds the blocking ʿahd/taʿyīn input to
  al-Saʿdī's Q59/Q60 reading and is conservative over it.
* **Takhṣīṣ** (ʿāmm/khāṣṣ as a specificity attack): the specific rule governs its own scope,
  the general one the rest. It is specification, not abrogation: the general stays in force
  outside the specific scope.
* **Ḥaml al-muṭlaq ʿalā al-muqayyad** as Q29's qualifier algebra, under a policy on when the
  two share ruling and cause.
* **Al-amr li'l-wujūb, al-nahy li'l-taḥrīm** as defeasible defaults (S2): an indication
  (qarīna) overrides. The nahy default is σ of the amr default.
* **Al-amr bi'l-shayʾ nahy ʿan ḍiddih** from σ, for a ruling assignment that respects σ on
  complementary acts.
* **Mafhūm al-mukhālafa** with its blocking conditions (the usual case, an answer to a
  question, gratitude/emphasis).
* **Tarjīḥ** as a preference ≺ that is a strict partial order and well-founded.
* **ʿUmūm al-lafẓ, not khuṣūṣ al-sabab** (Ibn al-Laḥḥām 61), as a policy.
-/

namespace Usul.Dalala

open Usul Usul.Schema

/-! ## Generality with ʿahd -/

/-- Q59/Q60 refined: a marker of generality is blocked by ʿahd (al- for a known referent) or
by taʿyīn (a proper name pinning the referent). -/
def IsGeneralIn (f : Sadi.NounForm) (c : Sadi.Context) (ahd : Bool) : Bool :=
  !ahd && Sadi.IsGeneral f c

/-- Conservative: without ʿahd the refinement is al-Saʿdī's reading. -/
theorem isGeneralIn_no_ahd (f : Sadi.NounForm) (c : Sadi.Context) :
    IsGeneralIn f c false = Sadi.IsGeneral f c := by
  simp [IsGeneralIn]

theorem ahd_blocks (f : Sadi.NounForm) (c : Sadi.Context) : IsGeneralIn f c true = false := rfl

/-- It is S3: the marker is the condition, ʿahd the impediment. -/
theorem isGeneralIn_is_gate (f : Sadi.NounForm) (c : Sadi.Context) (a : Bool) :
    IsGeneralIn f c a = true ↔
      (Sadi.Gate.ofBools [fun p : Bool × Bool => p.1] [Prod.snd]).Holds (Sadi.IsGeneral f c, a) := by
  rw [Sadi.Gate.holds_ofBools]; cases a <;> cases h : Sadi.IsGeneral f c <;> simp [IsGeneralIn, h]

/-! ## Takhṣīṣ: the specific governs its scope -/

/-- A general rule and a specific one; the specific's scope lies inside the general's. -/
structure Takhsis (α : Type) where
  general : α → Bool
  specific : α → Bool
  generalRuling : Hukm
  specificRuling : Hukm

/-- The governing ruling: the specific where it applies, else the general (S2). -/
def Takhsis.ruling {α : Type} (t : Takhsis α) (x : α) : Option Hukm :=
  first [if t.specific x then some t.specificRuling else none,
         if t.general x then some t.generalRuling else none]

theorem takhsis_specific_governs {α : Type} (t : Takhsis α) {x : α} (h : t.specific x = true) :
    t.ruling x = some t.specificRuling := by
  simp [Takhsis.ruling, first, h]

/-- Specification is not abrogation: outside the specific scope the general still holds. -/
theorem takhsis_not_naskh {α : Type} (t : Takhsis α) {x : α} (hs : t.specific x = false)
    (hg : t.general x = true) : t.ruling x = some t.generalRuling := by
  simp [Takhsis.ruling, first, hs, hg]

/-! ## Muṭlaq and muqayyad -/

/-- When the unrestricted is read as restricted: same ruling and same cause always; same
ruling with different cause per policy (two reports from Aḥmad); different rulings never. -/
def carryRestriction (sameHukm sameSabab allowDifferentSabab : Bool) : Bool :=
  sameHukm && (sameSabab || allowDifferentSabab)

theorem carry_same_hukm_same_sabab (p : Bool) : carryRestriction true true p = true := by
  cases p <;> rfl

theorem no_carry_different_hukm (s p : Bool) : carryRestriction false s p = false := rfl

/-- Carrying adds the qualifier: the restricted reading only narrows (Q29). -/
theorem carry_narrows {α : Type} (mutlaq qayd : α → Bool) (x : α)
    (h : (mutlaq x && qayd x) = true) : mutlaq x = true := by
  simp at h; exact h.1

/-! ## Command and prohibition as defeasible defaults -/

/-- The command's status: an indication decides, else obligation (S2). -/
def amrStatus (qarina : Option Hukm) : Hukm := resolveD [qarina] .wajib

/-- The prohibition's status: an indication decides, else prohibition. -/
def nahyStatus (qarina : Option Hukm) : Hukm := resolveD [qarina] .haram

theorem amr_default : amrStatus none = .wajib := rfl
theorem amr_defeasible (h : Hukm) : amrStatus (some h) = h := rfl

/-- The prohibition's default is the σ-image of the command's. -/
theorem nahy_default_is_sigma : nahyStatus none = Hukm.σ (amrStatus none) := rfl

/-! ## The command to a thing is a prohibition of its opposite -/

/-- A ruling assignment respects σ on an act and its opposite (ḍidd). -/
def RespectsDidd {Act : Type} (H : Act → Hukm) (didd : Act → Act) : Prop :=
  ∀ a, H (didd a) = Hukm.σ (H a)

theorem amr_nahy_didd_of {Act : Type} {H : Act → Hukm} {didd : Act → Act} (h : RespectsDidd H didd)
    {a : Act} (hw : H a = .wajib) : H (didd a) = .haram := by
  rw [h a, hw]; rfl

/-- And conversely the prohibition of a thing commands its opposite. -/
theorem nahy_amr_didd_of {Act : Type} {H : Act → Hukm} {didd : Act → Act} (h : RespectsDidd H didd)
    {a : Act} (hh : H a = .haram) : H (didd a) = .wajib := by
  rw [h a, hh]; rfl

/-! ## Mafhūm al-mukhālafa with its blockers -/

inductive Blocker where
  | none | usualCase | answerToQuestion | emphasis
  deriving DecidableEq, Repr

/-- Whether the ruling holds of `x` by the text and its contrary implication: inside the
condition yes; outside it, no, unless a blocker suspends the implication (then nothing follows). -/
def mafhum {α : Type} (cond : α → Bool) (b : Blocker) (x : α) : Option Bool :=
  if cond x then some true else if b == .none then some false else none

theorem mafhum_contrary {α : Type} {cond : α → Bool} {x : α} (h : cond x = false) :
    mafhum cond .none x = some false := by
  simp [mafhum, h]

theorem mafhum_blocked {α : Type} {cond : α → Bool} {b : Blocker} (hb : b ≠ .none) {x : α}
    (h : cond x = false) : mafhum cond b x = none := by
  simp [mafhum, h, hb]

/-! ## Tarjīḥ as a strict, well-founded preference -/

/-- `a ≺ b`: `b` is preferred to `a` by a rank (strength of the proof). -/
def Prefers {ι : Type} (rank : ι → Nat) (a b : ι) : Prop := rank a < rank b

theorem prefers_irrefl {ι : Type} (rank : ι → Nat) (a : ι) : ¬ Prefers rank a a := Nat.lt_irrefl _

theorem prefers_trans {ι : Type} (rank : ι → Nat) {a b c : ι} (h₁ : Prefers rank a b)
    (h₂ : Prefers rank b c) : Prefers rank a c := Nat.lt_trans h₁ h₂

theorem prefers_asymm {ι : Type} (rank : ι → Nat) {a b : ι} (h : Prefers rank a b) :
    ¬ Prefers rank b a := fun h' => Nat.lt_irrefl _ (Nat.lt_trans h h')

/-- Well-founded: no infinite chain of ever-weaker derivations. (On a finite set a most
preferred derivation exists: that is S8's `best_optimal`.) -/
theorem prefers_wf {ι : Type} (rank : ι → Nat) : WellFounded (Prefers rank) :=
  (measure rank).wf

/-! ## ʿUmūm al-lafẓ, khuṣūṣ al-sabab -/

/-- A general wording on a specific occasion: whether it covers cases beyond its occasion. -/
def coversBeyondSabab (byWording : Bool) (inOccasion generalWording : Bool) : Bool :=
  inOccasion || (byWording && generalWording)

theorem occasion_always_covered (p g : Bool) : coversBeyondSabab p true g = true := by
  cases p <;> rfl

end Usul.Dalala
