/-!
# Shard rajab-a17: readings of Ibn Rajab's qawāʿid 132, 134, 136, 139 and 141

Each reading is formalised from the qāʿida's own statement in the pinned witness
(`openiti-rajab-shamela21730`), status `candidate`. Where the statement leaves a branch open
(«على روايتين», «فيه قولان في المذهب», «وفي بلوغه خلاف»), the reading takes one of the sides the
qāʿida itself names and says which; the other sides stay recorded positions in the takhrīj suite
`corpus/takhrij/rajab_m8_rajab_a17_furu.json`.
-/

namespace Usul.Readings.RajabA17

/-- Qāʿida 132: «القدرة على اكتساب المال بالصناعات غني بالنسبة إلى نفقة النفس، ومن تلزم نفقته من
زوجة وخادم وهل هو غني فاضل عن ذلك على روايتين». The capacity to earn by a craft is richness for
his own maintenance and that of those he must maintain; for what lies beyond it (ḥajj, debts,
the ʿaql, the jizya) the qāʿida gives two riwāyas, and the reading takes the one that it is
surplus richness too («غني فاضل»). `hasWealth`: he holds wealth that counts; `canEarnByCraft`:
he is able to earn by a craft; `beyondOwnMaintenance`: the obligation in question lies beyond his
own maintenance and his dependants'. The output is that he counts as rich for it. -/
def craftCountsAsRich (hasWealth canEarnByCraft _beyondOwnMaintenance : Bool) : Bool :=
  hasWealth || canEarnByCraft

/-- For his own maintenance the capacity to earn is richness on both riwāyas. -/
theorem craft_rich_for_own_maintenance (w : Bool) : craftCountsAsRich w true false = true := by
  cases w <;> rfl

/-- Without wealth or a craft he is never rich, whatever the obligation. -/
theorem no_wealth_no_craft_not_rich (b : Bool) : craftCountsAsRich false false b = false := by
  cases b <;> rfl

/-- Qāʿida 134: «المنع أسهل من الرفع». An impediment that is present before a ruling or state is
established prevents it; one that supervenes after it was established does not lift it
(«يمنعه ابتداء ولا يفسخه في الدوام», «الإسلام يمنع ابتداء الرق ولا يرفعه بعد حصوله»).
`impediment`: there is an impediment (or a preventive measure) to the ruling; `beforeEstablishment`:
it is present before the ruling or state was established. The output is that it takes effect. -/
def impedimentOperates (impediment beforeEstablishment : Bool) : Bool :=
  impediment && beforeEstablishment

/-- With no impediment nothing operates, before or after. -/
theorem no_impediment_no_effect (b : Bool) : impedimentOperates false b = false := by
  cases b <;> rfl

/-- A supervening impediment does not lift what was established. -/
theorem supervening_does_not_lift : impedimentOperates true false = false := rfl

/-- Qāʿida 136: «الوطء المحرم العارض هل يستتبع تحريم مقدماته أم لا؟ إن كان لضعف الملك وقصوره أو خشية
عدم ثبوته ... فيحرم سائر أنواع الاستمتاع بها، وإن كان لغير ذلك من الموانع فهو نوعان: أحدهما العبادات
المانعة من الوطء ... ضرب يمتنع فيه جنس الترفه والاستمتاع بالنساء فيمنع الوطء والمباشرة كالإحرام القوي
... والاعتكاف. وضرب يمتنع فيه الجماع وما أفضى إلى الإنزال ... وهو الصيام ... النوع الثاني غير
العبادات فهل يحرم مع الوطء غيره فيه قولان في المذهب». For the second type the reading takes the
side of the qāʿida's first example, «الحيض والنفاس يحرم بهما الوطء في الفرج ولا يحرم ما دونه في
المذهب الصحيح». `weakOwnership`: the bar is for the weakness of the ownership or the fear that it
is not established; `worship`: the bar is an act of worship; `barsIndulgence`: that worship bars
the genus of indulgence with women (strong iḥrām, iʿtikāf). The output is that the preliminaries
of intercourse are forbidden too. -/
def preliminariesForbidden (weakOwnership worship barsIndulgence : Bool) : Bool :=
  weakOwnership || (worship && barsIndulgence)

/-- A bar for weakness of ownership forbids every kind of enjoyment. -/
theorem weak_ownership_forbids_all (w b : Bool) : preliminariesForbidden true w b = true := rfl

/-- Fasting forbids intercourse but not the preliminaries. -/
theorem fasting_spares_preliminaries : preliminariesForbidden false true false = false := rfl

/-- A bar that is not worship (with ownership sound) forbids intercourse alone on this reading. -/
theorem non_worship_spares_preliminaries (b : Bool) : preliminariesForbidden false false b = false := by
  cases b <;> rfl

/-- Qāʿida 139: «الحقوق الواجبة من جنس إذا كان بعضها مقدرا بالشرع وبعضها غير مقدر به، فهي ثلاثة
أنواع». The first, «من لم يقدر حقه يستحق الجميع عند الانفراد»: the unfixed may exceed the fixed.
The second, «أن يكون التقدير لنهاية الاستحقاق وغير المقدر موكولا إلى الرأي والاجتهاد من غير تقديره
بأصل يرجع إليه فلا يراد الحق الذي لم يقدر على المقدر»: it does not reach it. The third, tied to a
base: «إن كان محلهما واحدا لم يجاوز به المقدر وفي بلوغه خلاف، وإن كان محلهما مختلفا فالخلاف في بلوغ
المقدر ومجاوزته»; the reading takes, in one locus, that it does not reach it (the ḥukūma), and in
different loci, that it may (the slave's full value against the free man's diya).
`takesAllWhenAlone`: the holder of the unfixed right takes the whole when alone;
`tiedToBase`: the unfixed right's estimate goes back to a base that governs it; `sameLocus`: the
two rights fall on one locus. The output is that the unfixed right may reach the fixed one. -/
def unfixedMayReachFixed (takesAllWhenAlone tiedToBase sameLocus : Bool) : Bool :=
  takesAllWhenAlone || (tiedToBase && !sameLocus)

/-- The second type: a discretionary right with no base never reaches the fixed one. -/
theorem discretion_without_base_stays_below (l : Bool) :
    unfixedMayReachFixed false false l = false := by
  cases l <;> rfl

/-- In one locus the estimated right does not reach the fixed one. -/
theorem same_locus_stays_below : unfixedMayReachFixed false true true = false := rfl

/-- Qāʿida 141: «إذا أتلف عينا تعلق بها حق الله تعالى من يجب عليه حفظها واستيفاؤها إلى مدة معلومة
لزمه ضمانها بقيمتها في ذلك الوقت، لا يوم تلفها أو بمثلها على صفاتها في ذلك الوقت لا يوم تلفها على
أصح الوجهين». `custodianUntilTerm`: the destroyer is the one bound to keep the thing and carry out
God's right in it until a known term. The output is that his liability is reckoned at the term,
not at the day of destruction. -/
def dueTimeGoverns (custodianUntilTerm : Bool) : Bool := custodianUntilTerm

/-- Anyone else (an outsider) is liable at the day of destruction. -/
theorem outsider_at_destruction : dueTimeGoverns false = false := rfl

end Usul.Readings.RajabA17
