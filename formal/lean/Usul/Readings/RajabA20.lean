/-!
# Shard rajab-a20: readings of Ibn Rajab's qawāʿid 144 and 146

Each reading is formalised from the qāʿida's own statement in the pinned witness
(`openiti-rajab-shamela21730`), status `candidate`. Where the statement reports a split
(«ففيه قولان في المذهب أشهرهما»), the reading takes the side the qāʿida itself marks; the other
sides stay recorded positions in the takhrīj suite `corpus/takhrij/rajab_m8_rajab_a20_furu.json`.
-/

namespace Usul.Readings.RajabA20

/-- Qāʿida 144, its first kind, the rights the deceased held: «ما كان من حقوقه يجب بموته كالدية
والقصاص في النفس فلا ريب في أن لهم استيفاءه ... وما كان واجبا له في حياته إن كان قد طالب به
أو هو في يده ثبت لهم إرثه»; of what he did not claim, «حقوق التملكات والحقوق التي ليست بمالية
... ففيه قولان في المذهب أشهرهما: أنه لا يورث», while «حقوق أملاك ثابتة متعلقة بالأملاك الموروثة
فينتقل إلى الورثة بانتقال الأموال المتعلقة بها بدون المطالبة». The reading takes the marked
«أشهرهما». `accruesAtDeath`: the right falls due by his death (diya, qiṣāṣ for his life);
`claimedOrHeld`: he claimed it in his life, or it was in his hand; `attachedToProperty`: it is a
right of property attached to the property his heirs inherit (rahn, kafāla, ḍamān, the term of a
debt, return for a defect). The output is that the heirs take the right. -/
def heirInherits (accruesAtDeath claimedOrHeld attachedToProperty : Bool) : Bool :=
  accruesAtDeath || claimedOrHeld || attachedToProperty

/-- An unclaimed right of acquisition, or a right that is not of property, is not inherited. -/
theorem unclaimed_personal_right_not_inherited : heirInherits false false false = false := rfl

/-- A claimed right is inherited whatever else holds. -/
theorem claimed_right_inherited (a p : Bool) : heirInherits a true p = true := by
  cases a <;> rfl

/-- A right attached to inherited property passes without any claim. -/
theorem attached_right_passes (a c : Bool) : heirInherits a c true = true := by
  cases a <;> cases c <;> rfl

/-- Qāʿida 144, its second kind, the rights owed by the deceased: «فإذا كانت لازمة قام الوارث
مقامه فيقام الوارث مقامه في إيفائها وإن كانت جائزة، فإن بطلت بالموت فلا كلام وإن لم تبطل بالموت
فالوارث قائم مقامه في إمضائها وردها»; and what does not lapse by death is the contract that tends
to bindingness, «لأنه عقد يئول إلى اللزوم فلا يبطل في الموت كالبيع في مدة الخيار، بخلاف الشركة
والمضاربة». `binding`: the obligation is binding (lāzim); `tendsToBinding`: it is a permissible
contract that tends to bindingness (a rahn or hiba before delivery). The output is that the heir
stands in the deceased's place in it. -/
def heirStandsIn (binding tendsToBinding : Bool) : Bool := binding || tendsToBinding

/-- A permissible contract that does not tend to bindingness lapses by death: the heir has no
place in it. -/
theorem lapsing_contract_no_heir : heirStandsIn false false = false := rfl

/-- A binding obligation always falls to the heir to discharge. -/
theorem binding_obligation_heir (t : Bool) : heirStandsIn true t = true := by
  cases t <;> rfl

/-- Qāʿida 146: «تفارق المطلقة الرجعية الزوجات في صور». `rajiyya`: the woman is a revocably
divorced wife in her ʿidda; `listedPoint`: the ruling in question is one of the points the qāʿida
lists. The output is that she takes a wife's ruling on that point. The reading takes the
qāʿida's own statement: on each listed point she differs from wives. -/
def wifeRuleApplies (rajiyya listedPoint : Bool) : Bool := !(rajiyya && listedPoint)

/-- On a listed point the rajʿiyya does not take the wife's ruling. -/
theorem rajiyya_differs_on_listed_point : wifeRuleApplies true true = false := rfl

/-- A wife (not a rajʿiyya) always takes the wife's ruling. -/
theorem wife_takes_wife_rule (p : Bool) : wifeRuleApplies false p = true := by
  cases p <;> rfl

end Usul.Readings.RajabA20
