import Usul.Typing.Qaida

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

/-! The types the qawāʿid define are in `Usul.Typing.Qaida` (`Usul/Typing/Qaida.lean`). -/


/-- A situation: the join of the qāʿida types. -/
structure Situation extends Qaida.Qarain, Qaida.ItlafHal, Qaida.ItlafQasd, Qaida.Amana, Qaida.ZannError,
    Qaida.MajhulHaqq, Qaida.Luqata, Qaida.Istihlak, Qaida.BadalWujub, Qaida.Intiqal, Qaida.Itizal,
    Qaida.Rukhsa, Qaida.NiyyaMansiyya, Qaida.Mubashara, Qaida.Rajab111, Qaida.Rajab81, Qaida.Rajab53,
    Qaida.Rajab77, Qaida.Rajab73, Qaida.Rajab118, Qaida.Rajab109, Qaida.Rajab79, Qaida.Rajab69,
    Qaida.Rajab97, Qaida.Rajab113, Qaida.Rajab71, Qaida.Rajab95, Qaida.Rajab102, Qaida.Rajab99,
    Qaida.Rajab92, Qaida.Rajab98, Qaida.Rajab105, Qaida.Rajab107, Qaida.Rajab72, Qaida.Rajab112,
    Qaida.Rajab117, Qaida.Rajab110, Qaida.Rajab116, Qaida.Rajab96, Qaida.Rajab67, Qaida.Rajab80,
    Qaida.Rajab60, Qaida.Rajab78, Qaida.Rajab94, Qaida.Rajab90, Qaida.Rajab115, Qaida.Rajab101,
    Qaida.Rajab104, Qaida.Rajab108, Qaida.Rajab114, Qaida.Rajab100, Qaida.Rajab74, Qaida.Rajab4, Qaida.Rajab5, Qaida.Lahham43, Qaida.Rajab59,
    Qaida.Sadi9, Qaida.Rajab32, Qaida.Rajab35, Qaida.Rajab27, Qaida.Rajab14, Qaida.Rajab14Certainty, Qaida.Rajab12,
    Qaida.Rajab28, Qaida.Rajab56, Qaida.Rajab43, Qaida.Sadi48, Qaida.Rajab39, Qaida.Rajab51,
    Qaida.Rajab47, Qaida.Rajab61, Qaida.Rajab58, Qaida.Rajab52, Qaida.Rajab54, Qaida.Sadi35,
    Qaida.Rajab15, Qaida.Rajab3, Qaida.Rajab30, Qaida.Sadi25, Qaida.Rajab25, Qaida.Rajab50,
    Qaida.Sadi59, Qaida.Rajab20, Qaida.Rajab2, Qaida.Lahham52, Qaida.Rajab91, Qaida.ShakkShartFuru,
    Qaida.Rajab33, Qaida.Khalt, Qaida.Sadi45, Qaida.Rajab36, Qaida.Rajab31, Qaida.Rajab34,
    Qaida.Rajab17, Qaida.Rajab66, Qaida.Rajab11, Qaida.Sadi40, Qaida.Sadi30, Qaida.Rajab9,
    Qaida.Rajab49, Qaida.Rajab65, Qaida.Sadi32, Qaida.Rajab62, Qaida.Sadi50, Qaida.Rajab42,
    Qaida.Rajab24, Qaida.Sadi55, Qaida.Rajab55, Qaida.Rajab41, Qaida.Rajab57, Qaida.Rajab1,
    Qaida.Rajab19, Qaida.Rajab37, Qaida.Sadi41, Qaida.Rajab93, Qaida.Rajab29, Qaida.Lahham61,
    Qaida.Rajab64, Qaida.Rajab46, Qaida.Rajab10, Qaida.Rajab38, Qaida.Rajab119, Qaida.Rajab120,
    Qaida.Rajab121, Qaida.Rajab122, Qaida.Rajab123, Qaida.Rajab124, Qaida.Rajab125, Qaida.Rajab126,
    Qaida.Rajab128, Qaida.Rajab129, Qaida.Rajab130, Qaida.Rajab131,
    Qaida.Rajab132, Qaida.Rajab134, Qaida.Rajab136, Qaida.Rajab137, Qaida.Rajab138, Qaida.Rajab139, Qaida.Rajab141, Qaida.Rajab142, Qaida.Rajab143, Qaida.Rajab144, Qaida.Rajab145, Qaida.Rajab146,
    Qaida.Rajab147, Qaida.Rajab149, Qaida.Rajab150, Qaida.Rajab151, Qaida.Rajab152, Qaida.Rajab153, Qaida.Rajab154, Qaida.Rajab155, Qaida.Rajab156, Qaida.Rajab157,
    Qaida.Rajab158,
    Qaida.Rajab13, Qaida.Rajab23, Qaida.Rajab40, Qaida.Rajab70, Qaida.Rajab84, Qaida.Rajab85, Qaida.Rajab86, Qaida.Rajab87, Qaida.Rajab88,
    Qaida.Rajab82, Qaida.Istislah, Qaida.MaqasidTarjih

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

/-- `trust_voidance` reads Q14: a pure trust (amāna maḥḍa) is voided by transgression («تبطل بالتعدي»: bāṭil). -/
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

/-- `unknown_owner` reads Q20. -/
def unknownOwner : Typed Situation Muamalat.Recipient where
  Local := Bool
  proj s := s.ownerIdentifiable
  embed o := { ownerIdentifiable := some o }
  run := recipient
  proj_embed := fun _ => rfl

/-- `unknown_as_nonexistent` reads Ibn Rajab 106. -/
def unknownAsNonexistent : Typed Situation Bool where
  Local := Bool × Bool × Bool
  proj s := do pure (← s.unknown, ← s.despair, ← s.hardship)
  embed | (u, d, h) => { unknown := some u, despair := some d, hardship := some h }
  run | (u, d, h) => Refinements.treatedAsAbsent u d h
  proj_embed := fun _ => rfl

/-- `luqata` reads 106.f002's type. -/
def luqata : Typed Situation Refinements.LuqataOutcome where
  Local := Bool × Bool
  proj s := do pure (← s.yearPassed, ← s.ownable)
  embed | (y, o) => { yearPassed := some y, ownable := some o }
  run | (y, o) => Refinements.luqata y o
  proj_embed := fun _ => rfl

/-- `istihlak` reads Ibn Rajab 22's type. -/
def istihlak : Typed Situation Bool where
  Local := Bool
  proj s := s.consumed
  embed c := { consumed := some c }
  run := Refinements.istihlak
  proj_embed := fun _ => rfl

/-- `substitute` reads Q28. -/
def substitute : Typed Situation Bool where
  Local := Bool
  proj s := s.originalPossible
  embed p := { originalPossible := some p }
  run := Sadi.useSubstitute
  proj_embed := fun _ => rfl

/-- `substitute_at_obligation` reads Ibn Rajab 16's type, which extends Q28's. -/
def substituteAtObligation : Typed Situation Bool where
  Local := Bool × Bool
  proj s := do pure (← s.originalPossible, ← s.settledAtObligation)
  embed | (p, t) => { originalPossible := some p, settledAtObligation := some t }
  run | (p, t) => Refinements.useSubstituteAt p t
  proj_embed := fun _ => rfl

/-- `switch_to_original` reads Ibn Rajab 7's type. -/
def switchToOriginal : Typed Situation Bool where
  Local := Bool
  proj s := s.necessity
  embed n := { necessity := some n }
  run := Refinements.mustSwitch
  proj_embed := fun _ => rfl

/-- `abstention_under_possible_condition` reads Ibn Rajab 160's type. -/
def abstentionUnderPossibleCondition : Typed Situation Bool where
  Local := Bool × Bool × Bool
  proj s := do pure (← s.suspended, ← s.possible, ← s.absenceKnown)
  embed | (u, p, a) => { suspended := some u, possible := some p, absenceKnown := some a }
  run | (u, p, a) => Refinements.abstains u p a
  proj_embed := fun _ => rfl

/-- `doubt_in_condition` reads Ibn Rajab 68's type; its ghalaba is the ẓāhir reaching ẓann. -/
def doubtInCondition : Typed Situation Bool where
  Local := Bool × Bool × Bool
  proj s := do pure (← s.needsFirm, decide (← s.zahir).IsYaqin, ← s.aslMustashab)
  embed | (n, g, a) => { needsFirm := some n, zahir := some (if g then .zann else .shakk), aslMustashab := some a }
  run | (n, g, a) => Refinements.validUnderDoubt n g a
  proj_embed := fun ⟨_, g, _⟩ => by cases g <;> rfl

/-- `rukhsa_under_doubt` reads 68.f001's type. -/
def rukhsaUnderDoubt : Typed Situation Bool where
  Local := Bool × Bool
  proj s := do pure (← s.rukhsaNeedsCertainty, ← s.permissionEstablished)
  embed | (n, p) => { rukhsaNeedsCertainty := some n, permissionEstablished := some p }
  run | (n, p) => Refinements.rukhsaValid n p
  proj_embed := fun _ => rfl

/-- `ihram_specification` reads the forgotten intention's type. -/
def ihramSpecification : Typed Situation Bool where
  Local := Refinements.Nusuk → Bool
  proj s := s.component
  embed c := { component := some c }
  run c := Refinements.validOnEvery c Refinements.Nusuk.all
  proj_embed := fun _ => rfl

/-- Q28 types both substitute encoders: whether the original is possible is settled once. -/
theorem original_possibility_is_shared (p t : Bool) :
    let s : Situation := { originalPossible := some p, settledAtObligation := some t }
    substitute.judge s = some (Sadi.useSubstitute p) ∧
      substituteAtObligation.judge s = some (Refinements.useSubstituteAt p t) :=
  ⟨rfl, rfl⟩

/-- A type that extends its qāʿida's carries its fields: luqaṭa's situation is a 106 situation. -/
theorem luqata_extends_majhul (s : Situation) :
    s.toLuqata.toMajhulMadum.unknown = s.unknown := rfl

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
