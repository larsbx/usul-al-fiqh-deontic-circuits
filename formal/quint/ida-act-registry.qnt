// ACT-01: independently written finite registry and bound-admission model.
// The public wire contract is shared with Lean; no Lean result table is imported.
// Definition digests are exact pins here. The host adapter recomputes SHA-256
// over canonical definition bytes; this module assumes no hash injectivity.
module idaActRegistry {
  import ida as A from "./ida"
  import idaJudgment as J from "./ida-judgment"
  import idaDerivation as D from "./ida-derivation"

  type KindKey = { symbol: A::Symbol, version: int }
  type RoleSort = UnresolvedSort | DeclaredSort(A::RefKind)
  type RoleSpec = { role: str, kind: RoleSort }
  type Definition = { key: KindKey, digest: List[int], roles: List[RoleSpec] }
  type Registry = { snapshot: int, definitions: List[Definition] }
  type Qualification = {
    predicate: A::Symbol, version: int, arguments: List[A::EntityRef],
    polarity: bool, mention: A::Symbol
  }
  type ContextSnapshot = {
    contextId: int, timeId: int, profile: int, profileVersion: int,
    interpretationId: int, interpretationVersion: int, evidenceRevision: int,
    clock: A::Symbol, effectiveAt: int, recordedAt: int
  }
  type Envelope = {
    key: KindKey, definitionDigest: List[int], registrySnapshot: int,
    qualifications: List[Qualification], context: ContextSnapshot, act: A::Act
  }
  type Binding = { envelope: Envelope, premise: D::Premise }
  type Authority = {
    registry: Registry, bindings: List[Binding], environment: D::Environment
  }
  type BoundRequest = { envelope: Envelope, premise: D::Premise }
  type Signature = UnresolvedSignature | ResolvedSignature(List[A::Parameter])

  pure def sameKey(left: KindKey, right: KindKey): bool =
    A::sameSymbol(left.symbol, right.symbol) and left.version == right.version

  // Sets of complete tuples avoid delimiter-dependent or hash-based key equality.
  pure def uniqueDefinitionKeys(definitions: List[Definition]): bool = {
    val keySet = definitions.foldl(Set(), (seen, definition) =>
      seen.union(Set((definition.key.symbol.space, definition.key.symbol.name,
        definition.key.version))))
    keySet.size() == definitions.length()
  }

  pure def definitionWellFormed(definition: Definition): bool = {
    val names = definition.roles.foldl(Set(), (seen, role) => seen.union(Set(role.role)))
    and {
      A::validSymbol(definition.key.symbol),
      definition.key.version > 0,
      J::digestShape(definition.digest),
      names.size() == definition.roles.length(),
      definition.roles.foldl(true, (ok, role) => ok and role.role != ""),
    }
  }

  pure def registryWellFormed(registry: Registry): bool =
    registry.snapshot >= 0 and
      registry.definitions.foldl(true, (ok, definition) => ok and definitionWellFormed(definition))

  // No reference sort is manufactured for an unresolved role, even in a helper.
  pure def signatureOf(roles: List[RoleSpec]): Signature =
    roles.foldl(ResolvedSignature(List()), (signature, role) => match signature {
      | UnresolvedSignature => UnresolvedSignature
      | ResolvedSignature(parameters) => match role.kind {
        | UnresolvedSort => UnresolvedSignature
        | DeclaredSort(kind) => ResolvedSignature(parameters.append({ role: role.role, kind: kind }))
      }
    })

  pure def qualificationWellFormed(qualification: Qualification): bool = and {
    A::validSymbol(qualification.predicate),
    qualification.version > 0,
    qualification.arguments.foldl(true, (ok, argument) => ok and A::validEntity(argument)),
    A::validSymbol(qualification.mention),
  }

  pure def contextWellFormed(context: ContextSnapshot): bool = and {
    context.contextId >= 0, context.timeId >= 0, context.profile >= 0,
    context.profileVersion > 0, context.interpretationId >= 0,
    context.interpretationVersion > 0, context.evidenceRevision >= 0,
    A::validSymbol(context.clock), context.effectiveAt >= 0, context.recordedAt >= 0,
  }

  pure def envelopeWellFormed(envelope: Envelope): bool = and {
    A::validAct(envelope.act), contextWellFormed(envelope.context),
    envelope.qualifications.foldl(true, (ok, qualification) => ok and qualificationWellFormed(qualification)),
  }

  // Result codes are precedence-ordered diagnostics, not a legal ruling.
  // 0 success; 1 duplicate key; 2 malformed registry; 3 stale registry snapshot;
  // 4 unknown key/version; 5 digest mismatch; 6 unresolved role;
  // 7 declared-operation mismatch; 8 operand schema mismatch; 9 malformed envelope.
  pure def structuralCode(registry: Registry, envelope: Envelope): int = {
    if (not(uniqueDefinitionKeys(registry.definitions))) 1
    else if (not(registryWellFormed(registry))) 2
    else if (registry.snapshot != envelope.registrySnapshot) 3
    else {
      val definitions = registry.definitions.select(definition => sameKey(definition.key, envelope.key))
      if (definitions.length() == 0) 4
      else {
        val definition = definitions.head()
        if (definition.digest != envelope.definitionDigest) 5
        else match signatureOf(definition.roles) {
          | UnresolvedSignature => 6
          | ResolvedSignature(parameters) => {
            if (not(A::sameSymbol(envelope.act.operation.symbol, definition.key.symbol)) or
                not(A::sameParameters(envelope.act.operation.parameters, parameters))) 7
            else if (not(A::sameParameters(A::operandParameters(envelope.act.operands), parameters))) 8
            else if (not(envelopeWellFormed(envelope))) 9
            else 0
          }
        }
      }
    }
  }

  pure def sameQualification(left: Qualification, right: Qualification): bool = and {
    A::sameSymbol(left.predicate, right.predicate), left.version == right.version,
    left.polarity == right.polarity, A::sameSymbol(left.mention, right.mention),
    left.arguments.length() == right.arguments.length(),
    if (left.arguments.length() == right.arguments.length())
      indices(left.arguments).forall(i => A::sameEntity(left.arguments[i], right.arguments[i]))
    else false,
  }

  pure def sameContext(left: ContextSnapshot, right: ContextSnapshot): bool = and {
    left.contextId == right.contextId, left.timeId == right.timeId,
    left.profile == right.profile, left.profileVersion == right.profileVersion,
    left.interpretationId == right.interpretationId,
    left.interpretationVersion == right.interpretationVersion,
    left.evidenceRevision == right.evidenceRevision,
    A::sameSymbol(left.clock, right.clock),
    left.effectiveAt == right.effectiveAt, left.recordedAt == right.recordedAt,
  }

  pure def sameEnvelope(left: Envelope, right: Envelope): bool = and {
    sameKey(left.key, right.key), left.definitionDigest == right.definitionDigest,
    left.registrySnapshot == right.registrySnapshot, sameContext(left.context, right.context),
    A::sameAct(left.act, right.act),
    left.qualifications.length() == right.qualifications.length(),
    if (left.qualifications.length() == right.qualifications.length())
      indices(left.qualifications).forall(i => sameQualification(left.qualifications[i], right.qualifications[i]))
    else false,
  }

  // A deliberately lossy projection: it does not claim to embed the envelope.
  pure def project(envelope: Envelope): J::ScopeTarget = J::DescribedTarget(A::Perform(envelope.act))

  pure def uniqueBindingKeys(bindings: List[Binding]): bool = {
    val keySet = bindings.foldl(Set(), (seen, binding) => seen.union(Set(binding.premise.request.entryId)))
    keySet.size() == bindings.length()
  }

  pure def snapshotMatches(envelope: Envelope, premise: D::Premise): bool = {
    val scope = premise.request.record.scope
    val provenance = premise.request.record.provenance
    and {
      envelope.context.contextId == scope.context,
      envelope.context.timeId == scope.time,
      envelope.context.profile == scope.profile,
      envelope.context.profileVersion == scope.profileVersion,
      envelope.context.interpretationId == provenance.interpretationId,
      envelope.context.interpretationVersion == provenance.interpretationVersion,
    }
  }

  // Binding keys are source entry identities. Different sources may support the
  // same envelope; a single entry cannot silently carry two different envelopes.
  // Additional codes: 10 duplicate bindings; 11 missing binding; 12 envelope
  // mismatch; 13 premise mismatch; 14 projection mismatch; 15 source rejected;
  // 16 context/scope mismatch. There is no independent admission flag.
  pure def boundCode(authority: Authority, request: BoundRequest): int = {
    val structural = structuralCode(authority.registry, request.envelope)
    if (structural != 0) structural
    else if (not(uniqueBindingKeys(authority.bindings))) 10
    else {
      val bindings = authority.bindings.select(binding => binding.premise.request.entryId == request.premise.request.entryId)
      if (bindings.length() == 0) 11
      else {
        val binding = bindings.head()
        if (not(sameEnvelope(binding.envelope, request.envelope))) 12
        else if (not(D::samePremise(binding.premise, request.premise))) 13
        else if (not(J::sameScopeTarget(project(request.envelope), request.premise.request.record.scope.target))) 14
        else if (not(snapshotMatches(request.envelope, request.premise))) 16
        // MUTATION_POINT: source admission must be the existing evaluator.
        else if (D::accepted(D::evaluateSource(authority.environment, request.premise))) 0
        else 15
      }
    }
  }

  pure def baseOutcome(authority: Authority, request: BoundRequest): int =
    D::outcomeCode(D::evaluateSource(authority.environment, request.premise))

  // Synthetic wire fixtures. These are a declared finite domain, not a source
  // ontology. A source fixture's supplied admission remains separate from the
  // candidate status of any real interpretation.
  pure val baseDigest: List[int] = List(
    8,70,205,21,208,245,133,192,119,114,183,158,215,102,36,130,
    195,174,38,21,178,69,147,192,44,51,172,159,176,205,107,148)
  pure def repeatedDigest(byte: int): List[int] =
    range(0, 32).foldl(List(), (bytes, ignored) => bytes.append(byte))

  pure val baseKey: KindKey = { symbol: { space: "synthetic.act", name: "transfer" }, version: 1 }
  pure val payerRole: RoleSpec = { role: "payer", kind: DeclaredSort(A::PersonRef) }
  pure val recipientRole: RoleSpec = { role: "recipient", kind: DeclaredSort(A::PersonRef) }
  pure val propertyRole: RoleSpec = { role: "property", kind: DeclaredSort(A::AssetRef) }
  pure val baseDefinition: Definition = {
    key: baseKey, digest: baseDigest, roles: List(payerRole, recipientRole, propertyRole)
  }
  pure val baseRegistry: Registry = { snapshot: 1, definitions: List(baseDefinition) }
  pure val payer: A::EntityRef = { kind: A::PersonRef, symbol: { space: "person", name: "alice" } }
  pure val recipient: A::EntityRef = { kind: A::PersonRef, symbol: { space: "person", name: "bob" } }
  pure val property: A::EntityRef = { kind: A::AssetRef, symbol: { space: "asset", name: "coin" } }
  pure val payerOperand: A::Operand = { role: "payer", referent: payer }
  pure val recipientOperand: A::Operand = { role: "recipient", referent: recipient }
  pure val propertyOperand: A::Operand = { role: "property", referent: property }
  pure val baseParameters: List[A::Parameter] = List(
    { role: "payer", kind: A::PersonRef },
    { role: "recipient", kind: A::PersonRef },
    { role: "property", kind: A::AssetRef })
  pure val baseAct: A::Act = {
    operation: { symbol: baseKey.symbol, parameters: baseParameters },
    operands: List(payerOperand, recipientOperand, propertyOperand)
  }
  pure val baseQualification: Qualification = {
    predicate: { space: "synthetic.predicate", name: "qualified" }, version: 1,
    arguments: List(payer), polarity: true,
    mention: { space: "synthetic.source", name: "mention-1" }
  }
  pure val baseContext: ContextSnapshot = {
    contextId: 1, timeId: 1, profile: 1, profileVersion: 1,
    interpretationId: 1, interpretationVersion: 1, evidenceRevision: 1,
    clock: { space: "clock", name: "test" }, effectiveAt: 10, recordedAt: 20
  }
  pure val baseEnvelope: Envelope = {
    key: baseKey, definitionDigest: baseDigest, registrySnapshot: 1,
    qualifications: List(baseQualification), context: baseContext, act: baseAct
  }

  pure def registryCase(index: int): Registry = {
    val other = baseDefinition.with("key", baseKey.with("symbol", baseKey.symbol.with("name", "other")))
    val v2 = baseDefinition.with("key", baseKey.with("version", 2)).with("digest", repeatedDigest(2))
    val definitions =
      if (index == 0) List(baseDefinition)
      else if (index == 1) List()
      else if (index == 2) List(baseDefinition, baseDefinition)
      else if (index == 3) List(baseDefinition, baseDefinition.with("digest", repeatedDigest(2)))
      else if (index == 4) List(baseDefinition, baseDefinition.with("roles", List(propertyRole, recipientRole, payerRole)))
      else if (index == 5) List(baseDefinition, other, other)
      else if (index == 6) List(baseDefinition.with("roles", List(payerRole, recipientRole, propertyRole.with("kind", UnresolvedSort))))
      else if (index == 7) List(baseDefinition.with("digest", baseDigest.slice(0, 31)))
      else if (index == 8) List(baseDefinition.with("roles", List(payerRole, recipientRole, propertyRole.with("role", "payer"))))
      else if (index == 9) List(baseDefinition.with("roles", List(payerRole, recipientRole, propertyRole.with("role", ""))))
      else if (index == 10) List(baseDefinition.with("key", baseKey.with("symbol", baseKey.symbol.with("space", ""))))
      else if (index == 11) List(baseDefinition, other)
      else if (index == 12) List(baseDefinition.with("key", baseKey.with("version", 0)))
      else if (index == 13) List(baseDefinition, v2)
      else Set().getOnlyElement()
    { snapshot: 1, definitions: definitions }
  }

  pure def withQualification(qualification: Qualification): Envelope =
    baseEnvelope.with("qualifications", List(qualification))

  pure def envelopeCase(index: int): Envelope = {
    if (index == 0) baseEnvelope
    else if (index == 1) baseEnvelope.with("key", baseKey.with("version", 2))
    else if (index == 2) baseEnvelope.with("key", baseKey.with("symbol", baseKey.symbol.with("name", "unknown")))
    else if (index == 3) baseEnvelope.with("definitionDigest", repeatedDigest(2))
    else if (index == 4) baseEnvelope.with("registrySnapshot", 2)
    else if (index == 5) baseEnvelope.with("act", baseAct.with("operation", baseAct.operation.with("symbol", baseKey.symbol.with("name", "renamed"))))
    else if (index == 6) baseEnvelope.with("act", baseAct.with("operation", baseAct.operation.with("parameters", List(baseParameters[2], baseParameters[1], baseParameters[0]))))
    else if (index == 7) baseEnvelope.with("act", baseAct.with("operands", List(propertyOperand, recipientOperand, payerOperand)))
    else if (index == 8) baseEnvelope.with("act", baseAct.with("operands", List(payerOperand, recipientOperand, propertyOperand.with("referent", property.with("kind", A::ObligationRef)))))
    else if (index == 9) baseEnvelope.with("act", baseAct.with("operands", List(payerOperand.with("referent", recipient), recipientOperand.with("referent", payer), propertyOperand)))
    else if (index == 10) withQualification(baseQualification.with("polarity", false))
    else if (index == 11) withQualification(baseQualification.with("version", 2))
    else if (index == 12) withQualification(baseQualification.with("arguments", List(recipient)))
    else if (index == 13) withQualification(baseQualification.with("mention", baseQualification.mention.with("name", "mention-2")))
    else if (index == 14) baseEnvelope.with("context", baseContext.with("evidenceRevision", 2))
    else if (index == 15) baseEnvelope.with("context", baseContext.with("clock", baseContext.clock.with("name", "other")))
    else if (index == 16) baseEnvelope.with("context", baseContext.with("effectiveAt", 11))
    else if (index == 17) baseEnvelope.with("context", baseContext.with("recordedAt", 21))
    else if (index == 18) baseEnvelope.with("context", baseContext.with("contextId", 2))
    else if (index == 19) baseEnvelope.with("context", baseContext.with("timeId", 2))
    else if (index == 20) baseEnvelope.with("context", baseContext.with("profile", 2))
    else if (index == 21) baseEnvelope.with("context", baseContext.with("profileVersion", 2))
    else if (index == 22) baseEnvelope.with("context", baseContext.with("interpretationId", 2))
    else if (index == 23) baseEnvelope.with("context", baseContext.with("interpretationVersion", 2))
    else if (index == 24) baseEnvelope.with("act", baseAct.with("operands", List(payerOperand, recipientOperand, propertyOperand.with("referent", property.with("symbol", property.symbol.with("name", ""))))))
    else if (index == 25) withQualification(baseQualification.with("mention", baseQualification.mention.with("name", "")))
    else if (index == 26) withQualification(baseQualification.with("version", 0))
    else if (index == 27) baseEnvelope.with("context", baseContext.with("clock", baseContext.clock.with("name", "")))
    else if (index == 28) baseEnvelope.with("context", baseContext.with("profileVersion", 0))
    else if (index == 29) baseEnvelope.with("key", baseKey.with("version", 0))
    else if (index == 30) withQualification(baseQualification.with("predicate", baseQualification.predicate.with("name", "")))
    else if (index == 31) withQualification(baseQualification.with("arguments", List(payer.with("symbol", payer.symbol.with("name", "")))))
    else if (index == 32) baseEnvelope.with("context", baseContext.with("interpretationVersion", 0))
    else if (index == 33) baseEnvelope.with("act", baseAct.with("operands", List(payerOperand, recipientOperand, propertyOperand.with("role", "other"))))
    else if (index == 34) baseEnvelope.with("qualifications", List())
    else if (index == 35) baseEnvelope.with("act", baseAct.with("operands", List()))
    else Set().getOnlyElement()
  }

  pure val basePremise: D::Premise = D::structuredPremise(1, A::Perform(baseAct))
  pure val baseBinding: Binding = { envelope: baseEnvelope, premise: basePremise }
  pure val otherBinding: Binding = {
    envelope: baseEnvelope, premise: D::structuredPremise(2, A::Perform(baseAct))
  }

  // A new trusted binding may authorize a changed envelope only after the
  // corresponding request and source environment are explicitly reconstructed.
  pure def renewedPremise(envelope: Envelope): D::Premise = {
    val raw = basePremise.request.record
    val context = envelope.context
    val scope = raw.scope.with("target", project(envelope))
      .with("context", context.contextId).with("time", context.timeId)
      .with("profile", context.profile).with("profileVersion", context.profileVersion)
    val provenance = raw.provenance.with("interpretationId", context.interpretationId)
      .with("interpretationVersion", context.interpretationVersion)
    D::withRaw(basePremise, raw.with("scope", scope).with("provenance", provenance))
  }

  pure def bindingCase(index: int, envelope: Envelope, premise: D::Premise): List[Binding] = {
    if (index == 0) List(baseBinding)
    else if (index == 1) List()
    else if (index == 2) List(baseBinding, baseBinding)
    else if (index == 3) List(baseBinding, baseBinding.with("envelope", envelopeCase(10)))
    else if (index == 4) List(baseBinding, otherBinding, otherBinding)
    else if (index == 5) List({ envelope: envelope, premise: basePremise })
    else if (index == 6) List({ envelope: envelope, premise: premise })
    else if (index == 7) {
      val raw = basePremise.request.record
      val provenance = raw.provenance.with("source", raw.provenance.source.with("sourceHash", repeatedDigest(1)))
      List(baseBinding.with("premise", D::withRaw(basePremise, raw.with("provenance", provenance))))
    }
    else if (index == 8) List(baseBinding, otherBinding)
    else if (index == 9) List(baseBinding.with("envelope", envelopeCase(10)))
    else Set().getOnlyElement()
  }

  pure def environmentCase(index: int, premise: D::Premise): D::Environment = {
    val env = D::fixtureEnvironment(List(premise))
    if (index == 0) env
    else if (index == 1) D::withEntryStatus(env, premise.request.entryId, J::Candidate)
    else if (index == 2) D::withEntryStatus(env, premise.request.entryId, J::Quarantined)
    else if (index == 3) D::withEntryStatus(env, premise.request.entryId, J::Revoked)
    else if (index == 4) env.with("authenticatedSources", List())
    else if (index == 5) env.with("currentVersions", List(env.currentVersions.head().with("interpretationVersion", premise.request.record.provenance.interpretationVersion + 1)))
    else if (index == 6) env.with("evidence", List())
    else if (index == 7) D::withEvidenceClass(env, premise.request.entryId, D::Disputed)
    else if (index == 8) env.with("evidence", env.evidence.concat(env.evidence))
    else if (index == 9) env.with("implementationRevision", "")
    else if (index == 10) env.with("registry", env.registry.with("entries", env.registry.entries.concat(env.registry.entries)))
    else if (index == 11) {
      val entry = env.registry.entries.head()
      val raw = entry.record
      val provenance = raw.provenance.with("source", raw.provenance.source.with("sourceHash", repeatedDigest(1)))
      env.with("registry", env.registry.with("entries", List(entry.with("record", raw.with("provenance", provenance)))))
    }
    else Set().getOnlyElement()
  }

  type BoundFixture = { authority: Authority, request: BoundRequest }
  pure def boundFixture(envelopeIndex: int, bindingIndex: int, sourceIndex: int): BoundFixture = {
    val envelope = envelopeCase(envelopeIndex)
    val premise = if (bindingIndex == 6) renewedPremise(envelope) else basePremise
    {
      authority: {
        registry: baseRegistry, bindings: bindingCase(bindingIndex, envelope, premise),
        environment: environmentCase(sourceIndex, premise)
      },
      request: { envelope: envelope, premise: premise }
    }
  }

  pure def structuralCaseCode(registryIndex: int, envelopeIndex: int): int = {
    if (registryIndex < 0 or registryIndex >= 14 or envelopeIndex < 0 or envelopeIndex >= 36) -1
    else structuralCode(registryCase(registryIndex), envelopeCase(envelopeIndex))
  }

  pure def validBoundIndex(envelopeIndex: int, bindingIndex: int, sourceIndex: int): bool = and {
    envelopeIndex >= 0, envelopeIndex < 36,
    bindingIndex >= 0, bindingIndex < 10, sourceIndex >= 0, sourceIndex < 12,
  }

  pure def boundCaseCode(envelopeIndex: int, bindingIndex: int, sourceIndex: int): int = {
    if (not(validBoundIndex(envelopeIndex, bindingIndex, sourceIndex))) -1
    else {
      val fixture = boundFixture(envelopeIndex, bindingIndex, sourceIndex)
      boundCode(fixture.authority, fixture.request)
    }
  }

  pure def boundCaseIssue(envelopeIndex: int, bindingIndex: int, sourceIndex: int): int = {
    if (not(validBoundIndex(envelopeIndex, bindingIndex, sourceIndex))) -1
    else {
      val fixture = boundFixture(envelopeIndex, bindingIndex, sourceIndex)
      if (boundCode(fixture.authority, fixture.request) == 15)
        baseOutcome(fixture.authority, fixture.request)
      else 0
    }
  }

  // The expected finite results are specified by fixture classes, not extracted
  // from the resolver, the binding gate, or Lean's implementation.
  pure val baseStructuralExpected: List[int] = List(
    0,4,4,5,3,7,7,8,8,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,9,9,9,9,9,4,9,9,9,8,0,8)

  pure def expectedStructural(registryIndex: int, envelopeIndex: int): int = {
    if (Set(2,3,4,5).contains(registryIndex)) 1
    else if (Set(7,8,9,10,12).contains(registryIndex)) 2
    else if (registryIndex == 1) { if (envelopeIndex == 4) 3 else 4 }
    else if (registryIndex == 6) {
      if (envelopeIndex == 4) 3
      else if (Set(1,2,29).contains(envelopeIndex)) 4
      else if (envelopeIndex == 3) 5
      else 6
    }
    else if (registryIndex == 13 and envelopeIndex == 1) 5
    else baseStructuralExpected[envelopeIndex]
  }

  pure val sourceIssues: List[int] = List(0,7,7,7,10,11,13,16,14,24,6,8)

  pure def expectedBound(envelopeIndex: int, bindingIndex: int, sourceIndex: int): int = {
    val structural = baseStructuralExpected[envelopeIndex]
    val admittedSource = if (sourceIndex == 0) 0 else 15
    if (structural != 0) structural
    else if (bindingIndex == 1) 11
    else if (Set(2,3,4).contains(bindingIndex)) 10
    else if (bindingIndex == 5) {
      if (envelopeIndex == 9) 14
      else if (Set(18,19,20,21,22,23).contains(envelopeIndex)) 16
      else admittedSource
    }
    else if (bindingIndex == 6) admittedSource
    else if (bindingIndex == 7) { if (envelopeIndex == 0) 13 else 12 }
    else if (bindingIndex == 9) { if (envelopeIndex == 10) admittedSource else 12 }
    else if (envelopeIndex == 0) admittedSource
    else 12
  }

  run duplicateRegistryTest = assert(and {
    structuralCaseCode(2, 0) == 1,
    structuralCaseCode(3, 0) == 1,
    structuralCaseCode(4, 0) == 1,
    structuralCaseCode(5, 0) == 1,
    // Even malformed duplicate identities cannot make order choose an entry.
    structuralCode({ snapshot: 1, definitions: List(
      baseDefinition.with("key", baseKey.with("version", 0)),
      baseDefinition.with("key", baseKey.with("version", 0))) }, baseEnvelope) == 1,
  })

  run digestAndVersionTest = assert(and {
    structuralCaseCode(0, 1) == 4,
    structuralCaseCode(0, 3) == 5,
    structuralCaseCode(13, 1) == 5,
    structuralCode(registryCase(13), envelopeCase(1).with("definitionDigest", repeatedDigest(2))) == 0,
    boundCode({ registry: registryCase(13), bindings: List(baseBinding),
      environment: D::fixtureEnvironment(List(basePremise)) },
      { envelope: envelopeCase(1).with("definitionDigest", repeatedDigest(2)), premise: basePremise }) == 12,
    structuralCaseCode(7, 0) == 2,
    structuralCode(baseRegistry.with("definitions", List(baseDefinition.with("digest", repeatedDigest(256)))), baseEnvelope) == 2,
    structuralCaseCode(12, 0) == 2,
  })

  run unknownKindTest = assert(and {
    structuralCaseCode(0, 2) == 4,
    structuralCaseCode(1, 0) == 4,
    structuralCaseCode(11, 2) == 4,
    // A neighboring catalogue name is no implicit refinement or interpretation.
    structuralCode(registryCase(11), baseEnvelope.with("key", baseKey.with("symbol", baseKey.symbol.with("name", "other")))) == 7,
  })

  run declaredSignatureTest = assert(and {
    structuralCode(baseRegistry.with("definitions", List(baseDefinition.with("roles",
      List(propertyRole, recipientRole, payerRole)))), baseEnvelope) == 7,
    structuralCaseCode(0, 5) == 7,
    structuralCaseCode(0, 6) == 7,
    structuralCaseCode(0, 7) == 8,
    structuralCaseCode(0, 8) == 8,
    structuralCaseCode(0, 33) == 8,
    structuralCaseCode(0, 35) == 8,
    structuralCaseCode(8, 0) == 2,
    structuralCaseCode(9, 0) == 2,
  })

  run unresolvedMandateTest = {
    val symbol = { space: "synthetic.act", name: "revoke_mandate" }
    val definition = baseDefinition.with("key", baseKey.with("symbol", symbol))
      .with("roles", List({ role: "mandate", kind: UnresolvedSort }))
    val cast = { kind: A::ObligationRef, symbol: { space: "mandate", name: "M" } }
    val act = {
      operation: { symbol: symbol, parameters: List({ role: "mandate", kind: A::ObligationRef }) },
      operands: List({ role: "mandate", referent: cast })
    }
    val envelope = baseEnvelope.with("key", definition.key).with("act", act)
    assert(and {
      A::validAct(act),
      structuralCode({ snapshot: 1, definitions: List(definition) }, envelope) == 6,
      structuralCaseCode(6, 0) == 6,
      structuralCaseCode(6, 8) == 6,
    })
  }

  run sameSortRoleSwapTest = assert(and {
    structuralCaseCode(0, 9) == 0,
    not(J::sameScopeTarget(project(baseEnvelope), project(envelopeCase(9)))),
    boundCaseCode(9, 0, 0) == 12,
    // Matching trusted row isolates the target-projection guard itself.
    boundCaseCode(9, 5, 0) == 14,
    boundCaseCode(9, 6, 0) == 0,
  })

  run omittedQualificationBindingTest = assert(
    Set(10,11,12,13,34).forall(e => and {
      structuralCaseCode(0, e) == 0,
      J::sameScopeTarget(project(baseEnvelope), project(envelopeCase(e))),
      not(sameEnvelope(baseEnvelope, envelopeCase(e))),
      boundCaseCode(e, 0, 0) == 12,
      boundCaseCode(e, 5, 0) == 0,
    }))

  run snapshotBindingTest = assert(and {
    Set(14,15,16,17,18,19,20,21,22,23).forall(e => and {
      J::sameScopeTarget(project(baseEnvelope), project(envelopeCase(e))),
      boundCaseCode(e, 0, 0) == 12,
      boundCaseCode(e, 6, 0) == 0,
    }),
    // Exact trusted envelope/premise binding alone does not align scope fields.
    Set(18,19,20,21,22,23).forall(e => boundCaseCode(e, 5, 0) == 16),
    contextWellFormed(baseContext.with("recordedAt", 5)),
  })

  run bindingIdentityTest = assert(and {
    boundCaseCode(0, 1, 0) == 11,
    Set(2,3,4).forall(b => boundCaseCode(0, b, 0) == 10),
    boundCaseCode(0, 7, 0) == 13,
    boundCaseCode(0, 8, 0) == 0,
    boundCaseCode(0, 9, 0) == 12,
    boundCaseCode(10, 9, 0) == 0,
  })

  run baseAdmissionTest = assert(and {
    boundCaseCode(0, 0, 0) == 0,
    1.to(11).forall(s => and {
      boundCaseCode(0, 0, s) == 15,
      boundCaseIssue(0, 0, s) == sourceIssues[s],
      boundCaseCode(9, 6, s) == 15,
    }),
  })

  run multipleSourcesTest = {
    val second = D::structuredPremise(2, A::Perform(baseAct))
    val raw = second.request.record
    val secondPremise = D::withRaw(second, raw.with("provenance", raw.provenance.with("interpretationId", 1)))
    val env = D::fixtureEnvironment(List(basePremise, secondPremise))
      .with("currentVersions", List(D::pinOf(basePremise)))
    val authority = {
      registry: baseRegistry,
      bindings: List(baseBinding, { envelope: baseEnvelope, premise: secondPremise }),
      environment: env
    }
    assert(and {
      not(J::sameSource(basePremise.request.record.provenance.source, secondPremise.request.record.provenance.source)),
      boundCode(authority, { envelope: baseEnvelope, premise: basePremise }) == 0,
      boundCode(authority, { envelope: baseEnvelope, premise: secondPremise }) == 0,
    })
  }

  run emptySchemaAndZeroSnapshotTest = {
    val emptyAct = baseAct.with("operation", baseAct.operation.with("parameters", List())).with("operands", List())
    val registry = { snapshot: 0, definitions: List(baseDefinition.with("roles", List())) }
    val envelope = baseEnvelope.with("registrySnapshot", 0).with("act", emptyAct).with("qualifications", List())
    assert(and {
      structuralCode(registry, envelope) == 0,
      structuralCaseCode(0, 34) == 0,
      signatureOf(List()) == ResolvedSignature(List()),
    })
  }

  run malformedEnvelopeTest = assert(and {
    Set(24,25,26,27,28,30,31,32).forall(e => structuralCaseCode(0, e) == 9),
    structuralCaseCode(0, 4) == 3,
    structuralCaseCode(0, 29) == 4,
    not(contextWellFormed(baseContext.with("effectiveAt", -1))),
    not(qualificationWellFormed(baseQualification.with("version", -1))),
  })

  run fieldwiseEqualityTest = assert(and {
    0.to(35).forall(e => sameEnvelope(envelopeCase(e), envelopeCase(e))),
    1.to(35).forall(e => not(sameEnvelope(baseEnvelope, envelopeCase(e)))),
    0.to(35).forall(e => 0.to(35).forall(f =>
      sameEnvelope(envelopeCase(e), envelopeCase(f)) ==
      sameEnvelope(envelopeCase(f), envelopeCase(e)))),
  })

  run exhaustiveStructuralMatrixTest = assert(
    0.to(13).forall(r => 0.to(35).forall(e =>
      structuralCaseCode(r, e) == expectedStructural(r, e))))

  run exhaustiveBoundMatrixTest = assert(
    0.to(35).forall(e => 0.to(9).forall(b => 0.to(11).forall(s => {
      val expected = expectedBound(e, b, s)
      and {
        boundCaseCode(e, b, s) == expected,
        boundCaseIssue(e, b, s) == (if (expected == 15) sourceIssues[s] else 0),
      }
    }))))

  run decoderBoundariesTest = assert(and {
    Set(-1000,-1,14,1000).forall(r => structuralCaseCode(r, 0) == -1),
    Set(-1000,-1,36,1000).forall(e => structuralCaseCode(0, e) == -1 and boundCaseCode(e, 0, 0) == -1),
    Set(-1,10,1000).forall(b => boundCaseCode(0, b, 0) == -1),
    Set(-1,12,1000).forall(s => boundCaseCode(0, 0, s) == -1 and boundCaseIssue(0, 0, s) == -1),
  })
}
