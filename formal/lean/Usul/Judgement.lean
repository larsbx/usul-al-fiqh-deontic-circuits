import Usul.Signature
import Usul.Qawaid

/-!
# The judgement form (roadmap §2.1, `Γ ⊢ d : H(a, s) @ g`)

What a question asks, and what an answer must carry to be compared with another.

* **The khiṭāb.** The ḥukm is «ما اقتضاه خطاب الشرع المتعلق بأفعال المكلفين من طلب، أو تخيير، أو
  وضع» (Ibn ʿUthaymīn, *al-Uṣūl*, h002). A taklīfī question is answered by a `Hukm`, and
  `Hukm.mode` fixes the khiṭāb it falls under: takhyīr exactly for ibāḥa (h007), ṭalab for the
  other four (h003–h006). A waḍʿī question asks about a sign the Lawgiver posits (p013): whether
  something is a sabab, a sharṭ or a māniʿ, or whether an act is ṣaḥīḥ or fāsid, that is, whether
  its effects follow (h008, h009). Liability (ḍamān) is not a kind of its own: it is the effect of a
  sabab, a destruction or a wrongful hand, and is asked as `wadi .sabab`.
* **The dalīl.** Fiqh is «معرفة الأحكام الشرعية العملية بأدلتها التفصيلية» (h001): a judgement
  names the kinds of dalīl it rests on, and one that names none is not well-typed.
* **The subject.** Taklīf conditions the taklīfī judgement only. «خطاب الوضع» attaches to the acts
  of those not under taklīf (Ibn al-Laḥḥām, qāʿida 2), as the child's destruction is a sabab of
  liability in his wealth.
* **The grade.** A judgement is held at a `Grade`, as `Qawaid.Held` (IQ-21).

Two judgements are comparable only when they answer the same question about the same act and
subject (`Conflicts`). Only then is tarjīḥ between them in point.
-/

namespace Usul

/-- The three things a khiṭāb does: demand, give the choice, or posit (h002). -/
inductive Khitab where
  | talab | takhyir | wad
  deriving DecidableEq, Repr

/-- The khiṭāb a taklīfī status answers. -/
def Hukm.khitab (h : Hukm) : Khitab :=
  match h.mode with
  | .takhyir => .takhyir
  | _ => .talab

theorem Hukm.khitab_takhyir_iff (h : Hukm) : h.khitab = .takhyir ↔ h = .mubah := by
  cases h <;> decide

theorem Hukm.khitab_talab_iff (h : Hukm) : h.khitab = .talab ↔ h ≠ .mubah := by
  cases h <;> decide

/-- No taklīfī status is a posited sign. -/
theorem Hukm.khitab_ne_wad (h : Hukm) : h.khitab ≠ .wad := by
  cases h <;> decide

/-- An act and its omission answer the same khiṭāb. -/
theorem Hukm.khitab_σ (h : Hukm) : (σ h).khitab = h.khitab := by
  cases h <;> rfl

/-- The domain defaults (al-aṣl) answer different khiṭābs: choice in ʿādāt, demand in ʿibādāt. -/
theorem Domain.default_khitab : Domain.ada.default.khitab = .takhyir ∧ Domain.ibada.default.khitab = .talab :=
  ⟨rfl, rfl⟩

/-- Validity (h008, h009): an act is ṣaḥīḥ when its effects follow, fāsid when they do not. -/
inductive Validity where
  | sahih | fasid
  deriving DecidableEq, Repr

namespace Validity

def effectsFollow : Validity → Bool
  | sahih => true
  | fasid => false

def ofEffects (b : Bool) : Validity := if b then sahih else fasid

theorem ofEffects_effectsFollow (v : Validity) : ofEffects v.effectsFollow = v := by
  cases v <;> rfl

theorem effectsFollow_ofEffects (b : Bool) : (ofEffects b).effectsFollow = b := by
  cases b <;> rfl

end Validity

/-- The posited signs a waḍʿī question asks about (p013). -/
inductive Sign where
  | sabab | shart | mani | validity
  deriving DecidableEq, Repr

/-- A sabab, sharṭ or māniʿ holds or not; validity is ṣaḥīḥ or fāsid. -/
def Sign.Value : Sign → Type
  | .validity => Validity
  | .sabab | .shart | .mani => Bool

instance (s : Sign) : DecidableEq s.Value := by
  cases s <;> unfold Sign.Value <;> infer_instance

/-- What a question asks: the act's taklīfī status, or a posited sign. -/
inductive Question where
  | taklifi
  | wadi (s : Sign)
  deriving DecidableEq, Repr

/-- The type of an answer to each question. -/
def Question.Answer : Question → Type
  | .taklifi => Hukm
  | .wadi s => s.Value

instance (q : Question) : DecidableEq q.Answer := by
  cases q <;> unfold Question.Answer <;> infer_instance

/-- The khiṭāb an answer falls under. -/
def Question.khitab : (q : Question) → q.Answer → Khitab
  | .taklifi, h => Hukm.khitab h
  | .wadi _, _ => .wad

/-- The three-way split of h002 is exhaustive over answers, and waḍʿ is exactly the waḍʿī
questions. -/
theorem Question.khitab_wad_iff (q : Question) (a : q.Answer) : q.khitab a = .wad ↔ q ≠ .taklifi := by
  cases q with
  | taklifi => exact ⟨fun h => absurd h (Hukm.khitab_ne_wad a), fun h => absurd rfl h⟩
  | wadi s => exact ⟨fun _ => nofun, fun _ => rfl⟩

/-- Liability (ḍamān) is asked as a sabab: is this destruction or this hand a sabab of it? -/
def Question.daman : Question := .wadi .sabab

/-- A yes/no question about a taklīfī status. «يجوز» asks whether the act is permitted, that is, not
forbidden; «يجب» asks whether it is obligatory. Each answer is a projection of the status, so it is a
taklīfī question and needs a mukallaf like any other. -/
inductive Aspect where
  | obligatory | permitted
  deriving DecidableEq, Repr

def Aspect.holds : Aspect → Hukm → Bool
  | .obligatory, h => h == .wajib
  | .permitted, h => h != .haram

theorem Aspect.permitted_iff (h : Hukm) : Aspect.permitted.holds h = true ↔ h ≠ .haram := by
  cases h <;> decide

/-- What is obligatory is permitted. -/
theorem Aspect.obligatory_permitted (h : Hukm) (o : Aspect.obligatory.holds h = true) :
    Aspect.permitted.holds h = true := by
  cases h <;> simp_all [Aspect.holds]

/-- The aspects agree with the status of the omission: the omission of an obligatory act is not
permitted. -/
theorem Aspect.omission_of_obligatory (h : Hukm) (o : Aspect.obligatory.holds h = true) :
    Aspect.permitted.holds (Hukm.σ h) = false := by
  cases h <;> simp_all [Aspect.holds, Hukm.σ]

/-- A judgement: the answer to a question about an act and a subject, in a domain, held at a grade
on named kinds of dalīl. -/
structure Judgement (Act : Type) where
  question : Question
  act : Act
  subject : Subject
  domain : Domain
  answer : question.Answer
  grade : Grade
  rujhanKnown : Bool
  dalil : List DalilKind

namespace Judgement

variable {Act : Type}

def khitab (j : Judgement Act) : Khitab := j.question.khitab j.answer

/-- The answer as held, with its grade (`Qawaid.Held`). -/
def held (j : Judgement Act) : Qawaid.Held j.question.Answer := ⟨j.answer, j.grade, j.rujhanKnown⟩

/-- Well-typed: it rests on some dalīl (h001), and a taklīfī answer is addressed to a mukallaf. -/
def WellTyped (j : Judgement Act) : Prop :=
  j.dalil ≠ [] ∧ (j.question = .taklifi → j.subject.IsMukallaf)

instance (j : Judgement Act) : Decidable j.WellTyped := by
  unfold WellTyped; infer_instance

theorem no_dalil_ill_typed (j : Judgement Act) (h : j.dalil = []) : ¬ j.WellTyped :=
  fun w => w.1 h

theorem taklifi_needs_mukallaf {j : Judgement Act} (w : j.WellTyped) (h : j.question = .taklifi) :
    j.subject.IsMukallaf :=
  w.2 h

/-- Khiṭāb al-waḍʿ reaches those not under taklīf: a waḍʿī judgement about a non-mukallaf is
well-typed as soon as it names a dalīl. -/
theorem wadi_without_taklif (j : Judgement Act) (s : Sign) (hq : j.question = .wadi s)
    (hd : j.dalil ≠ []) : j.WellTyped :=
  ⟨hd, fun h => by rw [hq] at h; exact nomatch h⟩

/-- Two judgements conflict when they answer the same question about the same act and subject
differently. -/
def Conflicts (j k : Judgement Act) : Prop :=
  ∃ h : j.question = k.question, j.act = k.act ∧ j.subject = k.subject ∧ h ▸ j.answer ≠ k.answer

/-- Answers to different questions never conflict: a waḍʿī answer does not contradict a taklīfī
one, nor validity a sabab. -/
theorem not_conflicts_of_question_ne {j k : Judgement Act} (h : j.question ≠ k.question) :
    ¬ j.Conflicts k :=
  fun ⟨e, _⟩ => h e

end Judgement
end Usul
