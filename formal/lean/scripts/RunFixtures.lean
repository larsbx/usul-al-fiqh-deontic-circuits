import UsulTest.Fixtures.Runner
import UsulTest.Fixtures.Sheaf
import UsulTest.Fixtures.Fatwa
import UsulTest.Fixtures.Typing

open Usul.Fixtures

private def suites : List (String × List Fixture) := [
  ("runner", UsulTest.Fixtures.Runner.fixtures),
  ("sheaf", UsulTest.Fixtures.Sheaf.fixtures),
  ("fatwa", UsulTest.Fixtures.Fatwa.fixtures),
  ("typing", UsulTest.Fixtures.Typing.fixtures)
]

private def boolean (value : Bool) : String := if value then "true" else "false"

private def answer : Except String Bool → String
  | .ok value => boolean value
  | .error message => "error:" ++ reprStr message

def main (args : List String) : IO UInt32 := do
  let (selected, flip) ← match args with
    | [] => pure (suites, false)
    | [name] => pure (suites.filter (fun suite => suite.1 == name), false)
    | [name, "--flipped"] => pure (suites.filter (fun suite => suite.1 == name), true)
    | _ => throw (IO.userError "usage: RunFixtures.lean [runner|sheaf|fatwa|typing [--flipped]]")
  if selected.isEmpty then throw (IO.userError "unknown fixture suite")
  IO.println "suite\tname\texpected\tactual\tpremises\tstatus"
  let mut failures := 0
  for (suite, original) in selected do
    let fixtures := if flip then original.map Fixture.flipForControl else original
    let results := run fixtures
    failures := failures + failureCount results
    for (fixture, result) in fixtures.zip results do
      let status := match result.outcome with
        | .ok () => "pass"
        | .error reason => "fail:" ++ reprStr reason
      IO.println (String.intercalate "\t" [suite, fixture.name, boolean fixture.expected,
        answer fixture.query, String.intercalate "," (fixture.premises.map answer), status])
    if fixtures.isEmpty then
      IO.eprintln s!"{suite}: empty fixture suite"
  return if failures == 0 then 0 else 1
