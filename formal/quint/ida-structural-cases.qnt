// ACT-08: independently evaluated bounded structural examples.
// All inputs are synthetic fixture data. Report observations are not truth
// assignments, source authentication, legal rulings, or a general migration API.
module idaStructuralCases {
  type Symbol = { space: str, name: str }
  type Kind = { symbol: Symbol, version: int }
  type RefSort = PersonSort | AssetSort | ObligationSort | OccurrenceSort | PropositionSort
  type RoleSort = OpenSort | KnownSort(RefSort)
  type Role = { name: str, sort: RoleSort }
  type Parameter = { name: str, sort: RefSort }
  type Definition = { kind: Kind, digest: List[int], roles: List[Role] }
  type Ref = { sort: RefSort, symbol: Symbol }
  type Operand = { name: str, referent: Ref }
  type Act = { operation: Symbol, parameters: List[Parameter], operands: List[Operand] }
  type Declaration = { kind: Kind, digest: List[int], act: Act }
  type Signature = UnresolvedSignature | ResolvedSignature(List[Parameter])
  type Opportunity = { occurrence: Symbol, clock: Symbol, opensAt: int, closesAt: int }
  type Omission = { act: Act, opportunity: Opportunity }
  type Report = { predicate: Kind, arguments: List[Ref], positive: bool, mention: Symbol }
  // This finite carrier names every coordinate varied by the fixture. Constant
  // vocabulary and question constructors are represented by their fixed pins.
  type Scope = {
    target: Omission, kind: Kind, digest: List[int], registryVersion: int,
    question: int, subject: int, accountable: Ref, performer: Operand,
    contextId: int, timeId: int, profile: int, profileVersion: int,
    interpretationId: int, interpretationVersion: int, vocabularyVersion: int,
    policy: Kind, clockVersion: int, effectiveAt: int, recordedAt: int,
    cutoff: int, retrospective: bool
  }
  type Snapshot = { key: Kind, scope: Scope, evidenceRevision: int, reports: List[Report] }
  type Dependencies = { scope: Scope, support: Set[bool], exception: Set[bool] }
  type Atom = { predicate: Kind, person: Ref, positive: bool }
  // Only atoms and their repeated binary conjunction occur in this fixture.
  type Formula = AtomFormula(Atom) | DoubleFormula(Atom)
  type Application = {
    snapshot: Snapshot, grounding: List[Ref], premises: List[Formula], conclusion: Formula
  }
  type PremiseScope = {
    question: int, subject: int, target: Omission, contextId: int, timeId: int,
    profile: int, profileVersion: int, interpretationId: int, interpretationVersion: int
  }
  type Premise = { entryId: int, sourceId: int, registryVersion: int, scope: PremiseScope }
  type Certificate = { token: int, application: Application, formula: Formula, premise: Premise }
  type Side = { application: Application, certificates: List[Certificate] }
  type Environment = {
    registryVersion: int, entries: List[Premise], authenticatedSources: Set[int],
    evidence: List[Premise]
  }
  type Authority = {
    contexts: List[Snapshot], authenticated: List[Certificate],
    grants: List[Side], environment: Environment
  }
  type Trial = { authority: Authority, submitted: Side }

  pure def flag(b: bool): int = if (b) 1 else 0
  pure def bit(mask: int, weight: int): bool = (mask / weight) % 2 == 1
  pure def digest(byte: int): List[int] =
    range(0, 32).foldl(List(), (out, ignored) => out.append(byte))
  pure def named(space: str, name: str): Symbol = { space: space, name: name }
  pure def kind(space: str, name: str): Kind = { symbol: named(space, name), version: 1 }

  pure def roleSignature(roles: List[Role]): Signature =
    roles.foldl(ResolvedSignature(List()), (prior, role) => match prior {
      | UnresolvedSignature => UnresolvedSignature
      | ResolvedSignature(parameters) => match role.sort {
        // MUTATION_UNRESOLVED_ROLE: no obligation default for an open role.
        | OpenSort => UnresolvedSignature
        | KnownSort(sort) => ResolvedSignature(parameters.append({ name: role.name, sort: sort }))
      }
    })

  // Digest equality is a supplied pin, never a hash-injectivity assumption.
  pure def registryCode(definitions: List[Definition], requested: Declaration): int = {
    val kindKeys = definitions.foldl(Set(), (seen, d) => seen.union(Set(d.kind)))
    val found = definitions.select(d => d.kind == requested.kind)
    if (kindKeys.size() != definitions.length()) 1
    else if (found.length() == 0) 4
    else {
      val definition = found.head()
      if (definition.digest != requested.digest) 5
      else match roleSignature(definition.roles) {
        | UnresolvedSignature => 6
        | ResolvedSignature(parameters) => {
          val operands = requested.act.operands.foldl(List(), (out, o) =>
            out.append({ name: o.name, sort: o.referent.sort }))
          if (requested.act.operation != definition.kind.symbol or requested.act.parameters != parameters) 7
          else if (operands != parameters) 8
          else 0
        }
      }
    }
  }

  pure val alice: Ref = { sort: PersonSort, symbol: named("person", "alice") }
  pure val bob: Ref = { sort: PersonSort, symbol: named("person", "bob") }
  pure val debt: Ref = { sort: ObligationSort, symbol: named("synthetic.debt", "d1") }
  pure val repaymentKind: Kind = kind("synthetic.act", "repay")
  pure val supportKind: Kind = kind("synthetic.predicate", "qualified")
  pure val exceptionKind: Kind = supportKind.with("version", 2)
  pure val revokeKind: Kind = kind("fiqh.act.candidate.v1", "agency.revoke")
  pure val revokeDefinition: Definition = {
    kind: revokeKind, digest: digest(9), roles: List(
      { name: "revoking_party", sort: KnownSort(PersonSort) },
      { name: "mandate_reference", sort: OpenSort },
      { name: "manifestation", sort: OpenSort })
  }
  pure def revokeRequest(choice: int): Declaration = {
    val mandateSort = if (choice == 1) PersonSort else if (choice == 2) AssetSort
      else if (choice == 3) PropositionSort else ObligationSort
    val parameters = List({ name: "revoking_party", sort: PersonSort },
      { name: "mandate_reference", sort: mandateSort },
      { name: "manifestation", sort: PropositionSort })
    val operands = List({ name: "revoking_party", referent: alice },
      { name: "mandate_reference", referent: { sort: mandateSort, symbol: named("synthetic.mandate", "m1") } },
      { name: "manifestation", referent: { sort: PropositionSort, symbol: named("synthetic.manifestation", "m1") } })
    { kind: if (choice == 7) revokeKind.with("version", 2) else revokeKind,
      digest: digest(if (choice == 6) 8 else 9),
      act: { operation: revokeKind.symbol, parameters: parameters, operands: operands } }
  }
  pure def registryCell(choice: int): int = {
    val coerced = revokeDefinition.with("roles", List(
      { name: "revoking_party", sort: KnownSort(PersonSort) },
      { name: "mandate_reference", sort: KnownSort(ObligationSort) },
      { name: "manifestation", sort: KnownSort(PropositionSort) }))
    val partiallyRefined = revokeDefinition.with("roles", List(
      { name: "revoking_party", sort: KnownSort(PersonSort) },
      { name: "mandate_reference", sort: OpenSort },
      { name: "manifestation", sort: KnownSort(PropositionSort) }))
    val definitions = if (choice == 4) List()
      else if (choice == 5) List(revokeDefinition, coerced)
      else if (choice == 8) List(partiallyRefined)
      else List(revokeDefinition)
    registryCode(definitions, revokeRequest(choice))
  }

  pure val repayment: Act = {
    operation: repaymentKind.symbol,
    parameters: List({ name: "debtor", sort: PersonSort }, { name: "creditor", sort: PersonSort },
      { name: "debt", sort: ObligationSort }),
    operands: List({ name: "debtor", referent: alice }, { name: "creditor", referent: bob },
      { name: "debt", referent: debt })
  }
  // The substitution acts on person positions only. The rigid debt, occurrence,
  // clock and interval stay in their original carriers.
  pure def substitutePerson(ref: Ref, swapped: bool): Ref =
    if (not(swapped) or ref.sort != PersonSort) ref
    else if (ref == alice) bob else if (ref == bob) alice else ref
  pure def substituteAct(act: Act, swapped: bool): Act =
    act.with("operands", act.operands.foldl(List(), (out, o) =>
      out.append(o.with("referent", substitutePerson(o.referent, swapped)))))
  pure def opportunity(occurrence: int): Opportunity = {
    occurrence: named("synthetic.event", if (occurrence == 0) "one" else "two"),
    clock: named("clock", "test"), opensAt: 9, closesAt: 12
  }
  pure def omission(occurrence: int, swapped: bool): Omission =
    { act: substituteAct(repayment, swapped), opportunity: opportunity(occurrence) }
  pure def occurrenceCode(o: Opportunity): int =
    if (o.occurrence == named("synthetic.event", "one")) 1
    else if (o.occurrence == named("synthetic.event", "two")) 2 else 0

  pure def scope(occurrence: int, swapped: bool, destination: bool): Scope = {
    val target = omission(occurrence, destination and swapped)
    { target: target, kind: repaymentKind, digest: digest(1), registryVersion: 1,
      question: 1, subject: if (destination) 43 else 42,
      accountable: target.act.operands[1].referent, performer: target.act.operands[0],
      contextId: 1 + 2 * occurrence + flag(destination), timeId: 1,
      profile: 1, profileVersion: 1, interpretationId: 1, interpretationVersion: 1,
      vocabularyVersion: 1,
      policy: kind("synthetic.policy", if (destination) "destination" else "test"),
      clockVersion: 1, effectiveAt: 10, recordedAt: 20, cutoff: 20, retrospective: true }
  }
  pure def report(predicate: Kind, person: Ref, positive: bool): Report =
    { predicate: predicate, arguments: List(person), positive: positive,
      mention: named("synthetic.mention", "m1") }
  pure def reportRows(frame: Scope, mask: int): List[Report] = {
    val rows = List(report(supportKind, frame.accountable, true),
      report(supportKind, frame.accountable, false),
      report(exceptionKind, frame.performer.referent, true),
      report(exceptionKind, frame.performer.referent, false))
    val weights = List(1, 2, 4, 8)
    range(0, 4).foldl(List(), (out, i) => if (bit(mask, weights[i])) out.append(rows[i]) else out)
  }
  pure def snapshot(occurrence: int, swapped: bool, destination: bool, mask: int): Snapshot = {
    val frame = scope(occurrence, swapped, destination)
    { key: kind("synthetic.snapshot", "repayment").with("version", frame.contextId),
      scope: frame, evidenceRevision: 1, reports: reportRows(frame, mask) }
  }
  pure def snapshotShape(s: Snapshot): bool = and {
    s.key.version > 0, s.scope.profileVersion > 0, s.scope.interpretationVersion > 0,
    s.scope.target.opportunity.opensAt < s.scope.target.opportunity.closesAt,
    s.scope.target.opportunity.clock == named("clock", "test"),
    s.scope.kind == repaymentKind,
    s.scope.target.act.operation == repaymentKind.symbol,
    s.scope.target.act.operands[0] == s.scope.performer,
    s.scope.target.act.operands[1].referent == s.scope.accountable,
    s.reports.foldl(true, (ok, q) => ok and
      (q.predicate == supportKind or q.predicate == exceptionKind) and
      q.arguments.length() == 1 and q.arguments[0].sort == PersonSort),
  }

  // MUTATION_DROPPED_QUALIFICATION: the evaluator must read both signed queries.
  pure def reportsRead(s: Snapshot): List[Report] = s.reports
  pure def observed(rows: List[Report], predicate: Kind, person: Ref, positive: bool): bool =
    rows.foldl(false, (found, q) => found or
      (q.predicate == predicate and q.arguments == List(person) and q.positive == positive))
  pure def signedObservations(rows: List[Report], predicate: Kind, person: Ref): Set[bool] =
    rows.foldl(Set(), (signs, q) =>
      if (q.predicate == predicate and q.arguments == List(person)) signs.union(Set(q.positive)) else signs)
  pure def classify(support: Set[bool], exception: Set[bool]): int =
    if (exception == Set(true, false)) 7
    else if (exception.contains(true)) 6
    else if (support == Set(true, false)) 5
    else if (support.contains(true)) 4
    else if (support.contains(false)) 3
    else if (exception.contains(false)) 2
    else 1
  pure def evaluate(expected: Scope, s: Snapshot): int = {
    val rows = reportsRead(s)
    val support = Set(true, false).filter(sign => observed(rows, supportKind, s.scope.accountable, sign))
    val exception = Set(true, false).filter(sign => observed(rows, exceptionKind, s.scope.performer.referent, sign))
    if (s.scope != expected) 0 else classify(support, exception)
  }
  // MUTATION_ERASED_OCCURRENCE: full scoped projection retains the opportunity.
  pure def projectedOpportunity(o: Opportunity): Opportunity = o.with("occurrence", o.occurrence)
  pure def project(s: Snapshot): Dependencies = {
    val rows = reportsRead(s)
    val retained = s.scope.with("target", s.scope.target.with("opportunity",
      projectedOpportunity(s.scope.target.opportunity)))
    { scope: retained,
      support: signedObservations(rows, supportKind, s.scope.accountable),
      exception: signedObservations(rows, exceptionKind, s.scope.performer.referent) }
  }
  pure def evaluateProjected(expected: Scope, observed: Dependencies): int =
    if (observed.scope != expected) 0 else classify(observed.support, observed.exception)

  pure def premiseScope(s: Snapshot): PremiseScope = {
    question: s.scope.question, subject: s.scope.subject, target: s.scope.target,
    contextId: s.scope.contextId, timeId: s.scope.timeId,
    profile: s.scope.profile, profileVersion: s.scope.profileVersion,
    interpretationId: s.scope.interpretationId, interpretationVersion: s.scope.interpretationVersion
  }
  pure def premiseAtom(swapped: bool, destination: bool): Atom =
    { predicate: supportKind, person: substitutePerson(alice, destination and swapped), positive: true }
  pure def application(occurrence: int, swapped: bool, destination: bool, mask: int): Application = {
    val atom = premiseAtom(swapped, destination)
    { snapshot: snapshot(occurrence, swapped, destination, mask), grounding: List(alice, bob),
      premises: List(AtomFormula(atom)), conclusion: DoubleFormula(atom) }
  }
  pure def side(occurrence: int, swapped: bool, destination: bool, mask: int): Side = {
    val app = application(occurrence, swapped, destination, mask)
    val id = app.snapshot.scope.contextId
    val premise = { entryId: id, sourceId: id, registryVersion: 1, scope: premiseScope(app.snapshot) }
    { application: app, certificates: List(
      { token: id, application: app, formula: app.premises[0], premise: premise }) }
  }
  pure def authority(swapped: bool, leftMask: int, rightMask: int): Authority = {
    val sides = List(side(0, swapped, false, 9), side(0, swapped, true, leftMask),
      side(1, swapped, false, 9), side(1, swapped, true, rightMask))
    val certificates = sides.foldl(List(), (out, s) => out.concat(s.certificates))
    val premises = certificates.foldl(List(), (out, c) => out.append(c.premise))
    { contexts: sides.foldl(List(), (out, s) => out.append(s.application.snapshot)),
      authenticated: certificates, grants: sides,
      environment: { registryVersion: 1, entries: premises,
        authenticatedSources: premises.foldl(Set(), (out, p) => out.union(Set(p.sourceId))),
        evidence: premises } }
  }
  pure def nativeAuthority(swapped: bool): Authority = authority(swapped, 9, 9)

  // Source admission checks the exact submitted entry, authenticated source
  // identity, registry pin and evidence row; there is no independent admit flag.
  pure def sourceCode(a: Authority, p: Premise): int = {
    val env = a.environment
    if (p.registryVersion != env.registryVersion) 9
    else if (env.entries.select(entry => entry.entryId == p.entryId) != List(p)) 99
    else if (not(env.authenticatedSources.contains(p.sourceId))) 3
    else if (env.evidence.select(entry => entry == p) != List(p)) 7
    else 0
  }
  pure def authenticated(a: Authority, c: Certificate): bool =
    c.token != 0 and a.authenticated.select(other => other.token == c.token) == List(c)
  // MUTATION_CROSS_OCCURRENCE: authentication does not waive exact application scope.
  pure def certificateScope(c: Certificate, app: Application): bool =
    c.application == app and c.premise.scope == premiseScope(app.snapshot)
  pure def certificateCode(a: Authority, app: Application, c: Certificate): int =
    if (not(certificateScope(c, app))) 12
    else if (not(authenticated(a, c))) 4
    else sourceCode(a, c.premise)
  // MUTATION_STALE_CONTEXT: exact snapshot matching includes evidence revision.
  pure def currentSnapshot(a: Authority, expected: Snapshot): bool =
    a.contexts.select(s => s.scope.contextId == expected.scope.contextId) == List(expected)
  pure def checkSide(a: Authority, submitted: Side, expected: Application): int = {
    val formulas = submitted.certificates.foldl(List(), (out, c) => out.append(c.formula))
    if (submitted.application != expected) 10
    else if (not(currentSnapshot(a, expected.snapshot))) 2
    else if (not(snapshotShape(expected.snapshot))) 99
    else if (formulas != expected.premises) 1
    else {
      val certCode = submitted.certificates.foldl(0, (prior, c) =>
        if (prior != 0) prior else certificateCode(a, expected, c))
      if (certCode != 0) certCode
      else if (not(a.grants.select(s => s == submitted).length() > 0)) 5
      else 0
    }
  }
  pure def reconstruct(a: Authority, occurrence: int, swapped: bool, submitted: Side): int = {
    val source = side(occurrence, swapped, false, 9)
    val sourceResult = checkSide(a, source, source.application)
    val expected = application(occurrence, swapped, true, 9)
      .with("snapshot", submitted.application.snapshot)
    if (sourceResult != 0) sourceResult
    else if (expected.snapshot.scope != scope(occurrence, swapped, true)) 11
    else checkSide(a, submitted, expected)
  }
  pure def replay(current: Authority, issued: Authority, occurrence: int, swapped: bool): int =
    if (current != issued) 8
    else reconstruct(current, occurrence, swapped, side(occurrence, swapped, true, 9))

  // History values are independent of Report and Authority. Mask 2 makes the
  // version-one predicate true for Bob only; mask 1 does so for Alice only.
  pure def atomTruth(history: int, atom: Atom): bool = {
    val positive = atom.predicate == supportKind and
      ((atom.person == alice and bit(history, 1)) or (atom.person == bob and bit(history, 2)))
    positive == atom.positive
  }
  pure def formulaTruth(history: int, formula: Formula): bool = match formula {
    | AtomFormula(atom) => atomTruth(history, atom)
    | DoubleFormula(atom) => atomTruth(history, atom) and atomTruth(history, atom)
  }

  pure def qualificationCells(occurrence: int, mask: int): List[int] = {
    val s = snapshot(occurrence, true, true, mask)
    val native = snapshot(occurrence, true, true, 9)
    val projected = project(s)
    val current = authority(true, if (occurrence == 0) mask else 9, if (occurrence == 1) mask else 9)
    List(flag(snapshotShape(s)), evaluate(native.scope, s), evaluateProjected(native.scope, projected),
      occurrenceCode(projected.scope.target.opportunity),
      flag(s.scope.target == native.scope.target), flag(s.scope.kind == native.scope.kind),
      flag(formulaTruth(2, application(occurrence, true, true, mask).conclusion)),
      replay(current, nativeAuthority(true), occurrence, true))
  }

  pure def trial(occurrence: int, swapped: bool, mutation: int): Trial = {
    val a = nativeAuthority(swapped)
    val native = side(occurrence, swapped, true, 9)
    val own = native.certificates[0]
    val other = side(1 - occurrence, swapped, true, 9).certificates[0]
    if (mutation == 1) { authority: a, submitted: native.with("certificates", List()) }
    else if (mutation == 2) {
      val changed = own.with("formula", DoubleFormula(premiseAtom(swapped, true)))
      { authority: a, submitted: native.with("certificates", List(changed)) }
    }
    else if (mutation == 3) {
      val proposed = native.with("certificates", List(other))
      { authority: a.with("grants", a.grants.append(proposed)), submitted: proposed }
    }
    else if (mutation == 4) {
      val contexts = a.contexts.foldl(List(), (out, s) =>
        out.append(if (s.scope.contextId == native.application.snapshot.scope.contextId)
          s.with("evidenceRevision", s.evidenceRevision + 1) else s))
      { authority: a.with("contexts", contexts), submitted: native }
    }
    else if (mutation == 5)
      { authority: a.with("authenticated", a.authenticated.append(own)), submitted: native }
    else if (mutation == 6) {
      val env = a.environment.with("evidence", a.environment.evidence.select(p => p != own.premise))
      { authority: a.with("environment", env), submitted: native }
    }
    else if (mutation == 7)
      { authority: a.with("grants", a.grants.select(s => s != native)), submitted: native }
    else if (mutation == 8) {
      val env = a.environment.with("authenticatedSources",
        a.environment.authenticatedSources.filter(id => id != own.premise.sourceId))
      { authority: a.with("environment", env), submitted: native }
    }
    else if (mutation == 9) {
      val proposed = native.with("certificates", List(own.with("token", other.token)))
      { authority: a.with("grants", a.grants.append(proposed)), submitted: proposed }
    }
    else { authority: a, submitted: native }
  }
  pure def occurrenceCells(occurrence: int, swapped: bool, mutation: int): List[int] = {
    val source = application(occurrence, swapped, false, 9)
    val destination = application(occurrence, swapped, true, 9)
    val proposed = trial(occurrence, swapped, mutation)
    List(occurrenceCode(source.snapshot.scope.target.opportunity),
      occurrenceCode(destination.snapshot.scope.target.opportunity),
      occurrenceCode(project(destination.snapshot).scope.target.opportunity),
      source.snapshot.scope.profile, destination.snapshot.scope.profile,
      checkSide(proposed.authority, proposed.submitted, destination),
      reconstruct(proposed.authority, occurrence, swapped, proposed.submitted),
      replay(proposed.authority, nativeAuthority(swapped), occurrence, swapped))
  }

  pure def allCells: List[int] = {
    val registry = range(0, 9).foldl(List(), (out, v) => out.append(registryCell(v)))
    val qualified = range(0, 32).foldl(registry, (out, i) =>
      out.concat(qualificationCells(i / 16, i % 16)))
    range(0, 40).foldl(qualified, (out, i) =>
      out.concat(occurrenceCells(i / 20, (i / 10) % 2 == 1, i % 10)))
  }
  var results: List[int]
  action init = results' = allCells
  action step = results' = results

  run unresolvedMandateTest = assert(and {
    registryCell(0) == 6, registryCell(1) == 6, registryCell(2) == 6, registryCell(3) == 6,
    registryCell(8) == 6, registryCell(4) == 4, registryCell(5) == 1,
    registryCell(6) == 5, registryCell(7) == 4,
  })
  run qualificationDependencyTest = assert(0.to(1).forall(occurrence => and {
    qualificationCells(occurrence, 1)[1] == 4,
    qualificationCells(occurrence, 5)[1] == 6,
    qualificationCells(occurrence, 13)[1] == 7,
    qualificationCells(occurrence, 3)[1] == 5,
    qualificationCells(occurrence, 0)[1] == 1,
    qualificationCells(occurrence, 8)[1] == 2,
    snapshot(occurrence, true, true, 1).scope == snapshot(occurrence, true, true, 5).scope,
  }))
  run qualificationProjectionTest = assert(0.to(31).forall(i => {
    val occurrence = i / 16
    val mask = i % 16
    val cells = qualificationCells(occurrence, mask)
    val fresh = authority(true, if (occurrence == 0) mask else 9, if (occurrence == 1) mask else 9)
    val submitted = side(occurrence, true, true, mask)
    and { cells[0] == 1, cells[1] == cells[2], cells[6] == 1,
      checkSide(fresh, submitted, submitted.application) == 0,
      reconstruct(fresh, occurrence, true, submitted) == 0 }
  }))
  run occurrenceProjectionTest = assert(and {
    0.to(3).forall(i => {
      val occurrence = i / 2
      val cells = occurrenceCells(occurrence, i % 2 == 1, 0)
      cells[0] == occurrence + 1 and cells[1] == occurrence + 1 and cells[2] == occurrence + 1
    }),
    project(snapshot(0, true, true, 9)).scope.target != project(snapshot(1, true, true, 9)).scope.target,
    snapshot(0, true, true, 9).scope.kind == snapshot(1, true, true, 9).scope.kind,
  })
  run sameProfileSubstitutionTest = assert(0.to(3).forall(i => {
    val occurrence = i / 2
    val swapped = i % 2 == 1
    val source = application(occurrence, swapped, false, 9)
    val destination = application(occurrence, swapped, true, 9)
    and {
      source.snapshot.scope.profile == 1, destination.snapshot.scope.profile == 1,
      source.snapshot.scope.target.opportunity == destination.snapshot.scope.target.opportunity,
      destination.snapshot.scope.target.act.operands[2].referent == debt,
      substituteAct(substituteAct(repayment, swapped), swapped) == repayment,
      destination.premises.foldl(true, (ok, f) => ok and formulaTruth(if (swapped) 2 else 1, f)),
      formulaTruth(if (swapped) 2 else 1, destination.conclusion),
    }
  }))
  run nativeAdmissionTest = assert(0.to(3).forall(i => {
    val cells = occurrenceCells(i / 2, i % 2 == 1, 0)
    cells[5] == 0 and cells[6] == 0 and cells[7] == 0
  }))
  run crossOccurrenceCertificateTest = assert(0.to(3).forall(i => {
    val occurrence = i / 2
    val swapped = i % 2 == 1
    val proposed = trial(occurrence, swapped, 3)
    val borrowed = proposed.submitted.certificates[0]
    and {
      authenticated(proposed.authority, borrowed),
      sourceCode(proposed.authority, borrowed.premise) == 0,
      proposed.authority.grants.select(s => s == proposed.submitted).length() > 0,
      checkSide(proposed.authority, proposed.submitted, application(occurrence, swapped, true, 9)) == 12,
      occurrenceCells(occurrence, swapped, 3)[6] == 12,
    }
  }))
  run staleContextTest = assert(0.to(3).forall(i => {
    val cells = occurrenceCells(i / 2, i % 2 == 1, 4)
    cells[5] == 2 and cells[6] == 2 and cells[7] == 8
  }))
  run certificateAndInputControlsTest = assert(0.to(3).forall(i => {
    val occurrence = i / 2
    val swapped = i % 2 == 1
    and {
      occurrenceCells(occurrence, swapped, 1)[5] == 1,
      occurrenceCells(occurrence, swapped, 2)[5] == 1,
      occurrenceCells(occurrence, swapped, 5)[5] == 4,
      occurrenceCells(occurrence, swapped, 9)[5] == 4,
      occurrenceCells(occurrence, swapped, 1)[7] == 0,
      occurrenceCells(occurrence, swapped, 2)[7] == 0,
    }
  }))
  run sourceEvidenceAndGrantTest = assert(0.to(3).forall(i => {
    val occurrence = i / 2
    val swapped = i % 2 == 1
    occurrenceCells(occurrence, swapped, 6)[5] == 7 and
      occurrenceCells(occurrence, swapped, 7)[5] == 5 and
      occurrenceCells(occurrence, swapped, 8)[5] == 3
  }))
  run receiptAuthorityTest = assert(and {
    0.to(31).forall(i => qualificationCells(i / 16, i % 16)[7] == (if (i % 16 == 9) 0 else 8)),
    0.to(39).forall(i => occurrenceCells(i / 20, (i / 10) % 2 == 1, i % 10)[7] ==
      (if (i % 10 < 3) 0 else 8)),
  })
  run finiteTableShapeTest = assert(allCells.length() == 585)
}
