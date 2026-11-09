import UsulTest.IDAContext

/-! Deterministic finite ACT-01 observations for the independent Quint comparison. -/

open Usul.IDA.Context UsulTest.IDAContext

def main : IO Unit := do
  IO.println "family,x,y,z,result"
  for snapshot in [:28] do
    for catalog in [:10] do
      for premise in [:10] do
        IO.println s!"binding,{snapshot},{catalog},{premise},{compareCase snapshot catalog premise}"
  for tick in [8:14] do
    IO.println s!"phase,{tick},0,0,{phase opportunity tick}"
  for profile in [:2] do
    for history in [:4] do
      for coordinate in [:3] do
        IO.println s!"agency,{profile},{history},{coordinate},{agencyCase profile history coordinate}"
  for profile in [:2] do
    for scenario in [:6] do
      for perspective in [:2] do
        for coordinate in [:3] do
          IO.println s!"review,{profile},{scenario},{perspective * 3 + coordinate},{reviewCase profile scenario perspective coordinate}"
  for scenario in [:11] do
    for cutoff in [8:16] do
      IO.println s!"omission,{scenario},{cutoff},0,{omissionCase scenario cutoff}"
