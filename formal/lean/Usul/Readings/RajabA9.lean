/-!
# Shard rajab-a9: readings of Ibn Rajab's qawāʿid 107, 108 and 110

Each reading is formalised from the qāʿida's own statement (status `candidate`). Where the
statement leaves a question to khilāf, the reading returns the side the statement does not
establish, and the other side is held as a position on the farʿ, not as the reading.
-/

namespace Usul.Readings.RajabA9

/-- Qāʿida 107: «تمليك المعدوم، والإباحة له نوعان»: by way of origin «فالمشهور أنه لا يصح»;
by way of following «فيصح في الوقف والإجازة وهذا إذا صرح بدخول المعدوم»; and «إن لم يصرح
وكان المحل لا يستلزم المعدوم ففي دخوله خلاف، وكذا لو انتقل الوقف إلى قوم فحدث من يشاركهم».
`byOrigin`: the non-existent is granted to in its own right, not as following an existent;
`explicitInclusion`: the grant names its inclusion; `objectEntails`: the object of the grant
entails the non-existent. The output is whether the grant to (or inclusion of) the
non-existent holds; in the khilāf branch the statement does not establish it. -/
def maadumGrantValid (byOrigin explicitInclusion objectEntails : Bool) : Bool :=
  !byOrigin && (explicitInclusion || objectEntails)

/-- The qāʿida's first kind: a grant by way of origin does not hold, whatever it names. -/
theorem maadum_by_origin_invalid (e o : Bool) : maadumGrantValid true e o = false := rfl

/-- Qāʿida 108: «ما جهل وقوعه مترتبا أو متقارنا هل يحكم عليه بالتقارن أو بالتعاقب؟ فيه خلاف،
والمذهب الحكم بالتعاقب لبعد التقارن». `knownSimultaneous` / `knownSequential`: the order is
known to be simultaneous / sequential. The output is whether the matter is judged as
sequential; where neither is known, the madhhab judges it sequential. -/
def judgedSequential (knownSimultaneous knownSequential : Bool) : Bool :=
  knownSequential || !knownSimultaneous

/-- The qāʿida's own case: an unknown order is judged as sequence «لبعد التقارن». -/
theorem unknown_order_is_sequence : judgedSequential false false = true := rfl

/-- Qāʿida 110, its opening: «من ثبت له أحد أمرين فإن اختار أحدهما سقط الآخر، وإن أسقط
أحدهما أثبت الآخر». `choseOne`: he chose one of the two (rather than dropping one). The output
is whether the other remains his. -/
def otherOptionStands (choseOne : Bool) : Bool := !choseOne

/-- Qāʿida 110, refusal of both: «وإن امتنع منهما فإن كان امتناعه ضررا على غيره استوفى له الحق
الأصلي الثابت له إذا كان ماليا». `harmsOther`: his refusal harms another; `financial`: the
right is financial; `established`: it is an original right established for him. The output is
whether the right is exacted for him. -/
def refusalExactedForHim (harmsOther financial established : Bool) : Bool :=
  harmsOther && financial && established

/-- Qāʿida 110, refusal of both, harming another, where the right is not established: «وإن لم
يكن حقا ثابتا سقط». The output is whether his right falls. -/
def refusalRightFalls (harmsOther established : Bool) : Bool :=
  harmsOther && !established

/-- Qāʿida 110, refusal of both, harming another, where the right is not financial: «وإن كان
الحق غير مالي ألزم بالاختيار». The output is whether he is compelled to choose. -/
def refusalCompelledToChoose (harmsOther financial established : Bool) : Bool :=
  harmsOther && !financial && established

/-- Qāʿida 110, a right owed by the refuser: «وإن كان حقا عليه وأمكن استيفاؤه منه استوفي».
`rightOnHim`: the right is owed by him; `exactable`: it can be exacted from him. The output is
whether it is exacted (judged against him). -/
def rightOnRefuserExacted (rightOnHim exactable : Bool) : Bool := rightOnHim && exactable

/-- Qāʿida 110, an original and a substitute owed: «وإن كان عليه حقان أصلي وبدل فامتنع من البدل
حكم عليه بالأصل». `refusedSubstitute`: he refused the substitute. The output is whether he is
judged by the original. -/
def substituteRefusalJudgedByOriginal (refusedSubstitute : Bool) : Bool := refusedSubstitute

end Usul.Readings.RajabA9
