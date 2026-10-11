import Usul.Qiyas
import Usul.Muamalat

/-! Source terminology and scope: `docs/architecture/derived-types-glossary.md`.
These refinements certify the existing formal readings, not their source admission.
-/
namespace Usul.DerivedTypes

abbrev Admitted {α : Type} (g : Sadi.Gate α) := {x : α // g.Holds x}
abbrev CertainHeld (V : Type) := {h : Qawaid.Held V // h.IsYaqin}
abbrev GroundedHeld (V : Type) := {h : Qawaid.Held V // h.Suspended = false}
abbrev NecessityAllowance (need : Nat) := {taken : Nat // Qawaid.daruraPermits need taken}
abbrev CoherentRequirement := {r : Muamalat.Requirement // r.Coherent}
abbrev AdmittedDeal := Admitted Muamalat.Deal.gate
abbrev OptimalChoice {α : Type} (key : α → Int) (options : List α) :=
  {x : α // Schema.Optimal key options x}

def normalizeRequirement (r : Muamalat.Requirement) : CoherentRequirement :=
  ⟨r.normalize, Muamalat.q45_normalize_coherent r⟩

def certifyChoice {α : Type} (key : α → Int) (options : List α) :
    Option (OptimalChoice key options) :=
  match h : Sadi.best key options with
  | none => none
  | some x => some ⟨x, Schema.best_optimal h⟩

theorem certifyChoice_erases {α : Type} (key : α → Int) (options : List α) :
    (certifyChoice key options).map Subtype.val = Sadi.best key options := by
  unfold certifyChoice
  split <;> simp_all

theorem doubt_preserves {V : Type} (cur : CertainHeld V) (ev : Qawaid.Held V)
    (hs : ev.grade = .shakk) : Qawaid.update cur.val ev = cur.val :=
  Qawaid.yaqin_la_yazul_bish_shakk cur.val ev cur.property hs

/-- Local certification of all four premises of `applies`; not general waḍʿī validity. -/
structure Applicable {Act : Type} (w : Wad Act) where
  act : Act
  subject : Subject
  sabab : w.sabab act subject
  shart : w.shart act subject
  noMani : ¬ w.mani act subject
  mukallaf : subject.IsMukallaf

def applyRuling {Act : Type} {w : Wad Act} (ruling : Act → Hukm)
    (x : Applicable w) : Hukm :=
  applies w ruling x.act x.subject x.sabab x.shart x.noMani x.mukallaf

/-- Explicit executable factorization; stronger data than a bare invariance proposition. -/
structure FactoredRuling (Case Feature Result : Type) where
  feature : Case → Feature
  evaluate : Feature → Result
  ruling : Case → Result
  sound : ∀ c, ruling c = evaluate (feature c)

def FactoredRuling.factors {C F R : Type} (r : FactoredRuling C F R) :
    Schema.Factors r.ruling r.feature := Schema.Factors.of_eq r.evaluate r.sound

def destructionLiability : FactoredRuling (Bool × Muamalat.MentalState) Bool Bool :=
  ⟨Prod.fst, Bool.not, fun x => Muamalat.itlafLiable x.1 x.2, fun _ => rfl⟩

/-- Finite-case co-variation only; does not certify a transferable ʿilla. -/
abbrev ObservedDawaran {α β : Type} [DecidableEq β] (w : Qiyas.Wasf α)
    (r : β) (known : Qiyas.Known α β) :=
  {u : Unit // Qiyas.dawaran w r known = true}

abbrev AdmittedQiyas (α β : Type) := Admitted (Qiyas.gate (α := α) (β := β))

/-- Conditional transfer for the supplied ruling assignment H. -/
structure CertifiedTransfer {α β : Type} (H : α → β) where
  argument : AdmittedQiyas α β
  agrees : Qiyas.Agrees H argument.val.known
  factors : Schema.Factors H argument.val.illa

theorem CertifiedTransfer.conclusion {α β : Type} {H : α → β}
    (c : CertifiedTransfer H) : H c.argument.val.far = c.argument.val.hukm :=
  Qiyas.qiyas_sound c.argument.property c.agrees c.factors

end Usul.DerivedTypes
