import Usul.Kulliyyat
import Usul.Refinements

/-!
# Shard rajab-a31: the readings of Ibn Rajab's qawāʿid 87 and 88

Formalised from each qāʿida's own statement in the pinned witness (`openiti-rajab-shamela21730`),
status `candidate`. Both qawāʿid are typological: each names kinds and gives each kind its
ruling, and where a kind is left to khilāf the reading says which side it takes and why. The
furūʿ are annotated for their leading ruling in the takhrīj suite
`corpus/takhrij/rajab_m8_rajab_a31_furu.json`; the other side of each khilāf stays a recorded
position.
-/

namespace Usul.Readings.RajabA31

/-! ### Qāʿida 87: what of financial rights and amlāk accepts transfer and muʿāwaḍa -/

/-- The kinds of holding the qāʿida names, «فيما يقبل النقل والمعاوضة من الحقوق المالية
والأملاك»:

* `tamm`: «الأملاك التامة», including (by the qāʿida's closing taḥqīq) «منافع الأعيان المملوكة
  التي تقبل المعاوضة مع أعيانها»;
* `manfaa`: «ملك المنافع», a milk of the manfaʿa held by a contract;
* `harmRight`: «الحقوق الثابتة دفعا لضرر الأملاك» (the shufʿa and the like), excepted;
* `ikhtisas`: «ملك الانتفاع وحقوق الاختصاص سوى البضع وحقوق التملك», read with the furūʿ as
  milk al-intifāʿ, ḥaqq al-ikhtiṣāṣ and ḥaqq al-tamalluk together (f010: «فإن هذا حق تملك»). -/
inductive Holding where
  | tamm | manfaa | harmRight | ikhtisas
  deriving DecidableEq, Repr

/-- Qāʿida 87. `lazim`: the holding rests on a lāzim title («إن كان بعقد لازم», «إن كانت لازمة»);
`higher`: the transferring act is above the contract by which the manfaʿa was owned; `iwad`:
the transfer is for ʿiwaḍ. The output is that the transfer (naql) is valid.

* «أما الأملاك التامة فقابلة للنقل بالعوض وغيره في الجملة»: always.
* «وأما ملك المنافع فإن كان بعقد لازم ملك فيه نقل الملك بمثل العقد الذي ملك به أو دونه دون ما
  هو أعلى منه ويملك المعاوضة عليه أيضا»: a lāzim title, by an act not above it, with or
  without ʿiwaḍ.
* «وتستثنى من ذلك الحقوق الثابتة دفعا لضرر الأملاك فلا يصح النقل فيها بحال»: never (the
  muʿāwaḍa «على إثباتها واستيفائها» is not a naql of the right).
* «إن كانت لازمة جاز النقل لمن يقوم مقامه فيها بغير عوض وفي جوازه بعوض خلاف»: a lāzim right,
  without ʿiwaḍ. With ʿiwaḍ the qāʿida grants nothing and leaves a khilāf; the reading withholds
  (`false`) and the side that allows stays a recorded position. -/
def transferValid : Holding → Bool → Bool → Bool → Bool
  | .tamm, _, _, _ => true
  | .manfaa, lazim, higher, _ => lazim && !higher
  | .harmRight, _, _, _ => false
  | .ikhtisas, lazim, _, iwad => lazim && !iwad

/-- The full milk transfers by ʿiwaḍ and without it: «بالعوض وغيره». -/
theorem tamm_transfers (l h w : Bool) : transferValid .tamm l h w = true := rfl

/-- The manfaʿa owned by a lāzim contract passes by the same contract, and for ʿiwaḍ:
«بمثل العقد الذي ملك به … ويملك المعاوضة عليه أيضا». -/
theorem manfaa_same_contract (w : Bool) : transferValid .manfaa true false w = true := rfl

/-- Never by a contract above it: «دون ما هو أعلى منه» (f006: «ولا تجوز الإجارة ; لأنها أعلى»). -/
theorem manfaa_not_higher (l w : Bool) : transferValid .manfaa l true w = false := by
  cases l <;> rfl

/-- The rights that repel the harm of amlāk are never transferred: «فلا يصح النقل فيها بحال». -/
theorem harm_right_never (l h w : Bool) : transferValid .harmRight l h w = false := rfl

/-- A lāzim right of ikhtiṣāṣ passes without ʿiwaḍ: «جاز النقل لمن يقوم مقامه فيها بغير عوض». -/
theorem ikhtisas_free (h : Bool) : transferValid .ikhtisas true h false = true := rfl

/-- What is not lāzim does not pass at all (f008: «المستعير لا يملك نقل حقه من الانتفاع إلا أن
يقول بلزوم العارية»). -/
theorem not_lazim_no_transfer (k : Holding) (hk : k = .manfaa ∨ k = .ikhtisas) (h w : Bool) :
    transferValid k false h w = false := by
  rcases hk with rfl | rfl <;> rfl

/-- The ʿiwaḍ matters only for ikhtiṣāṣ: in the other kinds the ruling ignores it. -/
theorem iwad_only_for_ikhtisas (k : Holding) (hk : k ≠ .ikhtisas) (l h : Bool) :
    transferValid k l h true = transferValid k l h false := by
  cases k <;> simp_all [transferValid]

/-- Link to qāʿida 32 (`Usul.Refinements.benefitExceptionValid`): f004 «إجارة المنافع المستثناة
في عقد البيع» and f017 (the manumitted slave whose service is excepted) rest on the exception
being valid. A benefit excepted for a known period is valid by Q32, and once held under the
sale, a lāzim contract, Q87 lets it be leased by the same kind of contract. -/
theorem excepted_benefit_leasable (t : Bool) :
    Usul.Refinements.benefitExceptionValid true t = true ∧
      transferValid .manfaa true false true = true := ⟨rfl, rfl⟩

/-! ### Qāʿida 88: using and building in the travelled roads, their air and their ground -/

/-- Where the use is: the road's surface, the ground below it («القرار الباطن»), or its air
(«الهواء»). -/
inductive Layer where
  | surface | below | air
  deriving DecidableEq, Repr

/-- Qāʿida 88. `harmful`: the road is narrow or the use harms the passers; `permanent`: the thing
is lasting (building, planting, digging) rather than sitting or stopping an animal; `forAll`: it
is for a public benefit, not for one person; `leave`: the imām has given leave. The output is
that the use is allowed.

* «أما الطريق نفسه فإن كان ضيقا أو أحدث فيه ما يضر بالمارة فلا يجوز بكل حال»: harm bars it
  whatever else holds.
* «فإن كان المحدث فيه متأبدا … فإن كان لمنفعة خاصة بآحاد الناس لم يجز على المعروف من المذهب»:
  barred, and the imām's leave does not lift it (f003: «ولا يملك الإمام الإذن في ذلك»).
* «وإن كان لمنفعة عامة ففيه خلاف معروف ; منهم من يطلقه ومنهم من يخصه بحالة انتفاء إذن
  الإمام فيه»: on the second ṭarīqa the imām's leave removes the khilāf. The reading takes that
  ṭarīqa, the one the qāʿida itself words by the leave: allowed with leave, withheld without.
* «وإن كان غير متأبد ونفعه خاص كالجلوس وإيقاف الدابة فيه ففيه خلاف أيضا»: the qāʿida gives no
  condition. The reading takes the side the furūʿ report from «الأكثرون» (f004: «جاز بإذن الإمام
  وبدون إذنه») and Ibn Rajab's own ground, that it «لا يعطل حق المرور بالكلية فهو كالقيام
  لحاجة»: allowed.
* «وأما القرار الباطن فحكمه حكم الظاهر على المنصوص»: the ground below is the surface.
* «وأما الهواء فإن كان الانتفاع به خاصا بدون إذن الإمام فالمعروف منعه بإذنه فيه خلاف»: barred
  without leave; with leave the qāʿida again words the khilāf by the leave, and the reading
  allows it. -/
def roadUseAllowed (layer : Layer) (harmful permanent forAll leave : Bool) : Bool :=
  !harmful && (if layer = .air then leave else !permanent || (forAll && leave))

/-- Harm to the passers bars every use, in every layer: «فلا يجوز بكل حال». -/
theorem harm_bars (l : Layer) (p u m : Bool) : roadUseAllowed l true p u m = false := by
  cases l <;> rfl

/-- The ground below is judged as the surface: «فحكمه حكم الظاهر على المنصوص». -/
theorem below_as_surface (h p u m : Bool) :
    roadUseAllowed .below h p u m = roadUseAllowed .surface h p u m := rfl

/-- A lasting thing for one person's benefit is barred, with the imām's leave or without. -/
theorem private_permanent_barred (h m : Bool) : roadUseAllowed .surface h true false m = false := by
  cases h <;> rfl

/-- A lasting thing for a public benefit, harmless, is allowed exactly with the imām's leave. -/
theorem public_permanent_by_leave (m : Bool) : roadUseAllowed .surface false true true m = m := by
  cases m <;> rfl

/-- A harmless passing use is allowed, leave or none. -/
theorem passing_use_allowed (u m : Bool) : roadUseAllowed .surface false false u m = true := rfl

/-- The air is used only by the imām's leave. -/
theorem air_needs_leave (h p u : Bool) : roadUseAllowed .air h p u false = false := by
  cases h <;> rfl

/-- Link to qāʿida 15 of the kulliyyāt (`Usul.Kulliyyat.mayInflict`, *lā ḍarar*): the road use the
reading allows inflicts no harm on the passers. Whatever harm `h` the use would do, if the
qāʿida's harm flag is set exactly when that harm is not nil, an allowed use is one that Q15
permits to be inflicted. -/
theorem allowed_use_inflicts_no_harm (l : Layer) (r h : Nat) (p u m : Bool)
    (hu : roadUseAllowed l (!Usul.Kulliyyat.mayInflict r h) p u m = true) :
    Usul.Kulliyyat.mayInflict r h = true := by
  cases hm : Usul.Kulliyyat.mayInflict r h
  · rw [hm] at hu; cases l <;> simp_all [roadUseAllowed]
  · rfl

end Usul.Readings.RajabA31
