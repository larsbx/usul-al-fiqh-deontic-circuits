/-!
# Shard rajab-a15: readings of Ibn Rajab's qawāʿid 125 and 128

Each reading is formalised from the qāʿida's own statement in the pinned witness
(`openiti-rajab-shamela21730`), status `candidate`. Where the statement poses a question
(«على وجهين», «على روايتين»), the reading takes one side and names its ground; the other side
stays a recorded position in the takhrīj suite `corpus/takhrij/rajab_m8_rajab_a15_furu.json`.
-/

namespace Usul.Readings.RajabA15

/-- Qāʿida 125: «النية تعم الخاص وتخصص العام بغير خلاف فيها، وهل تقيد المطلق أو تكون استثناء
من النص؟ على وجهين فيها». The first two of its four aqsām (the intention generalising the
specific, and specifying the general) are without dispute: the intention governs the wording.
In the two disputed aqsām the reading takes the side that the intention does not govern: for
the restriction of an absolute, on Ibn Rajab's own ground «وهذا بخلاف تقييد المطلق فإنه زيادة
على مدلوله فلا تثبت الزيادة بالنية المجردة» and Aḥmad's naṣṣ in the vow of alms (riwāyat Abī
Dāwūd, «أنه لا يلزمه ما نواه»); for an exception from an explicit text, on «لأن النية إنما تصرف
اللفظ إلى محتمل ولا احتمال في النص الصريح» and Aḥmad's «النية فيما خفي ليس فيما ظهر».
`restrictsAbsolute`: the intention would restrict an absolute term (a taqyīd, an addition to its
meaning); `exceptsFromText`: the intention would except from an explicit text (a number, a
naṣṣ) rather than from a general. The output is that the intention governs the wording (it
takes effect, at least between him and God). -/
def intentionGoverns (restrictsAbsolute exceptsFromText : Bool) : Bool :=
  !restrictsAbsolute && !exceptsFromText

/-- The undisputed aqsām: generalising the specific and specifying the general. -/
theorem undisputed_aqsam : intentionGoverns false false = true := rfl

/-- A restriction of an absolute never takes effect by bare intention, whatever else holds. -/
theorem restriction_barred (e : Bool) : intentionGoverns true e = false := rfl

/-- An exception from an explicit text never takes effect by bare intention, whatever else holds. -/
theorem text_exception_barred (r : Bool) : intentionGoverns r true = false := by
  cases r <;> rfl

/-- Qāʿida 128: «إذا اختلف حال المضمون في حالي الجناية والسراية. فهاهنا أربعة أقسام». Of the
four, the text settles three: guaranteed in both states, there is ḍamān; «أن يكون مهدرا في
الحالين فلا ضمان بحال»; «أن تكون الجناية مهدرة والسراية في حال الضمان فتهدر تبعا للجناية
بالاتفاق». In the fourth, «أن تكون الجناية في حال الضمان والسراية في حال الإهدار، فهل يسقط
الضمان أم لا؟ على وجهين», the reading takes the side that it does not fall, on the ground the
text gives for the first qism, «لأن السراية لا تثبت منفردة وإنما تجب تابعة للجناية» (Abū Bakr,
al-Qāḍī and the aṣḥāb), and as al-Qāḍī and Abū al-Khaṭṭāb hold of game wounded in the ḥaram that
dies in the ḥill («لزمه كمال ضمانه»). `guaranteedAtInjury`: the victim was guaranteed on the
injurer when the injury was done; `guaranteedAtSpread`: he was guaranteed when the injury spread
to his death. The output is that the spread (the death from the injury) is guaranteed. -/
def spreadFollowsInjury (guaranteedAtInjury _guaranteedAtSpread : Bool) : Bool :=
  guaranteedAtInjury

/-- The second and third aqsām: an unguaranteed injury makes the spread unguaranteed, whatever
the state at the spread («فتهدر تبعا للجناية بالاتفاق»). -/
theorem unguaranteed_injury_barred (s : Bool) : spreadFollowsInjury false s = false := rfl

/-- The fourth qism, on the reading's side: the ḍamān does not fall with the spread's state. -/
theorem fourth_qism_guaranteed : spreadFollowsInjury true false = true := rfl

/-- Qāʿida 128, its first qism: «أن يكون مضمونا في الحالين، لكن يتفاوت قدر الضمان فيهما، فهل
الاعتبار بحال السراية أو حال الجناية؟ على روايتين». The reading takes the state of the injury,
on the same ground («وإنما تجب تابعة للجناية») and al-Qāḍī's «قياس المذهب» where the value fell
between the injury and the death («لأن موته حصل بقطع يده وقيمته في تلك الحال ألفان»). The
output is that the ḍamān is measured by the injury's state; outside the first qism there is no
ḍamān owed in both states to measure, and the output is false. -/
def measuredAtInjury (guaranteedAtInjury guaranteedAtSpread : Bool) : Bool :=
  guaranteedAtInjury && guaranteedAtSpread

/-- The measure question arises only in the first qism: either state unguaranteed, no measure. -/
theorem measure_needs_both (a s : Bool) :
    measuredAtInjury false s = false ∧ measuredAtInjury a false = false := by
  cases a <;> exact ⟨rfl, rfl⟩

/-- One ground for both readings («تابعة للجناية»): a ḍamān measured by the injury's state is a
ḍamān of the spread. -/
theorem measure_implies_spread_guaranteed (a s : Bool) (h : measuredAtInjury a s = true) :
    spreadFollowsInjury a s = true := by
  cases a <;> cases s <;> simp_all [measuredAtInjury, spreadFollowsInjury]

end Usul.Readings.RajabA15
