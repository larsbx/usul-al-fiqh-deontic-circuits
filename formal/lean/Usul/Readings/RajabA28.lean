import Usul.Refinements

/-!
# Shard rajab-a28: the readings of Ibn Rajab's qāʿida 82

Formalised from the qāʿida's own statement in the pinned witness (`openiti-rajab-shamela21730`,
v01 p161–173), status `candidate`. The qāʿida is typological. It sorts the separated growth
(«النماء المنفصل»: what is born of the thing, «كالولد والطلع والصوف واللبن والبيض», and what is
due because of it, «كالمهر والأرش») by the right attached to the thing: «والحقوق المتعلقة
بالأعيان ثلاثة: عقود وسبابته وحقوق يتعلق بغير فسخ ولا عقد» (the witness's «وسبابته» stands for the
fusūkh, which the qāʿida's own «فصل» headings name: «النماء في الفسوخ», «الحقوق المتعلقة بالأعيان من
غير عقد ولا فسخ»). Each nawʿ states its own ruling, and
each gets its own reading here, one for each nawʿ that has furūʿ:

* contracts not of immediate transfer that lead to ownership (`towardOwnershipFollows`);
* contracts not made to transfer the thing itself, first whether the growth is within the
  contract (`growthInContract`), then whether it follows its aṣl in ḍamān or amāna
  (`growthFollowsHand`);
* the fusūkh (`faskhGrowthFollows`);
* rights tied to things without a contract or a faskh (`rightGrowthFollows`).

The opening states (a contract made after the growth exists, and immediate transfers of
ownership) carry no furūʿ of their own («ومنها»), so no reading is given for them. Where a nawʿ
leaves two sides unmarked the reading takes the one its docstring names (RQ-02's policy in force),
and the other stays a recorded position in the takhrīj suite
`corpus/takhrij/rajab_m8_rajab_a28_furu.json`.
-/

namespace Usul.Readings.RajabA28

/-- Contracts not of immediate transfer, the first nawʿ: those that lead to ownership. «فما كان
منه لازما لا يستقل العاقد أو من يقوم مقامه بإبطاله من غير سبب فإنه يتبع فيه النماء المنفصل من العين
وغيرها»; and «وأما ما كان منها غير لازم وهو [ما] يملك العاقد إبطاله ... فلا يتبع فيه النماء من غير
عينه، وفي استتباع الولد خلاف». `lazim`: the contract is lāzim (neither the contracting party nor
whoever stands in his place can undo it alone without a sabab); `fromSubstance`: the growth is born
of the thing (the child), not earnings or what is due because of it. The output is that the growth
follows the thing into what the contract leads to.

Where the contract is not lāzim the qāʿida rules out growth not from the thing and reports
«خلاف» on the child. The reading takes the side whose ground the qāʿida states, that the party
can undo it («يملك العاقد إبطاله»): the child does not follow either. The other side (the child
follows) is a recorded position. -/
def towardOwnershipFollows (lazim _fromSubstance : Bool) : Bool := lazim

/-- Under a lāzim contract all separated growth follows, from the thing and from elsewhere. -/
theorem lazim_growth_follows (s : Bool) : towardOwnershipFollows true s = true := rfl

/-- Not lāzim: growth not born of the thing does not follow, as the qāʿida states. -/
theorem not_lazim_earnings_stay : towardOwnershipFollows false false = false := rfl

/-- Not lāzim: the child, where the qāʿida reports «خلاف», is read as not following. -/
theorem not_lazim_child_read_as_staying : towardOwnershipFollows false true = false := rfl

/-- Contracts not made to transfer the thing itself, the second nawʿ, first question: is the
growth within the contract? «فإن كان العقد واردا على العين وهو لازم فحكم النماء حكم الأصل، وإن
كان غير لازم أو لازما لكنه معقود على المنفعة من غير تأييد أو على ما في الذمة فلا يكون النماء داخلا
في العقد». `onSubstance`: the contract bears on the thing itself (not on a benefit without
perpetuity, nor on what is in the dhimma); `lazim`: it is lāzim. The output is that the growth is
within the contract and takes its aṣl's ruling there. -/
def growthInContract (onSubstance lazim : Bool) : Bool := onSubstance && lazim

/-- The pledge (rahn) bears on the thing and is lāzim: its growth is pledged with it. -/
theorem lazim_on_substance_within : growthInContract true true = true := rfl

/-- A right in the dhimma reaches no growth, lāzim or not. -/
theorem dhimma_reaches_no_growth (l : Bool) : growthInContract false l = false := by
  cases l <;> rfl

/-- A contract that is not lāzim reaches no growth. -/
theorem not_lazim_reaches_no_growth (s : Bool) : growthInContract s false = false := by
  cases s <;> rfl

/-- The second nawʿ, second question: does the growth outside the contract follow its aṣl in
ḍamān or amāna? «وهل يكون تابعا للأصل في الضمان وعدمه فيه وجهان: أحدهما: أنه تابع له فيهما.
والثاني: إن شارك الأصل في المعنى الذي أوجب الضمان أو الائتمان تبعه وإلا فلا». The qāʿida marks
neither wajh. The reading takes the first (RQ-02's policy in force): the growth follows its aṣl,
maḍmūn where the aṣl is maḍmūn and held on the aṣl's amāna where it is amāna. `_sharesGround`:
the record says the growth shares the meaning that made its aṣl maḍmūn or amāna; only the second
wajh reads it. The output is that the growth takes its aṣl's status in the hand. -/
def growthFollowsHand (_sharesGround : Bool) : Bool := true

/-- The second wajh, kept beside the reading so that its side is expressible: the growth follows
only where it shares the ground of its aṣl's ḍamān or amāna. -/
def growthFollowsHandSecondWajh (sharesGround : Bool) : Bool := sharesGround

/-- Where the growth shares its aṣl's ground the two wujūh agree. -/
theorem wujuh_agree_on_shared_ground : growthFollowsHand true = growthFollowsHandSecondWajh true := rfl

/-- The wujūh part only where the growth does not share it, the second then setting it apart. -/
theorem wujuh_part_off_shared_ground :
    growthFollowsHand false = true ∧ growthFollowsHandSecondWajh false = false := ⟨rfl, rfl⟩

/-- The fusūkh: «وأما في الفسوخ فلا تتبع فيها النماء الحاصل من الكسب بغير خلاف، وأما المتولد من
العين ففي تبعيته فيها روايتان في الجملة ترجعان إلى أن الفسخ هل هو رفع للعقد من أصله أو من حينه
والأصح عدم الاستتباع». `fromSubstance`: the growth is born of the thing, not earned;
`liftsFromOrigin`: the record says this faskh lifts the contract (or the ownership) from its
origin, as al-Qāḍī and Ibn ʿAqīl say of the faskh in the khiyār period («فسخ للعقد من أصله») and
Ibn Rajab of the found property whose owner comes («فانفسخ الملك من أصله»). The two riwāyāt return
to that question, so the growth born of the thing goes back with it only on a faskh from the
origin; a faskh otherwise lifts it from now and the growth stays, which is the qāʿida's «والأصح
عدم الاستتباع». The output is that the growth returns with the thing. -/
def faskhGrowthFollows (fromSubstance liftsFromOrigin : Bool) : Bool :=
  fromSubstance && liftsFromOrigin

/-- Earnings never return in a faskh: «بغير خلاف». -/
theorem earnings_stay_in_faskh (o : Bool) : faskhGrowthFollows false o = false := by
  cases o <;> rfl

/-- A faskh from now leaves the growth where it grew. -/
theorem faskh_from_now_leaves_growth (s : Bool) : faskhGrowthFollows s false = false := by
  cases s <;> rfl

/-- Link to qawāʿid 20–21 (`Usul.Refinements.growthKind`): what returns in a faskh is only growth
that is as a part of the thing, the child among it, for the qāʿida opposes it to earnings
(«لا يرد كالكسب»; «بناء على أن الولد جزء أو كسب»). -/
theorem faskh_returns_only_part (s o : Bool) (h : faskhGrowthFollows s o = true) :
    Usul.Refinements.growthKind s = .part := by
  cases s <;> cases o <;> first | rfl | exact absurd h (by decide)

/-- Rights tied to things without a contract or a faskh, where they are not ownership: «فإن كانت
حقا لازما لا يمكن إبطاله بوجه كحق الاستيلاد وسرى حكمه إلى الأولاد دون الأكساب ... وإن كان غير
لازم بل يمكن إبطاله إما باختيار المالك أو برضى المستحق لم يتبع النماء فيه الأصل بحال».
`lazimRight`: the right is lāzim; Ibn Rajab measures its strength by whether it bars the owner's
disposal («لأن حق الجناية ليس بالقوي، ولهذا لم يمنع التصرف عندنا»; of the estate, «تعلق رهن يمنع
التصرف فيه»). `fromSubstance`: the growth is born of the thing. The output is that the right
reaches the growth. -/
def rightGrowthFollows (lazimRight fromSubstance : Bool) : Bool := lazimRight && fromSubstance

/-- A lāzim right such as istīlād reaches the children and not the earnings. -/
theorem lazim_right_children_not_earnings :
    rightGrowthFollows true true = true ∧ rightGrowthFollows true false = false := ⟨rfl, rfl⟩

/-- A right that can be undone reaches no growth «بحال». -/
theorem undoable_right_reaches_nothing (s : Bool) : rightGrowthFollows false s = false := by
  cases s <;> rfl

/-- Link to qawāʿid 20–21: such a right reaches only growth that is as a part of the thing. -/
theorem right_reaches_only_part (l s : Bool) (h : rightGrowthFollows l s = true) :
    Usul.Refinements.growthKind s = .part := by
  cases l <;> cases s <;> first | rfl | exact absurd h (by decide)

end Usul.Readings.RajabA28
