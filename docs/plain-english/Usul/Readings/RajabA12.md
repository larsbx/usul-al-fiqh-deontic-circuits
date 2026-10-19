# Usul.Readings.RajabA12 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA12.lean`](../../../../formal/lean/Usul/Readings/RajabA12.lean)

Three of Ibn Rajab's qawāʿid (legal maxims) on timing and suspension become yes/no rules. Ownership relates back to a settled cause; a suspended contract follows the state at its occurrence unless the sharʿ bars it; and suspending annulment on something's existence needs a lawful purpose.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*, from the pinned witness `openiti-rajab-shamela21730`.
- **Reading**: a Boolean function of named facts. Status: candidate.
- Where the text poses a question («فيه خلاف», «قولان»), the reading takes one side and names its ground. The other side stays recorded in `corpus/takhrij/rajab_m8_rajab_a12_furu.json`.

## 2. Ownership that relates back (qāʿida 116)

| Definition / Theorem | Plain English |
| --- | --- |
| `ruledFromCause settledCause` | Ownership is reckoned from when its cause was concluded ⟺ the cause cannot be voided. |
| `unsettled_cause_not_retroactive` | A cause still voidable (the fuḍūlī's contract before ratification) does not reach back. |
| `worshipFromStart conditionWithinTime` | The attached class: a worship whose missing condition was met within its time is ruled as complete from its start. |
| `worship_joins_q116` | The worship class is the same rule as qāʿida 116, as the text says («ويلتحق بهذه القاعدة»). |

## 3. A suspended contract across two states (qāʿida 117)

A contract suspended (taʿlīq) in one state may take effect in another. The reading takes the state of occurrence and drops any side the sharʿ bars.

| Definition / Theorem | Plain English |
| --- | --- |
| `occurrenceGoverns _suspensionBarred occurrenceBarred` | The state of occurrence governs ⟺ that state is not sharʿan barred. |
| `occurrence_by_default` | With neither side barred, occurrence governs. |
| `barred_side_dropped` | A barred side is dropped: barring suspension leaves occurrence; barring occurrence removes it. |
| `occurrence_barred_never_governs` | A barred state of occurrence never governs. |

## 4. Suspending annulment (qāʿida 118)

| Definition | Plain English |
| --- | --- |
| `cancelOnExistenceValid legitimatePurpose` | Suspending a contract's annulment on its own existence is valid ⟺ it serves a purpose the sharʿ recognises. Otherwise the contract would not be meant for itself. |

## In one line

A settled cause carries ownership back to its start, a suspended contract follows the moment it takes effect unless the law forbids that, and an annulment clause is valid only with a recognised purpose.
