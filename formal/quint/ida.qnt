// Independent Quint foundation for IDA. No claim is made about a concrete ruling.
// H < K < M < N < W is an order of favor toward doing. Evidence combines by set
// intersection, never by choosing the greater point in that order.
module ida {
  type Hukm = H | K | M | N | W

  pure val carrier: Set[Hukm] = Set(H, K, M, N, W)

  // Semantic order: direct cases, independent of the integer wire encoding.
  pure def leq(a: Hukm, b: Hukm): bool = match a {
    | H => true
    | K => b != H
    | M => Set(M, N, W).contains(b)
    | N => Set(N, W).contains(b)
    | W => b == W
  }

  pure def meet(a: Hukm, b: Hukm): Hukm = if (leq(a, b)) a else b
  pure def join(a: Hukm, b: Hukm): Hukm = if (leq(a, b)) b else a
  pure def sigma(a: Hukm): Hukm = match a {
    | H => W
    | K => N
    | M => M
    | N => K
    | W => H
  }

  // Full target descriptions; signatures and reference meanings still need
  // source/profile admission outside this structural layer.
  type Symbol = { space: str, name: str }
  type RefKind = PersonRef | AssetRef | ObligationRef | OccurrenceRef | PropositionRef
  type EntityRef = { kind: RefKind, symbol: Symbol }
  type Parameter = { role: str, kind: RefKind }
  type Operand = { role: str, referent: EntityRef }
  type Operation = { symbol: Symbol, parameters: List[Parameter] }
  type Act = { operation: Operation, operands: List[Operand] }
  type Opportunity = { occurrence: Symbol, clock: Symbol, opensAt: int, closesAt: int }
  type Affect = { quality: Symbol, concerns: EntityRef }
  type Omission = { act: Act, opportunity: Opportunity }
  type Target = Perform(Act) | Omit(Omission) | Affective(Affect)

  pure def validSymbol(value: Symbol): bool =
    value.space != "" and value.name != ""
  pure def validEntity(value: EntityRef): bool = validSymbol(value.symbol)

  pure def validOperation(operation: Operation): bool = and {
    validSymbol(operation.symbol),
    indices(operation.parameters).forall(i => operation.parameters[i].role != ""),
    indices(operation.parameters).forall(i => indices(operation.parameters).forall(j =>
      (i != j).implies(operation.parameters[i].role != operation.parameters[j].role))),
  }

  pure def operandParameters(operands: List[Operand]): List[Parameter] =
    operands.foldl(List(), (parameters, operand) =>
      parameters.append({ role: operand.role, kind: operand.referent.kind }))

  pure def validAct(act: Act): bool = and {
    validOperation(act.operation),
    operandParameters(act.operands) == act.operation.parameters,
    indices(act.operands).forall(i => validEntity(act.operands[i].referent)),
  }
  pure def validOpportunity(opportunity: Opportunity): bool = and {
    validSymbol(opportunity.occurrence),
    validSymbol(opportunity.clock),
    opportunity.opensAt >= 0,
    opportunity.opensAt < opportunity.closesAt,
  }
  pure def validAffect(affect: Affect): bool =
    validSymbol(affect.quality) and validEntity(affect.concerns)
  pure def validTarget(target: Target): bool = match target {
    | Perform(act) => validAct(act)
    | Omit(omission) => validAct(omission.act) and validOpportunity(omission.opportunity)
    | Affective(affect) => validAffect(affect)
  }

  // Field-by-field equality is independent of Lean's derived equality.
  pure def sameSymbol(a: Symbol, b: Symbol): bool = and {
    a.space == b.space,
    a.name == b.name,
  }
  pure def sameEntity(a: EntityRef, b: EntityRef): bool = and {
    a.kind == b.kind,
    sameSymbol(a.symbol, b.symbol),
  }
  pure def sameParameter(left: Parameter, right: Parameter): bool =
    left.role == right.role and left.kind == right.kind
  pure def sameParameters(a: List[Parameter], b: List[Parameter]): bool = {
    if (length(a) != length(b)) false
    else indices(a).forall(i => sameParameter(a[i], b[i]))
  }
  pure def sameOperand(a: Operand, b: Operand): bool = and {
    a.role == b.role,
    sameEntity(a.referent, b.referent),
  }
  pure def sameOperands(a: List[Operand], b: List[Operand]): bool = {
    if (length(a) != length(b)) false
    else indices(a).forall(i => sameOperand(a[i], b[i]))
  }
  pure def sameOperation(a: Operation, b: Operation): bool = and {
    sameSymbol(a.symbol, b.symbol),
    sameParameters(a.parameters, b.parameters),
  }
  pure def sameAct(a: Act, b: Act): bool = and {
    sameOperation(a.operation, b.operation),
    sameOperands(a.operands, b.operands),
  }
  pure def sameOpportunity(a: Opportunity, b: Opportunity): bool = and {
    sameSymbol(a.occurrence, b.occurrence),
    sameSymbol(a.clock, b.clock),
    a.opensAt == b.opensAt,
    a.closesAt == b.closesAt,
  }
  pure def sameAffect(a: Affect, b: Affect): bool = and {
    sameSymbol(a.quality, b.quality),
    sameEntity(a.concerns, b.concerns),
  }
  pure def sameTarget(left: Target, right: Target): bool = match left {
    | Perform(a) => match right {
      | Perform(b) => sameAct(a, b)
      | _ => false
    }
    | Omit(a) => match right {
      | Omit(b) => sameAct(a.act, b.act) and sameOpportunity(a.opportunity, b.opportunity)
      | _ => false
    }
    | Affective(a) => match right {
      | Affective(b) => sameAffect(a, b)
      | _ => false
    }
  }

  pure def targetSymbol(space: str, name: str): Symbol = { space: space, name: name }
  pure def targetRef(kind: RefKind, space: str, name: str): EntityRef =
    { kind: kind, symbol: targetSymbol(space, name) }

  pure val debtRef: EntityRef = targetRef(ObligationRef, "demo.debt", "D")
  pure val creditorRef: EntityRef = targetRef(PersonRef, "demo.person", "creditor")
  pure val recipientRef: EntityRef = targetRef(PersonRef, "demo.person", "recipient")
  pure val debtParameter: Parameter = { role: "debt", kind: ObligationRef }
  pure val creditorParameter: Parameter = { role: "creditor", kind: PersonRef }
  pure val recipientParameter: Parameter = { role: "recipient", kind: PersonRef }
  pure val debtOperand: Operand = { role: "debt", referent: debtRef }
  pure val creditorOperand: Operand = { role: "creditor", referent: creditorRef }
  pure val recipientOperand: Operand = { role: "recipient", referent: recipientRef }

  pure val repayOperation: Operation = {
    symbol: targetSymbol("demo.action", "repay_debt"),
    parameters: List(debtParameter, creditorParameter, recipientParameter)
  }
  pure val repayAct: Act = {
    operation: repayOperation,
    operands: List(debtOperand, creditorOperand, recipientOperand)
  }
  pure val promiseAct: Act = repayAct.with("operation", repayOperation.with(
    "symbol", targetSymbol("demo.action", "promise_repayment")))
  pure val baseOpportunity: Opportunity = {
    occurrence: targetSymbol("demo.occasion", "installment_one"),
    clock: targetSymbol("demo.clock", "ticks"),
    opensAt: 100, closesAt: 200
  }
  pure val baseAffect: Affect = {
    quality: targetSymbol("demo.affect", "concern"), concerns: debtRef
  }

  // Actor comes from Key.subject; control remains in context.
  // These signatures and case names are synthetic, with no ruling asserted.
  pure val rawTargetCases: List[Target] = List(
    // 0
    Perform(repayAct),
    // 1: independently reconstructed, identical to 0
    Perform({
      operation: {
        symbol: { space: "demo.action", name: "repay_debt" },
        parameters: List(
          { role: "debt", kind: ObligationRef },
          { role: "creditor", kind: PersonRef },
          { role: "recipient", kind: PersonRef })
      },
      operands: List(
        { role: "debt", referent: {
          kind: ObligationRef, symbol: { space: "demo.debt", name: "D" } }},
        { role: "creditor", referent: {
          kind: PersonRef, symbol: { space: "demo.person", name: "creditor" } }},
        { role: "recipient", referent: {
          kind: PersonRef, symbol: { space: "demo.person", name: "recipient" } }})
    }),
    // 2..7: operation, namespace, reference and role changes
    Perform(promiseAct),
    Perform(repayAct.with("operation", repayOperation.with(
      "symbol", targetSymbol("other.action", "repay_debt")))),
    Perform(repayAct.with("operands", List(
      { role: "debt", referent: targetRef(ObligationRef, "demo.debt", "E") },
      creditorOperand, recipientOperand))),
    Perform(repayAct.with("operands", List(
      { role: "debt", referent: targetRef(ObligationRef, "other.debt", "D") },
      creditorOperand, recipientOperand))),
    Perform(repayAct.with("operands", List(
      debtOperand, { role: "creditor", referent: recipientRef },
      { role: "recipient", referent: creditorRef }))),
    Perform({
      operation: repayOperation.with("parameters", List(
        debtParameter, creditorParameter, { role: "payee", kind: PersonRef })),
      operands: List(
        debtOperand, creditorOperand, { role: "payee", referent: recipientRef })
    }),
    // 8..13: omission, act and every opportunity field
    Omit({ act: repayAct, opportunity: baseOpportunity }),
    Omit({ act: promiseAct, opportunity: baseOpportunity }),
    Omit({ act: repayAct, opportunity: baseOpportunity.with(
      "occurrence", targetSymbol("demo.occasion", "installment_two")) }),
    Omit({ act: repayAct, opportunity: baseOpportunity.with(
      "clock", targetSymbol("demo.clock", "other_ticks")) }),
    Omit({ act: repayAct, opportunity: baseOpportunity.with("opensAt", 101) }),
    Omit({ act: repayAct, opportunity: baseOpportunity.with("closesAt", 201) }),
    // 14..17: affect quality and its typed object
    Affective(baseAffect),
    Affective(baseAffect.with("quality", targetSymbol("demo.affect", "aversion"))),
    Affective(baseAffect.with("concerns", targetRef(ObligationRef, "demo.debt", "E"))),
    Affective(baseAffect.with("concerns", debtRef.with("kind", AssetRef))),
    // 18..19: signature identity, with wellformed matching arguments
    Perform({
      operation: repayOperation.with("parameters", List(
        debtParameter.with("kind", AssetRef), creditorParameter, recipientParameter)),
      operands: List(
        debtOperand.with("referent", debtRef.with("kind", AssetRef)),
        creditorOperand, recipientOperand)
    }),
    Perform({
      operation: repayOperation.with("parameters", List(
        recipientParameter, creditorParameter, debtParameter)),
      operands: List(recipientOperand, creditorOperand, debtOperand)
    }),
    // 20..27: malformed shape, sort, roles, names, intervals or operand order
    Perform(repayAct.with("operands", List(debtOperand, creditorOperand))),
    Perform(repayAct.with("operands", List(
      debtOperand.with("referent", debtRef.with("kind", PersonRef)),
      creditorOperand, recipientOperand))),
    Perform({
      operation: repayOperation.with("parameters", List(
        debtParameter, recipientParameter, recipientParameter)),
      operands: List(debtOperand, { role: "recipient", referent: creditorRef }, recipientOperand)
    }),
    Perform(repayAct.with("operation", repayOperation.with(
      "symbol", targetSymbol("demo.action", "")))),
    Perform(repayAct.with("operands", List(
      debtOperand.with("referent", targetRef(ObligationRef, "demo.debt", "")),
      creditorOperand, recipientOperand))),
    Omit({ act: repayAct, opportunity: baseOpportunity.with("closesAt", 100) }),
    Omit({ act: repayAct, opportunity:
      baseOpportunity.with("opensAt", 200).with("closesAt", 100) }),
    Perform(repayAct.with("operands", List(recipientOperand, creditorOperand, debtOperand)))
  )

  type TargetCaseDecode = InvalidTargetCase | DecodedTargetCase(Target)
  pure def targetCase(code: int): TargetCaseDecode = {
    if (code >= 0 and code < length(rawTargetCases))
      DecodedTargetCase(rawTargetCases[code])
    else InvalidTargetCase
  }
  pure def targetAdmitCode(code: int): int = match targetCase(code) {
    | InvalidTargetCase => -1
    | DecodedTargetCase(target) => if (validTarget(target)) 1 else 0
  }

  type KeyTarget = LegacyKeyTarget(int) | StructuredKeyTarget(Target)

  pure def validKeyTarget(target: KeyTarget): bool = match target {
    | LegacyKeyTarget(id) => id >= 0
    | StructuredKeyTarget(expression) => validTarget(expression)
  }

  pure def sameKeyTarget(left: KeyTarget, right: KeyTarget): bool = match left {
    | LegacyKeyTarget(a) => match right {
      | LegacyKeyTarget(b) => a == b
      | _ => false
    }
    | StructuredKeyTarget(a) => match right {
      | StructuredKeyTarget(b) => sameTarget(a, b)
      | _ => false
    }
  }

  type Key = {
    question: int,
    subject: int,
    target: KeyTarget,
    context: int,
    time: int,
    profile: int,
    version: int
  }

  type Input = NoRuling | Suspended | Known(Set[Hukm])
  type Result = RNoRuling | RSuspended | RKnown(Set[Hukm]) | Conflict | OutOfScope

  // An empty Known set is outside the input domain. It is represented by
  // Conflict only when the intersection of two valid premises is empty.
  pure def validInput(input: Input): bool = match input {
    | NoRuling => true
    | Suspended => true
    | Known(values) => values.size() > 0
  }

  pure def isSuspended(input: Input): bool = match input {
    | Suspended => true
    | _ => false
  }

  pure def isMissing(input: Input): bool = match input {
    | NoRuling => true
    | _ => false
  }

  pure def sameKey(a: Key, b: Key): bool = and {
    a.question == b.question,
    a.subject == b.subject,
    sameKeyTarget(a.target, b.target),
    a.context == b.context,
    a.time == b.time,
    a.profile == b.profile,
    a.version == b.version,
  }

  // Both inputs are REQUIRED premises. Precondition: validInput(left/right).
  // Precedence: scope mismatch, suspension, missing premise, intersection.
  pure def refine(leftKey: Key, left: Input, rightKey: Key, right: Input): Result = {
    if (not(validKeyTarget(leftKey.target) and validKeyTarget(rightKey.target))) OutOfScope
    else if (not(sameKey(leftKey, rightKey))) OutOfScope
    else if (isSuspended(left) or isSuspended(right)) RSuspended
    else if (isMissing(left) or isMissing(right)) RNoRuling
    else match left {
      | Known(leftValues) => match right {
        | Known(rightValues) => {
          val common = leftValues.intersect(rightValues)
          if (common.size() == 0) Conflict else RKnown(common)
        }
        | _ => RNoRuling
      }
      | _ => RNoRuling
    }
  }

  // Serialization begins here. Codes are wire data, not semantic ranks.
  type HukmDecode = InvalidHukm | DecodedHukm(Hukm)
  type InputDecode = InvalidInput | DecodedInput(Input)
  type KeyDecode = InvalidKey | DecodedKey(Key)

  pure def encodeHukm(value: Hukm): int = match value {
    | H => 0
    | K => 1
    | M => 2
    | N => 3
    | W => 4
  }

  pure def decodeHukm(code: int): HukmDecode = {
    if (code == 0) DecodedHukm(H)
    else if (code == 1) DecodedHukm(K)
    else if (code == 2) DecodedHukm(M)
    else if (code == 3) DecodedHukm(N)
    else if (code == 4) DecodedHukm(W)
    else InvalidHukm
  }

  pure def wireBit(value: Hukm): int = match value {
    | H => 1
    | K => 2
    | M => 4
    | N => 8
    | W => 16
  }

  pure def encodeSet(values: Set[Hukm]): int =
    values.fold(0, (mask, value) => mask + wireBit(value))

  // Called only after the enclosing input decoder checks 1 <= code <= 31.
  pure def decodeKnownMask(code: int): Set[Hukm] =
    carrier.filter(value => (code / wireBit(value)) % 2 == 1)

  pure def encodeInput(input: Input): int = match input {
    | NoRuling => 0
    | Suspended => 32
    | Known(values) => if (values.size() > 0) encodeSet(values) else -1
  }

  pure def decodeInput(code: int): InputDecode = {
    if (code == 0) DecodedInput(NoRuling)
    else if (code == 32) DecodedInput(Suspended)
    else if (code >= 1 and code <= 31) DecodedInput(Known(decodeKnownMask(code)))
    else InvalidInput
  }

  pure def encodeResult(result: Result): int = match result {
    | RNoRuling => 0
    | RSuspended => 32
    | RKnown(values) => if (values.size() > 0) encodeSet(values) else -1
    | Conflict => 33
    | OutOfScope => 34
  }

  pure val zeroKey: Key = {
    question: 0,
    subject: 0,
    target: LegacyKeyTarget(0),
    context: 0,
    time: 0,
    profile: 0,
    version: 0
  }

  pure def decodeKeyVariant(code: int): KeyDecode = {
    if (code == 0) DecodedKey(zeroKey)
    else if (code == 1) DecodedKey(zeroKey.with("question", 1))
    else if (code == 2) DecodedKey(zeroKey.with("subject", 1))
    else if (code == 3) DecodedKey(zeroKey.with("target", LegacyKeyTarget(1)))
    else if (code == 4) DecodedKey(zeroKey.with("context", 1))
    else if (code == 5) DecodedKey(zeroKey.with("time", 1))
    else if (code == 6) DecodedKey(zeroKey.with("profile", 1))
    else if (code == 7) DecodedKey(zeroKey.with("version", 1))
    else InvalidKey
  }

  // Every public wire API rejects out-of-domain arguments with -1.
  pure def meetCode(a: int, b: int): int = match decodeHukm(a) {
    | InvalidHukm => -1
    | DecodedHukm(left) => match decodeHukm(b) {
      | InvalidHukm => -1
      | DecodedHukm(right) => encodeHukm(meet(left, right))
    }
  }

  pure def joinCode(a: int, b: int): int = match decodeHukm(a) {
    | InvalidHukm => -1
    | DecodedHukm(left) => match decodeHukm(b) {
      | InvalidHukm => -1
      | DecodedHukm(right) => encodeHukm(join(left, right))
    }
  }

  pure def sigmaCode(a: int): int = match decodeHukm(a) {
    | InvalidHukm => -1
    | DecodedHukm(value) => encodeHukm(sigma(value))
  }

  pure def refineCode(key: int, left: int, right: int): int = match decodeKeyVariant(key) {
    | InvalidKey => -1
    | DecodedKey(rightKey) => match decodeInput(left) {
      | InvalidInput => -1
      | DecodedInput(leftInput) => match decodeInput(right) {
        | InvalidInput => -1
        | DecodedInput(rightInput) => encodeResult(refine(zeroKey, leftInput, rightKey, rightInput))
      }
    }
  }

  pure def targetPremises(code: int): (Input, Input) = {
    if (code == 0) (Known(carrier), Known(Set(W)))
    else if (code == 1) (Known(Set(H)), Known(Set(W)))
    else if (code == 2) (NoRuling, Known(carrier))
    else if (code == 3) (Suspended, Known(Set(M)))
    else if (code == 4) (Suspended, NoRuling)
    else (Known(Set(M)), Known(Set(M)))
  }

  // 35 is a shape-rejection diagnostic at this test boundary, not a Result.
  pure def targetRefineCode(leftCase: int, rightCase: int, status: int): int = {
    if (status < 0 or status > 5) -1
    else match targetCase(leftCase) {
      | InvalidTargetCase => -1
      | DecodedTargetCase(leftTarget) => match targetCase(rightCase) {
        | InvalidTargetCase => -1
        | DecodedTargetCase(rightTarget) => {
          if (not(validTarget(leftTarget) and validTarget(rightTarget))) 35
          else {
            val premises = targetPremises(status)
            encodeResult(refine(
              zeroKey.with("target", StructuredKeyTarget(leftTarget)), premises._1,
              zeroKey.with("target", StructuredKeyTarget(rightTarget)), premises._2))
          }
        }
      }
    }
  }

  pure val knownSets: Set[Set[Hukm]] = carrier.powerset().filter(values => values.size() > 0)
  pure val validInputs: Set[Input] = knownSets.map(values => Known(values)).union(Set(NoRuling, Suspended))

  // These are exhaustive deterministic assertions over the displayed finite
  // domains, not probabilistic samples or unbounded symbolic proofs.
  run latticeLawsTest = assert(and {
    carrier.forall(a => leq(H, a) and leq(a, W) and leq(a, a)),
    carrier.forall(a => carrier.forall(b => and {
      leq(a, b) or leq(b, a),
      (leq(a, b) and leq(b, a)).implies(a == b),
      leq(meet(a, b), a) and leq(meet(a, b), b),
      leq(a, join(a, b)) and leq(b, join(a, b)),
      meet(a, b) == meet(b, a),
      join(a, b) == join(b, a),
      meet(a, a) == a,
      join(a, a) == a,
      meet(a, join(a, b)) == a,
      join(a, meet(a, b)) == a,
      meet(a, H) == H,
      meet(a, W) == a,
      join(a, H) == a,
      join(a, W) == W,
    })),
    carrier.forall(a => carrier.forall(b => carrier.forall(c => and {
      (leq(a, b) and leq(b, c)).implies(leq(a, c)),
      (leq(c, a) and leq(c, b)).implies(leq(c, meet(a, b))),
      (leq(a, c) and leq(b, c)).implies(leq(join(a, b), c)),
      meet(meet(a, b), c) == meet(a, meet(b, c)),
      join(join(a, b), c) == join(a, join(b, c)),
      meet(a, join(b, c)) == join(meet(a, b), meet(a, c)),
      join(a, meet(b, c)) == meet(join(a, b), join(a, c)),
    }))),
  })

  run sigmaLawsTest = assert(and {
    sigma(H) == W and sigma(K) == N and sigma(M) == M and sigma(N) == K and sigma(W) == H,
    carrier.forall(a => sigma(sigma(a)) == a),
    carrier.forall(a => carrier.forall(b => and {
      leq(a, b) == leq(sigma(b), sigma(a)),
      sigma(meet(a, b)) == join(sigma(a), sigma(b)),
      sigma(join(a, b)) == meet(sigma(a), sigma(b)),
    })),
  })

  run codecRoundtripTest = assert(and {
    encodeHukm(H) == 0 and encodeHukm(K) == 1 and encodeHukm(M) == 2 and encodeHukm(N) == 3 and encodeHukm(W) == 4,
    wireBit(H) == 1 and wireBit(K) == 2 and wireBit(M) == 4 and wireBit(N) == 8 and wireBit(W) == 16,
    carrier.forall(value => decodeHukm(encodeHukm(value)) == DecodedHukm(value)),
    0.to(4).forall(code => match decodeHukm(code) {
      | InvalidHukm => false
      | DecodedHukm(value) => encodeHukm(value) == code
    }),
    knownSets.size() == 31,
    knownSets.forall(values => decodeInput(encodeSet(values)) == DecodedInput(Known(values))),
    validInputs.size() == 33,
    validInputs.forall(input => validInput(input) and decodeInput(encodeInput(input)) == DecodedInput(input)),
    0.to(32).forall(code => match decodeInput(code) {
      | InvalidInput => false
      | DecodedInput(input) => validInput(input) and encodeInput(input) == code
    }),
    not(validInput(Known(Set()))),
    encodeInput(Known(Set())) == -1,
    encodeResult(RKnown(Set())) == -1,
    encodeResult(RNoRuling) == 0,
    encodeResult(RSuspended) == 32,
    encodeResult(Conflict) == 33,
    encodeResult(OutOfScope) == 34,
    knownSets.forall(values => encodeResult(RKnown(values)) == encodeInput(Known(values))),
    decodeKeyVariant(0) == DecodedKey(zeroKey),
    decodeKeyVariant(1) == DecodedKey(zeroKey.with("question", 1)),
    decodeKeyVariant(2) == DecodedKey(zeroKey.with("subject", 1)),
    decodeKeyVariant(3) == DecodedKey(zeroKey.with("target", LegacyKeyTarget(1))),
    decodeKeyVariant(4) == DecodedKey(zeroKey.with("context", 1)),
    decodeKeyVariant(5) == DecodedKey(zeroKey.with("time", 1)),
    decodeKeyVariant(6) == DecodedKey(zeroKey.with("profile", 1)),
    decodeKeyVariant(7) == DecodedKey(zeroKey.with("version", 1)),
  })

  run invalidCodeTest = assert(and {
    Set(-1000, -2, -1, 5, 6, 9, 10, 31, 32, 33, 1000).forall(code => and {
      decodeHukm(code) == InvalidHukm,
      sigmaCode(code) == -1,
      0.to(4).forall(valid => meetCode(code, valid) == -1 and meetCode(valid, code) == -1
        and joinCode(code, valid) == -1 and joinCode(valid, code) == -1),
    }),
    Set(-1000, -2, -1, 33, 34, 35, 64, 65, 1000).forall(code => and {
      decodeInput(code) == InvalidInput,
      0.to(32).forall(valid => refineCode(0, code, valid) == -1 and refineCode(0, valid, code) == -1),
    }),
    Set(-1000, -2, -1, 8, 9, 16, 1000).forall(code => and {
      decodeKeyVariant(code) == InvalidKey,
      refineCode(code, 4, 4) == -1,
    }),
  })

  run missingPremiseTest = assert(and {
    0.to(31).forall(code => refineCode(0, 0, code) == 0 and refineCode(0, code, 0) == 0),
    refine(zeroKey, NoRuling, zeroKey, Known(Set(M))) == RNoRuling,
    refine(zeroKey, Known(Set(M)), zeroKey, NoRuling) == RNoRuling,
    refine(zeroKey, Known(Set(M)), zeroKey, Known(Set(M))) == RKnown(Set(M)),
    refineCode(0, 0, 4) != refineCode(0, 4, 4),
  })

  run suspensionTest = assert(and {
    0.to(32).forall(code => refineCode(0, 32, code) == 32 and refineCode(0, code, 32) == 32),
    refine(zeroKey, Suspended, zeroKey, Known(Set(M))) == RSuspended,
    refine(zeroKey, Suspended, zeroKey, NoRuling) == RSuspended,
    refineCode(0, 32, 4) != refineCode(0, 4, 4),
  })

  run partialPermissionTest = assert(and {
    knownSets.forall(left => knownSets.forall(right => {
      val common = left.intersect(right)
      val result = refine(zeroKey, Known(left), zeroKey, Known(right))
      if (common.size() == 0) result == Conflict
      else result == RKnown(common) and common.subseteq(left) and common.subseteq(right)
    })),
    refineCode(0, 3, 6) == 2,
    refineCode(0, 12, 24) == 8,
    1.to(31).forall(code => refineCode(0, 31, code) == code and refineCode(0, code, 31) == code),
    refineCode(0, 31, 31) == 31,
    refineCode(0, 0, 31) == 0,
    refineCode(0, 32, 31) == 32,
    refineCode(0, 31, 4) != refineCode(0, 0, 4),
    Known(carrier) != Known(Set(M)),
    Known(carrier) != NoRuling,
    Known(Set(M)) != NoRuling,
  })

  run conflictTest = assert(and {
    refineCode(0, 1, 16) == 33,
    refineCode(0, 4, 16) == 33,
    refineCode(0, 3, 24) == 33,
    carrier.forall(a => carrier.forall(b => (a != b).implies(
      refine(zeroKey, Known(Set(a)), zeroKey, Known(Set(b))) == Conflict))),
  })

  run commutativeRefinementTest = assert(
    0.to(32).forall(left => 0.to(32).forall(right => refineCode(0, left, right) == refineCode(0, right, left))))

  // All seven independently changed fields must reject every valid premise
  // pair, including missing/suspended pairs. This also checks guard precedence.
  run keyScopeTest = assert(and {
    sameKey(zeroKey, zeroKey),
    1.to(7).forall(key => 0.to(32).forall(left => 0.to(32).forall(right => refineCode(key, left, right) == 34))),
    not(sameKey(zeroKey, zeroKey.with("question", 1))),
    not(sameKey(zeroKey, zeroKey.with("subject", 1))),
    not(sameKey(zeroKey, zeroKey.with("target", LegacyKeyTarget(1)))),
    not(sameKey(zeroKey, zeroKey.with("context", 1))),
    not(sameKey(zeroKey, zeroKey.with("time", 1))),
    not(sameKey(zeroKey, zeroKey.with("profile", 1))),
    not(sameKey(zeroKey, zeroKey.with("version", 1))),
  })

  run targetAdmissionTest = assert(and {
    length(rawTargetCases) == 28,
    0.to(19).forall(code => targetAdmitCode(code) == 1),
    20.to(27).forall(code => targetAdmitCode(code) == 0),
    Set(-1000, -1, 28, 29, 1000).forall(code => targetAdmitCode(code) == -1),
    validSymbol(targetSymbol("namespace", "name")),
    not(validSymbol(targetSymbol("", "name"))),
    not(validSymbol(targetSymbol("namespace", ""))),
    not(validOperation(repayOperation.with("parameters", List({ role: "", kind: ObligationRef })))),
    not(validTarget(Omit({
      act: repayAct, opportunity: baseOpportunity.with("opensAt", -1)
    }))),
  })

  run targetIdentityTest = assert(and {
    0.to(19).forall(i => 0.to(19).forall(j => {
      val expected = i == j or ((i == 0 or i == 1) and (j == 0 or j == 1))
      sameTarget(rawTargetCases[i], rawTargetCases[j]) == expected
    })),
    0.to(27).forall(i => 0.to(27).forall(j =>
      sameTarget(rawTargetCases[i], rawTargetCases[j]) ==
        (rawTargetCases[i] == rawTargetCases[j]))),
  })

  run targetScopeTest = assert(
    0.to(27).forall(i => 0.to(27).forall(j => 0.to(5).forall(status => {
      val identical = i == j or ((i == 0 or i == 1) and (j == 0 or j == 1))
      val matchedResults = List(16, 33, 0, 32, 32, 4)
      val expected =
        if (i >= 20 or j >= 20) 35
        else if (identical) matchedResults[status]
        else 34
      targetRefineCode(i, j, status) == expected
    }))))

  run targetBoundaryTest = assert(and {
    0.to(5).forall(status => {
      val structured = zeroKey.with("target", StructuredKeyTarget(rawTargetCases[0]))
      val premises = targetPremises(status)
      refine(zeroKey, premises._1, structured, premises._2) == OutOfScope
        and refine(structured, premises._1, zeroKey, premises._2) == OutOfScope
    }),
    20.to(27).forall(code => 0.to(5).forall(status => {
      val invalidKey = zeroKey.with("target", StructuredKeyTarget(rawTargetCases[code]))
      val premises = targetPremises(status)
      refine(invalidKey, premises._1, invalidKey, premises._2) == OutOfScope
    })),
    Set(-1000, -1, 28, 29, 1000).forall(code =>
      targetRefineCode(code, 0, 0) == -1 and targetRefineCode(0, code, 0) == -1),
    Set(-1000, -1, 6, 7, 1000).forall(status =>
      targetRefineCode(0, 0, status) == -1),
  })
}
