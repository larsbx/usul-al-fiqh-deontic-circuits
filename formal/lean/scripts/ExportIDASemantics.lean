import UsulTest.IDASemantics

/-! Stable finite observation order for the independent Quint interpretation. -/

open UsulTest.IDASemantics

def main : IO Unit := do
  IO.println "family,x,y,z,w,v,results"
  for mask in [:16] do
    for assignment in [:4] do
      for a in [:5] do
        for b in [:5] do
          for which in [:8] do
            let cells := formulaCells mask assignment a b which
            IO.println s!"formula,{mask},{assignment},{a},{b},{which},{String.intercalate "," (cells.map toString)}"
  for revised in [:2] do
    for assignment in [:4] do
      for a in [:5] do
        for b in [:5] do
          let cells := meaningCells (revised == 1) assignment a b
          IO.println s!"meaning,{revised},{assignment},{a},{b},0,{String.intercalate "," (cells.map toString)}"
  for domain in [:5] do
    for selection in [:7] do
      for which in [:8] do
        IO.println s!"assessment,{domain},{selection},{which},0,0,{assessmentCell domain selection which}"
