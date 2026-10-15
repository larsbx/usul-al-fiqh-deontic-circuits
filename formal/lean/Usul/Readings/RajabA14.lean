/-!
# Shard rajab-a14: readings of Ibn Rajab's qawāʿid 121, 123 and 126

Each reading is formalised from the qāʿida's own statement in the pinned witness
(`openiti-rajab-shamela21730`), status `candidate`. Where the statement leaves a class to khilāf
(«ففيه وجهان», «في المسألة خلاف»), the reading takes one side and names its ground in the text;
the other side stays a recorded position in the takhrīj suite
`corpus/takhrij/rajab_m8_rajab_a14_furu.json`. All three readings return the same output: whether
the general wording covers the instance at issue.
-/

namespace Usul.Readings.RajabA14

/-- Qāʿida 121, «في تخصيص العموم بالعرف». Its three classes:
* `urfiHaqiqa`: the general name has come to be used for some of its members «حتى صار حقيقة
  عرفية», «فهذا يختص به العموم بغير خلاف»;
* `onlyQualified`: the instance is «ما لا يطلق عليه الاسم العام إلا مقيدا به ولا يفرد بحال»,
  «فهذه لا يدخل في العموم بغير خلاف نعلمه»;
* `mostlyQualified`: «ما يطلق عليه الاسم العام لكن الأكثر أن لا يذكر معه إلا بقيد أو قرينة، ولا
  يكاد يفهم عند الإطلاق دخوله فيه، ففيه وجهان».
For the third class the reading takes the side the qāʿida is headed for, the specialisation of
the general by custom, which Aḥmad's own naṣṣ in the vow of one's property states: «ذلك على قدر
ما نوى وعلى قدر مخرج يمينه، والأموال عند الناس تختلف». The output is whether the general
wording, used without qualification or intention, covers the instance. -/
def urfGeneralCovers (urfiHaqiqa onlyQualified mostlyQualified : Bool) : Bool :=
  !(urfiHaqiqa || onlyQualified || mostlyQualified)

/-- A customary ḥaqīqa specialises the general, «بغير خلاف», whatever the other classes. -/
theorem urfi_haqiqa_bars (o m : Bool) : urfGeneralCovers true o m = false := by
  cases o <;> cases m <;> rfl

/-- What is named only with its qualifier never enters the general, «بغير خلاف نعلمه». -/
theorem only_qualified_bars (u m : Bool) : urfGeneralCovers u true m = false := by
  cases u <;> cases m <;> rfl

/-- The reading's side of the two wujūh: what is mostly named with a qualifier is not covered. -/
theorem mostly_qualified_bars (u o : Bool) : urfGeneralCovers u o true = false := by
  cases u <;> cases o <;> rfl

/-- Outside the three classes, the general covers the instance. -/
theorem plain_member_covered : urfGeneralCovers false false false = true := rfl

/-- Qāʿida 123: «ويخص العموم بالشرع أيضا على الصحيح». `sharExcludes`: the sharʿ sets the
instance apart from what the general wording can bear (a day whose fast is forbidden or already
obligatory, forbidden meat, an heir in a bequest, a forbidden divorce, the Friday prayer within a
continuous iʿtikāf). The output is whether the general wording covers the instance. -/
def sharGeneralCovers (sharExcludes : Bool) : Bool := !sharExcludes

/-- What the sharʿ sets apart is never covered. -/
theorem shar_excluded_not_covered : sharGeneralCovers true = false := rfl

/-- The qāʿida's «أيضا» joins it to the specialisation by custom: the sharʿ specialises the
general as a class of custom does, and leaves it whole where it sets nothing apart. -/
theorem shar_like_urf (s : Bool) : sharGeneralCovers s = urfGeneralCovers s false false := by
  cases s <;> rfl

/-- Qāʿida 126: «الصور التي لا تقصد من العموم عادة إما لندورها أو لاختصاصها بمانع لكن يشملها
اللفظ مع اعتراف المتكلم بأنه لم يرد إدخالها فيه هل يحكم بدخولها أم لا؟ في المسألة خلاف».
`rareOrBarred`: the instance is one not ordinarily intended, for its rarity or an impediment
proper to it; `intended`: the speaker declared or is shown to have meant it («حتى يصرح
بدخولهم»). The reading takes the side Ibn Rajab names «صورة القاعدة» when he derives Aḥmad's
naṣṣ, «فإنها لا تقصد بالتحريم فلا تدخل في العموم لكونها لا تقصد عادة»: an instance not
ordinarily intended, and not intended, is not covered. An instance ordinarily intended stays
covered whatever the speaker says, «فلا يصح إخراجه من العموم بعدم إرادة دخوله». The output is
whether the general wording covers the instance. -/
def unintendedCovered (rareOrBarred intended : Bool) : Bool := intended || !rareOrBarred

/-- A declared intention brings any instance in. -/
theorem intended_covered (r : Bool) : unintendedCovered r true = true := by
  cases r <;> rfl

/-- The most prominent instance (the wife in «ما أحل الله علي حرام») cannot be taken out by not
intending it. -/
theorem ordinary_instance_covered (i : Bool) : unintendedCovered false i = true := by
  cases i <;> rfl

/-- The qāʿida's own case, on the reading's side: rare or barred, and not intended. -/
theorem rare_unintended_not_covered : unintendedCovered true false = false := rfl

end Usul.Readings.RajabA14
