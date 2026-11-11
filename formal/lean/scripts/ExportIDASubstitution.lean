import UsulTest.IDASubstitution

/-! Deterministic observations in the independent Quint table's coordinate order. -/

open UsulTest.IDASubstitution

def main : IO Unit := do
  IO.println "family,a,b,c,d,result"
  for a in [:7] do
    for b in [:7] do
      for c in [:7] do
        for d in [:7] do
          let cells := syntaxCase a b c d
          IO.println s!"syntax,{a},{b},{c},{d},{String.intercalate "," (cells.map toString)}"
  for mode in [:9] do
    for a in [:7] do
      for b in [:7] do
        IO.println s!"premise,{mode},{a},{b},0,{premiseCase mode a b}"
