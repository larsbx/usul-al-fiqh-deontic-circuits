# Usul.Dung in Plain English

Source: [`formal/lean/Usul/Dung.lean`](../../../formal/lean/Usul/Dung.lean)

Abstract argumentation in Dung's style gives a sound way to decide which arguments survive their attackers. The file proves that the "sceptical" answer, the grounded extension, is the unique least complete one, and that every finite debate has at least one "credulous" answer, a preferred extension.

## 1. Basic vocabulary

- **Arguments (`α`)** and an **attack relation (`att b a`)**: "b attacks a". Nothing else is assumed.
- **`ASet`**: a set of arguments, given as a yes/no test.
- **`ConflictFree`**: no member of the set attacks another member.
- **`Defends S a`**: every attacker of a is attacked back by some member of S.
- **`F` (characteristic function)**: maps S to the set of arguments S defends.
- **`Admissible`**: conflict-free and defends all its own members.
- **`Complete`**: admissible, and contains every argument it defends.
- **`approx n`**: the n-th grounded approximant. Start from the empty set and apply F n times.

## 2. The defence operator and the approximants

| Theorem | Plain English |
| --- | --- |
| `F_mono` | A bigger set defends at least as much. |
| `admissible_F` | **Fundamental lemma.** If S is admissible, so is F S. |
| `admissible_empty` | The empty set is admissible. |
| `approx_admissible`, `approx_conflictFree` | Every approximant is admissible, hence conflict-free. |
| `approx_succ`, `approx_mono` | The approximants only grow. |
| `approx_sub_complete` | Every complete extension contains every approximant. |
| `unattacked_in_approx_one` | An argument nobody attacks is accepted at the first step: the uncontested core. |

## 3. The grounded extension

- **`grounded`**: everything accepted by some approximant (the union of the chain).
- **`Finitary`**: each argument has finitely many attackers. Every framework the project builds is finitary.

| Theorem | Plain English |
| --- | --- |
| `grounded_conflictFree`, `grounded_sub_F`, `grounded_admissible` | The grounded set is admissible. |
| `countered_by_one_approx` | If finitely many attackers are each countered at some stage, one single stage counters them all. |
| `F_grounded_sub` | For finitary frameworks, whatever the grounded set defends is already in it. |
| `grounded_complete` | For finitary frameworks, the grounded set is complete. |
| `grounded_sub_complete` | The grounded set lies inside every complete extension. |
| `grounded_unique` | Any least complete extension equals the grounded one. It is unique. |

## 4. Preferred and stable extensions

- **`Preferred`**: an admissible set that no larger admissible set contains. A maximal defensible position.
- **`Stable`**: conflict-free, and attacks every argument outside it.

| Theorem | Plain English |
| --- | --- |
| `countP_lt_of_strict` | A counting helper: a strictly larger set leaves fewer listed items outside. |
| `admissible_sub_preferred`, `exists_preferred_superset` | Over a finite framework, every admissible set grows into a preferred one. Each enlargement leaves fewer arguments outside, so the process ends. |
| `exists_preferred` | Every finite framework has a preferred extension. Two riwāyāt (transmitted positions) attacking each other give one per side. |
| `stable_admissible` | A stable set is admissible. |
| `stable_preferred` | A stable set is preferred. The converse is not claimed, and stable sets need not exist. |

## In one line

The grounded extension is the unique least complete answer for any finitary debate, and every finite debate also has at least one maximal defensible position.
