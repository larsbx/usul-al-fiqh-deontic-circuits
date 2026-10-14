/-
Readings of Ibn Rajab's qawāʿid 72, 73, 74, 79 and 80 (Taqrīr al-qawāʿid), each formalised from
the qāʿida's own statement as a Boolean function of the facts it names. Shard `rajab-a2`, lane A;
candidate, awaiting human review.
-/

namespace Usul.Readings.RajabA2

/-- Qāʿida 72: «اشتراط النفقة والكسوة في العقود يقع على وجهين معاوضة وغير معاوضة»; the
muʿāwaḍa «تقع في العقود اللازمة», the non-muʿāwaḍa «إباحة النفقة للعامل ما دام متلبسا
بالعمل ويقع ذلك في العقود الجائزة». A stipulation of maintenance and clothing holds as a
muʿāwaḍa (countervalue) in a binding contract, and as a licence (ibāḥa) in any contract. -/
def nafaqaStipulable (muawada binding : Bool) : Bool := !muawada || binding

/-- Qāʿida 72: in the muʿāwaḍa «ويملك فيها الطعام والكسوة كما يملك غيرهما من الأموال
المعاوض بها»; the other is «إباحة النفقة للعامل», so what is left over is returned, save what has
been spent in its purpose, the farq the qāʿida itself draws: «لأن الدابة قد صرفت في سبيل الله
واستعملت فيه وكذلك الكسوة يحصل المقصود بها بخلاف ما فضل من النفقة». -/
def nafaqaOwned (muawada spentInPurpose : Bool) : Bool := muawada || spentInPurpose

/-- Qāʿida 73: a stipulated benefit of one party that is «استئجارا له مقابلا بعوض فيصح على ظاهر
المذهب»; one that is «إلزاما له لما لا يلزمه بالعقد ... ولا يقابل بعوض فلا يصح». -/
def benefitConditionValid (againstCompensation : Bool) : Bool := againstCompensation

/-- Qāʿida 74: «فيمن يستحق العوض عن عمل بغير شرط وهو نوعان: أحدهما: أن يعمل العمل ودلالة حاله
تقتضي المطالبة بالعوض. والثاني: أن يعمل عملا فيه غناء عن المسلمين وقيام بمصالحهم العامة أو فيه
استنقاذ لمال معصوم من الهلكة». Anyone else who works on another's property has no wage («فالمعروف
من المذهب أنه لا أجرة له»). -/
def wageWithoutStipulation (professional publicOrRescue : Bool) : Bool :=
  professional || publicOrRescue

/-- Qāʿida 79: «الزرع النابت في أرض الغير بغير إذن صحيح»; the landowner may take the crop, since
«المقتضي لتملك الزرع هو انتفاء الإذن الصحيح». Crop sown by ownership or a valid permission is
not taken. -/
def ownerTakesCrop (validPermission : Bool) : Bool := !validPermission

/-- Qāʿida 80: «ما تكرر حمله من أصول البقول والخضراوات هل هو ملحق بالزرع أو بالشجر؟ فيه وجهان».
The reading takes the wajh whose ground the qāʿida states, «إن ألحقناها بالشجر لتكرر حملها»:
what bears repeatedly takes the tree's ruling. The crop wajh stays a recorded position. -/
def asTree (repeatedBearing : Bool) : Bool := repeatedBearing

end Usul.Readings.RajabA2
