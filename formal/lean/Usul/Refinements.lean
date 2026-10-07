import Usul.Muamalat
import Usul.Qawaid

/-!
# Refinements driven by the takhrīj suite (the bank applied to itself)

Each refinement adds the input whose absence an M4 case exposed, with a default that gives the
earlier reading back exactly (`*_conservative`). So no earlier result changes, and the cases
that needed the input can now be encoded faithfully. A refinement does not decide the related
register question; it makes the alternatives expressible.

* **Lots** (gap `fact:confusion_category`; Ibn Rajab 160's second clause: lots also «distinguish
  the entitled person, specific in fact, from his confusion»): a confused specific entitlement
  goes to lots even when the thing is divisible. Related: IQ-09.
* **Recourse** (gaps `fact:owed_by_other`, `fact:permission`; Ibn Rajab 75's two types):
  recourse for paying what another owed, or for spending by permission, unless given as a gift.
* **Aṣl and ẓāhir** (gap `fact:amara`; Ibn Rajab 159, «because time has indicators by which it
  is known, unlike what has no indicator: completing prayer, purity, ḥadath»): on equal grades
  the ẓāhir prevails only where the matter has indicators. Related: IQ-20.
-/

namespace Usul.Refinements

open Usul Usul.Muamalat

/-! ## Lots -/

def allocationFull (entitledKnown divisible confused : Bool) : Allocation :=
  if entitledKnown then .toEntitled else if confused then .lot else allocation false divisible

theorem allocationFull_conservative (k d : Bool) : allocationFull k d false = allocation k d := by
  cases k <;> cases d <;> rfl

/-- A confused specific entitlement goes to lots whatever the divisibility. -/
theorem confused_goes_to_lot (d : Bool) : allocationFull false d true = .lot := by
  cases d <;> rfl

/-! ## Recourse -/

def recourseFull (gift owedByOther permission : Bool) : Bool :=
  !gift && (owedByOther || permission)

/-- Q32's subject is paying what another owed: there the refinement is the old reading. -/
theorem recourseFull_conservative (g p : Bool) : recourseFull g true p = decide (0 < recourse g 1) := by
  cases g <;> cases p <;> rfl

theorem no_recourse_unowed_unpermitted (g : Bool) : recourseFull g false false = false := by
  cases g <;> rfl

/-! ## Aṣl and ẓāhir -/

/-- The ẓāhir prevails when strictly stronger, or equal and the matter has indicators. -/
def zahirPrevails (asl zahir : Grade) (amara : Bool) : Bool :=
  decide (asl < zahir) || (decide (asl.rank = zahir.rank) && amara)

/-- With indicators assumed, this is `Qawaid.update`'s choice. -/
theorem zahirPrevails_conservative (a z : Grade) :
    zahirPrevails a z true = ((Qawaid.update (⟨0, a⟩ : Qawaid.Held Nat) ⟨1, z⟩).value == 1) := by
  cases a <;> cases z <;> decide

/-- Without indicators, equal grades keep the aṣl (Ibn Rajab 159, f007). -/
theorem tie_without_amara_keeps_asl (g : Grade) : zahirPrevails g g false = false := by
  cases g <;> decide

/-- A stronger ẓāhir prevails with or without indicators (a sharʿī proof). -/
theorem stronger_prevails {a z : Grade} (h : a < z) (m : Bool) : zahirPrevails a z m = true := by
  simp [zahirPrevails, h]

end Usul.Refinements
