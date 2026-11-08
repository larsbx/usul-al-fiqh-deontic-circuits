import UsulTest.IDAJudgment

open UsulTest.IDAJudgment

/-- Export the complete declared family, with variants varying fastest. -/
def main : IO Unit := do
  IO.println "question,answer,admission,variant,result"
  for question in List.range 6 do
    for answer in List.range 36 do
      for admission in List.range 4 do
        for variant in List.range 34 do
          IO.println s!"{question},{answer},{admission},{variant},{fixtureCode question answer admission variant}"
