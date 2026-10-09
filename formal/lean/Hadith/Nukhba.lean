import Hadith.Turuq
import Usul.Taarud

/-!
# The *Nukhba* partition tree (al-Albānī track §2.1, H2)

Ibn Ḥajar, *Nukhbat al-Fikar* with *Nuzhat al-Naẓar*: muṣṭalaḥ as nested taqāsīm. Each taqsīm
is a total function into an inductive type, so exhaustiveness and disjointness hold by
construction; what has to be proved is that each class is characterised exactly as the text
defines it (the `_iff` lemmas). Every class is quoted and linked in
`corpus/hadith/kernel_scales.json`.

* **Number of ṭuruq**: mutawātir / mashhūr / ʿazīz / gharīb; all but the first are āḥād.
  Only tawātur yields qaṭʿ (ʿilm yaqīnī); āḥād reach ẓann. The *Nukhba* also allows ʿilm
  naẓarī from āḥād with qarāʾin «على المختار»: a disputed upgrade, not encoded.
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

/-! ## 1. Number of ṭuruq -/

/-- Routes «بلا عدد معين», or `routes k` = exactly `k + 1` counted routes. -/
inductive Turuq where
  | unbounded
  | routes (k : Nat)
  deriving DecidableEq, Repr

inductive Kathra where
  | mutawatir | mashhur | aziz | gharib
  deriving DecidableEq, Repr

def kathra : Turuq → Kathra
  | .unbounded => .mutawatir
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
theorem mutawatir_iff (t : Turuq) : kathra t = .mutawatir ↔ t = .unbounded := by
  rcases t with _ | _ | _ | _ <;> simp [kathra]

/-- «وكلها سوى الأول آحاد». -/
def Ahad (t : Turuq) : Prop := kathra t ≠ .mutawatir

theorem ahad_iff (t : Turuq) : Ahad t ↔ ∃ k, t = .routes k := by
  rcases t with _ | k <;> simp [Ahad, mutawatir_iff]

/-- What a khabar yields: tawātur gives qaṭʿ; āḥād give the grade of their verdict. -/
def knowledge (t : Turuq) (v : Verdict) : Usul.Grade :=
  if kathra t = .mutawatir then .qat else v.grade

theorem knowledge_qat_iff (t : Turuq) (v : Verdict) : knowledge t v = .qat ↔ t = .unbounded := by
  unfold knowledge; rw [← mutawatir_iff]; split
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

/-- No ʿadāla-ṭaʿn is ever repaired: the text lifts only failures of ḍabṭ, status or continuity. -/
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
iʿtibār band, so `Hadith.Turuq` may lift it, but the *Nuzha* names only the mastūr. This is
recorded as an open interpretive point (roadmap §2.3), not resolved here. -/
theorem majhul_gap : ¬ Martaba.majhul.verdict.Shadid ∧ liftable (.taan .jahala) = false := by
  decide

/-! ## 5. Muʿāraḍa: the maqbūl under conflict is the uṣūl kernel's resolution order -/

/-- «فإن أمكن الجمع فمختلف الحديث، أو لا وثبت المتأخر فهو الناسخ … وإلا فالترجيح، ثم التوقف». -/
abbrev muarada {P : Type} : Usul.Conflict P → Usul.Resolution P := Usul.resolve

theorem muarada_tawaqquf_iff {P : Type} (c : Usul.Conflict P) :
    muarada c = .tawaqquf ↔ c.jam = none ∧ c.naskh = none ∧ c.tarjih = none :=
  Usul.resolve_tawaqquf_iff

end Hadith.Nukhba
