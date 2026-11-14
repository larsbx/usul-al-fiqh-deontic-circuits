module idaProjectionTable {
  import idaProjection as P from "./ida-projection"

  var results: List[int]
  action init = results' = {
    val cases = range(0, 2880).foldl(List(), (out, i) =>
      out.concat(P::caseCells(i / 1440 == 1, (i / 96) % 15, (i / 6) % 16, i % 6)))
    val pairs = range(0, 512).foldl(cases, (out, i) =>
      out.concat(P::pairCells(i / 256 == 1, (i / 16) % 16, i % 16)))
    val relabeled = range(0, 8).foldl(pairs, (out, i) =>
      out.concat(P::relabelCells(i / 4 == 1, (i / 2) % 2 == 1, i % 2 == 1)))
    range(0, 16).foldl(relabeled, (out, i) =>
      out.concat(P::unattestedCells(i / 8 == 1, (i / 4) % 2 == 1,
        (i / 2) % 2 == 1, i % 2 == 1)))
  }
  action step = results' = results
}
