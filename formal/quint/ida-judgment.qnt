// Independent typed-record and registry model for the next IDA slice.
// The supplied registry is trusted input. Digest syntax/equality does not
// authenticate bytes, interpretation, a religious position, or a derivation.
// Every finite fixture below is synthetic.
module idaJudgment {
  import ida as A from "./ida"

  type Hukm = Haram | Makruh | Mubah | Mandub | Wajib
  type Question = Taklifi | Sabab | Shart | Mani | ValidityQuestion
  type Validity = Fasid | Sahih
  type Answer = TaklifiAnswer(Set[Hukm]) | SignAnswer(bool) | ValidityAnswer(Validity)
  type Payload = NoRuling | Suspended | Known(Answer)
  type TargetKind = Behavior | Affect
  type LegacyTarget = { id: int, kind: TargetKind }
  type ScopeTarget = OpaqueTarget(LegacyTarget) | DescribedTarget(A::Target)
  type Domain = Ada | Ibada
  type Grade = Wahm | Shakk | Zann | Qat
  type DalilKind = Nass | Ijma | FatwaSahabi | AqrabSahabi | MursalDaif | Qiyas | Istishab
  type Status = Candidate | Admitted | Quarantined | Revoked

  type Subject = { baligh: bool, aqil: bool }
  type Scope = {
    subjectId: int, subject: Subject, target: ScopeTarget,
    context: int, time: int, profile: int, profileVersion: int, domain: Domain
  }
  type SourceRef = {
    sourceId: int, sourceHash: List[int], sourceBytes: int,
    passageStart: int, passageEnd: int, passageHash: List[int]
  }
  type Provenance = {
    source: SourceRef, interpretationId: int, interpretationVersion: int,
    grade: Grade, rujhanKnown: bool, dalil: List[DalilKind], premises: List[int],
    ruleId: int, implementationRevision: str
  }
  type RawRecord = { questionCode: int, answerCode: int, scope: Scope, provenance: Provenance }
  type TypedRecord = { question: Question, payload: Payload, scope: Scope, provenance: Provenance }
  type Entry = { entryId: int, status: Status, record: RawRecord }
  type Registry = { snapshot: int, entries: List[Entry] }
  type Request = { snapshot: int, entryId: int, record: RawRecord }
  type Receipt = { snapshot: int, entryId: int, record: TypedRecord }

  type QuestionDecode = BadQuestion | QuestionValue(Question)
  type PayloadDecode = BadPayload | PayloadValue(Payload)
  type PayloadEncode = BadPayloadEncoding | PayloadCode(int)
  type RecordDecode = BadRecord | RecordValue(TypedRecord)
  type RecordEncode = BadRecordEncoding | RecordCode(RawRecord)
  type Rejection = BadAnswer | BadReference | IllTyped | StaleSnapshot
    | MissingEntry | AmbiguousEntry | NotAdmitted | RecordMismatch
  type Validation = Rejected(Rejection) | Accepted(Receipt)

  pure val carrier: Set[Hukm] = Set(Haram, Makruh, Mubah, Mandub, Wajib)
  pure val questions: Set[Question] = Set(Taklifi, Sabab, Shart, Mani, ValidityQuestion)

  pure def encodeQuestion(question: Question): int = match question {
    | Taklifi => 0
    | Sabab => 1
    | Shart => 2
    | Mani => 3
    | ValidityQuestion => 4
  }

  pure def decodeQuestion(code: int): QuestionDecode = {
    if (code == 0) QuestionValue(Taklifi)
    else if (code == 1) QuestionValue(Sabab)
    else if (code == 2) QuestionValue(Shart)
    else if (code == 3) QuestionValue(Mani)
    else if (code == 4) QuestionValue(ValidityQuestion)
    else BadQuestion
  }

  pure def bit(value: Hukm): int = match value {
    | Haram => 1
    | Makruh => 2
    | Mubah => 4
    | Mandub => 8
    | Wajib => 16
  }

  // Quint has no dependent types: this predicate is the question index.
  // The decoder constructs only fitting payloads. Empty known sets never fit.
  pure def payloadFits(question: Question, payload: Payload): bool = match payload {
    | NoRuling => true
    | Suspended => true
    | Known(answer) => match answer {
      | TaklifiAnswer(values) => question == Taklifi and values.size() > 0
      | SignAnswer(_) => Set(Sabab, Shart, Mani).contains(question)
      | ValidityAnswer(_) => question == ValidityQuestion
    }
  }

  pure def decodePayload(question: Question, code: int): PayloadDecode = {
    if (code == 0) PayloadValue(NoRuling)
    else if (code == 32) PayloadValue(Suspended)
    else match question {
      | Taklifi => {
        if (code >= 1 and code <= 31)
          PayloadValue(Known(TaklifiAnswer(carrier.filter(value => (code / bit(value)) % 2 == 1))))
        else BadPayload
      }
      | ValidityQuestion => {
        if (code == 35) PayloadValue(Known(ValidityAnswer(Fasid)))
        else if (code == 36) PayloadValue(Known(ValidityAnswer(Sahih)))
        else BadPayload
      }
      | _ => {
        if (code == 33) PayloadValue(Known(SignAnswer(false)))
        else if (code == 34) PayloadValue(Known(SignAnswer(true)))
        else BadPayload
      }
    }
  }

  pure def encodePayload(payload: Payload): PayloadEncode = match payload {
    | NoRuling => PayloadCode(0)
    | Suspended => PayloadCode(32)
    | Known(answer) => match answer {
      | TaklifiAnswer(values) => {
        if (values.size() == 0) BadPayloadEncoding
        else PayloadCode(values.fold(0, (mask, value) => mask + bit(value)))
      }
      | SignAnswer(value) => PayloadCode(if (value) 34 else 33)
      | ValidityAnswer(value) => PayloadCode(match value { | Fasid => 35 | Sahih => 36 })
    }
  }

  pure def decodeRecord(record: RawRecord): RecordDecode = match decodeQuestion(record.questionCode) {
    | BadQuestion => BadRecord
    | QuestionValue(question) => match decodePayload(question, record.answerCode) {
      | BadPayload => BadRecord
      | PayloadValue(payload) => RecordValue({
        question: question, payload: payload, scope: record.scope, provenance: record.provenance
      })
    }
  }

  pure def encodeRecord(record: TypedRecord): RecordEncode = {
    if (not(payloadFits(record.question, record.payload))) BadRecordEncoding
    else match encodePayload(record.payload) {
      | BadPayloadEncoding => BadRecordEncoding
      | PayloadCode(code) => RecordCode({
        questionCode: encodeQuestion(record.question), answerCode: code,
        scope: record.scope, provenance: record.provenance
      })
    }
  }

  // A rejected pair is zero; an accepted pair returns its canonical answer + 1.
  pure def codecCode(question: int, answer: int): int = match decodeQuestion(question) {
    | BadQuestion => 0
    | QuestionValue(q) => match decodePayload(q, answer) {
      | BadPayload => 0
      | PayloadValue(payload) => match encodePayload(payload) {
        | BadPayloadEncoding => 0
        | PayloadCode(code) => code + 1
      }
    }
  }

  // Lean rules these out with Nat. Quint checks them at the raw boundary,
  // including every natural-valued field of the separately supplied registry.
  pure def naturalList(values: List[int]): bool = values.foldl(true, (ok, value) => ok and value >= 0)

  pure def sourceNaturals(source: SourceRef): bool = and {
    Set(source.sourceId, source.sourceBytes, source.passageStart, source.passageEnd).forall(value => value >= 0),
    naturalList(source.sourceHash), naturalList(source.passageHash),
  }

  pure def targetNaturals(target: ScopeTarget): bool = match target {
    | OpaqueTarget(value) => value.id >= 0
    | DescribedTarget(expression) => match expression {
      | Omit(omission) => omission.opportunity.opensAt >= 0 and omission.opportunity.closesAt >= 0
      | _ => true
    }
  }

  pure def recordNaturals(record: RawRecord): bool = and {
    Set(record.questionCode, record.answerCode, record.scope.subjectId,
      record.scope.context, record.scope.time, record.scope.profile, record.scope.profileVersion,
      record.provenance.interpretationId, record.provenance.interpretationVersion,
      record.provenance.ruleId).forall(value => value >= 0),
    targetNaturals(record.scope.target),
    sourceNaturals(record.provenance.source),
    naturalList(record.provenance.premises),
  }

  pure def boundaryNaturals(registry: Registry, request: Request): bool = and {
    registry.snapshot >= 0, request.snapshot >= 0, request.entryId >= 0,
    recordNaturals(request.record),
    registry.entries.foldl(true, (ok, entry) =>
      ok and entry.entryId >= 0 and recordNaturals(entry.record)),
  }

  pure def digestShape(digest: List[int]): bool =
    digest.length() == 32 and digest.foldl(true, (ok, byte) => ok and byte >= 0 and byte <= 255)

  pure def referenceShape(provenance: Provenance): bool = and {
    digestShape(provenance.source.sourceHash),
    digestShape(provenance.source.passageHash),
    provenance.source.passageStart < provenance.source.passageEnd,
    provenance.source.passageEnd <= provenance.source.sourceBytes,
    provenance.implementationRevision != "",
  }

  pure def validScopeTarget(target: ScopeTarget): bool = match target {
    | OpaqueTarget(_) => true
    | DescribedTarget(expression) => A::validTarget(expression)
  }

  pure def sameScopeTarget(left: ScopeTarget, right: ScopeTarget): bool = match left {
    | OpaqueTarget(a) => match right {
      | OpaqueTarget(b) => a.id == b.id and a.kind == b.kind
      | _ => false
    }
    | DescribedTarget(a) => match right {
      | DescribedTarget(b) => A::sameTarget(a, b)
      | _ => false
    }
  }

  // This retains the existing Judgement gate. Evidence grade is not promoted.
  pure def wellTyped(record: TypedRecord): bool = and {
    record.provenance.dalil.length() > 0,
    validScopeTarget(record.scope.target),
    record.question != Taklifi or (record.scope.subject.baligh and record.scope.subject.aqil),
  }

  // Explicit field comparisons independently implement COMPLETE record equality.
  pure def sameScope(a: Scope, b: Scope): bool = and {
    a.subjectId == b.subjectId,
    a.subject == b.subject,
    sameScopeTarget(a.target, b.target),
    a.context == b.context,
    a.time == b.time,
    a.profile == b.profile,
    a.profileVersion == b.profileVersion,
    a.domain == b.domain,
  }

  pure def sameSource(a: SourceRef, b: SourceRef): bool = and {
    a.sourceId == b.sourceId,
    a.sourceHash == b.sourceHash,
    a.sourceBytes == b.sourceBytes,
    a.passageStart == b.passageStart,
    a.passageEnd == b.passageEnd,
    a.passageHash == b.passageHash,
  }

  pure def sameProvenance(a: Provenance, b: Provenance): bool = and {
    sameSource(a.source, b.source),
    a.interpretationId == b.interpretationId,
    a.interpretationVersion == b.interpretationVersion,
    a.grade == b.grade,
    a.rujhanKnown == b.rujhanKnown,
    a.dalil == b.dalil,
    a.premises == b.premises,
    a.ruleId == b.ruleId,
    a.implementationRevision == b.implementationRevision,
  }

  pure def sameRecord(a: RawRecord, b: RawRecord): bool = and {
    a.questionCode == b.questionCode,
    a.answerCode == b.answerCode,
    sameScope(a.scope, b.scope),
    sameProvenance(a.provenance, b.provenance),
  }

  // Guard order is part of the contract. Entry selection preserves multiplicity;
  // duplicate IDs are rejected even when both copies have identical contents.
  pure def validate(registry: Registry, request: Request): Validation = match decodeRecord(request.record) {
    | BadRecord => Rejected(BadAnswer)
    | RecordValue(typed) => {
      if (not(boundaryNaturals(registry, request))) Rejected(BadReference)
      else if (not(referenceShape(typed.provenance))) Rejected(BadReference)
      else if (not(wellTyped(typed))) Rejected(IllTyped)
      else if (request.snapshot != registry.snapshot) Rejected(StaleSnapshot)
      else {
        val matching = registry.entries.select(entry => entry.entryId == request.entryId)
        if (matching.length() == 0) Rejected(MissingEntry)
        else if (matching.length() != 1) Rejected(AmbiguousEntry)
        else {
          val entry = matching.head()
          if (entry.status != Admitted) Rejected(NotAdmitted)
          else if (not(sameRecord(entry.record, request.record))) Rejected(RecordMismatch)
          else Accepted({ snapshot: request.snapshot, entryId: request.entryId, record: typed })
        }
      }
    }
  }

  pure def resultCode(result: Validation): int = match result {
    | Accepted(_) => 0
    | Rejected(reason) => match reason {
      | BadAnswer => 1
      | BadReference => 2
      | IllTyped => 3
      | StaleSnapshot => 4
      | MissingEntry => 5
      | AmbiguousEntry => 6
      | NotAdmitted => 7
      | RecordMismatch => 8
    }
  }

  // A receipt is data. Fresh validation against the CURRENT supplied registry
  // is mandatory, including when the historical receipt was accepted.
  pure def revalidate(registry: Registry, receipt: Receipt): Validation = match encodeRecord(receipt.record) {
    | BadRecordEncoding => Rejected(BadAnswer)
    | RecordCode(raw) => validate(registry, {
      snapshot: receipt.snapshot, entryId: receipt.entryId, record: raw
    })
  }

  // Synthetic finite-domain construction, separate from the validator.
  pure def syntheticDigest(byte: int): List[int] =
    range(0, 32).foldl(List(), (bytes, _) => bytes.append(byte))

  pure def syntheticBaseline(question: int): RawRecord = {
    if (question < 0 or question > 4) Set().getOnlyElement()
    else {
      questionCode: question,
      answerCode: if (question == 0) 16 else if (question == 4) 36 else 34,
      scope: {
        subjectId: 1, subject: { baligh: true, aqil: true },
        target: OpaqueTarget({ id: 1, kind: Behavior }), context: 1, time: 1,
        profile: 1, profileVersion: 1, domain: Ada
      },
      provenance: {
        source: {
          sourceId: 1, sourceHash: syntheticDigest(0), sourceBytes: 4,
          passageStart: 1, passageEnd: 3, passageHash: syntheticDigest(0)
        },
        interpretationId: 1, interpretationVersion: 1, grade: Qat,
        rujhanKnown: true, dalil: List(Nass), premises: List(),
        ruleId: 1, implementationRevision: "rev-a"
      }
    }
  }

  pure def syntheticStatus(code: int): Status = {
    if (code == 0) Candidate
    else if (code == 1) Admitted
    else if (code == 2) Quarantined
    else if (code == 3) Revoked
    else Set().getOnlyElement()
  }

  pure def syntheticEntry(question: int, status: Status): Entry =
    { entryId: 1, status: status, record: syntheticBaseline(question) }

  pure def syntheticRegistry(question: int, status: Status): Registry =
    { snapshot: 1, entries: List(syntheticEntry(question, status)) }

  pure def syntheticRequest(question: int): Request =
    { snapshot: 1, entryId: 1, record: syntheticBaseline(question) }

  pure def syntheticRecordVariant(question: int, caseId: int): RawRecord = {
    val record = syntheticBaseline(question)
    val scope = record.scope
    val provenance = record.provenance
    val source = provenance.source
    if (caseId == 1) record.with("questionCode", (question + 1) % 5)
    else if (caseId == 2) record.with("answerCode", if (question == 0) 1 else if (question == 4) 35 else 33)
    else if (caseId == 3) record.with("scope", scope.with("subjectId", 2))
    else if (caseId == 4) record.with("scope", scope.with("subject", scope.subject.with("baligh", false)))
    else if (caseId == 5) record.with("scope", scope.with("subject", scope.subject.with("aqil", false)))
    else if (caseId == 6) record.with("scope", scope.with("target", OpaqueTarget({ id: 2, kind: Behavior })))
    else if (caseId == 7) record.with("scope", scope.with("target", OpaqueTarget({ id: 1, kind: Affect })))
    else if (caseId == 8) record.with("scope", scope.with("context", 2))
    else if (caseId == 9) record.with("scope", scope.with("time", 2))
    else if (caseId == 10) record.with("scope", scope.with("profile", 2))
    else if (caseId == 11) record.with("scope", scope.with("profileVersion", 2))
    else if (caseId == 12) record.with("scope", scope.with("domain", Ibada))
    else if (caseId == 13) record.with("provenance", provenance.with("source", source.with("sourceId", 2)))
    else if (caseId == 14) record.with("provenance", provenance.with("source", source.with("sourceHash", syntheticDigest(1))))
    else if (caseId == 15) record.with("provenance", provenance.with("source", source.with("sourceBytes", 5)))
    else if (caseId == 16) record.with("provenance", provenance.with("source", source.with("passageStart", 2)))
    else if (caseId == 17) record.with("provenance", provenance.with("source", source.with("passageEnd", 4)))
    else if (caseId == 18) record.with("provenance", provenance.with("source", source.with("passageHash", syntheticDigest(1))))
    else if (caseId == 19) record.with("provenance", provenance.with("interpretationId", 2))
    else if (caseId == 20) record.with("provenance", provenance.with("interpretationVersion", 2))
    else if (caseId == 21) record.with("provenance", provenance.with("grade", Zann))
    else if (caseId == 22) record.with("provenance", provenance.with("rujhanKnown", false))
    else if (caseId == 23) record.with("provenance", provenance.with("dalil", List(Qiyas)))
    else if (caseId == 24) record.with("provenance", provenance.with("premises", List(2)))
    else if (caseId == 25) record.with("provenance", provenance.with("ruleId", 2))
    else if (caseId == 26) record.with("provenance", provenance.with("implementationRevision", "rev-b"))
    else if (caseId == 30) record.with("provenance", provenance.with("source", source.with("sourceHash", List())))
    else if (caseId == 31) record.with("provenance", provenance.with("source", source.with("passageStart", 3)))
    else if (caseId == 32) record.with("provenance", provenance.with("dalil", List()))
    else if (caseId == 33) record.with("provenance", provenance.with("source", source.with("sourceHash", syntheticDigest(256))))
    else if (caseId == 34) record.with("provenance", provenance.with("implementationRevision", ""))
    else if (caseId == 35) record.with("provenance", provenance.with("source", source.with("passageHash", List())))
    else if (caseId == 36) record.with("provenance", provenance.with("source", source.with("passageEnd", 5)))
    else if (caseId == 37) record.with("provenance", provenance.with("source", source.with("passageHash", syntheticDigest(256))))
    else if (Set(0, 27, 28, 29).contains(caseId)) record
    else Set().getOnlyElement()
  }

  pure def syntheticRequestVariant(question: int, caseId: int): Request = {
    snapshot: if (caseId == 27) 2 else 1,
    entryId: if (caseId == 28) 2 else 1,
    record: syntheticRecordVariant(question, caseId)
  }

  pure def admissionCode(question: int, status: int, caseId: int): int = {
    val entry = syntheticEntry(question, syntheticStatus(status))
    val registry: Registry = { snapshot: 1, entries: if (caseId == 29) List(entry, entry) else List(entry) }
    resultCode(validate(registry, syntheticRequestVariant(question, caseId)))
  }

  pure def syntheticRegistryUpdate(question: int, update: int): Registry = {
    val entry = syntheticEntry(question, Admitted)
    val registry = syntheticRegistry(question, Admitted)
    if (update == 0) registry
    else if (update == 1) registry.with("snapshot", 2)
    else if (update == 2) registry.with("entries", List(entry.with("status", Revoked)))
    else if (update == 3) registry.with("entries", List(entry.with("status", Quarantined)))
    else if (update == 4) registry.with("entries", List(entry.with("record", syntheticRecordVariant(question, 14))))
    else if (update == 5) registry.with("entries", List(entry.with("record", syntheticRecordVariant(question, 11))))
    else if (update == 6) registry.with("entries", List())
    else if (update == 7) registry.with("entries", List(entry, entry))
    else Set().getOnlyElement()
  }

  pure def syntheticReceipt(question: int): Receipt =
    match validate(syntheticRegistry(question, Admitted), syntheticRequest(question)) {
      | Accepted(receipt) => receipt
      // Empty getOnlyElement deliberately raises a runtime error if minting
      // fails. A failed setup cannot masquerade as a successful rejection case.
      | Rejected(_) => Set().getOnlyElement()
    }

  pure def revalidationCode(question: int, update: int): int =
    resultCode(revalidate(syntheticRegistryUpdate(question, update), syntheticReceipt(question)))

  // Register a specified synthetic record exactly. Used to check preservation
  // of payloads and metadata, independently of request-tampering scenarios.
  pure def validateSyntheticRecord(record: RawRecord): Validation =
    validate({ snapshot: 1, entries: List({ entryId: 1, status: Admitted, record: record }) },
      { snapshot: 1, entryId: 1, record: record })

  // Positive preservation must vary admitted contents as well as test rejected
  // tampering. Both the registry and request here carry the specified raw value.
  pure def preservesSyntheticRequest(raw: RawRecord, snapshot: int, entryId: int): bool = {
    val registry: Registry = {
      snapshot: snapshot, entries: List({ entryId: entryId, status: Admitted, record: raw })
    }
    val request: Request = { snapshot: snapshot, entryId: entryId, record: raw }
    match validate(registry, request) {
      | Rejected(_) => false
      | Accepted(receipt) => and {
        receipt.snapshot == snapshot,
        receipt.entryId == entryId,
        payloadFits(receipt.record.question, receipt.record.payload),
        referenceShape(receipt.record.provenance),
        wellTyped(receipt.record),
        encodeRecord(receipt.record) == RecordCode(raw),
        receipt.record.scope == raw.scope,
        receipt.record.provenance == raw.provenance,
        match revalidate(registry, receipt) {
          | Rejected(_) => false
          | Accepted(rechecked) => and {
            rechecked.snapshot == snapshot,
            rechecked.entryId == entryId,
            encodeRecord(rechecked.record) == RecordCode(raw),
            rechecked == receipt,
          }
        },
      }
    }
  }

  run codecFamiliesTest = assert(and {
    questions.forall(question => decodeQuestion(encodeQuestion(question)) == QuestionValue(question)),
    0.to(5).forall(question => 0.to(37).forall(answer => {
      val allowed = or {
        question == 0 and answer >= 0 and answer <= 32,
        Set(1, 2, 3).contains(question) and Set(0, 32, 33, 34).contains(answer),
        question == 4 and Set(0, 32, 35, 36).contains(answer),
      }
      codecCode(question, answer) == (if (allowed) answer + 1 else 0)
    })),
    Set(-1000, -1, 5, 6, 1000).forall(question =>
      Set(-1, 0, 1, 16, 32, 33, 34, 35, 36, 1000).forall(answer => codecCode(question, answer) == 0)),
    0.to(4).forall(question => Set(-1000, -1, 37, 38, 64, 1000).forall(answer => codecCode(question, answer) == 0)),
  })

  run typedPayloadTest = assert(and {
    0.to(4).forall(question => 0.to(37).forall(answer => {
      val raw = syntheticBaseline(question).with("answerCode", answer)
      match decodeRecord(raw) {
        | BadRecord => codecCode(question, answer) == 0
        | RecordValue(typed) => and {
          payloadFits(typed.question, typed.payload),
          encodeRecord(typed) == RecordCode(raw),
          match encodePayload(typed.payload) {
            | BadPayloadEncoding => false
            | PayloadCode(code) => code == answer
          },
        }
      }
    })),
    not(payloadFits(Taklifi, Known(SignAnswer(true)))),
    not(payloadFits(Sabab, Known(ValidityAnswer(Sahih)))),
    not(payloadFits(ValidityQuestion, Known(TaklifiAnswer(Set(Wajib))))),
    not(payloadFits(Taklifi, Known(TaklifiAnswer(Set())))),
    encodePayload(Known(TaklifiAnswer(Set()))) == BadPayloadEncoding,
  })

  run metadataBindingTest = assert(and {
    0.to(4).forall(question => 0.to(37).forall(caseId => {
      val baseline = syntheticBaseline(question)
      val changed = syntheticRecordVariant(question, caseId)
      sameRecord(baseline, changed) == (baseline == changed)
    })),
    0.to(4).forall(question => Set(2, 3, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
      16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26).forall(caseId => admissionCode(question, 1, caseId) == 8)),
    admissionCode(1, 1, 1) == 8,
    admissionCode(2, 1, 1) == 8,
    Set(0, 3, 4).forall(question => admissionCode(question, 1, 1) == 1),
  })

  run admissionStatusTest = assert(and {
    0.to(4).forall(question => 0.to(3).forall(status =>
      admissionCode(question, status, 0) == (if (status == 1) 0 else 7))),
    0.to(4).forall(question => Set(0, 2, 3).forall(status =>
      admissionCode(question, status, 14) == 7)),
  })

  run duplicateEntryTest = assert(and {
    0.to(4).forall(question => 0.to(3).forall(status => admissionCode(question, status, 29) == 6)),
    0.to(4).forall(question => {
      val admitted = syntheticEntry(question, Admitted)
      val revoked = admitted.with("status", Revoked)
      val different = admitted.with("record", syntheticRecordVariant(question, 14))
      val request = syntheticRequest(question)
      and {
        resultCode(validate({ snapshot: 1, entries: List(admitted, revoked) }, request)) == 6,
        resultCode(validate({ snapshot: 1, entries: List(revoked, admitted) }, request)) == 6,
        resultCode(validate({ snapshot: 1, entries: List(admitted, different) }, request)) == 6,
        resultCode(validate({ snapshot: 1, entries: List(admitted, revoked.with("entryId", 2)) }, request)) == 0,
        resultCode(validate({ snapshot: 1, entries: List(revoked.with("entryId", 2), admitted) }, request)) == 0,
      }
    }),
  })

  run capacityAndEvidenceTest = assert(and {
    Set(4, 5).forall(caseId => admissionCode(0, 1, caseId) == 3),
    1.to(4).forall(question => Set(4, 5).forall(caseId => and {
      admissionCode(question, 1, caseId) == 8,
      resultCode(validateSyntheticRecord(syntheticRecordVariant(question, caseId))) == 0,
    })),
    0.to(4).forall(question => and {
      admissionCode(question, 1, 32) == 3,
      resultCode(validateSyntheticRecord(syntheticRecordVariant(question, 32))) == 3,
    }),
  })

  run referenceShapeTest = assert(and {
    0.to(4).forall(question => 0.to(3).forall(status =>
      Set(30, 31, 33, 34, 35, 36, 37).forall(caseId => admissionCode(question, status, caseId) == 2))),
    digestShape(syntheticDigest(0)),
    digestShape(syntheticDigest(255)),
    not(digestShape(syntheticDigest(256))),
    not(digestShape(syntheticDigest(-1))),
    not(digestShape(syntheticDigest(0).tail())),
    not(digestShape(syntheticDigest(0).append(0))),
    0.to(4).forall(question => {
      val record = syntheticBaseline(question)
      val source = record.provenance.source.with("sourceHash", syntheticDigest(255))
        .with("passageHash", syntheticDigest(255)).with("passageStart", 0).with("passageEnd", 4)
      resultCode(validateSyntheticRecord(record.with("provenance", record.provenance.with("source", source)))) == 0
    }),
  })

  run unresolvedAndPartialTest = assert(and {
    questions.forall(question => and {
      decodePayload(question, 0) == PayloadValue(NoRuling),
      decodePayload(question, 32) == PayloadValue(Suspended),
      NoRuling != Suspended,
    }),
    decodePayload(Taklifi, 4) == PayloadValue(Known(TaklifiAnswer(Set(Mubah)))),
    decodePayload(Taklifi, 30) == PayloadValue(Known(TaklifiAnswer(Set(Makruh, Mubah, Mandub, Wajib)))),
    decodePayload(Taklifi, 31) == PayloadValue(Known(TaklifiAnswer(carrier))),
    decodePayload(Taklifi, 0) != decodePayload(Taklifi, 4),
    decodePayload(Taklifi, 4) != decodePayload(Taklifi, 30),
    decodePayload(Taklifi, 30) != decodePayload(Taklifi, 31),
    0.to(4).forall(question => Set(0, 32).forall(answer =>
      resultCode(validateSyntheticRecord(syntheticBaseline(question).with("answerCode", answer))) == 0)),
    1.to(31).forall(answer =>
      resultCode(validateSyntheticRecord(syntheticBaseline(0).with("answerCode", answer))) == 0),
  })

  run snapshotTest = assert(and {
    0.to(4).forall(question => 0.to(3).forall(status => admissionCode(question, status, 27) == 4)),
    0.to(4).forall(question => resultCode(validate(
      { snapshot: 2, entries: List() }, syntheticRequest(question))) == 4),
  })

  run receiptRevalidationTest = assert(and {
    0.to(4).forall(question => 0.to(7).forall(update =>
      revalidationCode(question, update) == List(0, 4, 7, 7, 8, 8, 5, 6).nth(update))),
    0.to(4).forall(question => {
      val original = syntheticReceipt(question)
      val changed = original.with("record", original.record.with("provenance",
        original.record.provenance.with("source", original.record.provenance.source.with("sourceHash", syntheticDigest(1)))))
      and {
        resultCode(revalidate(syntheticRegistry(question, Admitted), changed)) == 8,
        resultCode(revalidate(syntheticRegistryUpdate(question, 2), original)) == 7,
        resultCode(revalidate(syntheticRegistry(question, Admitted), original)) == 0,
        original.snapshot == 1,
      }
    }),
  })

  run acceptancePreservationTest = assert(and {
    0.to(4).forall(question => 0.to(37).forall(answer => {
      val raw = syntheticBaseline(question).with("answerCode", answer)
      match validateSyntheticRecord(raw) {
        | Rejected(_) => codecCode(question, answer) == 0
        | Accepted(receipt) => and {
          receipt.snapshot == 1, receipt.entryId == 1,
          payloadFits(receipt.record.question, receipt.record.payload),
          referenceShape(receipt.record.provenance), wellTyped(receipt.record),
          encodeRecord(receipt.record) == RecordCode(raw),
          receipt.record.scope == raw.scope,
          receipt.record.provenance == raw.provenance,
        }
      }
    })),
    // Explicit well-formed variants are admitted against matching registry
    // records. Boolean-family question changes and non-mukallaf wadi subjects
    // are included; malformed and non-mukallaf taklifi cases are not positives.
    0.to(4).forall(question => {
      val ordinaryCases = Set(0, 2, 3, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
        16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26)
      val capacityCases = if (question == 0) Set() else Set(4, 5)
      val questionCases = if (Set(1, 2).contains(question)) Set(1) else Set()
      ordinaryCases.union(capacityCases).union(questionCases).forall(caseId =>
        Set(1, 9).forall(snapshot => Set(1, 7).forall(entryId =>
          preservesSyntheticRequest(syntheticRecordVariant(question, caseId), snapshot, entryId))))
    }),
    // All 49 valid question/payload pairs, including every partial taklifi set,
    // missing and suspended answers, survive admission and fresh revalidation.
    0.to(4).forall(question => {
      val answers = if (question == 0) 0.to(32)
        else if (question == 4) Set(0, 32, 35, 36) else Set(0, 32, 33, 34)
      answers.forall(answer => Set(1, 9).forall(snapshot => Set(1, 7).forall(entryId =>
        preservesSyntheticRequest(syntheticBaseline(question).with("answerCode", answer), snapshot, entryId))))
    }),
    0.to(4).forall(question => Set(Wahm, Shakk, Zann, Qat).forall(grade => Bool.forall(known => {
      val raw = syntheticBaseline(question)
      val changed = raw.with("provenance", raw.provenance.with("grade", grade).with("rujhanKnown", known))
      preservesSyntheticRequest(changed, 9, 7)
    }))),
  })

  run diagnosticPriorityTest = assert({
    val request = syntheticRequest(0)
    val record = request.record
    val badReference = syntheticRecordVariant(0, 30)
    val illTyped = syntheticRecordVariant(0, 32)
    val absent: Registry = { snapshot: 2, entries: List() }
    and {
      resultCode(validate(absent, request.with("record", badReference.with("questionCode", 5)))) == 1,
      resultCode(validate(absent, request.with("record", badReference))) == 2,
      resultCode(validate(absent, request.with("record", illTyped))) == 3,
      resultCode(validate(absent, request)) == 4,
      resultCode(validate(absent.with("snapshot", 1), request)) == 5,
      admissionCode(0, 0, 29) == 6,
      admissionCode(0, 0, 14) == 7,
      admissionCode(0, 1, 14) == 8,
      record != badReference,
    }
  })

  run structuredTargetAdmissionTest = assert({
    val baseline = syntheticRequest(1)
    val raw = baseline.record
    val structured = raw.with("scope", raw.scope.with("target", DescribedTarget(A::rawTargetCases.nth(0))))
    val malformed = raw.with("scope", raw.scope.with("target", DescribedTarget(A::rawTargetCases.nth(21))))
    val legacyRegistry = syntheticRegistry(1, Admitted)
    val structuredRegistry = legacyRegistry.with("entries",
      List(legacyRegistry.entries.head().with("record", structured)))
    and {
      preservesSyntheticRequest(structured, 1, 1),
      resultCode(validateSyntheticRecord(malformed)) == 3,
      resultCode(validate(legacyRegistry, baseline.with("record", structured))) == 8,
      resultCode(validate(structuredRegistry, baseline)) == 8,
      resultCode(revalidate(structuredRegistry, syntheticReceipt(1))) == 8,
    }
  })

  run negativeNaturalBoundaryTest = assert({
    val raw = syntheticBaseline(0)
    val scope = raw.scope
    val provenance = raw.provenance
    val source = provenance.source
    val negativeRecords = Set(
      raw.with("scope", scope.with("subjectId", -1)),
      raw.with("scope", scope.with("target", OpaqueTarget({ id: -1, kind: Behavior }))),
      raw.with("scope", scope.with("context", -1)),
      raw.with("scope", scope.with("time", -1)),
      raw.with("scope", scope.with("profile", -1)),
      raw.with("scope", scope.with("profileVersion", -1)),
      raw.with("provenance", provenance.with("source", source.with("sourceId", -1))),
      raw.with("provenance", provenance.with("source", source.with("sourceBytes", -1))),
      raw.with("provenance", provenance.with("source", source.with("passageStart", -1))),
      raw.with("provenance", provenance.with("source", source.with("passageEnd", -1))),
      raw.with("provenance", provenance.with("source", source.with("sourceHash", syntheticDigest(-1)))),
      raw.with("provenance", provenance.with("source", source.with("passageHash", syntheticDigest(-1)))),
      raw.with("provenance", provenance.with("interpretationId", -1)),
      raw.with("provenance", provenance.with("interpretationVersion", -1)),
      raw.with("provenance", provenance.with("ruleId", -1)),
      raw.with("provenance", provenance.with("premises", List(-1)))
    )
    val registry = syntheticRegistry(0, Admitted)
    val request = syntheticRequest(0)
    val entry = syntheticEntry(0, Admitted)
    and {
      negativeRecords.forall(negative => resultCode(validateSyntheticRecord(negative)) == 2),
      negativeRecords.forall(negative => resultCode(validate(
        registry.with("entries", List(entry, entry.with("entryId", 2).with("record", negative))), request)) == 2),
      Set(-1000, -1).forall(value => and {
        resultCode(validate(registry, request.with("snapshot", value))) == 2,
        resultCode(validate(registry, request.with("entryId", value))) == 2,
        resultCode(validate(registry.with("snapshot", value), request)) == 2,
        resultCode(validate(registry.with("entries", List(entry.with("entryId", value))), request)) == 2,
        resultCode(validate(registry.with("entries", List(entry.with("record", raw.with("questionCode", value)))), request)) == 2,
        resultCode(validate(registry.with("entries", List(entry.with("record", raw.with("answerCode", value)))), request)) == 2,
        resultCode(validate(registry, request.with("record", raw.with("questionCode", value)))) == 1,
        resultCode(validate(registry, request.with("record", raw.with("answerCode", value)))) == 1,
      }),
    }
  })
}
