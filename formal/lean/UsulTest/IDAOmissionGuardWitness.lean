import Usul.Typing.IDAOmission

/-!
# An observation counterexample to erasing omission data

Repository-native supplement to the IDA context-theory paper.
Source baseline: main 98d4052eded4063c9cb928c87120f44aa628f23d.
Source tree: 8c9f7b3fc383ee9295f4588f0abd8a04916c7018.

These are synthetic observations under the implemented evaluator. They do not
prove actual nonperformance, capacity, culpability, or any juristic ruling.
The two opportunity records retain one occurrence and clock but disagree on
the declared closing bound; the theorem does not adjudicate which is correct.
-/

namespace IDAPaper.NativeOmission

open Usul.IDA

def debtor : EntityRef := ⟨.person, ⟨"paper.person", "debtor"⟩⟩
def creditor : EntityRef := ⟨.person, ⟨"paper.person", "creditor"⟩⟩
def obligation : EntityRef := ⟨.obligation, ⟨"paper.debt", "repayment"⟩⟩

def repayment : Action :=
  ⟨⟨⟨"paper.act", "repay"⟩,
      [⟨"debtor", .person⟩, ⟨"creditor", .person⟩, ⟨"obligation", .obligation⟩]⟩,
    [⟨"debtor", debtor⟩, ⟨"creditor", creditor⟩, ⟨"obligation", obligation⟩]⟩

def earlyOpportunity : Opportunity :=
  ⟨⟨"paper.occurrence", "repayment-1"⟩, ⟨"paper.clock", "ticks"⟩, 0, 10⟩

def lateOpportunity : Opportunity :=
  { earlyOpportunity with closesAt := 20 }

theorem repayment_wellFormed : repayment.WellFormed := by decide
theorem earlyOpportunity_wellFormed : earlyOpportunity.WellFormed := by decide
theorem lateOpportunity_wellFormed : lateOpportunity.WellFormed := by decide

def earlyTarget : Target :=
  ⟨.omit repayment earlyOpportunity,
    ⟨repayment_wellFormed, earlyOpportunity_wellFormed⟩⟩

def lateTarget : Target :=
  ⟨.omit repayment lateOpportunity,
    ⟨repayment_wellFormed, lateOpportunity_wellFormed⟩⟩

def earlyScope : Omission.Scope :=
  ⟨repayment, earlyOpportunity, debtor, ⟨"debtor", debtor⟩,
    ⟨⟨"paper.act", "repay"⟩, 1⟩, List.replicate 32 0, 1⟩

def lateScope : Omission.Scope :=
  { earlyScope with opportunity := lateOpportunity }

/-- Exactly the fields retained when the opportunity's two bounds are erased. -/
structure WithoutBounds where
  action : Action
  occurrence : Symbol
  clock : Symbol
  accountable : EntityRef
  performer : Operand
  definition : ActRegistry.KindKey
  definitionDigest : List Nat
  clockVersion : Nat
  deriving DecidableEq

def eraseBounds (scope : Omission.Scope) : WithoutBounds :=
  ⟨scope.action, scope.opportunity.occurrence, scope.opportunity.clock,
    scope.accountable, scope.performer, scope.definition,
    scope.definitionDigest, scope.clockVersion⟩

theorem erased_bounds_equal : eraseBounds earlyScope = eraseBounds lateScope := rfl

theorem early_window_closed : earlyScope.opportunity.closesAt ≤ 15 := by decide
theorem late_window_open : 15 < lateScope.opportunity.closesAt := by decide

theorem early_observation :
    Omission.evaluate earlyScope 15 15 [] none = .coverageMissing := by decide

theorem late_observation :
    Omission.evaluate lateScope 15 15 [] none = .pending := by decide

theorem observations_differ :
    Omission.evaluate earlyScope 15 15 [] none ≠
      Omission.evaluate lateScope 15 15 [] none := by
  rw [early_observation, late_observation]
  decide

/-- No evaluator on this erased representation reproduces all outputs even
when the declared action and opportunity are structurally well formed. -/
theorem no_evaluator_after_erasing_bounds :
    ¬ ∃ evaluateErased : WithoutBounds → Omission.Outcome,
      ∀ s : Omission.Scope, s.action.WellFormed → s.opportunity.WellFormed →
        Omission.evaluate s 15 15 [] none = evaluateErased (eraseBounds s) := by
  rintro ⟨evaluateErased, agrees⟩
  apply observations_differ
  calc
    Omission.evaluate earlyScope 15 15 [] none =
        evaluateErased (eraseBounds earlyScope) :=
          agrees earlyScope repayment_wellFormed earlyOpportunity_wellFormed
    _ = evaluateErased (eraseBounds lateScope) := congrArg evaluateErased erased_bounds_equal
    _ = Omission.evaluate lateScope 15 15 [] none :=
      (agrees lateScope repayment_wellFormed lateOpportunity_wellFormed).symm

def earlyKey : Key := ⟨1, 1, .structured earlyTarget, 1, 15, 1, 1⟩
def lateKey : Key := { earlyKey with target := .structured lateTarget }

theorem other_six_coordinates_equal :
    earlyKey.question = lateKey.question ∧
    earlyKey.subject = lateKey.subject ∧
    earlyKey.context = lateKey.context ∧
    earlyKey.time = lateKey.time ∧
    earlyKey.profile = lateKey.profile ∧
    earlyKey.version = lateKey.version := by
  exact ⟨rfl, rfl, rfl, rfl, rfl, rfl⟩

theorem target_expressions_differ : earlyTarget.expression ≠ lateTarget.expression := by decide

theorem targets_differ : earlyKey.target ≠ lateKey.target := by decide

theorem keys_differ : earlyKey ≠ lateKey := by
  intro equal
  exact targets_differ (congrArg Key.target equal)

/-- The real IDA guard rejects the pair, independently of premise payloads. -/
theorem guarded_combination_rejects (left right : Input) :
    combine earlyKey lateKey left right = .outOfScope :=
  (outOfScope_iff earlyKey lateKey left right).mpr keys_differ

def completeCoverage : Omission.Coverage :=
  ⟨earlyScope, [.direct, .alternate], 10⟩

theorem complete_coverage_well_scoped :
    Omission.Coverage.Complete earlyScope 15 (some completeCoverage) := by decide

theorem covered_observation :
    Omission.evaluate earlyScope 15 15 [] (some completeCoverage) =
      .coveredNoCompletion := by decide

theorem coverage_changes_observation :
    Omission.evaluate earlyScope 15 15 [] none ≠
      Omission.evaluate earlyScope 15 15 [] (some completeCoverage) := by
  rw [early_observation, covered_observation]
  decide

/-- A function of scope, times and reports alone cannot reproduce the evaluator
for every supplied coverage argument, even at this single fixed closed scope. -/
theorem no_evaluator_after_erasing_coverage :
    ¬ ∃ fixed : Omission.Outcome, ∀ coverage : Option Omission.Coverage,
      Omission.evaluate earlyScope 15 15 [] coverage = fixed := by
  rintro ⟨fixed, agrees⟩
  exact coverage_changes_observation ((agrees none).trans (agrees (some completeCoverage)).symm)

end IDAPaper.NativeOmission

#print axioms IDAPaper.NativeOmission.repayment_wellFormed
#print axioms IDAPaper.NativeOmission.earlyOpportunity_wellFormed
#print axioms IDAPaper.NativeOmission.lateOpportunity_wellFormed
#print axioms IDAPaper.NativeOmission.erased_bounds_equal
#print axioms IDAPaper.NativeOmission.early_window_closed
#print axioms IDAPaper.NativeOmission.late_window_open
#print axioms IDAPaper.NativeOmission.early_observation
#print axioms IDAPaper.NativeOmission.late_observation
#print axioms IDAPaper.NativeOmission.observations_differ
#print axioms IDAPaper.NativeOmission.no_evaluator_after_erasing_bounds
#print axioms IDAPaper.NativeOmission.other_six_coordinates_equal
#print axioms IDAPaper.NativeOmission.target_expressions_differ
#print axioms IDAPaper.NativeOmission.targets_differ
#print axioms IDAPaper.NativeOmission.keys_differ
#print axioms IDAPaper.NativeOmission.guarded_combination_rejects
#print axioms IDAPaper.NativeOmission.complete_coverage_well_scoped
#print axioms IDAPaper.NativeOmission.covered_observation
#print axioms IDAPaper.NativeOmission.coverage_changes_observation
#print axioms IDAPaper.NativeOmission.no_evaluator_after_erasing_coverage
