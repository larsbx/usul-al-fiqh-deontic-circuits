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

  type Key = {
    question: int,
    subject: int,
    target: int,
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
    a.target == b.target,
    a.context == b.context,
    a.time == b.time,
    a.profile == b.profile,
    a.version == b.version,
  }

  // Both inputs are REQUIRED premises. Precondition: validInput(left/right).
  // Precedence: scope mismatch, suspension, missing premise, intersection.
  pure def refine(leftKey: Key, left: Input, rightKey: Key, right: Input): Result = {
    if (not(sameKey(leftKey, rightKey))) OutOfScope
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
    target: 0,
    context: 0,
    time: 0,
    profile: 0,
    version: 0
  }

  pure def decodeKeyVariant(code: int): KeyDecode = {
    if (code == 0) DecodedKey(zeroKey)
    else if (code == 1) DecodedKey(zeroKey.with("question", 1))
    else if (code == 2) DecodedKey(zeroKey.with("subject", 1))
    else if (code == 3) DecodedKey(zeroKey.with("target", 1))
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
    decodeKeyVariant(3) == DecodedKey(zeroKey.with("target", 1)),
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
    not(sameKey(zeroKey, zeroKey.with("target", 1))),
    not(sameKey(zeroKey, zeroKey.with("context", 1))),
    not(sameKey(zeroKey, zeroKey.with("time", 1))),
    not(sameKey(zeroKey, zeroKey.with("profile", 1))),
    not(sameKey(zeroKey, zeroKey.with("version", 1))),
  })
}
