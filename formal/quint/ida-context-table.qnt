// All declared finite observations, in the same coordinate order as the Lean exporter.
module idaContextTable {
  import idaContext as C from "./ida-context"
  import idaOmission as O from "./ida-omission"

  pure def cell(i: int): int = {
    if (i < 2800) C::compareCase(i / 100, (i / 10) % 10, i % 10)
    else if (i < 2806) C::phase(C::opportunity, i - 2800 + 8)
    else if (i < 2830) {
      val offset = i - 2806
      C::agencyCase(offset / 12, (offset / 3) % 4, offset % 3)
    } else if (i < 2902) {
      val offset = i - 2830
      C::reviewCase(offset / 36, (offset / 6) % 6, (offset / 3) % 2, offset % 3)
    } else {
      val offset = i - 2902
      O::omissionCase(offset / 168, (offset / 12) % 14, offset % 12)
    }
  }

  var results: List[int]
  action init = results' = range(0, 5926).foldl(List(), (cells, i) => cells.append(cell(i)))
  action step = results' = results
}
