# Usul.Readings.RajabA21 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA21.lean`](../../../../formal/lean/Usul/Readings/RajabA21.lean)

Five of Ibn Rajab's qawāʿid (legal maxims) become yes/no rules: where a woman's measure is half a man's, how determinate rights differ, when a cause governs a transfer, the four kinds of marriage prohibition, and what fixes the whole mahr.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*, from the pinned witness `openiti-rajab-shamela21730`.
- **Reading**: a Boolean function of named facts. Status: candidate.
- Where a record reports a split, the reading gives the qāʿida's own statement. Other sides stay in `corpus/takhrij/rajab_m8_rajab_a21_furu.json`.

## 2. Halving and determinate holders (qawāʿid 147 and 149)

| Definition / Theorem | Plain English |
| --- | --- |
| `womanHalf female listedPoint` | Her measure is half a man's ⟺ she is a woman and the point is listed (inheritance, diya, ʿaqīqa, testimony, gifts to children, days of prayer). |
| `man_not_halved` | A man's measure is never halved. |
| `unlisted_not_halved` | Off the listed points, nothing is halved. |
| `determinateHolderRule holderDeterminate` | A right held by a determinate person takes the determinate holder's rules. |
| `indeterminate_differs` | A right owed to no determinate holder does not. |

## 3. Causes behind transfers (qāʿida 150)

| Definition / Theorem | Plain English |
| --- | --- |
| `causeGovernsTransfer givenForCause independentCause` | A gift, sale or waiver takes its cause's ruling ⟺ it was made because of a cause (a loan, an office) and no independent cause, such as a prior custom of gifting, explains it. |
| `independent_cause_frees` | An independent cause always frees the transfer. |
| `no_cause_not_governed` | A transfer made for no cause is not governed by one. |

## 4. Prohibited marriages (qāʿida 152)

Four kinds: by nasab (lineage), by ṣihr (marriage ties), by combination (jamʿ), and by riḍāʿ (nursing).

| Definition / Theorem | Plain English |
| --- | --- |
| `marriageProhibited nasabDabit sihrClass jamRahm radaCounterpart` | The marriage, or the combination, is prohibited ⟺ any of the four applies. |
| `outside_four_kinds_lawful` | Outside the four kinds, every relative is lawful. |
| `rada_counterpart_prohibits` | The nursing counterpart of a lineage prohibition always prohibits. |

## 5. Fixing the whole mahr (qāʿida 155)

| Definition / Theorem | Plain English |
| --- | --- |
| `mahrEstablished intercourse khalwa capable death` | The whole mahr is hers ⟺ intercourse, or seclusion (khalwa) with one capable of intercourse, or death before consummation. |
| `khalwa_without_capacity` | Seclusion with one incapable establishes nothing by itself. |
| `intercourse_establishes` | Intercourse fixes the mahr in every case. |
| `death_establishes` | Death before consummation fixes it in every case. |

## In one line

A woman's share is halved only on the listed points, determinate rights have their own rules, a transfer for a cause follows the cause unless custom explains it, four kinds of tie bar marriage, and three events fix the whole mahr.
