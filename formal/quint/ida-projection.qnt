// ACT-03 independent finite observation model. IDs here encode only the
// synthetic fixture's exact predicate versions, participants, and scope changes.
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

  // These Boolean examples concern information dependence and extension of
  // supplied labels. They do not assign a legal status to an act or source.
  type EncoderSituation = { enabled: bool, feature: bool, noise: bool }
  type PartialBool = NoValue | BoolValue(bool)

  pure def readFeature(situation: EncoderSituation): PartialBool =
    if (situation.enabled) BoolValue(situation.feature) else NoValue

  pure def negateAnswer(answer: PartialBool): PartialBool = match answer {
    | NoValue => NoValue
    | BoolValue(value) => BoolValue(not(value))
  }

  pure def partialCode(value: PartialBool): int = match value {
    | NoValue => 0
    | BoolValue(answer) => if (answer) 2 else 1
  }

  pure def relabelCells(active: bool, feature: bool, noise: bool): List[int] = {
    val situation = { enabled: active, feature: feature, noise: noise }
    val originalProjection = readFeature(situation)
    val relabeledProjection = readFeature(situation)
    val originalAnswer = originalProjection
    // MUTATION_OUTPUT_RELABELING: equal information does not reuse the old answer.
    val relabeledAnswer = negateAnswer(relabeledProjection)
    List(partialCode(originalProjection), partialCode(relabeledProjection),
      flag(originalProjection != NoValue), flag(relabeledProjection != NoValue),
      partialCode(originalAnswer), partialCode(relabeledAnswer),
      flag(originalProjection == relabeledProjection), flag(originalAnswer == relabeledAnswer))
  }

  type FeaturePoint = { feature: bool, noise: bool }
  type KnownRow = { point: FeaturePoint, answer: bool }

  pure val featureCases: Set[FeaturePoint] =
    0.to(3).map(i => { feature: bit(i, 2), noise: bit(i, 1) })
  pure val knownRows: Set[KnownRow] = featureCases.filter(point => not(point.feature))
    .map(point => { point: point, answer: true })

  // Both possible labels on the unobserved feature class remain available.
  // MUTATION_UNATTESTED_FEATURE: known labels do not select the unseen value.
  pure def extensionAnswer(knownValue: bool, unseenValue: bool, point: FeaturePoint): bool =
    if (point.feature) unseenValue else knownValue

  pure def knownConsistent: bool = knownRows.forall(left => knownRows.forall(right =>
    left.point.feature != right.point.feature or left.answer == right.answer))

  pure def extensionAgrees(knownValue: bool, unseenValue: bool): bool =
    knownRows.forall(row => extensionAnswer(knownValue, unseenValue, row.point) == row.answer)

  pure def extensionFactors(knownValue: bool, unseenValue: bool): bool =
    featureCases.forall(left => featureCases.forall(right =>
      left.feature != right.feature or
        extensionAnswer(knownValue, unseenValue, left) == extensionAnswer(knownValue, unseenValue, right)))

  pure def featureAttested(point: FeaturePoint): bool =
    knownRows.exists(row => row.point.feature == point.feature)

  pure def unattestedCells(knownValue: bool, unseenValue: bool, feature: bool, noise: bool): List[int] = {
    val point = { feature: feature, noise: noise }
    val firstExtension = extensionAnswer(true, false, point)
    val secondExtension = extensionAnswer(true, true, point)
    List(flag(extensionAnswer(knownValue, unseenValue, point)), flag(knownConsistent),
      flag(extensionAgrees(knownValue, unseenValue)), flag(extensionFactors(knownValue, unseenValue)),
      flag(featureAttested(point)), flag(firstExtension), flag(secondExtension),
      flag(firstExtension == secondExtension))
  }

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

  run outputRelabelingTest = assert(0.to(7).forall(i => {
    val active = bit(i, 4)
    val feature = bit(i, 2)
    val noise = bit(i, 1)
    val cells = relabelCells(active, feature, noise)
    and {
      cells == relabelCells(active, feature, not(noise)),
      cells[0] == cells[1], cells[2] == flag(active), cells[3] == flag(active), cells[6] == 1,
      if (active) and {
        cells[0] == (if (feature) 2 else 1), cells[4] == cells[0],
        cells[5] == 3 - cells[4], cells[7] == 0,
      } else and { cells[0] == 0, cells[4] == 0, cells[5] == 0, cells[7] == 1 },
    }
  }))

  run unattestedFeatureTest = assert(and {
    featureCases.size() == 4, knownRows.size() == 2,
    extensionAgrees(true, false), extensionAgrees(true, true),
    extensionFactors(true, false), extensionFactors(true, true),
    Set(false, true).forall(unseen =>
      extensionFactors(false, unseen) and not(extensionAgrees(false, unseen))),
    featureCases.filter(point => not(featureAttested(point))).size() == 2,
    featureCases.forall(point =>
      (extensionAnswer(true, false, point) == extensionAnswer(true, true, point)) == featureAttested(point)),
    0.to(15).forall(i => {
      val knownValue = bit(i, 8)
      val unseenValue = bit(i, 4)
      val feature = bit(i, 2)
      val noise = bit(i, 1)
      val cells = unattestedCells(knownValue, unseenValue, feature, noise)
      and {
        cells == unattestedCells(knownValue, unseenValue, feature, not(noise)),
        cells[1] == 1, cells[2] == flag(knownValue), cells[3] == 1,
        cells[4] == flag(not(feature)), cells[5] == flag(not(feature)), cells[6] == 1,
        cells[7] == flag(not(feature)),
        if (knownValue) cells[0] == (if (unseenValue) cells[6] else cells[5])
        else if (not(feature)) cells[0] == 0 else cells[0] == flag(unseenValue),
      }
    }),
  })
}
