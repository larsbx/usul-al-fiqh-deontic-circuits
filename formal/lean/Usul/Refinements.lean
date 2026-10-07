import Usul.Muamalat
import Usul.Qawaid

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
    zahirPrevails a z true = ((Qawaid.update (⟨0, a⟩ : Qawaid.Held Nat) ⟨1, z⟩).value == 1) := by
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
theorem abstention_keeps_status {V : Type} (marriage : Qawaid.Held V) (hy : marriage.grade.IsYaqin)
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

end Usul.Refinements
