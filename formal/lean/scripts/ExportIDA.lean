import Usul.IDA

open Usul.IDA

/-- Export only the declared finite audit family; out-of-range codes fail. -/
def emitIDA (sectionName : String) (a b c : Nat) (result : Option Nat) : IO Unit := do
  match result with
  | some value => IO.println s!"{sectionName},{a},{b},{c},{value}"
  | none => throw (IO.userError s!"invalid IDA export input: {sectionName},{a},{b},{c}")

def main : IO Unit := do
  IO.println "section,a,b,c,result"
  for a in List.range 5 do
    for b in List.range 5 do
      emitIDA "meet" a b 0 (meetCode a b)
  for a in List.range 5 do
    for b in List.range 5 do
      emitIDA "join" a b 0 (joinCode a b)
  for a in List.range 5 do
    emitIDA "sigma" a 0 0 (sigmaCode a)
  for k in List.range 8 do
    for left in List.range 33 do
      for right in List.range 33 do
        emitIDA "refine" k left right (refineCode k left right)
  for target in List.range 28 do
    emitIDA "target_admit" target 0 0 (targetAdmitCode target)
  for left in List.range 28 do
    for right in List.range 28 do
      for premise in List.range 6 do
        emitIDA "target_refine" left right premise (targetRefineCode left right premise)
