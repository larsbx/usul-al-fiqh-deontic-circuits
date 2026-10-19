# Usul.Readings.RajabA16 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA16.lean`](../../../../formal/lean/Usul/Readings/RajabA16.lean)

Three of Ibn Rajab's qawāʿid (legal maxims) become yes/no rules. Liability for a shot is reckoned at the hit but retaliation at the shot. Needed house, servant and mount are not surplus wealth. The ability to gain wealth by marriage is not richness.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*, from the pinned witness `openiti-rajab-shamela21730`.
- **Reading**: a Boolean function of named facts. Status: candidate.
- Where the text gives several views («فيه للأصحاب أوجه»), the reading takes one the qāʿida names. The others stay in `corpus/takhrij/rajab_m8_rajab_a16_furu.json`.
- Qāʿida 127 is read elsewhere, as `Usul.Readings.Mubashara.damanOn`; this shard's duplicate was dropped.

## 2. Shot and hit (qāʿida 129)

The target's state may change between the shot and the hit. The reading takes the qāʿida's third option: split qawad (retaliation) from ḍamān (liability).

| Definition / Theorem | Plain English |
| --- | --- |
| `hitStateGoverns liabilityRuling` | The state at the hit governs ⟺ the ruling is a liability (diya, a slave's value, the jazāʾ for game). |
| `qawad_at_shot` | Qawad is never reckoned at the hit; it goes by the shot. |
| `aqilaBears memberAtShot memberAtHit` | A body of kin (ʿāqila) bears the diya ⟺ the shooter belonged to it at both the shot and the hit. |
| `changed_affiliation_bars_aqila` | If his affiliation changed in between, no ʿāqila bears it; the diya falls on his own wealth. |

## 3. Needed goods (qāʿida 130)

| Definition / Theorem | Plain English |
| --- | --- |
| `countsAsSurplus needed` | A house, servant or mount counts as surplus wealth ⟺ he does not need it. Surplus bars taking zakat, obliges ḥajj and kaffāra (expiation), and pays debts. |
| `needed_not_surplus` | What he needs is never surplus. Aḥmad states this. |

## 4. Wealth by marriage (qāʿida 131)

| Definition / Theorem | Plain English |
| --- | --- |
| `countsAsRich hasWealth _canEarnByBudh` | A person counts as rich ⟺ they hold wealth. The power to gain a mahr by marrying (the buḍʿ) is ignored. |
| `budh_capacity_irrelevant` | That power adds nothing to richness. |

## In one line

Liability waits for the hit while retaliation is fixed at the shot, needed essentials are not surplus, and the prospect of a dowry is not wealth.
