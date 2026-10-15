/-!
# Shard rajab-a5: readings of Ibn Rajab's qawāʿid 94, 95 and 97

Each reading is formalised from the qāʿida's own statement (status `candidate`). Where a farʿ of
the qāʿida turns on a fact the statement leaves implicit, the reading takes that fact as an input,
quoting the text's own words.
-/

namespace Usul.Readings.RajabA5

/-- Qāʿida 94: one who receives another's property, without its owner's permission, from the hand
of one who holds it by right: «إن كان يجوز له إقباضه فهو أمانة عند الثاني إن كان الأول أمينا وإلا
فلا، وإن لم يك إقباضه جائزا فالضمان عليهما» (Ibn Rajab's «ويتخرج وجه آخر ألا يضمن غير الأول» is
held as a position, not as the reading). `handoverPermitted`: the first may hand it over;
`firstTrustee`: the first holds it as a trust (amīn). The output is the second receiver's
liability. -/
def secondReceiverLiable (handoverPermitted firstTrustee : Bool) : Bool :=
  !handoverPermitted || !firstTrustee

/-- Qāʿida 95: one who destroys another's property «وهو يظن أنه له أو تصرف فيه يظن لنفسه ولاية
عليه ثم يتبين خطأ ظنه»:
* relying on an apparent cause from another, «ثم تبين خطأ المتسبب أو أقر بتعمده للجناية ضمن
  المتسبب», so the actor does not bear it (`externalCause`);
* where the basis is shown unfit to rely on, «فإن تعلق به حكم فنقص فالضمان على المتلف وإلا فلا
  ضمان» (`basisVoid`, `rulingOverturned`);
* on bare ijtihād «ففي ضمانه قولان». The reading separates the two clauses of the opening: one who
  took it as his own (`asOwner`, «يظن أنه له») bears it, «فكأن إحالة الضمان على المستوفي للنفع
  أولا» and «لتلف المال تحت يده بانتفاعه به»; one who acted by a supposed authority over it
  («يظن لنفسه ولاية عليه») bears it only where he fell short, «لتفريطه» (`negligent`).
The output is the actor's liability. -/
def errorActorLiable (externalCause basisVoid rulingOverturned asOwner negligent : Bool) : Bool :=
  if externalCause then false
  else if basisVoid then rulingOverturned
  else asOwner || negligent

/-- Qāʿida 97: property in one's hand, or a debt owed, whose owner is known but absent and hoped
for: «فليس له التصرف فيه بدون إذن الحاكم إلا أن يكون تافها فله الصدقة به عنه»; where he is
despaired of, «في رواية صالح جواز التصدق به ولم يعين حاكما»; and where the owner is unknown, «جاز
التصدق به عنه لشرط الضمان بدون إذن الحاكم قولا واحدا على أصح الطريقين». `ownerKnown`: its owner
is known; `trivial`: it is trifling; `despaired`: his return is despaired of. The output is
whether he may dispose of it (give it in charity for the owner) without the judge's permission. -/
def disposeWithoutJudge (ownerKnown trivial despaired : Bool) : Bool :=
  !ownerKnown || trivial || despaired

/-- Qāʿida 95's first branch: whatever else holds, an apparent cause from another frees the
actor. -/
theorem externalCause_frees (b o a n : Bool) : errorActorLiable true b o a n = false := rfl

/-- Qāʿida 97: an unknown owner's property may be given in charity without the judge. -/
theorem unknownOwner_without_judge (t d : Bool) : disposeWithoutJudge false t d = true := rfl

end Usul.Readings.RajabA5
