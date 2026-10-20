import Usul.Refinements
import Usul.Dalala

/-!
# Shard rajab-a27: readings of Ibn Rajab's qawāʿid 40 and 70

Each reading is formalised from the qāʿida's own statement in the pinned witness
(`openiti-rajab-shamela21730`), status `candidate`. Both qawāʿid are typological: they name kinds
(«نوعان») or a default with its exceptions, and list ṣuwar. Each record is annotated for its
leading ruling in the takhrīj suite `corpus/takhrij/rajab_m8_rajab_a27_furu.json`; where a record
reports a khilāf, the other sides stay recorded positions there.
-/

namespace Usul.Readings.RajabA27

/-! ## Qāʿida 40: rulings on a thing (ʿayn) when its ownership changes -/

/-- Qāʿida 40: «الأحكام المتعلقة بالأعيان بالنسبة إلى تبدل الأملاك واختلافها عليها نوعان: أحدهما:
ما يتعلق الحكم فيه بملك واحد فإذا زال ذلك الملك سقط الحكم», and the second kind, «ما يتعلق الحكم
فيه بنفس العين من حيث هي تعلقا لازما» which is not «يختص تعلقه بملك دون ملك».

`tiedToAin`: the ruling attaches to the ʿayn itself as a binding (lāzim) right, the second kind;
otherwise it attaches to one ownership, the first kind. `holderConsented`: the holder of the right
consented to its lapse; the second kind lapses only so: the pledge does not end «بدون رضى
المرتهن», the designated sacrificial animal's right «لا يزول بدون اختيار المالك», return for a
defect is not barred «إذا لم يدل على الرضا». The output is that the ruling survives the change of
ownership (or the lapse) and stands again, without a new contract, when the thing returns.

Where the record itself says the kind is disputed («مختلف في إلحاقها بأحد النوعين»), the case
takes the kind its first-stated wajh gives, and the other wujūh stay recorded positions. -/
def survivesOwnershipChange (tiedToAin holderConsented : Bool) : Bool :=
  tiedToAin && !holderConsented

/-- The first kind: a ruling on one ownership falls with it and does not come back (ijāra,
iʿāra, waṣiyya). -/
theorem one_ownership_falls (c : Bool) : survivesOwnershipChange false c = false := by
  cases c <;> rfl

/-- The second kind: a binding right in the ʿayn survives, and returns with the thing. -/
theorem bound_to_ain_survives : survivesOwnershipChange true false = true := rfl

/-- Even the second kind lapses with the right-holder's consent. -/
theorem consent_lapses (t : Bool) : survivesOwnershipChange t true = false := by
  cases t <;> rfl

/-- The text draws this link: the lessee's case whose share of the rent is not yet refunded
«فقد سبق نظائرها في قاعدة من تعذر عليه الأصل واستقر حقه في البدل ثم وجد الأصل», with al-aẓhar
«عدم استحقاق المنافع لأن حقه سقط منه وانتقل إلى بدلها». Under qāʿida 16 with the state at
obligation, a right settled in the substitute stays there although the original is found again,
and under qāʿida 40 the lease, on one ownership, does not return: both give the same answer. -/
theorem lease_as_settled_substitute :
    Usul.Refinements.useSubstituteAt true true = true ∧ survivesOwnershipChange false false = false :=
  ⟨rfl, rfl⟩

/-- Not drawn by qāʿida 40's text but the same distinction as qāʿida 24 (a right on the property
itself, against one on its owner for a reason that ends with the transfer): without consent, the
second kind is qāʿida 24's right on the property, and the first its owner's right whose reason
ends. -/
theorem agrees_with_q24 (t : Bool) :
    survivesOwnershipChange t false = Usul.Refinements.rightSurvivesTransfer t true := by
  cases t <;> rfl

/-! ## Qāʿida 70: the specific agent and the general object of his own act -/

/-- Qāʿida 70: «الفعل المتعدي إلى مفعول أو المتعلق بظرف أو مجرور إذا كان مفعوله أو متعلقه عاما
فهل يدخل الفاعل الخاص في عمومه أم يكون ذكر الفاعل قرينة مخرجة له من العموم أو يختلف ذلك بحسب
القرائن؟ فيه خلاف في المذهب، والمرجح فيه التخصيص إلا مع التصريح بالدخول أو قرائن تدل عليه».

The reading takes the side the qāʿida names al-murajjaḥ, takhṣīṣ: the agent is not covered by
the general object or adjunct of his own act. `explicitInclusion`: he is named, or authorised
expressly («التصريح بالدخول»); `qarinaInclusion`: a qarīna shows he is meant («أو قرائن تدل
عليه»). The output is that the agent falls under the general term. -/
def agentIncluded (explicitInclusion qarinaInclusion : Bool) : Bool :=
  explicitInclusion || qarinaInclusion

/-- The murajjaḥ: with neither exception, the mention of the agent takes him out (takhṣīṣ). -/
theorem takhsis_by_default : agentIncluded false false = false := rfl

/-- Express inclusion brings him in (the principal's permission to buy from himself, a creditor
named among the debtors to be released). -/
theorem explicit_includes (q : Bool) : agentIncluded true q = true := by
  cases q <;> rfl

/-- A qarīna of inclusion brings him in (al-Mughnī's iḥtimāl in the alms case, «فإن دلت قرينة على
الدخول جاز الأخذ»; the slave left a third of the estate, who enters «ضرورة صحة الوصية له»). -/
theorem qarina_includes (e : Bool) : agentIncluded e true = true := by
  cases e <;> rfl

/-- The text draws this link: the qāʿida is about an object or adjunct that is general
(«إذا كان مفعوله أو متعلقه عاما»), so it specifies a genuine ʿāmm. In «من دخل داري» the
conditional particle is general (Ibn al-Laḥḥām's generality reading, with no ʿahd), yet the
speaker, the agent of the oath, is not covered: «لم يدخل المتكلم». -/
theorem specifies_a_general_term :
    Usul.Dalala.IsGeneralIn .particle .condition false = true ∧ agentIncluded false false = false :=
  ⟨rfl, rfl⟩

end Usul.Readings.RajabA27
