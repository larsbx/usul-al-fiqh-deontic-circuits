import Usul.Muamalat
import Usul.Qawaid
import Usul.Kulliyyat
import Usul.Dalala

/-!
# Refinements driven by the takhrīj suite (the bank applied to itself)

Each refinement adds the input whose absence an M4 case exposed, with a default that gives the
earlier reading back exactly (`*_conservative`). So no earlier result changes, and the cases
that needed the input can now be encoded faithfully. A refinement does not decide the related
register question; it makes the alternatives expressible.

* **Lots** (gap `fact:confusion_category`; Ibn Rajab 160's second clause: lots also «distinguish
  the entitled person, specific in fact, from his confusion»): a confused specific entitlement
  goes to lots even when the thing is divisible. Related: IQ-09.
* **Recourse** (gaps `fact:owed_by_other`, `fact:permission`; Ibn Rajab 75's two types):
  recourse for paying what another owed, or for spending by permission, unless given as a gift.
* **The unknown as non-existent** (gap `rule:unknown_as_nonexistent`; Ibn Rajab 106).
* **Reading toward the lowest** (gap `rule:haml_ala_adna`; Ibn al-Laḥḥām 52.f008, grounded in
  Aḥmad's naṣṣ that the least the name covers is due «because it is the certain»).
* **Voidance of trust** (gap `rule:trust_voidance`; Ibn Rajab 45).
* **Recourse when permission cannot be sought** (gap `fact:permission_unobtainable`; Ibn Rajab 75).
* **Abstention while a divorce condition may have occurred** (gap
  `rule:abstention_under_possible_condition`; Taqī al-Dīn on Aḥmad's texts, cited by Ibn Rajab).
* **Round 4** (the open gaps' own texts): ghulūl forfeiture (Ibn Rajab 140.f006), the right for
  and against oneself after denial (Ibn al-Laḥḥām 54.f002), tie-breaks among fayʾ recipients (Ibn
  Rajab 160.f038), luqaṭa (106.f002), the forgotten iḥrām (106.f007), the command after ṣarf
  (Ibn al-Laḥḥām 43.f005) and the command over mixed items (43.f006).
* **Ẓann and ʿilm** (register IQ-21, no takhrīj gap): the knowledge acted on is knowledge
  *that* a view preponderates (Ibn Taymiyya: «اعتقاد الرجحان» is ʿilm, «رجحان الاعتقاد» is ẓann);
  bayt 90 of Ibn ʿUthaymīn's manẓūma, «وإن تعذر اليقين فارجعا لغالب الظن»; and «لا عبرة بالظن البين
  خطؤه» limited by «الاجتهاد لا ينقض بالاجتهاد».
* **Aṣl and ẓāhir** (gap `fact:amara`; Ibn Rajab 159, «because time has indicators by which it
  is known, unlike what has no indicator: completing prayer, purity, ḥadath»): on equal grades
  the ẓāhir prevails only where the matter has indicators. Related: IQ-20.
-/

namespace Usul.Refinements

open Usul Usul.Muamalat

/-! ## Lots -/

def allocationFull (entitledKnown divisible confused : Bool) : Allocation :=
  if entitledKnown then .toEntitled else if confused then .lot else allocation false divisible

theorem allocationFull_conservative (k d : Bool) : allocationFull k d false = allocation k d := by
  cases k <;> cases d <;> rfl

/-- A confused specific entitlement goes to lots whatever the divisibility. -/
theorem confused_goes_to_lot (d : Bool) : allocationFull false d true = .lot := by
  cases d <;> rfl

/-! ## Recourse -/

def recourseFull (gift owedByOther permission : Bool) : Bool :=
  !gift && (owedByOther || permission)

/-- Q32's subject is paying what another owed: there the refinement is the old reading. -/
theorem recourseFull_conservative (g p : Bool) : recourseFull g true p = decide (0 < recourse g 1) := by
  cases g <;> cases p <;> rfl

theorem no_recourse_unowed_unpermitted (g : Bool) : recourseFull g false false = false := by
  cases g <;> rfl

/-! ## Aṣl and ẓāhir -/

/-- The ẓāhir prevails when strictly stronger, or equal and the matter has indicators. -/
def zahirPrevails (asl zahir : Grade) (amara : Bool) : Bool :=
  decide (asl < zahir) || (decide (asl.rank = zahir.rank) && amara)

/-- With indicators assumed, this is `Qawaid.update`'s choice. -/
theorem zahirPrevails_conservative (a z : Grade) :
    zahirPrevails a z true = ((Qawaid.update (⟨0, a, true⟩ : Qawaid.Held Nat) ⟨1, z, true⟩).value == 1) := by
  cases a <;> cases z <;> decide

/-- Without indicators, equal grades keep the aṣl (Ibn Rajab 159, f007). -/
theorem tie_without_amara_keeps_asl (g : Grade) : zahirPrevails g g false = false := by
  cases g <;> decide

/-- A stronger ẓāhir prevails with or without indicators (a sharʿī proof). -/
theorem stronger_prevails {a z : Grade} (h : a < z) (m : Bool) : zahirPrevails a z m = true := by
  simp [zahirPrevails, h]

/-! ## The unknown as non-existent (Ibn Rajab 106)

«ينزل المجهول منزلة المعدوم وإن كان الأصل بقاءه إذا يئس من الوقوف عليه أو شق اعتباره»: the
unknown is treated as non-existent, even though its continuation is the presumption, when one
despairs of learning it or taking it into account is a hardship. -/

def treatedAsAbsent (unknown despair hardship : Bool) : Bool := unknown && (despair || hardship)

/-- Al-Saʿdī's Q20 (an unidentifiable right-holder is treated as non-existent) is the instance
where one despairs of identifying him. -/
theorem q20_is_instance (identifiable : Bool) :
    recipient identifiable =
      if treatedAsAbsent (!identifiable) true false then .publicInterest else .owner := by
  cases identifiable <;> rfl

/-- An unknown one may still hope to learn, at no hardship, is not set aside (the beginner's
doubtful days, which «become clear by repetition soon»). -/
theorem knowable_not_set_aside : treatedAsAbsent true false false = false := rfl

/-! ## Reading toward the lowest (ḥaml ʿalā al-adnā)

Ibn al-Laḥḥām 52.f008: a tayammum intended for «al-ṣalāt» unspecified covers only the
supererogatory, «تنزيلا له على الأدنى» (the more widely held view among the companions). Its
ground is Aḥmad's naṣṣ on a bequest of «a slave» from several: «له أخسهم يعني أدنى ما يقع عليه
الاسم لأنه المتيقن» (Ibn Rajab, on qāʿida 160). -/

/-- An unspecified intention over referents that differ in rank is read as the lowest. -/
def hamlAlaAdna (unspecified ranked : Bool) : Bool := unspecified && ranked

/-- Why the lowest: if covering a level covers every level beneath it, the lowest of the
candidate levels is covered whichever was meant. It is the certain (al-mutayaqqan, cf. Q11). -/
theorem adna_is_certain (covers : Nat → Nat → Bool)
    (mono : ∀ l k, k ≤ l → covers l k = true) (levels : List Nat) (lo : Nat)
    (hlo : ∀ l ∈ levels, lo ≤ l) : ∀ l ∈ levels, covers l lo = true :=
  fun l hl => mono l lo (hlo l hl)

/-! ## Voidance of trust (Ibn Rajab 45)

«المذهب أن الأمانة المحضة تبطل بالتعدي والأمانة المتضمنة لأمر آخر لا تبطل على الصحيح»: a pure
trust is voided by transgression; a trust that includes something else is not. -/

def trustVoided (pure transgressed : Bool) : Bool := pure && transgressed

theorem compound_trust_survives (t : Bool) : trustVoided false t = false := by cases t <;> rfl

/-- Voidance is about the contract; liability for loss (Q14) follows transgression either way. -/
theorem liability_independent_of_voidance (pure : Bool) :
    lossLiable .trustee true false = true ∧ trustVoided pure true = pure := by
  cases pure <;> exact ⟨rfl, rfl⟩

/-! ## Recourse when permission cannot be sought (Ibn Rajab 75.f006)

«الحيوان المودع إذا أنفق عليه المستودع ناويا للرجوع فإن تعذر استئذان مالكه رجع»; the ground
given for the judge's permission, «إذنه قائم مقام إذن الغائب», extends to necessity. -/

def recourseNec (gift owedByOther permission unobtainable : Bool) : Bool :=
  recourseFull gift owedByOther (permission || unobtainable)

theorem recourseNec_conservative (g o p : Bool) : recourseNec g o p false = recourseFull g o p := by
  cases p <;> simp [recourseNec]

/-! ## Abstention while a divorce condition may have occurred

Taqī al-Dīn on Aḥmad's texts (Ibn Rajab, on qāʿida 160): «وحاصله أنه متى علق الطلاق بشرط وأمكن
وجوده فإنه يعتزل امرأته حتى يعلم انتفاؤه». The marriage is not judged dissolved: the husband «is
certain of his wife's lawfulness, doubting her prohibition». Abstention governs conduct, not
status. -/

def abstains (suspended possible absenceKnown : Bool) : Bool := suspended && possible && !absenceKnown

/-- The status is untouched: a doubt about the condition (shakk) does not displace the certain
marriage (Q11); abstention is a separate rule of conduct. -/
theorem abstention_keeps_status {V : Type} (marriage : Qawaid.Held V) (hy : marriage.IsYaqin)
    (doubt : Qawaid.Held V) (hs : doubt.grade = .shakk) :
    Qawaid.update marriage doubt = marriage ∧ abstains true true false = true :=
  ⟨Qawaid.yaqin_la_yazul_bish_shakk marriage doubt hy hs, rfl⟩

theorem known_absence_ends_abstention (p : Bool) : abstains true p true = false := by cases p <;> rfl

/-! ## Ẓann and ʿilm (IQ-21)

Ibn Taymiyya (Majmūʿ v13 p117): «فرق بين اعتقاد الرجحان ورجحان الاعتقاد أما اعتقاد الرجحان فهو علم
… وأما رجحان هذا الاعتقاد على هذا الاعتقاد فهو الظن». A ẓann grounds action as knowledge only when
its preponderance is itself known on a dalīl; where it is not, «فهو متوقف لا قول له». -/

/-- Certainty for acting: qaṭʿ, or a ẓann whose preponderance is known (second-order ʿilm). -/
def yaqinForAmal (g : Grade) (rujhanKnown : Bool) : Bool :=
  g == .qat || (g == .zann && rujhanKnown)

/-- Conservative: with preponderance known, it is the kernel's `IsYaqin`. -/
theorem yaqinForAmal_conservative (g : Grade) : yaqinForAmal g true = decide g.IsYaqin := by
  cases g <;> decide

/-- The Boolean form of the adopted kernel reading `Grade.YaqinFor`. -/
theorem yaqinForAmal_iff (g : Grade) (k : Bool) : yaqinForAmal g k = decide (g.YaqinFor k) := by
  cases g <;> cases k <;> decide

/-- A ẓann whose preponderance is not known grounds nothing: suspension (tawaqquf). -/
theorem unknown_rujhan_suspends : yaqinForAmal .zann false = false := rfl

/-- Qaṭʿ needs no second-order knowledge. -/
theorem qat_suffices (k : Bool) : yaqinForAmal .qat k = true := by cases k <;> rfl

/-- What one builds on (bayt 90, «إذا تعذر اليقين رجعنا إلى غلبة الظن»): certainty where attainable,
else ghalabat al-ẓann where there is one, else the aṣl («وإن لم يكن غلبة ظن رجعنا إلى الأصل»). -/
inductive Basis where
  | yaqin | ghalabatZann | asl
  deriving DecidableEq, Repr

def basis (yaqinAttainable ghalaba : Bool) : Basis :=
  if yaqinAttainable then .yaqin else if ghalaba then .ghalabatZann else .asl

/-- Where certainty is attainable, a preponderant belief is not consulted (the manẓūma's
example: certain of purity, believing a ḥadath, he stays on purity). -/
theorem attainable_yaqin_excludes_ghalaba (g : Bool) : basis true g = .yaqin := by cases g <;> rfl

/-- The order is S2's: `basis` is `resolveD` over [yaqīn, ghalaba] with the aṣl as default. -/
theorem basis_is_first (y g : Bool) :
    basis y g = Schema.resolveD [if y then some .yaqin else none, if g then some .ghalabatZann else none] .asl := by
  cases y <;> cases g <;> rfl

/-- «لا عبرة بالظن البين خطؤه» (al-Mardāwī, al-Taḥbīr v2 p917), with its limit «الاجتهاد لا ينقض
بالاجتهاد»: a ẓann acted on is set aside when its error becomes evident by what is decisive, not by
a second ijtihād («فبان خطؤه بدليل قاطع», al-Musawwada p522). Domains where even a certain error
leaves the act standing (qibla, zakāt to one believed poor) are an exemption. -/
def zannSetAside (errorShownBy : Grade) (exempt : Bool) : Bool := errorShownBy == .qat && !exempt

theorem ijtihad_not_overturned_by_ijtihad (e : Bool) : zannSetAside .zann e = false := by
  cases e <;> rfl

theorem evident_error_sets_aside : zannSetAside .qat false = true := rfl

/-! ## Round 4: the open gaps' own principles -/

/-! ### Ghulūl (Ibn Rajab 140.f006)

«فيجتمع عليه غرم ما سرقه مع حرمان سهمه المستحق منها، وقد يكون قدر السرقة وأقل وأكثر»: on the
riwāya that theft from booty is ghulūl, the thief owes the theft once and forfeits his share. -/

/-- What a thief from the booty bears: the theft once, plus his share when it counts as ghulūl. -/
def bootyTheftBurden (theft share : Nat) (asGhulul : Bool) : Nat :=
  Muamalat.compensationOwed theft false + if asGhulul then share else 0

/-- Whether the share is forfeited. -/
def ghululForfeits (asGhulul : Bool) : Bool := asGhulul

/-- Not Q35's doubling: the aggravation may be less than, equal to or more than the theft. -/
theorem ghulul_is_not_doubling (theft : Nat) (h : 0 < theft) :
    bootyTheftBurden theft 0 true < 2 * theft ∧ bootyTheftBurden theft theft true = 2 * theft ∧
      2 * theft < bootyTheftBurden theft (theft + 1) true := by
  simp only [bootyTheftBurden, Muamalat.compensationOwed, if_true, Bool.false_eq_true, if_false]
  omega

/-! ### A right for or against oneself after denying it (Ibn al-Laḥḥām 54.f002)

«والفرق بين النصين أن الشهادة حق عليه فتسمع بعد النفي كما لو أقر بالحق بعد جحوده والبينة حق له
فلا تسمع كما لو ادعى الحق بعد أن نفاه». -/

/-- After denying it, a right *for* the speaker is not heard; a right *against* him is. -/
def heardAfterDenial (forHimself : Bool) : Bool := !forHimself

/-- The ground for the second half is Q55: a confession after any denial binds. -/
theorem against_self_like_confession (pre post : List Muamalat.Plea) :
    heardAfterDenial false = true ∧ (pre ++ .confess :: post).foldl Muamalat.plead false = true :=
  ⟨rfl, Muamalat.q55_confession_absorbs pre post⟩

/-! ### Tie-breaks among fayʾ recipients (Ibn Rajab 160.f038)

Equal in rank: ordered by criteria (al-Mujarrad: age, then hijra; al-Aḥkām al-Sulṭāniyya:
precedence in Islam, religion, age, courage), «ثم ولي الأمر مخير إن شاء أقرع بينهما وإن شاء
رتبهما على رأيه واجتهاده». -/

inductive TieBreak where
  | byCriteria | rulerChoice
  deriving DecidableEq, Repr

/-- The first criterion on which they differ decides; if none, the ruler chooses (S2). -/
def fayTieBreak (differs : List Bool) : TieBreak :=
  Schema.resolveD (differs.map fun d => if d then some .byCriteria else none) .rulerChoice

/-- Here lots are optional: the ruler may lot or rank by ijtihād, unlike a confused specific
entitlement, where lots are owed (`confused_goes_to_lot`). -/
def rulerMayLot : TieBreak → Bool
  | .rulerChoice => true
  | .byCriteria => false

theorem equal_on_all_criteria (n : Nat) : fayTieBreak (List.replicate n false) = .rulerChoice := by
  induction n with
  | zero => rfl
  | succ n ih => simpa [fayTieBreak, Schema.resolveD, Schema.first, List.replicate] using ih

/-! ### Luqaṭa (Ibn Rajab 106.f002)

«اللقطة بعد الحول فإنها تتملك لجهالة ربها وما لا يتملك منها يتصدق به عنه على الصحيح». -/

inductive LuqataOutcome where
  | hold | finderOwns | charity
  deriving DecidableEq, Repr

def luqata (yearPassed ownable : Bool) : LuqataOutcome :=
  if !yearPassed then .hold else if ownable then .finderOwns else .charity

/-- It is an instance of qāʿida 106: after the year of announcement the owner, still unknown,
is treated as absent (despair of learning him). -/
theorem luqata_is_instance (ownable : Bool) :
    luqata true ownable ≠ .hold ∧ treatedAsAbsent true true false = true := by
  cases ownable <;> exact ⟨by decide, rfl⟩

/-! ### The forgotten iḥrām (Ibn Rajab 106.f007)

Specified as qirān, it suffices for the ḥajj; for the ʿumra «أشهرهما عند المتأخرين لا يجزئه لجواز
أن يكون أحرم بحج أو لا، ثم أدخل عليه العمرة»; the second view: it suffices, «تنزيلا للمجهول
كالمعدوم». -/

inductive Nusuk where
  | ifrad | tamattu | qiran
  deriving DecidableEq, Repr

def Nusuk.all : List Nusuk := [.ifrad, .tamattu, .qiran]

/-- What suffices under a forgotten intention: what is valid on every possibility. -/
def validOnEvery {P : Type} (valid : P → Bool) (ps : List P) : Bool := ps.all valid

def hajjValid : Nusuk → Bool := fun _ => true

/-- Adding the ʿumra to a ḥajj already begun (ifrād first) does not make a valid ʿumra. -/
def umraValid : Nusuk → Bool
  | .ifrad => false
  | _ => true

theorem forgotten_ihram :
    validOnEvery hajjValid Nusuk.all = true ∧ validOnEvery umraValid Nusuk.all = false := ⟨rfl, rfl⟩

/-- The second view: the unknown ifrād possibility treated as absent, the ʿumra suffices. -/
theorem second_view_by_treated_as_absent :
    validOnEvery umraValid (Nusuk.all.filter (· != .ifrad)) = true := rfl

/-! ### The command after ṣarf (Ibn al-Laḥḥām 43.f005)

Abū al-Ṭayyib, and al-Tamīmī among the Ḥanbalīs: «اللفظ موضوع لإفادة الوجوب دون الجواز وإنما
الجواز تبع للوجوب… فإذا سقط الوجوب سقط التابع له». That is Q50 (`Kulliyyat.established`): the
jawāz has no independent proof in the wording and follows the wujūb. -/

/-- Whether the command still proves permissibility once its obligation is turned away. -/
def jawazAfterSarf (sarf : Bool) : Bool := Kulliyyat.established false (!sarf)

theorem sarf_removes_jawaz : jawazAfterSarf true = false := rfl

/-! ### A command over mixed items (Ibn al-Laḥḥām 43.f006)

«وافعلوا الخير», «دع ما يريبك». Ibn ʿAbd al-Salām: obligation, specified by the recommended items;
Abū al-ʿAbbās: «أريد به الواجب في الواجبات والمستحب في المستحبات». -/

/-- Abū al-ʿAbbās's reading: each item takes its own status. -/
def amrPerItem {α : Type} (status : α → Hukm) (x : α) : Hukm := status x

/-- Ibn ʿAbd al-Salām's reading: obligation, with the recommended items specified out. -/
def amrByTakhsis {α : Type} (status : α → Hukm) : Dalala.Takhsis α :=
  ⟨fun _ => true, fun x => status x == .mandub, .wajib, .mandub⟩

/-- The two readings give the same ruling on every item; they differ only in what the word
means, not in what it rules. -/
theorem mixed_readings_agree {α : Type} (status : α → Hukm)
    (h : ∀ x, status x = .wajib ∨ status x = .mandub) (x : α) :
    (amrByTakhsis status).ruling x = some (amrPerItem status x) := by
  rcases h x with hx | hx <;>
    simp [amrByTakhsis, amrPerItem, Dalala.Takhsis.ruling, Schema.first, hx]

/-! ## M8, first tranche: readings of Ibn Rajab's qawāʿid 6, 22 and 68 -/

/-! ### Qāʿida 6: an act done on a belief later shown wrong

«إذا فعل عبادة في وقت وجوبها يظن أنها الواجبة عليه ثم تبين بآخرة أن الواجب كان غيرها فإنه
يجزئه»; joined to it: «ما إذا خفي الاطلاع على خلل الشرط ثم تبين، فإنه يغتفر في الأصح». Its
limits: a judge's ruling is undone «لتعلق حق الغير به», and repetition falls on one who «فرط بترك
البحث والتحقيق». -/

/-- The act stands despite the error, unless another's right is attached or he was negligent. -/
def errorExcused (othersRight negligent : Bool) : Bool := !othersRight && !negligent

/-- Qāʿida 6 grounds `zannSetAside`'s exemption: a decisively shown error sets the act aside
exactly when another's right is attached or he was negligent. -/
theorem q6_grounds_exemption (o n : Bool) : zannSetAside .qat (errorExcused o n) = (o || n) := by
  cases o <;> cases n <;> rfl

/-! ### Qāʿida 22: what is consumed in another

«العين المنغمرة في غيرها إذا لم يظهر أثرها فهل هي كالمعدومة حكما أو لا؟ فيه خلاف». The reading
takes one side: consumed without trace, it is treated as non-existent. -/

/-- One side of the khilāf, as an instance of qāʿida 106: its trace cannot be found. -/
def istihlak (consumed : Bool) : Bool := treatedAsAbsent consumed true false

theorem istihlak_iff (c : Bool) : istihlak c = c := by cases c <;> rfl

/-! ### Qāʿida 68: acting while doubting a condition of validity

«أحدهما ما يشترط فيه النية الجازمة فلا يصح إيقاعه بهذا التردد ما لم يكن الشك غلبة ظن تكفي
مثله»; and where he «بني على أصل لم يثبت زواله» the hesitation does not harm; «والنوع الثاني ما
لا يحتاج إلى نية جازمة فالصحيح فيه الصحة». -/

def validUnderDoubt (needsFirm ghalaba aslMustashab : Bool) : Bool :=
  !needsFirm || ghalaba || aslMustashab

/-- Where firmness is needed, what makes it firm is a basis the bank already has: ghalabat
al-ẓann (bayt 90's `basis`) or a presumption that has not been shown to end. -/
theorem firm_by_basis (g a : Bool) :
    validUnderDoubt true g a = ((basis false g == .ghalabatZann) || a) := by
  cases g <;> cases a <;> rfl

theorem no_firmness_needed (g a : Bool) : validUnderDoubt false g a = true := rfl

/-! ## M8, second tranche: Ibn Rajab's qawāʿid 7, 27, 28, 64 and 65 -/

/-! ### Qāʿida 7: finding the original while performing the substitute

«(أحدهما) أن يكون المتلبس به رخصة عامة شرعت تيسيرا… فهذا لا يجب عليه الانتقال… الضرب الثاني: أن
يكون المتلبس به إنما شرع ضرورة للعجز عن الأصل… فهذا يلزمه الانتقال إلى الأصل عند القدرة عليه». -/

/-- Switch to the original when the substitute was a necessity, not when it was a general
concession. -/
def mustSwitch (necessity : Bool) : Bool := necessity

/-- The necessity type is Q28 (Ibn Rajab 16): once the original is possible, the substitute is
not used. -/
theorem necessity_is_q28 : mustSwitch true = !Sadi.useSubstitute true := rfl

/-! ### Qāʿida 27: destroying or spoiling for one's own benefit or another's

«من أتلف نفسا أو أفسد عبادة لنفع يعود إلى نفسه فلا ضمان عليه، وإن كان النفع يعود إلى غيره فعليه
الضمان». -/

def liableForOthersBenefit (benefitsOther : Bool) : Bool := benefitsOther

/-! ### Qāʿida 28: loss from two acts

«إذا حصل التلف من فعلين أحدهما مأذون فيه والآخر غير مأذون فيه وجب الضمان كاملا على الصحيح، وإن
كان من فعلين غير مأذون فيهما فالضمان بينهما نصفين حتى لو كان أحدهما من فعل من لا يجب الضمان عليه
لم يجب على الآخر أكثر من النصف». -/

inductive Share where
  | full | half
  deriving DecidableEq, Repr

/-- The non-permitted actor's share: all, if the other act was permitted; half otherwise, even
when the other actor owes nothing. -/
def concurrentShare (otherPermitted : Bool) : Share := if otherPermitted then .full else .half

/-! ### Qawāʿid 64 and 65: a condition that existed in fact but was unknown

64: one who acted before learning of a permission that in fact existed; 65: one who disposed of a
thing believing it not his, and it was his. Both «فيه وجهان». The reading takes knowledge as
required (65: «الرضا بغير المعلوم هل هو رضى معتبر والأظهر عدم اعتباره»; 64.f001, al-manṣūṣ),
with Ibn Rajab's exception in 64: «الضمان لا يثبت بمجرد الاعتقاد فيما ليس بمضمون». -/

/-- Whether the condition counts as met: if he knew it, or if all that is at stake is liability,
which mere belief does not establish. -/
def countsAsMet (knew liabilityOnly : Bool) : Bool := knew || liabilityOnly

theorem liability_not_by_belief : countsAsMet false true = true := rfl

/-- The converse of qāʿida 6: there an act done on a belief later shown wrong stands; here an
act done against a belief later shown wrong does not, unless only liability is at stake. -/
theorem unknown_condition_does_not_count : countsAsMet false false = false := rfl

/-! ## M8 tranche 3: qawāʿid segmented by their lists and divisions -/

/-! ### Qāʿida 1: running water

«الماء الجاري هل هو كالراكد أو كل جرية منه لها حكم الماء المنفرد. فيه خلاف في المذهب». The reading
takes the second limb, al-Qāḍī's madhhab on the first farʿ («(والثانية) : المذهب عند القاضي»). -/

inductive Body where
  | perJirya | whole
  deriving DecidableEq, Repr

/-- Running water is judged jirya by jirya; still water as one body. -/
def runningBody (running : Bool) : Body := if running then .perJirya else .whole

/-! ### Qāʿida 17: one noble act against many

«إذا تقابل عملان أحدهما ذو شرف في نفسه ورفعة وهو واحد، والآخر ذو تعدد في نفسه وكثرة … ظاهر كلام
أحمد ترجيح الكثرة», the two costing the same time or money («في زمن واحد», «بعشرة»). Outside
equal cost the qāʿida makes no comparison, and the reading prefers neither. -/

def preferMany (sameCost : Bool) : Bool := sameCost

/-! ### Qāʿida 66: acting on a mistaken basis while the true one exists

«ولو تصرف مستندا إلى سبب ثم تبين خطؤه فيه وأن السبب المعتمد غيره وهو موجود فهو نوعان», and in
both «التصرف صحيح» (the second: «والمذهب هنا الصحة بلا ريب»). -/

/-- Valid when he acted on a basis he believed and a valid basis in fact existed. -/
def validWithBasis (believed actual : Bool) : Bool := believed && actual

/-- The contrast with qāʿida 65: there he acted believing the basis absent, and the act fails. -/
theorem q65_is_the_unbelieved_basis : validWithBasis false true = countsAsMet false false := rfl

/-! ### Qāʿida 91: what the hand takes in

«يضمن بالعقد وباليد الأموال المحضة»; of what is not pure property, what has a share of it (umm
al-walad, the mukātab, the mudabbar) «فيضمن باليد», while «الحر لا تثبت عليه اليد». -/

def handLiable (propertyLike : Bool) : Bool := propertyLike

/-! ### Qāʿida 93: the hands that take from a usurper unaware

«إن كان القابض قد دخل على ضمان عين أو منفعة استقر ضمانها عليه ولم يرجع على الغاصب … ما لم يدخل
على ضمانه … رجع به على الغاصب». Where he benefited from what he did not undertake there are two
riwāyas; the reading follows the head principle, recourse unless he undertook the liability. -/

def takerRecourse (enteredOnLiability : Bool) : Bool := !enteredOnLiability

theorem undertaken_settles : takerRecourse true = false := rfl
/-! ## M8, third tranche: Ibn Rajab's qawāʿid 31 and 47

These are candidate readings of the named source positions, not adopted rulings.
Q31 distinguishes corruption after a binding start from prevention, and faulty from
non-faulty loss. The non-faulty-loss branch follows the author of al-Mughnī; another
position remains recorded in the annotation. Q47 distinguishes compensation under
the contract from compensation for loss. It does not identify every defective contract
with a void contract, or decide which contracts are binding. -/

inductive MakeupFailure where
  | corruption | prevention | lossWithFault | lossWithoutFault
  deriving DecidableEq, Repr

inductive MakeupExtent where
  | asBegun | baseline
  deriving DecidableEq, Repr

/-- Q31, within its source scope of a binding undertaking. `baseline` in the prevention
case describes the form of a subsequent make-up, not a duty to perform it. -/
def makeupAfterFailure : MakeupFailure → MakeupExtent
  | .corruption | .lossWithFault => .asBegun
  | .prevention | .lossWithoutFault => .baseline

/-- The pilgrim who corrupted the undertaking and the prevented pilgrim are distinct. -/
theorem prevention_not_corruption :
    makeupAfterFailure .prevention ≠ makeupAfterFailure .corruption := by decide

/-- Q31's designated offering: fault preserves its enhanced description; the no-fault
branch is the expressly recorded al-Mughnī position, not a resolution of the two wujūh. -/
theorem fault_changes_replacement :
    makeupAfterFailure .lossWithFault ≠ makeupAfterFailure .lossWithoutFault := by decide

inductive CompensationBasis where
  | agreed | equivalent
  deriving DecidableEq, Repr

/-- Q47's explanatory distinction: contract compensation uses the named consideration;
loss compensation uses the equivalent. The annotation must establish which applies. -/
def defectiveCompensationBasis (contractLiability : Bool) : CompensationBasis :=
  if contractLiability then .agreed else .equivalent

/-- Use the existing price/value selector only after the source-backed basis is fixed.
These Nat arguments are test amounts, not estimates of any historical price. -/
def defectiveCompensation (contractLiability : Bool) (named equivalent : Nat) : Nat :=
  Muamalat.priceDue (if contractLiability then some named else none) equivalent

theorem defective_compensation_by_basis (c : Bool) (n v : Nat) :
    defectiveCompensation c n v =
      if defectiveCompensationBasis c = .agreed then n else v := by
  cases c <;> rfl

/-- The loss branch must not preserve the price merely because it was named. -/
theorem defective_loss_ignores_named (n n' v : Nat) :
    defectiveCompensation false n v = defectiveCompensation false n' v := rfl

/-! ## Round 5: the open gaps' own principles, after M8 tranches 1–3 -/

/-! ### A ruling against the judge's own ijtihād (Ibn Rajab 68.f009)

«لو حكم حاكم في مسألة مختلف فيها بما يرى أن الحق في غيره أثم وعصى بذلك ولم ينقض حكمه إلا أن
يكون مخالفا لنص صريح» (Ibn Abī Mūsā). -/

/-- Undone only when a clear text shows it wrong: IQ-21's `zannSetAside`, the text being decisive
and the judge's own contrary view an ijtihād. -/
def rulingUndone (contradictsNass : Bool) : Bool :=
  zannSetAside (if contradictsNass then .qat else .zann) false

theorem own_ijtihad_does_not_undo : rulingUndone false = false := ijtihad_not_overturned_by_ijtihad false
theorem clear_text_undoes : rulingUndone true = true := evident_error_sets_aside

/-! ### Oaths read by custom (Ibn Rajab 1.f003; al-Saʿdī Q9)

«والأيمان مرجعها إلى العرف»: what the oath names, the law not defining it, is measured by custom
(Q9, `Usul.Kulliyyat.measure`). Custom counts the running river as one body of water. -/

def oathBody (customOneBody : Bool) : Body :=
  Usul.Kulliyyat.measure none (if customOneBody then .whole else .perJirya)

theorem oath_follows_custom (c : Bool) :
    oathBody c = if c then .whole else .perJirya := Usul.Kulliyyat.q09_custom_decides _

/-! ### Fungibles mixed with their own kind (Ibn Rajab 22.f003–f004)

«لو خلط زيته بزيت غيره على وجه لا يتميز … المنصوص في رواية عبد الله وأبي الحارث أنه اشتراك». -/

inductive Mixed where
  | shared | consumed | separate
  deriving DecidableEq, Repr

/-- Still distinguishable: each keeps his own (22.f006, grain that can be picked out). Mixed
indistinguishably: shared with its own kind, qāʿida 22's consumption in another kind. -/
def mixedOutcome (sameKind indistinct : Bool) : Mixed :=
  if !indistinct then .separate else if sameKind then .shared else .consumed

theorem other_kind_is_consumed : mixedOutcome false true = .consumed := rfl
theorem distinct_stays_separate (s : Bool) : mixedOutcome s false = .separate := by cases s <;> rfl

/-! ### Lawful wealth mixed with unlawful (Ibn Rajab 22.f007)

Aḥmad (al-Marrūdhī): «إن كانت الدراهم قليلة كثلاثة فيها درهم حرام وجب التوقف عنها حتى يعلم وإن
كانت كثيرة كثلاثين فيها درهم حرام فإنه يخرج منها درهما ويتصرف في الباقي», since taking out the
much «يجحف بماله». -/

inductive MixedHaram where
  | suspend | takeOut
  deriving DecidableEq, Repr

def mixedHaram (lawfulMany : Bool) : MixedHaram := if lawfulMany then .takeOut else .suspend

/-! ### A concession under doubt (Ibn Rajab 68.f001)

«لأن المسح رخصة ولم تتحقق إباحتها فلم يصح كمن قصر وهو يشك في جواز القصر». -/

/-- A concession whose permission needs certainty stands only when that permission is established. -/
def rukhsaValid (rukhsaNeedsCertainty permissionEstablished : Bool) : Bool :=
  !rukhsaNeedsCertainty || permissionEstablished

/-- A concession is qāʿida 68's first type: a condition that needs a firm basis, with no aṣl to
lean on (the aṣl is the ʿazīma). -/
theorem rukhsa_is_firm_condition (r p : Bool) : rukhsaValid r p = validUnderDoubt r p false := by
  cases r <;> cases p <;> rfl

/-! ### A sale conditioned on a known fact (Ibn Rajab 68.f007)

al-Kāfī: «لأنه تعليق على شرط واقع يعلمانه فلا يؤثر ذكره في العقد», with Aḥmad's naṣṣ (Ibn Manṣūr)
on selling the absent thing «إن كان سالما». -/

def conditionedSaleValid (conditional knownToHold : Bool) : Bool := !conditional || knownToHold

/-! ### Pardoning qiṣāṣ before the spread (Ibn Rajab 65.f004)

Majd al-Dīn builds it «على أن القصاص هل يجب للميت أو لورثته»; «وجزم القاضي وغيره بأنه لا يصح العفو
ههنا». -/

def pardonOfSpreadValid (rightIsVictims : Bool) : Bool := rightIsVictims

/-- If the right to qiṣāṣ for the life is the heirs', he pardoned what he did not know to be his to
pardon: qāʿida 65's unknown condition. -/
theorem heirs_right_is_q65 : pardonOfSpreadValid false = countsAsMet false false := rfl

/-! ## M8 tranche 4 -/

/-! ### Qāʿida 2: hair and nails

«شعر الحيوان في حكم المنفصل عنه لا في حكم المتصل، وكذلك الظفر. هذا هو جادة المذهب». -/

inductive Attachment where
  | attached | detached
  deriving DecidableEq, Repr

def hairStatus (hairOrNail : Bool) : Attachment := if hairOrNail then .detached else .attached

/-! ### Qawāʿid 20–21: growth from the substance is as a part

20: «النماء المتولد من العين حكمه حكم الجزء، والمتولد من الكسب بخلافه على الصحيح»; 21: whether
the child is as a part or as earnings, «والأظهر أنه جزء». -/

inductive Growth where
  | part | separate
  deriving DecidableEq, Repr

def growthKind (fromSubstance : Bool) : Growth := if fromSubstance then .part else .separate

/-- Qāʿida 21's al-aẓhar is qāʿida 20 applied: the child grows from the mother's substance. -/
theorem child_is_part : growthKind true = .part := rfl

/-! ### Qāʿida 24: transferring property a due right attaches to

«من تعلق بماله حق واجب عليه فبادر إلى نقل الملك عنه صح، ثم إن كان الحق متعلقا بالمال نفسه لم
يسقط وإن كان متعلقا بمالكه لمعنى زال بانتقاله عنه سقط، وإن كان لا يزول بانتقاله لم يسقط على
الأصح». The transfer itself is valid; the reading decides whether the right survives it. -/

def rightSurvivesTransfer (onProperty reasonCeases : Bool) : Bool := onProperty || !reasonCeases

theorem owner_right_lapses_with_its_reason : rightSurvivesTransfer false true = false := rfl
theorem property_right_survives (r : Bool) : rightSurvivesTransfer true r = true := rfl

/-! ## M8 tranche 5 -/

/-! ### Qāʿida 25: what follows ownership proven by evidence or confession

«من ثبت له ملك عين ببينة أو إقرار فهل يتبعها ما يتصل بها أو تولد منها أم لا؟ في المسألة خلاف».
The reading takes Ibn Rajab's recurring measure: what follows in sale follows here. -/

def followsProven (followsInSale : Bool) : Bool := followsInSale

/-! ### Qāʿida 29: a tolerated amount exceeded

«من سومح في مقدار يسير فزاد عليه فهل تنتفي المسامحة في الزيادة وحدها أو في الجميع فيه وجهان».
The reading takes Ibn Rajab's distinction in 29.f003: the excess alone where he is not at fault,
«بخلاف الوكيل والمضحي». -/

inductive Lapse where
  | all | excess
  deriving DecidableEq, Repr

def toleranceLapse (atFault : Bool) : Lapse := if atFault then .all else .excess

/-! ### Qāʿida 30: what was given out as due and failed to count

«… فهل يعود إلى ملكه أم لا؟ فيه خلاف». The reading: what did not discharge the duty is still his. -/

def returnsToOwner (failedToCount : Bool) : Bool := failedToCount

/-! ### Qāʿida 32: excepting the benefit of a transferred thing

«يصح عندنا استثناء منفعة العين المنتقل ملكها من ناقلها مدة معلومة», and in waqf and manumission
for his life too, «لأن جهالة المدة هنا لا تؤثر». -/

def benefitExceptionValid (knownPeriod toleratesUncertainty : Bool) : Bool :=
  knownPeriod || toleratesUncertainty

theorem known_period_suffices (t : Bool) : benefitExceptionValid true t = true := rfl

/-! ### Qāʿida 33: the implicit exception

«الاستثناء الحكمي هل هو كالاستثناء اللفظي أم تغتفر فيه الجهالة … والصحيح عند صاحب المغني الصحة،
وهو قياس المذهب، خلافا للقاضي». -/

/-- An exception of uncertain extent: valid when it arises by law, not when stated. -/
def uncertainExceptionValid (implicit : Bool) : Bool := implicit

/-! ### Qāʿida 34: benefits owed under a binding contract

«استحقاق منافع العبد بعقد لازم يمنع من سريان العتق إليها كالاستثناء في العقد وأولى ; لأن الاستثناء
الحكمي أقوى», against Taqī al-Dīn. -/

def manumissionReachesBenefits (bindingContract : Bool) : Bool := !bindingContract

/-- 34 is 33 applied: the binding contract is an implicit exception, so manumission stops at it. -/
theorem binding_is_implicit_exception (b : Bool) :
    manumissionReachesBenefits b = !uncertainExceptionValid b := rfl

/-! ## M8 tranche 6 -/

/-! ### Qāʿida 35: owning the benefit by contract, then the thing

A perpetual commutative contract (nikāḥ) dissolves on owning the person; a lease does not, «لا
ينفسخ وهو الصحيح وهو اختيار القاضي وابن عقيل والأكثرين». -/

def priorContractDissolves (perpetualCommutative : Bool) : Bool := perpetualCommutative

/-! ### Qāʿida 37: successive contracts on one thing

«في توارد العقود المختلفة بعضها على بعض، وتداخل أحكامها»: the later contract's ruling governs the
hand (the pledge used becomes a loan, the pledge on usurped goods clears the usurper). -/

def laterContractGoverns (successive : Bool) : Bool := successive

/-- Jamʿ (`corpus/reconciliation/ledger.json`): the later contract governs where it binds, or where
the earlier one did not. Abū al-Barakāt's farq, «ويسقط ضمان العارية لأنها ليست لازمة، وعقد هذه الأمانة
لازم» (37.f003), reconciles the reading with Majd's ẓāhir of Aḥmad: a non-binding permission does not
turn a binding pledge into a loan (37.f000), and a void condition does not displace it (37.f006). -/
def laterBindingGoverns (successive earlierBinding laterBinding : Bool) : Bool :=
  successive && (laterBinding || !earlierBinding)

/-- Conservative: where the later contract binds, the earlier reading is unchanged. -/
theorem laterBindingGoverns_conservative (s e : Bool) :
    laterBindingGoverns s e true = laterContractGoverns s := by
  cases s <;> cases e <;> rfl

/-- And where the earlier did not bind (the deposit, the loan, the usurpation). -/
theorem laterBindingGoverns_unbound_earlier (s l : Bool) :
    laterBindingGoverns s false l = laterContractGoverns s := by
  cases s <;> cases l <;> rfl

theorem binding_pledge_survives : laterBindingGoverns true true false = false := rfl

/-! ### Qāʿida 38: contract words joined with what takes them out of their nature

«فهل يفسد العقد بذلك أو يجعل كناية عما يمكن صحته على ذلك الوجه؟ … يلتفت إلى أن المغلب هل هو اللفظ
أو المعنى». The reading takes the meaning. -/

def asKinayaValid (otherContractPossible : Bool) : Bool := otherContractPossible

/-! ### Qāʿida 39: contracts by allusion

Kināyāt conclude «سائر العقود سوى النكاح لاشتراط الشهادة عليه وهي لا تقع على النية» (Abū al-Khaṭṭāb,
al-Mughnī, «وكلام كثير من الأصحاب يدل عليه»), against al-Qāḍī's restriction to divorce and
manumission. -/

def kinayaConcludes (needsWitnessing : Bool) : Bool := !needsWitnessing

theorem witnessed_needs_explicit : kinayaConcludes true = false := rfl

/-! ### Qāʿida 41: a bound right and the destroyed thing's substitute

«إذا تعلق بعين حق تعلقا لازما فأتلفها من يلزمه الضمان فهل يعود الحق إلى البدل المأخوذ من غير عقد
آخر؟ فيه خلاف». The reading: the right passes to the substitute. -/

def rightPassesToSubstitute (boundToThing : Bool) : Bool := boundToThing

/-- As with transfer (qāʿida 24): a right on the property itself follows it. -/
theorem substitute_as_transfer : rightPassesToSubstitute true = rightSurvivesTransfer true false := rfl

/-! ## M8 tranche 7: qawāʿid 3, 5, 9, 10, 12 -/

/-! ### Qāʿida 3: an undistinguished excess over what suffices

«هل يوصف الكل بالوجوب أو قدر الإجزاء منه … ففيه وجهان». The reading follows Ibn Rajab's own
resolution: the whole is obligatory where the whole was the original duty, lightened
(«وصف الكل بالوجوب على الصحيح», the traveller's four), and otherwise the excess is voluntary
(al-Qāḍī on the older age in zakāt, «وهو الصواب»). A separable excess is voluntary «فلا إشكال». -/

def excessObligatory (separable lightened : Bool) : Bool := !separable && lightened

/-! ### Qāʿida 5: an act advanced before its time, the state then changing

The act suffices when it was the duty as it stood at performance: «لأنه كان فرضه في الظاهر فبرئ به …
فصادف … ذمة بريئة»; the boy's prayer before puberty discharged no duty, so the manṣūṣ has it
repeated. -/

def advancedSuffices (dueAtPerformance : Bool) : Bool := dueAtPerformance

/-! ### Qāʿida 9: worship performed in a prohibited way

Invalid where the prohibition returns to the act itself, to a condition specific to it, or to a
condition not specific to it («روايتان أشهرهما عدمها»); valid where it returns to what is no
condition («وخالفه الأكثرون», against Abū Bakr). -/

inductive Prohibited where
  | essence | specificCondition | generalCondition | outside
  deriving DecidableEq, Repr

def validDespite : Prohibited → Bool
  | .outside => true
  | _ => false

/-! ### Qāʿida 10: wordings in worship and contracts

«ما يعتبر معناه دون لفظه كألفاظ عقد البيع … وألفاظ الطلاق»; «ما يعتبر لفظه مع القدرة عليه دون العجز
عنه». The reading: a non-Arabic wording counts where only the meaning counts, or where he cannot
manage the Arabic. -/

def otherTongueValid (meaningOnly able : Bool) : Bool := meaningOnly || !able

/-! ### Qāʿida 12: worship transmitted in several forms

«ظاهر كلام الأصحاب» is to keep to one form; combining is disputed. The reading takes Taqī al-Dīn's
criterion: forms that are substitutes for each other are not combined, «ولا يصح الجمع بين البدل
والمبدل»; forms that are not (two prayers) may be, «جمعت فعله وأمره» (Aḥmad). -/

def combineForms (substitutes : Bool) : Bool := !substitutes

/-! ## M8 tranche 8: qawāʿid 4, 11, 14, 15, 19 -/

/-! ### Qāʿida 4: advancing worship

«لا يجوز تقديمها على سبب وجوبها ويجوز تقديمها بعد سبب الوجوب وقبل الوجوب». -/

def advanceAllowed (causePresent : Bool) : Bool := causePresent

/-! ### Qāʿida 11: the voluntary before the obligatory of its kind

«فإن كانت موسعة جاز التنفل قبل أدائها … وإن كانت مضيقة لم تصح على الصحيح». -/

def naflValid (narrow financial : Bool) : Bool := !narrow || financial

/-- Zakāt is the carve-out: «فقال الأصحاب يصح أن يتنفل بالصدقة قبل أدائها وإن كانت على الفور», with
Aḥmad's naṣṣ (Muhannā), so narrowness bars only the purely bodily worship of one kind. -/
theorem zakat_carve_out : naflValid true true = true := rfl

/-! ### Qāʿida 14: a cause from one of two men, not known which

The reading takes Ibn Rajab's own farq: binding both is right where it costs no right («بخلاف إيجاب
الطهارة عليهما فإنه لا ضرر فيه»), and wrong where it would cut a right («إجبار الإنسان على قطع
ملكه بغير حق»). There neither is bound, yet each refrains until certain, «ولنا وجه آخر بوجوب
اعتزال كل منهما زوجته حتى يتيقن الأمر ونص عليه أحمد», which the slave-women follow by qiyās
al-manṣūṣ. `abstain` is that composite: no attachment, with abstention. -/

inductive Attach where
  | neither | each | lot | abstain
  deriving DecidableEq, Repr

def attachTo (harmless : Bool) : Attach := if harmless then .each else .abstain

/-! ### Qāʿida 15: corollaries of one aṣl against another

«لم يلتفت إلى ذلك اللازم على الصحيح»: each matter stays on its own aṣl. -/

def eachOnItsAsl (separateMatters : Bool) : Bool := separateMatters

/-! ### Qāʿida 19: ability to perform and the dhimma

«إمكان الأداء ليس بشرط في استقرار الواجبات بالشرع في الذمة على ظاهر المذهب»; for making up
(qaḍāʾ) «فاعتبر الأصحاب له إمكان الأداء». -/

def settlesInDhimma (makingUp : Bool) : Bool := !makingUp

/-! ## M8 tranche 9: qawāʿid 36, 42, 43, 46, 49, 50, 51 -/

/-- Qāʿida 36: a lease by one whose authority ends dissolves unless the new holder succeeds the
lessor in what is his («فلا اعتراض له على عقوده بل هو منفذ لها»): the ward who comes of age, the heir,
the buyer; it dissolves for the conqueror and for the next waqf tier, who take from the wāqif. -/
def leaseDissolves (succeedsLessor : Bool) : Bool := !succeedsLessor

/-- Qāʿida 42: a property held for another must be returned at once where the owner did not
consent to its holding, or where it is guaranteed («فتجب المبادرة إلى الرد بكل حال»); a trust held
by consent waits for the demand. -/
def returnAtOnce (heldByConsent guaranteed : Bool) : Bool := !heldByConsent || guaranteed

/-- Qāʿida 43: continued holding without permission makes liable only one who withholds it
(«فإن كان ممتنعا من تسليمه فهو غاصب»; «لتعديه بترك الرد مع إمكانه»). -/
def holderLiable (withholds : Bool) : Bool := withholds

/-- Qāʿida 43, the second division: after a commutative contract ends with the thing in his hand,
he is liable where he caused the ending or shared in it, «لأنه يسبب إلى جعل ملك غيره في يده», and not
where the other ended it alone (the ẓāhir of al-Mughnī on the ṣadāq). -/
def liableAfterEnding (endedByHolder : Bool) : Bool := endedByHolder

/-- Qāʿida 46: a void contract is concluded only where it binds and cannot be left by word
(iḥrām) or carries a pervasive effect (nikāḥ, kitāba); a void sale or lease «فالمعروف من المذهب
أنه غير منعقد». -/
def voidConcluded (binding pervasive : Bool) : Bool := binding && pervasive

/-- Qāʿida 49: a contract binds without qabḍ unless qabḍ is part of its completion (salam,
ribawī exchange). -/
def bindsWithoutQabd (qabdCompletes : Bool) : Bool := !qabdCompletes

/-- Qāʿida 50: a forced acquisition is owned before the price is paid only under necessity
(«لأن ضرره لا يندفع إلا بذلك»); otherwise «والضرر لا يزال بالضرر». -/
def ownedBeforePayment (necessity : Bool) : Bool := necessity

/-- Qāʿida 51: what is determined enters the new owner's ḍamān without transport, the bond of
the former owner cut («وقد انقطعت علق البائع منه»); the undetermined needs qabḍ. -/
def inNewOwnersDaman (determined : Bool) : Bool := determined

/-- Qāʿida 52: disposal before qabḍ is barred only in the undetermined («جادة المذهب وهو أن لا
ضمان ولا منع من التصرف إلا في المبهم خاصة»), and where the disposer's right is not settled: the
stipend, «شيء مغيب لا يدرى أيصل إليه أم لا», and the alms, «لا تملك بدون القبض». -/
def disposeBeforeQabd (mubham settled : Bool) : Bool := !mubham && settled

/-- Qāʿida 54: one may not dispose of a thing so as to extinguish another's right in it without
his leave, whether the right was taken, demanded, or only established («والصحيح أنه لا يجوز
أيضا»); a disposal that leaves the right to a substitute is allowed. -/
def mayDisposeOver (extinguishes : Bool) : Bool := !extinguishes

/-- Qāʿida 56: a contract's condition of capacity suffices when concurrent with it («المنصوص عن
أحمد الاكتفاء بالمقارنة في الصحة»), against the wajh that it must precede. -/
def conditionMet (prior concurrent : Bool) : Bool := prior || concurrent

/-- Qāʿida 58: desisting at once from what one is engaged in is not doing the forbidden, unless
one began knowing the prohibition imminent («لإقدامه على الفعل مع علمه بتحريمه في وقته لا سيما مع
قرب الوقت»). -/
def desistIsAct (foresaw : Bool) : Bool := foresaw

/-- Qāʿida 61: a deputy is removed with his principal's removal or death unless his mandate is
general, a deputy for the Muslims («بخلاف القضاة فإنهم نواب للمسلمين»). -/
def removedWithPrincipal (general : Bool) : Bool := !general

/-- Qāʿida 62: removal takes effect before it is known (the agent, «المشهور»), except in a public
office carrying a right of God, «شبيه بنسخ الأحكام لا يثبت قبل بلوغ الناسخ». -/
def removedBeforeKnowledge (publicOffice : Bool) : Bool := !publicOffice

/-! ## Reconciliation refinements (`corpus/reconciliation/ledger.json`)

Each is a jamʿ: a farq the later works cite, conservative over the earlier reading where the farq
is absent, carrying the residues it touches to the prevailing (taṣḥīḥ) side. -/

/-- Qāʿida 16 with the state at obligation: once the substitute is what was due when the obligation
arose, finding the original later does not move him to it. «والاعتبار في الكفارات بحالة الوجوب»
(al-Iqnāʿ); «اعتبارا بوقت الوجوب كسائر الكفارات» (Kashshāf); for a right fixed in the value at the
divorce or the conversion, al-aṣḥāb deny the return to the thing. -/
def useSubstituteAt (originalPossible settledAtObligation : Bool) : Bool :=
  !originalPossible || settledAtObligation

theorem useSubstituteAt_conservative (p : Bool) :
    useSubstituteAt p false = Usul.Sadi.useSubstitute p := by
  cases p <;> rfl

theorem settled_substitute_stands : useSubstituteAt true true = true := rfl

/-- Qāʿidas 64–65 with the madhhab's farq for transactions: where the unknown condition is the
actor's own authority over the property (his ownership, or the owner's permission), the transaction
stands, «لأن الاعتبار في العقود بما في نفس الأمر» (Kashshāf); ṭalāq, ʿitq and nikāḥ keep the reading. -/
def countsAsMetIn (knew liabilityOnly transactionAuthority : Bool) : Bool :=
  knew || liabilityOnly || transactionAuthority

theorem countsAsMetIn_conservative (k l : Bool) :
    countsAsMetIn k l false = countsAsMet k l := by
  cases k <;> cases l <;> rfl

theorem authority_in_fact_suffices : countsAsMetIn false false true = true := rfl

/-- Qāʿida 3 with the farq of following: «الاتباع قد يسقط الواجب» (Ibn ʿAqīl), so the imām's
rukūʿ beyond the sufficient measure counts for the one who joins him; al-Inṣāf: «ومن أدرك الركوع
أدرك الركعة … هذا المذهب مطلقا». -/
def excessObligatoryIn (separable lightened following : Bool) : Bool :=
  !separable && (lightened || following)

theorem excessObligatoryIn_conservative (s l : Bool) :
    excessObligatoryIn s l false = excessObligatory s l := by
  cases s <;> cases l <;> rfl

/-- Qāʿida 5 with the state at obligation for kaffārāt: an expiation advanced by fasting does not
suffice when the oath is broken while well off, «والاعتبار في الكفارات بحالة الوجوب» (al-Iqnāʿ;
Kashshāf). -/
def advancedSufficesIn (dueAtPerformance kaffaraChanged : Bool) : Bool :=
  dueAtPerformance && !kaffaraChanged

theorem advancedSufficesIn_conservative (d : Bool) :
    advancedSufficesIn d false = advancedSuffices d := by
  cases d <;> rfl

/-- Qāʿida 10 with the farq of the act not itself due: one who does not know the Arabic need not
learn it for nikāḥ or liʿān, «لأن النكاح غير واجب بأصل الشرع فلم يجب تعلم» (Kashshāf); the khuṭba,
being due, keeps the wording. -/
def otherTongueValidIn (meaningOnly able needNotLearn : Bool) : Bool :=
  meaningOnly || !able || needNotLearn

theorem otherTongueValidIn_conservative (m a : Bool) :
    otherTongueValidIn m a false = otherTongueValid m a := by
  cases m <;> cases a <;> rfl

/-- Qāʿida 50 with the madhhab's condition on the shufʿa: the shafīʿ owns by the demand «إذا كان
مليئا بالثمن» (al-Inṣāf: «وهو المذهب»; al-Iqnāʿ), a solvent taker inflicting no harm («والضرر لا
يزال بالضرر»). The farq is cited for the shufʿa only: Ibn Rajab keeps the seller's annulment apart
(«اجتمع له العوض والمعوض»), so the other acquisitions keep the reading. -/
def ownedBeforePaymentIn (necessity shufa solvent : Bool) : Bool := necessity || (shufa && solvent)

/-- Outside the shufʿa the refinement is the earlier reading. -/
theorem ownedBeforePaymentIn_conservative (n v : Bool) :
    ownedBeforePaymentIn n false v = ownedBeforePayment n := by
  cases n <;> rfl

/-- And so it is for an insolvent shafīʿ. -/
theorem ownedBeforePaymentIn_insolvent (n s : Bool) :
    ownedBeforePaymentIn n s false = ownedBeforePayment n := by
  cases n <;> cases s <;> rfl

/-- Qāʿida 52 with the madhhab's bar on selling a debt to any but the debtor («ولا يجوز لغيره»: al-Inṣāf,
«وهو الصحيح من المذهب. وعليه الأصحاب»), which covers the deeds. -/
def disposeBeforeQabdIn (mubham settled debtToThird : Bool) : Bool :=
  disposeBeforeQabd mubham settled && !debtToThird

theorem disposeBeforeQabdIn_conservative (m s : Bool) :
    disposeBeforeQabdIn m s false = disposeBeforeQabd m s := by
  cases m <;> cases s <;> rfl

/-- Qāʿida 61 with the madhhab on the qāḍī's deputies: removed with him even under a general
mandate, «لأنهم نواب القاضي بخلاف القضاة فإنهم نواب للمسلمين» (al-Inṣāf: «هذا الصحيح من المذهب.
وعليه أكثر الأصحاب»). -/
def removedWithPrincipalIn (general ofQadi : Bool) : Bool := removedWithPrincipal general || ofQadi

theorem removedWithPrincipalIn_conservative (g : Bool) :
    removedWithPrincipalIn g false = removedWithPrincipal g := by
  cases g <;> rfl

end Usul.Refinements
