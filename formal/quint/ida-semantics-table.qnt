module idaSemanticsTable {
  import idaSemantics as S from "./ida-semantics"

  var results: List[int]
  action init = results' = {
    val formulas = range(0, 12800).foldl(List(), (out, i) =>
      out.concat(S::formulaCells(i / 800, (i / 200) % 4, (i / 40) % 5, (i / 8) % 5, i % 8)))
    val meanings = range(0, 200).foldl(formulas, (out, i) =>
      out.concat(S::meaningCells(i / 100 == 1, (i / 25) % 4, (i / 5) % 5, i % 5)))
    range(0, 280).foldl(meanings, (out, i) =>
      out.append(S::assessmentCell(i / 56, (i / 8) % 7, i % 8)))
  }
  action step = results' = results
}
