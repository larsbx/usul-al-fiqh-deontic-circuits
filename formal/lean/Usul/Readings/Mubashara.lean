import Usul.Muamalat

/-!
# Ibn Rajab, qāʿida 127: the direct act and the cause

«إذا استند إتلاف أموال الآدميين ونفوسهم إلى مباشرة وسبب تعلق الضمان بالمباشرة دون السبب إلا إذا
كانت المباشرة مبنية على السبب وناشئة عنه … ثم إن كانت المباشرة والحالة هذه لا عدوان فيها بالكلية
استقل السبب وحده بالضمان، وإن كان فيها عدوان شاركت السبب في الضمان. فالأقسام ثلاثة»

An itlāf rests on a direct act (mubāshara) and a cause (sabab). Liability attaches to the direct
act, unless that act is built on the cause and arises from it. In that case, the cause bears it
alone when the direct act has no transgression at all, and the two share it when it has some.
These are the three divisions; the qāʿida's own furūʿ instance each:

* f000 «فالضمان على الدافع وحده»: a direct act not arising from the cause, so the direct actor;
* f003 «فالضمان والقود عليهم دون الحاكم»: arising without transgression, so the cause alone;
* f005 «الممسك مع القاتل فإنهما يشتركان … على إحدى الروايتين»: shared, on one riwāya.

The reading covers only what the statement covers: an itlāf with both a direct act and a cause.
Liability of a cause with no direct act («المتسبب لا يضمن إلا بالتعدي») is not stated here and stays
a gap. Status: candidate reading.
-/

namespace Usul.Readings.Mubashara

/-- On whom the ḍamān of the itlāf falls. -/
inductive Daman where
  | mubashir | sabab | shared
  deriving DecidableEq, Repr

/-- Q127: `arising` = the direct act is built on the cause and arises from it («مبنية على السبب
وناشئة عنه»); `udwan` = the direct act has some transgression («فيها عدوان»). -/
def damanOn (arising udwan : Bool) : Daman :=
  if !arising then .mubashir else if udwan then .shared else .sabab

theorem q127_direct_unless_arising (u : Bool) : damanOn false u = .mubashir := rfl

theorem q127_cause_alone_without_udwan : damanOn true false = .sabab := rfl

theorem q127_shared_with_udwan : damanOn true true = .shared := rfl

/-- The three divisions exhaust the qāʿida: every case falls in exactly one. -/
theorem q127_three_divisions (a u : Bool) :
    damanOn a u = .mubashir ∨ damanOn a u = .sabab ∨ damanOn a u = .shared := by
  cases a <;> cases u <;> simp [damanOn]

/-- Link to al-Saʿdī Q13 «الإتلاف يستوي فيه المتعمد والجاهل والناسي»: where the direct act does not
arise from another's cause, the direct destroyer bears the ḍamān, and destruction without right is
compensable whatever his state of mind. -/
theorem q127_agrees_with_q13 (u : Bool) (m : Muamalat.MentalState) :
    damanOn false u = .mubashir ∧ Muamalat.itlafLiable false m = true :=
  ⟨rfl, rfl⟩

end Usul.Readings.Mubashara
