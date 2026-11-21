import Hadith.ClassicalCriteria
import Hadith.Turuq
import Usul.Taarud

/-!
# The *Nukhba* partition tree (al-Albānī track §2.1, H2)

Ibn Ḥajar, *Nukhbat al-Fikar* with *Nuzhat al-Naẓar*: muṣṭalaḥ as nested taqāsīm. Each taqsīm
is a total function into an inductive type, so exhaustiveness and disjointness hold by
construction; what has to be proved is that each class is characterised exactly as the text
defines it (the `_iff` lemmas). Every class is quoted and linked in
`corpus/hadith/kernel_scales.json`.

* **Number of ṭuruq**: reviewed tawātur, or āḥād classified by the minimum
  count through the route levels. The four tawātur conditions are explicit
  findings from the *Nuzha* (`src:openiti-nuzha-shamela1565/v01:p041–p043`).
  The certainty projection here uses the project's `Usul.Grade` scale.
  Ibn Ḥajar also allows ʿilm naẓarī from āḥād with qarāʾin under his preferred
  view. That assessment lies outside this projection.
* **Saqṭ**: position and count of the dropped narrators name the gap (muʿallaq, mursal,
  muʿḍal, munqaṭiʿ); a hidden gap is tadlīs (from one he met) or irsāl khafī (from a
  contemporary he did not meet).
* **Ṭaʿn**: ten causes «على الأشد فالأشد», five in ʿadāla and five in ḍabṭ (*Nuzha*, v01:p087).
* **Jabr**: «ومتى توبع السيء الحفظ بمعتبر … وكذا المختلط الذي لم يتميز والمستور والإسناد المرسل
  وكذا المدلس إذا لم يعرف المحذوف منه صار حديثهم حسنا» (*Nuzha*, v01:p104–105). This is the text
  the `Hadith.Turuq` lift answers to; `Martaba.cause` and the lemmas after it compare the two.
* **Muʿāraḍa**: the maqbūl under conflict is muḥkam, or else jamʿ, naskh, tarjīḥ, tawaqquf:
  exactly the uṣūl kernel's `Usul.resolve`, reused, not restated.
-/

namespace Hadith.Nukhba
open Hadith.ClassicalCriteria (Finding)

/-! ## 1. Number of ṭuruq -/

/-- Critical findings for Ibn Ḥajar's four tawātur conditions (*Nuzha*, v01:p041–p043).
`numerousEnough` concerns ordinary impossibility of agreement on falsehood.
`throughout` records that the required multiplicity persists throughout.
`impartsKnowledge` is a premise about the hearer in the source's definition. -/
structure TawaturFindings where
  numerousEnough : Finding
  throughout : Finding
  sensoryBasis : Finding
  impartsKnowledge : Finding
  deriving DecidableEq, Repr

def TawaturFindings.Established (e : TawaturFindings) : Prop :=
  e.numerousEnough = .established ∧ e.throughout = .established ∧
    e.sensoryBasis = .established ∧ e.impartsKnowledge = .established

instance (e : TawaturFindings) : Decidable e.Established := by
  unfold TawaturFindings.Established
  infer_instance

/-- A reviewed tawātur case, or an āḥād case with minimum multiplicity `k + 1`
through the levels of its isnāds. There is no prescribed numeric tawātur threshold. -/
inductive Turuq where
  | tawatur (findings : TawaturFindings) (review : findings.Established)
  | routes (k : Nat)
  deriving DecidableEq, Repr

inductive Kathra where
  | mutawatir | mashhur | aziz | gharib
  deriving DecidableEq, Repr

def kathra : Turuq → Kathra
  | .tawatur _ _ => .mutawatir
  | .routes 0 => .gharib
  | .routes 1 => .aziz
  | .routes (_ + 2) => .mashhur

theorem gharib_iff (t : Turuq) : kathra t = .gharib ↔ t = .routes 0 := by
  rcases t with _ | _ | _ | _ <;> simp [kathra]
theorem aziz_iff (t : Turuq) : kathra t = .aziz ↔ t = .routes 1 := by
  rcases t with _ | _ | _ | _ <;> simp [kathra]
/-- «مع حصر بما فوق الاثنتين». -/
theorem mashhur_iff (t : Turuq) : kathra t = .mashhur ↔ ∃ k, t = .routes (k + 2) := by
  rcases t with _ | _ | _ | k <;> simp [kathra]
theorem mutawatir_iff (t : Turuq) :
    kathra t = .mutawatir ↔ ∃ e : TawaturFindings, ∃ h : e.Established, t = .tawatur e h := by
  cases t with
  | tawatur e h => exact ⟨fun _ => ⟨e, h, rfl⟩, fun _ => rfl⟩
  | routes k =>
    constructor
    · rcases k with _ | _ | _ <;> simp [kathra]
    · rintro ⟨_, _, h⟩
      cases h

/-- «وكلها سوى الأول آحاد». -/
def Ahad (t : Turuq) : Prop := kathra t ≠ .mutawatir

theorem ahad_iff (t : Turuq) : Ahad t ↔ ∃ k, t = .routes k := by
  rcases t with _ | _ | _ | _ <;> simp [Ahad, kathra]

/-- The project's certainty projection gives qaṭʿ to certified tawātur.
Its āḥād branch reuses the grade of the supplied verdict. -/
def knowledge (t : Turuq) (v : Verdict) : Usul.Grade :=
  if kathra t = .mutawatir then .qat else v.grade

theorem knowledge_qat_iff (t : Turuq) (v : Verdict) :
    knowledge t v = .qat ↔ kathra t = .mutawatir := by
  unfold knowledge; split
  · simp_all
  · simp_all [Verdict.grade_ne_qat]

/-! ## 2. Saqṭ -/

/-- Where the drop is: at the compiler's end (*mabādiʾ*), at the end after the tābiʿī, or elsewhere. -/
inductive Place where
  | mabadi | akhir | wasat
  deriving DecidableEq, Repr

/-- A drop of `count + 1` narrators. -/
structure Saqt where
  place       : Place
  count       : Nat
  consecutive : Bool
  deriving DecidableEq, Repr

inductive SaqtName where
  | muallaq | mursal | muadal | munqati
  deriving DecidableEq, Repr

/-- «فالأول المعلق، والثاني المرسل، والثالث إن كان باثنين فصاعدا مع التوالي فهو المعضل وإلا فالمنقطع». -/
def name (s : Saqt) : SaqtName :=
  match s.place with
  | .mabadi => .muallaq
  | .akhir => .mursal
  | .wasat => if 1 ≤ s.count ∧ s.consecutive then .muadal else .munqati

theorem muadal_iff (s : Saqt) :
    name s = .muadal ↔ s.place = .wasat ∧ 2 ≤ s.count + 1 ∧ s.consecutive = true := by
  rcases s with ⟨_ | _ | _, n, _ | _⟩ <;> simp [name] <;> omega

/-- A hidden drop: from one he met is tadlīs; from a contemporary he never met, irsāl khafī;
otherwise the gap is visible from the dates (*ʿadam al-talāqī*). -/
inductive Visibility where
  | wadih | mudallas | mursalKhafi
  deriving DecidableEq, Repr

def visibility (met contemporary : Bool) : Visibility :=
  if met then .mudallas else if contemporary then .mursalKhafi else .wadih

theorem mudallas_iff (m c : Bool) : visibility m c = .mudallas ↔ m = true := by
  cases m <;> cases c <;> simp [visibility]

/-! ## 3. Ṭaʿn: ten causes, most severe first -/

inductive Taan where
  | kadhib | tuhma | fuhshGhalat | ghafla | fisq | wahm | mukhalafa | jahala | bida | suHifz
  deriving DecidableEq, Repr

namespace Taan

def all : List Taan := [kadhib, tuhma, fuhshGhalat, ghafla, fisq, wahm, mukhalafa, jahala, bida, suHifz]

/-- Position in the *Nukhba*'s order: 1 is the most severe («على الأشد فالأشد»). -/
def severity : Taan → Nat
  | kadhib => 1 | tuhma => 2 | fuhshGhalat => 3 | ghafla => 4 | fisq => 5
  | wahm => 6 | mukhalafa => 7 | jahala => 8 | bida => 9 | suHifz => 10

/-- Causes in ʿadāla (the rest are in ḍabṭ). -/
def adala : Taan → Bool
  | kadhib | tuhma | fisq | jahala | bida => true
  | _ => false

theorem all_complete (t : Taan) : t ∈ all := by cases t <;> simp [all]
theorem severity_injective {a b : Taan} (h : a.severity = b.severity) : a = b := by
  cases a <;> cases b <;> simp_all [severity]
theorem severity_is_order : all.map severity = List.range' 1 10 := by decide
/-- «خمسة منها تتعلق بالعدالة، وخمسة تتعلق بالضبط». -/
theorem five_and_five : (all.filter adala).length = 5 ∧ (all.filter (!adala ·)).length = 5 := by
  decide

end Taan

/-! ## 4. Jabr: which weaknesses a muʿtabar follower repairs -/

/-- A cause of weakness: a ṭaʿn, the mastūr (majhūl al-ḥāl, named apart from `jahala`), a
gap, or tadlīs with the omitted narrator unknown. -/
inductive Cause where
  | taan (t : Taan)
  | mastur
  | saqt (s : SaqtName)
  | tadlis
  deriving DecidableEq, Repr

/-- The *Nuzha*'s list, verbatim in scope: sūʾ al-ḥifẓ (with the unsorted mukhtaliṭ), the
mastūr, the mursal, the mudallas. Nothing else is named. -/
def liftable : Cause → Bool
  | .taan .suHifz | .mastur | .saqt .mursal | .tadlis => true
  | _ => false

/-- The jabr criterion in this passage of the *Nuzha*, v01:p104–p105.
The second input is a finding of a matching muʿtabar follower, whose standing
is at least that of the transmitter followed. It comes from route comparison. -/
def jabr (c : Cause) (qualifiedFollower : Finding) : Bool :=
  liftable c && decide (qualifiedFollower = .established)

theorem jabr_iff (c : Cause) (f : Finding) :
    jabr c f = true ↔ liftable c = true ∧ f = .established := by
  simp [jabr]

/-- The listed classes in this passage exclude ʿadāla-ṭaʿn. -/
theorem not_liftable_of_adala {t : Taan} (h : t.adala = true) : liftable (.taan t) = false := by
  cases t <;> simp_all [Taan.adala, liftable]

/-- The cause behind each *Taqrīb* martaba below the ḥujja band, where the wording names one
(`daif` and `maqbul` name none: «ḍaʿīf» is unexplained, «maqbūl» is a status). -/
def _root_.Hadith.Martaba.cause : Martaba → Option Cause
  | .saduqYahim => some (.taan .suHifz)
  | .mastur => some .mastur
  | .majhul => some (.taan .jahala)
  | .matruk | .muttaham => some (.taan .tuhma)
  | .kadhdhab => some (.taan .kadhib)
  | _ => none

/-- Soundness of the kernel's bands against the *Nuzha*: every martaba whose cause the text
lifts sits in the iʿtibār band (neither ḥujja nor shadīd). -/
theorem liftable_in_itibar (m : Martaba) (c : Cause) (hc : m.cause = some c)
    (hl : liftable c = true) : ¬ m.verdict.Hujja ∧ ¬ m.verdict.Shadid := by
  cases m <;> simp_all [Martaba.cause] <;> subst hc <;> simp_all [liftable] <;> decide

/-- …and every martaba whose cause is an ʿadāla-ṭaʿn of kadhib or tuhma is shadīd. -/
theorem kadhib_tuhma_shadid (m : Martaba) (t : Taan) (hc : m.cause = some (.taan t))
    (ht : t = .kadhib ∨ t = .tuhma) : m.verdict.Shadid := by
  rcases ht with rfl | rfl <;> cases m <;> simp [Martaba.cause] at hc <;> decide

/-- **Where the kernel is wider than the text.** Majhūl al-ʿayn (martaba 9) is in the kernel's
iʿtibār band, so `Hadith.Turuq` may lift it, but the *Nuzha* names only the mastūr.
**Decision (2026-10-09, project owner): kept repairable.** The kernel follows *Tamām al-Minna*
Q10, which withholds repair only for «تهمة في صدقهم أو دينهم»; unknown status is not tuhma.
The theorem stays as the standing record that this goes beyond the *Nuzha*'s list
(roadmap §2.3, decision D1). -/
theorem majhul_gap : ¬ Martaba.majhul.verdict.Shadid ∧ liftable (.taan .jahala) = false := by
  decide

/-! ## 5. Muʿāraḍa: the maqbūl under conflict is the uṣūl kernel's resolution order -/

/-- «فإن أمكن الجمع فمختلف الحديث، أو لا وثبت المتأخر فهو الناسخ … وإلا فالترجيح، ثم التوقف». -/
abbrev muarada {P : Type} : Usul.Conflict P → Usul.Resolution P := Usul.resolve

theorem muarada_tawaqquf_iff {P : Type} (c : Usul.Conflict P) :
    muarada c = .tawaqquf ↔ c.jam = none ∧ c.naskh = none ∧ c.tarjih = none :=
  Usul.resolve_tawaqquf_iff

end Hadith.Nukhba
