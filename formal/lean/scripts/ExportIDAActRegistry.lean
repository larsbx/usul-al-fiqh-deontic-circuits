import UsulTest.IDAActRegistry

/-! Fixed finite comparison surface. The table contains actual Lean evaluator
results, not the expected-result oracle used by the scenario proofs. -/

open UsulTest.IDAActRegistry

def main : IO Unit := do
  let stdout ← IO.getStdout
  stdout.putStrLn "family,x,y,z,code,baseIssue"
  for r in List.range 14 do
    for e in List.range 36 do
      stdout.putStrLn s!"structural,{r},{e},0,{structuralCode r e},0"
  for e in List.range 36 do
    for b in List.range 10 do
      for s in List.range 12 do
        stdout.putStrLn s!"bound,{e},{b},{s},{boundCode e b s},{boundBaseIssue e b s}"
