// Source-bound IDA judgment replay. The trusted snapshot is an input assumption.
// Digests use ASCII code points, preserving exact wire syntax independently
// of host string operations: digits 48..57 and lowercase hex letters 97..102.
module idaJudgment {
  type Taklifi = Haram | Makruh | Mubah | Mandub | Wajib
  type Validity = Fasid | Sahih
  type Question = TaklifiQuestion | SababQuestion | ShartQuestion | ManiQuestion | ValidityQuestion
  type Verdict = NoRuling(Question) | Suspend(Question) | Conflict(Question) | OutOfScope(Question)
    | TaklifiKnown(Set[Taklifi]) | SababKnown(Set[bool]) | ShartKnown(Set[bool])
    | ManiKnown(Set[bool]) | ValidityKnown(Set[Validity])
  type VerdictDecode = InvalidVerdict | DecodedVerdict(Verdict)
  type Digest = List[int]
  type Scope = { question: int, questionId: str, subject: str, target: str,
    context: str, time: str, profile: str, profileVersion: str }
  type SourceRef = { sourceId: str, sourceDigest: Digest, locator: str, passageDigest: Digest }
  type Claim = { scope: Scope, answer: int, source: SourceRef, interpretationId: str,
    interpretationVersion: str, evidenceGrade: str, implementationRevision: str }
  type Derivation = { claim: Claim, schema: int, rule: int }
  type Packet = { claim: Claim, derivation: Derivation, reportedAdmission: int }
  type Admission = { claim: Claim, status: int }
  type TrustedSnapshot = { requestedScope: Scope, registeredSource: SourceRef,
    sourceEnabled: bool, admission: Admission }
  type Judgment = { verdict: Verdict, claim: Claim, admissionStatus: int }
  type ReplayResult = Rejected(int) | Accepted(Judgment)
  type Fixture = { packet: Packet, trusted: TrustedSnapshot }

  pure val taklifiCarrier = Set(Haram, Makruh, Mubah, Mandub, Wajib)
  pure val boolCarrier = Set(false, true)
  pure val validityCarrier = Set(Fasid, Sahih)
  pure val hexChars = 48.to(57).union(97.to(102))
  pure def repeated(c: int, n: int): Digest = range(0, n).foldl(List(), (cs, _) => cs.append(c))
  pure def validDigest(d: Digest): bool = d.length() == 64 and d.indices().forall(i => hexChars.contains(d.nth(i)))
  pure def taklifiBit(v: Taklifi): int = match v {
    | Haram => 1 | Makruh => 2 | Mubah => 4 | Mandub => 8 | Wajib => 16
  }
  pure def boolBit(v: bool): int = if (v) 2 else 1
  pure def validityBit(v: Validity): int = match v { | Fasid => 1 | Sahih => 2 }
  pure def questionTag(q: int): Question =
    if (q == 0) TaklifiQuestion else if (q == 1) SababQuestion
    else if (q == 2) ShartQuestion else if (q == 3) ManiQuestion else ValidityQuestion
  pure def decode(q: int, a: int): VerdictDecode =
    if (q < 0 or q > 4) InvalidVerdict
    else if (a == 0) DecodedVerdict(NoRuling(questionTag(q)))
    else if (a == 32) DecodedVerdict(Suspend(questionTag(q)))
    else if (a == 33) DecodedVerdict(Conflict(questionTag(q)))
    else if (a == 34) DecodedVerdict(OutOfScope(questionTag(q)))
    else if (q == 0 and a >= 1 and a <= 31)
      DecodedVerdict(TaklifiKnown(taklifiCarrier.filter(v => (a / taklifiBit(v)) % 2 == 1)))
    else if (a >= 1 and a <= 3) {
      val bs = boolCarrier.filter(v => (a / boolBit(v)) % 2 == 1)
      if (q == 1) DecodedVerdict(SababKnown(bs))
      else if (q == 2) DecodedVerdict(ShartKnown(bs))
      else if (q == 3) DecodedVerdict(ManiKnown(bs))
      else DecodedVerdict(ValidityKnown(validityCarrier.filter(v => (a / validityBit(v)) % 2 == 1)))
    } else InvalidVerdict
  pure def verdictCode(v: Verdict): int = match v {
    | NoRuling(_) => 0
    | Suspend(_) => 32
    | Conflict(_) => 33
    | OutOfScope(_) => 34
    | TaklifiKnown(xs) => xs.fold(0, (a, x) => a + taklifiBit(x))
    | SababKnown(xs) => xs.fold(0, (a, x) => a + boolBit(x))
    | ShartKnown(xs) => xs.fold(0, (a, x) => a + boolBit(x))
    | ManiKnown(xs) => xs.fold(0, (a, x) => a + boolBit(x))
    | ValidityKnown(xs) => xs.fold(0, (a, x) => a + validityBit(x))
  }
  pure def wellFormed(c: Claim): bool = and {
    c.scope.questionId != "", c.scope.profile != "", c.scope.profileVersion != "",
    c.source.sourceId != "", c.source.locator != "",
    validDigest(c.source.sourceDigest), validDigest(c.source.passageDigest),
    c.interpretationId != "", c.interpretationVersion != "",
    c.evidenceGrade != "", c.implementationRevision != ""
  }
  pure def replay(p: Packet, t: TrustedSnapshot): ReplayResult = match decode(p.claim.scope.question, p.claim.answer) {
    | InvalidVerdict => Rejected(100)
    | DecodedVerdict(v) =>
      if (p.derivation.schema != 1 or p.derivation.rule != 0) Rejected(101)
      else if (not(wellFormed(p.claim))) Rejected(102)
      else if (p.claim.scope != t.requestedScope) Rejected(103)
      else if (not(t.sourceEnabled) or p.claim.source != t.registeredSource) Rejected(104)
      else if (t.admission.status != 1) Rejected(105)
      else if (p.claim != p.derivation.claim) Rejected(106)
      else if (p.claim != t.admission.claim) Rejected(107)
      else Accepted({ verdict: v, claim: p.claim, admissionStatus: t.admission.status })
  }
  pure def resultCode(r: ReplayResult): int = match r {
    | Rejected(code) => code | Accepted(j) => verdictCode(j.verdict)
  }
  pure def outcome(f: Fixture): int = resultCode(replay(f.packet, f.trusted))
  pure def baseClaim(q: int, a: int): Claim = {
    scope: { question: q, questionId: "inquiry", subject: "subject", target: "target",
      context: "context", time: "time", profile: "profile", profileVersion: "v1" },
    answer: a,
    source: { sourceId: "source", sourceDigest: repeated(97, 64), locator: "passage", passageDigest: repeated(99, 64) },
    interpretationId: "interpretation", interpretationVersion: "v1",
    evidenceGrade: "synthetic", implementationRevision: "revision"
  }
  pure def fixtureFor(c: Claim, status: int): Fixture = {
    packet: { claim: c, derivation: { claim: c, schema: 1, rule: 0 }, reportedAdmission: 0 },
    trusted: { requestedScope: c.scope, registeredSource: c.source, sourceEnabled: true,
      admission: { claim: c, status: status } }
  }
  pure def changedAnswer(a: int): int = if (a == 1) 2 else 1
  pure def changeClaimField(c: Claim, i: int): Claim =
    if (i == 1) c.with("scope", c.scope.with("question", (c.scope.question + 1) % 5))
    else if (i == 2) c.with("scope", c.scope.with("subject", "changed"))
    else if (i == 3) c.with("scope", c.scope.with("target", "changed"))
    else if (i == 4) c.with("scope", c.scope.with("context", "changed"))
    else if (i == 5) c.with("scope", c.scope.with("time", "changed"))
    else if (i == 6) c.with("scope", c.scope.with("profile", "changed"))
    else if (i == 7) c.with("scope", c.scope.with("profileVersion", "changed"))
    else if (i == 8) c.with("answer", changedAnswer(c.answer))
    else if (i == 9) c.with("source", c.source.with("sourceId", "changed"))
    else if (i == 10) c.with("source", c.source.with("sourceDigest", repeated(98, 64)))
    else if (i == 11) c.with("source", c.source.with("locator", "changed"))
    else if (i == 12) c.with("source", c.source.with("passageDigest", repeated(98, 64)))
    else if (i == 13) c.with("interpretationId", "changed")
    else if (i == 14) c.with("interpretationVersion", "changed")
    else if (i == 15) c.with("evidenceGrade", "changed")
    else if (i == 16) c.with("implementationRevision", "changed")
    else c.with("scope", c.scope.with("questionId", "changed"))
  pure def onlyClaim(f: Fixture, c: Claim): Fixture = f.with("packet", f.packet.with("claim", c))
  pure def coherentWithoutAdmission(f: Fixture, c: Claim): Fixture = {
    packet: f.packet.with("claim", c).with("derivation", f.packet.derivation.with("claim", c)),
    trusted: f.trusted.with("requestedScope", c.scope).with("registeredSource", c.source)
  }
  pure def coherentAll(f: Fixture, c: Claim): Fixture = {
    val rebound = coherentWithoutAdmission(f, c)
    rebound.with("trusted", rebound.trusted.with("admission", rebound.trusted.admission.with("claim", c)))
  }
  pure def fixture(q: int, a: int, status: int, vcase: int): Fixture = {
    val c = baseClaim(q, a)
    val f = fixtureFor(c, status)
    if (vcase == 0) f
    else if ((vcase >= 1 and vcase <= 16) or vcase == 32) onlyClaim(f, changeClaimField(c, vcase))
    else if (vcase == 17) f.with("packet", f.packet.with("derivation", f.packet.derivation.with("schema", 0)))
    else if (vcase == 18) f.with("packet", f.packet.with("derivation", f.packet.derivation.with("rule", 1)))
    else if (vcase == 19) f.with("packet", f.packet.with("derivation", f.packet.derivation.with("claim", c.with("answer", changedAnswer(a)))))
    else if (vcase == 20) f.with("packet", f.packet.with("reportedAdmission", 1))
    else if (vcase == 21) f.with("trusted", f.trusted.with("sourceEnabled", false))
    else if (vcase == 22) f.with("trusted", f.trusted.with("registeredSource", c.source.with("sourceDigest", repeated(98, 64))))
    else if (vcase == 23) f.with("trusted", f.trusted.with("requestedScope", c.scope.with("profileVersion", "changed")))
    else if (vcase == 24) coherentAll(f, c.with("source", c.source.with("locator", "")))
    else if (vcase == 25) coherentWithoutAdmission(f, changeClaimField(c, 1))
    else if (vcase == 26) coherentWithoutAdmission(f, changeClaimField(c, 10))
    else if (vcase == 27) coherentWithoutAdmission(f, changeClaimField(c, 7))
    else if (vcase == 28) coherentWithoutAdmission(f, changeClaimField(c, 8))
    else if (vcase == 29) coherentWithoutAdmission(f, changeClaimField(c, 14))
    else if (vcase == 30) coherentAll(f, c.with("source", c.source.with("sourceDigest", List(98, 97, 100))))
    else if (vcase == 31) coherentWithoutAdmission(f, changeClaimField(c, 16))
    else coherentWithoutAdmission(f, changeClaimField(c, 32))
  }
  pure def validAnswers(q: int): Set[int] = (if (q == 0) 1.to(31) else 1.to(3)).union(Set(0, 32, 33, 34))
  pure val allClaimFields = 1.to(16).union(Set(32))
  pure def malformedDigest(d: Digest): bool = {
    val c = baseClaim(0, 1)
    val f = fixtureFor(c, 1)
    outcome(coherentAll(f, c.with("source", c.source.with("sourceDigest", d)))) == 102 and
      outcome(coherentAll(f, c.with("source", c.source.with("passageDigest", d)))) == 102
  }
  run acceptedAllMasksTest = assert(0.to(4).forall(q => validAnswers(q).forall(a => outcome(fixture(q, a, 1, 0)) == a)))
  run invalidQuestionTest = assert(Set(-1, 5, 6).forall(q => 0.to(35).forall(a => outcome(fixture(q, a, 1, 0)) == 100)))
  run invalidAnswerCodesTest = assert(0.to(4).forall(q => Set(-1, 35, 36, 100).forall(a => outcome(fixture(q, a, 1, 0)) == 100)))
  run wrongQuestionCarrierTest = assert(1.to(4).forall(q => 4.to(31).forall(a => outcome(fixture(q, a, 1, 0)) == 100)))
  run typedVerdictsTest = assert(and {
    decode(0, 31) == DecodedVerdict(TaklifiKnown(taklifiCarrier)),
    decode(1, 3) == DecodedVerdict(SababKnown(boolCarrier)),
    decode(2, 3) == DecodedVerdict(ShartKnown(boolCarrier)),
    decode(3, 3) == DecodedVerdict(ManiKnown(boolCarrier)),
    decode(4, 3) == DecodedVerdict(ValidityKnown(validityCarrier)),
    0.to(4).forall(q => decode(q, 0) == DecodedVerdict(NoRuling(questionTag(q))))
  })
  run typedSingletonsTest = assert(and {
    decode(0, 1) == DecodedVerdict(TaklifiKnown(Set(Haram))),
    decode(0, 2) == DecodedVerdict(TaklifiKnown(Set(Makruh))),
    decode(0, 4) == DecodedVerdict(TaklifiKnown(Set(Mubah))),
    decode(0, 8) == DecodedVerdict(TaklifiKnown(Set(Mandub))),
    decode(0, 16) == DecodedVerdict(TaklifiKnown(Set(Wajib))),
    decode(1, 1) == DecodedVerdict(SababKnown(Set(false))),
    decode(1, 2) == DecodedVerdict(SababKnown(Set(true))),
    decode(2, 1) == DecodedVerdict(ShartKnown(Set(false))),
    decode(2, 2) == DecodedVerdict(ShartKnown(Set(true))),
    decode(3, 1) == DecodedVerdict(ManiKnown(Set(false))),
    decode(3, 2) == DecodedVerdict(ManiKnown(Set(true))),
    decode(4, 1) == DecodedVerdict(ValidityKnown(Set(Fasid))),
    decode(4, 2) == DecodedVerdict(ValidityKnown(Set(Sahih)))
  })
  run exceptionalQuestionIdentityTest = assert(and {
    decode(0, 0) == DecodedVerdict(NoRuling(TaklifiQuestion)),
    decode(1, 0) == DecodedVerdict(NoRuling(SababQuestion)),
    decode(2, 0) == DecodedVerdict(NoRuling(ShartQuestion)),
    decode(3, 0) == DecodedVerdict(NoRuling(ManiQuestion)),
    decode(4, 0) == DecodedVerdict(NoRuling(ValidityQuestion)),
    decode(0, 32) == DecodedVerdict(Suspend(TaklifiQuestion)),
    decode(1, 32) == DecodedVerdict(Suspend(SababQuestion)),
    decode(2, 32) == DecodedVerdict(Suspend(ShartQuestion)),
    decode(3, 32) == DecodedVerdict(Suspend(ManiQuestion)),
    decode(4, 32) == DecodedVerdict(Suspend(ValidityQuestion)),
    decode(0, 33) == DecodedVerdict(Conflict(TaklifiQuestion)),
    decode(1, 33) == DecodedVerdict(Conflict(SababQuestion)),
    decode(2, 33) == DecodedVerdict(Conflict(ShartQuestion)),
    decode(3, 33) == DecodedVerdict(Conflict(ManiQuestion)),
    decode(4, 33) == DecodedVerdict(Conflict(ValidityQuestion)),
    decode(0, 34) == DecodedVerdict(OutOfScope(TaklifiQuestion)),
    decode(1, 34) == DecodedVerdict(OutOfScope(SababQuestion)),
    decode(2, 34) == DecodedVerdict(OutOfScope(ShartQuestion)),
    decode(3, 34) == DecodedVerdict(OutOfScope(ManiQuestion)),
    decode(4, 34) == DecodedVerdict(OutOfScope(ValidityQuestion))
  })
  run preservedStatusesTest = assert(0.to(4).forall(q => Set(0, 32, 33, 34).forall(a => outcome(fixture(q, a, 1, 0)) == a)))
  run supportedSchemaRuleTest = assert(0.to(4).forall(q => validAnswers(q).forall(a => and {
    outcome(fixture(q, a, 1, 17)) == 101, outcome(fixture(q, a, 1, 18)) == 101
  })))
  run malformedEmptyDigestTest = assert(malformedDigest(List()))
  run malformedUppercaseDigestTest = assert(malformedDigest(repeated(65, 64)))
  run malformed63DigestTest = assert(malformedDigest(repeated(97, 63)))
  run malformed65DigestTest = assert(malformedDigest(repeated(97, 65)))
  run malformedNonhexDigestTest = assert(malformedDigest(repeated(103, 64)))
  run malformedEmptyInterpretationIdTest = assert({
    val c = baseClaim(0, 1)
    outcome(coherentAll(fixtureFor(c, 1), c.with("interpretationId", ""))) == 102
  })
  run malformedEmptyInterpretationVersionTest = assert({
    val c = baseClaim(0, 1)
    outcome(coherentAll(fixtureFor(c, 1), c.with("interpretationVersion", ""))) == 102
  })
  run malformedRequiredFieldsTest = assert({
    val c = baseClaim(0, 1)
    val f = fixtureFor(c, 1)
    Set(
      c.with("scope", c.scope.with("questionId", "")),
      c.with("scope", c.scope.with("profile", "")),
      c.with("scope", c.scope.with("profileVersion", "")),
      c.with("source", c.source.with("sourceId", "")),
      c.with("source", c.source.with("locator", "")),
      c.with("evidenceGrade", ""), c.with("implementationRevision", "")
    ).forall(bad => outcome(coherentAll(f, bad)) == 102)
  })
  run currentScopeBindingTest = assert(0.to(4).forall(q => {
    val c = baseClaim(q, 1)
    val f = fixtureFor(c, 1)
    1.to(7).union(Set(32)).forall(i => {
      val changed = changeClaimField(c, i)
      val g = fixtureFor(changed, 1)
      outcome(g.with("trusted", g.trusted.with("requestedScope", c.scope))) == 103
    })
  }))
  run registeredSourceBindingTest = assert({
    val c = baseClaim(0, 1)
    val f = fixtureFor(c, 1)
    9.to(12).forall(i => {
      val changed = changeClaimField(c, i)
      val g = fixtureFor(changed, 1)
      outcome(g.with("trusted", g.trusted.with("registeredSource", c.source))) == 104
    })
  })
  run disabledSourceTest = assert(0.to(4).forall(q => validAnswers(q).forall(a => outcome(fixture(q, a, 1, 21)) == 104)))
  run trustedAdmissionStatusTest = assert(0.to(4).forall(q => validAnswers(q).forall(a => Set(0, 2, 3).forall(s => outcome(fixture(q, a, s, 20)) == 105))))
  run ignoredReportedAdmissionTest = assert(0.to(4).forall(q => validAnswers(q).forall(a => Set(-1, 0, 1, 2, 3, 99).forall(s => {
    val f = fixture(q, a, 1, 0)
    outcome(f.with("packet", f.packet.with("reportedAdmission", s))) == a
  }))))
  run retainedDerivationBindingTest = assert(0.to(4).forall(q => {
    val c = baseClaim(q, 1)
    val f = fixtureFor(c, 1)
    allClaimFields.forall(i => {
      val changed = changeClaimField(c, i)
      val g = fixtureFor(changed, 1)
      outcome(g.with("packet", g.packet.with("derivation", f.packet.derivation))) == 106
    })
  }))
  run coherentRebindAdmissionTest = assert(0.to(4).forall(q => {
    val c = baseClaim(q, 1)
    val f = fixtureFor(c, 1)
    allClaimFields.forall(i => outcome(coherentWithoutAdmission(f, changeClaimField(c, i))) == 107)
  }))
  run acceptedRetainsClaimTest = assert(0.to(4).forall(q => validAnswers(q).forall(a => {
    val c = baseClaim(q, a)
    val f = fixtureFor(c, 1)
    match replay(f.packet, f.trusted) {
      | Rejected(_) => false
      | Accepted(j) => j.claim == c and j.admissionStatus == 1 and verdictCode(j.verdict) == a
    }
  })))
  run opaqueScopeIdentifiersTest = assert({
    val c = baseClaim(0, 1)
    val empty = c.with("scope", c.scope.with("subject", "").with("target", "").with("context", "").with("time", ""))
    outcome(fixtureFor(empty, 1)) == 1
  })
  run validationPriorityTest = assert({
    val c = baseClaim(0, 1)
    val bad = c.with("source", c.source.with("locator", ""))
    val f = fixtureFor(c, 0)
    val packet = f.packet.with("claim", bad).with("derivation", f.packet.derivation.with("schema", 0))
    val trust = f.trusted.with("sourceEnabled", false).with("requestedScope", c.scope.with("time", "changed"))
    val g = { packet: packet, trusted: trust }
    and {
      outcome(onlyClaim(g, bad.with("answer", 35))) == 100,
      outcome(g) == 101,
      outcome(g.with("packet", packet.with("derivation", f.packet.derivation))) == 102,
      outcome(g.with("packet", f.packet)) == 103,
      outcome({ packet: f.packet, trusted: trust.with("requestedScope", c.scope) }) == 104,
      outcome(f) == 105,
      outcome(fixture(0, 1, 1, 19)) == 106,
      outcome(fixture(0, 1, 1, 28)) == 107
    }
  })
}
