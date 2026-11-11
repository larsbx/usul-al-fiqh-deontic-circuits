module idaPilotTrace {
  type Report = { person: int, version: int, positive: bool }
  type Certificate = { token: int, scope: int, person: int, version: int, positive: bool }

  pure val alice = 1
  pure val bob = 2
  pure val source = List(
    { token: 1, scope: 1, person: bob, version: 1, positive: true },
    { token: 2, scope: 1, person: alice, version: 2, positive: false })
  pure val destination = List(
    { token: 3, scope: 2, person: alice, version: 1, positive: true },
    { token: 4, scope: 2, person: bob, version: 2, positive: false })

  pure def bit(mask: int, scale: int): bool = (mask / scale) % 2 == 1

  pure def reports(mask: int): Set[Report] = {
    val rows = List(
      { person: alice, version: 1, positive: true },
      { person: alice, version: 1, positive: false },
      { person: bob, version: 2, positive: true },
      { person: bob, version: 2, positive: false })
    val scales = List(1, 2, 4, 8)
    rows.indices().filter(i => bit(mask, scales[i])).map(i => rows[i])
  }

  pure def has(rows: Set[Report], person: int, version: int, positive: bool): bool =
    rows.contains({ person: person, version: version, positive: positive })

  pure def guard(rows: Set[Report]): bool =
    has(rows, alice, 1, true) and not(has(rows, alice, 1, false))
    and has(rows, bob, 2, false) and not(has(rows, bob, 2, true))

  pure def observation(rows: Set[Report]): int =
    if (has(rows, bob, 2, true)) {
      if (has(rows, bob, 2, false)) 7 else 6
    } else if (has(rows, alice, 1, true)) {
      if (has(rows, alice, 1, false)) 5 else 4
    } else if (has(rows, alice, 1, false)) 3 else 1

  pure def population(n: int): Set[int] =
    if (n == 0) Set() else if (n == 1) Set(0) else if (n == 2) Set(1) else 0.to(15)

  pure def truth(mask: int, certificate: Certificate): bool = {
    val scale = if (certificate.version == 1) {
      if (certificate.person == alice) 1 else 2
    } else {
      if (certificate.person == alice) 4 else 8
    }
    bit(mask, scale) == certificate.positive
  }

  pure def assessment(n: int): int = {
    val possible = population(n)
    val compatible = possible.filter(h => truth(h, destination[0]) and truth(h, destination[1]))
    if (possible == Set()) 0
    else if (compatible == Set()) 1
    else if (compatible.forall(h => truth(h, destination[0]) and truth(h, destination[1]))) 2
    else 3
  }

  pure def admission(mode: int): int = {
    val current = if (mode == 4) 3 else 2
    val supplied = if (mode == 1) List()
      else if (mode == 2) List(destination[0].with("person", bob), destination[1])
      else destination
    val supported = if (mode == 3) Set(source[0], source[1])
      else Set(source[0], source[1], destination[0], destination[1])
    val granted = mode != 5
    if (current != 2) 3
    else if (supplied != destination) 1
    else if (not(supplied.indices().forall(i => supported.contains(supplied[i])))) 2
    else if (not(granted)) 4
    else 0
  }

  pure def cells(mask: int, history: int, mode: int): List[int] = {
    val rows = reports(mask)
    val ready = guard(rows)
    val semantics = assessment(history)
    val admitted = admission(mode)
    val result = if (admitted != 0) admitted
      else if (not(ready)) 5
      else if (semantics == 0) 6
      else if (semantics == 1) 7
      else if (semantics == 2) 0
      else 99
    List(if (ready) 1 else 0, observation(rows), semantics, result)
  }

  pure def omission(n: int): int = {
    val expectedOccurrence = 1
    val batchOccurrence = if (n == 3) 2 else 1
    val effective = 12
    val cutoff = 20
    val covered = n != 1
    val reports = if (n == 2) Set({ tick: 11, recorded: 14 }) else Set()
    if (batchOccurrence != expectedOccurrence) 3
    else if (reports.exists(r => 9 <= r.tick and r.tick < 12
      and r.tick <= effective and r.tick <= r.recorded and r.recorded <= cutoff)) 2
    else if (covered) 0
    else 1
  }

  var results: List[int]
  action init = results' = 0.to(15).fold(List(), (masks, m) =>
    0.to(3).fold(masks, (histories, h) =>
      0.to(5).fold(histories, (modes, a) => modes.concat(cells(m, h, a)))))
    .concat(0.to(3).fold(List(), (out, n) => out.append(omission(n))))
  action step = results' = results

  run controlsTest = assert(and {
    cells(9, 2, 0) == List(1, 4, 2, 0),
    1.to(5).forall(mode => cells(9, 2, mode)[3] == List(0, 1, 1, 2, 3, 4)[mode]),
    cells(9, 0, 0)[3] == 6,
    cells(9, 1, 0)[3] == 7,
    cells(1, 2, 0)[3] == 5,
    cells(11, 2, 0)[3] == 5,
    cells(13, 2, 0)[3] == 5,
    guard(reports(9).union(Set({ person: alice, version: 2, positive: true }))),
    0.to(3).forall(n => omission(n) == n),
  })
}
