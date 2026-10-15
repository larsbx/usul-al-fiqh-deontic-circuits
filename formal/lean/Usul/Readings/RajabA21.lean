/-!
# Shard rajab-a21: readings of Ibn Rajab's qawāʿid 147, 149, 150, 152 and 155

Each reading is formalised from the qāʿida's own statement in the pinned witness
(`openiti-rajab-shamela21730`), status `candidate`. Where a record reports a split, the reading
gives the qāʿida's own statement; the other sides stay recorded positions in the takhrīj suite
`corpus/takhrij/rajab_m8_rajab_a21_furu.json`.
-/

namespace Usul.Readings.RajabA21

/-- Qāʿida 147: «أحكام النساء على النصف من أحكام الرجال في مواضع». `female`: the party whose
measure is in question is a woman; `listedPoint`: the ruling is one of the points the qāʿida
lists (inheritance, diya, ʿaqīqa, testimony, gifts to children, the days of prayer). The output
is that her measure on that point is half a man's. -/
def womanHalf (female listedPoint : Bool) : Bool := female && listedPoint

/-- A man's measure is never the halved one. -/
theorem man_not_halved (p : Bool) : womanHalf false p = false := rfl

/-- Off the listed points the qāʿida halves nothing. -/
theorem unlisted_not_halved (w : Bool) : womanHalf w false = false := by
  cases w <;> rfl

/-- Qāʿida 149: «الحق الثابت لمعين يخالف الثابت لغير معين في أحكام». `holderDeterminate`: the
right is held by (or the property is owed to) a determinate person: a determinate heir, a known
owner, a determinate creditor. The output is that the ruling proper to a determinate holder's
right applies (the third that protects heirs, return to the owner, the term kept for the heir,
payment on his demand); a right for an indeterminate party differs from it. -/
def determinateHolderRule (holderDeterminate : Bool) : Bool := holderDeterminate

/-- A right owed to no determinate holder does not take the determinate holder's ruling. -/
theorem indeterminate_differs : determinateHolderRule false = false := rfl

/-- Qāʿida 150: «تعتبر الأسباب في عقود التمليكات كما يعتبر في الأيمان». `givenForCause`: the
transfer (gift, sale, added portion, waiver) was made because of a cause (a loan, an office, an
intercession, a contract, a marriage); `independentCause`: a cause other than that one is shown
for it, such as a custom of gifting that preceded the loan or the office («ممن لم يجر له منه
عادة»). The output is that the transfer is governed by its cause: it takes the cause's ruling
(barred where the cause bars it, returned when the cause fails). -/
def causeGovernsTransfer (givenForCause independentCause : Bool) : Bool :=
  givenForCause && !independentCause

/-- An independent cause (a prior custom) takes the transfer out of the cause's ruling,
whatever else holds. -/
theorem independent_cause_frees (c : Bool) : causeGovernsTransfer c true = false := by
  cases c <;> rfl

/-- A transfer made for no cause is not governed by one. -/
theorem no_cause_not_governed (i : Bool) : causeGovernsTransfer false i = false := rfl

/-- Qāʿida 152: «المحرمات في النكاح أربعة أنواع»: by nasab, by ṣihr, by combination, by riḍāʿ.
`nasabDabit`: she falls under the ḍābiṭ of nasab («يحرم على الإنسان أصوله وفروعه، وفروع أصله
الأدنى وإن سفلن، وفروع أصوله البعيدة دون بناتهن»); `sihrClass`: she is in one of the four ṣihr
classes («حلائل الآباء والأبناء وأمهات النساء وبنات النساء المدخول بهن»); `jamRahm`: she and a
wife already held have between them a maḥram raḥim such that, were one male, he could not marry
the other «لأجل النسب دون الصهر»; `radaCounterpart`: she stands to him by riḍāʿ where, by nasab,
she would fall under one of the three kinds («فيحرم به ما يحرم من النسب في الأنواع الثلاثة
المتقدمة»). The output is that the marriage (or the combination) is prohibited. -/
def marriageProhibited (nasabDabit sihrClass jamRahm radaCounterpart : Bool) : Bool :=
  nasabDabit || sihrClass || jamRahm || radaCounterpart

/-- Outside the four kinds every relative is lawful: «ولم يبق من الأقارب حلالا سوى ...». -/
theorem outside_four_kinds_lawful : marriageProhibited false false false false = false := rfl

/-- The riḍāʿ counterpart of any of the three kinds prohibits, whatever else holds. -/
theorem rada_counterpart_prohibits (n s j : Bool) : marriageProhibited n s j true = true := by
  cases n <;> cases s <;> cases j <;> rfl

/-- Qāʿida 155: «يتقرر المهر كله للمرأة بأحد ثلاثة أشياء»: «الوطء ... الخلوة ممن يمكن الوطء
بمثله ... الموت قبل الدخول». `intercourse`: he had intercourse with her; `khalwa`: he was alone
with her; `capable`: he is one whose like can have intercourse; `death`: one of them died before
consummation. The output is that the whole mahr is established for her. -/
def mahrEstablished (intercourse khalwa capable death : Bool) : Bool :=
  intercourse || (khalwa && capable) || death

/-- A khalwa with one who cannot have intercourse establishes nothing by itself. -/
theorem khalwa_without_capacity (k : Bool) : mahrEstablished false k false false = false := by
  cases k <;> rfl

/-- Intercourse establishes the mahr «على كل حال». -/
theorem intercourse_establishes (k c d : Bool) : mahrEstablished true k c d = true := rfl

/-- Death before consummation establishes the mahr whatever else holds. -/
theorem death_establishes (i k c : Bool) : mahrEstablished i k c true = true := by
  cases i <;> cases k <;> cases c <;> rfl

end Usul.Readings.RajabA21
