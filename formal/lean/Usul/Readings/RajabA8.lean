/-!
# Shard rajab-a8: readings of Ibn Rajab's qawāʿid 104 and 105

Each reading is formalised from the qāʿida's own statement (status `candidate`). Where the
statement leaves a question to khilāf, the reading returns the side the statement does not
establish, and the other side is held as a position on the farʿ, not as the reading.
-/

namespace Usul.Readings.RajabA8

/-- Qāʿida 104: consent to what is unknown in amount, genus or description binds when what is
committed to is a contract or annulment that admits vagueness: «إن كان الملتزم عقدا أو فسخا يصح
إبهامه بالنسبة إلى أنواعه أو إلى أعيان من يرد عليه صح الرضا به وألزم بغير خلاف»; otherwise
«وإن كان غير ذلك ففيه خلاف», and the qāʿida does not make it bind. `vaguenessAdmitted`: the
commitment is of the first kind. The output is whether the consent binds. -/
def unknownConsentBinds (vaguenessAdmitted : Bool) : Bool := vaguenessAdmitted

/-- Qāʿida 105, the inshāʾāt: pure transfers of ownership, securities and gifts binding by
contract or delivery «فلا يصح في مبهم من أعيان متفاوتة», but «ويصح في مبهم من أعيان متساوية
مختلطة كقفيز صبرة»; a gift tied to death «فيصح في المبهم بغير خلاف», as do revocable gifts,
partnerships and trusts, and annulments «ما وضع منها على التغليب والسراية صح في المبهم كالطلاق
والعتاق». A claim and a testimony follow the object: «فإن كانت بما يصح وقوع العقد عليه مبهما
… فإنها تصح». `bindingTransfer`: the inshāʾ is of the first type; `equalMixed`: the vague object
is one of equal, mixed units. The output is whether it is valid on the vague object. -/
def vagueInshaValid (bindingTransfer equalMixed : Bool) : Bool := !bindingTransfer || equalMixed

/-- Qāʿida 105, the ikhbārāt: «فما كان منها خبرا دينيا أو كان يجب به حق على المخبر قبل في
المبهم، فإن تعلق به وجوب حق على غيره لم يقبل إلا فيما يظهر له فيه عذر الاشتباه ففيه خلاف».
`religiousOrAgainstSelf`: the report is religious or obliges a right on the reporter. The output
is whether it is accepted in the vague. -/
def vagueReportAccepted (religiousOrAgainstSelf : Bool) : Bool := religiousOrAgainstSelf

/-- Qāʿida 105, its faṣl on an inshāʾ tied to a name that does not single out what it names:
«فإن لم ينوه في الباطن معينا فهو كالتصريح بالإبهام وإن نوى به معينا فإن كان العقد مما لا يشترط
له الشهادة صح وإلا ففيه خلاف». `vagueValid`: the same inshāʾ is valid on an explicitly vague
object; `intendedSpecific`: a specific one was intended inwardly; `witnessingRequired`: the
contract requires witnesses. The output is whether it is valid. -/
def sharedNameValid (vagueValid intendedSpecific witnessingRequired : Bool) : Bool :=
  if intendedSpecific then !witnessingRequired else vagueValid

/-- The faṣl's own link: a shared name with no inward designation «فهو كالتصريح بالإبهام». -/
theorem sharedName_unintended_is_vague (vagueValid witnessingRequired : Bool) :
    sharedNameValid vagueValid false witnessingRequired = vagueValid := rfl

/-- Qāʿida 105, its furūʿ on one entitled in fact whom we cannot identify: «لأن الهبة والإقرار هنا
وقع لمعنى في الباطن وإنما أشكل علينا الوقوف عليه فيميز بالقرعة», «على قياس المذهب في اشتباه
المستحق للمال بغيره». `specificInFact`: the right fell on a specific one, unknown to us. The
output is whether the entitled one is singled out by lot. -/
def lotDistinguishes (specificInFact : Bool) : Bool := specificInFact

end Usul.Readings.RajabA8
