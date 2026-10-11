import Usul.Signature
import Usul.Muamalat
import Usul.Refinements

/-!
# The type system: situations, and encoders typed over them

A takhrīj encoder reads a record of facts (its *local signature*) and returns a ruling. Read
alone, local signatures do not meet: two encoders that both ask whether the holder transgressed
ask it under different names. This module gives them a common type.

* **The qawāʿid define the types.** A qāʿida's statement ranges over certain facts, and the
  structure in `Qaida` named after it holds exactly those, each `Option` until a text settles it.
  A qāʿida that builds on another extends its type (Q52 extends Q11). `Situation` is the join of
  the qāʿida types: a field is shared only where qawāʿid state the same notion, so negligence in
  safekeeping (Q14 «يفرط») and negligence in inquiry (Ibn Rajab Q6 «فرط بترك البحث») stay two
  fields, and Lean checks that a field merged through `extends` has one type.
* `Typed S O` is an encoder typed over `S`, ruling in `O`. `proj` reads its local signature off a situation, if
  every field it needs is known; `embed` writes a local record into a situation; the law
  `proj_embed` says nothing is lost on the way. `run` is the encoder's existing kernel function,
  so typing an encoder changes no ruling (conservativity by construction).
* `Typed.applies s` is the typing judgement used for routing: the situation inhabits the
  encoder's signature. A field it lacks is a `missing_fact`. Two encoders that apply to one
  situation and disagree are taʿāruḍ material (`Usul.Taarud`).

Routing by type replaces routing by wording: a classical farʿ and a modern fatwā that describe
the same situation receive the same `Situation`, whatever their words (roadmap T2, T3).
-/

namespace Usul.Typing

open Usul Usul.Muamalat

/-- An encoder typed over the situation type `S`, ruling in `O`. -/
structure Typed (S O : Type) where
  Local : Type
  proj : S → Option Local
  embed : Local → S
  run : Local → O
  proj_embed : ∀ l, proj (embed l) = some l

namespace Typed

variable {S O : Type} (E : Typed S O)

/-- The situation inhabits the encoder's signature: every fact it reads is known. -/
def applies (s : S) : Bool := (E.proj s).isSome

/-- The encoder's ruling on a situation, when it applies. -/
def judge (s : S) : Option O := (E.proj s).map E.run

theorem judge_embed (l : E.Local) : E.judge (E.embed l) = some (E.run l) := by
  simp [judge, E.proj_embed]

theorem applies_embed (l : E.Local) : E.applies (E.embed l) = true := by
  simp [applies, E.proj_embed]

theorem applies_iff_judge (s : S) : E.applies s = true ↔ (E.judge s).isSome = true := by
  simp [applies, judge]

end Typed

/-! ## The types the qawāʿid define -/

namespace Qaida

/-- al-Saʿdī Q11 «الأصل بقاء ما كان على ما كان، واليقين لا يزول بالشك»: the presumption and the
apparent that would displace it, each with its epistemic grade. -/
structure Yaqin where
  asl : Option Grade := none
  zahir : Option Grade := none

/-- al-Saʿdī Q52 «إذا قويت القرائن قدمت على الأصل»: Q11's type, with the indicator (qarīna). -/
structure Qarain extends Yaqin where
  amara : Option Bool := none

/-- al-Saʿdī Q13 «الإتلاف يستوي فيه المتعمد والجاهل والناسي»: the destroyer's state of mind. -/
structure ItlafHal where
  mental : Option MentalState := none

/-- al-Saʿdī Q36 «من أتلف شيئاً لينتفع به ضمنه، ومن أتلفه دفعاً لمضرته فلا ضمان عليه»: the purpose
of the destruction. -/
structure ItlafQasd where
  purpose : Option Purpose := none

/-- al-Saʿdī Q14 «التلف في يد الأمين غير مضمون إذا لم يتعد أو يفرط، وفي يد الظالم مضمون مطلقاً»: the
hand, and the trustee's transgression («يتعد») and negligence in safekeeping («يفرط»); with
`pureTrust`, the pure trust (amāna maḥḍa) that transgression voids. -/
structure Amana where
  hand : Option Hand := none
  pureTrust : Option Bool := none
  transgressed : Option Bool := none
  negligent : Option Bool := none

/-- Ibn Rajab Q6: an act done on a presumption later shown wrong stands, save «لتعلق حق الغير به»
and for one who «فرط بترك البحث والتحقيق» (negligence in inquiry, not in safekeeping). -/
structure ZannError where
  othersRight : Option Bool := none
  negligentInquiry : Option Bool := none

end Qaida

/-- A situation: the join of the qāʿida types. -/
structure Situation extends Qaida.Qarain, Qaida.ItlafHal, Qaida.ItlafQasd, Qaida.Amana, Qaida.ZannError

/-! ## Encoders typed over `Situation` (names as in `takhrij.ENCODERS`) -/

/-- `itlaf` reads Q13 ⊔ Q36: liable unless with right, whatever the state of mind. -/
def itlaf : Typed Situation Bool where
  Local := Purpose × MentalState
  proj s := do pure (← s.purpose, ← s.mental)
  embed | (p, m) => { purpose := some p, mental := some m }
  run | (p, m) => itlafLiable (withRight p) m
  proj_embed := fun _ => rfl

/-- `trust_loss` reads Q14: a trustee is liable only by transgression or negligence. -/
def trustLoss : Typed Situation Bool where
  Local := Hand × Bool × Bool
  proj s := do pure (← s.hand, ← s.transgressed, ← s.negligent)
  embed | (h, t, n) => { hand := some h, transgressed := some t, negligent := some n }
  run | (h, t, n) => lossLiable h t n
  proj_embed := fun _ => rfl

/-- `trust_voidance` reads Q14: a pure trust is voided by transgression. -/
def trustVoidance : Typed Situation Bool where
  Local := Bool × Bool
  proj s := do pure (← s.pureTrust, ← s.transgressed)
  embed | (p, t) => { pureTrust := some p, transgressed := some t }
  run | (p, t) => Refinements.trustVoided p t
  proj_embed := fun _ => rfl

/-- `excused_error` reads Ibn Rajab Q6. -/
def excusedError : Typed Situation Bool where
  Local := Bool × Bool
  proj s := do pure (← s.othersRight, ← s.negligentInquiry)
  embed | (o, n) => { othersRight := some o, negligentInquiry := some n }
  run | (o, n) => Refinements.errorExcused o n
  proj_embed := fun _ => rfl

/-- `asl_zahir` reads Q52, which extends Q11. -/
def aslZahir : Typed Situation Bool where
  Local := Grade × Grade × Bool
  proj s := do pure (← s.asl, ← s.zahir, ← s.amara)
  embed | (a, z, m) => { asl := some a, zahir := some z, amara := some m }
  run | (a, z, m) => Refinements.zahirPrevails a z m
  proj_embed := fun _ => rfl

/-! ## What typing by qāʿida buys -/

/-- Q14 types both trust encoders: a text that settles «يتعد» once serves both. -/
theorem transgression_is_shared (h : Hand) (p t n : Bool) :
    let s : Situation := { hand := some h, pureTrust := some p, transgressed := some t, negligent := some n }
    trustLoss.judge s = some (lossLiable h t n) ∧
      trustVoidance.judge s = some (Refinements.trustVoided p t) :=
  ⟨rfl, rfl⟩

/-- Negligence is qualified by its qāʿida: settling negligence in safekeeping (Q14) does not
settle negligence in inquiry (Ibn Rajab Q6), so `excused_error` still lacks a fact. -/
theorem negligence_is_qualified :
    let s : Situation := { hand := some .trustee, transgressed := some false, negligent := some true,
                           othersRight := some false }
    trustLoss.applies s = true ∧ excusedError.applies s = false :=
  ⟨rfl, rfl⟩

/-- `itlaf` needs both qawāʿid's facts: the purpose alone (Q36) leaves it a missing fact (Q13). -/
theorem itlaf_reads_two_qawaid (p : Purpose) :
    itlaf.applies { purpose := some p } = false := rfl

/-- Q52 extends Q11: the presumption's fields are Q11's, read through Q52's type. -/
theorem qarain_extends_yaqin (s : Situation) :
    s.toQarain.toYaqin.asl = s.asl ∧ s.toQarain.toYaqin.zahir = s.zahir := ⟨rfl, rfl⟩

end Usul.Typing
