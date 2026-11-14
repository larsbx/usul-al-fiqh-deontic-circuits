import UsulTest.IDAProjection

/-! Stable finite observation order for the independent Quint comparison. -/

open UsulTest.IDAProjection
open Usul.IDA

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
    for feature in fivefoldValues do
      for noise in [:2] do
        let cells := relabelCells (enabled == 1) feature (noise == 1)
        IO.println s!"relabel,{enabled},0,{encodeHukm feature},{noise},{String.intercalate "," (cells.map toString)}"
  for knownValue in fivefoldValues do
    for unseenValue in fivefoldValues do
      for feature in [:2] do
        for noise in [:2] do
          let cells := unattestedCells knownValue unseenValue (feature == 1) (noise == 1)
          IO.println s!"unattested,{encodeHukm knownValue},{encodeHukm unseenValue},{feature},{noise},{String.intercalate "," (cells.map toString)}"
  for h in fivefoldValues do
    for k in fivefoldValues do
      let cells := fivefoldCells h k
      IO.println s!"fivefold,{encodeHukm h},{encodeHukm k},0,0,{String.intercalate "," (cells.map toString)}"
