# Usul.Readings.RajabA2 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA2.lean`](../../../../formal/lean/Usul/Readings/RajabA2.lean)

Five of Ibn Rajab's qawāʿid (legal maxims) on contracts, wages and land become yes/no rules. Each reading is a function of the facts the qāʿida itself names. The file gives definitions only; it proves no theorems.

## 1. How the readings work

- **Qāʿida** (pl. qawāʿid): a general maxim of the law. These come from Ibn Rajab's *Taqrīr al-qawāʿid*, a Ḥanbalī work.
- **Reading**: a Boolean function. Its inputs are the facts the qāʿida names; its output answers the qāʿida's question.
- **Status**: every reading is a candidate (shard `rajab-a2`, lane A), awaiting human review.

## 2. Maintenance stipulated in a contract (qāʿida 72)

A stipulation of maintenance and clothing (nafaqa) comes in two kinds. As a **muʿāwaḍa** (countervalue) it belongs to binding contracts. As a mere licence (ibāḥa) for the worker it can sit in any contract.

| Definition | Plain English |
| --- | --- |
| `nafaqaStipulable muawada binding` | The stipulation holds ⟺ it is a licence, or the contract is binding. |
| `nafaqaOwned muawada spentInPurpose` | The worker owns what he received ⟺ it was a countervalue, or it was spent in its purpose. Leftover maintenance under a licence goes back. |

## 3. A stipulated benefit (qāʿida 73)

| Definition | Plain English |
| --- | --- |
| `benefitConditionValid againstCompensation` | A condition that one party render a service is valid ⟺ it is set against a compensation, like hiring him. Imposing a duty with nothing in return is invalid. |

## 4. A wage without a stipulation (qāʿida 74)

Someone who works on another's property is normally owed nothing. The qāʿida names two exceptions.

| Definition | Plain English |
| --- | --- |
| `wageWithoutStipulation professional publicOrRescue` | A wage is owed ⟺ his circumstances show he works for pay, or the work serves the Muslims' public interest or rescues protected property from loss. |

## 5. Crops and plants (qawāʿid 79 and 80)

| Definition | Plain English |
| --- | --- |
| `ownerTakesCrop validPermission` | A landowner may take a crop grown on his land ⟺ there was no valid permission to sow it. |
| `asTree repeatedBearing` | A plant that bears repeatedly (herb and vegetable roots) takes the ruling of a tree. The other wajh (view), that it is a crop, stays a recorded position. |

## In one line

Ibn Rajab's rules on stipulated maintenance, service conditions, unasked wages and crops on another's land each reduce to one or two named facts, combined by "and", "or" and "not".
