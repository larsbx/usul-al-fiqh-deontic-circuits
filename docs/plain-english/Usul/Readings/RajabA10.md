# Usul.Readings.RajabA10 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA10.lean`](../../../../formal/lean/Usul/Readings/RajabA10.lean)

Two of Ibn Rajab's qawāʿid (legal maxims) become yes/no rules. Qāʿida 109 says how far a bar on an unspecified item, on a combination, or on a common amount spreads. Qāʿida 111 says when proof of one alternative alone makes it owed.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*.
- **Reading**: a Boolean function of named facts. Status: candidate.
- Where the statement leaves a question to khilāf (disagreement), the reading returns the side the statement does not establish.

## 2. Bars that spread (qāʿida 109)

The qāʿida names three kinds of bar.

| Definition / Theorem | Plain English |
| --- | --- |
| `vagueOneBarsAll confusionEffective distinguished` | First kind: a bar on one unspecified item, or one confused with others, bars dealing with all of them ⟺ the confusion has effect and the item is not yet singled out. |
| `combinationBarsItsAmount combiningAmount` | Second kind: a bar on combining bars only the amount that makes the combination. |
| `simultaneousCombinationVoids hasPrecedence` | If the combination happens at once, an item's contract is void ⟺ it lacks precedence over the other. The free woman, whose marriage can be added to the slave-woman's but not the reverse, is the model. |
| `simultaneous_equal_voids_all` | With equality, every item is void (fāsid). |
| `commonAmountGeneral barsCommonAmount` | Third kind: a bar on what is common to all (an indefinite under negation or a condition) is general over every instance. |

## 3. Proving one alternative (qāʿida 111)

When one cause makes one of two things due, and a proof points to one of them only, there are two riwāyas.

| Definition | Plain English |
| --- | --- |
| `alternativeProvenAlone proofEstablishesCause` | The alternative the proof points to is owed ⟺ the proof is one by which the cause itself is established. |

## In one line

An unresolved confusion bars every confused item, a bar on combining reaches only the combining amount (voiding all equals together), a bar on a common amount is general, and an alternative is owed only by a proof strong enough to establish its cause.
