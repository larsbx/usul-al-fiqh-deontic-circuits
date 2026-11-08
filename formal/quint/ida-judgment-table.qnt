// Complete deterministic export of the declared synthetic domain.
// codec 6*38 = 228; admission 5*4*38 = 760; revalidation 5*8 = 40.
// Total: 1,028 entries. No sampling is used to construct this vector.
module idaJudgmentTable {
  import idaJudgment.codecCode from "./ida-judgment"
  import idaJudgment.admissionCode from "./ida-judgment"
  import idaJudgment.revalidationCode from "./ida-judgment"

  var results: List[int]

  pure def tableValue(index: int): int = {
    if (index < 0 or index >= 1028) Set().getOnlyElement()
    else if (index < 228) codecCode(index / 38, index % 38)
    else if (index < 988) {
      val offset = index - 228
      admissionCode(offset / (4 * 38), (offset / 38) % 4, offset % 38)
    }
    else {
      val offset = index - 988
      revalidationCode(offset / 8, offset % 8)
    }
  }

  action init = results' = range(0, 1028).foldl(List(), (rows, index) => rows.append(tableValue(index)))
  action step = results' = results
}
