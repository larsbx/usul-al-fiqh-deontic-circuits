// Canonical deterministic export. Original 8767 rows are preserved as a prefix.
// Then 28 structural admission bits and 28 * 28 * 6 target conjunction cases.
module idaTable {
  import ida.meetCode from "./ida"
  import ida.joinCode from "./ida"
  import ida.sigmaCode from "./ida"
  import ida.refineCode from "./ida"
  import ida.targetAdmitCode from "./ida"
  import ida.targetRefineCode from "./ida"

  var results: List[int]

  pure def tableValue(index: int): int = {
    if (index < 25) meetCode(index / 5, index % 5)
    else if (index < 50) joinCode((index - 25) / 5, (index - 25) % 5)
    else if (index < 55) sigmaCode(index - 50)
    else if (index < 8767) {
      val offset = index - 55
      refineCode(offset / (33 * 33), (offset / 33) % 33, offset % 33)
    }
    else if (index < 8795) targetAdmitCode(index - 8767)
    else {
      val offset = index - 8795
      targetRefineCode(offset / (28 * 6), (offset / 6) % 28, offset % 6)
    }
  }

  action init = results' = range(0, 13499).foldl(List(), (rows, index) => rows.append(tableValue(index)))
  action step = results' = results
}
