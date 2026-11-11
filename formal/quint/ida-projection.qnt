// ACT-03 independent finite observation model. IDs here encode only the
// synthetic fixture's exact predicate versions, participants, and scope changes.
module idaProjection {
  type Row = { predicate: str, version: int, person: str, positive: bool, mention: int }

  pure val support: str = "qualified"
  pure val guard: str = "guard"
  pure val payer: str = "payer"
  pure val recipient: str = "recipient"

  pure def bit(mask: int, weight: int): bool = (mask / weight) % 2 == 1
  pure def flag(value: bool): int = if (value) 1 else 0

  pure def report(predicate: str, version: int, person: str, positive: bool): Row =
    { predicate: predicate, version: version, person: person, positive: positive, mention: 1 }

  pure val rows: List[Row] = List(report(support, 1, recipient, true),
    report(support, 1, recipient, false), report(guard, 1, payer, true),
    report(guard, 1, payer, false))

  pure def reports(mask: int, noise: int): Set[Row] = {
    val weights = List(1, 2, 4, 8)
    val base = Set(0, 1, 2, 3).filter(i => bit(mask, weights[i])).map(i => rows[i])
    if (noise == 1) base.union(Set(report("unrelated", 1, recipient, true)))
    else if (noise == 2) base.union(Set(report(guard, 2, payer, true)))
    else if (noise == 3) base.union(Set(report(guard, 1, recipient, true)))
    else if (noise == 4) base.union(base.map(q => q.with("mention", 2)))
    else base
  }

  pure def observes(source: Set[Row], predicate: str, person: str, positive: bool): bool =
    source.exists(q => q.predicate == predicate and q.version == 1 and
      q.person == person and q.positive == positive)

  pure def signature(source: Set[Row], shape: int): int = {
    val accountable = if (shape == 6) payer else recipient
    val performer = if (shape == 7 or shape == 13) recipient else payer
    flag(observes(source, support, accountable, true)) +
      2 * flag(observes(source, support, accountable, false)) +
      4 * flag(observes(source, guard, performer, true)) +
      8 * flag(observes(source, guard, performer, false))
  }

  // Independent truth table, indexed by both signs of support and exception.
  pure def outcome(fallbackEnabled: bool, shape: int, observed: int): int = {
    val defaultCase = if (fallbackEnabled) 2 else 1
    val status = List(1,4,3,5,6,6,6,6,defaultCase,4,3,5,7,7,7,7)
    if (shape == 0) status[observed] else 0
  }

  pure def caseCells(fallbackEnabled: bool, shape: int, mask: int, noise: int): List[int] = {
    val found = signature(reports(mask, noise), shape)
    val result = outcome(fallbackEnabled, shape, found)
    val equivalent = shape == 0 and found == signature(reports(mask, 0), 0)
    val coreEqual = shape != 1 and shape != 13
    List(1, result, result, flag(bit(found, 1)), flag(bit(found, 2)),
      flag(bit(found, 4)), flag(bit(found, 8)), flag(equivalent),
      flag(coreEqual), flag(shape != 9))
  }

  pure def pairCells(fallbackEnabled: bool, left: int, right: int): List[int] = {
    val a = signature(reports(left, 0), 0)
    val b = signature(reports(right, 1), 0)
    List(flag(a == b), flag(outcome(fallbackEnabled, 0, a) == outcome(fallbackEnabled, 0, b)), 1, 1)
  }

  run reportDependenciesTest = assert(and {
    caseCells(true, 0, 1, 0) == List(1,4,4,1,0,0,0,1,1,1),
    caseCells(true, 0, 5, 0) == List(1,6,6,1,0,1,0,1,1,1),
    caseCells(true, 0, 1, 2) == caseCells(true, 0, 1, 0),
    caseCells(true, 0, 1, 3) == caseCells(true, 0, 1, 0),
    caseCells(true, 0, 1, 4) == caseCells(true, 0, 1, 0),
    pairCells(true, 1, 5) == List(0,0,1,1),
    pairCells(true, 5, 7) == List(0,1,1,1),
    pairCells(true, 5, 5) == List(1,1,1,1),
  })

  run scopeAndFallbackTest = assert(and {
    caseCells(true, 1, 1, 0) == List(1,0,0,1,0,0,0,0,0,1),
    caseCells(true, 9, 1, 0) == List(1,0,0,1,0,0,0,0,1,0),
    1.to(14).forall(i => caseCells(true, i, 1, 0)[1] == 0),
    caseCells(true, 0, 0, 0)[1] == 1,
    caseCells(true, 0, 8, 0)[1] == 2,
    caseCells(false, 0, 8, 0)[1] == 1,
  })
}
