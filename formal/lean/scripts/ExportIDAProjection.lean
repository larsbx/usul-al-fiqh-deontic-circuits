import UsulTest.IDAProjection

/-! Stable finite observation order for the independent Quint comparison. -/

open UsulTest.IDAProjection

def main : IO Unit := do
  IO.println "family,default,shape,left,right,results"
  for enabled in [:2] do
    for shape in List.finRange 15 do
      for mask in [:16] do
        for noise in [:6] do
          let cells := caseCells (enabled == 1) shape mask noise
          IO.println s!"case,{enabled},{shape.val},{mask},{noise},{String.intercalate "," (cells.map toString)}"
  for enabled in [:2] do
    for left in [:16] do
      for right in [:16] do
        let cells := pairCells (enabled == 1) left right
        IO.println s!"pair,{enabled},0,{left},{right},{String.intercalate "," (cells.map toString)}"
  for enabled in [:2] do
    for feature in [:2] do
      for noise in [:2] do
        let cells := relabelCells (enabled == 1) (feature == 1) (noise == 1)
        IO.println s!"relabel,{enabled},0,{feature},{noise},{String.intercalate "," (cells.map toString)}"
  for knownValue in [:2] do
    for unseenValue in [:2] do
      for feature in [:2] do
        for noise in [:2] do
          let cells := unattestedCells (knownValue == 1) (unseenValue == 1) (feature == 1) (noise == 1)
          IO.println s!"unattested,{knownValue},{unseenValue},{feature},{noise},{String.intercalate "," (cells.map toString)}"
