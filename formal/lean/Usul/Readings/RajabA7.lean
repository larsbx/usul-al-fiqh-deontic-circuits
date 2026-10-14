/-!
# Shard rajab-a7: readings of Ibn Rajab's qawāʿid 100, 101 and 102

Each reading is formalised from the qāʿida's own statement in the pinned witness
(`openiti-rajab-shamela21730`), status `candidate`. Where the statement poses a question
(«فيه خلاف»), the reading takes one side and names its ground; the other side stays a recorded
position in the takhrīj suite `corpus/takhrij/rajab_m8_rajab_a7_furu.json`.
-/

namespace Usul.Readings.RajabA7

/-- Qāʿida 100: «الواجب بالنذر. هل يلحق الواجب بالشروع أو بالمندوب؟ فيه خلاف». The reading
takes the side the qāʿida's own name gives it, a wājib: the vowed act takes the ruling of the
obligation imposed by the sharʿ (the witness reads «بالشروع»; the qāʿida's own fifth farʿ
names the term, al-Qāḍī's «حملا له على واجب الشرع»), not that of the
voluntary act (Ibn ʿAqīl's «لأن الملزم بالنذر هو التطوع المطلق»). `sharRuling` is what the
sharʿ obligation would get on the farʿ's question, the second argument what the mandūb would
get; the output is the vowed act's ruling. -/
def vowedRuling (sharRuling _mandubRuling : Bool) : Bool := sharRuling

/-- Where the sharʿ obligation and the mandūb agree there is nothing for the khilāf to turn on. -/
theorem vowed_agreeing_analogues (r : Bool) : vowedRuling r r = r := rfl

/-- Qāʿida 101: «من خير بين شيئين وأمكنه الإتيان بنصفيهما معا فهل يجزئه أم لا؟ فيه خلاف».
The reading takes the side of the furūʿ the madhhab marks («يجزئ على المشهور», «والمذهب
الإجزاء»): the two halves suffice where they are halves of one measure, so that together they
make up one whole of the thing due («لتكميل الحرية»; «عمل بمقتضى قوله في كل أربعين بنت لبون
وفي كل خمسين حقة»); a day's fast with the feeding of four poor has no common measure, and
there «فالأظهر منعه». `commonUnit`: both parts are counted in one unit (the raqaba, the ṣāʿ,
the poor of a kaffāra, the jubrān's sheep-or-ten-dirhams). The output is that it suffices. -/
def splitSuffices (commonUnit : Bool) : Bool := commonUnit

/-- Qāʿida 102: «من أتى بسبب يفيد الملك أو الحل أو يسقط الواجبات على وجه محرم وكان مما تدعو
النفوس إليه ألغى ذلك السبب وصار وجوده كالعدم ولم يترتب عليه أحكامه». `forbiddenManner`: the
cause was brought about in a forbidden way; `soulsDrawn`: it is of what souls are drawn to (not
what «في الطبع وازع عنه», as one who strikes his own head till he is mad). The output is that
the cause is cancelled («ألغى») and its effects do not follow. -/
def causeVoided (forbiddenManner soulsDrawn : Bool) : Bool := forbiddenManner && soulsDrawn

/-- A cause the nature itself deters from is not cancelled (ilghāʾ), however it was brought about. -/
theorem deterred_cause_stands (f : Bool) : causeVoided f false = false := by
  cases f <;> rfl

/-- The qāʿida attached to 102: «من تعجل حقه أو ما أبيح له قبل وقته على وجه محرم عوقب
بحرمانه». `hastenedForbidden`: he hastened his right, or what would be permitted to him, before
its time in a forbidden way. The output is that he is deprived of it. -/
def hastenedForfeited (hastenedForbidden : Bool) : Bool := hastenedForbidden

/-- The text joins the two: «ويدخل فيها من مسائل: الأولى مسألة قتل الموروث والموصى له». A
forbidden hastening of what souls are drawn to is cancelled (ilghāʾ) by qāʿida 102 and forfeited by the
attached qāʿida alike. -/
theorem killing_heir_under_both : causeVoided true true = hastenedForfeited true := rfl

end Usul.Readings.RajabA7
