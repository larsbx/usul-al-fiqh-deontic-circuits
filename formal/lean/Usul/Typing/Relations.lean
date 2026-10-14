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
| `q95IsInquiry…`, `inquiryIsQ95…` | 95 «تركه الفحص عن حاله تفريط» | 6 «فرط بترك البحث والتحقيق», and back |
| `despairedIsDespair`, `hopedIsNotDespair` | 97 «آيس من قدومه» / «يرجى قدومه» | 106 «إذا يئس من الوقوف عليه» |
| `knownOwner…`, `unknownOwner…` | 97 «يعرف مالكه» / «لم يعرف مالكه بل جهل» | 98 «إذا جهل ربه», and back |
| `unknownOwnerIsMajhul` | 98 «إذا جهل ربه» | 106: unknown |

The fifth is what the kernel already assumes in `Refinements.istihlak` (`istihlak_agrees`).

The shards' three look-alikes (2026-10-14), decided from the texts:
* 95's negligence is 6's: 95 explains its «لتفريطه» as «تركه الفحص عن حاله تفريط», and 6 as «فرط بترك
  البحث والتحقيق», each of one who acted on a presumption later shown wrong. Neither qāʿida builds
  on the other, so the fields stay apart and are related both ways, at both values.
* 97's despair of the absent owner's return is 106's despair: 97 rests it on the mafqūd, whose
  life is presumed («وإن كان الأصل بقاءه»), and its furūʿ say «وأيس من الاطلاع عليه», 106's
  «يئس من الوقوف عليه». 106's despair is wider (the mustaḥāḍa's blood), so only 97 ⇒ 106.
* 97's known owner is 98's owner not unknown: 97 says «وإن لم يعرف مالكه بل جهل», 98 «إذا جهل ربه»;
  both ways, negated. 98's unknown owner is an instance of 106's unknown, as 106.f002 «لجهالة ربها»
  is; 106's unknown is wider (an heir, a time), so only 98 ⇒ 106, and only when unknown. 97 does not
  settle 106's unknown: its despaired-of owner is known.
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
def negligentQ95 : BoolField := ⟨(·.negligentQ95), fun s v => { s with negligentQ95 := v }⟩
def negligentInquiry : BoolField := ⟨(·.negligentInquiry), fun s v => { s with negligentInquiry := v }⟩
def despaired : BoolField := ⟨(·.despaired), fun s v => { s with despaired := v }⟩
def ownerKnown : BoolField := ⟨(·.ownerKnown), fun s v => { s with ownerKnown := v }⟩
def ownerUnknown : BoolField := ⟨(·.ownerUnknown), fun s v => { s with ownerUnknown := v }⟩
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

open Field in
def q95IsInquiryNegligent : Implication := ⟨[(negligentQ95, true)], [(negligentInquiry, true)]⟩
open Field in
def q95IsInquiryDiligent : Implication := ⟨[(negligentQ95, false)], [(negligentInquiry, false)]⟩
open Field in
def inquiryIsQ95Negligent : Implication := ⟨[(negligentInquiry, true)], [(negligentQ95, true)]⟩
open Field in
def inquiryIsQ95Diligent : Implication := ⟨[(negligentInquiry, false)], [(negligentQ95, false)]⟩
open Field in
def despairedIsDespair : Implication := ⟨[(despaired, true)], [(despair, true)]⟩
open Field in
def hopedIsNotDespair : Implication := ⟨[(despaired, false)], [(despair, false)]⟩
open Field in
def knownOwnerNotUnknown : Implication := ⟨[(ownerKnown, true)], [(ownerUnknown, false)]⟩
open Field in
def knownOwnerDenied : Implication := ⟨[(ownerKnown, false)], [(ownerUnknown, true)]⟩
open Field in
def unknownOwnerNotKnown : Implication := ⟨[(ownerUnknown, true)], [(ownerKnown, false)]⟩
open Field in
def unknownOwnerDenied : Implication := ⟨[(ownerUnknown, false)], [(ownerKnown, true)]⟩
open Field in
def unknownOwnerIsMajhul : Implication := ⟨[(ownerUnknown, true)], [(unknown, true)]⟩

def implications : List Implication :=
  [rukhsaNeedsFirm, yearDespair, unidentifiedIsMajhul, majhulIsUnidentified, knownIsIdentified,
   hopedIsIdentified, consumedIsMajhul, q95IsInquiryNegligent, q95IsInquiryDiligent,
   inquiryIsQ95Negligent, inquiryIsQ95Diligent, despairedIsDespair, hopedIsNotDespair,
   knownOwnerNotUnknown, knownOwnerDenied, unknownOwnerNotKnown, unknownOwnerDenied,
   unknownOwnerIsMajhul]

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

/-! ## The shards' look-alikes, at work -/

/-- 95.f008 «يضمن لتفريطه» settles 6's negligence in inquiry; 6.f004's diligent qibla-seeker
settles 95's. -/
theorem q95_negligence_is_inquiry :
    (saturate { negligentQ95 := some true }).negligentInquiry = some true ∧
      (saturate { negligentInquiry := some false }).negligentQ95 = some false := by decide

/-- 97's absent owner despaired of, with his identity known, is 106's despair and nothing more:
106's unknown stays open. -/
theorem q97_despair_is_106 :
    (saturate { ownerKnown := some true, despaired := some true }).despair = some true ∧
      (saturate { ownerKnown := some true, despaired := some true }).unknown = none := by decide

/-- 97's unknown owner, despaired of, chains through 98 and 106 to Q20: the right-holder cannot
be identified. -/
theorem q97_unknown_owner_is_unidentified :
    (saturate { ownerKnown := some false, despaired := some true }).ownerIdentifiable = some false := by
  decide

/-- 98's handover by description and 106 meet on one situation: an unknown owner settles 106's
unknown, never the converse. -/
theorem q98_owner_is_106_unknown :
    (saturate { ownerUnknown := some true }).unknown = some true ∧
      (saturate { unknown := some true }).ownerUnknown = none := by decide

end Usul.Typing
