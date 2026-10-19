# Usul.Readings.RajabA17 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA17.lean`](../../../../formal/lean/Usul/Readings/RajabA17.lean)

Five of Ibn Rajab's qawāʿid (legal maxims) become yes/no rules: a craft as richness, impediments that prevent but do not lift, which bars on intercourse reach its preliminaries, when an unfixed right may reach a fixed one, and when a custodian's liability is measured.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*, from the pinned witness `openiti-rajab-shamela21730`.
- **Reading**: a Boolean function of named facts. Status: candidate.
- Where the text leaves a branch open, the reading takes a side the qāʿida names and says which. The others stay in `corpus/takhrij/rajab_m8_rajab_a17_furu.json`.

## 2. Earning by a craft (qāʿida 132)

The ability to earn by a craft is richness for one's own and one's dependants' maintenance. For what lies beyond (ḥajj, debts, jizya) there are two riwāyas. The reading takes the one that it is richness there too.

| Definition / Theorem | Plain English |
| --- | --- |
| `craftCountsAsRich hasWealth canEarnByCraft _beyondOwnMaintenance` | He counts as rich ⟺ he has wealth or can earn by a craft. |
| `craft_rich_for_own_maintenance` | For his own maintenance, a craft is richness on both riwāyas. |
| `no_wealth_no_craft_not_rich` | With neither, he is never rich. |

## 3. Prevention is easier than removal (qāʿida 134)

| Definition / Theorem | Plain English |
| --- | --- |
| `impedimentOperates impediment beforeEstablishment` | An impediment takes effect ⟺ it exists before the ruling is established. Islam prevents enslavement but does not lift it once in place. |
| `no_impediment_no_effect` | No impediment, no effect. |
| `supervening_does_not_lift` | A later impediment does not lift what was established. |

## 4. Bars on intercourse (qāʿida 136)

| Definition / Theorem | Plain English |
| --- | --- |
| `preliminariesForbidden weakOwnership worship barsIndulgence` | The preliminaries of intercourse are forbidden too ⟺ the bar comes from weak ownership, or from a worship that bars all indulgence (strong iḥrām, iʿtikāf). |
| `weak_ownership_forbids_all` | A bar from weak ownership forbids every kind of enjoyment. |
| `fasting_spares_preliminaries` | Fasting forbids intercourse but not the preliminaries. |
| `non_worship_spares_preliminaries` | A bar that is not worship (menses, on the sound view) forbids intercourse alone. |

## 5. Fixed and unfixed rights (qāʿida 139)

| Definition / Theorem | Plain English |
| --- | --- |
| `unfixedMayReachFixed takesAllWhenAlone tiedToBase sameLocus` | An unfixed right may reach the fixed one ⟺ its holder takes everything when alone, or it is tied to a base and the two rights fall on different loci. |
| `discretion_without_base_stays_below` | A discretionary right with no base never reaches the fixed one. |
| `same_locus_stays_below` | In one locus, the estimated right (the ḥukūma) stays below the fixed one. |

## 6. A custodian who destroys (qāʿida 141)

| Definition / Theorem | Plain English |
| --- | --- |
| `dueTimeGoverns custodianUntilTerm` | One bound to keep a thing for God's right until a term, who destroys it, is liable at its value at that term, not on the day it was destroyed. |
| `outsider_at_destruction` | Anyone else is liable at the day of destruction. |

## In one line

A craft counts as wealth, impediments block beginnings but not continuations, only weak ownership or full-abstention worship forbids the preliminaries, unfixed rights stay below fixed ones in one locus, and a custodian answers at the term.
