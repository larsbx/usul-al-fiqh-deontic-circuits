// Candidate-only intake against the existing ACT-01 registry. The input has
// no operation, declared signature, source premise, admission flag, or ruling.
// A prepared draft supplies structural evidence only. Definitions and digests
// are supplied pins; their authority and interpretation remain separate.
module idaActIntake {
  import ida as A from "./ida"
  import idaActRegistry as R from "./ida-act-registry"

  type Input = {
    key: R::KindKey, definitionDigest: List[int], registrySnapshot: int,
    qualifications: List[R::Qualification], context: R::ContextSnapshot,
    operands: List[A::Operand]
  }
  type Prepared = { envelope: R::Envelope, definition: R::Definition }
  type Result = PrepRejected(int) | PrepDraft(Prepared)

  // Whole-registry checks precede lookup. A client cannot supply a replacement
  // sort for an unresolved role: the signature is taken only from the registry.
  // Diagnostic numbers retain the existing ACT-01 structural meaning.
  pure def prepare(registry: R::Registry, input: Input): Result = {
    if (not(R::uniqueDefinitionKeys(registry.definitions))) PrepRejected(1)
    else if (not(R::registryWellFormed(registry))) PrepRejected(2)
    else if (registry.snapshot != input.registrySnapshot) PrepRejected(3)
    else {
      val definitions = registry.definitions.select(d => R::sameKey(d.key, input.key))
      if (definitions.length() == 0) PrepRejected(4)
      else if (definitions.length() != 1) PrepRejected(1)
      else {
        val definition = definitions.head()
        if (definition.digest != input.definitionDigest) PrepRejected(5)
        else match R::signatureOf(definition.roles) {
          | UnresolvedSignature => PrepRejected(6)
          | ResolvedSignature(parameters) => {
            val envelope: R::Envelope = {
              key: input.key,
              definitionDigest: input.definitionDigest,
              registrySnapshot: input.registrySnapshot,
              qualifications: input.qualifications,
              context: input.context,
              act: {
                operation: { symbol: definition.key.symbol, parameters: parameters },
                operands: input.operands
              }
            }
            // Reuse the actual independent registry resolver. Intake does not
            // invent a second successful-resolution or admission predicate.
            val code = R::structuralCode(registry, envelope)
            if (code == 0) PrepDraft({ envelope: envelope, definition: definition })
            else PrepRejected(code)
          }
        }
      }
    }
  }

  pure def resultCode(result: Result): int = match result {
    | PrepRejected(code) => code
    | PrepDraft(_) => 0
  }

  pure def prepareCode(registry: R::Registry, input: Input): int =
    resultCode(prepare(registry, input))

  // Empty/singleton observations give the wire comparison an unambiguous
  // result shape without a default envelope or a fabricated definition.
  pure def draftEnvelopes(result: Result): List[R::Envelope] = match result {
    | PrepRejected(_) => List()
    | PrepDraft(draft) => List(draft.envelope)
  }

  pure def draftDefinitions(result: Result): List[R::Definition] = match result {
    | PrepRejected(_) => List()
    | PrepDraft(draft) => List(draft.definition)
  }

  pure def inputOf(envelope: R::Envelope): Input = {
    key: envelope.key,
    definitionDigest: envelope.definitionDigest,
    registrySnapshot: envelope.registrySnapshot,
    qualifications: envelope.qualifications,
    context: envelope.context,
    operands: envelope.act.operands
  }

  pure val baseInput: Input = inputOf(R::baseEnvelope)
  pure val referenceKinds: Set[A::RefKind] = Set(
    A::PersonRef, A::AssetRef, A::ObligationRef, A::OccurrenceRef, A::PropositionRef)

  pure def inputCase(index: int): Input = inputOf(R::envelopeCase(index))

  // Reuse the declared ACT-01 finite inputs, but discard the old caller's
  // operation declaration because that field does not exist in intake.
  pure def preparationCode(registryIndex: int, inputIndex: int): int =
    if (registryIndex < 0 or registryIndex >= 14 or inputIndex < 0 or inputIndex >= 36) -1
    else prepareCode(R::registryCase(registryIndex), inputCase(inputIndex))

  run registeredDraftTest = assert(and {
    prepare(R::baseRegistry, baseInput) ==
      PrepDraft({ envelope: R::baseEnvelope, definition: R::baseDefinition }),
    draftDefinitions(prepare(R::baseRegistry, baseInput)) == List(R::baseDefinition),
    draftEnvelopes(prepare(R::baseRegistry, baseInput)) == List(R::baseEnvelope),
    R::structuralCode(R::baseRegistry, R::baseEnvelope) == 0,
  })

  run registeredOrderTest = {
    val definition = R::baseDefinition.with("roles",
      List(R::recipientRole, R::payerRole, R::propertyRole))
    val registry = R::baseRegistry.with("definitions", List(definition))
    val input = baseInput.with("operands",
      List(R::recipientOperand, R::payerOperand, R::propertyOperand))
    val expected = R::baseEnvelope.with("act", {
      operation: { symbol: definition.key.symbol, parameters: List(
        { role: "recipient", kind: A::PersonRef },
        { role: "payer", kind: A::PersonRef },
        { role: "property", kind: A::AssetRef }) },
      operands: input.operands
    })
    assert(and {
      prepareCode(registry, baseInput) == 8,
      prepare(registry, input) == PrepDraft({ envelope: expected, definition: definition }),
    })
  }

  run operandMismatchTest = {
    val wrongSort = R::propertyOperand.with("referent", R::payer)
    assert(and {
      prepareCode(R::baseRegistry, baseInput.with("operands",
        List(R::recipientOperand, R::payerOperand, R::propertyOperand))) == 8,
      prepareCode(R::baseRegistry, baseInput.with("operands",
        List(R::payerOperand, R::recipientOperand, wrongSort))) == 8,
      prepareCode(R::baseRegistry, baseInput.with("operands",
        List(R::payerOperand, R::recipientOperand))) == 8,
      prepareCode(R::baseRegistry, baseInput.with("operands",
        baseInput.operands.append(R::propertyOperand))) == 8,
    })
  }

  run participantIdentityTest = {
    val input = baseInput.with("operands", List(
      R::payerOperand.with("referent", R::recipient),
      R::recipientOperand.with("referent", R::payer), R::propertyOperand))
    val result = prepare(R::baseRegistry, input)
    assert(and {
      resultCode(result) == 0,
      draftEnvelopes(result).head().act.operands == input.operands,
      draftEnvelopes(result).head().act != R::baseAct,
      draftEnvelopes(result).head().act.operation == R::baseAct.operation,
    })
  }

  run wholeRegistryTest = assert(and {
    Set(2,3,4,5).forall(index => prepareCode(R::registryCase(index), baseInput) == 1),
    Set(7,8,9,10,12).forall(index => prepareCode(R::registryCase(index), baseInput) == 2),
    prepareCode(R::registryCase(11), baseInput) == 0,
    draftEnvelopes(prepare(R::registryCase(2), baseInput)) == List(),
    draftDefinitions(prepare(R::registryCase(2), baseInput)) == List(),
  })

  run revisionPinsTest = assert(and {
    prepareCode(R::baseRegistry, baseInput.with("registrySnapshot", 2)) == 3,
    prepareCode(R::baseRegistry, baseInput.with("key", baseInput.key.with("version", 2))) == 4,
    prepareCode(R::baseRegistry, baseInput.with("key",
      baseInput.key.with("symbol", baseInput.key.symbol.with("name", "unlisted")))) == 4,
    prepareCode(R::baseRegistry, baseInput.with("definitionDigest", R::repeatedDigest(2))) == 5,
    prepareCode(R::registryCase(1), baseInput) == 4,
  })

  run unresolvedCannotBeCoercedTest = assert(
    referenceKinds.forall(kind => {
      val alleged = R::propertyOperand.with("referent", R::property.with("kind", kind))
      val input = baseInput.with("operands", List(R::payerOperand, R::recipientOperand, alleged))
      and {
        prepareCode(R::registryCase(6), input) == 6,
        draftEnvelopes(prepare(R::registryCase(6), input)) == List(),
        draftDefinitions(prepare(R::registryCase(6), input)) == List(),
      }
    }))

  run retainedMetadataTest = {
    val qualifications = List(R::baseQualification.with("polarity", false),
      R::baseQualification.with("mention", { space: "synthetic.source", name: "other-mention" }))
    val context = R::baseContext.with("evidenceRevision", 2).with("recordedAt", 21)
    val input = baseInput.with("qualifications", qualifications).with("context", context)
    val result = prepare(R::baseRegistry, input)
    val expected = R::baseEnvelope.with("qualifications", qualifications).with("context", context)
    assert(and {
      result == PrepDraft({ envelope: expected, definition: R::baseDefinition }),
      inputOf(draftEnvelopes(result).head()) == input,
      R::project(expected) == R::project(R::baseEnvelope),
      not(R::sameEnvelope(expected, R::baseEnvelope)),
    })
  }

  run malformedPayloadTest = {
    val emptyReference = R::payerOperand.with("referent",
      R::payer.with("symbol", R::payer.symbol.with("name", "")))
    assert(and {
      prepareCode(R::baseRegistry, baseInput.with("qualifications",
        List(R::baseQualification.with("version", 0)))) == 9,
      prepareCode(R::baseRegistry, baseInput.with("context",
        R::baseContext.with("profileVersion", 0))) == 9,
      prepareCode(R::baseRegistry, baseInput.with("operands",
        List(emptyReference, R::recipientOperand, R::propertyOperand))) == 9,
    })
  }

  run diagnosticPrecedenceTest = {
    val unknown = baseInput.with("key", baseInput.key.with("version", 9))
      .with("registrySnapshot", 2).with("definitionDigest", List()).with("operands", List())
    assert(and {
      prepareCode(R::registryCase(2), unknown) == 1,
      prepareCode(R::registryCase(7), unknown) == 2,
      prepareCode(R::baseRegistry, unknown) == 3,
      prepareCode(R::baseRegistry, unknown.with("registrySnapshot", 1)) == 4,
      prepareCode(R::registryCase(6), baseInput.with("definitionDigest", List())) == 5,
      prepareCode(R::registryCase(6), baseInput.with("operands", List())) == 6,
    })
  }
}
