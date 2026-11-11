module idaAdmission {
  type Inquiry = { question: int, accountable: int, performer: int, target: List[int], context: int }
  type Snapshot = { version: int, policy: int, inquiry: Inquiry }
  type Application = { snapshot: Snapshot, grounding: List[int], premises: List[int], conclusion: List[int] }
  type Certificate = { token: int, sourceId: int, entry: int, registryVersion: int, app: Application, atom: int }
  type Side = { app: Application, certs: List[Certificate] }
  type Authority = {
    contexts: Set[Snapshot], registryVersion: int, sources: Set[int],
    evidence: Set[Certificate], signed: Set[Certificate], grants: Set[Side]
  }

  // Two person slots, a fixed obligation, and one predicate. Substitution swaps
  // the roles and transports the one assumed atom into the repeated conjunction.
  pure def application(destination: bool): Application = {
    val grounding = List(1, 2)
    val debtor = if (destination) grounding[1] else grounding[0]
    val creditor = if (destination) grounding[0] else grounding[1]
    val index = if (destination) 2 else 1
    val inquiry = { question: 1, accountable: creditor, performer: debtor,
      target: List(debtor, creditor, 4), context: index }
    { snapshot: { version: index, policy: index, inquiry: inquiry },
      grounding: grounding, premises: List(debtor), conclusion: List(debtor, debtor) }
  }

  pure def side(destination: bool): Side = {
    val app = application(destination)
    val id = if (destination) 2 else 1
    { app: app, certs: List({ token: id, sourceId: id, entry: id,
      registryVersion: 1, app: app, atom: app.premises[0] }) }
  }

  pure val source = side(false)
  pure val destination = side(true)
  pure val srcCert = source.certs[0]
  pure val dstCert = destination.certs[0]
  pure val authority: Authority = {
    contexts: Set(source.app.snapshot, destination.app.snapshot), registryVersion: 1,
    sources: Set(1, 2), evidence: Set(srcCert, dstCert), signed: Set(srcCert, dstCert),
    grants: Set(source, destination)
  }

  pure def check(a: Authority, s: Side, expected: Application): int = {
    val submitted = s.app.snapshot
    val current = a.contexts.filter(c => c.inquiry.context == submitted.inquiry.context)
    if (s.app != expected.with("snapshot", submitted)) 10
    else if (current != Set(submitted)) 2
    else if (submitted.inquiry != expected.snapshot.inquiry) 6
    else if (submitted.policy != expected.snapshot.policy) 11
    else if (s.certs.foldl(List(), (atoms, c) => atoms.append(c.atom)) != expected.premises) 1
    else if (s.certs.indices().exists(i => s.certs[i].app != s.app)) 99
    else if (s.certs.indices().exists(i => {
      val c = s.certs[i]
      a.signed.filter(other => other.token == c.token) != Set(c)
    })) 4
    else if (s.certs.indices().exists(i => s.certs[i].registryVersion != a.registryVersion)) 9
    else if (s.certs.indices().exists(i => not(a.sources.contains(s.certs[i].sourceId)))) 3
    else if (s.certs.indices().exists(i => not(a.evidence.contains(s.certs[i])))) 7
    else if (not(a.grants.contains(s))) 5
    else 0
  }

  pure def admit(a: Authority, d: Side): int = {
    val from = check(a, source, application(false))
    if (from != 0) from else check(a, d, application(true))
  }

  pure def replay(a: Authority, issued: Authority, d: Side): int =
    if (a != issued) 8 else admit(a, d)

  pure def changedSnapshot(s: Snapshot): Authority =
    authority.with("contexts", Set(source.app.snapshot, s))

  pure def control(n: int): int = {
    val original = destination.app.snapshot
    if (n == 0) admit(authority, destination)
    else if (n == 1) admit(authority, destination.with("certs", List()))
    else if (n == 2) admit(changedSnapshot(original.with("version", 3)), destination)
    else if (n == 3) admit(authority.with("sources", Set(1)), destination)
    else if (n == 4) admit(authority, destination.with("certs", List(dstCert.with("atom", srcCert.atom))))
    else if (n == 5) {
      val reused = dstCert.with("token", srcCert.token)
      val proposed = destination.with("certs", List(reused))
      admit(authority.with("grants", Set(source, proposed))
        .with("evidence", Set(srcCert, reused)), proposed)
    }
    else if (n == 6) admit(authority.with("grants", Set(source)), destination)
    else if (n == 7) {
      val changed = original.with("inquiry", original.inquiry.with("accountable", 2))
      admit(changedSnapshot(changed), destination.with("app", destination.app.with("snapshot", changed)))
    }
    else if (n == 8) admit(authority.with("evidence", Set(srcCert)), destination)
    else if (n == 9) replay(authority.with("grants", Set(source)), authority, destination)
    else if (n == 10) admit(authority.with("registryVersion", 2), destination)
    else if (n == 11) admit(authority, destination.with("app", destination.app.with("grounding", List(2, 1))))
    else {
      val changed = original.with("policy", 1)
      admit(changedSnapshot(changed), destination.with("app", destination.app.with("snapshot", changed)))
    }
  }

  pure def bit(mask: int, scale: int): bool = (mask / scale) % 2 == 1

  // Cross all five independent authority/evidence flags. The history truth
  // assignment is checked separately and never enters admit.
  pure def bounded(mask: int): bool = {
    val a = authority
      .with("sources", if (bit(mask, 1)) Set(1, 2) else Set(1))
      .with("evidence", if (bit(mask, 2)) Set(srcCert, dstCert) else Set(srcCert))
      .with("signed", if (bit(mask, 4)) Set(srcCert, dstCert) else Set(srcCert))
      .with("grants", if (bit(mask, 8)) Set(source, destination) else Set(source))
      .with("registryVersion", if (bit(mask, 16)) 1 else 2)
    (admit(a, destination) == 0) == (mask == 31)
  }

  var results: List[int]
  action init = results' = 0.to(12).fold(List(), (out, n) => out.append(control(n)))
  action step = results' = results

  run controlsTest = assert(0.to(12).forall(n =>
    control(n) == List(0, 1, 2, 3, 1, 4, 5, 6, 7, 8, 9, 10, 11)[n]))

  run boundedAuthorityTest = assert(0.to(31).forall(bounded))

  run independentSemanticsTest = assert(and {
    source.app.snapshot.inquiry.target != destination.app.snapshot.inquiry.target,
    source.app.conclusion != destination.app.conclusion,
    0.to(3).forall(mask => {
      val truth = Set(1, 2).filter(person => bit(mask, person))
      val premise = destination.app.premises[0]
      not(truth.contains(premise)) or
        destination.app.conclusion.indices().forall(i => truth.contains(destination.app.conclusion[i]))
    }),
    replay(authority, authority, destination) == 0,
  })
}
