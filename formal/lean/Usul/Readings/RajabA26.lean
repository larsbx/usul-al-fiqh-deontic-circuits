/-!
# Shard rajab-a26: readings of Ibn Rajab's qawāʿid 13 and 23

Formalised from each qāʿida's own statement in the pinned witness (`openiti-rajab-shamela21730`),
status `candidate`. Both qawāʿid are typological: a statement, then a list of ṣuwar. Each record is
annotated for its leading ruling in the takhrīj suite `corpus/takhrij/rajab_m8_rajab_a26_furu.json`,
and the khilāf a record reports stays a recorded position there.
-/

namespace Usul.Readings.RajabA26

/-- Qāʿida 13: «إذا وجدنا أثرا معلولا لعلة ووجدنا في محله علة صالحة له، ويمكن أن يكون الأثر
معلولا لغيرها لكن لا يتحقق وجود غيرها، فهل يحال ذلك الأثر على تلك العلة المعلومة أم لا؟».
The output is the iḥāla: the athar is referred to the ʿilla known to be in its locus.

`knownCauseFit`: an ʿilla fit for the athar is established in its locus («علة صالحة له»), and no
other is established. `zahirElsewhere`: the ẓāhir points to another ʿilla («وقد تظهر الإحالة على
غيرها»).

The qāʿida's ground is the aṣl «أن لا علة سوى هذه المتحققة». Where the ẓāhir does not point
elsewhere, aṣl and ẓāhir agree («فيتوافق الأصل الظاهر») and the athar is referred to the known
ʿilla. Where it does, «فيختلفان»: aṣl and ẓāhir conflict, and qāʿida 13 does not settle that
conflict (it is qāʿida 159's, `asl_zahir`). The reading then returns `false`, meaning only that the
iḥāla is not secured by this qāʿida; a farʿ that turns on the conflict is not decided here. -/
def ihalaOnKnownCause (knownCauseFit zahirElsewhere : Bool) : Bool :=
  knownCauseFit && !zahirElsewhere

/-- Aṣl and ẓāhir agree: the athar is referred to the known ʿilla. -/
theorem agreeing_refers : ihalaOnKnownCause true false = true := rfl

/-- No ʿilla established in the locus: nothing to refer the athar to. -/
theorem no_known_cause (z : Bool) : ihalaOnKnownCause false z = false := by
  cases z <;> rfl

/-- The ẓāhir points elsewhere: the aṣl alone does not secure the iḥāla («فيختلفان»). -/
theorem conflict_not_secured (k : Bool) : ihalaOnKnownCause k true = false := by
  cases k <;> rfl

/-- Qāʿida 23: «من حرم عليه الامتناع من بدل شيء سئله فامتنع فهل يسقط إذنه بالكلية أو يعتبر
ويجبره الحاكم عليه هذا نوعان». The output is that the refuser's idhn lapses altogether
(«يسقط إذنه بالكلية»): the one asking proceeds without it and without the ḥākim.

`refusalForbidden`: the refusal is ḥarām on him («من حرم عليه الامتناع»), the qāʿida's scope.
`merePermission`: what is asked of him is an idhn and nothing more, the first nawʿ («أن يكون
المطلوب منه إذنا مجردا»); otherwise it is the second, a taṣarruf («تصرفا لعقد أو فسخ أو
غيرهما»).

In the first nawʿ the idhn lapses, and the qāʿida gives its ground: «وإنما سقط اعتبار الإذن في هذه
الصور لأن اعتباره يؤدي إلى مشقة وحرج وربما أدى إلى فوات الحق بالكلية». In the second the ḥākim
compels him or acts in his stead, so it does not lapse altogether; whether the ḥākim compels or
acts for him is a further question the reading does not decide. -/
def idhnLapses (refusalForbidden merePermission : Bool) : Bool :=
  refusalForbidden && merePermission

/-- First nawʿ: a mere idhn, refused when refusal is ḥarām, lapses. -/
theorem mere_idhn_lapses : idhnLapses true true = true := rfl

/-- Second nawʿ: a taṣarruf refused does not lapse; the ḥākim compels him or acts for him. -/
theorem tasarruf_needs_hakim : idhnLapses true false = false := rfl

/-- Outside the qāʿida's scope, a refusal he may make lapses nothing. -/
theorem permitted_refusal_stands (m : Bool) : idhnLapses false m = false := by
  cases m <;> rfl

end Usul.Readings.RajabA26
