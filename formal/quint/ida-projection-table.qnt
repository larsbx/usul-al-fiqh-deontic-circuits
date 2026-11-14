module idaProjectionTable {
  import idaProjection as P from "./ida-projection"

  var results: List[int]
  action init = results' = {
    val cases = range(0, 2880).foldl(List(), (out, i) =>
      out.concat(P::caseCells(i / 1440 == 1, (i / 96) % 15, (i / 6) % 16, i % 6)))
    val pairs = range(0, 512).foldl(cases, (out, i) =>
      out.concat(P::pairCells(i / 256 == 1, (i / 16) % 16, i % 16)))
    val relabeled = range(0, 20).foldl(pairs, (out, i) =>
      out.concat(P::relabelCells(i / 10 == 1, P::hukmValues[(i / 2) % 5], i % 2 == 1)))
    val extensions = range(0, 100).foldl(relabeled, (out, i) =>
      out.concat(P::unattestedCells(P::hukmValues[i / 20], P::hukmValues[(i / 4) % 5],
        (i / 2) % 2 == 1, i % 2 == 1)))
    range(0, 25).foldl(extensions, (out, i) =>
      out.concat(P::fivefoldCells(P::hukmValues[i / 5], P::hukmValues[i % 5])))
  }
  action step = results' = results
}
