/-!
# Executable fixture expectations

Queries and premises are total Lean computations. An evaluation error is an
explicit value and never counts as a negative answer. Negative expectations
must establish at least one premise before their answer is checked.

This runner verifies finite model expectations. Passing it does not admit a
source interpretation or establish a ruling outside the declared model.
-/

namespace Usul.Fixtures

deriving instance DecidableEq for Except

structure Fixture where
  name : String
  expected : Bool
  query : Except String Bool
  premises : List (Except String Bool) := []
  deriving Repr

def Fixture.ofBool (name : String) (expected query : Bool)
    (premises : List Bool := []) : Fixture :=
  ⟨name, expected, .ok query, premises.map Except.ok⟩

inductive Failure where
  | noExpectations
  | duplicateName
  | invalidName
  | unknownKind (kind : String)
  | vacuousNegative
  | premiseFailed
  | evaluationError (message : String)
  | queryMismatch
  deriving DecidableEq, Repr, BEq

abbrev Outcome := Except Failure Unit

def decodeKind : String → Except Failure Bool
  | "expect_true" => .ok true
  | "expect_false" => .ok false
  | other => .error (.unknownKind other)

def checkPremises : List (Except String Bool) → Outcome
  | [] => .ok ()
  | .error message :: _ => .error (.evaluationError message)
  | .ok false :: _ => .error .premiseFailed
  | .ok true :: rest => checkPremises rest

def judge (fixture : Fixture) : Outcome := do
  if !fixture.expected && fixture.premises.isEmpty then
    throw .vacuousNegative
  checkPremises fixture.premises
  match fixture.query with
  | .error message => throw (.evaluationError message)
  | .ok actual => if actual == fixture.expected then pure () else throw .queryMismatch

def validName (name : String) : Bool :=
  !name.isEmpty && name.toList.all (fun c => c != '\t' && c != '\n' && c != '\r')

structure Result where
  name : String
  outcome : Outcome
  deriving Repr

def run (fixtures : List Fixture) : List Result :=
  if fixtures.isEmpty then [⟨"<suite>", .error .noExpectations⟩]
  else fixtures.map fun fixture =>
    let outcome :=
      if !validName fixture.name then .error .invalidName
      else if (fixtures.filter (fun other => other.name == fixture.name)).length > 1 then
        .error .duplicateName
      else judge fixture
    ⟨fixture.name, outcome⟩

def isPass : Outcome → Bool
  | .ok () => true
  | .error _ => false

def failureCount (results : List Result) : Nat :=
  (results.filter (fun result => !isPass result.outcome)).length

/-- Add a true premise if needed, so a polarity control fails for its answer,
not merely because the newly negative case lacks a premise. -/
def Fixture.flipForControl (fixture : Fixture) : Fixture :=
  { fixture with
    expected := !fixture.expected
    premises := if fixture.premises.isEmpty then [.ok true] else fixture.premises }

theorem flip_preserves_query (fixture : Fixture) :
    fixture.flipForControl.query = fixture.query := rfl

theorem flip_complements_expected (fixture : Fixture) :
    fixture.flipForControl.expected = !fixture.expected := rfl

theorem negative_requires_premise (name : String) (query : Except String Bool) :
    judge ⟨name, false, query, []⟩ = .error .vacuousNegative := rfl

theorem premise_error_is_failure (message : String) (rest : List (Except String Bool)) :
    checkPremises (.error message :: rest) = .error (.evaluationError message) := rfl

theorem false_premise_is_failure (rest : List (Except String Bool)) :
    checkPremises (.ok false :: rest) = .error .premiseFailed := rfl

theorem checked_negative_requires_false (name : String) (actual : Bool) :
    judge (Fixture.ofBool name false actual [true]) = .ok () ↔ actual = false := by
  cases actual with
  | false => exact ⟨fun _ => rfl, fun _ => rfl⟩
  | true => exact ⟨(fun h => by cases h), (fun h => by cases h)⟩

theorem checked_positive_requires_true (name : String) (actual : Bool) :
    judge (Fixture.ofBool name true actual [true]) = .ok () ↔ actual = true := by
  cases actual with
  | false => exact ⟨(fun h => by cases h), (fun h => by cases h)⟩
  | true => exact ⟨fun _ => rfl, fun _ => rfl⟩

theorem query_error_is_not_negative (name message : String) :
    judge ⟨name, false, .error message, [.ok true]⟩ =
      .error (.evaluationError message) := rfl

theorem flipped_answer_fails (name : String) (actual : Bool) :
    judge ((Fixture.ofBool name actual actual).flipForControl) =
      .error .queryMismatch := by
  cases actual <;> rfl

theorem empty_suite_fails :
    run [] = [⟨"<suite>", .error .noExpectations⟩] := rfl

end Usul.Fixtures
