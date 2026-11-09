// All declared finite observations, in the same coordinate order as the Lean exporter.
module idaContextTable {
  import idaContext as C from "./ida-context"

  pure def cell(i: int): int = {
    if (i < 2800) C::compareCase(i / 100, (i / 10) % 10, i % 10)
    else if (i < 2806) C::phase(C::opportunity, i - 2800 + 8)
    else {
      val offset = i - 2806
      C::agencyCase(offset / 12, (offset / 3) % 4, offset % 3)
    }
  }

  var results: List[int]
  action init = results' = range(0, 2830).foldl(List(), (cells, i) => cells.append(cell(i)))
  action step = results' = results
}
