# Usul.Readings.Mubashara in Plain English

Source: [`formal/lean/Usul/Readings/Mubashara.lean`](../../../../formal/lean/Usul/Readings/Mubashara.lean)

When destruction of life or property (itlāf) rests on both a direct act (mubāshara) and a cause (sabab), Ibn Rajab's qāʿida 127 says who is liable. The direct actor bears it, unless his act arose from the cause. Then the cause bears it alone if the act had no transgression, and they share it if it had some.

## 1. The rule

- **`Daman`**: who bears liability (ḍamān): the direct actor (mubāshir), the cause, or both shared.
- **`damanOn arising udwan`**: `arising` means the direct act is built on the cause and arises from it; `udwan` means the direct act has some transgression (ʿudwān).

The qāʿida's own furūʿ illustrate each branch. One who hands something over bears it alone. Witnesses whose testimony the judge acted on bear it, not the judge. One who holds a victim shares it with the killer, on one riwāya.

| Theorem | Plain English |
| --- | --- |
| `q127_direct_unless_arising` | If the direct act did not arise from the cause, the direct actor is liable. |
| `q127_cause_alone_without_udwan` | Arising without transgression: the cause alone. |
| `q127_shared_with_udwan` | Arising with transgression: shared. |
| `q127_three_divisions` | Every case falls in one of the three divisions. |
| `q127_agrees_with_q13` | Agrees with al-Saʿdī's Q13: the direct destroyer is liable, and destruction without right is compensable whatever his state of mind. |

## 2. What is left out

The reading covers only an itlāf with both a direct act and a cause. Liability of a cause with no direct act ("the one who causes is liable only for transgression") is not stated here and stays a gap. Status: candidate reading.

## In one line

Liability falls on the direct actor, unless his act arose from the cause: then on the cause alone without transgression, or on both with it.
