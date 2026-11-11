import Usul.Hukm

/-!
# IDA foundation

The algebra uses the existing qualitative `Hukm` carrier and its order.  Numeric
codes below are only a wire format, never the definition of a ruling or its
order.  Partial answers are constraints for the conjunction of two required
premises.  They make no claim about source authentication or legal admission.
-/
namespace Usul.IDA

/-- Minimum in the existing qualitative order. -/
def meet (a b : Hukm) : Hukm := if a ≤ b then a else b
/-- Maximum in the existing qualitative order. -/
def join (a b : Hukm) : Hukm := if a ≤ b then b else a
/-- The existing omission duality. -/
def sigma : Hukm → Hukm := Hukm.σ

theorem meet_le_left (a b : Hukm) : meet a b ≤ a := by
  cases a <;> cases b <;> decide
theorem meet_le_right (a b : Hukm) : meet a b ≤ b := by
  cases a <;> cases b <;> decide
theorem le_meet_iff (a b c : Hukm) : a ≤ meet b c ↔ a ≤ b ∧ a ≤ c := by
  cases a <;> cases b <;> cases c <;> decide
theorem left_le_join (a b : Hukm) : a ≤ join a b := by
  cases a <;> cases b <;> decide
theorem right_le_join (a b : Hukm) : b ≤ join a b := by
  cases a <;> cases b <;> decide
theorem join_le_iff (a b c : Hukm) : join a b ≤ c ↔ a ≤ c ∧ b ≤ c := by
  cases a <;> cases b <;> cases c <;> decide
theorem meet_eq_left_iff (a b : Hukm) : meet a b = a ↔ a ≤ b := by
  cases a <;> cases b <;> decide
theorem join_eq_right_iff (a b : Hukm) : join a b = b ↔ a ≤ b := by
  cases a <;> cases b <;> decide

theorem meet_comm (a b : Hukm) : meet a b = meet b a := by
  cases a <;> cases b <;> decide
theorem join_comm (a b : Hukm) : join a b = join b a := by
  cases a <;> cases b <;> decide
theorem meet_assoc (a b c : Hukm) : meet (meet a b) c = meet a (meet b c) := by
  cases a <;> cases b <;> cases c <;> decide
theorem join_assoc (a b c : Hukm) : join (join a b) c = join a (join b c) := by
  cases a <;> cases b <;> cases c <;> decide
theorem meet_idem (a : Hukm) : meet a a = a := by cases a <;> decide
theorem join_idem (a : Hukm) : join a a = a := by cases a <;> decide
theorem meet_absorb (a b : Hukm) : meet a (join a b) = a := by
  cases a <;> cases b <;> decide
theorem join_absorb (a b : Hukm) : join a (meet a b) = a := by
  cases a <;> cases b <;> decide
theorem meet_join_distrib (a b c : Hukm) :
    meet a (join b c) = join (meet a b) (meet a c) := by
  cases a <;> cases b <;> cases c <;> decide
theorem join_meet_distrib (a b c : Hukm) :
    join a (meet b c) = meet (join a b) (join a c) := by
  cases a <;> cases b <;> cases c <;> decide
theorem meet_top (a : Hukm) : meet a .wajib = a := by cases a <;> decide
theorem join_bottom (a : Hukm) : join a .haram = a := by cases a <;> decide
theorem meet_bottom (a : Hukm) : meet a .haram = .haram := by cases a <;> decide
theorem join_top (a : Hukm) : join a .wajib = .wajib := by cases a <;> decide
theorem bottom_le (a : Hukm) : Hukm.haram ≤ a := Hukm.haram_le a
theorem le_top (a : Hukm) : a ≤ Hukm.wajib := Hukm.le_wajib a

theorem sigma_involutive (a : Hukm) : sigma (sigma a) = a := Hukm.σ_σ a
theorem sigma_order_reversing {a b : Hukm} (h : a ≤ b) : sigma b ≤ sigma a :=
  Hukm.σ_antitone h
theorem sigma_le_sigma_iff (a b : Hukm) : sigma a ≤ sigma b ↔ b ≤ a :=
  Hukm.σ_le_σ
theorem sigma_meet (a b : Hukm) : sigma (meet a b) = join (sigma a) (sigma b) := by
  cases a <;> cases b <;> decide
theorem sigma_join (a b : Hukm) : sigma (join a b) = meet (sigma a) (sigma b) := by
  cases a <;> cases b <;> decide
theorem sigma_fixed_iff (a : Hukm) : sigma a = a ↔ a = .mubah := Hukm.σ_fixed_iff a

/-- A finite subset represented by five independent membership decisions. -/
structure HukmSet where
  haram : Bool
  makruh : Bool
  mubah : Bool
  mandub : Bool
  wajib : Bool
  deriving DecidableEq, Repr

namespace HukmSet

def mem (s : HukmSet) : Hukm → Bool
  | .haram => s.haram
  | .makruh => s.makruh
  | .mubah => s.mubah
  | .mandub => s.mandub
  | .wajib => s.wajib

def Nonempty (s : HukmSet) : Prop :=
  s.haram = true ∨ s.makruh = true ∨ s.mubah = true ∨ s.mandub = true ∨ s.wajib = true

instance (s : HukmSet) : Decidable s.Nonempty :=
  inferInstanceAs (Decidable (_ ∨ _ ∨ _ ∨ _ ∨ _))

def Subset (s t : HukmSet) : Prop := ∀ h, s.mem h = true → t.mem h = true

def inter (s t : HukmSet) : HukmSet :=
  ⟨s.haram && t.haram, s.makruh && t.makruh, s.mubah && t.mubah,
    s.mandub && t.mandub, s.wajib && t.wajib⟩

def all : HukmSet := ⟨true, true, true, true, true⟩
def singleton (h : Hukm) : HukmSet :=
  ⟨h == .haram, h == .makruh, h == .mubah, h == .mandub, h == .wajib⟩

theorem mem_inter (s t : HukmSet) (h : Hukm) :
    (s.inter t).mem h = (s.mem h && t.mem h) := by cases h <;> rfl

theorem inter_subset_left (s t : HukmSet) : (s.inter t).Subset s := by
  intro h hm
  rw [mem_inter] at hm
  simp only [Bool.and_eq_true] at hm
  exact hm.1

theorem inter_subset_right (s t : HukmSet) : (s.inter t).Subset t := by
  intro h hm
  rw [mem_inter] at hm
  simp only [Bool.and_eq_true] at hm
  exact hm.2

theorem nonempty_iff_exists (s : HukmSet) : s.Nonempty ↔ ∃ h, s.mem h = true := by
  constructor
  · intro hs
    rcases hs with hs | hs | hs | hs | hs
    · exact ⟨.haram, hs⟩
    · exact ⟨.makruh, hs⟩
    · exact ⟨.mubah, hs⟩
    · exact ⟨.mandub, hs⟩
    · exact ⟨.wajib, hs⟩
  · rintro ⟨h, hh⟩
    cases h
    · exact Or.inr (Or.inr (Or.inr (Or.inr hh)))
    · exact Or.inr (Or.inr (Or.inr (Or.inl hh)))
    · exact Or.inr (Or.inr (Or.inl hh))
    · exact Or.inr (Or.inl hh)
    · exact Or.inl hh

theorem singleton_nonempty (h : Hukm) : (singleton h).Nonempty := by
  cases h <;> decide

theorem all_nonempty : all.Nonempty := by decide

end HukmSet

/-- A known answer always denotes at least one ruling. -/
structure Constraint where
  set : HukmSet
  nonempty : set.Nonempty
  deriving DecidableEq

namespace Constraint

def all : Constraint := ⟨HukmSet.all, HukmSet.all_nonempty⟩
def singleton (h : Hukm) : Constraint := ⟨HukmSet.singleton h, HukmSet.singleton_nonempty h⟩

theorem has_member (s : Constraint) : ∃ h, s.set.mem h = true :=
  (HukmSet.nonempty_iff_exists s.set).mp s.nonempty

end Constraint


/-!
## Structured targets

Qualified names, named reference sorts, declared operation signatures, and
ordered operands make the expression inspectable. These predicates check the
supplied structure, not source authority, reference resolution, applicability,
or voluntary control. Control remains in the surrounding context.
-/

/-- A qualified vocabulary name. -/
structure Symbol where
  space : String
  name : String
  deriving DecidableEq, Repr

namespace Symbol
def WellFormed (symbol : Symbol) : Prop :=
  symbol.space ≠ "" ∧ symbol.name ≠ ""
instance (symbol : Symbol) : Decidable symbol.WellFormed :=
  inferInstanceAs (Decidable (symbol.space ≠ "" ∧ symbol.name ≠ ""))
end Symbol

/-- Reference sorts in this representation, not categories of rulings. -/
inductive RefKind where
  | person | asset | obligation | occurrence | proposition
  deriving DecidableEq, Repr

/-- A reference retains both its sort and its qualified name. -/
structure EntityRef where
  kind : RefKind
  symbol : Symbol
  deriving DecidableEq, Repr

namespace EntityRef
def WellFormed (referent : EntityRef) : Prop := referent.symbol.WellFormed
instance (referent : EntityRef) : Decidable referent.WellFormed :=
  inferInstanceAs (Decidable referent.symbol.WellFormed)
end EntityRef

/-- One named, typed slot in an operation signature. -/
structure Parameter where
  role : String
  kind : RefKind
  deriving DecidableEq, Repr

/-- One named, typed argument supplied to an operation. -/
structure Operand where
  role : String
  referent : EntityRef
  deriving DecidableEq, Repr

namespace Operand
def parameter (operand : Operand) : Parameter :=
  ⟨operand.role, operand.referent.kind⟩
end Operand

/-- The entire declared signature participates in operation identity. -/
structure Operation where
  symbol : Symbol
  parameters : List Parameter
  deriving DecidableEq, Repr

namespace Operation
def WellFormed (operation : Operation) : Prop :=
  operation.symbol.WellFormed ∧
  operation.parameters.all (fun parameter => decide (parameter.role ≠ "")) = true ∧
  (operation.parameters.map Parameter.role).Nodup
instance (operation : Operation) : Decidable operation.WellFormed :=
  inferInstanceAs (Decidable (
    operation.symbol.WellFormed ∧
    operation.parameters.all (fun parameter => decide (parameter.role ≠ "")) = true ∧
    (operation.parameters.map Parameter.role).Nodup))
end Operation

/-- An operation instantiated with ordered, named, typed operands. -/
structure Action where
  operation : Operation
  operands : List Operand
  deriving DecidableEq, Repr

namespace Action
def WellFormed (action : Action) : Prop :=
  action.operation.WellFormed ∧
  action.operands.map Operand.parameter = action.operation.parameters ∧
  action.operands.all (fun operand => decide operand.referent.WellFormed) = true
instance (action : Action) : Decidable action.WellFormed :=
  inferInstanceAs (Decidable (
    action.operation.WellFormed ∧
    action.operands.map Operand.parameter = action.operation.parameters ∧
    action.operands.all (fun operand => decide operand.referent.WellFormed) = true))
end Action

/-- A named occurrence and strictly ordered interval on a named clock. -/
structure Opportunity where
  occurrence : Symbol
  clock : Symbol
  opensAt : Nat
  closesAt : Nat
  deriving DecidableEq, Repr

namespace Opportunity
def WellFormed (opportunity : Opportunity) : Prop :=
  opportunity.occurrence.WellFormed ∧
  opportunity.clock.WellFormed ∧
  opportunity.opensAt < opportunity.closesAt
instance (opportunity : Opportunity) : Decidable opportunity.WellFormed :=
  inferInstanceAs (Decidable (
    opportunity.occurrence.WellFormed ∧
    opportunity.clock.WellFormed ∧
    opportunity.opensAt < opportunity.closesAt))
end Opportunity

/-- An affective quality directed toward an explicitly typed referent. -/
structure Affect where
  quality : Symbol
  concerns : EntityRef
  deriving DecidableEq, Repr

namespace Affect
def WellFormed (affect : Affect) : Prop :=
  affect.quality.WellFormed ∧ affect.concerns.WellFormed
instance (affect : Affect) : Decidable affect.WellFormed :=
  inferInstanceAs (Decidable (affect.quality.WellFormed ∧ affect.concerns.WellFormed))
end Affect

/-- Inspectable target syntax before structural checking. -/
inductive TargetExpr where
  | perform (action : Action)
  | omit (action : Action) (opportunity : Opportunity)
  | affect (state : Affect)
  deriving DecidableEq, Repr

namespace TargetExpr
def WellFormed : TargetExpr → Prop
  | .perform action => action.WellFormed
  | .omit action opportunity => action.WellFormed ∧ opportunity.WellFormed
  | .affect state => state.WellFormed
instance (expression : TargetExpr) : Decidable expression.WellFormed :=
  match expression with
  | .perform action => inferInstanceAs (Decidable action.WellFormed)
  | .omit action opportunity =>
      inferInstanceAs (Decidable (action.WellFormed ∧ opportunity.WellFormed))
  | .affect state => inferInstanceAs (Decidable state.WellFormed)
end TargetExpr

/-- A target carries its complete expression and structural proof. -/
structure Target where
  expression : TargetExpr
  wellFormed : expression.WellFormed
  deriving DecidableEq

instance : Repr Target where
  reprPrec target precedence := reprPrec target.expression precedence

namespace Target
/-- Structural checking preserves the supplied expression exactly. -/
def validate (expression : TargetExpr) : Option Target :=
  if h : expression.WellFormed then some ⟨expression, h⟩ else none
end Target

theorem operation_wellFormed_parameter_roles {operation : Operation}
    (h : operation.WellFormed) :
    ∀ parameter ∈ operation.parameters, parameter.role ≠ "" := by
  simpa only [List.all_eq_true, decide_eq_true_eq] using h.2.1

theorem operation_wellFormed_unique_roles {operation : Operation}
    (h : operation.WellFormed) :
    (operation.parameters.map Parameter.role).Nodup := h.2.2

theorem action_wellFormed_operation {action : Action} (h : action.WellFormed) :
    action.operation.WellFormed := h.1

theorem action_wellFormed_signature {action : Action} (h : action.WellFormed) :
    action.operands.map Operand.parameter = action.operation.parameters := h.2.1

theorem action_wellFormed_references {action : Action} (h : action.WellFormed) :
    ∀ operand ∈ action.operands, operand.referent.WellFormed := by
  simpa only [List.all_eq_true, decide_eq_true_eq] using h.2.2

theorem action_eq_iff_fields (left right : Action) :
    left = right ↔ left.operation = right.operation ∧ left.operands = right.operands := by
  cases left
  cases right
  simp

theorem opportunity_wellFormed_bounds {opportunity : Opportunity}
    (h : opportunity.WellFormed) :
    opportunity.opensAt < opportunity.closesAt := h.2.2

theorem omit_wellFormed_iff (action : Action) (opportunity : Opportunity) :
    (TargetExpr.omit action opportunity).WellFormed ↔
      action.WellFormed ∧ opportunity.WellFormed := Iff.rfl

theorem perform_ne_omit (left right : Action) (opportunity : Opportunity) :
    TargetExpr.perform left ≠ TargetExpr.omit right opportunity := by
  intro h
  cases h

theorem perform_ne_affect (action : Action) (state : Affect) :
    TargetExpr.perform action ≠ TargetExpr.affect state := by
  intro h
  cases h

theorem omit_ne_affect (action : Action) (opportunity : Opportunity) (state : Affect) :
    TargetExpr.omit action opportunity ≠ TargetExpr.affect state := by
  intro h
  cases h

theorem perform_eq_iff (left right : Action) :
    TargetExpr.perform left = TargetExpr.perform right ↔ left = right := by simp

theorem omit_eq_iff (left right : Action) (lo ro : Opportunity) :
    TargetExpr.omit left lo = TargetExpr.omit right ro ↔
      left = right ∧ lo = ro := by simp

theorem affect_eq_iff (left right : Affect) :
    TargetExpr.affect left = TargetExpr.affect right ↔ left = right := by simp

theorem target_eq_iff_expression_eq (left right : Target) :
    left = right ↔ left.expression = right.expression := by
  constructor
  · intro h
    cases h
    rfl
  · intro h
    cases left with
    | mk le lw =>
      cases right with
      | mk re rw =>
        cases h
        rfl

theorem target_validate_eq_some_iff (expression : TargetExpr) (target : Target) :
    Target.validate expression = some target ↔ target.expression = expression := by
  constructor
  · intro h
    by_cases hw : expression.WellFormed
    · have ht : (⟨expression, hw⟩ : Target) = target := by
        simpa [Target.validate, hw] using h
      cases ht
      rfl
    · simp [Target.validate, hw] at h
  · intro h
    cases target with
    | mk te wf =>
      cases h
      simp [Target.validate, wf]

theorem target_validate_eq_none_iff (expression : TargetExpr) :
    Target.validate expression = none ↔ ¬ expression.WellFormed := by
  by_cases h : expression.WellFormed <;> simp [Target.validate, h]

theorem target_validate_roundTrip (target : Target) :
    Target.validate target.expression = some target :=
  (target_validate_eq_some_iff target.expression target).2 rfl

/-! ## Synthetic target fixtures: no doctrinal conclusions are assigned. -/
namespace TargetFixtures

def debt : EntityRef := ⟨.obligation, ⟨"demo.debt", "D"⟩⟩
def creditor : EntityRef := ⟨.person, ⟨"demo.person", "creditor"⟩⟩
def recipient : EntityRef := ⟨.person, ⟨"demo.person", "recipient"⟩⟩
def signature : Operation :=
  ⟨⟨"demo.action", "repay_debt"⟩,
    [⟨"debt", .obligation⟩, ⟨"creditor", .person⟩, ⟨"recipient", .person⟩]⟩
def baseAction : Action :=
  ⟨signature, [⟨"debt", debt⟩, ⟨"creditor", creditor⟩, ⟨"recipient", recipient⟩]⟩
def promiseAction : Action :=
  { baseAction with operation := { signature with symbol := ⟨"demo.action", "promise_repayment"⟩ } }
def opportunity : Opportunity :=
  ⟨⟨"demo.occasion", "installment_one"⟩, ⟨"demo.clock", "ticks"⟩, 100, 200⟩
def concern : Affect := ⟨⟨"demo.affect", "concern"⟩, debt⟩
def base : Target := ⟨.perform baseAction, by decide⟩
def promise : Target := ⟨.perform promiseAction, by decide⟩

/-- Select a fully described synthetic expression; numbers select test cases only. -/
def expression : Nat → Option TargetExpr
  | 0 => some (.perform baseAction)
  | 1 => some (.perform
      ⟨⟨⟨"demo.action", "repay_debt"⟩,
        [⟨"debt", .obligation⟩, ⟨"creditor", .person⟩, ⟨"recipient", .person⟩]⟩,
       [⟨"debt", ⟨.obligation, ⟨"demo.debt", "D"⟩⟩⟩,
        ⟨"creditor", ⟨.person, ⟨"demo.person", "creditor"⟩⟩⟩,
        ⟨"recipient", ⟨.person, ⟨"demo.person", "recipient"⟩⟩⟩]⟩)
  | 2 => some (.perform promiseAction)
  | 3 => some (.perform { baseAction with
      operation := { signature with symbol := ⟨"other.action", "repay_debt"⟩ } })
  | 4 => some (.perform { baseAction with operands :=
      [⟨"debt", { debt with symbol := ⟨"demo.debt", "E"⟩ }⟩,
       ⟨"creditor", creditor⟩, ⟨"recipient", recipient⟩] })
  | 5 => some (.perform { baseAction with operands :=
      [⟨"debt", { debt with symbol := ⟨"other.debt", "D"⟩ }⟩,
       ⟨"creditor", creditor⟩, ⟨"recipient", recipient⟩] })
  | 6 => some (.perform { baseAction with operands :=
      [⟨"debt", debt⟩, ⟨"creditor", recipient⟩, ⟨"recipient", creditor⟩] })
  | 7 => some (.perform
      ⟨{ signature with parameters :=
          [⟨"debt", .obligation⟩, ⟨"creditor", .person⟩, ⟨"payee", .person⟩] },
       [⟨"debt", debt⟩, ⟨"creditor", creditor⟩, ⟨"payee", recipient⟩]⟩)
  | 8 => some (.omit baseAction opportunity)
  | 9 => some (.omit promiseAction opportunity)
  | 10 => some (.omit baseAction
      { opportunity with occurrence := ⟨"demo.occasion", "installment_two"⟩ })
  | 11 => some (.omit baseAction
      { opportunity with clock := ⟨"demo.clock", "other_ticks"⟩ })
  | 12 => some (.omit baseAction { opportunity with opensAt := 101 })
  | 13 => some (.omit baseAction { opportunity with closesAt := 201 })
  | 14 => some (.affect concern)
  | 15 => some (.affect { concern with quality := ⟨"demo.affect", "aversion"⟩ })
  | 16 => some (.affect { concern with
      concerns := { debt with symbol := ⟨"demo.debt", "E"⟩ } })
  | 17 => some (.affect { concern with concerns := { debt with kind := .asset } })
  | 18 => some (.perform
      ⟨{ signature with parameters :=
          [⟨"debt", .asset⟩, ⟨"creditor", .person⟩, ⟨"recipient", .person⟩] },
       [⟨"debt", { debt with kind := .asset }⟩,
        ⟨"creditor", creditor⟩, ⟨"recipient", recipient⟩]⟩)
  | 19 => some (.perform
      ⟨{ signature with parameters := signature.parameters.reverse },
       baseAction.operands.reverse⟩)
  | 20 => some (.perform
      { baseAction with operands := [⟨"debt", debt⟩, ⟨"creditor", creditor⟩] })
  | 21 => some (.perform { baseAction with operands :=
      [⟨"debt", { debt with kind := .person }⟩,
       ⟨"creditor", creditor⟩, ⟨"recipient", recipient⟩] })
  | 22 => some (.perform
      ⟨{ signature with parameters :=
          [⟨"debt", .obligation⟩, ⟨"recipient", .person⟩, ⟨"recipient", .person⟩] },
       [⟨"debt", debt⟩, ⟨"recipient", creditor⟩, ⟨"recipient", recipient⟩]⟩)
  | 23 => some (.perform { baseAction with
      operation := { signature with symbol := ⟨"demo.action", ""⟩ } })
  | 24 => some (.perform { baseAction with operands :=
      [⟨"debt", { debt with symbol := ⟨"demo.debt", ""⟩ }⟩,
       ⟨"creditor", creditor⟩, ⟨"recipient", recipient⟩] })
  | 25 => some (.omit baseAction { opportunity with closesAt := 100 })
  | 26 => some (.omit baseAction { opportunity with opensAt := 200, closesAt := 100 })
  | 27 => some (.perform { baseAction with operands := baseAction.operands.reverse })
  | _ => none

end TargetFixtures

/-- Legacy numbers are opaque and live in a separate equality class. -/
inductive KeyTarget where
  | legacy (id : Nat)
  | structured (target : Target)
  deriving DecidableEq, Repr

/-- All seven coordinates participate in scope equality. -/
structure Key where
  question : Nat
  subject : Nat
  target : KeyTarget
  context : Nat
  time : Nat
  profile : Nat
  version : Nat
  deriving DecidableEq, Repr

namespace Key

def zero : Key := ⟨0, 0, .legacy 0, 0, 0, 0, 0⟩

theorem eq_iff_fields (a b : Key) : a = b ↔
    a.question = b.question ∧ a.subject = b.subject ∧ a.target = b.target ∧
    a.context = b.context ∧ a.time = b.time ∧ a.profile = b.profile ∧
    a.version = b.version := by
  cases a
  cases b
  simp only [Key.mk.injEq]

end Key

/-- Status of one required premise. NoRuling does not assert universal permission. -/
inductive Input where
  | noRuling
  | suspended
  | known (constraint : Constraint)
  deriving DecidableEq

/-- Output statuses are separate from the five ruling values. -/
inductive Result where
  | noRuling
  | suspended
  | known (constraint : Constraint)
  | conflict
  | outOfScope
  deriving DecidableEq

/-- Intersection for two known, in-scope premises. -/
def intersectKnown (left right : Constraint) : Result :=
  if hn : (left.set.inter right.set).Nonempty then
    .known ⟨left.set.inter right.set, hn⟩
  else .conflict

/-- The status priority once scope equality has been established. -/
def combineSame : Input → Input → Result
  | .suspended, _ => .suspended
  | _, .suspended => .suspended
  | .noRuling, _ => .noRuling
  | _, .noRuling => .noRuling
  | .known left, .known right => intersectKnown left right

/-- Conjunction of two required premises, guarded by the complete key. -/
def combine (leftKey rightKey : Key) (left right : Input) : Result :=
  if leftKey = rightKey then combineSame left right else .outOfScope

theorem intersectKnown_not_outOfScope (left right : Constraint) :
    intersectKnown left right ≠ .outOfScope := by
  unfold intersectKnown
  split <;> simp

theorem combineSame_not_outOfScope (left right : Input) :
    combineSame left right ≠ .outOfScope := by
  cases left <;> cases right <;> simp [combineSame, intersectKnown_not_outOfScope]

theorem outOfScope_iff (lk rk : Key) (left right : Input) :
    combine lk rk left right = .outOfScope ↔ lk ≠ rk := by
  by_cases hk : lk = rk
  · simp [combine, hk, combineSame_not_outOfScope]
  · simp [combine, hk]

/-- Exact guard: every coordinate must match, even for missing/suspended input. -/
theorem inScope_iff_all_fields (lk rk : Key) (left right : Input) :
    combine lk rk left right ≠ .outOfScope ↔
      lk.question = rk.question ∧ lk.subject = rk.subject ∧ lk.target = rk.target ∧
      lk.context = rk.context ∧ lk.time = rk.time ∧ lk.profile = rk.profile ∧
      lk.version = rk.version := by
  rw [← Key.eq_iff_fields]
  by_cases hk : lk = rk
  · simp [combine, hk, combineSame_not_outOfScope]
  · simp [combine, hk]

theorem combine_same_key (k : Key) (left right : Input) :
    combine k k left right = combineSame left right := by simp [combine]

theorem known_intersection_exact {left right result : Constraint}
    (h : intersectKnown left right = .known result) :
    result.set = left.set.inter right.set := by
  unfold intersectKnown at h
  split at h
  · cases h
    rfl
  · contradiction

theorem known_result_exact {lk rk : Key} {left right result : Constraint}
    (h : combine lk rk (.known left) (.known right) = .known result) :
    lk = rk ∧ result.set = left.set.inter right.set := by
  unfold combine at h
  split at h
  · rename_i hk
    exact ⟨hk, known_intersection_exact h⟩
  · contradiction

theorem known_result_subset_both {lk rk : Key} {left right result : Constraint}
    (h : combine lk rk (.known left) (.known right) = .known result) :
    result.set.Subset left.set ∧ result.set.Subset right.set := by
  have he := (known_result_exact h).2
  rw [he]
  exact ⟨HukmSet.inter_subset_left _ _, HukmSet.inter_subset_right _ _⟩

theorem known_result_nonempty {lk rk : Key} {left right : Input} {result : Constraint}
    (_h : combine lk rk left right = .known result) : result.set.Nonempty :=
  result.nonempty

/-- A Known output requires two Known inputs as well as equal complete keys. -/
theorem known_requires_two_known {lk rk : Key} {left right : Input} {result : Constraint}
    (h : combine lk rk left right = .known result) :
    lk = rk ∧ ∃ l r, left = .known l ∧ right = .known r ∧
      result.set = l.set.inter r.set := by
  unfold combine at h
  split at h
  · rename_i hk
    cases left <;> cases right <;> simp [combineSame] at h
    exact ⟨hk, _, _, rfl, rfl, known_intersection_exact h⟩
  · contradiction

theorem missing_left_not_known (lk rk : Key) (right : Input) (result : Constraint) :
    combine lk rk .noRuling right ≠ .known result := by
  by_cases hk : lk = rk <;> cases right <;> simp [combine, combineSame, hk]

theorem missing_right_not_known (lk rk : Key) (left : Input) (result : Constraint) :
    combine lk rk left .noRuling ≠ .known result := by
  by_cases hk : lk = rk <;> cases left <;> simp [combine, combineSame, hk]

theorem missing_left_same_key (k : Key) (right : Input) (h : right ≠ .suspended) :
    combine k k .noRuling right = .noRuling := by
  cases right <;> simp_all [combine, combineSame]

theorem missing_right_same_key (k : Key) (left : Input) (h : left ≠ .suspended) :
    combine k k left .noRuling = .noRuling := by
  cases left <;> simp_all [combine, combineSame]

theorem suspended_left_preserved (k : Key) (right : Input) :
    combine k k .suspended right = .suspended := by simp [combine, combineSame]

theorem suspended_right_preserved (k : Key) (left : Input) :
    combine k k left .suspended = .suspended := by
  cases left <;> simp [combine, combineSame]

theorem conflict_iff_empty (k : Key) (left right : Constraint) :
    combine k k (.known left) (.known right) = .conflict ↔
      ¬ (left.set.inter right.set).Nonempty := by
  simp [combine, combineSame, intersectKnown]

theorem conflict_iff_no_common_ruling (k : Key) (left right : Constraint) :
    combine k k (.known left) (.known right) = .conflict ↔
      ¬ ∃ h, left.set.mem h = true ∧ right.set.mem h = true := by
  rw [conflict_iff_empty, HukmSet.nonempty_iff_exists]
  simp only [HukmSet.mem_inter, Bool.and_eq_true]

theorem unknown_ne_all : Input.noRuling ≠ .known Constraint.all := by decide
theorem unknown_ne_mubah : Input.noRuling ≠ .known (Constraint.singleton .mubah) := by decide
theorem all_ne_mubah : Constraint.all ≠ Constraint.singleton .mubah := by decide

/-! ## Checked serialization (wire tags only) -/

def encodeHukm : Hukm → Nat
  | .haram => 0 | .makruh => 1 | .mubah => 2 | .mandub => 3 | .wajib => 4

def decodeHukm : Nat → Option Hukm
  | 0 => some .haram | 1 => some .makruh | 2 => some .mubah
  | 3 => some .mandub | 4 => some .wajib | _ => none

theorem hukm_roundtrip (h : Hukm) : decodeHukm (encodeHukm h) = some h := by
  cases h <;> rfl

/-- Bit positions follow H,K,M,N,W. A mask is a set, not a ruling score. -/
def encodeSet (s : HukmSet) : Nat :=
  (if s.haram then 1 else 0) + (if s.makruh then 2 else 0) +
  (if s.mubah then 4 else 0) + (if s.mandub then 8 else 0) +
  (if s.wajib then 16 else 0)

def decodeSet (mask : Nat) : HukmSet :=
  ⟨mask.testBit 0, mask.testBit 1, mask.testBit 2, mask.testBit 3, mask.testBit 4⟩

/-- Only 1..31 can construct a Known constraint. -/
def decodeConstraint (mask : Nat) : Option Constraint :=
  if 1 ≤ mask ∧ mask ≤ 31 then
    if hn : (decodeSet mask).Nonempty then some ⟨decodeSet mask, hn⟩ else none
  else none

def decodeInput (code : Nat) : Option Input :=
  if code = 0 then some .noRuling
  else if code = 32 then some .suspended
  else (decodeConstraint code).map Input.known

def encodeResult : Result → Nat
  | .noRuling => 0
  | .suspended => 32
  | .known s => encodeSet s.set
  | .conflict => 33
  | .outOfScope => 34

/-- The finite exported family; combine accepts arbitrary targets and other coordinates. -/
def keyVariant : Nat → Option Key
  | 0 => some Key.zero
  | 1 => some { Key.zero with question := 1 }
  | 2 => some { Key.zero with subject := 1 }
  | 3 => some { Key.zero with target := .legacy 1 }
  | 4 => some { Key.zero with context := 1 }
  | 5 => some { Key.zero with time := 1 }
  | 6 => some { Key.zero with profile := 1 }
  | 7 => some { Key.zero with version := 1 }
  | _ => none

def meetCode (a b : Nat) : Option Nat := do
  let a ← decodeHukm a
  let b ← decodeHukm b
  pure (encodeHukm (meet a b))

def joinCode (a b : Nat) : Option Nat := do
  let a ← decodeHukm a
  let b ← decodeHukm b
  pure (encodeHukm (join a b))

def sigmaCode (a : Nat) : Option Nat := do
  let a ← decodeHukm a
  pure (encodeHukm (sigma a))

def refineCode (key left right : Nat) : Option Nat := do
  let rightKey ← keyVariant key
  let left ← decodeInput left
  let right ← decodeInput right
  pure (encodeResult (combine Key.zero rightKey left right))

theorem decodeHukm_rejects (n : Nat) (hn : 5 ≤ n) : decodeHukm n = none := by
  cases n with
  | zero => contradiction
  | succ n =>
    cases n with
    | zero => contradiction
    | succ n =>
      cases n with
      | zero => contradiction
      | succ n =>
        cases n with
        | zero => contradiction
        | succ n =>
          cases n with
          | zero => contradiction
          | succ n => rfl

theorem decodeInput_rejects (n : Nat) (hn : 32 < n) : decodeInput n = none := by
  have h0 : n ≠ 0 := by omega
  have h32 : n ≠ 32 := by omega
  have h31 : ¬ (1 ≤ n ∧ n ≤ 31) := by omega
  simp [decodeInput, h0, h32, decodeConstraint, h31]

theorem decodeConstraint_rejects_zero : decodeConstraint 0 = none := by decide

/-- A target mismatch alone suffices to reject conjunction. -/
theorem target_mismatch_outOfScope (lk rk : Key) (left right : Input)
    (h : lk.target ≠ rk.target) :
    combine lk rk left right = .outOfScope := by
  apply (outOfScope_iff lk rk left right).2
  intro hk
  exact h (congrArg (fun key : Key => key.target) hk)

/-- The legacy embedding preserves the original numeric scope comparison. -/
theorem legacy_scope_preserved (lk rk : Key) (l r : Nat) (left right : Input) :
    combine { lk with target := .legacy l } { rk with target := .legacy r } left right
      ≠ .outOfScope ↔
      lk.question = rk.question ∧ lk.subject = rk.subject ∧ l = r ∧
      lk.context = rk.context ∧ lk.time = rk.time ∧ lk.profile = rk.profile ∧
      lk.version = rk.version := by
  simp only [inScope_iff_all_fields, KeyTarget.legacy.injEq]

theorem legacy_structured_outOfScope (lk rk : Key) (id : Nat) (target : Target)
    (left right : Input) :
    combine { lk with target := .legacy id } { rk with target := .structured target }
      left right = .outOfScope := by
  simp [outOfScope_iff, Key.eq_iff_fields]

/-- A known output preserves the entire target expression on both sides. -/
theorem known_result_same_target {lk rk : Key} {left right result : Constraint}
    (h : combine lk rk (.known left) (.known right) = .known result) :
    lk.target = rk.target :=
  congrArg (fun key : Key => key.target) (known_result_exact h).1

/-- Admission bit for one explicit synthetic target; no source admission is implied. -/
def targetAdmitCode (code : Nat) : Option Nat := do
  let expression ← TargetFixtures.expression code
  pure (if (Target.validate expression).isSome then 1 else 0)

/-- Six representative premise pairs; the original table still covers all 33 by 33. -/
def targetPremiseCase : Nat → Option (Input × Input)
  | 0 => some (.known Constraint.all, .known (Constraint.singleton .wajib))
  | 1 => some (.known (Constraint.singleton .haram), .known (Constraint.singleton .wajib))
  | 2 => some (.noRuling, .known Constraint.all)
  | 3 => some (.suspended, .known (Constraint.singleton .mubah))
  | 4 => some (.suspended, .noRuling)
  | 5 => some (.known (Constraint.singleton .mubah), .known (Constraint.singleton .mubah))
  | _ => none

/--
Fixture comparison with an explicit structural-rejection tag 35.
This tag belongs to this test boundary, not to Result or the ruling carrier.
-/
def targetRefineCode (leftCode rightCode premiseCode : Nat) : Option Nat := do
  let leftExpression ← TargetFixtures.expression leftCode
  let rightExpression ← TargetFixtures.expression rightCode
  let (left, right) ← targetPremiseCase premiseCode
  match Target.validate leftExpression, Target.validate rightExpression with
  | some leftTarget, some rightTarget =>
      pure (encodeResult (combine
        { Key.zero with target := .structured leftTarget }
        { Key.zero with target := .structured rightTarget } left right))
  | _, _ => pure 35

end Usul.IDA
