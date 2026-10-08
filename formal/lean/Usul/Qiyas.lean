import Usul.Schema

/-!
# Qiyās: the ways of establishing the ʿilla (masālik) and the objections (qawādiḥ)

Q58 and S1 give the core: if the ruling depends only on the ʿilla, a farʿ sharing it shares
the ruling. This module adds the two classical bodies of doctrine around that core.

* **Masālik al-ʿilla**: how a waṣf is shown to be the ʿilla. Naṣṣ and ijmāʿ come from
  outside the model. Here: ṭard, dawarān (ṭard wa-ʿaks), al-sabr wa'l-taqsīm, munāsaba (tied
  to Q1), shabah (S8), and the three manāṭ operations (tanqīḥ, takhrīj, taḥqīq).
* **Qawādiḥ**: the objections in debate. Each comes with a soundness theorem saying *why* it
  defeats the inference: it contradicts a premise, or it shows the data underdetermine the
  farʿ. Covered: manʿ, naqḍ (with takhṣīṣ al-ʿilla), kasr, ʿadam al-taʾthīr (with plurality of
  ʿilal), farq / muʿāraḍa fī al-aṣl, qalb, al-qawl bi'l-mūjab, fasād al-iʿtibār, fasād al-waḍʿ.

Where the madhhab is divided (takhṣīṣ al-ʿilla, taʿaddud al-ʿilal, the status of kasr, the
mursal), the position is a parameter, never a choice made here. The register
(`corpus/review/sadi_interpretive_questions.json`, IQ-13 to IQ-16) cites the established
Ḥanbalī positions: al-Musawwada v1 pp. 328, 412, 428, 450 and Rawḍat al-Nāẓir v1 p. 477.
Ibn Taymiyya's definition, «the sound qiyās … is joining two like things and separating two
different things» (Majmūʿ al-Fatāwā v20 p504), is the pair `Factors.qiyas` / `farq_defeats`.

The whole qiyās is then an S3 gate: the arkān and taḥqīq al-manāṭ are conditions, the
qawādiḥ impediments, and `qiyas_sound` proves that the gate licenses the farʿ's ruling.
-/

namespace Usul.Qiyas

open Usul Usul.Schema

/-- A waṣf: a Boolean description of cases. -/
abbrev Wasf (α : Type) := α → Bool

section Data

variable {α β : Type}

/-- Cases whose ruling is given (by naṣṣ or ijmāʿ), with that ruling. -/
abbrev Known (α β : Type) := List (α × β)

/-- Ruling `H` agrees with every given case. -/
def Agrees (H : α → β) (known : Known α β) : Prop := ∀ p ∈ known, H p.1 = p.2

/-! ## Masālik: ṭard and dawarān -/

/-- Ṭard: wherever the waṣf is found among the given cases, the ruling `r` is found. -/
def tard [DecidableEq β] (w : Wasf α) (r : β) (known : Known α β) : Bool :=
  known.all fun p => !w p.1 || p.2 == r

/-- ʿAks: wherever the waṣf is absent, the ruling is absent. -/
def aks [DecidableEq β] (w : Wasf α) (r : β) (known : Known α β) : Bool :=
  known.all fun p => w p.1 || p.2 != r

/-- Dawarān: the ruling turns with the waṣf, present and absent. -/
def dawaran [DecidableEq β] (w : Wasf α) (r : β) (known : Known α β) : Bool := tard w r known && aks w r known

theorem tard_iff [DecidableEq β] {w : Wasf α} {r : β} {known : Known α β} :
    tard w r known = true ↔ ∀ p ∈ known, w p.1 = true → p.2 = r := by
  simp only [tard, List.all_eq_true, Bool.or_eq_true, Bool.not_eq_true', beq_iff_eq]
  exact forall₂_congr fun p _ => by cases w p.1 <;> simp

theorem aks_iff [DecidableEq β] {w : Wasf α} {r : β} {known : Known α β} :
    aks w r known = true ↔ ∀ p ∈ known, w p.1 = false → p.2 ≠ r := by
  simp only [aks, List.all_eq_true, Bool.or_eq_true, bne_iff_ne, ne_eq]
  exact forall₂_congr fun p _ => by cases w p.1 <;> simp

theorem dawaran_iff [DecidableEq β] {w : Wasf α} {r : β} {known : Known α β} :
    dawaran w r known = true ↔ ∀ p ∈ known, (w p.1 = true ↔ p.2 = r) := by
  simp only [dawaran, Bool.and_eq_true, tard_iff, aks_iff]
  constructor
  · rintro ⟨ht, ha⟩ p hp
    cases hw : w p.1
    · exact ⟨nofun, fun h => absurd h (ha p hp hw)⟩
    · exact ⟨fun _ => ht p hp hw, fun _ => rfl⟩
  · intro h
    exact ⟨fun p hp hw => (h p hp).1 hw, fun p hp hw hr => by simp [(h p hp).2 hr] at hw⟩

/-- Ṭard alone is weak: a waṣf found in no given case satisfies it vacuously. -/
theorem tard_vacuous [DecidableEq β] (r : β) (known : Known α β) : tard (fun _ => false) r known = true :=
  tard_iff.2 fun _ _ h => nomatch h

/-- Dawarān is only presumptive (ẓannī): two waṣfs can both turn with the ruling on all
given cases and still disagree on a farʿ. -/
theorem dawaran_not_unique :
    ∃ (known : Known Nat Bool) (w₁ w₂ : Wasf Nat) (far : Nat),
      dawaran w₁ true known = true ∧ dawaran w₂ true known = true ∧ w₁ far ≠ w₂ far :=
  ⟨[(0, true), (1, false)], (· == 0), (· % 2 == 0), 2, by decide, by decide, by decide⟩

/-! ## Masālik: al-sabr wa'l-taqsīm -/

/-- Probing: keep the candidates that a refutation test does not eliminate. -/
def survivors (refuted : Wasf α → Bool) (cs : List (Wasf α)) : List (Wasf α) :=
  cs.filter fun w => !refuted w

/-- Soundness of sabr wa-taqsīm: if the division is exhaustive (the ʿilla is among the
candidates) and the ʿilla is not refuted, a sole survivor is the ʿilla. -/
theorem sabr_sound {refuted : Wasf α → Bool} {cs : List (Wasf α)} {illa w : Wasf α}
    (hasr : illa ∈ cs) (hok : refuted illa = false) (h : survivors refuted cs = [w]) : w = illa := by
  have : illa ∈ survivors refuted cs := List.mem_filter.2 ⟨hasr, by simp [hok]⟩
  rw [h] at this
  exact (List.mem_singleton.1 this).symm

/-- Without exhaustiveness (ḥaṣr) the method fails: the sole survivor need not be the ʿilla. -/
theorem sabr_needs_hasr :
    ∃ (refuted : Wasf Nat → Bool) (cs : List (Wasf Nat)) (illa w : Wasf Nat),
      refuted illa = false ∧ survivors refuted cs = [w] ∧ w 1 ≠ illa 1 :=
  ⟨fun _ => false, [fun _ => true], fun _ => false, fun _ => true, rfl, rfl, by decide⟩

/-- The usual refutation test: a candidate is eliminated by a counter-case (naqḍ). -/
def refutedByNaqd [DecidableEq β] (r : β) (known : Known α β) (w : Wasf α) : Bool := !tard w r known

/-! ## Masālik: munāsaba (suitability), tied to Q1 -/

/-- A waṣf is suitable for a demand when every case it marks carries preponderant benefit. -/
def Munasib {Act : Type} (w : Wasf Act) (weigh : Act → Sadi.Weighing) : Prop :=
  ∀ x, w x = true → (weigh x).harm < (weigh x).benefit

/-- Under Q1, any waṣf on whose cases the law demands the act is suitable: munāsaba is
what Q1 predicts of a sound ʿilla of command. -/
theorem munasaba_of_q01 {Act : Type} {ruling : Act → Hukm} {weigh : Act → Sadi.Weighing}
    (hq : Sadi.Q01 ruling weigh) (w : Wasf Act) (hw : ∀ x, w x = true → (ruling x).mode = .talabFil) :
    Munasib w weigh :=
  fun x hx => (hq x).1 (hw x hx)

/-- Degrees of legal recognition of a suitable waṣf. -/
inductive Recognition where
  | muathhir   -- its very kind recognised for this very ruling by naṣṣ or ijmāʿ
  | mulaim     -- its kind or genus recognised for the ruling's genus
  | gharib     -- recognised only by the ruling attached to it here
  | mursal     -- neither recognised nor cancelled (maṣlaḥa mursala)
  | mulgha     -- cancelled by the law
  deriving DecidableEq, Repr

/-- Acceptance of a suitable waṣf. Whether the mursal is accepted is a parameter: it is
disputed. The cancelled one is never accepted. -/
def Recognition.accepted (acceptMursal : Bool) : Recognition → Bool
  | .mulgha => false
  | .mursal => acceptMursal
  | _ => true

theorem mulgha_never_accepted (b : Bool) : Recognition.mulgha.accepted b = false := rfl

/-! ## Masālik: shabah (resemblance), an instance of S8 -/

/-- How many of the listed features the farʿ shares with a candidate aṣl. -/
def resemblance (features : List (Wasf α)) (far asl : α) : Nat :=
  (features.filter fun g => g far == g asl).length

/-- Qiyās al-shabah attaches the farʿ to the aṣl it resembles most (ghalabat al-ashbāh). -/
def shabahAsl (features : List (Wasf α)) (far : α) (asls : List α) : Option α :=
  Sadi.best (fun a => (resemblance features far a : Int)) asls

theorem shabah_optimal {features : List (Wasf α)} {far : α} {asls : List α} {a : α}
    (h : shabahAsl features far asls = some a) :
    Optimal (fun a => (resemblance features far a : Int)) asls a :=
  best_optimal h

/-! ## Masālik: the manāṭ operations -/

/-- Tanqīḥ al-manāṭ: a ruling stated on two features, one shown irrelevant (ilghāʾ
al-fāriq), depends on the other alone. -/
theorem tanqih_manat {F G : Type} {H : α → β} {e₁ : α → F} {e₂ : α → G} (K : F → G → β)
    (hH : ∀ x, H x = K (e₁ x) (e₂ x)) (hign : Ignores K) : Factors H e₁ :=
  fun x y hxy => by rw [hH x, hH y, hign (e₁ x) (e₂ x) (e₂ y), hxy]

/-- Takhrīj al-manāṭ is the extraction of the ʿilla, by sabr (`sabr_sound`) or munāsaba.
Taḥqīq al-manāṭ is verifying the ʿilla in the farʿ: a condition of the gate below. -/
abbrev TahqiqManat (w : Wasf α) (far : α) : Prop := w far = true

/-! ## Qawādiḥ -/

/-- The underdetermination lemma behind manʿ and farq: if a feature separates the farʿ from
the aṣl, rulings depending only on it can agree on the aṣl and differ on the farʿ. -/
theorem underdetermined {F : Type} [DecidableEq F] (e : α → F) {asl far : α} (h : e far ≠ e asl)
    {b₁ b₂ : β} (hb : b₁ ≠ b₂) :
    ∃ H₁ H₂ : α → β, Factors H₁ e ∧ Factors H₂ e ∧ H₁ asl = H₂ asl ∧ H₁ far ≠ H₂ far := by
  refine ⟨fun _ => b₁, fun x => if e x = e far then b₂ else b₁,
    fun _ _ _ => rfl, fun x y hxy => by simp [hxy], ?_, ?_⟩
  · simp [Ne.symm h]
  · simpa using hb

/-- Manʿ (denial that the ʿilla is in the farʿ): the inference has no hold. -/
theorem man_defeats {w : Wasf α} {asl far : α} (h : w far ≠ w asl) {b₁ b₂ : β} (hb : b₁ ≠ b₂) :
    ∃ H₁ H₂ : α → β, Factors H₁ w ∧ Factors H₂ w ∧ H₁ asl = H₂ asl ∧ H₁ far ≠ H₂ far :=
  underdetermined w h hb

/-- Farq / muʿāraḍa fī al-aṣl: the objector names a second waṣf present in the aṣl and
absent in the farʿ. Unless it is shown irrelevant (tanqīḥ), the aṣl does not fix the farʿ. -/
theorem farq_defeats {w w' : Wasf α} {asl far : α} (hw : w far = w asl) (h' : w' far ≠ w' asl)
    {b₁ b₂ : β} (hb : b₁ ≠ b₂) :
    ∃ H₁ H₂ : α → β, Factors H₁ (fun x => (w x, w' x)) ∧ Factors H₂ (fun x => (w x, w' x)) ∧
      H₁ asl = H₂ asl ∧ H₁ far ≠ H₂ far :=
  underdetermined (fun x => (w x, w' x)) (by simp [hw, h']) hb

/-- Naqḍ: a given case with the waṣf and a different ruling. -/
def Naqd (w : Wasf α) (r : β) (known : Known α β) : Prop :=
  ∃ p ∈ known, w p.1 = true ∧ p.2 ≠ r

theorem naqd_iff_not_tard [DecidableEq β] {w : Wasf α} {r : β} {known : Known α β} :
    Naqd w r known ↔ tard w r known = false := by
  rw [← Bool.not_eq_true, tard_iff]
  constructor
  · rintro ⟨p, hp, hw, hr⟩ h; exact hr (h p hp hw)
  · intro h
    simp only [Classical.not_forall] at h
    obtain ⟨p, hp, hw, hr⟩ := h
    exact ⟨p, hp, hw, hr⟩

/-- Naqḍ is decisive against an ʿilla held to determine the ruling: no ruling agreeing with
the given cases depends only on the waṣf and gives the aṣl ruling `r` (generalising
`Sadi.q58_naqd`). -/
theorem naqd_defeats {w : Wasf α} {r : β} {known : Known α β} {asl : α} (hasl : w asl = true)
    (hn : Naqd w r known) {H : α → β} (hH : Agrees H known) (hr : H asl = r) : ¬ Factors H w := by
  intro hf
  obtain ⟨p, hp, hw, hne⟩ := hn
  exact hne (by rw [← hH p hp, hf p.1 asl (by rw [hw, hasl]), hr])

/-- Takhṣīṣ al-ʿilla: if an impediment `m` is present in every counter-case, the ʿilla
restricted by the impediment's absence has no naqḍ. Whether this repair is admitted is the
disputed question; `naqdSucceeds` takes the position as a parameter. -/
theorem takhsis_repairs {w m : Wasf α} {r : β} {known : Known α β}
    (hm : ∀ p ∈ known, w p.1 = true → p.2 ≠ r → m p.1 = true) :
    ¬ Naqd (fun x => w x && !m x) r known := by
  rintro ⟨p, hp, hw, hne⟩
  simp only [Bool.and_eq_true, Bool.not_eq_true'] at hw
  simp [hm p hp hw.1 hne] at hw

/-- Naqḍ as an objection: it succeeds unless takhṣīṣ is admitted and an impediment explains
every counter-case. -/
def NaqdSucceeds (allowTakhsis : Bool) (w m : Wasf α) (r : β) (known : Known α β) : Prop :=
  Naqd w r known ∧ (allowTakhsis = false ∨ ∃ p ∈ known, w p.1 = true ∧ p.2 ≠ r ∧ m p.1 = false)

/-- How the ʿilla was established: the dispute over takhṣīṣ is reported for the *inferred*
ʿilla (al-Musawwada v1 p412: «لا يجوز تخصيص العلة المستنبطة وتخصيصها نقض لها»). -/
inductive IllaSource where
  | mansusa     -- stated by the text
  | mustanbata  -- inferred
  deriving DecidableEq, Repr

/-- Naqḍ under a takhṣīṣ policy that may depend on the ʿilla's source. -/
def NaqdSucceedsBy (policy : IllaSource → Bool) (src : IllaSource) (w m : Wasf α) (r : β)
    (known : Known α β) : Prop :=
  NaqdSucceeds (policy src) w m r known

/-- Under a policy refusing takhṣīṣ, every naqḍ succeeds. -/
theorem naqd_succeeds_without_takhsis {policy : IllaSource → Bool} {src : IllaSource}
    (hp : policy src = false) {w m : Wasf α} {r : β} {known : Known α β} (h : Naqd w r known) :
    NaqdSucceedsBy policy src w m r known :=
  ⟨h, .inl hp⟩

/-- Under a policy admitting takhṣīṣ, a naqḍ whose every counter-case carries the impediment
fails. -/
theorem naqd_answered_by_takhsis {policy : IllaSource → Bool} {src : IllaSource}
    (hp : policy src = true) {w m : Wasf α} {r : β} {known : Known α β}
    (hm : ∀ p ∈ known, w p.1 = true → p.2 ≠ r → m p.1 = true) :
    ¬ NaqdSucceedsBy policy src w m r known := by
  rintro ⟨_, h | ⟨p, hp', hw, hne, hm'⟩⟩
  · simp [hp] at h
  · simp [hm p hp' hw hne] at hm'

/-- Kasr: naqḍ against the ḥikma (the purpose) rather than the waṣf. A naqḍ of the waṣf
yields a kasr of any ḥikma it proxies (maẓinna), but not conversely. -/
theorem naqd_gives_kasr {w hikma : Wasf α} {r : β} {known : Known α β}
    (proxy : ∀ x, w x = true → hikma x = true) (h : Naqd w r known) : Naqd hikma r known := by
  obtain ⟨p, hp, hw, hne⟩ := h
  exact ⟨p, hp, proxy _ hw, hne⟩

theorem kasr_without_naqd :
    ∃ (known : Known Nat Bool) (w hikma : Wasf Nat),
      (∀ x, w x = true → hikma x = true) ∧ Naqd hikma true known ∧ ¬ Naqd w true known := by
  refine ⟨[(1, false)], (· == 0), fun _ => true, fun _ h => rfl, ⟨(1, false), by simp, rfl, by decide⟩, ?_⟩
  rintro ⟨p, hp, hw, _⟩
  simp at hp; subst hp; simp at hw

/-- ʿAdam al-taʾthīr: the ruling found without the waṣf. -/
def AdamTathir (w : Wasf α) (r : β) (known : Known α β) : Prop :=
  ∃ p ∈ known, w p.1 = false ∧ p.2 = r

theorem adamTathir_iff_not_aks [DecidableEq β] {w : Wasf α} {r : β} {known : Known α β} :
    AdamTathir w r known ↔ aks w r known = false := by
  rw [← Bool.not_eq_true, aks_iff]
  constructor
  · rintro ⟨p, hp, hw, hr⟩ h; exact h p hp hw hr
  · intro h
    simp only [Classical.not_forall, Classical.not_not] at h
    obtain ⟨p, hp, hw, hr⟩ := h
    exact ⟨p, hp, hw, hr⟩

/-- With plurality of ʿilal (taʿaddud al-ʿilal) admitted, ʿadam al-taʾthīr is answered when
another ʿilla covers the case; the objection succeeds only on an uncovered case. -/
def AdamTathirSucceeds (allowPlural : Bool) (w : Wasf α) (others : List (Wasf α)) (r : β)
    (known : Known α β) : Prop :=
  ∃ p ∈ known, w p.1 = false ∧ p.2 = r ∧ (allowPlural = false ∨ ∀ w' ∈ others, w' p.1 = false)

theorem dawaran_answers_adamTathir [DecidableEq β] {w : Wasf α} {r : β} {known : Known α β}
    (h : dawaran w r known = true) : ¬ AdamTathir w r known := by
  rw [adamTathir_iff_not_aks]
  simp only [dawaran, Bool.and_eq_true] at h
  simp [h.2]

/-- Qalb: the objector shows the same ʿilla, from the same aṣl, yields a ruling `Q`
incompatible in the farʿ with the proponent's `P`. Then the ʿilla cannot ground both. -/
theorem qalb_defeats {w : Wasf α} {asl far : α} {P Q : α → Bool} (hw : w far = w asl)
    (hP : P asl = true) (hQ : Q asl = true) (hinc : ¬ (P far = true ∧ Q far = true)) :
    ¬ (Factors P w ∧ Factors Q w) :=
  fun ⟨fp, fq⟩ => hinc ⟨(fp far asl hw).trans hP, (fq far asl hw).trans hQ⟩

/-- Al-qawl bi'l-mūjab: the objector concedes what the qiyās proves and shows that it does
not reach the disputed point. -/
def QawlBiMujab (proved disputed : Wasf α) : Prop := ∃ x, proved x = true ∧ disputed x = false

theorem qawlBiMujab_defeats {proved disputed : Wasf α} (h : QawlBiMujab proved disputed) :
    ¬ ∀ x, proved x = true → disputed x = true :=
  fun hall => by obtain ⟨x, hp, hd⟩ := h; simp [hall x hp] at hd

/-- Fasād al-iʿtibār: a qiyās against a text. Text precedes qiyās (S2): with a text on the
farʿ the qiyās is not considered. -/
def farRuling (text qiyas : Option β) (tawaqquf : β) : β := resolveD [text, qiyas] tawaqquf

theorem fasad_itibar (t : β) (q : Option β) (d : β) : farRuling (some t) q d = t := rfl

/-- "No sound qiyās contradicts a sound text": a qiyās that differs from the text is never the
outcome. -/
theorem qiyas_against_text_discarded {t q : β} (hne : q ≠ t) (d : β) :
    farRuling (some t) (some q) d ≠ q := by
  rw [fasad_itibar]; exact Ne.symm hne

/-- Fasād al-waḍʿ: the waṣf is used for the opposite (σ) of the ruling the law attaches to
it. If the waṣf is the ʿilla, that opposite never follows, except for ibāḥa, the only
σ-fixed status. -/
theorem fasad_wad {H : α → Hukm} {w : Wasf α} {t far : α} {h : Hukm}
    (hf : Factors H w) (hw : w far = w t) (ht : H t = h) (hm : h ≠ .mubah) : H far ≠ Hukm.σ h := by
  rw [hf far t hw, ht]
  exact fun e => hm ((Hukm.σ_fixed_iff h).1 e.symm)

/-! ## The qiyās gate (S3) and its soundness -/

/-- An argument by qiyās, with the given cases and any text on the farʿ. -/
structure Argument (α β : Type) where
  asl : α
  far : α
  hukm : β
  illa : Wasf α
  known : Known α β
  textOnFar : Option β

/-- Conditions: the aṣl's ruling is given, the ʿilla is in the aṣl and the farʿ (taḥqīq
al-manāṭ), and no text rules the farʿ. Impediment: naqḍ. -/
def gate : Sadi.Gate (Argument α β) :=
  ⟨[fun a => (a.asl, a.hukm) ∈ a.known, fun a => a.illa a.asl = true,
    fun a => TahqiqManat a.illa a.far, fun a => a.textOnFar = none],
   [fun a => Naqd a.illa a.hukm a.known]⟩

/-- Soundness of qiyās: through the gate, every ruling that agrees with the given cases and
depends only on the ʿilla gives the farʿ the aṣl's ruling. -/
theorem qiyas_sound {a : Argument α β} (hg : gate.Holds a) {H : α → β}
    (hH : Agrees H a.known) (hf : Factors H a.illa) : H a.far = a.hukm := by
  obtain ⟨hc, _⟩ := hg
  have hk : (a.asl, a.hukm) ∈ a.known := hc (fun a => (a.asl, a.hukm) ∈ a.known) (by simp [gate])
  have ha : a.illa a.asl = true := hc (fun a => a.illa a.asl = true) (by simp [gate])
  have hfar : a.illa a.far = true := hc (fun a => TahqiqManat a.illa a.far) (by simp [gate])
  rw [hf a.far a.asl (by rw [hfar, ha])]
  exact hH _ hk

/-- Through the gate there is always such a ruling: the ʿilla is consistent with the given
cases (so the gate's naqḍ impediment is exactly what consistency needs). -/
theorem gate_consistent {a : Argument α β} (hg : gate.Holds a) (default : β) :
    ∃ H : α → β, (∀ p ∈ a.known, a.illa p.1 = true → H p.1 = p.2) ∧ Factors H a.illa ∧ H a.far = a.hukm := by
  obtain ⟨hc, hm⟩ := hg
  have hfar : a.illa a.far = true := hc (fun a => TahqiqManat a.illa a.far) (by simp [gate])
  have hn : ¬ Naqd a.illa a.hukm a.known := hm (fun a => Naqd a.illa a.hukm a.known) (by simp [gate])
  refine ⟨fun x => if a.illa x then a.hukm else default, ?_, ?_, by simp [hfar]⟩
  · intro p hp hw
    refine Classical.byContradiction fun hne => hn ⟨p, hp, hw, fun e => hne ?_⟩
    simp [hw, e]
  · intro x y hxy; simp [hxy]

end Data

end Usul.Qiyas
