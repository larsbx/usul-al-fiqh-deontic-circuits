import Usul.Jadal

/-!
# The limits of qiyās: how it fails, where it runs, how clear it is

* **Fallibility** (Rawḍat al-Nāẓir v2 p185): qiyās goes wrong when the ruling is not caused,
  the ʿilla is missed, part of it is omitted, an extraneous description is added, or it is
  wrongly believed present in the farʿ. Ibn al-Qayyim's errors of the qiyāsīs («considering
  causes the Lawgiver did not consider and disregarding ones he did», Iʿlām v1 p263) are the
  addition and omission cases. With the ʿilla as a conjunction of descriptions the two are
  asymmetric: an added description keeps the qiyās sound but narrow, an omitted one makes it
  unsound.
* **"Nothing in the sharīʿa is against sound qiyās"** (Iʿlām v1 p289 ff.; Ibn Taymiyya): once
  texts are among the given cases, a qiyās contradicting a text is a naqḍ, so it was not a
  sound qiyās.
* **Scope** (Rawḍa v2 pp. 293–300; al-Ṭūfī v3 pp. 448–453; al-Kawkab v4 p220): for the
  Ḥanbalīs qiyās runs wherever the rationale is understood, including ḥudūd, kaffārāt and
  fixed amounts; original negation takes only qiyās al-dalāla. The Ḥanafīs exclude ḥudūd,
  kaffārāt, rukhaṣ and fixed amounts. Qiyās in causes is disputed inside the madhhab (a
  parameter).
* **Jalī / khafī** (al-Kawkab v4 p207; Ibn ʿUthaymīn p72), **shahādat al-uṣūl** (Rawḍa v2
  p231), and **tamthīl ≡ shumūl** (Ibn Taymiyya, al-Radd p116: the jurists' analogy and the
  first-figure syllogism carry the same content; the middle term is the ʿilla).
-/

namespace Usul.QiyasLimits

open Usul Usul.Schema Usul.Qiyas

/-! ## Fallibility: the ʿilla as a conjunction of descriptions -/

/-- An ʿilla made of several descriptions, all required. -/
def conj {α : Type} (parts : List (Wasf α)) : Wasf α := fun x => parts.all (· x)

theorem conj_iff {α : Type} {parts : List (Wasf α)} {x : α} :
    conj parts x = true ↔ ∀ f ∈ parts, f x = true := by
  simp [conj, List.all_eq_true]

/-- Adding an extraneous description (al-Rawḍa's fourth error) keeps the qiyās sound: every
case the proposed ʿilla marks has the true one. It is only narrower. -/
theorem addition_sound {α : Type} {true_ proposed : List (Wasf α)} (h : ∀ f ∈ true_, f ∈ proposed)
    {x : α} (hx : conj proposed x = true) : conj true_ x = true :=
  conj_iff.2 fun f hf => conj_iff.1 hx f (h f hf)

/-- Omitting part of the ʿilla (the third error) makes it unsound: a case with the proposed
ʿilla but lacking the omitted part gets the ruling wrongly. -/
theorem omission_unsound {α : Type} {true_ proposed : List (Wasf α)} {f : Wasf α} (hf : f ∈ true_)
    {x : α} (hp : conj proposed x = true) (hfx : f x = false) :
    conj proposed x = true ∧ conj true_ x = false := by
  refine ⟨hp, ?_⟩
  cases e : conj true_ x
  · rfl
  · simp [conj_iff.1 e f hf] at hfx

/-- The asymmetry in ruling terms: with an added description, qiyās never extends the ruling
to a case outside the true ʿilla. -/
theorem addition_never_overextends {α β : Type} {H : α → β} {true_ proposed : List (Wasf α)}
    (h : ∀ f ∈ true_, f ∈ proposed) {asl far : α} (hasl : conj true_ asl = true)
    (hf : Factors H (conj true_)) (hfar : conj proposed far = true) : H far = H asl :=
  hf far asl (by rw [addition_sound h hfar, hasl])

/-! ## No sound qiyās against a text -/

/-- With texts among the given cases, a qiyās whose ʿilla is in a text-ruled farʿ that the text
rules otherwise is a naqḍ: no ruling agreeing with the texts depends only on that ʿilla. -/
theorem qiyas_against_text_unsound {α β : Type} {w : Wasf α} {known : Known α β} {asl far : α} {r t : β}
    (hasl : w asl = true) (hfar : w far = true) (htext : (far, t) ∈ known) (hne : t ≠ r)
    {H : α → β} (hH : Agrees H known) (hr : H asl = r) : ¬ Factors H w :=
  naqd_defeats hasl ⟨(far, t), htext, hfar, hne⟩ hH hr

/-! ## Scope -/

inductive Domain where
  | ibadat | muamalat | hudud | kaffarat | rukhas | muqaddarat | asbab | nafyAsli | nafyTari
  deriving DecidableEq, Repr

inductive Kind where
  | illa | dalala
  deriving DecidableEq, Repr

/-- The Ḥanbalī scope: wherever the rationale is understood; in causes per a parameter (the
inner dispute); original negation only by qiyās al-dalāla (Rawḍa v2 p300; al-Ṭūfī v3 p453). -/
def hanbaliAdmits (allowAsbab : Bool) (d : Domain) (k : Kind) (intelligible : Bool) : Bool :=
  intelligible && (d != .asbab || allowAsbab) && (d != .nafyAsli || k == .dalala)

/-- The Ḥanafī scope as the Ḥanbalī sources report it: no qiyās in ḥudūd, kaffārāt, rukhaṣ or
fixed amounts (al-Kawkab v4 p220; Rawḍa v2 p298). -/
def hanafiAdmits (allowAsbab : Bool) (d : Domain) (k : Kind) (intelligible : Bool) : Bool :=
  hanbaliAdmits allowAsbab d k intelligible &&
    !(d == .hudud || d == .kaffarat || d == .rukhas || d == .muqaddarat)

/-- In ḥudūd and kaffārāt the Ḥanbalī condition is intelligibility alone. -/
theorem hanbali_hudud (a : Bool) (k : Kind) (i : Bool) :
    hanbaliAdmits a .hudud k i = i ∧ hanbaliAdmits a .kaffarat k i = i := by
  cases a <;> cases k <;> cases i <;> decide

/-- Where the rationale is not understood (the number of rakʿas), no domain admits qiyās. -/
theorem no_qiyas_without_rationale (a : Bool) (d : Domain) (k : Kind) : hanbaliAdmits a d k false = false := by
  simp [hanbaliAdmits]

/-- Original negation takes qiyās al-dalāla, not qiyās al-ʿilla. -/
theorem nafy_asli_only_dalala (a : Bool) (i : Bool) : hanbaliAdmits a .nafyAsli .illa i = false := by
  cases a <;> cases i <;> decide

/-- The Ḥanafī scope is contained in the Ḥanbalī one. -/
theorem hanafi_within_hanbali {a : Bool} {d : Domain} {k : Kind} {i : Bool}
    (h : hanafiAdmits a d k i = true) : hanbaliAdmits a d k i = true := by
  simp only [hanafiAdmits, Bool.and_eq_true] at h; exact h.1

/-- … and strictly: an intelligible ḥadd separates them. -/
theorem hanafi_strictly_narrower (a : Bool) (k : Kind) :
    hanbaliAdmits a .hudud k true = true ∧ hanafiAdmits a .hudud k true = false := by
  cases a <;> cases k <;> decide

/-! ## Jalī and khafī -/

inductive Clarity where
  | jali | khafi
  deriving DecidableEq, Repr

/-- Jalī when the ʿilla is textual or consensual, or the absence of a difference is certain;
otherwise khafī (al-Kawkab v4 p207; Ibn ʿUthaymīn p72). -/
def clarity (src : IllaSource) (noFariqCertain : Bool) : Clarity :=
  if src == .mansusa || noFariqCertain then .jali else .khafi

/-- The jalī is preferred (Ibn ʿUthaymīn p82), consistently with the constraint that a textual
ʿilla outranks an inferred one (`Jadal.RespectsSources`). -/
theorem textual_is_jali (b : Bool) : clarity .mansusa b = .jali := by
  cases b <;> rfl

theorem khafi_iff (src : IllaSource) (b : Bool) :
    clarity src b = .khafi ↔ src = .mustanbata ∧ b = false := by
  cases src <;> cases b <;> simp [clarity]

/-! ## Shahādat al-uṣūl -/

/-- The uṣūl testify for a waṣf when there are some and none of them contradicts it (ṭard
across the family of uṣūl). Its acceptance is disputed (Rawḍa v2 p231), so it is not a gate
condition here. -/
def shahadatUsul {α β : Type} [DecidableEq β] (w : Wasf α) (r : β) (usul : Known α β) : Bool :=
  !usul.isEmpty && tard w r usul

/-- Testimony from more uṣūl is stronger: it survives restriction to any non-empty subfamily
(and qiyās on many uṣūl is preferred, al-Ṭūfī v3 p713). -/
theorem shahada_restrict {α β : Type} [DecidableEq β] {w : Wasf α} {r : β} {usul sub : Known α β}
    (hs : ∀ p ∈ sub, p ∈ usul) (hne : sub ≠ []) (h : shahadatUsul w r usul = true) :
    shahadatUsul w r sub = true := by
  simp only [shahadatUsul, Bool.and_eq_true] at h ⊢
  refine ⟨by cases sub <;> simp_all, ?_⟩
  exact tard_iff.2 fun p hp hw => tard_iff.1 h.2 p (hs p hp) hw

/-! ## Tamthīl and shumūl -/

/-- Ibn Taymiyya: the jurists' qiyās (tamthīl: any two cases joined by the jāmiʿ share the
ruling) and the first-figure syllogism (shumūl: one ruling holds of everything with the middle
term) carry the same content once some case has the jāmiʿ; certainty depends on the premises,
not the form. -/
theorem tamthil_iff_shumul {α β : Type} {H : α → β} {w : Wasf α} {a₀ : α} (h₀ : w a₀ = true) :
    (∀ asl far, w asl = true → w far = true → H far = H asl) ↔ (∃ h : β, ∀ x, w x = true → H x = h) := by
  constructor
  · intro ht; exact ⟨H a₀, fun x hx => ht a₀ x h₀ hx⟩
  · rintro ⟨h, hs⟩ asl far ha hf; rw [hs far hf, hs asl ha]

/-- And either follows from the ʿilla's determining the ruling (Q58). -/
theorem shumul_of_factors {α β : Type} {H : α → β} {w : Wasf α} {asl : α} (hasl : w asl = true)
    (hf : Factors H w) : ∀ x, w x = true → H x = H asl :=
  fun x hx => hf x asl (by rw [hx, hasl])

end Usul.QiyasLimits
