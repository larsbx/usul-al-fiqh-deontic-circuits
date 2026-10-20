# UsulTest.KernelContracts in Plain English

Source: [`formal/lean/UsulTest/KernelContracts.lean`](../../../formal/lean/UsulTest/KernelContracts.lean)

The kernel's boundaries hold. The grounded runner rejects malformed input and is correct for every well-formed framework. And no command reading can be admitted on evaluation alone: the facts it presupposes must come from outside. No corpus interpretation is adopted here.

## 1. The checked grounded runner

`checkedGrounded n edges` returns `some S`, the grounded extension, when every attack names arguments below n, and `none` otherwise.

| Check | Plain English |
| --- | --- |
| `checkedGrounded 0 [] == some []` | No arguments, nothing survives. |
| `checkedGrounded 1 [(0, 0)] == some []` | A self-attacker never survives. |
| two- and three-cycles → `some []` | Mutual and circular attacks settle nothing. |
| `checkedGrounded 3 [(0, 1), (0, 1), (1, 2)] == some [0, 2]` | A duplicated attack changes nothing. |
| six-argument chain → `some [0, 2, 4]` | Defence carries down a long chain. |
| `checkedGrounded 0 [(0, 0)] == none`, `1 [(2, 0)]`, `1 [(0, 2)]` | Any out-of-range endpoint is refused rather than silently dropped. |

Two general statements, not samples:

- **`grounded_complete`**: for every well-formed framework, the output is a complete extension.
- **`checkedGrounded_least`**: it is contained in every complete extension, so it is the least one.

## 2. Admission needs external premises

A command derivation records which reading licenses a result. An **`AdmittedCommand`** also needs `CommandPremises`: an admissible qarīna (contextual indicator), the first-command-position context, and established imitation of the Prophet's act. **`rejectAll`** supplies none of them; **`rejectQarina`** supplies only the context.

| Statement | Plain English |
| --- | --- |
| derivation for `.propheticAct .authorConditional true` | Setting the imitation flag gives a literal reading as a derivation. |
| `no_author_admission_without_imitation` | But without evidence of imitation, it cannot be admitted. A flag is not evidence. |
| admission given `imitation` | A caller who has the evidence can admit it. |
| `authorConditional false` → `.unsettled`, admitted under `rejectAll` | Leaving the question open needs no positive claim. |
| `.obligation .qadi .wujubLabel (some .mandub)` derives `.mandub` | Al-Qāḍī's reading lets a qarīna turn "wujūb" into recommendation. |
| …but not admitted under `rejectQarina` | Only if that qarīna is shown admissible. |
| Abū al-Barakāt's farḍ reading, under `rejectAll` | Without the first-position context, even an explicit obligation is not admitted. |
| intended permission reading, under `rejectAll` | The same holds for an intended permission. |
| `no_positive_gesture_derivation` | The Jāmiʿ's writing argument gives no literal reading of a gesture. |
| `author_literal_requires_imitation` | The conditional reading is literal only when imitation holds. |

## 3. Same ruling, different routes

| Statement | Plain English |
| --- | --- |
| `permissionReport` vs `permissionArgument` | Al-Qāḍī's report calls permission literal, his argument figurative. Both still give mubāḥ (`derivation_preserves_intended_ruling`). |
| `CommandDerivation.deterministic` | Once the reading and all inputs are fixed, the result is unique. |

## In one line

The grounded runner is proven right for every valid framework and refuses invalid ones, and no command reading is admitted until its outside premises are actually supplied.
