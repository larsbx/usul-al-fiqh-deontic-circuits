# UsulTest.TakhrijCo in Plain English

Source: [`formal/lean/UsulTest/TakhrijCo.lean`](../../../formal/lean/UsulTest/TakhrijCo.lean)

Some furūʿ (derived cases) follow from more than one qāʿida (legal maxim). This generated suite checks the second derivations, the co-annotations, against their Lean readings, kept apart from the main takhrīj (derivation) guards.

## 1. What a co-annotation is

- **Home annotation**: the one qāʿida a farʿ is filed under, guarded in `UsulTest.Takhrij`.
- **Co-annotation** (`far@encoder`): a record that a second encoder derives the same stated ruling from the farʿ's own words. It is admitted only if it is `derivable`, uses a different encoder from the home, and its farʿ already has a home annotation.
- **Guard**: `#guard (reading inputs) == expected`. It runs the reading at build time and fails the build on a mismatch.
- The file is generated from `corpus/takhrij/co` and must not be edited by hand.

## 2. The current guards

| Farʿ | Check | Plain English |
| --- | --- | --- |
| Ibn Rajab q127.f003 @ `error_actor_liable` | `RajabA5.errorActorLiable true false false false false == false` | When the loss has an external cause, the one who acted in error is not liable. |
| Ibn Rajab q095.f001 @ `mubashara_tasabbub` | `Mubashara.damanOn true false == .sabab` | When the direct act arises from the cause with no transgression (ʿudwān), liability (ḍamān) falls on the one who caused it (sabab). |

Both are `derivable`: the reading gives the stated ruling outright.

## In one line

Where a case follows from two maxims, the second derivation is checked too, without counting the case twice.
