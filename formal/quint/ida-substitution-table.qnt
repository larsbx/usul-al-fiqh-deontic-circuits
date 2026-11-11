// 2,401 substitutions with eight cells each, then 441 premise-arrow checks.
module idaSubstitutionTable {
  import idaSubstitution as S from "./ida-substitution"

  var results: List[int]
  action init = results' = {
    val syntax = range(0, 2401).foldl(List(), (cells, row) =>
      cells.concat(S::syntaxCase(row / 343, (row / 49) % 7, (row / 7) % 7, row % 7)))
    range(0, 441).foldl(syntax, (cells, row) =>
      cells.append(S::premiseCase(row / 49, (row / 7) % 7, row % 7)))
  }
  action step = results' = results
}
