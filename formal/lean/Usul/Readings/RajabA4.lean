/-!
# Shard rajab-a4: readings of Ibn Rajab's qawāʿid 77, 81, 90 and 92

Each reading is formalised from the qāʿida's own statement (status `candidate`). Where a farʿ of
the qāʿida turns on a fact or a rule the statement leaves implicit, the reading takes that fact
as an input (or a second reading is given beside it), quoting the farʿ's own words.
-/

namespace Usul.Readings.RajabA4

/-- Qāʿida 77: one whose property is joined to another's, distinct but subordinate, and cannot be
separated without harm reaching him, the owner of the principal takes it over at its value and
its owner is compelled: «فلمالك الأصل أن يتملكه بالقيمة من مالكه ويجبر المالك على القبول»; but
where it can be separated without harm, «فالمشهور أنه ليس له تملكه قهرا لزوال ضرره بالفصل».
The harm counted is that of an owner who did not transgress: the buyer from the usurper «لا يقلع
مجانا لعدم التعدي في غرسه», while the usurper's own planting is uprooted free on «المشهور».
`wrongful`: the subordinate was added by transgression; `separableWithoutHarm`: it can be
separated without harm. The output is whether it is taken over at its value. -/
def takenOverAtValue (wrongful separableWithoutHarm : Bool) : Bool :=
  !wrongful && !separableWithoutHarm

/-- Qāʿida 81: attached growth in property that reverts to the one from whom ownership moved
follows the property, «تتبع الأعيان على ظاهر المذهب عند أصحابنا» (the manṣūṣ, al-Shīrāzī's and
Ibn ʿAqīl's view is that it does not, held here as a position, not as the reading); and «ويتبع
الأصل في التوثقة والضمان على المشهور». Outside these two scopes the qāʿida does not make it
follow. -/
def attachedGrowthFollows (revertsToTransferor securityOrLiability : Bool) : Bool :=
  revertsToTransferor || securityOrLiability

/-- Qāʿida 81, its farʿ on a crop or fruit bought on condition of cutting and left until it ripens
or hardens: «فهل يبطل البيع بذلك أم لا؟ فيه روايتان: أشهرهما أنه يبطل». The growth then returns
to the seller with the annulled sale. -/
def cutSaleVoid (leftUntilRipe : Bool) : Bool := leftUntilRipe

/-- Qāʿida 90: hands over another's property without his permission are three: «يد يمكن أن يثبت
باستيلائها الملك فينتفي الضمان عما يستولي عليه سواء حصل الملك به أو لم يحصل ويد لا يثبت لها
الملك وينتفي عنها الضمان ويد لا يثبت لها الملك ويثبت عليها الضمان», the last being «اليد
العادية». `canOwn`: a hand by whose seizure ownership can be established; `transgressing`: the
transgressing hand (not one with a sharʿī authority, keeping for the owner, or a party with
manaʿa). The output is liability. -/
def seizingHandLiable (canOwn transgressing : Bool) : Bool :=
  !canOwn && transgressing

/-- Qāʿida 92: whether a hand of liability stands with the owner's hand is disputed; «والأظهر أنه
إن زال انتفاع المالك وسلطانه ثبت الضمان وإلا فلا». The output is liability. -/
def liableWithOwnerHand (ownerControlRemoved : Bool) : Bool := ownerControlRemoved

end Usul.Readings.RajabA4
