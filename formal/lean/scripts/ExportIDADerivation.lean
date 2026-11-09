import UsulTest.IDADerivation

/-! Deterministic export for independent Quint replay; no oracle imports. -/

open Usul.IDA.Derivation UsulTest.IDADerivation

private def emitCell (out : IO.FS.Stream) (group : String) (a b c result : Nat) : IO Unit :=
  out.putStrLn s!"{group},{a},{b},{c},{result}"

private def emitEvaluation (out : IO.FS.Stream) (group : String)
    (a b : Nat) (e : Evaluation) : IO Unit := do
  for c in List.range 8 do
    emitCell out group a b c (projection e c)

def main : IO Unit := do
  let out ← IO.getStdout
  out.putStrLn "section,a,b,c,result"
  for i in [1, 2] do
    let cells := sourceCells i
    for cell in List.range 68 do
      emitCell out "source" i cell 0 (cells[cell]!)
  for q in List.range 5 do
    for variant in List.range 32 do
      emitEvaluation out "leaf" q variant (leafEval q variant)
  for a in List.range 33 do
    for b in List.range 33 do
      emitEvaluation out "taklifi" a b (pairEval 0 a b)
  for q in [1, 2, 3, 4] do
    for pair in List.range 16 do
      emitEvaluation out "typed" q pair (pairEval q (B q (pair / 4)) (B q (pair % 4)))
  for variant in List.range 13 do
    emitEvaluation out "scope" variant 0 (scopeEval variant)
  for variant in List.range 10 do
    for shape in List.range 3 do
      emitEvaluation out "tree" variant shape (treeEval variant shape)
  for scenario in List.range 2 do
    for index in List.range 2 do
      emitEvaluation out "alternatives" scenario index (alternativeEval scenario index)
  for variant in List.range 16 do
    emitCell out "replay" variant 0 0 (replayValue variant)
  for variant in List.range 13 do
    emitEvaluation out "target" variant 0 (targetEval variant)
  for variant in List.range 3 do
    emitCell out "target-replay" variant 0 0 (if targetReplay variant then 1 else 0)
