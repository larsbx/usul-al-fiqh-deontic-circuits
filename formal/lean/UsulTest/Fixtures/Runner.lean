import Usul.Fixtures.Runner

namespace UsulTest.Fixtures.Runner
open Usul.Fixtures

private def check (name : String) (actual expected : Outcome) : Fixture :=
  Fixture.ofBool name true (decide (actual = expected))

def fixtures : List Fixture := [
  check "positive_success" (judge (.ofBool "probe" true true)) (.ok ()),
  check "positive_failure" (judge (.ofBool "probe" true false)) (.error .queryMismatch),
  check "negative_success" (judge (.ofBool "probe" false false [true])) (.ok ()),
  check "negative_failure" (judge (.ofBool "probe" false true [true])) (.error .queryMismatch),
  check "undefined_query_fails" (judge ⟨"probe", false, .error "undefined", [.ok true]⟩)
    (.error (.evaluationError "undefined")),
  Fixture.ofBool "unknown_kind_fails" true
    (decide (decodeKind "expect_maybe" = .error (.unknownKind "expect_maybe"))),
  Fixture.ofBool "flipped_polarities_fail" true
    ([true, false].all fun value =>
      decide (judge ((Fixture.ofBool "probe" value value).flipForControl) = .error .queryMismatch)),
  Fixture.ofBool "empty_suite_fails" true (failureCount (run []) == 1),
  Fixture.ofBool "duplicate_names_fail" true
    (failureCount (run [.ofBool "same" true true, .ofBool "same" true true]) == 2),
  check "negative_needs_premise" (judge (.ofBool "probe" false false)) (.error .vacuousNegative),
  check "failed_premise_blocks_negative" (judge (.ofBool "probe" false false [false]))
    (.error .premiseFailed),
  check "failed_premise_blocks_positive" (judge (.ofBool "probe" true true [false]))
    (.error .premiseFailed),
  check "premise_error_fails" (judge ⟨"probe", false, .ok false, [.error "undefined"]⟩)
    (.error (.evaluationError "undefined")),
  check "later_failed_premise_fails" (judge (.ofBool "probe" false false [true, false]))
    (.error .premiseFailed),
  check "later_premise_error_fails" (judge ⟨"probe", false, .ok false, [.ok true, .error "undefined"]⟩)
    (.error (.evaluationError "undefined")),
  Fixture.ofBool "empty_name_fails" true
    (failureCount (run [.ofBool "" true true]) == 1),
  Fixture.ofBool "record_delimiter_name_fails" true
    (failureCount (run [.ofBool "bad\tname" true true]) == 1),
  Fixture.ofBool "failure_count_is_exact" true
    (failureCount [⟨"a", .ok ()⟩, ⟨"b", .error .queryMismatch⟩,
      ⟨"c", .error (.evaluationError "undefined")⟩] == 2)
]

end UsulTest.Fixtures.Runner
