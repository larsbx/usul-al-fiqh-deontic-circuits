module idaZakatStructure {
  pure def resolution(version: int, pinned: bool, sorts: List[str]): int =
    if (version != 1) 4
    else if (not(pinned)) 5
    else if (sorts != List("person", "person", "asset")) 8
    else 0

  pure def permute(swap: bool, refs: List[int]): List[int] =
    if (swap) List(refs[1], refs[0], refs[2]) else refs

  pure def substitution(a: bool, b: bool): List[int] = {
    val refs = List(1, 2, 3)
    val direct = permute(a != b, refs)
    val staged = permute(a, permute(b, refs))
    List(if (direct == staged) 1 else 0).concat(direct)
  }

  var results: List[int]
  action init = {
    val roles = List("person", "person", "asset")
    results' = List(resolution(1, true, roles), resolution(2, true, roles),
      resolution(1, false, roles), resolution(1, true, List("person", "person")),
      resolution(1, true, List("person", "person", "person")))
      .concat(substitution(false, false)).concat(substitution(false, true))
      .concat(substitution(true, false)).concat(substitution(true, true))
  }
  action step = results' = results
}
