# Usul.Readings.RajabA9 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA9.lean`](../../../../formal/lean/Usul/Readings/RajabA9.lean)

Three of Ibn Rajab's qawāʿid (legal maxims) become yes/no rules: granting to the non-existent, judging events of unknown order, and the fate of a choice between two rights. Qāʿida 110 splits into five small readings, one per clause.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*.
- **Reading**: a Boolean function of named facts. Status: candidate.
- Where the statement leaves a question to khilāf (disagreement), the reading returns the side the statement does not establish. The other side is held as a position on the farʿ (particular case).

## 2. Granting to the non-existent (qāʿida 107)

- **`byOrigin`**: the non-existent (maʿdūm) is granted to in its own right, not as following something existing.
- **`explicitInclusion`**: the grant names its inclusion. **`objectEntails`**: the object of the grant entails it.

| Definition / Theorem | Plain English |
| --- | --- |
| `maadumGrantValid` | The grant holds ⟺ it is not by origin, and the grant names the non-existent or its object entails it. |
| `maadum_by_origin_invalid` | A grant by origin never holds, whatever it names. |

## 3. Unknown order (qāʿida 108)

| Definition / Theorem | Plain English |
| --- | --- |
| `judgedSequential knownSimultaneous knownSequential` | Events are judged sequential ⟺ known to be sequential, or not known to be simultaneous. |
| `unknown_order_is_sequence` | When the order is unknown, the madhhab judges them sequential, since exact simultaneity is unlikely. |

## 4. One of two rights (qāʿida 110)

He who holds one of two options loses the other by choosing, and keeps the other by dropping one. If he refuses both, the outcome depends on harm and the kind of right.

| Definition | Plain English |
| --- | --- |
| `otherOptionStands choseOne` | The other option remains ⟺ he did not choose one (he dropped one instead). |
| `refusalExactedForHim harmsOther financial established` | His refusal harms another, the right is financial and an original established right: it is exacted for him. |
| `refusalRightFalls harmsOther established` | His refusal harms another and the right is not established: his right falls. |
| `refusalCompelledToChoose harmsOther financial established` | His refusal harms another and the right is established but not financial: he is compelled to choose. |
| `rightOnRefuserExacted rightOnHim exactable` | A right owed by him that can be exacted is exacted from him. |
| `substituteRefusalJudgedByOriginal refusedSubstitute` | Owing an original and a substitute, if he refuses the substitute he is judged by the original. |

## In one line

The non-existent can be included only by following something existing, unknown order counts as sequence, and refusing a choice between rights is resolved by harm, kind of right and whether it is established.
