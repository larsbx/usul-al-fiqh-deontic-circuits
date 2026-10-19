import Usul.Readings.RajabA6
import Usul.Readings.RajabA20
import Usul.Refinements

/-!
# Shard rajab-a30: the reading of Ibn Rajab's qāʿida 85

Formalised from the qāʿida's own statement in the pinned witness (`openiti-rajab-shamela21730`),
status `candidate`. The qāʿida is a typology: «الحقوق خمسة أنواع»: a right of ownership (ḥaqq
milk), a right to come to own (ḥaqq tamalluk), a right of use (ḥaqq intifāʿ), a right of
exclusive holding (ḥaqq ikhtiṣāṣ), and a right attached for recovering a right (ḥaqq al-taʿalluq
li-istīfāʾ al-ḥaqq). `Haqq` names the five; each reading below gives the ruling the text states for
one kind (or one of its ṣuwar), over facts the furūʿ state. Which kind a given cause yields
(ownership by conquest, by the lapse of the year of announcing, by the testator's death; the
amenities of property; the kind of the zakāt's attachment) is, in the text, disputed case by case
and decided in each bāb, not by the typology; those furūʿ are gaps in the takhrīj suite
`corpus/takhrij/rajab_m8_rajab_a30_furu.json`, each naming the rule it needs.
-/

namespace Usul.Readings.RajabA30

/-- «الحقوق خمسة أنواع (أحدها) حق ملك ... (والثاني) حق تملك ... [النوع الثالث حق الانتفاع] ...
[النوع الرابع حق الاختصاص] ... [النوع الخامس حق التعلق لاستيفاء الحق]». -/
inductive Haqq where
  | milk | tamalluk | intifaa | ikhtisas | taalluq
  deriving DecidableEq, Repr

/-- Ownership is already in hand, without the holder's choice, only for ḥaqq milk; the right to
come to own (ḥaqq tamalluk) waits on his choice: «لا يدخل حتى يختار ... فيكون حقه فيها حق
تملك». -/
def Haqq.ownedWithoutChoice : Haqq → Bool
  | .milk => true
  | _ => false

/-- Ḥaqq ikhtiṣāṣ «غير قابل للشمول والمعاوضات»: it does not take an exchange. -/
def Haqq.takesExchange : Haqq → Bool
  | .ikhtisas => false
  | _ => true

/-! ## The second kind: ḥaqq tamalluk -/

/-- The kind's own ḍābiṭ: «هذا كله فيمن انعقد له سبب التملك وصار التملك واقفا على اختياره».
`causeConcluded`: a cause of his coming to own has been concluded for him; `causeCompletesMilk`: that
cause by itself establishes the ownership, with no choice of his («يثبت له الملك بغير اختياره»,
«قهرا»). The output is that his ownership waits on his choice: he holds a ḥaqq tamalluk, not a
ḥaqq milk. Whether a given cause completes the ownership is what the furūʿ dispute
(«وههنا صور مختلف فيها هل يثبت فيها الملك أو حق التمليك؟»). -/
def awaitsChoice (causeConcluded causeCompletesMilk : Bool) : Bool :=
  causeConcluded && !causeCompletesMilk

/-- A cause that completes the ownership leaves nothing to choose: ḥaqq milk. -/
theorem completed_cause_is_milk (c : Bool) : awaitsChoice c true = false := by
  cases c <;> rfl

/-- Without a concluded cause there is no ḥaqq tamalluk (the one bargaining, the suitor: «ولم
ينعقد السبب كالمستام والخاطب»). -/
theorem no_cause_no_tamalluk (m : Bool) : awaitsChoice false m = false := rfl

/-- Link to qāʿida 144 (`RajabA20.heirInherits`): on the kind's own furūʿ, one who dies before
choosing to own or claiming «فلا حق له» (the ghanīma), which is qāʿida 144's «حقوق التملكات ...
أشهرهما: أنه لا يورث»: an unclaimed right to come to own, not falling due at death and not attached
to inherited property, does not pass to the heirs. -/
theorem unclaimed_tamalluk_not_inherited :
    Usul.Readings.RajabA20.heirInherits false false false = false := rfl

/-- Link to qāʿida 55 (`Refinements.disposalTakes`): one whose ownership waits on his choice does
not come to own by disposing unless the cause of ownership has settled for him: the right to come
to own is not yet ownership. -/
theorem tamalluk_disposal_does_not_take (c m : Bool) (h : awaitsChoice c m = true) :
    Usul.Refinements.disposalTakes (!(awaitsChoice c m)) false = false := by
  simp [h, Usul.Refinements.disposalTakes]

/-! ## The third kind: ḥaqq intifāʿ -/

/-- «كما لا يملك الجار إعارة غيره ما يستحقه من الانتفاع بملك جاره»; «فلا يكون له في الأرض
سوى حق الانتفاع». `useRightOnly`: what he holds in another's property is a right to use it for a
given benefit (to leave his crop standing, his beams on the wall), not the benefit owned. The output
is that he may pass the benefit to another (lend or lease it) or use the property beyond that
benefit. -/
def mayPassBenefit (useRightOnly : Bool) : Bool := !useRightOnly

/-- A bare right of use is neither lent nor leased. -/
theorem use_right_not_passed : mayPassBenefit true = false := rfl

/-- The kind's first ṣuwar: «وضع الجار خشبه على جدار جاره إذا لم يضر به للنص الوارد فيه» and
«إجراء الماء في أرض غيره إذا اضطر إلى ذلك في إحدى الروايتين». `needed`: he needs (or is compelled
to) the use of the other's property; `harmful`: the use harms the owner. The output is that a ḥaqq
intifāʿ in the other's property is established for him without the owner's leave. -/
def useRightForNeed (needed harmful : Bool) : Bool := needed && !harmful

/-- A harmful use is never established without leave. -/
theorem harm_bars_use_right (n : Bool) : useRightForNeed n true = false := by
  cases n <;> rfl

/-- Link to qāʿida 99 (`RajabA6.freeAyn`): the same ṣuwar (beams on the wall, water over the land)
are qāʿida 99's needed things given without ʿiwaḍ where the giving does no harm. -/
theorem use_right_is_q99 (n h : Bool) :
    useRightForNeed n h = Usul.Readings.RajabA6.freeAyn n (!h) := by
  cases n <;> cases h <;> rfl

/-- Where the use right is established, qāʿida 99's benefit is due free. -/
theorem use_right_gives_free_benefit (n h : Bool) (hu : useRightForNeed n h = true) :
    Usul.Readings.RajabA6.freeBenefit n = true := by
  cases n <;> cases h <;> simp_all [useRightForNeed, Usul.Readings.RajabA6.freeBenefit]

/-! ## The fourth kind: ḥaqq ikhtiṣāṣ -/

/-- «وهو عبارة عما يختص مستحقه بالانتفاع به ولا يملك أحد مزاحمته فيه»; «فأما ما لا يجوز
الانتفاع به من النجاسات بحال فلا يد ثابتة عليه، وآية ذلك أنه لا يجب رده على من انتزعه ممن هو في
يده بخلاف ما فيه نفع مباح فإنه يجب رده»; and of wine, «وهذا كله يدل على ثبوت اليد على الخمر
لإمكان عودها مالا». `permittedBenefit`: the thing (not owned wealth) has a permitted use;
`mayBecomeMal`: it can return to being wealth. The output is that the holder's hand stands on it as
a ḥaqq ikhtiṣāṣ: it is returned to him if taken. -/
def handStands (permittedBenefit mayBecomeMal : Bool) : Bool := permittedBenefit || mayBecomeMal

/-- What has no permitted use and cannot return to wealth carries no hand: «فلا يد ثابتة عليه». -/
theorem no_benefit_no_hand : handStands false false = false := rfl

/-- The kind's place ṣuwar: «فالسابق إليها أحق بها»; «فيكون الجالس أحق بمجلسه إلى أن يقوم عنه
باختياره قاطعا للجلوس أما إن قام لحاجة عارضة ونيته العود فهو أحق بمجلسه». `preceded`: he came
first to a place shared and open to use (the market's open stalls, the mosque); `leftByChoice`: he
left it by his choice, cutting off his sitting. The output is that he is more entitled to it (none
may push him from it). -/
def firstComerAhaqq (preceded leftByChoice : Bool) : Bool := preceded && !leftByChoice

/-- Leaving by choice ends the entitlement. -/
theorem leaving_ends_ikhtisas (p : Bool) : firstComerAhaqq p true = false := by
  cases p <;> rfl

/-- The kind does not take an exchange. -/
theorem ikhtisas_takes_no_exchange : Haqq.ikhtisas.takesExchange = false := rfl

/-! ## The fifth kind: ḥaqq al-taʿalluq li-istīfāʾ al-ḥaqq -/

/-- «تعلق حق المرتهن بالرهن ومعناه أن جميع أجزاء الرهن محبوس بكل جزء من الدين حتى يستوفي
جميعه»; «تعلق حق الجناية بالجاني ... ويتعلق الحق بمجموع الرقبة لا بقدر الأرش على ظاهر كلام
الأصحاب». `pledgeTie`: the right is tied as a pledge is to the pledged thing; `jinayaTie`: the right
is tied as an injury's is to the slave who injured. The output is that the whole of the thing is
held for the right, not the measure of the right in it. -/
def wholeBound (pledgeTie jinayaTie : Bool) : Bool := pledgeTie || jinayaTie

/-- The pledge's tie holds the whole. -/
theorem pledge_holds_whole (j : Bool) : wholeBound true j = true := rfl

/-- The kind's name, «حق التعلق لاستيفاء الحق», and its ṣūra «تعلق حق غرماء المفلس بماله بعد
الحجر وهو تعلق استحقاق الاستيفاء منه». `tied`: a cause the text names has tied the right to this
property (the pledge, the injury, the ḥajr, the designation). The output is that the holder is
entitled to recover his right from that property. -/
def recoverFrom (tied : Bool) : Bool := tied

/-- «تعلق حقوق الفقراء بالهدي والأضاحي المعينة ويقدمون بما يجب صرفه إليهم منها على الغرماء في
حياة الموجب وبعد وفاته». `tied`: as above; `rivalInDhimmaOnly`: the competing claim is owed only in
the dhimma, not tied to this property. The output is that the tied right is paid from the property
before the competing claim. -/
def tiedPrecedes (tied rivalInDhimmaOnly : Bool) : Bool := tied && rivalInDhimmaOnly

/-- A right preferred in the property is one recovered from it. -/
theorem precedence_is_recovery (t r : Bool) (h : tiedPrecedes t r = true) : recoverFrom t = true := by
  cases t <;> cases r <;> simp_all [tiedPrecedes, recoverFrom]

/-- An untied right precedes nothing. -/
theorem untied_precedes_nothing (r : Bool) : tiedPrecedes false r = false := rfl

end Usul.Readings.RajabA30
