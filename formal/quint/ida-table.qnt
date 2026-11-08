// Canonical deterministic wire table, exported in one zero-step ITF trace.
// Layout: meet 25, join 25, sigma 5, refinement 8 * 33 * 33 = 8712.
// Inputs are ordered key outermost, left next, right innermost.
module idaTable {
  import ida.meetCode from "./ida"
  import ida.joinCode from "./ida"
  import ida.sigmaCode from "./ida"
  import ida.refineCode from "./ida"

  var results: List[int]

  pure def tableValue(index: int): int = {
    if (index < 25) meetCode(index / 5, index % 5)
    else if (index < 50) joinCode((index - 25) / 5, (index - 25) % 5)
    else if (index < 55) sigmaCode(index - 50)
    else {
      val offset = index - 55
      refineCode(offset / (33 * 33), (offset / 33) % 33, offset % 33)
    }
  }

  action init = results' = range(0, 8767).foldl(List(), (rows, index) => rows.append(tableValue(index)))
  action step = results' = results
}
