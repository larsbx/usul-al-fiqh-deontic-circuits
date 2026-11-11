module idaProjectionTable {
  import idaProjection as P from "./ida-projection"

  var results: List[int]
  action init = results' = {
    val cases = range(0, 2880).foldl(List(), (out, i) =>
      out.concat(P::caseCells(i / 1440 == 1, (i / 96) % 15, (i / 6) % 16, i % 6)))
    range(0, 512).foldl(cases, (out, i) =>
      out.concat(P::pairCells(i / 256 == 1, (i / 16) % 16, i % 16)))
  }
  action step = results' = results
}
