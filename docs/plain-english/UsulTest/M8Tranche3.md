# UsulTest.M8Tranche3 in Plain English

Source: [`formal/lean/UsulTest/M8Tranche3.lean`](../../../formal/lean/UsulTest/M8Tranche3.lean)

These hand-written guards sharpen the third M8 tranche of Ibn Rajab's qawāʿid (legal maxims). Each pair shows that a reading really separates two situations the source treats differently. The amounts are synthetic, and no guard adopts a scholarly position or supplies a missing fact.

## 1. Qāʿida 31: making up a failed undertaking

`makeupAfterFailure` says how a make-up must be done after an undertaking fails, e.g. a ḥajj. `asBegun` means in the form it was begun, e.g. from the earlier place of iḥrām. `baseline` means in its basic form.

| Check | Plain English |
| --- | --- |
| `makeupAfterFailure .corruption == .asBegun` | One who corrupted the undertaking repeats it as begun. |
| `makeupAfterFailure .prevention == .baseline` | One prevented from completing it does not. |
| `makeupAfterFailure .lossWithFault == .asBegun` | Loss through one's own fault keeps the enhanced form. |
| `makeupAfterFailure .lossWithoutFault == .baseline` | Loss without fault does not; this follows the author of al-Mughnī. |

## 2. Qāʿida 47: named price or equivalent value

`defectiveCompensation contractLiability named equivalent` gives what is owed for a defective contract's object. Under the contract, the named price applies. For loss, the equivalent value applies.

| Check | Plain English |
| --- | --- |
| `defectiveCompensation false 7 11 == 11`, `false 13 11 == 11` | For loss, the equivalent is owed, whether the named price is lower or higher. |
| `defectiveCompensation true 7 11 == 7`, `true 7 13 == 7` | Under the contract, the named price is owed, whatever the equivalent. |

## 3. Input boundaries of earlier generic readings

These guards (from PR #32) confirm each reading turns on its stated input and nothing else.

| Check | Plain English |
| --- | --- |
| `runningBody false == .whole`, `true == .perJirya` | Still water is judged as one body; running water jirya by jirya (flow by flow). |
| `preferMany false == false`, `true == true` | Many acts beat one noble act only when they cost the same. |
| `validWithBasis` on three inputs | An act is valid only when he relied on a basis and a valid basis in fact existed. |
| `handLiable false == false`, `true == true` | The hand takes liability only for what is property or property-like. |
| `takerRecourse true == false`, `false == true` | One who took from a usurper unaware can recover from him, unless he undertook the liability himself. |

The last input refers to the liability object being checked, not every object in the record.

## In one line

Each reading in this tranche separates exactly the situations its source separates, and responds only to the inputs it names.
