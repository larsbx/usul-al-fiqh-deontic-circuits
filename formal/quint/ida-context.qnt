// Independent ACT-01 relation over the bounded ground pilot. No Lean output
// or evidence-admission decision is imported. The existing Quint relations
// supply the act-schema check and the separate candidate agency transition.
module idaContext {
  import ida as A from "./ida"
  import idaJudgment as J from "./ida-judgment"
  import idaDerivation as D from "./ida-derivation"
  import idaActRegistry as R from "./ida-act-registry"
  import agency as G from "./agency"

  type Definition = { key: R::KindKey, sorts: List[A::RefKind] }
  type Vocabulary = { pin: R::KindKey, definitions: List[Definition] }
  type Perspective = AsKnown | Retrospective
  type TimeView = { clockVersion: int, cutoff: int, perspective: Perspective }
  type Inquiry = {
    questionId: int, question: J::Question, scope: J::Scope,
    accountable: A::EntityRef, performer: A::Operand
  }
  type OpportunityChoice = PerformOnly | WithOpportunity(A::Opportunity)
  type Snapshot = {
    key: R::KindKey, vocabulary: Vocabulary, admissionPolicy: R::KindKey,
    envelope: R::Envelope, time: TimeView, inquiry: Inquiry, opportunity: OpportunityChoice
  }

  pure def versioned(key: R::KindKey): bool =
    A::validSymbol(key.symbol) and key.version > 0

  pure def coordinates(s: Snapshot): (int, int) =
    (s.envelope.context.contextId, s.envelope.context.timeId)

  pure def target(s: Snapshot): J::ScopeTarget = match s.opportunity {
    | PerformOnly => J::DescribedTarget(A::Perform(s.envelope.act))
    | WithOpportunity(o) => J::DescribedTarget(A::Omit({ act: s.envelope.act, opportunity: o }))
  }

  pure def typed(v: Vocabulary, q: R::Qualification): bool = {
    val key = { symbol: q.predicate, version: q.version }
    val signature = q.arguments.foldl(List(), (sorts, argument) => sorts.append(argument.kind))
    R::qualificationWellFormed(q) and
      v.definitions.select(d => d.key == key) == List({ key: key, sorts: signature })
  }

  pure def validTime(s: Snapshot): bool = {
    val m = s.envelope.context
    and {
      s.time.clockVersion > 0, m.recordedAt <= s.time.cutoff,
      match s.time.perspective {
        | AsKnown => s.time.cutoff == m.effectiveAt
        | Retrospective => s.time.cutoff > m.effectiveAt
      },
      match s.opportunity {
        | PerformOnly => true
        | WithOpportunity(o) => A::validOpportunity(o) and o.clock == m.clock
      },
    }
  }

  pure def wellFormed(s: Snapshot): bool = {
    val v = s.vocabulary
    val m = s.envelope.context
    val scope = s.inquiry.scope
    and {
      versioned(s.key), versioned(s.admissionPolicy), versioned(v.pin),
      v.definitions.foldl(Set(), (seen, d) => seen.union(Set(d.key))).size() == v.definitions.length(),
      indices(v.definitions).forall(i => versioned(v.definitions[i].key)),
      s.envelope.qualifications.foldl(true, (ok, q) => ok and typed(v, q)),
      R::structuralCode(R::baseRegistry, s.envelope) == 0,
      (scope.context, scope.time) == coordinates(s),
      scope.profile == m.profile, scope.profileVersion == m.profileVersion,
      scope.target == target(s),
      A::validEntity(s.inquiry.accountable), s.inquiry.accountable.kind == A::PersonRef,
      s.inquiry.performer.referent.kind == A::PersonRef,
      s.envelope.act.operands.select(o => o == s.inquiry.performer).length() > 0,
      validTime(s),
    }
  }

  pure def unambiguous(catalog: List[Snapshot]): bool = {
    val keySet = catalog.foldl(Set(), (seen, s) => seen.union(Set(s.key)))
    val pairs = catalog.foldl(Set(), (seen, s) => seen.union(Set(coordinates(s))))
    keySet.size() == catalog.length() and pairs.size() == catalog.length()
  }

  pure def compatible(s: Snapshot, t: Snapshot): bool = {
    val m = s.envelope.context
    val n = t.envelope.context
    and {
      s.vocabulary.pin != t.vocabulary.pin or s.vocabulary == t.vocabulary,
      m.timeId != n.timeId or
        (m.clock, s.time.clockVersion, m.effectiveAt) == (n.clock, t.time.clockVersion, n.effectiveAt),
      indices(s.vocabulary.definitions).forall(i => indices(t.vocabulary.definitions).forall(j => {
        val d = s.vocabulary.definitions[i]
        val e = t.vocabulary.definitions[j]
        d.key != e.key or d == e
      })),
    }
  }

  pure def consistent(catalog: List[Snapshot]): bool =
    indices(catalog).forall(i => indices(catalog).forall(j => compatible(catalog[i], catalog[j])))

  pure def matches(s: Snapshot, p: D::Premise): bool = {
    val record = p.request.record
    and {
      p.questionId == s.inquiry.questionId,
      record.questionCode == J::encodeQuestion(s.inquiry.question),
      record.scope == s.inquiry.scope,
      R::snapshotMatches(s.envelope, p),
    }
  }

  // Structural result only. The code has no ruling or evidence-admission case.
  pure def bindCode(catalog: List[Snapshot], expected: Snapshot, p: D::Premise): int = {
    val found = catalog.select(s => coordinates(s) == coordinates(expected))
    if (not(unambiguous(catalog))) 1
    else if (not(consistent(catalog))) 6
    else if (found.length() == 0) 2
    else if (found.length() != 1) 1
    else {
      val actual = found[0]
      if (actual != expected) 3
      else if (not(wellFormed(actual))) 4
      else if (not(matches(actual, p))) 5
      else 0
    }
  }

  pure val opportunity: A::Opportunity = {
    occurrence: { space: "synthetic.event", name: "one" }, clock: R::baseContext.clock,
    opensAt: 9, closesAt: 12
  }
  pure val predicate: Definition = {
    key: { symbol: R::baseQualification.predicate, version: 1 }, sorts: List(A::PersonRef)
  }
  pure val vocabulary: Vocabulary = {
    pin: { symbol: { space: "synthetic.vocab", name: "pilot" }, version: 1 },
    definitions: List(predicate)
  }

  pure def synchronize(s: Snapshot): Snapshot = {
    val m = s.envelope.context
    val scope = s.inquiry.scope.with("target", target(s))
      .with("context", m.contextId).with("time", m.timeId)
      .with("profile", m.profile).with("profileVersion", m.profileVersion)
    s.with("inquiry", s.inquiry.with("scope", scope))
  }

  pure val base: Snapshot = synchronize({
    key: { symbol: { space: "synthetic.snapshot", name: "pilot" }, version: 1 },
    vocabulary: vocabulary,
    admissionPolicy: { symbol: { space: "synthetic.policy", name: "test" }, version: 1 },
    envelope: R::baseEnvelope.with("context", R::baseContext.with("recordedAt", 9)),
    time: { clockVersion: 1, cutoff: 10, perspective: AsKnown },
    inquiry: { questionId: 1, question: J::Shart, scope: R::basePremise.request.record.scope,
      accountable: R::recipient, performer: R::payerOperand },
    opportunity: WithOpportunity(opportunity)
  })

  pure def withMetadata(s: Snapshot, m: R::ContextSnapshot): Snapshot =
    synchronize(s.with("envelope", s.envelope.with("context", m)))

  pure def withQualifications(qs: List[R::Qualification]): Snapshot =
    base.with("envelope", base.envelope.with("qualifications", qs))

  pure def atTick(tick: int): Snapshot =
    withMetadata(base, base.envelope.context.with("effectiveAt", tick).with("recordedAt", tick))
      .with("time", base.time.with("cutoff", tick))

  pure def snapshotCase(n: int): Snapshot = {
    val q = R::baseQualification
    val m = base.envelope.context
    if (n == 1) withQualifications(List(q.with("polarity", false)))
    else if (n == 2) withQualifications(List(q.with("arguments", List(R::recipient))))
    else if (n == 3) withQualifications(List(q.with("arguments", List(R::property))))
    else if (n == 4) withQualifications(List(q.with("version", 2)))
    else if (n == 5) base.with("vocabulary",
      vocabulary.with("definitions", List(predicate, predicate.with("sorts", List(A::AssetRef)))))
    else if (n == 6) withMetadata(base, m.with("evidenceRevision", 2))
    else if (n == 7) withMetadata(base, m.with("clock", m.clock.with("name", "other")))
    else if (n == 8) atTick(9)
    else if (n == 9) atTick(12)
    else if (n == 10) withMetadata(base, m.with("recordedAt", 11))
      .with("time", { clockVersion: 1, cutoff: 12, perspective: Retrospective })
    else if (n == 11) base.with("time", base.time.with("cutoff", 11))
    else if (n == 12) withMetadata(base, m.with("recordedAt", 11))
    else if (n == 13) base.with("inquiry", base.inquiry.with("performer", R::recipientOperand))
    else if (n == 14) base.with("inquiry", base.inquiry.with("accountable", R::payer))
    else if (n == 15) base.with("inquiry", base.inquiry.with("performer", R::propertyOperand))
    else if (n == 16) base.with("inquiry", base.inquiry.with("scope",
      base.inquiry.scope.with("target", J::OpaqueTarget({ id: 1, kind: J::Behavior }))))
    else if (n == 17) base.with("inquiry", base.inquiry.with("scope",
      base.inquiry.scope.with("profileVersion", 2)))
    else if (n == 18) synchronize(base.with("envelope", base.envelope.with("act", R::envelopeCase(9).act))
      .with("inquiry", base.inquiry.with("performer", R::payerOperand.with("referent", R::recipient))))
    else if (n == 19) base.with("time", base.time.with("clockVersion", 2))
    else if (n == 20) synchronize(base.with("opportunity", WithOpportunity(
      opportunity.with("occurrence", opportunity.occurrence.with("name", "other")))))
    else if (n == 21) synchronize(base.with("opportunity", WithOpportunity(opportunity.with("closesAt", 13))))
    else if (n == 22) withQualifications(List())
    else if (n == 23) synchronize(base.with("opportunity", PerformOnly))
    else if (n == 24) synchronize(base.with("opportunity", WithOpportunity(opportunity.with("closesAt", 9))))
    else if (n == 25) base.with("admissionPolicy", base.admissionPolicy.with("version", 2))
    else if (n == 26) withQualifications(List(q, q.with("polarity", false)))
    else if (n == 27) withMetadata(base, m.with("evidenceRevision", 2))
      .with("key", base.key.with("version", 2))
    else base
  }

  pure def catalogCase(n: int, s: Snapshot): List[Snapshot] = {
    val otherKey = s.with("key", s.key.with("version", s.key.version + 1))
    val other = withMetadata(otherKey, s.envelope.context.with("contextId", 2))
    if (n == 0) List(s)
    else if (n == 1) List(base)
    else if (n == 2) List(s, otherKey)
    else if (n == 3) List(s, other.with("key", s.key))
    else if (n == 4) List()
    else if (n == 5) List(s, other.with("vocabulary", {
      pin: s.vocabulary.pin.with("version", 2),
      definitions: List(predicate.with("sorts", List(A::AssetRef)))
    }))
    else if (n == 6) List(s, other.with("time", other.time.with("clockVersion", other.time.clockVersion + 1)))
    else if (n == 7) List(s, other)
    else if (n == 8) List(s, s)
    else if (n == 9) List(s, other.with("vocabulary", s.vocabulary.with("definitions", List())))
    else List()
  }

  pure def premiseCase(n: int, s: Snapshot): D::Premise = {
    val p = R::renewedPremise(s.envelope).with("questionId", s.inquiry.questionId)
    val scope = s.inquiry.scope
    val r = p.request.record.with("questionCode", J::encodeQuestion(s.inquiry.question)).with("scope", scope)
    if (n == 1) D::withRaw(p.with("questionId", p.questionId + 1), r)
    else if (n == 2) D::withRaw(p, r.with("questionCode", 4))
    else if (n == 3) D::withRaw(p, r.with("scope", scope.with("subjectId", scope.subjectId + 1)))
    else if (n == 4) D::withRaw(p, r.with("scope", scope.with("domain", J::Ibada)))
    else if (n == 5) D::withRaw(p, r.with("scope", scope.with("target", J::OpaqueTarget({ id: 1, kind: J::Behavior }))))
    else if (n == 6) D::withRaw(p, r.with("scope", scope.with("time", scope.time + 1)))
    else if (n == 7) D::withRaw(p, r.with("provenance",
      r.provenance.with("interpretationVersion", r.provenance.interpretationVersion + 1)))
    else if (n == 8) D::withRaw(p, r.with("scope", scope.with("profileVersion", scope.profileVersion + 1)))
    else if (n == 9) D::withRaw(p, r.with("scope",
      scope.with("subject", scope.subject.with("aqil", not(scope.subject.aqil)))))
    else D::withRaw(p, r)
  }

  pure def compareCase(s: int, c: int, p: int): int = {
    val expected = snapshotCase(s)
    bindCode(catalogCase(c, expected), expected, premiseCase(p, expected))
  }

  pure def phase(o: A::Opportunity, tick: int): int =
    if (tick >= o.closesAt) 2 else if (tick >= o.opensAt) 1 else 0

  pure def agencyCase(profile: int, history: int, coordinate: int): int = {
    val cfg = { profile: if (profile == 0) G::Immediate else G::OnKnowledge, independent: true }
    val extra = if (history == 1) List(G::NotifyA) else if (history == 2) List(G::NotifyB)
      else if (history == 3) List(G::NotifyA, G::NotifyB) else List()
    val events = List(G::Appoint, G::ExecuteA, G::Revoke).concat(extra)
    val end = events.foldl(G::Enabled(G::initialState), (current, event) => match current {
      | Disabled => G::Disabled
      | Enabled(s) => G::transition(cfg, s, event)
    })
    match end {
      | Disabled => 2
      | Enabled(s) => {
        val observed = if (coordinate == 0) s.accepted == G::AExecution
          else if (coordinate == 1) G::canAct(cfg, s, G::AgentA) else G::canAct(cfg, s, G::AgentB)
        if (observed) 1 else 0
      }
    }
  }

  pure def reviewCase(profile: int, scenario: int, perspective: int, coordinate: int): int = {
    val cfg = { profile: if (profile == 0) G::Immediate else G::OnKnowledge, independent: true }
    val execution = 10
    val cutoff = if (perspective == 0) 10 else 15
    val evidence = { effectiveAt: List(12, 8, 8, 8, 10, 8)[scenario], recordedAt: 15 }
    val notice = List(0, 0, 9, 12, 0, 7)[scenario]
    val visible = evidence.recordedAt <= cutoff
    val revoked = if (visible) List(G::Revoke) else List()
    val noticed = if (visible and notice > 0) List(G::NotifyA) else List()
    val events =
      if (evidence.effectiveAt >= execution) List(G::ExecuteA).concat(revoked).concat(noticed)
      else if (notice > 0 and notice < execution) revoked.concat(noticed).append(G::ExecuteA)
      else revoked.append(G::ExecuteA).concat(noticed)
    val replay = List(G::Appoint).concat(events).foldl(G::Enabled(G::initialState), (current, event) =>
      match current {
        | Disabled => G::Disabled
        | Enabled(s) => G::transition(cfg, s, event)
      })
    if (evidence.effectiveAt == execution or (notice > 0 and notice <= evidence.effectiveAt)) 3
    else match replay {
      | Disabled => 2
      | Enabled(s) => {
        val observed = if (coordinate == 0) s.accepted == G::AExecution
          else if (coordinate == 1) G::canAct(cfg, s, G::AgentA) else s.knownA
        if (observed) 1 else 0
      }
    }
  }

  run agencyReviewTest = assert(and {
    reviewCase(0, 0, 1, 0) == 1, reviewCase(0, 0, 1, 1) == 0,
    reviewCase(0, 1, 0, 0) == 1, reviewCase(0, 1, 1, 0) == 2,
    reviewCase(1, 1, 1, 0) == 1, reviewCase(1, 1, 1, 2) == 0,
    reviewCase(1, 2, 0, 2) == 0, reviewCase(1, 2, 1, 0) == 2,
    reviewCase(1, 3, 1, 0) == 1, reviewCase(1, 3, 1, 2) == 1,
    reviewCase(0, 4, 1, 0) == 3, reviewCase(0, 5, 1, 0) == 3,
  })

  run exactIdentityTest = assert(and {
    compareCase(0, 0, 0) == 0,
    compareCase(0, 2, 0) == 1, compareCase(0, 3, 0) == 1, compareCase(0, 8, 0) == 1,
    compareCase(0, 4, 0) == 2,
    compareCase(0, 5, 0) == 6, compareCase(0, 6, 0) == 6, compareCase(0, 9, 0) == 6,
    compareCase(0, 7, 0) == 0,
    target(snapshotCase(1)) == target(base),
    Set(1, 2, 6, 13, 14, 18, 19, 20, 21, 22, 25, 26).forall(s => compareCase(s, 1, 0) == 3),
    1.to(9).forall(p => compareCase(0, 0, p) == 5),
  })

  run syntaxAndTimeTest = assert(and {
    Set(3, 4, 7, 11, 12, 15, 16, 17, 24).forall(s => compareCase(s, 0, 0) == 4),
    compareCase(5, 0, 0) == 6, // a single vocabulary conflicts with itself
    Set(8, 9, 10, 23, 26).forall(s => compareCase(s, 0, 0) == 0),
    phase(opportunity, 8) == 0, phase(opportunity, 9) == 1, phase(opportunity, 12) == 2,
  })

  run candidateSourceTest = {
    val s = snapshotCase(23)
    val p = premiseCase(0, s)
    assert(bindCode(List(s), s, p) == 0 and
      not(D::accepted(D::evaluateSource(R::environmentCase(1, p), p))))
  }

  run evidenceRevisionTest = {
    val updated = snapshotCase(27)
    val updatedCatalog = List(updated)
    assert(and {
      target(updated) == target(base),
      bindCode(updatedCatalog, base, premiseCase(0, base)) == 3,
      bindCode(updatedCatalog, updated, premiseCase(0, updated)) == 0,
      agencyCase(0, 0, 0) == 1, agencyCase(0, 0, 1) == 0,
      agencyCase(1, 0, 1) == 1, agencyCase(1, 1, 1) == 0, agencyCase(1, 1, 2) == 1,
    })
  }
}
