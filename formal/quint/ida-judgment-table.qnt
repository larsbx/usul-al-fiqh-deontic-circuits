// q, answer, trusted admission status, vcase, with vcase innermost.
// A single ITF state exports the complete 6 * 36 * 4 * 34 result vector.
module idaJudgmentTable {
  import idaJudgment.fixture from "./ida-judgment"
  import idaJudgment.outcome from "./ida-judgment"
  var results: List[int]
  pure def tableValue(index: int): int = {
    val vcase = index % 34
    val status = (index / 34) % 4
    val answer = (index / (34 * 4)) % 36
    val question = index / (34 * 4 * 36)
    outcome(fixture(question, answer, status, vcase))
  }
  action init = results' = range(0, 29376).foldl(List(), (rows, index) => rows.append(tableValue(index)))
  action step = results' = results
}
