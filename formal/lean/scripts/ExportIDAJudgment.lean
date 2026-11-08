import Usul.Typing.IDAJudgment

open Usul.IDA.Judgment

/- Abort rather than turn a fixture construction failure into a passing row. -/
def emitIDAJudgment (sectionName : String) (a b c : Nat) (result : Option Nat) : IO Unit := do
  match result with
  | some value => IO.println s!"{sectionName},{a},{b},{c},{value}"
  | none => throw (IO.userError s!"unsupported IDA judgment fixture: {sectionName},{a},{b},{c}")

def main : IO Unit := do
  IO.println "section,a,b,c,result"
  for q in List.range 6 do
    for a in List.range 38 do
      emitIDAJudgment "codec" q a 0 (some (codecCode q a))
  for q in List.range 5 do
    for status in List.range 4 do
      for variant in List.range 38 do
        emitIDAJudgment "admission" q status variant (admissionCode q status variant)
  for q in List.range 5 do
    for update in List.range 8 do
      emitIDAJudgment "revalidation" q update 0 (revalidationCode q update)
