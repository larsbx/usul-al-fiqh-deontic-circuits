// Independent executable replay of the source-bound derivation contract.
// No proof of a juristic interpretation is inferred from formal acceptance.
module idaDerivation {
  import idaJudgment as J from "./ida-judgment"
  import ida as A from "./ida"

  type Premise = { questionId: int, request: J::Request }
  type KnownConclusion = { questionId: int, question: J::Question, answer: J::Answer, scope: J::Scope }
  type Conclusion = NoConclusion | KnownConclusionValue(KnownConclusion)
  type EvidenceClass = Supported | EvidenceMissing | EvidenceSuspended | Disputed | Unauthenticated
  type VersionPin = { profile: int, profileVersion: int, interpretationId: int, interpretationVersion: int }
  type EvidenceDecision = { premise: Premise, classification: EvidenceClass }
  type Environment = {
    registry: J::Registry, authenticatedSources: List[J::SourceRef],
    currentVersions: List[VersionPin], evidence: List[EvidenceDecision], implementationRevision: str
  }
  type Issue = RegistryRejected(J::Rejection) | BadSourceRule | SourceUnauthenticated
    | StaleInterpretation | ConflictingVersions | MissingEvidence | ConflictingEvidence
    | EvidenceMismatch | DisputedEvidence | SuspendedEvidence | UnauthenticatedEvidence
    | MissingRuling | SuspendedRuling | OutOfScope | ConflictingAnswers | MalformedProgram | BadEnvironment
  type Evaluation = { conclusion: Conclusion, issues: List[Issue], provenance: List[Premise] }
  type AnswerCombination = AnswerConflict | CombinedAnswer(J::Answer)
  type Instruction = Source(Premise) | Both({ left: int, right: int })
  type Program = List[Instruction]
  type Machine = { nodes: List[Evaluation], structurallyValid: bool }
  type Receipt = { environment: Environment, program: Program, evaluation: Evaluation }
  type LeafFixture = { environment: Environment, premise: Premise }
  type TreeFixture = { environment: Environment, first: Premise, middle: Premise, last: Premise }

  pure def samePremise(left: Premise, right: Premise): bool = and {
    left.questionId == right.questionId,
    left.request.snapshot == right.request.snapshot,
    left.request.entryId == right.request.entryId,
    J::sameRecord(left.request.record, right.request.record),
  }
  pure def sourceAuthenticated(env: Environment, source: J::SourceRef): bool =
    env.authenticatedSources.select(reference => J::sameSource(reference, source)).length() > 0
  pure def matchingVersions(env: Environment, premise: Premise): List[VersionPin] =
    env.currentVersions.select(pin => and {
      pin.profile == premise.request.record.scope.profile,
      pin.interpretationId == premise.request.record.provenance.interpretationId,
    })
  pure def currentInterpretation(env: Environment, premise: Premise): bool = {
    val pins = matchingVersions(env, premise)
    pins.length() == 1 and and {
      pins.head().profileVersion == premise.request.record.scope.profileVersion,
      pins.head().interpretationVersion == premise.request.record.provenance.interpretationVersion,
    }
  }
  pure def matchingEvidence(env: Environment, premise: Premise): List[EvidenceDecision] =
    env.evidence.select(decision => decision.premise.request.entryId == premise.request.entryId)
  pure def supportedEvidence(env: Environment, premise: Premise): bool = {
    val decisions = matchingEvidence(env, premise)
    decisions.length() == 1 and and {
      samePremise(decisions.head().premise, premise), decisions.head().classification == Supported,
    }
  }
  pure def blocked(provenance: List[Premise], issues: List[Issue]): Evaluation =
    { conclusion: NoConclusion, issues: issues, provenance: provenance }
  pure def conclusionTyped(conclusion: Conclusion): bool = match conclusion {
    | NoConclusion => false
    | KnownConclusionValue(value) => J::payloadFits(value.question, J::Known(value.answer))
  }
  pure def accepted(evaluation: Evaluation): bool =
    evaluation.issues.length() == 0 and conclusionTyped(evaluation.conclusion)
  pure def classification(evaluation: Evaluation): J::Status =
    if (accepted(evaluation)) J::Admitted else J::Candidate
  pure def scopeCompatible(left: J::Scope, right: J::Scope): bool =
    J::sameScope(left, right)
  pure def sameQuestionScope(left: KnownConclusion, right: KnownConclusion): bool = and {
    left.questionId == right.questionId, left.question == right.question,
    scopeCompatible(left.scope, right.scope),
  }
  pure def toAlgebra(hukm: J::Hukm): A::Hukm = match hukm {
    | Haram => A::H | Makruh => A::K | Mubah => A::M | Mandub => A::N | Wajib => A::W
  }
  pure def fromAlgebra(hukm: A::Hukm): J::Hukm = match hukm {
    | H => J::Haram | K => J::Makruh | M => J::Mubah | N => J::Mandub | W => J::Wajib
  }
  pure def conjoinAnswers(question: J::Question, left: J::Answer, right: J::Answer): AnswerCombination =
    if (not(J::payloadFits(question, J::Known(left))) or not(J::payloadFits(question, J::Known(right)))) AnswerConflict
    else match left {
      | TaklifiAnswer(leftSet) => match right {
        | TaklifiAnswer(rightSet) => match A::refine(A::zeroKey, A::Known(leftSet.map(toAlgebra)), A::zeroKey, A::Known(rightSet.map(toAlgebra))) {
          | RKnown(result) => CombinedAnswer(J::TaklifiAnswer(result.map(fromAlgebra)))
          | _ => AnswerConflict
        }
        | _ => AnswerConflict
      }
      | _ => if (left == right) CombinedAnswer(left) else AnswerConflict
    }
  pure def knownOf(questionId: int, record: J::TypedRecord): Conclusion = match record.payload {
    | Known(answer) => KnownConclusionValue({ questionId: questionId, question: record.question, answer: answer, scope: record.scope })
    | _ => NoConclusion
  }
  pure def environmentNaturals(env: Environment): bool = and {
    env.registry.snapshot >= 0,
    env.implementationRevision != "",
    env.authenticatedSources.foldl(true, (ok, source) => ok and J::sourceNaturals(source)),
    env.currentVersions.foldl(true, (ok, pin) => ok and and {
      pin.profile >= 0, pin.profileVersion >= 0, pin.interpretationId >= 0, pin.interpretationVersion >= 0,
    }),
    env.evidence.foldl(true, (ok, decision) => ok and and {
      decision.premise.questionId >= 0, J::boundaryNaturals(env.registry, decision.premise.request),
    }),
  }
  pure def evaluateSource(env: Environment, premise: Premise): Evaluation = {
    val provenance = List(premise)
    if (not(environmentNaturals(env)) or premise.questionId < 0) blocked(provenance, List(BadEnvironment))
    else match J::validate(env.registry, premise.request) {
      | Rejected(reason) => blocked(provenance, List(RegistryRejected(reason)))
      | Accepted(receipt) => {
        val record = receipt.record
        val pins = matchingVersions(env, premise)
        val decisions = matchingEvidence(env, premise)
        if (record.provenance.premises.length() != 0 or record.provenance.ruleId != 1) blocked(provenance, List(BadSourceRule))
        else if (not(sourceAuthenticated(env, record.provenance.source))) blocked(provenance, List(SourceUnauthenticated))
        else if (pins.length() > 1) blocked(provenance, List(ConflictingVersions))
        else if (not(currentInterpretation(env, premise))) blocked(provenance, List(StaleInterpretation))
        else if (decisions.length() == 0) blocked(provenance, List(MissingEvidence))
        else if (decisions.length() != 1) blocked(provenance, List(ConflictingEvidence))
        else if (not(samePremise(decisions.head().premise, premise))) blocked(provenance, List(EvidenceMismatch))
        else match decisions.head().classification {
          | EvidenceMissing => blocked(provenance, List(MissingEvidence))
          | EvidenceSuspended => blocked(provenance, List(SuspendedEvidence))
          | Disputed => blocked(provenance, List(DisputedEvidence))
          | Unauthenticated => blocked(provenance, List(UnauthenticatedEvidence))
          | Supported => match record.payload {
            | NoRuling => blocked(provenance, List(MissingRuling))
            | Suspended => blocked(provenance, List(SuspendedRuling))
            | Known(answer) => { conclusion: KnownConclusionValue({ questionId: premise.questionId, question: record.question, answer: answer, scope: record.scope }), issues: List(), provenance: provenance }
          }
        }
      }
    }
  }
  pure def homogeneous(provenance: List[Premise]): bool =
    provenance.length() > 0 and provenance.foldl(true, (ok, premise) => ok and and {
      premise.questionId == provenance.head().questionId,
      premise.request.record.questionCode == provenance.head().request.record.questionCode,
      scopeCompatible(premise.request.record.scope, provenance.head().request.record.scope),
    })
  pure def requireBoth(left: Evaluation, right: Evaluation): Evaluation = {
    val provenance = left.provenance.concat(right.provenance)
    val issues = left.issues.concat(right.issues)
    if (not(homogeneous(provenance))) blocked(provenance, List(OutOfScope).concat(issues))
    else if (issues.length() > 0) blocked(provenance, issues)
    else match left.conclusion {
      | NoConclusion => blocked(provenance, List(MalformedProgram))
      | KnownConclusionValue(a) => match right.conclusion {
        | NoConclusion => blocked(provenance, List(MalformedProgram))
        | KnownConclusionValue(b) =>
          if (not(sameQuestionScope(a, b))) blocked(provenance, List(OutOfScope))
          else match conjoinAnswers(a.question, a.answer, b.answer) {
            | AnswerConflict => blocked(provenance, List(ConflictingAnswers))
            | CombinedAnswer(answer) => {
              conclusion: KnownConclusionValue(a.with("answer", answer)),
              issues: List(), provenance: provenance,
            }
          }
      }
    }
  }
  pure val emptyMachine: Machine = { nodes: List(), structurallyValid: true }
  pure def advance(env: Environment, machine: Machine, instruction: Instruction): Machine =
    if (not(machine.structurallyValid)) machine
    else match instruction {
      | Source(premise) => machine.with("nodes", machine.nodes.append(evaluateSource(env, premise)))
      | Both(refs) =>
        if (refs.left < 0 or refs.right < 0 or refs.left >= machine.nodes.length() or refs.right >= machine.nodes.length())
          machine.with("structurallyValid", false)
        else machine.with("nodes", machine.nodes.append(requireBoth(machine.nodes.nth(refs.left), machine.nodes.nth(refs.right))))
    }
  pure def execute(env: Environment, program: Program): Machine =
    program.foldl(emptyMachine, (machine, instruction) => advance(env, machine, instruction))
  pure def evaluate(env: Environment, program: Program): Evaluation = {
    val machine = execute(env, program)
    if (not(machine.structurallyValid) or machine.nodes.length() == 0)
      blocked(machine.nodes.foldl(List(), (provenance, node) => provenance.concat(node.provenance)), List(MalformedProgram))
    else machine.nodes.nth(machine.nodes.length() - 1)
  }
  pure def alternatives(env: Environment, programs: List[Program]): List[Evaluation] =
    programs.foldl(List(), (outputs, program) => outputs.append(evaluate(env, program)))
  pure def issueReceipt(env: Environment, program: Program): Receipt =
    { environment: env, program: program, evaluation: evaluate(env, program) }
  pure def replay(current: Environment, receipt: Receipt): bool = and {
    current == receipt.environment,
    receipt.evaluation == evaluate(current, receipt.program),
    accepted(receipt.evaluation),
  }
  pure def issueCode(issue: Issue): int = match issue {
    | RegistryRejected(reason) => J::resultCode(J::Rejected(reason))
    | BadSourceRule => 9 | SourceUnauthenticated => 10 | StaleInterpretation => 11
    | ConflictingVersions => 12 | MissingEvidence => 13 | ConflictingEvidence => 14
    | EvidenceMismatch => 15 | DisputedEvidence => 16 | SuspendedEvidence => 17
    | UnauthenticatedEvidence => 18 | MissingRuling => 19 | SuspendedRuling => 20
    | OutOfScope => 21 | ConflictingAnswers => 22 | MalformedProgram => 23 | BadEnvironment => 24
  }
  pure def outcomeCode(evaluation: Evaluation): int =
    if (accepted(evaluation)) 0 else if (evaluation.issues.length() > 0) issueCode(evaluation.issues.head()) else 23
  pure def knownAnswerProjection(conclusion: Conclusion): int = match conclusion {
    | NoConclusion => 0
    | KnownConclusionValue(value) => match J::encodePayload(J::Known(value.answer)) {
      | BadPayloadEncoding => 0 | PayloadCode(code) => code + 1
    }
  }
  pure def projection(evaluation: Evaluation, coordinate: int): int =
    if (coordinate == 0) outcomeCode(evaluation)
    else if (coordinate == 1) { if (classification(evaluation) == J::Admitted) 1 else 0 }
    else if (coordinate == 2) match evaluation.conclusion { | NoConclusion => 0 | KnownConclusionValue(value) => value.questionId + 1 }
    else if (coordinate == 3) match evaluation.conclusion { | NoConclusion => 0 | KnownConclusionValue(value) => J::encodeQuestion(value.question) + 1 }
    else if (coordinate == 4) knownAnswerProjection(evaluation.conclusion)
    else if (coordinate == 5) evaluation.provenance.length()
    else if (coordinate == 6) evaluation.issues.foldl(0, (acc, issue) => acc * 32 + issueCode(issue))
    else if (coordinate == 7) evaluation.provenance.foldl(0, (acc, premise) => acc * 16 + premise.request.entryId)
    else Set().getOnlyElement()

  // Synthetic bytes are hashed independently by the source-authentication adapter.
  pure val syntheticSource1: J::SourceRef = {
    sourceId: 1,
    sourceHash: List(186,29,212,220,231,84,88,79,207,141,146,254,115,4,103,238,6,112,140,192,4,251,252,68,37,94,197,6,229,77,11,90),
    sourceBytes: 4, passageStart: 1, passageEnd: 3,
    passageHash: List(65,165,86,179,131,19,10,60,154,253,106,235,174,55,83,203,233,237,227,132,205,125,78,197,92,180,180,31,175,219,49,5),
  }
  pure val syntheticSource2: J::SourceRef = {
    sourceId: 2,
    sourceHash: List(15,1,238,239,235,128,119,75,25,217,36,106,154,23,175,166,163,180,228,198,32,60,70,245,81,18,23,166,136,3,230,222),
    sourceBytes: 4, passageStart: 1, passageEnd: 3,
    passageHash: List(207,58,188,131,38,100,107,153,10,73,22,170,34,235,191,13,208,89,233,123,250,27,82,242,175,170,149,135,191,14,196,77),
  }
  pure def sourceCell(identity: int, coordinate: int): int = {
    val source = if (identity == 1) syntheticSource1 else syntheticSource2
    List(source.sourceId).concat(source.sourceHash).concat(List(source.sourceBytes, source.passageStart, source.passageEnd)).concat(source.passageHash).nth(coordinate)
  }
  pure def fixturePremise(questionCode: int, answerCode: int, identity: int): Premise = {
    val baseline = J::syntheticBaseline(questionCode)
    val source = if (identity % 2 == 1) syntheticSource1 else syntheticSource2
    val raw = baseline.with("answerCode", answerCode).with("provenance", baseline.provenance.with("source", source).with("interpretationId", identity))
    { questionId: 7, request: { snapshot: 1, entryId: identity, record: raw } }
  }
  pure def pinOf(premise: Premise): VersionPin = {
    profile: premise.request.record.scope.profile,
    profileVersion: premise.request.record.scope.profileVersion,
    interpretationId: premise.request.record.provenance.interpretationId,
    interpretationVersion: premise.request.record.provenance.interpretationVersion,
  }
  pure def fixtureEnvironment(premises: List[Premise]): Environment = {
    registry: { snapshot: 1, entries: premises.foldl(List(), (entries, premise) => entries.append({ entryId: premise.request.entryId, status: J::Admitted, record: premise.request.record })) },
    authenticatedSources: premises.foldl(List(), (sources, premise) => sources.append(premise.request.record.provenance.source)),
    currentVersions: premises.foldl(List(), (pins, premise) => pins.append(pinOf(premise))),
    evidence: premises.foldl(List(), (decisions, premise) => decisions.append({ premise: premise, classification: Supported })),
    implementationRevision: "derivation-v1",
  }
  pure def knownAnswerCode(questionCode: int): int = if (questionCode == 0) 16 else if (questionCode == 4) 36 else 34
  pure def withRaw(premise: Premise, raw: J::RawRecord): Premise = premise.with("request", premise.request.with("record", raw))
  pure def sourceProgram(premise: Premise): Program = List(Source(premise))
  pure def pairProgram(left: Premise, right: Premise): Program = List(Source(left), Source(right), Both({ left: 0, right: 1 }))
  pure def withEntryStatus(env: Environment, identity: int, status: J::Status): Environment =
    env.with("registry", env.registry.with("entries", env.registry.entries.foldl(List(), (entries, entry) => entries.append(if (entry.entryId == identity) entry.with("status", status) else entry))))
  pure def withEvidenceClass(env: Environment, identity: int, evidenceClass: EvidenceClass): Environment =
    env.with("evidence", env.evidence.foldl(List(), (decisions, decision) => decisions.append(if (decision.premise.request.entryId == identity) decision.with("classification", evidenceClass) else decision)))
  pure def changedSource(source: J::SourceRef, caseId: int): J::SourceRef =
    if (caseId == 13) source.with("sourceId", 99)
    else if (caseId == 14) source.with("sourceHash", J::syntheticDigest(1))
    else if (caseId == 15) source.with("sourceBytes", 5)
    else if (caseId == 16) source.with("passageStart", 2)
    else if (caseId == 17) source.with("passageEnd", 4)
    else source.with("passageHash", J::syntheticDigest(1))
  pure def leafFixture(questionCode: int, caseId: int): LeafFixture = {
    val premise = fixturePremise(questionCode, knownAnswerCode(questionCode), 1)
    val env = fixtureEnvironment(List(premise))
    val raw = premise.request.record
    val decision = env.evidence.head()
    val pin = env.currentVersions.head()
    val source = raw.provenance.source
    val changedPremise =
      if (caseId == 21) withRaw(premise, raw.with("answerCode", 0))
      else if (caseId == 22) withRaw(premise, raw.with("answerCode", 32))
      else if (caseId == 23) withRaw(premise, raw.with("provenance", raw.provenance.with("premises", List(2))))
      else if (caseId == 24) withRaw(premise, raw.with("provenance", raw.provenance.with("ruleId", 2)))
      else if (caseId == 26) premise.with("request", premise.request.with("snapshot", 2))
      else if (caseId == 27) withRaw(premise, raw.with("provenance", raw.provenance.with("source", source.with("sourceHash", J::syntheticDigest(0)))))
      else if (caseId == 28) withRaw(premise, raw.with("provenance", raw.provenance.with("source", source.with("passageStart", 2))))
      else if (caseId == 29) withRaw(premise, raw.with("provenance", raw.provenance.with("interpretationVersion", 2)))
      else if (caseId == 30) withRaw(premise, raw.with("provenance", raw.provenance.with("grade", J::Zann)))
      else premise
    val changedEnv =
      if (caseId == 1) withEntryStatus(env, 1, J::Candidate)
      else if (caseId == 2) withEntryStatus(env, 1, J::Quarantined)
      else if (caseId == 3) withEntryStatus(env, 1, J::Revoked)
      else if (caseId == 4) env.with("authenticatedSources", List())
      else if (caseId == 5) env.with("authenticatedSources", List(source.with("sourceHash", J::syntheticDigest(0))))
      else if (caseId == 6) env.with("authenticatedSources", List(source.with("passageStart", 2)))
      else if (caseId == 7) env.with("authenticatedSources", List(source.with("passageHash", J::syntheticDigest(0))))
      else if (caseId == 8) env.with("currentVersions", List())
      else if (caseId == 9) env.with("currentVersions", List(pin.with("profileVersion", 2)))
      else if (caseId == 10) env.with("currentVersions", List(pin.with("interpretationVersion", 2)))
      else if (caseId == 11) env.with("currentVersions", List(pin, pin))
      else if (caseId == 12) env.with("currentVersions", List(pin, pin.with("interpretationVersion", 2)))
      else if (caseId == 13) env.with("evidence", List())
      else if (caseId == 14) env.with("evidence", List(decision, decision))
      else if (caseId == 15) env.with("evidence", List(decision, decision.with("classification", Disputed)))
      else if (caseId == 16) withEvidenceClass(env, 1, Disputed)
      else if (caseId == 17) withEvidenceClass(env, 1, EvidenceMissing)
      else if (caseId == 18) withEvidenceClass(env, 1, EvidenceSuspended)
      else if (caseId == 19) withEvidenceClass(env, 1, Unauthenticated)
      else if (caseId == 20) env.with("evidence", List(decision.with("premise", premise.with("questionId", 8))))
      else if (caseId >= 21 and caseId <= 24) fixtureEnvironment(List(changedPremise))
      else if (caseId == 25) env.with("implementationRevision", "")
      else if (caseId == 31) env.with("evidence", List(decision.with("premise", withRaw(premise, raw.with("provenance", raw.provenance.with("grade", J::Zann))))))
      else env
    { environment: changedEnv, premise: changedPremise }
  }
  pure def leafOutcome(questionCode: int, caseId: int): Evaluation = {
    val fixture = leafFixture(questionCode, caseId)
    evaluateSource(fixture.environment, fixture.premise)
  }
  pure val leafCodes: List[int] = List(0,7,7,7,10,10,10,10,11,11,11,12,12,13,14,14,16,13,17,18,15,19,20,9,9,24,4,8,8,8,8,15)
  pure def pairOutcome(questionCode: int, leftCode: int, rightCode: int): Evaluation = {
    val left = fixturePremise(questionCode, leftCode, 1)
    val right = fixturePremise(questionCode, rightCode, 2)
    evaluate(fixtureEnvironment(List(left, right)), pairProgram(left, right))
  }
  pure def typedAnswers(questionCode: int): List[int] = if (questionCode == 4) List(0,32,35,36) else List(0,32,33,34)
  pure def typedOutcome(questionCode: int, caseId: int): Evaluation =
    pairOutcome(questionCode, typedAnswers(questionCode).nth(caseId / 4), typedAnswers(questionCode).nth(caseId % 4))
  pure def scopeRight(caseId: int): Premise = {
    val premise = fixturePremise(1, 34, 2)
    if (caseId == 0) premise
    else if (caseId == 1) premise.with("questionId", 8)
    else if (caseId == 2) withRaw(premise, premise.request.record.with("questionCode", 2))
    else withRaw(premise, premise.request.record.with("scope", J::syntheticRecordVariant(1, caseId).scope))
  }
  pure def scopeOutcome(caseId: int): Evaluation = {
    val left = fixturePremise(1, 34, 1)
    val right = scopeRight(caseId)
    evaluate(fixtureEnvironment(List(left, right)), pairProgram(left, right))
  }
  pure def treeFixture(caseId: int): TreeFixture = {
    val first = fixturePremise(0, 31, 1)
    val original = fixturePremise(0, 16, 2)
    val last = fixturePremise(0, 16, 3)
    val middle =
      if (caseId == 1) withRaw(original, original.request.record.with("answerCode", 0))
      else if (caseId == 2) withRaw(original, original.request.record.with("answerCode", 32))
      else if (caseId == 7) original.with("questionId", 8)
      else if (caseId == 8) withRaw(original, original.request.record.with("answerCode", 1))
      else original
    val baseline = fixtureEnvironment(List(first, middle, last))
    val env =
      if (caseId == 3) withEntryStatus(baseline, 2, J::Candidate)
      else if (caseId == 4) withEvidenceClass(baseline, 2, Disputed)
      else if (caseId == 5) baseline.with("authenticatedSources", baseline.authenticatedSources.select(source => source.sourceId != 2))
      else if (caseId == 6) baseline.with("currentVersions", baseline.currentVersions.foldl(List(), (pins, pin) => pins.append(if (pin.interpretationId == 2) pin.with("interpretationVersion", 2) else pin)))
      else if (caseId == 9) withEvidenceClass(baseline, 2, EvidenceMissing)
      else baseline
    { environment: env, first: first, middle: middle, last: last }
  }
  pure def treeProgram(fixture: TreeFixture, shape: int): Program =
    if (shape == 0) List(Source(fixture.first), Source(fixture.middle), Both({ left: 0, right: 1 }), Source(fixture.last), Both({ left: 2, right: 3 }))
    else if (shape == 1) List(Source(fixture.first), Source(fixture.middle), Source(fixture.last), Both({ left: 1, right: 2 }), Both({ left: 0, right: 3 }))
    else List(Source(fixture.first), Source(fixture.middle), Source(fixture.last), Both({ left: 0, right: 1 }), Both({ left: 1, right: 2 }), Both({ left: 3, right: 4 }))
  pure def treeOutcome(caseId: int, shape: int): Evaluation = {
    val fixture = treeFixture(caseId)
    evaluate(fixture.environment, treeProgram(fixture, shape))
  }
  pure def alternativeOutcomes(scenario: int): List[Evaluation] = {
    val left = fixturePremise(0, 1, 1)
    val right = fixturePremise(0, 16, 2)
    val baseline = fixtureEnvironment(List(left, right))
    val env = if (scenario == 0) baseline else withEntryStatus(baseline, 2, J::Candidate)
    alternatives(env, List(sourceProgram(left), sourceProgram(right)))
  }
  pure val baselineReceipt: Receipt = {
    val left = fixturePremise(0, 31, 1)
    val right = fixturePremise(0, 16, 2)
    issueReceipt(fixtureEnvironment(List(left, right)), pairProgram(left, right))
  }
  pure def changedConclusion(conclusion: Conclusion, caseId: int): Conclusion = match conclusion {
    | NoConclusion => NoConclusion
    | KnownConclusionValue(value) => KnownConclusionValue(
      if (caseId == 7) value.with("answer", J::TaklifiAnswer(Set(J::Haram)))
      else if (caseId == 9) value.with("scope", value.scope.with("context", 2))
      else value.with("questionId", 8))
  }
  pure def replayCase(caseId: int): bool = {
    val env = baselineReceipt.environment
    val current =
      if (caseId == 1) env.with("implementationRevision", "derivation-v2")
      else if (caseId == 2) env.with("registry", env.registry.with("snapshot", 2))
      else if (caseId == 3) env.with("authenticatedSources", List())
      else if (caseId == 4) env.with("currentVersions", List(env.currentVersions.head(), env.currentVersions.nth(1).with("interpretationVersion", 2)))
      else if (caseId == 5) withEvidenceClass(env, 2, Disputed)
      else if (caseId == 6) withEntryStatus(env, 2, J::Candidate)
      else env
    val output = baselineReceipt.evaluation
    val receipt =
      if (caseId == 7 or caseId == 9 or caseId == 12) baselineReceipt.with("evaluation", output.with("conclusion", changedConclusion(output.conclusion, caseId)))
      else if (caseId == 8) baselineReceipt.with("evaluation", output.with("provenance", List(output.provenance.head())))
      else if (caseId == 10) baselineReceipt.with("environment", env.with("implementationRevision", "derivation-v2"))
      else if (caseId == 11) baselineReceipt.with("program", sourceProgram(output.provenance.head()))
      else if (caseId == 13) baselineReceipt.with("evaluation", output.with("issues", List(MissingRuling)))
      else if (caseId == 14) baselineReceipt.with("evaluation", output.with("conclusion", NoConclusion))
      else if (caseId == 15) baselineReceipt.with("environment", env.with("evidence", List(env.evidence.head())))
      else baselineReceipt
    replay(current, receipt)
  }

  // Full-record assertions complement (and are stronger than) the exported projections.
  pure def preservesSource(premise: Premise, output: Evaluation): bool = match J::decodeRecord(premise.request.record) {
    | BadRecord => false
    | RecordValue(record) => and {
      accepted(output), output.issues == List(), output.provenance == List(premise),
      output.conclusion == knownOf(premise.questionId, record), classification(output) == J::Admitted,
    }
  }
  pure def isBlocked(output: Evaluation, provenance: List[Premise], issues: List[Issue]): bool = and {
    output == { conclusion: NoConclusion, issues: issues, provenance: provenance },
    not(accepted(output)), classification(output) == J::Candidate,
  }
  pure def decodedQuestion(questionCode: int): J::Question = match J::decodeQuestion(questionCode) {
    | QuestionValue(question) => question | BadQuestion => Set().getOnlyElement()
  }
  pure def decodedAnswer(questionCode: int, answerCode: int): J::Answer = match J::decodePayload(decodedQuestion(questionCode), answerCode) {
    | PayloadValue(payload) => match payload { | Known(answer) => answer | _ => Set().getOnlyElement() }
    | BadPayload => Set().getOnlyElement()
  }
  pure def payloadIssues(answerCode: int): List[Issue] =
    if (answerCode == 0) List(MissingRuling) else if (answerCode == 32) List(SuspendedRuling) else List()
  pure def expectedKnown(questionCode: int, answer: J::Answer, provenance: List[Premise]): Evaluation = {
    conclusion: KnownConclusionValue({ questionId: 7, question: decodedQuestion(questionCode), answer: answer, scope: provenance.head().request.record.scope }),
    issues: List(), provenance: provenance,
  }
  pure def expectedPair(questionCode: int, leftCode: int, rightCode: int): Evaluation = {
    val provenance = List(fixturePremise(questionCode, leftCode, 1), fixturePremise(questionCode, rightCode, 2))
    val inherited = payloadIssues(leftCode).concat(payloadIssues(rightCode))
    if (inherited.length() > 0) blocked(provenance, inherited)
    else if (questionCode == 0) {
      val intersection = J::carrier.filter(hukm => (leftCode / J::bit(hukm)) % 2 == 1 and (rightCode / J::bit(hukm)) % 2 == 1)
      if (intersection.size() == 0) blocked(provenance, List(ConflictingAnswers))
      else expectedKnown(questionCode, J::TaklifiAnswer(intersection), provenance)
    } else if (leftCode != rightCode) blocked(provenance, List(ConflictingAnswers))
    else expectedKnown(questionCode, decodedAnswer(questionCode, leftCode), provenance)
  }
  pure def treeExpectedIssues(caseId: int, shape: int): List[Issue] = {
    val issue =
      if (caseId == 1) MissingRuling
      else if (caseId == 2) SuspendedRuling
      else if (caseId == 3) RegistryRejected(J::NotAdmitted)
      else if (caseId == 4) DisputedEvidence
      else if (caseId == 5) SourceUnauthenticated
      else if (caseId == 6) StaleInterpretation
      else if (caseId == 7) OutOfScope
      else if (caseId == 8) ConflictingAnswers
      else MissingEvidence
    if (caseId == 0) List()
    else if (caseId == 7) { if (shape == 2) List(issue, issue, issue) else List(issue, issue) }
    else if (caseId == 8) List(issue)
    else if (shape == 2) List(issue, issue)
    else List(issue)
  }
  pure def treeProvenance(fixture: TreeFixture, shape: int): List[Premise] =
    if (shape == 2) List(fixture.first, fixture.middle, fixture.middle, fixture.last)
    else List(fixture.first, fixture.middle, fixture.last)
  pure def boundedMachineInvariant(env: Environment, machine: Machine, bound: int): bool = and {
    machine.nodes.length() <= bound,
    machine.nodes.foldl(true, (ok, node) => ok and
      (not(accepted(node)) or and {
        homogeneous(node.provenance),
        node.provenance.foldl(true, (trusted, premise) => trusted and accepted(evaluateSource(env, premise))),
      })),
  }

  run derivationSourcePreservationTest = assert(and {
    0.to(4).forall(q => {
      val premise = fixturePremise(q, knownAnswerCode(q), 1)
      preservesSource(premise, evaluateSource(fixtureEnvironment(List(premise)), premise))
    }),
    Set(1,7,42,9001).forall(questionId => {
      val premise = fixturePremise(0, 30, 1).with("questionId", questionId)
      preservesSource(premise, evaluateSource(fixtureEnvironment(List(premise)), premise))
    }),
    Set(0,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,26).forall(caseId => {
      val original = fixturePremise(1, 34, 1)
      val changed = J::syntheticRecordVariant(1, caseId)
      val premise = withRaw(original, changed.with("provenance", changed.provenance.with("source", original.request.record.provenance.source)))
      preservesSource(premise, evaluateSource(fixtureEnvironment(List(premise)), premise))
    }),
  })
  run derivationSourceAuthenticationTest = assert(and {
    13.to(18).forall(caseId => {
      val original = fixturePremise(1, 34, 1)
      val raw = original.request.record
      val premise = withRaw(original, raw.with("provenance", raw.provenance.with("source", changedSource(raw.provenance.source, caseId))))
      val env = fixtureEnvironment(List(premise)).with("authenticatedSources", List(raw.provenance.source))
      isBlocked(evaluateSource(env, premise), List(premise), List(SourceUnauthenticated))
    }),
    0.to(4).forall(q => {
      val fixture = leafFixture(q, 4)
      isBlocked(evaluateSource(fixture.environment, fixture.premise), List(fixture.premise), List(SourceUnauthenticated))
    }),
  })
  run derivationVersionTest = assert(and {
    8.to(12).forall(caseId => {
      val fixture = leafFixture(0, caseId)
      val issue = if (caseId <= 10) StaleInterpretation else ConflictingVersions
      isBlocked(evaluateSource(fixture.environment, fixture.premise), List(fixture.premise), List(issue))
    }),
    {
      val premise = fixturePremise(1, 34, 1)
      val env = fixtureEnvironment(List(premise))
      val stale = env.with("currentVersions", List(env.currentVersions.head().with("interpretationId", 99)))
      isBlocked(evaluateSource(stale, premise), List(premise), List(StaleInterpretation))
    },
  })
  run derivationEvidenceTest = assert(and {
    13.to(20).forall(caseId => {
      val fixture = leafFixture(0, caseId)
      val output = evaluateSource(fixture.environment, fixture.premise)
      and { outcomeCode(output) == leafCodes.nth(caseId), output.conclusion == NoConclusion,
        output.provenance == List(fixture.premise), output.issues.length() == 1, classification(output) == J::Candidate }
    }),
    {
      val premise = fixturePremise(1, 34, 1)
      val env = fixtureEnvironment(List(premise))
      val changed = premise.with("request", premise.request.with("snapshot", 2))
      val mismatch = env.with("evidence", List({ premise: changed, classification: Supported }))
      isBlocked(evaluateSource(mismatch, premise), List(premise), List(EvidenceMismatch))
    },
    {
      val fixture = leafFixture(1, 31)
      isBlocked(evaluateSource(fixture.environment, fixture.premise), List(fixture.premise), List(EvidenceMismatch))
    },
  })
  run derivationNoPromotionTest = assert(and {
    0.to(4).forall(q => Set(1,2,3,21,22).forall(caseId => {
      val fixture = leafFixture(q, caseId)
      val output = evaluateSource(fixture.environment, fixture.premise)
      and { not(accepted(output)), classification(output) == J::Candidate,
        output.conclusion == NoConclusion, output.provenance == List(fixture.premise),
        output.issues.length() == 1, issueCode(output.issues.head()) == leafCodes.nth(caseId) }
    })),
    classification(blocked(List(), List(MissingEvidence))) == J::Candidate,
  })
  run derivationSourceRuleTest = assert(0.to(4).forall(q => Set(23,24).forall(caseId => {
    val fixture = leafFixture(q, caseId)
    isBlocked(evaluateSource(fixture.environment, fixture.premise), List(fixture.premise), List(BadSourceRule))
  })))
  run derivationLeafCasesTest = assert(0.to(4).forall(q => 0.to(31).forall(caseId => {
    val fixture = leafFixture(q, caseId)
    val output = evaluateSource(fixture.environment, fixture.premise)
    and {
      outcomeCode(output) == leafCodes.nth(caseId), output.provenance == List(fixture.premise),
      if (caseId == 0) preservesSource(fixture.premise, output)
      else and { output.conclusion == NoConclusion, output.issues.length() == 1, classification(output) == J::Candidate },
    }
  })))
  run derivationConjunctionTest = assert(0.to(32).forall(a => 0.to(32).forall(b =>
    pairOutcome(0, a, b) == expectedPair(0, a, b))))
  run derivationTypedConjunctionTest = assert(1.to(4).forall(q => 0.to(15).forall(caseId =>
    typedOutcome(q, caseId) == expectedPair(q, typedAnswers(q).nth(caseId / 4), typedAnswers(q).nth(caseId % 4)))))
  run derivationScopeTest = assert(0.to(12).forall(caseId => {
    val left = fixturePremise(1, 34, 1)
    val right = scopeRight(caseId)
    val env = fixtureEnvironment(List(left, right))
    val output = evaluate(env, pairProgram(left, right))
    and {
      preservesSource(left, evaluateSource(env, left)), preservesSource(right, evaluateSource(env, right)),
      if (caseId == 0) output == expectedPair(1, 34, 34)
      else isBlocked(output, List(left, right), List(OutOfScope)),
    }
  }))
  run derivationScopeBeforeTaintTest = assert(Set(0,32).forall(answerCode => {
    val left = fixturePremise(1, answerCode, 1)
    val right = scopeRight(8)
    val env = fixtureEnvironment(List(left, right))
    isBlocked(evaluate(env, pairProgram(left, right)), List(left, right), List(OutOfScope).concat(payloadIssues(answerCode)))
  }))
  run derivationDeepTaintTest = assert(0.to(9).forall(caseId => 0.to(2).forall(shape => {
    val fixture = treeFixture(caseId)
    val program = treeProgram(fixture, shape)
    val output = evaluate(fixture.environment, program)
    val provenance = treeProvenance(fixture, shape)
    and {
      if (caseId == 0) output == expectedKnown(0, J::TaklifiAnswer(Set(J::Wajib)), provenance)
      else isBlocked(output, provenance, treeExpectedIssues(caseId, shape)),
      boundedMachineInvariant(fixture.environment, execute(fixture.environment, program), 6),
    }
  })))
  run derivationAlternativesTest = assert(and {
    0.to(1).forall(scenario => {
      val left = fixturePremise(0, 1, 1)
      val right = fixturePremise(0, 16, 2)
      val outputs = alternativeOutcomes(scenario)
      and {
        outputs.length() == 2, preservesSource(left, outputs.head()),
        if (scenario == 0) preservesSource(right, outputs.nth(1))
        else isBlocked(outputs.nth(1), List(right), List(RegistryRejected(J::NotAdmitted))),
      }
    }),
    outcomeCode(pairOutcome(0, 1, 16)) == 22,
    alternatives(fixtureEnvironment(List()), List()) == List(),
  })
  run derivationReceiptReplayTest = assert(0.to(15).forall(caseId => replayCase(caseId) == (caseId == 0)))
  run derivationGraphTest = assert({
    val premise = fixturePremise(0, 16, 1)
    val env = fixtureEnvironment(List(premise))
    val source = Source(premise)
    and {
      isBlocked(evaluate(env, List()), List(), List(MalformedProgram)),
      isBlocked(evaluate(env, List(Both({ left: 0, right: 0 }))), List(), List(MalformedProgram)),
      Set(-1,1,99).forall(index => {
        val program = List(source, Both({ left: 0, right: index }), source)
        isBlocked(evaluate(env, program), List(premise), List(MalformedProgram))
      }),
      evaluate(env, List(source, Both({ left: 0, right: 0 }))) == expectedKnown(0, J::TaklifiAnswer(Set(J::Wajib)), List(premise, premise)),
      not(homogeneous(List())),
      isBlocked(requireBoth(blocked(List(premise), List()), blocked(List(premise), List())), List(premise, premise), List(MalformedProgram)),
    }
  })
  run derivationQuestionIdentityTest = assert(and {
    Set(0,7,8,42).forall(identity => {
      val premise = fixturePremise(0, 16, 1).with("questionId", identity)
      preservesSource(premise, evaluateSource(fixtureEnvironment(List(premise)), premise))
    }),
    {
      val original = fixturePremise(0, 16, 1)
      val changed = original.with("questionId", 8)
      isBlocked(evaluateSource(fixtureEnvironment(List(original)), changed), List(changed), List(EvidenceMismatch))
    },
    outcomeCode(scopeOutcome(1)) == 21,
  })
  run derivationMetadataAndGradesTest = assert(Set(J::Wahm,J::Shakk,J::Zann,J::Qat).forall(grade => Set(false,true).forall(rujhan => Set(1,2,99).forall(contextId => {
    val originalLeft = fixturePremise(1, 34, 1)
    val originalRight = fixturePremise(1, 34, 2)
    val leftRaw = originalLeft.request.record
    val rightRaw = originalRight.request.record
    val left = withRaw(originalLeft, leftRaw.with("scope", leftRaw.scope.with("context", contextId)).with("provenance", leftRaw.provenance.with("grade", grade).with("rujhanKnown", rujhan)))
    val right = withRaw(originalRight, rightRaw.with("scope", rightRaw.scope.with("context", contextId)).with("provenance", rightRaw.provenance.with("grade", J::Zann).with("dalil", List(J::Qiyas))))
    val env = fixtureEnvironment(List(left, right))
    val output = evaluate(env, pairProgram(left, right))
    and { output == expectedKnown(1, J::SignAnswer(true), List(left, right)),
      output.provenance.head().request.record.provenance.grade == grade,
      output.provenance.nth(1).request.record.provenance.grade == J::Zann }
  }))))
  run derivationRawBoundaryTest = assert({
    val premise = fixturePremise(1, 34, 1)
    val env = fixtureEnvironment(List(premise))
    val negative = premise.with("questionId", -1)
    val stale = env.with("currentVersions", List(env.currentVersions.head().with("interpretationVersion", -1)))
    val source = env.with("authenticatedSources", List(syntheticSource1.with("sourceBytes", -1)))
    and {
      isBlocked(evaluateSource(env, negative), List(negative), List(BadEnvironment)),
      isBlocked(evaluateSource(stale, premise), List(premise), List(BadEnvironment)),
      isBlocked(evaluateSource(source, premise), List(premise), List(BadEnvironment)),
      isBlocked(evaluateSource(env.with("implementationRevision", ""), premise), List(premise), List(BadEnvironment)),
    }
  })
  run derivationAlgebraTest = assert(and {
    J::carrier.forall(hukm => fromAlgebra(toAlgebra(hukm)) == hukm),
    1.to(31).forall(a => 1.to(31).forall(b => {
      val left = J::carrier.filter(hukm => (a / J::bit(hukm)) % 2 == 1)
      val right = J::carrier.filter(hukm => (b / J::bit(hukm)) % 2 == 1)
      val common = left.intersect(right)
      val result = conjoinAnswers(J::Taklifi, J::TaklifiAnswer(left), J::TaklifiAnswer(right))
      if (common.size() == 0) result == AnswerConflict else result == CombinedAnswer(J::TaklifiAnswer(common))
    })),
  })
  run derivationQuestionFamilyTest = assert(and {
    1.to(4).forall(q => Set(false,true).forall(a => Set(false,true).forall(b => {
      val left = if (q == 4) J::ValidityAnswer(if (a) J::Sahih else J::Fasid) else J::SignAnswer(a)
      val right = if (q == 4) J::ValidityAnswer(if (b) J::Sahih else J::Fasid) else J::SignAnswer(b)
      val output = conjoinAnswers(decodedQuestion(q), left, right)
      if (a == b) output == CombinedAnswer(left) else output == AnswerConflict
    }))),
    conjoinAnswers(J::Taklifi, J::SignAnswer(true), J::SignAnswer(true)) == AnswerConflict,
    conjoinAnswers(J::Sabab, J::TaklifiAnswer(Set(J::Mubah)), J::TaklifiAnswer(Set(J::Mubah))) == AnswerConflict,
    conjoinAnswers(J::Taklifi, J::TaklifiAnswer(Set()), J::TaklifiAnswer(Set(J::Mubah))) == AnswerConflict,
  })
  run derivationScopePredicateTest = assert(0.to(4).forall(q => {
    val premise = fixturePremise(q, knownAnswerCode(q), 1)
    val original = { questionId: 7, question: decodedQuestion(q), answer: decodedAnswer(q, knownAnswerCode(q)), scope: premise.request.record.scope }
    and {
      sameQuestionScope(original, original),
      not(sameQuestionScope(original, original.with("questionId", 8))),
      not(sameQuestionScope(original, original.with("question", decodedQuestion((q + 1) % 5)))),
      3.to(12).forall(caseId => not(sameQuestionScope(original, original.with("scope", J::syntheticRecordVariant(q, caseId).scope)))),
    }
  }))
}
