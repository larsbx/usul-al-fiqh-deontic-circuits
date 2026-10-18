# Usul.FiniteGrounded in Plain English

Source: [`formal/lean/Usul/FiniteGrounded.lean`](../../../formal/lean/Usul/FiniteGrounded.lean)

The finite grounded runner from `Usul.Grounded` is correct end to end. Its n + 1 rounds always reach a fixed point, and on any well-formed graph its output is exactly the unique least complete Dung extension. Malformed inputs are rejected, never silently repaired.

## 1. Iteration and its bound

- **`iterate n att k`**: apply `step` k times starting from the empty list.

| Theorem | Plain English |
| --- | --- |
| `grounded_eq_iterate` | The runner `grounded` is exactly `iterate` run n + 1 times. |
| `step_mono` | A bigger accepted set yields a bigger next step. |
| `iterate_increasing` | Each round contains the previous one. |
| `iterate_bounded` | No round holds more than n arguments. |
| `stable_or_growing` | At each round, either nothing changed or at least k + 1 arguments are accepted. |
| `iterate_stable` | Hence round n + 1 equals round n: the chain has stopped. |
| `grounded_fixed` | One more step leaves the runner's output unchanged. It is a fixed point. |

## 2. Rejecting malformed graphs

- **`WellFormed n att`**: every attack edge names two arguments below n.
- **`wellFormed`**: the Boolean check for the same thing.
- **`checkedGrounded`**: the public entry point. It returns `some` result on a well-formed graph and `none` otherwise. Dropping an out-of-range edge would quietly change the debate, so it refuses instead.

| Theorem | Plain English |
| --- | --- |
| `wellFormed_iff` | The Boolean check is true ⟺ the graph is well-formed. |
| `checkedGrounded_some_iff` | The checked runner returns S ⟺ the graph is well-formed and the runner's output is S. |
| `checkedGrounded_rejects` | A malformed graph gets `none`. |

## 3. Matching the abstract semantics

- **`attack`** and **`extension`**: read the edge list and an output list as an attack relation and an argument set over `Fin n` (the numbers below n).

| Theorem | Plain English |
| --- | --- |
| `finite_step_iff` | On a well-formed graph, one step equals the abstract defence operator `Dung.F`. |
| `iterate_iff_approx` | Every round k equals the abstract approximant `Dung.approx k`, for all inputs, not only test fixtures. |
| `grounded_complete` | The runner's output is a complete extension. |
| `grounded_least` | It lies inside every complete extension. |
| `grounded_conflictFree` | No accepted argument attacks another. |
| `grounded_exists_unique` | A least complete extension exists and is unique, and it is the runner's output. |
| `checkedGrounded_complete`, `checkedGrounded_least` | Whatever the checked runner returns is complete and least. |

## In one line

On any well-formed finite debate, the checked runner halts at a fixed point and returns exactly the unique least complete extension; on a malformed one it refuses.
