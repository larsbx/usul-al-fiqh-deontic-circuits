# UsulTest in Plain English

Source: [`formal/lean/UsulTest.lean`](../../formal/lean/UsulTest.lean)

The root of the test library. Building it builds every `UsulTest` suite, so all of their kernel-checked examples and `#guard` checks run.

## 1. What it imports

The following suites:

- **Argumentation semantics**: `GroundedVectors`, `GroundedStress`, `ExtensionSemantics`.
- **Signatures and schemata**: `SignatureMap`, `Schemata`, `CommandSchemata`.
- **Takhrīj (deriving rulings for new cases)**: `TakhrijMirror`, `Takhrij`, `TakhrijCo`, `M8Tranche3`, `FatawaBank`, `FatawaTakhrij`, `R2Sample1Semantic`.
- **Tables of conflicts, distinctions and texts**: `TanaqudTable`, `FuruqTable`, `NususTable`, `Reconcile`.
- **Rulings and judgements**: `TypedRulings`, `KernelContracts`, `Judgement`, `EncoderTypes`, `TaklifBehaviour`.
- **Agency pilot**: `Agency` (joint-action, scope, revocation, knowledge, and receipt regressions).
- **Contextual IDA pilot**: `IDAPilot` (the shared guarded application trace, exact destination admission, relevant-report controls, and scoped omission observations).
- **Category layer and institutions**: `Cat`, `Obstructions`, `Interval`, `Institutions`.

Importing `IDAPilot` also reaches `Usul.Typing.IDAPilot` and
`Usul.Typing.IDAOmissionWire`. All three modules therefore participate in the
root compiled audit, whose exact module-coverage requirement remains unchanged.

## In one line

One import that runs the whole test suite.

The umbrella includes `UsulTest.IDADerivation` and `UsulTest.IDADerivationContracts` for synthetic derivation scenarios and fixed proposition witnesses.
