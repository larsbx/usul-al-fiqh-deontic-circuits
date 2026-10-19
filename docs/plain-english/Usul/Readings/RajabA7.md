# Usul.Readings.RajabA7 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA7.lean`](../../../../formal/lean/Usul/Readings/RajabA7.lean)

Three of Ibn Rajab's qawāʿid (legal maxims) become yes/no rules: a vowed act is ruled like a sharʿ obligation, two halves suffice only in a common measure, and a cause brought about in a forbidden way toward what souls crave is cancelled.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*, from the pinned witness `openiti-rajab-shamela21730`.
- **Reading**: a Boolean function of named facts. Status: candidate.
- Where the text says «فيه خلاف» (there is disagreement), the reading takes one side and names its ground. The other side stays recorded in `corpus/takhrij/rajab_m8_rajab_a7_furu.json`.

## 2. The vowed obligation (qāʿida 100)

Is a vowed act like an obligation imposed by the sharʿ (revealed law), or like a voluntary (mandūb) act? The reading takes the sharʿ side, after al-Qāḍī.

| Definition / Theorem | Plain English |
| --- | --- |
| `vowedRuling sharRuling _mandubRuling` | The vowed act gets whatever the sharʿ obligation would get. The mandūb answer is ignored. |
| `vowed_agreeing_analogues` | Where both analogues agree, there is nothing to dispute. |

## 3. Two halves of a choice (qāʿida 101)

| Definition | Plain English |
| --- | --- |
| `splitSuffices commonUnit` | Half of each of two options suffices ⟺ both are counted in one unit (a slave's freedom, a ṣāʿ, the poor of a kaffāra). A day's fast plus feeding four poor has no common measure and does not suffice. |

## 4. A forbidden cause (qāʿida 102 and its attached qāʿida)

| Definition / Theorem | Plain English |
| --- | --- |
| `causeVoided forbiddenManner soulsDrawn` | A cause of ownership, lawfulness or release is cancelled (ilghāʾ) ⟺ it was brought about in a forbidden way and is something souls are drawn to. |
| `deterred_cause_stands` | A cause human nature already deters from is never cancelled. |
| `hastenedForfeited hastenedForbidden` | Whoever hastens his right before its time in a forbidden way is deprived of it. |
| `killing_heir_under_both` | The heir who kills the one he inherits from falls under both rules alike. |

## In one line

A vow follows the sharʿ obligation, halves count only when they share a unit, and a forbidden shortcut to something craved is void and forfeits the prize.
