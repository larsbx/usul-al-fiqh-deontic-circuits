// Finite joint-agency pilot. Source choices and exclusions:
// ../../docs/research/agency-source-profile.md
// The two revocation profiles remain distinct. This is a scoped operational
// interpretation of the cited rules, not a general contract-validity oracle.
module agency {
  type RevocationProfile = Immediate | OnKnowledge
  type Config = { profile: RevocationProfile, independent: bool }
  type Agent = AgentA | AgentB
  type Acceptance = NoExecution | AExecution | BExecution | JointExecution
  type State = {
    appointed: bool,
    revoked: bool,
    knownA: bool,
    knownB: bool,
    withdrawnA: bool,
    withdrawnB: bool,
    accepted: Acceptance,
  }
  type Event = Appoint | Revoke | NotifyA | NotifyB | WithdrawA | WithdrawB
    | ExecuteA | ExecuteB | ExecuteJoint | Stutter
    | ExecuteAOutsideScope | ExecuteBOutsideScope | ExecuteJointOutsideScope
  type Transition = Disabled | Enabled(State)

  pure val initialState: State = {
    appointed: false,
    revoked: false,
    knownA: false,
    knownB: false,
    withdrawnA: false,
    withdrawnB: false,
    accepted: NoExecution,
  }

  // Authority at the time of execution. Knowledge is agent-specific; a later
  // notice or revocation never erases the historical accepted-execution field.
  pure def canAct(cfg: Config, s: State, agent: Agent): bool = {
    val withdrawn = match agent {
      | AgentA => s.withdrawnA
      | AgentB => s.withdrawnB
    }
    val known = match agent {
      | AgentA => s.knownA
      | AgentB => s.knownB
    }
    val revocationAllows = match cfg.profile {
      | Immediate => not(s.revoked)
      | OnKnowledge => not(known)
    }
    s.appointed and not(withdrawn) and revocationAllows
  }

  pure def canActAlone(cfg: Config, s: State, agent: Agent): bool =
    cfg.independent and canAct(cfg, s, agent)

  // Only one appointment and one modeled execution. The identity of the
  // jointly appointed pair and the grant's scope stay fixed throughout a run.
  // Administrative events are retained after execution to test history safety.
  pure def transition(cfg: Config, s: State, event: Event): Transition =
    match event {
      | Appoint => if (not(s.appointed))
          Enabled(s.with("appointed", true)) else Disabled
      | Revoke => if (s.appointed and not(s.revoked))
          Enabled(s.with("revoked", true)) else Disabled
      | NotifyA => if (s.revoked and not(s.knownA))
          Enabled(s.with("knownA", true)) else Disabled
      | NotifyB => if (s.revoked and not(s.knownB))
          Enabled(s.with("knownB", true)) else Disabled
      | WithdrawA => if (s.appointed and not(s.withdrawnA))
          Enabled(s.with("withdrawnA", true)) else Disabled
      | WithdrawB => if (s.appointed and not(s.withdrawnB))
          Enabled(s.with("withdrawnB", true)) else Disabled
      | ExecuteA => if (s.accepted == NoExecution and canActAlone(cfg, s, AgentA))
          Enabled(s.with("accepted", AExecution)) else Disabled
      | ExecuteB => if (s.accepted == NoExecution and canActAlone(cfg, s, AgentB))
          Enabled(s.with("accepted", BExecution)) else Disabled
      | ExecuteJoint => if (s.accepted == NoExecution
          and canAct(cfg, s, AgentA) and canAct(cfg, s, AgentB))
          Enabled(s.with("accepted", JointExecution)) else Disabled
      | Stutter => Enabled(s)
      | ExecuteAOutsideScope => Disabled
      | ExecuteBOutsideScope => Disabled
      | ExecuteJointOutsideScope => Disabled
    }

  // Wire contract with the independently implemented Lean model. All 256 raw
  // states, including unreachable combinations, are compared; reachability is
  // checked separately from the all-false/no-execution initial state.
  pure def bit(value: bool): int = if (value) 1 else 0
  pure def encodeState(s: State): int = {
    val acceptance = match s.accepted {
      | NoExecution => 0
      | AExecution => 1
      | BExecution => 2
      | JointExecution => 3
    }
    bit(s.appointed) + 2 * bit(s.revoked) + 4 * bit(s.knownA)
      + 8 * bit(s.knownB) + 16 * bit(s.withdrawnA)
      + 32 * bit(s.withdrawnB) + 64 * acceptance
  }
  pure def decodeState(code: int): State = {
    appointed: code % 2 == 1,
    revoked: (code / 2) % 2 == 1,
    knownA: (code / 4) % 2 == 1,
    knownB: (code / 8) % 2 == 1,
    withdrawnA: (code / 16) % 2 == 1,
    withdrawnB: (code / 32) % 2 == 1,
    accepted: if (code / 64 == 0) NoExecution
      else if (code / 64 == 1) AExecution
      else if (code / 64 == 2) BExecution else JointExecution,
  }
  pure def encodeConfig(cfg: Config): int =
    (match cfg.profile { | Immediate => 0 | OnKnowledge => 2 })
      + bit(cfg.independent)
  pure def decodeConfig(code: int): Config = {
    profile: if (code < 2) Immediate else OnKnowledge,
    independent: code % 2 == 1,
  }
  pure def encodeEvent(event: Event): int = match event {
    | Appoint => 0 | Revoke => 1 | NotifyA => 2 | NotifyB => 3
    | WithdrawA => 4 | WithdrawB => 5 | ExecuteA => 6 | ExecuteB => 7
    | ExecuteJoint => 8 | Stutter => 9 | ExecuteAOutsideScope => 10
    | ExecuteBOutsideScope => 11 | ExecuteJointOutsideScope => 12
  }
  pure def decodeEvent(code: int): Event =
    if (code == 0) Appoint else if (code == 1) Revoke
    else if (code == 2) NotifyA else if (code == 3) NotifyB
    else if (code == 4) WithdrawA else if (code == 5) WithdrawB
    else if (code == 6) ExecuteA else if (code == 7) ExecuteB
    else if (code == 8) ExecuteJoint else if (code == 9) Stutter
    else if (code == 10) ExecuteAOutsideScope
    else if (code == 11) ExecuteBOutsideScope else ExecuteJointOutsideScope

  pure def nextCode(configCode: int, stateCode: int, eventCode: int): int =
    match transition(decodeConfig(configCode), decodeState(stateCode), decodeEvent(eventCode)) {
      | Disabled => -1
      | Enabled(nextState) => encodeState(nextState)
    }

  // Rejected attempts return -1 and leave the current state available to the
  // next attempt. This is a scenario-runner convention, not a model transition.
  pure def outcomes(configCode: int, events: List[int]): List[int] = {
    val result = events.foldl((0, List()), (acc, event) => {
      val nextState = nextCode(configCode, acc._1, event)
      (if (nextState < 0) acc._1 else nextState, acc._2.append(nextState))
    })
    result._2
  }

  var config: Config
  var state: State
  var previous: State
  var lastEvent: int

  action initFor(configCode: int): bool = all {
    config' = decodeConfig(configCode),
    state' = initialState,
    previous' = initialState,
    lastEvent' = -1,
  }
  action init = {
    nondet configCode = 0.to(3).oneOf()
    initFor(configCode)
  }
  action take(event: Event): bool = {
    val result = transition(config, state, event)
    all {
      result != Disabled,
      config' = config,
      state' = match result { | Disabled => state | Enabled(nextState) => nextState },
      previous' = state,
      lastEvent' = encodeEvent(event),
    }
  }
  action step = any {
    take(Appoint), take(Revoke), take(NotifyA), take(NotifyB),
    take(WithdrawA), take(WithdrawB), take(ExecuteA), take(ExecuteB),
    take(ExecuteJoint), take(Stutter), take(ExecuteAOutsideScope),
    take(ExecuteBOutsideScope), take(ExecuteJointOutsideScope),
  }

  val wellFormed = and {
    state.revoked implies state.appointed,
    state.knownA implies state.revoked,
    state.knownB implies state.revoked,
    state.withdrawnA implies state.appointed,
    state.withdrawnB implies state.appointed,
    state.accepted != NoExecution implies state.appointed,
  }
  val historyStable = previous.accepted != NoExecution
    implies state.accepted == previous.accepted
  val newExecution = previous.accepted == NoExecution
    and state.accepted != NoExecution
  val jointRequirement = newExecution
    implies (state.accepted == JointExecution or config.independent)
  val scopePreserved = newExecution implies lastEvent.in(Set(6, 7, 8))
  val authorityAtExecution = newExecution implies match state.accepted {
    | NoExecution => false
    | AExecution => canAct(config, previous, AgentA)
    | BExecution => canAct(config, previous, AgentB)
    | JointExecution => canAct(config, previous, AgentA)
        and canAct(config, previous, AgentB)
  }
  val safety = wellFormed and historyStable and jointRequirement
    and scopePreserved and authorityAtExecution

  // Deterministic tests: --max-samples=1 does not subsample any forall below.
  run codecRoundtripTest = assert(and {
    0.to(255).forall(code => encodeState(decodeState(code)) == code),
    0.to(3).forall(code => encodeConfig(decodeConfig(code)) == code),
    0.to(12).forall(code => encodeEvent(decodeEvent(code)) == code),
  })
  run jointExecutionTest = initFor(0).then(take(Appoint))
    .then(take(ExecuteJoint)).expect(state.accepted == JointExecution and safety)
  run jointSoloRejectedTest = initFor(0).then(take(Appoint))
    .then(take(ExecuteA).fail())
  run immediateRevocationTest = initFor(0).then(take(Appoint))
    .then(take(Revoke)).expect(transition(config, state, ExecuteJoint) == Disabled
      and state.revoked and not(state.knownA) and state.accepted == NoExecution)
  run knowledgeBeforeNoticeTest = initFor(2).then(take(Appoint))
    .then(take(Revoke)).then(take(ExecuteJoint))
    .expect(state.accepted == JointExecution and safety)
  run asymmetricNoticeTest = initFor(3).then(take(Appoint))
    .then(take(Revoke)).then(take(NotifyA))
    .expect(transition(config, state, ExecuteA) == Disabled)
    .then(take(ExecuteB)).expect(state.accepted == BExecution and safety)
  run withdrawalBlocksJointTest = initFor(0).then(take(Appoint))
    .then(take(WithdrawA)).expect(transition(config, state, ExecuteJoint) == Disabled
      and state.withdrawnA and state.accepted == NoExecution)
  run acceptedHistoryTest = initFor(1).then(take(Appoint))
    .then(take(ExecuteA)).then(take(Revoke)).then(take(NotifyA))
    .expect(state.accepted == AExecution and safety)
  run scopeRejectedTest = initFor(1).then(take(Appoint))
    .expect(and {
      transition(config, state, ExecuteAOutsideScope) == Disabled,
      transition(config, state, ExecuteBOutsideScope) == Disabled,
      transition(config, state, ExecuteJointOutsideScope) == Disabled,
      state.accepted == NoExecution,
    })
}
