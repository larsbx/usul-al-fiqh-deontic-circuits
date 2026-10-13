/-!
# Shard rajab-a12: readings of Ibn Rajab's qawāʿid 116, 117 and 118

Each reading is formalised from the qāʿida's own statement in the pinned witness
(`openiti-rajab-shamela21730`), status `candidate`. Where the statement poses a question
(«فيه خلاف», «قولان»), the reading takes one side and names its ground; the other side stays a
recorded position in the takhrīj suite `corpus/takhrij/rajab_m8_rajab_a12_furu.json`.
-/

namespace Usul.Readings.RajabA12

/-- Qāʿida 116: «من استند تملكه إلى سبب مستقر لا يمكن إبطاله وتأخر حصول الملك عنه فهل ينعطف
إحكام ملكه إلى أول وقت انعقاد السبب ويثبت إحكامه من حينئذ أم لا يثبت إلا من حين ثبوت الملك؟
فيه خلاف». The reading takes the side the qāʿida's own condition implies: the ruling relates
back to the cause where the cause is settled, and not where it is not, as Ibn Rajab says of the
fuḍūlī's contract, «ولكن السبب هنا غير مستقر لإمكان زواله بالرد ويشهد للوجه الثاني», and as
he marks the walāʾ of a mukātab who paid the heirs, «والمذهب أن الولاء للسيد الأول».
`settledCause`: the ownership rests on a cause that cannot be voided. The output is that the
ruling of the ownership is reckoned from the time the cause was concluded. -/
def ruledFromCause (settledCause : Bool) : Bool := settledCause

/-- The qāʿida's own exception: a cause that can still be voided (the fuḍūlī's contract before
ratification) does not carry the ruling back. -/
theorem unsettled_cause_not_retroactive : ruledFromCause false = false := rfl

/-- Qāʿida 116, its attached class: «ويلتحق بهذه القاعدة العبادات التي يكتفي بحصول بعض شرائطها
في أثناء وقتها إذا وجد الشرط في أثنائها فهل يحكم لها بحكم ما اجتمعت شرائطها من ابتدائها أم لا؟
فيه خلاف أيضا». `conditionWithinTime`: the missing condition was attained within the act's time,
where attaining it midway suffices. The output, on the reading's side of the khilāf, is that the
act is ruled as one whose conditions were met from its beginning. -/
def worshipFromStart (conditionWithinTime : Bool) : Bool := conditionWithinTime

/-- The text joins the class to the qāʿida («ويلتحق بهذه القاعدة»): a condition attained in time
stands as a settled cause, and the act takes the qāʿida's ruling. -/
theorem worship_joins_q116 (c : Bool) : worshipFromStart c = ruledFromCause c := rfl

/-- Qāʿida 117: «كل عقد معلق يختلف باختلاف حالين إذا وجد تعليقه في أحدهما ووقوعه في الآخر فهل
يغلب عليه جانب التعليق أو جانب الوقوع في المسألة قولان إلا أن يقتضي اعتبار أحدهما إلى ما هو
ممتنع شرعا فيلغي». The reading takes the side of the state of occurrence, the side of the farʿ
the aṣḥāb report without dispute («فإنه يقع الطلاق بدعيا ... ولم يحك الأصحاب فيه خلافا»), and
drops whichever side the sharʿ bars. `suspensionBarred`: taking the state of suspension leads
to what is sharʿan impossible; `occurrenceBarred`: taking the state of occurrence does. The
output is that the state of occurrence governs. -/
def occurrenceGoverns (suspensionBarred occurrenceBarred : Bool) : Bool :=
  suspensionBarred || !occurrenceBarred

/-- With neither side barred, the reading's side: the state of occurrence. -/
theorem occurrence_by_default : occurrenceGoverns false false = true := rfl

/-- The qāʿida's exception: a side the sharʿ bars is dropped, «فيلغي». -/
theorem barred_side_dropped :
    occurrenceGoverns true false = true ∧ occurrenceGoverns false true = false :=
  ⟨rfl, rfl⟩

/-- Qāʿida 118: «تعليق فسخ العقد وإبطاله لوجوده إن كان فيه مقصود معتبر شرعا صح وإلا لم يصح إذ
لو صح لصار العقد غير مقصود في نفسه». `legitimatePurpose`: the suspension serves a purpose the
sharʿ recognises (as «لأن الملك يراد للعتق ويكون مقصودا»). The output is that the suspension
is valid. -/
def cancelOnExistenceValid (legitimatePurpose : Bool) : Bool := legitimatePurpose

end Usul.Readings.RajabA12
