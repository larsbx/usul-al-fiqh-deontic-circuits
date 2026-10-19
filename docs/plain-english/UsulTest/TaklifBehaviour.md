# UsulTest.TaklifBehaviour in Plain English

Source: [`formal/lean/UsulTest/TaklifBehaviour.lean`](../../../formal/lean/UsulTest/TaklifBehaviour.lean)

One concrete life story of a legally responsible person, written as a sequence of states. The same story is replayed by the TLA+ model checker, so Lean and TLA+ test the same behaviour. The file is generated from `formal/fixtures/taklif-behaviour-v1.json` and must not be edited by hand.

## 1. A state as five yes/no flags

The TLA+ spec `Taklif.tla` tracks taklīf (legal responsibility). Lean keeps only its Boolean core.

- **`st b a t r d`**: builds one state from five flags, in this order:
  - **baligh**: has reached bulūgh (legal maturity).
  - **aqil**: has ʿaql (sound mind).
  - **travelling**: is on a journey.
  - **rukhsa**: is using a rukhṣa (dispensation), here the traveller's.
  - **bound ≠ {}**: at least one duty is currently owed.
- The abstraction drops which duties are owed and which the person can perform. It keeps only whether any duty is owed.

## 2. The behaviour

| Definition | Plain English |
| --- | --- |
| `behaviour` | A trace of 8 states: an initial state, then seven steps. |

The seven steps, in order:

1. **Bulugh**: the person matures; duties (ṣalāt and ṣawm) become owed.
2. **Incapacity(sawm)**: fasting becomes impossible. Ṣalāt is still owed, so the abstract state does not change.
3. **Depart**: a journey begins.
4. **TakeRukhsa**: the traveller's dispensation is taken.
5. **Arrive**: the journey ends, and the dispensation ends with it.
6. **Recover(sawm)**: fasting is possible again. Again the abstract state does not change.
7. **LoseAql**: sound mind is lost; no duty remains owed, though maturity stays.

The start is a sane minor with nothing owed.

## 3. Why it matters

`UsulTest.Institutions` imports this trace. It checks that every invariant of the spec holds along it, such as "a rukhṣa needs its cause" and "bulūgh is irreversible". TLC replays the same steps through `Taklif.tla`'s own actions in `TaklifTrace.tla`. A drift between the Lean fragment and the TLA+ model would make one of the two fail.

## In one line

A single, generated life trace (maturity, travel, dispensation, loss of reason) that Lean and TLA+ both check, so the two models of taklīf stay in step.
