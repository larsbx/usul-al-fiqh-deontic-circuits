/-!
# Shard rajab-a16: readings of Ibn Rajab's qawāʿid 129, 130 and 131

Qāʿida 127 is read on main as `Usul.Readings.Mubashara.damanOn` (shard rajab-q127); this shard's
duplicate reading and annotations of it were dropped at integration.

Each reading is formalised from the qāʿida's own statement in the pinned witness
(`openiti-rajab-shamela21730`), status `candidate`. Where the statement poses a question
(«فيه للأصحاب أوجه»), the reading takes one of the sides the qāʿida itself names; the other sides
stay recorded positions in the takhrīj suite `corpus/takhrij/rajab_m8_rajab_a16_furu.json`.
-/

namespace Usul.Readings.RajabA16

/-- Qāʿida 129: «إذا تعينت حال المرمي تجيئ بين الرمي والإصابة، فهل الاعتبار بحال الإصابة أم بحالة
الرمي، أم يفرق بين القود والضمان ...؟ فيه للأصحاب أوجه». The reading takes the qāʿida's third
option, the split between qawad and ḍamān: liability (ḍamān of a person, his diya, the value of a
slave, the jazāʾ of game) is reckoned at the hit, as the aṣḥāb report of the diya «اعتبارا بحالة
الإصابة»; qawad and the other conditions of the act are reckoned at the shot, «لفقد التكافؤ حين
الجناية وهو حالة الإرسال». `liabilityRuling`: the ruling in question is a liability (ḍamān). The
output is that the state at the hit governs. -/
def hitStateGoverns (liabilityRuling : Bool) : Bool := liabilityRuling

/-- Qawad is never reckoned at the hit on this reading. -/
theorem qawad_at_shot : hitStateGoverns false = false := rfl

/-- Qāʿida 129, the ʿāqila of a shooter whose affiliation changed between the shot and the hit:
«يجب ضمانه في ماله ; لأنه لم يكن مسلما حال الرمي لتعقله عاقلته المسلمون، ولا يجب على عاقلته من
أهل الذمة ; لأنه حين الإصابة كان مسلما وبذلك جزم صاحب المحرر والكافي». Both states are given
effect: a body of kin bears the diya only if the shooter belonged to it at the shot and at the
hit. `memberAtShot`, `memberAtHit`: he belonged to that ʿāqila at the shot / at the hit. The
output is that this ʿāqila bears the diya. -/
def aqilaBears (memberAtShot memberAtHit : Bool) : Bool := memberAtShot && memberAtHit

/-- A change of affiliation between shot and hit bars every ʿāqila: the diya falls in his own
wealth. -/
theorem changed_affiliation_bars_aqila (h : Bool) :
    aqilaBears false h = false ∧ aqilaBears h false = false := by
  cases h <;> exact ⟨rfl, rfl⟩

/-- Qāʿida 130: «المسكن والخادم والمركب المحتاج إليه ليس بمال فاضل يمنع أخذ الزكوات ولا يجب فيه
الحج والكفارات ولا يوفي منه الديون والنفقات نص على ذلك أحمد». `needed`: the house, servant or
mount is needed by him. The output is that it counts as surplus wealth (barring zakāt, obliging
ḥajj and expiation (kaffāra), sold for debts and maintenance). -/
def countsAsSurplus (needed : Bool) : Bool := !needed

/-- What he needs never counts as surplus. -/
theorem needed_not_surplus : countsAsSurplus true = false := rfl

/-- Qāʿida 131: «القدرة على اكتساب المال بالبضع ليس بغنى معتبر، صرح به القاضي في خلافه».
`hasWealth`: she (or he) holds wealth that counts; `canEarnByBudh`: she can obtain wealth by
marriage (a mahr), or he by marrying off his umm walad. The output is that the person counts as
rich. -/
def countsAsRich (hasWealth _canEarnByBudh : Bool) : Bool := hasWealth

/-- The capacity to earn by the buḍʿ adds nothing to richness. -/
theorem budh_capacity_irrelevant (w : Bool) : countsAsRich w true = countsAsRich w false := rfl

end Usul.Readings.RajabA16
