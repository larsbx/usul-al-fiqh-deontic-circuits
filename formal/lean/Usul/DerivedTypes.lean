import Usul.Qiyas
import Usul.Muamalat
import Usul.Kulliyyat

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


/-! ## Q41 / S7 — certified coverage, without assuming equivalence or minimality -/

/-- A proposed set of performances with a proof that each owed act is discharged. -/
structure DischargePlan {α : Type} (r : α → α → Prop) (owed : List α) where
  done : List α
  covers : Schema.Covers r done owed

def representativePlan {α : Type} (r : α → α → Prop) [DecidableRel r]
    (reflexive : ∀ a, r a a) (owed : List α) : DischargePlan r owed :=
  ⟨Schema.reps r owed, Schema.reps_covers reflexive owed⟩

/-- Each obligation has a performed witness. No equivalence assumption is needed. -/
theorem DischargePlan.dischargesEach {α : Type} {r : α → α → Prop} {owed : List α}
    (p : DischargePlan r owed) {o : α} (ho : o ∈ owed) :
    ∃ d ∈ p.done, r d o := p.covers o ho

/-- The Q41 reading uses same kind and purpose; source-specific extra conditions
must be supplied by a different relation, not inferred from this certificate. -/
def worshipPlan {K P O : Type} [DecidableEq K] [DecidableEq P]
    (owed : List (Kulliyyat.Act K P O)) :
    DischargePlan Kulliyyat.Merges owed :=
  representativePlan Kulliyyat.Merges Kulliyyat.q41_merges_refl owed

/-! ## Q46 — a bounded permission under an evident cause and refusal -/

structure TakingContext where
  causeEvident : Bool
  refuses : Bool
  claim : Nat

/-- Local Q46 certificate; context facts are supplied, not inferred from text. -/
structure TakingPermission (ctx : TakingContext) where
  amount : Nat
  evident : ctx.causeEvident = true
  refused : ctx.refuses = true
  bounded : amount ≤ ctx.claim

def certifyTaking (ctx : TakingContext) (amount : Nat) : Option (TakingPermission ctx) :=
  if he : ctx.causeEvident = true then
    if hr : ctx.refuses = true then
      if hb : amount ≤ ctx.claim then some ⟨amount, he, hr, hb⟩ else none
    else none
  else none

theorem TakingPermission.permitted {ctx : TakingContext} (p : TakingPermission ctx) :
    Muamalat.mayTake ctx.causeEvident ctx.refuses ctx.claim p.amount = true := by
  simp [Muamalat.mayTake, p.evident, p.refused, p.bounded]

/-- The certified interface accepts exactly the old Boolean evaluator's cases. -/
theorem certifyTaking_complete (ctx : TakingContext) (amount : Nat) :
    (certifyTaking ctx amount).isSome = Muamalat.mayTake
      ctx.causeEvident ctx.refuses ctx.claim amount := by
  rcases ctx with ⟨e, r, c⟩
  cases e <;> cases r <;> by_cases h : amount ≤ c <;>
    simp [certifyTaking, Muamalat.mayTake, h]

theorem hiddenCause_noPermission {ctx : TakingContext} (h : ctx.causeEvident = false) :
    ¬ Nonempty (TakingPermission ctx) := by
  rintro ⟨p⟩
  have := p.evident
  simp [h] at this

theorem excessiveTaking_noPermission {ctx : TakingContext} {amount : Nat}
    (h : ctx.claim < amount) :
    ¬ ∃ p : TakingPermission ctx, p.amount = amount := by
  rintro ⟨p, hp⟩
  have hb := p.bounded
  rw [hp] at hb
  omega

end Usul.DerivedTypes
