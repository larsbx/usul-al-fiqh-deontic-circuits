import Usul.Qiyas
import Usul.Tanaqud

/-!
# al-Saʿdī's furūq: the bank applied to its furūʿ (part two of *al-Qawāʿid wa'l-Uṣūl al-Jāmiʿa*)

The second part opens with its aṣl: «الشارع لا يفرق بين المتشابهات من كل وجه، بل لا بد فيها من
فوارق معنوية … وإلا فاعلم أن الفرق صوري والفروق الصورية ضعيفة جداً». Two masāʾil ruled
differently need a meaningful feature (maʿnā) that separates them; a separation with none is
ṣūrī. That is `Schema.Factors`: the ruling factors through the meaningful features.

al-Saʿdī then grades the furūq of the fuqahāʾ, item by item
(`corpus/furuq/sadi_tranche*.json`):

* `sahih`: they are ruled apart, and a meaningful feature separates them;
* `daif`: they are ruled apart, but nothing meaningful separates them, so «الحكم فيهما واحد»;
* `jamDaif`: they are ruled alike, but a naṣṣ or a meaning separates them (e.g. «ضعف عدم التفريق»);
* `reported`: he reports the fuqahāʾ's farq («وفرّقوا», «ومن الفروق عند الأصحاب») without grading it,
  so his ruling is recorded as theirs; nothing is attributed to him beyond the report.

This module states the aṣl and works out the items whose reason is already a theorem of the bank.
-/

namespace Usul.Furuq

open Usul.Schema Usul.Qiyas

/-- al-Saʿdī's grade of a farq. -/
inductive Grade where
  | sahih | daif | jamDaif | reported
  deriving DecidableEq, Repr

/-- What his grade says about the two masāʾil: ruled apart, or alike. -/
def Grade.apart : Grade → Bool
  | .sahih | .jamDaif | .reported => true
  | .daif => false

/-- How the fuqahāʾ he answers rule them: apart, unless he faults them for ruling alike. -/
def Grade.madhhab : Grade → Bool
  | .sahih | .daif | .reported => true
  | .jamDaif => false

/-- His ruling matches the madhhab's exactly on the sound and the merely reported furūq; every
weak grade overturns it. -/
theorem confirms_iff_sahih (g : Grade) : g.apart = g.madhhab ↔ g = .sahih ∨ g = .reported := by
  cases g <;> decide

/-- Whether the ruling is his own: every grade but the bare report. -/
def Grade.his : Grade → Bool
  | .reported => false
  | _ => true

/-- The register applied to itself. A later item may overturn an earlier one on a shared case
only if the earlier is a bare report (overturning his own grade would make him contradict
himself) and the later is his own grade. The overturn is then exactly a `daif` grade: the
reported farq is the one he holds weak. -/
theorem overturn_iff_daif (p c : Grade) :
    (p.his = false ∧ c.his = true ∧ p.apart ≠ c.apart) ↔ (p = .reported ∧ c = .daif) := by
  cases p <;> cases c <;> decide

section Asl

variable {α F G β : Type} {H : α → β} {m : α → F} {a b : α}

/-- The aṣl: if the ruling turns only on the meaningful features, masāʾil alike in them are
ruled alike. -/
theorem alike_unless_farq (h : Factors H m) (hab : m a = m b) : H a = H b := h a b hab

/-- A sound farq is a meaningful feature: two masāʾil ruled apart differ in one. -/
theorem farq_is_maana (h : Factors H m) (hne : H a ≠ H b) : m a ≠ m b := fun e => hne (h a b e)

/-- A ṣūrī farq is idle: a feature the ruling does not turn on separates nothing, however the
two masāʾil differ in it. -/
theorem suri_farq_idle (h : Factors H m) (hab : m a = m b) (s : α → G) (_ : s a ≠ s b) :
    H a = H b := h a b hab

end Asl

/-! ## F06 · the mutanaffil behind the muftariḍ: a naqḍ

The fuqahāʾ bar the muftariḍ from praying behind the mutanaffil, citing the difference of
intention. al-Saʿdī: «وتعليلهم باختلاف النية موجود في ائتمام المتنفل بالمفترض», which they
allow. The cited ʿilla is present in a case ruled the other way, so it is broken by naqḍ:
no ruling that agrees with that case can turn on the intention alone. -/

inductive Imama where
  | fardBehindNafl | naflBehindFard
  deriving DecidableEq, Repr

/-- Their ʿilla: the two intentions differ (true in both arrangements). -/
def niyyaDiffers : Wasf Imama := fun _ => true

theorem f06_naqd {H : Imama → Bool} (hH : Agrees H [(.naflBehindFard, true)])
    (hban : H .fardBehindNafl = false) : ¬ Factors H niyyaDiffers :=
  naqd_defeats (asl := .fardBehindNafl) rfl ⟨(.naflBehindFard, true), by simp, rfl, by decide⟩ hH hban

/-! ## F13 · shaving and perfume in iḥrām: ruled alike

The madhhab excuses the ignorant and the forgetful in clothing, covering the head and perfume,
but not in shaving and clipping the nails, «وعللوه بأنه إتلاف». al-Saʿdī: «إنما الإتلاف الذي
يستوي فيه الأهل وغيره في حقوق الآدميين … وهذه الحق فيها لله متمحض». That is the qayd of T-01,
so both are ruled by God's right and the excused owes nothing in either. -/

/-- In God's right only the deliberate owes: the excused owes nothing, shaving included, so
«إتلاف» separates nothing here. -/
theorem f13_alike (m : Muamalat.MentalState) (hm : m ≠ .deliberate) :
    Tanaqud.t1.jam (.allah, m) = false := by
  cases m <;> simp_all <;> decide

/-! ## F15 · game killed deliberately or not: ruled apart

The majority require the jazāʾ for game either way. al-Saʿdī: «ضعف عدم التفريق بين
المتعمد وغير المتعمد في قتل الصيد … مع أن الآية الكريمة نصت على المتعمد». Under T-01 the two
fall on different sides. -/

theorem f15_apart :
    Tanaqud.t1.jam (.allah, .deliberate) = true ∧ Tanaqud.t1.jam (.allah, .forgetful) = false := by
  decide

/-! ## F18 · omitting a command vs committing a prohibition: a sound farq

«ومن الفروق الصحيحة الثابتة شرعاً: الفرق بين من ترك المأمور سهواً أو جهلاً … وبين فاعل المحظور
وهو معذور بجهل أو نسيان». This is Q27 (`Sadi.q27_asymmetry`). -/

theorem f18_sahih : Sadi.dischargedByExcuse .omitCommand ≠ Sadi.dischargedByExcuse .commitProhibited := by
  decide

/-! ## F109 · destruction by the non-mukallaf: T-01's human side

«ويشبه هذا إيجاب الضمان على المكلفين وغير المكلفين في إتلافات النفوس والأموال». F13 states the
same qayd: «إنما الإتلاف الذي يستوي فيه الأهل وغيره في حقوق الآدميين». On the human side of
T-01, whoever destroys is liable, whatever his state, so F109, F13 and T-01 agree. -/

theorem f109_adami (m : Muamalat.MentalState) : Tanaqud.t1.jam (.adami, m) = true := by
  cases m <;> decide

end Usul.Furuq
