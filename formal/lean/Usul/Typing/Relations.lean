import Usul.Typing.Encoders

/-!
# Relations between qāʿida types

Some facts are one notion stated at two levels: a farʿ's fact settles a fact of the qāʿida above it.
Where a human decision relates them without merging the fields (2026-10-11), the relation is an
`Implication`, in the direction the texts give: when the premise holds, the consequent follows.
`saturate` fills an implied field only where the situation leaves it open; a fact a text states is
never overridden. The router (`Typed.applies`) then sees what a text settles directly and what
follows from it.

| Relation | From | To |
|---|---|---|
| `rukhsaNeedsFirm` | 68.f001 «المسح رخصة ولم تتحقق إباحتها» | 68 «ما يشترط فيه النية الجازمة» |
| `yearDespair` | 106.f002 «اللقطة بعد الحول … لجهالة ربها» | 106 «إذا يئس من الوقوف عليه» |
| `unidentifiedIsMajhul` | al-Saʿdī Q20 «إذا تعذر معرفة من له الحق» | 106: unknown and despaired of |
| `majhulIsUnidentified` | 106: unknown and despaired of | Q20 |
| `knownIsIdentified`, `hopedIsIdentified` | 106: not unknown, or not despaired of | Q20 |
| `consumedIsMajhul` | Ibn Rajab 22 «العين المنغمرة … إذا لم يظهر أثرها» | 106: unknown and despaired of |

The fifth is what the kernel already assumes in `Refinements.istihlak` (`istihlak_agrees`).
-/

namespace Usul.Typing

set_option maxRecDepth 100000

/-- A Boolean field of the situation, read and written. -/
structure BoolField where
  get : Situation → Option Bool
  set : Situation → Option Bool → Situation

namespace Field
def needsFirm : BoolField := ⟨(·.needsFirm), fun s v => { s with needsFirm := v }⟩
def rukhsaNeedsCertainty : BoolField := ⟨(·.rukhsaNeedsCertainty), fun s v => { s with rukhsaNeedsCertainty := v }⟩
def yearPassed : BoolField := ⟨(·.yearPassed), fun s v => { s with yearPassed := v }⟩
def unknown : BoolField := ⟨(·.unknown), fun s v => { s with unknown := v }⟩
def despair : BoolField := ⟨(·.despair), fun s v => { s with despair := v }⟩
def ownerIdentifiable : BoolField := ⟨(·.ownerIdentifiable), fun s v => { s with ownerIdentifiable := v }⟩
def consumed : BoolField := ⟨(·.consumed), fun s v => { s with consumed := v }⟩
end Field

/-- When every premise holds, each consequent follows. -/
structure Implication where
  premise : List (BoolField × Bool)
  consequent : List (BoolField × Bool)

/-- Fill the consequents the situation leaves open, when the premise holds. -/
def Implication.fire (r : Implication) (s : Situation) : Situation :=
  if r.premise.all (fun (f, b) => f.get s == some b) then
    r.consequent.foldl (fun s (f, b) => if (f.get s).isNone then f.set s (some b) else s) s
  else s

open Field in
def rukhsaNeedsFirm : Implication := ⟨[(rukhsaNeedsCertainty, true)], [(needsFirm, true)]⟩
open Field in
def yearDespair : Implication := ⟨[(yearPassed, true)], [(despair, true)]⟩
open Field in
def unidentifiedIsMajhul : Implication := ⟨[(ownerIdentifiable, false)], [(unknown, true), (despair, true)]⟩
open Field in
def majhulIsUnidentified : Implication := ⟨[(unknown, true), (despair, true)], [(ownerIdentifiable, false)]⟩
open Field in
def knownIsIdentified : Implication := ⟨[(unknown, false)], [(ownerIdentifiable, true)]⟩
open Field in
def hopedIsIdentified : Implication := ⟨[(despair, false)], [(ownerIdentifiable, true)]⟩
open Field in
def consumedIsMajhul : Implication := ⟨[(consumed, true)], [(unknown, true), (despair, true)]⟩

def implications : List Implication :=
  [rukhsaNeedsFirm, yearDespair, unidentifiedIsMajhul, majhulIsUnidentified, knownIsIdentified,
   hopedIsIdentified, consumedIsMajhul]

/-- Every relation, repeated until chains settle (one round per relation suffices). -/
def saturate (s : Situation) : Situation :=
  (List.range implications.length).foldl (fun s _ => implications.foldl (fun s r => r.fire s) s) s

/-! ## The relations, at work -/

theorem year_settles_despair : (saturate { yearPassed := some true }).despair = some true := by decide

theorem rukhsa_settles_firmness :
    (saturate { rukhsaNeedsCertainty := some true }).needsFirm = some true := by decide

/-- A stated fact is never overridden: a text that says the year passed but the owner is still
hoped for keeps its word. -/
theorem stated_fact_kept :
    (saturate { yearPassed := some true, despair := some false }).despair = some false := by decide

/-- Chains settle: consumed ⇒ unknown and despaired of ⇒ the right-holder cannot be identified. -/
theorem consumed_is_unidentified :
    (saturate { consumed := some true }).ownerIdentifiable = some false := by decide

/-- After saturation, a luqaṭa text past its year is routed to 106's encoder once it states the
remaining facts. -/
theorem luqata_routes_to_majhul :
    unknownAsNonexistent.applies
      (saturate { yearPassed := some true, unknown := some true, hardship := some false }) = true := by
  decide

/-- The fifth relation is what the kernel already assumes: `istihlak c = treatedAsAbsent c true _`.
On a consumed thing, 106's encoder on the saturated situation rules as `istihlak` does. -/
theorem istihlak_agrees (h : Bool) :
    unknownAsNonexistent.judge (saturate { consumed := some true, hardship := some h }) =
      istihlak.judge { consumed := some true } := by
  cases h <;> decide

end Usul.Typing
