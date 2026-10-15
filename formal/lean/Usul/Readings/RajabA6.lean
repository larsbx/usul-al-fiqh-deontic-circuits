/-!
# Ibn Rajab, qawāʿid 96, 98 and 99 (shard `rajab-a6`, candidate)

Each reading is formalised from the qāʿida's own statement in the pinned witness
(`openiti-rajab-shamela21730`). Facts are named Booleans; the takhrīj suite
`corpus/takhrij/rajab_m8_rajab_a6_furu.json` tests them against the furūʿ.

Qāʿidas 96 and 99 each state two kinds in their own words («هذا على قسمين»; «من الأعيان … أو
المنافع»), so each has one reading per kind.
-/

namespace Usul.Readings.RajabA6

/-! ### Qāʿida 96: performing, without leave, what another must render -/

/-- Q96, first kind, «أن تكون العين ملكا لمن وجب عليه الأداء وقد تعلق بها حق للغير»: «فإن كان
المتصرف له ولاية التصرف وقع الموقع ولا ضمان، ولو كان الواجب دينا وإن لم يكن له ولاية فإن كانت
العين متميزة بنفسها فلا ضمان ويجزئ، وإن لم تكن متميزة من بقية ماله ضمن ولم يجزئ». The result is
`true` when the performance falls in its place and the performer owes no liability. (The owner's
ratification, «إلا أن يجيز المالك التصرف», hangs on the mawqūf fuḍūlī contract and is not read
here.) -/
def ownedDischarge (wilaya distinct : Bool) : Bool := wilaya || distinct

/-- Q96, second kind, «أن يكون الواجب أداؤه غير مملوك له فأداه الغير إلى مستحقه»: «فإن كان
مستحقه معينا فإنه يجزئ ولا ضمان وإن لم يكن معينا ففي الإجزاء خلاف». Only the determined
recipient is stated to suffice; the undetermined one is left to its khilāf (`false`). -/
def unownedDischarge (recipientDetermined : Bool) : Bool := recipientDetermined

/-- «ولو كان الواجب دينا»: with wilāya the performance falls in place even where nothing
distinct was fixed for it. -/
theorem wilaya_suffices (d : Bool) : ownedDischarge true d = true := by
  cases d <;> rfl

/-- Without wilāya, the distinct thing alone decides. -/
theorem without_wilaya_distinct_decides (d : Bool) : ownedDischarge false d = d := by
  cases d <;> rfl

/-! ### Qāʿida 98: handing over by description -/

/-- «من ادعى شيئا ووصفه دفع إليه بالصفة إذا جهل ربه ولم يثبت عليه يد من جهة مالكه وإلا فلا»:
handed over to the one who describes it when its owner is unknown and no hand from the owner's
side is established over it; otherwise not. -/
def byDescription (described ownerUnknown ownerHand : Bool) : Bool :=
  described && ownerUnknown && !ownerHand

/-- «وإلا فلا»: an established hand from the owner's side bars handing over by description. -/
theorem owner_hand_bars (d u : Bool) : byDescription d u true = false := by
  cases d <;> cases u <;> rfl

/-! ### Qāʿida 99: what must be given freely -/

/-- Q99 for things, «ما تدعوا الحاجة إلى الانتفاع به من الأعيان ولا ضرر في بذله لتيسيره وكثرة
وجوده … يجب بذله مجانا بغير عوض في الأظهر»: a thing needed whose giving does no harm, being easy
and abundant, must be given without ʿiwaḍ. -/
def freeAyn (needed harmless : Bool) : Bool := needed && harmless

/-- Q99 for benefits, «أو المنافع المحتاج إليها يجب بذله مجانا بغير عوض في الأظهر»: a needed
benefit must be given without ʿiwaḍ, with no further condition stated. -/
def freeBenefit (needed : Bool) : Bool := needed

/-- The benefit kind is the weaker condition: whatever need makes a thing's giving free makes a
benefit's giving free. -/
theorem ayn_implies_benefit (n h : Bool) (hf : freeAyn n h = true) : freeBenefit n = true := by
  cases n <;> cases h <;> simp_all [freeAyn, freeBenefit]

end Usul.Readings.RajabA6
