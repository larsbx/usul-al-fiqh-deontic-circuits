/-!
# Shard rajab-a22: readings of Ibn Rajab's qawāʿid 151 and 154

Each reading is formalised from the qāʿida's own statement in the pinned witness
(`openiti-rajab-shamela21730`), status `candidate`. Where the statement reports a split, the reading
takes the side the qāʿida itself marks («وأكثر الأصحاب ... يقولون: ليس بمتقوم»); the other sides stay
recorded positions in the takhrīj suite `corpus/takhrij/rajab_m8_rajab_a22_furu.json`.
-/

namespace Usul.Readings.RajabA22

/-- Qāʿida 151: «دلالة الأحوال يختلف بها دلالة الأقوال في قبول دعوى ما يوافقها ورد ما يخالفها،
ويترتب عليها الأحكام بمجردها». `supports`: the circumstance (ḥāl) agrees with the claim, or
indicates the matter on which a ruling is to attach; `belies`: the circumstance contradicts the
claim. The output is that the claim is accepted (the indicated ruling attaches) on the strength of
the circumstance. A claim the circumstance belies is rejected whatever else holds; a claim it does
not support is not carried by this qāʿida (it is left to the general rule of claims). -/
def halCarriesClaim (supports belies : Bool) : Bool := supports && !belies

/-- A claim the circumstance supports, and does not belie, is accepted. -/
theorem supported_claim_accepted : halCarriesClaim true false = true := rfl

/-- The bar: a claim the circumstance belies is rejected, whatever else holds. -/
theorem belied_claim_rejected (s : Bool) : halCarriesClaim s true = false := by
  cases s <;> rfl

/-- Without the circumstance's support the qāʿida carries nothing. -/
theorem unsupported_claim_not_carried (b : Bool) : halCarriesClaim false b = false := by
  cases b <;> rfl

/-- Qāʿida 154: «خروج البضع من الزوج هل هو متقوم أم لا؟ بمعنى أنه هل يلزمه المخرج له قهرا ضمانة
للزوج بالمهر؟ ... وأكثر الأصحاب كالقاضي ومن بعده يقولون: ليس بمتقوم، وخصوا هذا الخلاف بمن عدا
الزوجة». The reading takes the marked side of «أكثر الأصحاب»: the exit of the buḍʿ is not valued
in itself. A mahr is charged for it only where the act fixed on the husband a share of mahr for a
buḍʿ he had not consummated («المفسد قرر هذا النصف على الزوج», the record's second maʾkhadh), or
where the husband, his marriage standing, elects the mahr in place of his wife («فإنه يخير بين
زوجته وبين المهر»); and never against the wife herself («فقالوا لا يضمن ... شيئا بغير خلاف»).
`chargedUnconsummated`: the act fixed on the husband mahr for an unconsummated buḍʿ;
`electsMahr`: the husband elects the mahr in place of his still-standing marriage;
`wifeBears`: the one the exit would be charged to (or whose property buys it) is the wife. The
output is that the exit of the buḍʿ carries a mahr (is charged, or bought as a thing of value). -/
def budExitCharged (chargedUnconsummated electsMahr wifeBears : Bool) : Bool :=
  (chargedUnconsummated || electsMahr) && !wifeBears

/-- The bar: the wife is never charged for the exit of her own buḍʿ, whatever else holds. -/
theorem wife_never_charged (c e : Bool) : budExitCharged c e true = false := by
  cases c <;> cases e <;> rfl

/-- The bare exit, with no fixed unconsummated mahr and no election, carries nothing: it is not
valued in itself. -/
theorem bare_exit_not_charged (w : Bool) : budExitCharged false false w = false := by
  cases w <;> rfl

/-- One who fixes an unconsummated half on the husband owes it. -/
theorem fixed_half_charged (e : Bool) : budExitCharged true e false = true := by
  cases e <;> rfl

/-- The husband who elects the mahr in place of his wife takes it. -/
theorem elected_mahr_charged (c : Bool) : budExitCharged c true false = true := by
  cases c <;> rfl

end Usul.Readings.RajabA22
