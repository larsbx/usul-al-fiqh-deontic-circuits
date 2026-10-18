# Usul.Readings.RajabA11 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA11.lean`](../../../../formal/lean/Usul/Readings/RajabA11.lean)

Four of Ibn Rajab's qawāʿid (legal maxims) become one-input yes/no rules. They cover the lesser of two forbidden things in necessity, how one set is distributed over another, unqualified partnership, and shared rights. The file has one theorem.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*.
- **Reading**: a Boolean function of named facts. Status: candidate.
- Where the statement leaves a question to khilāf (disagreement), the reading takes the side the statement marks («الأشهر», the better known), or the split it draws between contexts.

## 2. The readings

| Definition / Theorem | Plain English |
| --- | --- |
| `necessityPermits heavier` | Q112: one in necessity (muḍṭarr) facing two forbidden things may take an option ⟺ it is not the heavier in harm. The excess has no necessity. When both are equal, neither is excess. |
| `eachOverWhole qarinaOneToOne` | Q113: numbered things spread over another set go each over the whole ⟺ no qarīna (contextual indicator) points to one-to-one pairing. |
| `eachOverWhole_unmarked` | With no qarīna, the qāʿida's «الأشهر» applies: each over the whole. |
| `sharikaHalves isIqrar` | Q114: an unqualified "partnership" means half and half ⟺ it is not stated in an admission (iqrār). In an admission it is vague. |
| `accruesToRest eachEntitledWhole` | Q115: when each holder of a shared right is entitled to the whole, what one drops accrues to the rest. |

## In one line

In necessity take the lighter harm, spread sets each-over-whole unless context pairs them, read an unqualified partnership as halves except in an admission, and let a whole-entitlement pass to the others when one gives it up.
