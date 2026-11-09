// Exhaustive declared finite product, in the shared CSV row order:
// 504 structural rows (registry, envelope), then 4320 bound rows
// (envelope, trusted-binding configuration, source-environment configuration).
// Two cells per row: result code and base derivation issue (zero unless code15).
// This file computes every result from the independently written Quint relation.
module idaActRegistryTable {
  import idaActRegistry as R from "./ida-act-registry"

  pure val structuralRows: int = 14 * 36
  pure val boundRows: int = 36 * 10 * 12
  pure val rowCount: int = structuralRows + boundRows
  pure val cellCount: int = rowCount * 2

  pure def tableValue(cell: int): int = {
    if (cell < 0 or cell >= cellCount) -1
    else {
      val row = cell / 2
      val coordinate = cell % 2
      if (row < structuralRows) {
        if (coordinate == 0) R::structuralCaseCode(row / 36, row % 36) else 0
      }
      else {
        val offset = row - structuralRows
        val envelope = offset / (10 * 12)
        val binding = (offset / 12) % 10
        val source = offset % 12
        if (coordinate == 0) R::boundCaseCode(envelope, binding, source)
        else R::boundCaseIssue(envelope, binding, source)
      }
    }
  }

  var results: List[int]
  action init = results' = range(0, cellCount).foldl(List(), (cells, cell) => cells.append(tableValue(cell)))
  action step = results' = results
}
