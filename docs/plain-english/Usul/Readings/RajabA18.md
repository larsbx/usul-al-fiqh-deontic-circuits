# Usul.Readings.RajabA18 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA18.lean`](../../../../formal/lean/Usul/Readings/RajabA18.lean)

Two of Ibn Rajab's qawāʿid (legal maxims) become yes/no rules. If deliberate killing makes one of two things due (qawad or diya), taking or waiving qawad over an encumbered victim forfeits wealth owed to another. A thing burdened with a right is compensated if guaranteed, or if destroyed while someone holds the right.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*, from the pinned witness `openiti-rajab-shamela21730`.
- **Reading**: a Boolean function of named facts. Status: candidate.
- Qāʿida 137 asks whether deliberate killing obliges qawad (retaliation) alone or one of two things. The input `eitherOfTwo` keeps both riwāyas expressible. Other sides stay in `corpus/takhrij/rajab_m8_rajab_a18_furu.json`.

## 2. Retaliation and waiver (qāʿida 137, first and second parts)

The reading takes the wajh Ibn Rajab marks better known, which Aḥmad states.

| Definition / Theorem | Plain English |
| --- | --- |
| `forfeitsAttachedRight eitherOfTwo victimEncumbered` | Taking or waiving qawad forfeits wealth owed to another ⟺ one of two things is due and the victim carried another's right (a pledge, a legacy, a partner's share). He may not then act alone, and is liable if he does. |
| `qawad_alone_forfeits_nothing` | If qawad alone is due, nothing is forfeited. |
| `unencumbered_forfeits_nothing` | If no other right attached to the victim, nothing is forfeited. |

## 3. Settlement (qāʿida 137, third part)

| Definition / Theorem | Plain English |
| --- | --- |
| `sulhReplacesWealth eitherOfTwo victimOwned` | A ṣulḥ (settlement) counts as an exchange of wealth ⟺ one of two things is due and the one killed was the claimant's own slave. Otherwise it is over the qawad. |
| `sulh_on_qawad_alone` | If qawad alone is due, a ṣulḥ is never an exchange for wealth. |
| `sulh_for_free_victim` | A ṣulḥ over a free man's blood is always over the qawad. |

## 4. Compensating a burdened thing (qāʿida 138)

| Definition / Theorem | Plain English |
| --- | --- |
| `mustCompensate guaranteed destroyed claimantExists` | Ḍamān (compensation) is due ⟺ the thing was guaranteed, or it was destroyed by an act (itlāf) and a beneficiary of the right exists. |
| `guaranteed_always` | A guaranteed thing is compensated in every case. |
| `unguaranteed_perishing_free` | An unguaranteed thing that merely perishes is not compensated. |
| `unguaranteed_without_claimant_free` | An unguaranteed thing with no present beneficiary owes nothing. |

## In one line

When killing obliges qawad or diya, acting on an encumbered victim costs another's wealth and a settlement for one's own slave is a wealth exchange; and a burdened thing is owed for if guaranteed, or if destroyed while someone holds the right.
