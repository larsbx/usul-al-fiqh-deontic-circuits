// Canonical finite export. See docs/research/ida-derivation-wire.md.
module idaDerivationTable {
  import idaDerivation as D from "./ida-derivation"
  var results: List[int]
  pure def cells(evaluation: D::Evaluation): List[int] =
    range(0,8).foldl(List(), (values, coordinate) => values.append(D::projection(evaluation, coordinate)))
  pure val sourceRows: List[int] = range(1,3).foldl(List(), (rows, identity) =>
    rows.concat(range(0,68).foldl(List(), (values, coordinate) => values.append(D::sourceCell(identity, coordinate)))))
  pure val leafRows: List[int] = range(0,5).foldl(List(), (rows, q) =>
    rows.concat(range(0,32).foldl(List(), (values, caseId) => values.concat(cells(D::leafOutcome(q, caseId))))))
  pure val taklifiRows: List[int] = range(0,33).foldl(List(), (rows, a) =>
    rows.concat(range(0,33).foldl(List(), (values, b) => values.concat(cells(D::pairOutcome(0, a, b))))))
  pure val typedRows: List[int] = range(1,5).foldl(List(), (rows, q) =>
    rows.concat(range(0,16).foldl(List(), (values, caseId) => values.concat(cells(D::typedOutcome(q, caseId))))))
  pure val scopeRows: List[int] = range(0,13).foldl(List(), (rows, caseId) => rows.concat(cells(D::scopeOutcome(caseId))))
  pure val treeRows: List[int] = range(0,10).foldl(List(), (rows, caseId) =>
    rows.concat(range(0,3).foldl(List(), (values, shape) => values.concat(cells(D::treeOutcome(caseId, shape))))))
  pure val alternativeRows: List[int] = range(0,2).foldl(List(), (rows, scenario) =>
    rows.concat(range(0,2).foldl(List(), (values, identity) => values.concat(cells(D::alternativeOutcomes(scenario).nth(identity))))))
  pure val replayRows: List[int] = range(0,16).foldl(List(), (rows, caseId) => rows.append(if (D::replayCase(caseId)) 1 else 0))
  action init = results' = sourceRows.concat(leafRows).concat(taklifiRows).concat(typedRows).concat(scopeRows).concat(treeRows).concat(alternativeRows).concat(replayRows)
  action step = results' = results
}
