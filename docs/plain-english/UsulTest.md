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
- **Structural zakat pilot**: `IDAZakatStructure` checks the restricted candidate's typed registry and role-preserving substitutions while leaving eligibility, amount, occurrence, and discharge unresolved.
- **Integrated structural cases**: `IDAStructuralCases` and `IDAStructuralCasesContracts` check unresolved agency roles, qualification-sensitive observations, and distinct occurrence bindings with supplied synthetic authority; full ACT-08 acceptance remains open.
- **Candidate act intake**: `IDAActIntake` checks the 504-case preparation matrix and retained inputs; `IDAActIntakeContracts` independently states 20 fixed proof requirements. Registry definitions determine the operation, and unresolved signatures still reject every supplied operand list. These suites participate in the whole-core audit without issuing source authority or a ruling.
- **Category layer and institutions**: `Cat`, `Obstructions`, `Interval`, `Institutions`.
- **Native fixtures**: `Fixtures.Contracts` imports the migrated contextual, fatwa, and typing suites with fixed proposition witnesses and runner controls. The independent fixture gate also checks frozen legacy coverage and adversarial mutations.

Importing `IDAPilot` also reaches `Usul.Typing.IDAPilot` and
`Usul.Typing.IDAOmissionWire`. All three modules therefore participate in the
root compiled audit, whose exact module-coverage requirement remains unchanged.

## In one line

One import that runs the whole test suite.

The umbrella includes `UsulTest.IDADerivation` and `UsulTest.IDADerivationContracts` for synthetic derivation scenarios and fixed proposition witnesses.

`UsulTest.IDACaseWorkbench` adds the source-bound review fixture and controls
for missing/conflicting reports, empty/incompatible histories, changed
destination authority, and reuse based only on act kind. Its proof inventory
participates in the same whole-core audit.
