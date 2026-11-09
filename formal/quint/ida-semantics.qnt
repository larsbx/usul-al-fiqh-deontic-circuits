// Independent finite interpretation of the ACT-04 fixture. A history is
// a complete truth table for two versioned predicates and two people.
// Reports never enter this model as truth values.
module idaSemantics {
  type Atom = { version: int, term: int, positive: bool }

  pure def bit(mask: int, weight: int): bool = (mask / weight) % 2 == 1
  pure def flag(value: bool): int = if (value) 1 else 0

  // References 1 and 2 are Alice and Bob. Reference 3 is another Alice
  // in a different namespace. Reference 4 is the rigid debt.
  pure def assignment(index: int): List[int] =
    List(if (bit(index, 1)) 2 else 1, if (bit(index, 2)) 1 else 2)

  pure def ref(term: int, values: List[int]): int =
    if (term < 2) values[term] else term - 1

  pure def pull(a: int, b: int, values: List[int]): List[int] =
    List(ref(a, values), ref(b, values))

  pure def atom(version: int, term: int, positive: bool): Atom =
    { version: version, term: term, positive: positive }

  pure def formula(which: int): List[Atom] = {
    val x = atom(1, 0, true)
    val y = atom(1, 1, true)
    val negX = x.with("positive", false)
    if (which == 0) List(x)
    else if (which == 1) List(negX)
    else if (which == 2) List(y)
    else if (which == 3) List(x.with("version", 2))
    else if (which == 4) List(x, y)
    else if (which == 5) List(x, negX)
    else if (which == 6) List(atom(2, 1, false))
    else List(atom(1, 4, true))
  }

  pure def rename(f: List[Atom], a: int, b: int): List[Atom] =
    f.foldl(List(), (out, q) => {
      val replacement = if (q.term == 0) a else if (q.term == 1) b else q.term
      out.append(q.with("term", replacement))
    })

  pure def truth(mask: int, version: int, person: int): bool = {
    val scale = if (version == 2) 4 else 1
    if (person == 1) bit(mask, scale)
    else if (person == 2) bit(mask, 2 * scale)
    else false
  }

  pure def satisfied(mask: int, values: List[int], f: List[Atom]): bool =
    f.foldl(true, (soFar, q) => soFar and
      (truth(mask, q.version, ref(q.term, values)) == q.positive))

  pure def formulaCells(mask: int, index: int, a: int, b: int, which: int): List[int] = {
    val values = assignment(index)
    val f = formula(which)
    List(flag(satisfied(mask, values, rename(f, a, b))),
      flag(satisfied(mask, pull(a, b, values), f)))
  }

  pure def meaning(revised: bool, roles: List[int]): List[int] =
    if (revised) List(0, 0, 0) else List(roles[0], roles[1], 4)

  pure def meaningCells(revised: bool, index: int, a: int, b: int): List[int] = {
    val values = assignment(index)
    val direct = List(ref(a, values), ref(b, values))
    val pulled = pull(a, b, values)
    meaning(revised, direct).concat(meaning(revised, pulled))
      .concat(List(direct[1], direct[0], flag(direct == pulled)))
  }

  pure def premises(selection: int): Set[int] =
    if (selection == 0) Set()
    else if (selection == 1) Set(0)
    else if (selection == 2) Set(1)
    else if (selection == 3) Set(0, 1)
    else if (selection == 4) Set(4)
    else if (selection == 5) Set(3)
    else Set(2, 1)

  pure def population(domain: int): Set[int] =
    if (domain == 0) Set()
    else if (domain == 1) Set(0)
    else if (domain == 2) Set(1)
    else if (domain == 3) Set(0, 1, 2, 3)
    else 0.to(15)

  pure def assessmentCell(domain: int, selection: int, which: int): int = {
    val candidates = population(domain)
    val compatibleWorlds = candidates.filter(mask =>
      premises(selection).forall(p => satisfied(mask, assignment(0), formula(p))))
    if (candidates.size() == 0) 0
    else if (compatibleWorlds.size() == 0) 1
    else if (compatibleWorlds.forall(mask => satisfied(mask, assignment(0), formula(which)))) 2
    else 3
  }

  run substitutionAndVersionTest = assert(and {
    meaningCells(false, 0, 1, 0) == List(2,1,4,2,1,4,1,2,1),
    meaningCells(true, 0, 1, 0) == List(0,0,0,0,0,0,1,2,1),
    formulaCells(4, 0, 0, 1, 0) == List(0,0),
    formulaCells(4, 0, 0, 1, 3) == List(1,1),
    formulaCells(1, 0, 4, 1, 0) == List(0,0),
    formulaCells(2, 0, 1, 0, 0) == List(1,1),
    formulaCells(0, 0, 0, 1, 1) == List(1,1),
    formulaCells(1, 0, 0, 1, 1) == List(0,0),
  })

  run finiteNonvacuityTest = assert(and {
    assessmentCell(0, 0, 0) == 0,
    assessmentCell(4, 3, 0) == 1,
    assessmentCell(4, 1, 0) == 2,
    assessmentCell(4, 0, 0) == 3,
  })
}
