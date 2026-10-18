# UsulTest.GroundedVectors in Plain English

Source: [`formal/lean/UsulTest/GroundedVectors.lean`](../../../formal/lean/UsulTest/GroundedVectors.lean)

Lean's executable grounded extension returns the expected answer on 47 shared test vectors. The same vectors, from `grounded-v1.json`, test the Python and Haskell implementations, so all three agree case by case.

## 1. What a vector holds

Each entry in `groundedVectors` is (name, n, attacks, expected grounded set).

- **n**: the number of arguments, numbered from 0.
- **attacks**: pairs (a, b), "a attacks b".
- **expected**: the arguments that survive under grounded semantics: unattacked ones, plus whatever they defend, repeated to a fixed point.

## 2. Hand-made vectors (7)

| Vector | Plain English |
| --- | --- |
| `unattacked` | One argument, no attacks: it survives, `[0]`. |
| `two_riwayat` | Two reports attack each other: neither is settled, `[]`. |
| `reinstatement` | 0 attacks 1, 1 attacks 2: 0 defeats 1, so 2 is restored, `[0, 2]`. |
| `self_attack` | An argument that attacks itself never survives. |
| `odd_cycle` | Three arguments in a ring: nothing is settled. |
| `chain4` | A chain of four: the 1st and 3rd survive, `[0, 2]`. |
| `defended_by_two` | 2 and 3 both attack 1, which attacks 0: `[0, 2, 3]`. |

## 3. Random vectors (40)

`random_00` to `random_39` are seeded random frameworks of 1 to 7 arguments. They cover empty results, self-attacks, cycles and long defence chains. For example, `random_22` has seven arguments and eleven attacks, and only argument 6 survives.

## 4. The check

| Check | Plain English |
| --- | --- |
| `groundedVectors.all fun (_, n, att, g) => Usul.Grounded.grounded n att == g` | Every one of the 47 vectors gives exactly the expected set. |

## In one line

On 47 shared cases, from mutual riwāyāt to odd cycles, Lean's grounded semantics agrees with the expected answers the other implementations also meet.
