// ACT-03 independent finite model of report observations and fivefold rulings.
// Report-family IDs encode synthetic predicate, participant and scope fixtures;
// the additional families use the explicit five-constructor Hukm carrier below.
module idaProjection {
  type Row = { predicate: str, version: int, person: str, positive: bool, mention: int }

  pure val support: str = "qualified"
  pure val guard: str = "guard"
  pure val payer: str = "payer"
  pure val recipient: str = "recipient"

  pure def bit(mask: int, weight: int): bool = (mask / weight) % 2 == 1
  pure def flag(value: bool): int = if (value) 1 else 0

  pure def report(predicate: str, version: int, person: str, positive: bool): Row =
    { predicate: predicate, version: version, person: person, positive: positive, mention: 1 }

  pure val rows: List[Row] = List(report(support, 1, recipient, true),
    report(support, 1, recipient, false), report(guard, 1, payer, true),
    report(guard, 1, payer, false))

  pure def reports(mask: int, noise: int): Set[Row] = {
    val weights = List(1, 2, 4, 8)
    val base = Set(0, 1, 2, 3).filter(i => bit(mask, weights[i])).map(i => rows[i])
    if (noise == 1) base.union(Set(report("unrelated", 1, recipient, true)))
    else if (noise == 2) base.union(Set(report(guard, 2, payer, true)))
    else if (noise == 3) base.union(Set(report(guard, 1, recipient, true)))
    else if (noise == 4) base.union(base.map(q => q.with("mention", 2)))
    else base
  }

  pure def observes(source: Set[Row], predicate: str, person: str, positive: bool): bool =
    source.exists(q => q.predicate == predicate and q.version == 1 and
      q.person == person and q.positive == positive)

  pure def signature(source: Set[Row], shape: int): int = {
    val accountable = if (shape == 6) payer else recipient
    val performer = if (shape == 7 or shape == 13) recipient else payer
    flag(observes(source, support, accountable, true)) +
      2 * flag(observes(source, support, accountable, false)) +
      4 * flag(observes(source, guard, performer, true)) +
      8 * flag(observes(source, guard, performer, false))
  }

  // Independent truth table, indexed by both signs of support and exception.
  pure def outcome(fallbackEnabled: bool, shape: int, observed: int): int = {
    val defaultCase = if (fallbackEnabled) 2 else 1
    val status = List(1,4,3,5,6,6,6,6,defaultCase,4,3,5,7,7,7,7)
    if (shape == 0) status[observed] else 0
  }

  pure def caseCells(fallbackEnabled: bool, shape: int, mask: int, noise: int): List[int] = {
    val found = signature(reports(mask, noise), shape)
    val result = outcome(fallbackEnabled, shape, found)
    val equivalent = shape == 0 and found == signature(reports(mask, 0), 0)
    val coreEqual = shape != 1 and shape != 13
    List(1, result, result, flag(bit(found, 1)), flag(bit(found, 2)),
      flag(bit(found, 4)), flag(bit(found, 8)), flag(equivalent),
      flag(coreEqual), flag(shape != 9))
  }

  pure def pairCells(fallbackEnabled: bool, left: int, right: int): List[int] = {
    val a = signature(reports(left, 0), 0)
    val b = signature(reports(right, 1), 0)
    List(flag(a == b), flag(outcome(fallbackEnabled, 0, a) == outcome(fallbackEnabled, 0, b)), 1, 1)
  }

  // The ruling carrier is the five-element deontic chain. Boolean values below
  // describe applicability, feature membership and checks, never ruling values.
  // Sigma is used only as a synthetic output map; no source or legal inference
  // is obtained merely by relabeling an answer.
  type Hukm = Haram | Makruh | Mubah | Mandub | Wajib
  pure val hukmValues: List[Hukm] = List(Haram, Makruh, Mubah, Mandub, Wajib)
  pure val hukmCarrier: Set[Hukm] = Set(Haram, Makruh, Mubah, Mandub, Wajib)

  pure def hukmCode(value: Hukm): int = match value {
    | Haram => 0
    | Makruh => 1
    | Mubah => 2
    | Mandub => 3
    | Wajib => 4
  }

  // Semantic order is independent of the integer export encoding. Meet and
  // join search the actual finite lower/upper bounds, rather than output tables.
  pure def lowerSet(value: Hukm): Set[Hukm] = match value {
    | Haram => Set(Haram)
    | Makruh => Set(Haram, Makruh)
    | Mubah => Set(Haram, Makruh, Mubah)
    | Mandub => Set(Haram, Makruh, Mubah, Mandub)
    | Wajib => hukmCarrier
  }
  pure def leq(left: Hukm, right: Hukm): bool = lowerSet(right).contains(left)
  pure def meet(left: Hukm, right: Hukm): Hukm =
    hukmValues.foldl(Haram, (best, value) =>
      if (leq(value, left) and leq(value, right) and leq(best, value)) value else best)
  pure def join(left: Hukm, right: Hukm): Hukm =
    hukmValues.foldl(Wajib, (best, value) =>
      if (leq(left, value) and leq(right, value) and leq(value, best)) value else best)
  pure def sigma(value: Hukm): Hukm = match value {
    | Haram => Wajib
    | Makruh => Mandub
    | Mubah => Mubah
    | Mandub => Makruh
    | Wajib => Haram
  }
  // MUTATION_BOOLEAN_COMPLEMENT: an order-reversing dual need not be a complement.
  pure def isComplement(left: Hukm, right: Hukm): bool =
    meet(left, right) == Haram and join(left, right) == Wajib

  type EncoderSituation = { enabled: bool, feature: Hukm, noise: bool }
  type PartialHukm = NoValue | HukmValue(Hukm)

  // MUTATION_MUBAH_AS_ABSENCE: mubah remains a present, concrete ruling.
  pure def readFeature(situation: EncoderSituation): PartialHukm =
    if (situation.enabled) HukmValue(situation.feature) else NoValue

  pure def sigmaAnswer(answer: PartialHukm): PartialHukm = match answer {
    | NoValue => NoValue
    | HukmValue(value) => HukmValue(sigma(value))
  }

  pure def partialCode(value: PartialHukm): int = match value {
    | NoValue => 0
    | HukmValue(answer) => 1 + hukmCode(answer)
  }

  pure def relabelCells(active: bool, feature: Hukm, noise: bool): List[int] = {
    val situation = { enabled: active, feature: feature, noise: noise }
    val originalProjection = readFeature(situation)
    val relabeledProjection = readFeature(situation)
    val originalAnswer = originalProjection
    // MUTATION_OUTPUT_RELABELING: equal information does not reuse the old answer.
    val relabeledAnswer = sigmaAnswer(relabeledProjection)
    List(partialCode(originalProjection), partialCode(relabeledProjection),
      flag(originalProjection != NoValue), flag(relabeledProjection != NoValue),
      partialCode(originalAnswer), partialCode(relabeledAnswer),
      flag(originalProjection == relabeledProjection), flag(originalAnswer == relabeledAnswer))
  }

  type FeaturePoint = { feature: bool, noise: bool }
  type KnownRow = { point: FeaturePoint, answer: Hukm }

  pure val featureCases: Set[FeaturePoint] =
    0.to(3).map(i => { feature: bit(i, 2), noise: bit(i, 1) })
  pure val knownRows: Set[KnownRow] = featureCases.filter(point => not(point.feature))
    .map(point => { point: point, answer: Wajib })

  // All five labels on the unobserved feature class remain available.
  // MUTATION_UNATTESTED_FEATURE: known labels do not select the unseen value.
  pure def extensionAnswer(knownValue: Hukm, unseenValue: Hukm, point: FeaturePoint): Hukm = {
    val selectedRuling = if (point.feature) unseenValue else knownValue
    // MUTATION_FIVEFOLD_OUTPUT: preserve the five-valued codomain.
    selectedRuling
  }

  pure def knownConsistent: bool = knownRows.forall(left => knownRows.forall(right =>
    left.point.feature != right.point.feature or left.answer == right.answer))

  pure def extensionAgrees(knownValue: Hukm, unseenValue: Hukm): bool =
    knownRows.forall(row => extensionAnswer(knownValue, unseenValue, row.point) == row.answer)

  pure def extensionFactors(knownValue: Hukm, unseenValue: Hukm): bool =
    featureCases.forall(left => featureCases.forall(right =>
      left.feature != right.feature or
        extensionAnswer(knownValue, unseenValue, left) == extensionAnswer(knownValue, unseenValue, right)))

  pure def featureAttested(point: FeaturePoint): bool =
    knownRows.exists(row => row.point.feature == point.feature)

  pure def unattestedCells(knownValue: Hukm, unseenValue: Hukm, feature: bool, noise: bool): List[int] = {
    val point = { feature: feature, noise: noise }
    val firstExtension = extensionAnswer(Wajib, Mubah, point)
    val secondExtension = extensionAnswer(Wajib, Mandub, point)
    List(hukmCode(extensionAnswer(knownValue, unseenValue, point)), flag(knownConsistent),
      flag(extensionAgrees(knownValue, unseenValue)), flag(extensionFactors(knownValue, unseenValue)),
      flag(featureAttested(point)), hukmCode(firstExtension), hukmCode(secondExtension),
      flag(firstExtension == secondExtension))
  }

  pure def fivefoldCells(left: Hukm, right: Hukm): List[int] =
    List(hukmCode(left), hukmCode(right), hukmCode(meet(left, right)), hukmCode(join(left, right)),
      hukmCode(sigma(left)), hukmCode(sigma(right)), flag(sigma(left) == left),
      flag(isComplement(left, right)))

  run reportDependenciesTest = assert(and {
    caseCells(true, 0, 1, 0) == List(1,4,4,1,0,0,0,1,1,1),
    caseCells(true, 0, 5, 0) == List(1,6,6,1,0,1,0,1,1,1),
    caseCells(true, 0, 1, 2) == caseCells(true, 0, 1, 0),
    caseCells(true, 0, 1, 3) == caseCells(true, 0, 1, 0),
    caseCells(true, 0, 1, 4) == caseCells(true, 0, 1, 0),
    pairCells(true, 1, 5) == List(0,0,1,1),
    pairCells(true, 5, 7) == List(0,1,1,1),
    pairCells(true, 5, 5) == List(1,1,1,1),
  })

  run scopeAndFallbackTest = assert(and {
    caseCells(true, 1, 1, 0) == List(1,0,0,1,0,0,0,0,0,1),
    caseCells(true, 9, 1, 0) == List(1,0,0,1,0,0,0,0,1,0),
    1.to(14).forall(i => caseCells(true, i, 1, 0)[1] == 0),
    caseCells(true, 0, 0, 0)[1] == 1,
    caseCells(true, 0, 8, 0)[1] == 2,
    caseCells(false, 0, 8, 0)[1] == 1,
  })

  run outputRelabelingTest = assert(and {
    partialCode(NoValue) == 0, partialCode(HukmValue(Mubah)) == 3,
    hukmCarrier.map(value => partialCode(HukmValue(value))) == 1.to(5),
    0.to(19).forall(i => {
      val active = i / 10 == 1
      val feature = hukmValues[(i / 2) % 5]
      val noise = bit(i, 1)
      val cells = relabelCells(active, feature, noise)
      and {
        cells == relabelCells(active, feature, not(noise)),
        cells[0] == cells[1], cells[2] == flag(active), cells[3] == flag(active), cells[6] == 1,
        cells[7] == flag(not(active) or feature == Mubah),
        if (active) and {
          cells[0] == 1 + hukmCode(feature), cells[4] == cells[0],
          cells[5] == 1 + hukmCode(sigma(feature)), cells[5] > 0,
        } else and { cells[0] == 0, cells[4] == 0, cells[5] == 0 },
      }
    }),
    relabelCells(true, Mubah, false)[0] == 3,
    relabelCells(true, Mubah, false)[5] == 3,
    relabelCells(false, Mubah, false)[0] == 0,
  })

  run unattestedFeatureTest = assert(and {
    featureCases.size() == 4, knownRows.size() == 2,
    extensionAgrees(Wajib, Mubah), extensionAgrees(Wajib, Mandub),
    extensionFactors(Wajib, Mubah), extensionFactors(Wajib, Mandub),
    hukmCarrier.forall(knownValue => hukmCarrier.forall(unseenValue => and {
      extensionFactors(knownValue, unseenValue),
      extensionAgrees(knownValue, unseenValue) == (knownValue == Wajib),
    })),
    featureCases.filter(point => not(featureAttested(point))).size() == 2,
    featureCases.filter(point => not(featureAttested(point))).forall(point =>
      hukmCarrier.map(unseen => extensionAnswer(Wajib, unseen, point)) == hukmCarrier),
    featureCases.forall(point =>
      (extensionAnswer(Wajib, Mubah, point) == extensionAnswer(Wajib, Mandub, point)) == featureAttested(point)),
    0.to(99).forall(i => {
      val knownValue = hukmValues[i / 20]
      val unseenValue = hukmValues[(i / 4) % 5]
      val feature = (i / 2) % 2 == 1
      val noise = bit(i, 1)
      val cells = unattestedCells(knownValue, unseenValue, feature, noise)
      and {
        cells == unattestedCells(knownValue, unseenValue, feature, not(noise)),
        cells[1] == 1, cells[2] == flag(knownValue == Wajib), cells[3] == 1,
        cells[4] == flag(not(feature)),
        cells[5] == (if (feature) 2 else 4), cells[6] == (if (feature) 3 else 4),
        cells[7] == flag(not(feature)),
        cells[0] == hukmCode(if (feature) unseenValue else knownValue),
      }
    }),
  })

  run fivefoldAlgebraTest = assert(and {
    hukmCarrier.size() == 5, hukmCarrier.map(hukmCode) == 0.to(4),
    0.to(4).forall(i => hukmCode(hukmValues[i]) == i),
    sigma(Haram) == Wajib, sigma(Makruh) == Mandub, sigma(Mubah) == Mubah,
    sigma(Mandub) == Makruh, sigma(Wajib) == Haram,
    hukmCarrier.forall(left => and {
      sigma(sigma(left)) == left, (sigma(left) == left) == (left == Mubah),
      meet(left, left) == left, join(left, left) == left,
      isComplement(left, sigma(left)) == (left == Haram or left == Wajib),
      hukmCarrier.forall(right => and {
        leq(left, right) == (hukmCode(left) <= hukmCode(right)),
        leq(left, right) == leq(sigma(right), sigma(left)),
        meet(left, right) == meet(right, left), join(left, right) == join(right, left),
        meet(left, join(left, right)) == left, join(left, meet(left, right)) == left,
        sigma(meet(left, right)) == join(sigma(left), sigma(right)),
        sigma(join(left, right)) == meet(sigma(left), sigma(right)),
        isComplement(left, right) ==
          ((left == Haram and right == Wajib) or (left == Wajib and right == Haram)),
        fivefoldCells(left, right)[6] == flag(left == Mubah),
        fivefoldCells(left, right)[7] ==
          flag((left == Haram and right == Wajib) or (left == Wajib and right == Haram)),
        hukmCarrier.forall(third => and {
          meet(meet(left, right), third) == meet(left, meet(right, third)),
          join(join(left, right), third) == join(left, join(right, third)),
        }),
      }),
    }),
  })
}
