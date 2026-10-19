# Usul.Readings.Concordance in Plain English

Source: [`formal/lean/Usul/Readings/Concordance.lean`](../../../../formal/lean/Usul/Readings/Concordance.lean)

Two separate efforts formalised the same four of Ibn Rajab's qawāʿid (maxims). For qawāʿid 3, 9 and 15 the two readings are proved equal. For qāʿida 14 they read two different moves of the text, so they are joined by a reconciliation (jamʿ) that matches the madhhab's preferred position.

## 1. Qāʿida 3: the excess over a duty

| Theorem | Plain English |
| --- | --- |
| `q3_readings_agree` | `wholeObligatory` and `excessObligatory` are the same function. The excess is obligatory only when it cannot be told apart and the whole was the original, lightened duty. |

## 2. Qāʿida 9: worship done in a prohibited way

- **`siteOf`**, **`siteOf_inv`**: a one-to-one match between the two readings' lists of where a prohibition sits. The four sites are the act of worship itself, a condition specific to it, a general condition, and something outside it.

| Theorem | Plain English |
| --- | --- |
| `siteOf_inv_siteOf`, `siteOf_siteOf_inv` | The match is a bijection. |
| `q9_readings_agree` | Both readings give the same validity verdict on every site. Worship stays valid only when the prohibition is external. |
| `validDespite_refines_q38` | The newer reading also agrees with al-Saʿdī's Q38 on every site. |

## 3. Qāʿida 15: a presumption does not carry its corollary

| Theorem | Plain English |
| --- | --- |
| `q15_readings_agree` | "The corollary carries" is exactly "not each matter on its own aṣl". |

## 4. Qāʿida 14: two men, one doubtful breach

The case: one of two men must have broken his purity, but each is unsure it was him. The text asks two questions. Taken alone, does the ruling attach to each? Taken together, how are they ruled jointly?

- **`attachTo`**: Ibn Rajab's farq. A harmless ruling (requiring purification) attaches to each; where it would cut a right, each abstains.
- **`oneOfTwoAttaches`**: the joint case. Taken together (e.g. one leading the other in prayer), the certain cause attaches.
- **`attachOnCertainty`**: the jamʿ. If the ruling is harmless and each is certain of his purity and doubts only the breach, it binds neither. This is the madhhab position in al-Inṣāf, al-Furūʿ and Sharḥ al-Muntahā.

| Theorem | Plain English |
| --- | --- |
| `attachOnCertainty_conservative` | Without each man's certainty, the jamʿ is just `attachTo`. |
| `attachOnCertainty_departs` | The jamʿ differs from `attachTo` only in the harmless, certain case, and only by binding neither. |
| `attachOnCertainty_abstains` | Where a right would be cut, each abstains, certain or not. |
| `q14_alone_is_q15` | The alone case is qāʿida 15: each stays on his aṣl, and the corollary does not carry. |
| `q14_together_attaches_alone_not` | Taken together the cause attaches; taken alone it does not. |

## In one line

Where two formalisations of a maxim say the same thing, the file proves it; where they answer different questions, it joins them so neither is lost.
