/-!
# Shard rajab-a24: the reading of Ibn Rajab's qāʿida 156

Formalised from the qāʿida's own statement in the pinned witness (`openiti-rajab-shamela21730`),
status `candidate`. Where the statement reports two riwāyāt («ففي تنصف المهر وسقوطه روايتان»),
the reading pins one side as a named constant; the other side stays a recorded position in the
takhrīj suite `corpus/takhrij/rajab_m8_rajab_a24_furu.json`.
-/

namespace Usul.Readings.RajabA24

/-- The side the reading takes where the separation comes from the wife together with the husband
or with a stranger, on which the qāʿida reports «ففي تنصف المهر وسقوطه روايتان»: the reading takes
the first-named, that the named mahr is halved. -/
def mixedTakesHalf : Bool := true

/-- Qāʿida 156: «الفرقة قبل الدخول إن كانت من جهة الزوج وحده أو من جهة أجنبي وحده تنصف بها المهر
المسمى، وإن كانت من جهة الزوجة وحدها سقط بها المهر، وإن كانت من جهة الزوجين معا أو من جهة الزوجة
مع أجنبي ففي تنصف المهر وسقوطه روايتان»; and of the first kind «ويستثنى من هذا القسم الفسوخ التي
يملكها الزوج لضرر يلحقه إما لظهور عيب في الزوجة أو فوات شرط فيسقط بها المهر».
`byHusband`, `byStranger`, `byWife`: the separation before consummation comes (in part) from the
husband's, a stranger's, the wife's side; `harmFasakh`: it is an annulment the husband holds for a
harm from her (her defect, a lapsed condition). A separation from none of them (the compulsory
separation of the sixth kind) is not from the husband or a stranger. The output is that the named
mahr is halved; false is that it falls entirely. -/
def mahrHalved (byHusband byStranger byWife harmFasakh : Bool) : Bool :=
  !harmFasakh && (if byWife then (byHusband || byStranger) && mixedTakesHalf
                  else byHusband || byStranger)

/-- The husband's annulment for a harm from her drops the mahr, whatever else holds. -/
theorem harm_fasakh_drops (h s w : Bool) : mahrHalved h s w true = false := by
  cases h <;> cases s <;> cases w <;> rfl

/-- A separation from the wife alone drops the mahr. -/
theorem wife_alone_drops : mahrHalved false false true false = false := rfl

/-- A separation from the husband alone halves it. -/
theorem husband_alone_halves : mahrHalved true false false false = true := rfl

/-- A separation from a stranger alone halves it. -/
theorem stranger_alone_halves : mahrHalved false true false false = true := rfl

/-- A separation from no party's side (the compulsory kind) does not halve it. -/
theorem compulsory_drops (w : Bool) : mahrHalved false false w false = false := by
  cases w <;> rfl

/-- A separation from the wife with the husband, or with a stranger, takes the pinned side. -/
theorem mixed_takes_pinned (h s : Bool) (hs : (h || s) = true) :
    mahrHalved h s true false = mixedTakesHalf := by
  cases h <;> cases s <;> simp_all [mahrHalved, mixedTakesHalf]

end Usul.Readings.RajabA24
