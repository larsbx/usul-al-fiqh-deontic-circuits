// Independent bounded ACT-02 model. The two variable positions are people.
// The synthetic repayment's third operand is a rigid obligation.
module idaSubstitution {
  type Reference = { sort: str, space: str, name: str }
  type Term = Position(int) | Constant(Reference)
  type Atom = { version: int, term: Term, positive: bool }

  pure val alice: Reference = { sort: "person", space: "person", name: "alice" }
  pure val bob: Reference = { sort: "person", space: "person", name: "bob" }
  pure val otherAlice: Reference = { ...alice, space: "other.person" }
  pure val debt: Reference = { sort: "obligation", space: "synthetic.debt", name: "d1" }
  pure val x: Term = Position(0)
  pure val y: Term = Position(1)
  pure val grounded: List[Term] = List(Constant(alice), Constant(bob))

  pure val raw: List[Term] = List(x, y, Constant(alice), Constant(bob), Constant(debt),
    Position(2), Constant(otherAlice))

  pure def acceptsPerson(t: Term): bool = match t {
    | Position(n) => n >= 0 and n < 2
    | Constant(ref) => ref.sort == "person" and ref.space != "" and ref.name != ""
  }

  pure def reindex(t: Term, replacement: List[Term]): Term = match t {
    | Position(n) => replacement[n]
    | Constant(ref) => Constant(ref)
  }

  pure def sequence(first: List[Term], second: List[Term]): List[Term] =
    first.foldl(List(), (out, term) => out.append(reindex(term, second)))

  pure def atom(t: Term): Atom = { version: 1, term: t, positive: true }
  pure def moveAtom(a: Atom, replacement: List[Term]): Atom =
    a.with("term", reindex(a.term, replacement))

  pure def code(t: Term): int = match t {
    | Position(_) => 0
    | Constant(ref) =>
      if (ref == alice) 1 else if (ref == bob) 2 else if (ref == otherAlice) 3
      else if (ref == debt) 4 else 0
  }

  // Coordinate order retains debtor, creditor, obligation, accountable party,
  // and performer separately. The first cell compares direct and staged paths
  // for those coordinates and both conjuncts.
  pure def syntaxCase(a: int, b: int, c: int, d: int): List[int] = {
    val first = List(raw[a], raw[b])
    val second = List(raw[c], raw[d])
    if (not(Set(a,b,c,d).forall(i => acceptsPerson(raw[i])))) List(0,0,0,0,0,0,0,0)
    else {
      val inquiry = List(x, y, Constant(debt), y, x)
      val directSub = sequence(sequence(first, second), grounded)
      val direct = sequence(inquiry, directSub)
      val staged = sequence(sequence(sequence(inquiry, first), second), grounded)
      val left = atom(x)
      val right = atom(y)
      val directFormula = List(moveAtom(left, directSub), moveAtom(right, directSub))
      val stagedFormula = List(left, right).foldl(List(), (out, a) =>
        out.append(moveAtom(moveAtom(moveAtom(a, first), second), grounded)))
      List(if (direct == staged and directFormula == stagedFormula) 1 else 0)
        .concat(direct.foldl(List(), (out, term) => out.append(code(term))))
        .concat(directFormula.foldl(List(), (out, a) => out.append(code(a.term))))
    }
  }

  // Atomic availability normalizes the finite support formulas. A conjunction
  // and its two premises have the same available atoms for this calculus.
  pure def available(mode: int): Set[Atom] = {
    val a = atom(x)
    val b = atom(y)
    if (mode == 0 or mode == 4) Set(a,b)
    else if (mode == 1) Set(a)
    else if (mode == 2) Set(b)
    else if (mode == 3) Set()
    else if (mode == 5) Set(a,b.with("positive",false))
    else if (mode == 6) Set(a,b.with("version",2))
    else if (mode == 7) Set(a.with("positive",false),a)
    else Set(atom(Constant(alice)), atom(Constant(bob)))
  }

  pure def premiseCase(mode: int, a: int, b: int): int = {
    val proposed = List(raw[a], raw[b])
    if (not(acceptsPerson(raw[a]) and acceptsPerson(raw[b]))) 0
    else {
      val required = Set(moveAtom(atom(x), proposed), moveAtom(atom(y), proposed))
      if (required.subseteq(available(mode))) 2 else 1
    }
  }

  run rigidAndRoleTest = assert(and {
    syntaxCase(0,1,0,1) == List(1,1,2,4,2,1,1,2),
    syntaxCase(1,0,0,1) == List(1,2,1,4,1,2,2,1),
    syntaxCase(6,1,0,1) == List(1,3,2,4,2,3,3,2),
    syntaxCase(4,1,0,1) == List(0,0,0,0,0,0,0,0),
    syntaxCase(0,1,0,5) == List(0,0,0,0,0,0,0,0),
    syntaxCase(1,0,2,1) == List(1,2,1,4,1,2,2,1),
    syntaxCase(1,0,1,0) == List(1,1,2,4,2,1,1,2),
    syntaxCase(0,1,2,2) == List(1,1,1,4,1,1,1,1),
  })

  run premiseTest = assert(and {
    premiseCase(0,1,0) == 2,
    premiseCase(1,0,1) == 1,
    premiseCase(1,0,0) == 2,
    premiseCase(5,0,1) == 1,
    premiseCase(6,0,1) == 1,
    premiseCase(7,0,1) == 1,
    premiseCase(8,2,3) == 2,
  })
}
