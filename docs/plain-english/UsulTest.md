# UsulTest in Plain English

Source: [`formal/lean/UsulTest.lean`](../../formal/lean/UsulTest.lean)

The root of the test library. Building it builds every `UsulTest` suite, so all of their kernel-checked examples and `#guard` checks run.

## 1. What it imports

25 suites:

- **Argumentation semantics**: `GroundedVectors`, `GroundedStress`, `ExtensionSemantics`.
- **Signatures and schemata**: `SignatureMap`, `Schemata`, `CommandSchemata`.
- **Takhrīj (deriving rulings for new cases)**: `TakhrijMirror`, `Takhrij`, `TakhrijCo`, `M8Tranche3`, `FatawaBank`, `FatawaTakhrij`, `R2Sample1Semantic`.
- **Tables of conflicts, distinctions and texts**: `TanaqudTable`, `FuruqTable`, `NususTable`, `Reconcile`.
- **Rulings and judgements**: `TypedRulings`, `KernelContracts`, `Judgement`, `EncoderTypes`, `TaklifBehaviour`.
- **Category layer and institutions**: `Cat`, `Obstructions`, `Institutions`.

## In one line

One import that runs the whole test suite.
