import UsulTest.Fixtures.Runner
import UsulTest.Fixtures.Sheaf
import UsulTest.Fixtures.Fatwa
import UsulTest.Fixtures.Typing

/-! Fixed proposition witnesses: changing a theorem statement does not satisfy
the same contract merely by retaining its name. Runtime fixtures are checked
separately so semantic mutants must compile before being tested. -/
namespace UsulTest.Fixtures.Contracts
open Usul.Fixtures

theorem require_negative_premise (name : String) (query : Except String Bool) :
    judge ⟨name, false, query, []⟩ = .error .vacuousNegative :=
  negative_requires_premise name query

theorem require_false_negative (name : String) (actual : Bool) :
    judge (.ofBool name false actual [true]) = .ok () ↔ actual = false :=
  checked_negative_requires_false name actual

theorem require_true_positive (name : String) (actual : Bool) :
    judge (.ofBool name true actual [true]) = .ok () ↔ actual = true :=
  checked_positive_requires_true name actual

theorem require_query_error (name message : String) :
    judge ⟨name, false, .error message, [.ok true]⟩ = .error (.evaluationError message) :=
  query_error_is_not_negative name message

theorem require_premise_error (message : String) (rest : List (Except String Bool)) :
    checkPremises (.error message :: rest) = .error (.evaluationError message) :=
  premise_error_is_failure message rest

theorem require_false_premise (rest : List (Except String Bool)) :
    checkPremises (.ok false :: rest) = .error .premiseFailed :=
  false_premise_is_failure rest

theorem require_polarity_rejection (name : String) (actual : Bool) :
    judge ((Fixture.ofBool name actual actual).flipForControl) = .error .queryMismatch :=
  flipped_answer_fails name actual

theorem require_flip_query (fixture : Fixture) :
    fixture.flipForControl.query = fixture.query := flip_preserves_query fixture

theorem require_flip_polarity (fixture : Fixture) :
    fixture.flipForControl.expected = !fixture.expected := flip_complements_expected fixture

theorem require_empty_rejection : run [] = [⟨"<suite>", .error .noExpectations⟩] :=
  empty_suite_fails

theorem runner_controls_pass : failureCount (run UsulTest.Fixtures.Runner.fixtures) = 0 := by decide

theorem typing_inventory_matches : UsulTest.Fixtures.Typing.inventoryAgrees = true := by decide

theorem typing_keeps_derived_conflicts : UsulTest.Fixtures.Typing.derivedConflictRetained = true := by decide

theorem typing_stated_facts_block_derivation : UsulTest.Fixtures.Typing.statedConflictBlocked = true := by decide

theorem require_typing_preservation (relations : List Typing.Rule) (original : Typing.Facts)
    (old : Typing.Fact) (present : old ∈ original) : old ∈ Typing.close relations original :=
  Typing.close_preserves relations original old present

theorem require_fatwa_priority (decision : Fatwa.Decision) (rest : List (Option Fatwa.Decision)) :
    Fatwa.firstDecision (some decision :: rest) = some decision :=
  Fatwa.firstDecision_head decision rest

theorem require_fatwa_candidate (candidates : List (Option Fatwa.Decision)) (decision : Fatwa.Decision)
    (selected : Fatwa.firstDecision candidates = some decision) : some decision ∈ candidates :=
  Fatwa.firstDecision_member candidates decision selected

end UsulTest.Fixtures.Contracts
