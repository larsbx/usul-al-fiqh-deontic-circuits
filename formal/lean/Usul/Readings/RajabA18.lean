/-!
# Shard rajab-a18: readings of Ibn Rajab's qawāʿid 137 and 138

Each reading is formalised from the qāʿida's own statement in the pinned witness
(`openiti-rajab-shamela21730`), status `candidate`. Qāʿida 137 asks «الواجب بقتل العمد هل هو القود
عينا أو أحد أمرين ... فيه روايتان» and branches into three sub-qawāʿid (retaliation, waiver and
ṣulḥ), each posed «على وجهين». Where the statement poses a question, the reading takes one of the
sides the qāʿida itself names (`eitherOfTwo` keeps the riwāya expressible); the other sides stay
recorded positions in the takhrīj suite `corpus/takhrij/rajab_m8_rajab_a18_furu.json`.
-/

namespace Usul.Readings.RajabA18

/-- Qāʿida 137, its first and second sub-qawāʿid (retaliation and waiver): «ثم إن قلنا: الواجب القود
عينا فلا يكون الاستيفاء تفويتا للمال وإن قلنا أحد الأمرين فهل هو تفويت للمال أم لا؟ على وجهين».
The reading takes the wajh Ibn Rajab marks «أشهرهما اللزوم نص عليه أحمد», with the ground he gives
for it: «وقد كان تعلق حقه برقبة العبد المرهون فيتعلق ببدله الواجب», and his limit of it: «وهذا
بخلاف اقتصاص المكاتب من الجاني عليه فإنه لم يفوت به مالا مملوكا له».
`eitherOfTwo`: the obligation of deliberate killing is one of two things (qawad or diya), not qawad
alone. `victimEncumbered`: the one killed (or injured) was property to which another's right was
already attached (a pledge, a usufruct or legacy, a partner's share). The output is that taking
the qawad, or waiving it gratis, forfeits wealth owed to that other: the actor may not do it alone,
and if he does he is liable to him. -/
def forfeitsAttachedRight (eitherOfTwo victimEncumbered : Bool) : Bool :=
  eitherOfTwo && victimEncumbered

/-- On the riwāya that qawad alone is due, nothing is forfeited: «فلا يكون الاستيفاء تفويتا للمال». -/
theorem qawad_alone_forfeits_nothing (v : Bool) : forfeitsAttachedRight false v = false := rfl

/-- Where no other right was attached to the victim, nothing is forfeited, whichever riwāya. -/
theorem unencumbered_forfeits_nothing (e : Bool) : forfeitsAttachedRight e false = false := by
  cases e <;> rfl

/-- Qāʿida 137, its third sub-qawāʿida: «الصلح عن موجب الجناية، فإن قلنا هو القود وحده فله الصلح عنه
بمقدار الدية وبأقل وأكثر منها إذ الدية غير واجبة بالجناية ... وإن قلنا أحد شيئين فهل يكون الصلح
عنها صلحا عن القود أو المال على وجهين». The reading takes the wajh that the ṣulḥ is over the qawad,
except where the one killed was the claimant's own property, whose compensation replaces it:
«وعلل بأنه عوض عن المقتول فهو كقتل الخطأ». `eitherOfTwo`: as above. `victimOwned`: the one killed
was a slave owned by the claimant. The output is that the ṣulḥ compensation counts as a
wealth-for-wealth exchange (bound by the diya's measure in its genus, open to pre-emption (shufʿa),
taking the character of the wealth it replaces). -/
def sulhReplacesWealth (eitherOfTwo victimOwned : Bool) : Bool :=
  eitherOfTwo && victimOwned

/-- On the riwāya that qawad alone is due, a ṣulḥ is never an exchange for wealth:
«إذ الدية غير واجبة بالجناية». -/
theorem sulh_on_qawad_alone (v : Bool) : sulhReplacesWealth false v = false := rfl

/-- A ṣulḥ over the blood of a free man is over the qawad, whichever riwāya. -/
theorem sulh_for_free_victim (e : Bool) : sulhReplacesWealth e false = false := by
  cases e <;> rfl

/-- Qāʿida 138: «العين المتعلق بها حق لله تعالى أو لآدمي، إما أن تكون مضمونة أو غير مضمونة فإن كانت
مضمونة وجب ضمانها بالتلف والإتلاف بكل حال، وإن لم تكن مضمونة لم يجب ضمانها بالتلف ووجب بالإتلاف إن
كان مستحق موجود وإلا فلا». `guaranteed`: the thing burdened with the right is guaranteed (maḍmūna).
`destroyed`: it was destroyed by an act (itlāf), not lost by perishing (talaf). `claimantExists`:
there is a present beneficiary of the right. The output is that compensation (ḍamān) of it is due. -/
def mustCompensate (guaranteed destroyed claimantExists : Bool) : Bool :=
  guaranteed || (destroyed && claimantExists)

/-- A guaranteed thing is compensated (ḍamān) «بكل حال». -/
theorem guaranteed_always (d c : Bool) : mustCompensate true d c = true := rfl

/-- An unguaranteed thing that perishes is not compensated: «لم يجب ضمانها بالتلف». -/
theorem unguaranteed_perishing_free (c : Bool) : mustCompensate false false c = false := rfl

/-- An unguaranteed thing with no present beneficiary owes no ḍamān: «وإلا فلا». -/
theorem unguaranteed_without_claimant_free (d : Bool) : mustCompensate false d false = false := by
  cases d <;> rfl

end Usul.Readings.RajabA18
