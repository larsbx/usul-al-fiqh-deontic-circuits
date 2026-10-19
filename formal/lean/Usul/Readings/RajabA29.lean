import Usul.Refinements

/-!
# Shard rajab-a29: readings of Ibn Rajab's qawāʿid 84 and 86

Each reading is formalised from the qāʿida's own statement in the pinned witness
(`openiti-rajab-shamela21730`), status `candidate`. Both qawāʿid are typological: 84 sorts the
rulings tied to the unseparated ḥaml into two anwāʿ, 86 sorts milk into four kinds. Where a record
reports a split, the reading gives the qāʿida's own statement and the other sides stay recorded
positions in the takhrīj suite `corpus/takhrij/rajab_m8_rajab_a29_furu.json`.
-/

namespace Usul.Readings.RajabA29

/-! ## Qāʿida 84: does the ḥaml have a ḥukm before it separates?

«الحمل هل له حكم قبل انفصاله أم لا؟ حكى القاضي وابن عقيل وغيرهما في المسألة روايتين قالوا
والصحيح من المذهب أن له حكما». Ibn Rajab then sorts the rulings into two anwāʿ:
«أحدهما: ما يتعلق بسبب الحمل بغيره فهذا ثابت بالاتفاق لأن الأحكام الشرعية تتعلق على الأسباب
الظاهرة فإذا ظهرت أمارة الحمل كان وجوده هو الظاهر فترتب عليه أحكامه في الظاهر»; the second,
«الأحكام الثابتة للحمل في نفسه … وهذا النوع هو مراد من يأن الخلاف في الحمل له حكم أم لا». -/

/-- The qāʿida with its two riwāyāt pinned, not chosen. `hasHukm`: the riwāya that the ḥaml has a
ḥukm; `forAnother`: the ruling bears on another by cause of the ḥaml (the first nawʿ), not on the
ḥaml in itself (the second); `evident`: «ظهرت أمارة الحمل», its existence is the ẓāhir. The output
is that the ruling takes effect before separation (in the ẓāhir, «مراعى بانفصاله حيا»). -/
def hukmBeforeSeparationOn (hasHukm forAnother evident : Bool) : Bool :=
  evident && (forAnother || hasHukm)

/-- The reading: the qāʿida's «الصحيح من المذهب أن له حكما». -/
def hamlHukm (forAnother evident : Bool) : Bool := hukmBeforeSeparationOn true forAnother evident

/-- The first nawʿ is «ثابت بالاتفاق»: neither riwāya moves it, and it follows the amāra alone. -/
theorem first_nawa_agreed (r e : Bool) : hukmBeforeSeparationOn r true e = e := by
  cases r <;> cases e <;> rfl

/-- The second nawʿ is the locus of the two riwāyāt: with the amāra shown they part. -/
theorem second_nawa_is_the_riwayat :
    hukmBeforeSeparationOn true false true ≠ hukmBeforeSeparationOn false false true := by decide

/-- On the ṣaḥīḥ, an evident ḥaml grounds the ruling of either nawʿ before separation. -/
theorem sahih_evident_grounds (f : Bool) : hamlHukm f true = true := by cases f <;> rfl

/-- Without the amāra nothing attaches: «والطلاق لا يقع مع الشك والاحتمال». -/
theorem no_amara_no_hukm (f : Bool) : hamlHukm f false = false := by cases f <;> rfl

/-- Link to qawāʿid 20–21: on the first ṭarīq the ḥaml is «كجزء من أجزاء أمه», and in contracts on
the pregnant «حكمه حكم الأجزاء لا حكم الولد المنفصل، فيجب رده مع العين»: growth from the
substance, which qāʿida 20 rules a part. -/
theorem haml_in_contract_is_part : Usul.Refinements.growthKind true = .part :=
  Usul.Refinements.child_is_part

/-- Link to qāʿida 57 («كما سبق تقريره في قاعدة اقتران الحكم ومانعه»): on Ibn ʿAqīl's
ownership at the death, the ḥaml inherits from the father whose death makes it Muslim, for the
inheritance coincides with the bar's cause, not with the bar; qāʿida 57 lets such a ruling stand. -/
theorem inheritance_precedes_islam_bar :
    hamlHukm false true = Usul.Refinements.holdsAgainstBar false := rfl

/-! ## Qāʿida 86: the four kinds of milk

«الملك أربعة أنواع: ملك عين ومنفعة، وملك عين بلا منفعة، وملك منفعة بلا عين، وملك انتفاع من
غير ملك المنفعة». -/

inductive MilkKind where
  | aynAndManfaa | aynWithoutManfaa | manfaaWithoutAyn | intifaOnly
  deriving DecidableEq, Repr

/-- `holdsAyn`: the raqaba is his; `benefitByTamlik`: the benefit is his by a tamlīk (with the
ʿayn, or alone by waṣiyya, waqf, kharāj, ijāra, a reserved benefit, iqṭāʿ al-istighlāl), not by a
bare permission or ibāḥa. The second kind is the raqaba whose benefits were given away; the fourth
is a use permitted without the benefit being owned («فإنه يملك الانتفاع لا المنفعة»). -/
def milkKind (holdsAyn benefitByTamlik : Bool) : MilkKind :=
  match holdsAyn, benefitByTamlik with
  | true, true => .aynAndManfaa
  | true, false => .aynWithoutManfaa
  | false, true => .manfaaWithoutAyn
  | false, false => .intifaOnly

/-- Whether the holder owns the manfaʿa itself, as against a bare intifāʿ. -/
def MilkKind.ownsManfaa : MilkKind → Bool
  | .aynAndManfaa | .manfaaWithoutAyn => true
  | .aynWithoutManfaa | .intifaOnly => false

/-- The benefit is owned exactly when it came by a tamlīk. -/
theorem owns_manfaa_iff_tamlik (a b : Bool) : (milkKind a b).ownsManfaa = b := by
  cases a <;> cases b <;> rfl

/-- The four kinds are four: the classification separates every pair of criteria. -/
theorem milkKind_injective (a b a' b' : Bool) (h : milkKind a b = milkKind a' b') :
    a = a' ∧ b = b' := by
  cases a <;> cases b <;> cases a' <;> cases b' <;> simp_all [milkKind]

/-- Link to qāʿida 32: «منافع المبيع المستثناة في العقد مدة معلومة» are non-perpetual milk of the
manfaʿa without the ʿayn. A benefit reserved for a known period is valid (qāʿida 32), so the seller
who reserved it holds the manfaʿa of what he no longer owns. -/
theorem reserved_benefit_is_manfaa (t : Bool) :
    milkKind false (Usul.Refinements.benefitExceptionValid true t) = .manfaaWithoutAyn := rfl

/-- And the buyer, for that period, holds the ʿayn without its manfaʿa: the second kind. -/
theorem buyer_holds_ayn_without_manfaa (t : Bool) :
    milkKind true (!Usul.Refinements.benefitExceptionValid true t) = .aynWithoutManfaa := rfl

end Usul.Readings.RajabA29
