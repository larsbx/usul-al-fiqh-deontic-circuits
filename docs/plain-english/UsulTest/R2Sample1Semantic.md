# UsulTest.R2Sample1Semantic in Plain English

Source: [`formal/lean/UsulTest/R2Sample1Semantic.lean`](../../../formal/lean/UsulTest/R2Sample1Semantic.lean)

Three candidate semantic controls for encoder components. They show which inputs a component depends on and which it ignores. These are checks of the encoders, not legal verdicts.

## 1. The checks

| Check | Plain English |
| --- | --- |
| `RajabA10.simultaneousCombinationVoids true == false`, `false == true` | When a barred combination arises at once, an item's contract is void unless it has precedence over the other. Ḥarb's chronology supplies neither value, so both are kept. Extracting this input really decides the outcome. |
| `RajabA2.wageWithoutStipulation true publicOrRescue = true` | A professional, such as a fuller or tailor, earns a wage without stipulating it. Public service or rescue does not matter, and the source does not state it. |
| `Refinements.allocationFull false divisible true = .lot` | When the entitled party is unknown and the claims are confused, the judge draws lots (qurʿa). This holds whether or not the property is divisible, so no guess is needed. |

The last two are proved for both values of the unknown input.

## In one line

Each component either truly turns on its input or provably ignores the input the source leaves unstated.
