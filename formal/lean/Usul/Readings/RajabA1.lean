/-!
# Ibn Rajab, qawāʿid 60, 67, 69 and 71 (shard `rajab-a1`, candidate)

Each reading is formalised from the qāʿida's own statement in the pinned witness
(`openiti-rajab-shamela21730`). Facts are named Booleans; the takhrīj suite
`corpus/takhrij/rajab_m8_rajab_a1_furu.json` tests them against the furūʿ.
-/

namespace Usul.Readings.RajabA1

/-! ### Qāʿida 60: rescinding a permissible contract that harms someone -/

/-- What a rescission of a non-binding contract does: it is barred, it takes effect with the harm
made good, or it is free. -/
inductive Rescission where
  | barred | withRemedy | free
  deriving DecidableEq, Repr

/-- «التفاسخ في العقود الجائزة متى تضمن ضررا على أحد المتعاقدين أو غيرهما ممن له تعلق بالعقد لم
يجز ولم ينفذ إلا أن يمكن استدراك الضرر بضمان أو نحوه فيجوز على ذلك الوجه»: a rescission that
harms a party or one connected with the contract is barred, unless the harm can be made good by
liability or the like; without harm the permissible contract is rescinded freely. -/
def rescission (harm remediable : Bool) : Rescission :=
  if !harm then .free else if remediable then .withRemedy else .barred

/-! ### Qāʿida 67: a right that came back by gift or release -/

/-- «من استحق الرجوع بعين أو دين بفسخ أو غيره وكان قد رجع إليه ذلك الحق بهبة أو إبراء ممن يستحق
عليه الرجوع فهل يستحق الرجوع ببدله أم لا؟ في المسألة وجهان», read by Ibn Rajab's own takhrīj in the
qāʿida's opening, «ويتخرج التفريق بين الهبة والإبراء فيرجع بالهبة دون الإبراء»: what came back by
gift (ownership left and returned) still founds recourse for its substitute; what was released
(«لأن ملكه لم يزل عنه») does not. -/
def recourseAfterReturn (returnedByGift : Bool) : Bool := returnedByGift

/-! ### Qāʿida 69: may one engaged for specified work delegate it? -/

/-- «العقد الوارد على عمل معين إما أن يكون لازما ثابتا في الذمة بعوض كالإجارة فالواجب تحصيل ذلك
العمل ولا يتعين أن يعمله المعقود معه إلا بشرط أو قرينة تدل عليه وإما أن يكون غير لازم وإنما
يستفاد التصرف فيه بمجرد الإذن فلا يجوز للمعقود معه أن يقيم غيره مقامه في عمله إلا بإذن صريح أو
قرينة دالة عليه»: under a binding contract he may delegate unless a condition or indication
requires him personally; acting by bare permission he may not, unless permission or an indication
of it is present. Those acting by wilāya, «ويتردد بين هذين», take one side or the other through
the same facts. -/
def mayDelegate (binding personalRequired permissionIndicated : Bool) : Bool :=
  if binding then !personalRequired else permissionIndicated

/-- The two kinds differ in their default: with no condition and no indication, the one bound in
his dhimma may delegate and the one acting by permission may not. -/
theorem delegation_defaults_differ :
    mayDelegate true false false = true ∧ mayDelegate false false false = false := ⟨rfl, rfl⟩

/-! ### Qāʿida 71: eating from property without its owners' permission -/

/-- «وإن كانت الولاية لمصلحة المولى عليه فالمنصوص جواز الأكل منه أيضا بقدر عمله»; for property
over which he has no wilāya, «فيجوز الأكل منه للضرورة بلا نزاع وأما مع عدمها فيجوز فيما تتوق إليه
النفوس مع عدم الحفظ والاحتراز عليه». Eating «بقدر عمله» is in return for the work, so it lapses for
one otherwise paid for it (the furūʿ's «لاستغنائهما عنه بطلب الأجرة»). -/
def mayEat (necessity wardWilaya compensatedOtherwise unguardedCraved : Bool) : Bool :=
  necessity || (wardWilaya && !compensatedOtherwise) || unguardedCraved

/-- Necessity permits eating whatever the holding. -/
theorem necessity_permits (w c u : Bool) : mayEat true w c u = true := by
  simp [mayEat]

end Usul.Readings.RajabA1
