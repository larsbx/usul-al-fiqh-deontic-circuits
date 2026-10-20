# Usul.Readings.Maqasid in Plain English

Source: [`formal/lean/Usul/Readings/Maqasid.lean`](../../../../formal/lean/Usul/Readings/Maqasid.lean)

The law serves purposes (maqāṣid): preserving religion, life, mind, lineage and wealth, in three ranks of urgency. This module reads that doctrine from four texts. It then uses it twice: to say when an interest (maṣlaḥa) counts as a proof, and to order two conflicting interests in tarjīḥ (weighing).

The four texts:

- al-Shāṭibī, *al-Muwāfaqāt* (Kitāb al-Maqāṣid, v02 p017–033): the ranks, the five, the two sides of preservation, complements and their condition, and how the ranks depend on each other.
- al-Ghazālī, *al-Mustaṣfā* (v01 p173–177): the five, and his three conditions for an unattested interest, with his own cases.
- Ibn Qudāma, *Rawḍat al-Nāẓir* (v01 p478–483): the same doctrine in the madhhab's own uṣūl, and the dispute.
- Ibn al-Najjār, *Sharḥ al-Kawkab al-Munīr* (v04 p158–169, p726–728): the Ḥanbalī order of the purposes in tarjīḥ.

## 1. The ranks and the five

- **`Rutba`**: the three ranks. Necessities (ḍarūrī), needs (ḥājī), refinements (taḥsīnī), ranked in that order.
- **`Kulli`**: the universals (kulliyyāt): religion, life, mind, lineage, wealth, and honour (ʿirḍ), which only al-Kawkab adds.
- The lists as each text gives them: `fiveMustasfa`, `fiveRawda`, `fiveMuwafaqat`, `sixKawkab`.
- **`Kulli.rank`**: al-Kawkab's order, read from the «ف» ("then") joining his list. Honour sits level with wealth, "the lowest of the universals".

| Theorem | Plain English |
| --- | --- |
| `Rutba.rank_injective` | No two ranks share a place. |
| `rawda_is_mustasfa` | The Rawḍa gives al-Ghazālī's five in his order. |
| `muwafaqat_same_five` | al-Shāṭibī's five are the same five, in another order. |
| `five_nodup` | Neither list repeats an item. |
| `kawkab_adds_ird` | al-Kawkab's list is the five with honour appended. |
| `ird_outside_the_five` | Honour is not among the five of al-Ghazālī or al-Shāṭibī. |
| `kawkab_descending` | al-Kawkab lists his universals from highest rank to lowest. |
| `ird_lowest` | Honour is the lowest, level with wealth. |

## 2. Preservation from two sides

al-Shāṭibī: the necessities are kept by what establishes them (the side of existence, wujūd) and by what wards off their loss (the side of non-existence, ʿadam).

- **`Janib`**: the two sides.
- **`Bab`**: the four divisions of the law: acts of worship, customs, transactions, offences.
- **`preserves`**: worship keeps religion; customs keep life and mind; transactions keep lineage and wealth, all from the side of existence. Offences (jināyāt) keep all five from the side of non-existence.
- **`mediated`**: transactions also keep life and mind, but only through customs.

| Theorem | Plain English |
| --- | --- |
| `both_sides` | Every one of the five is kept from both sides. |
| `wujud_partition` | From the side of existence, each of the five has exactly one division that keeps it directly. |
| `adam_only_jinayat` | Only the offences keep anything from the side of non-existence. |

## 3. The deterrents

The Rawḍa and al-Mustaṣfā give one deterrent (zajr) for each of the five: killing the misleading unbeliever (religion), retaliation (life), the penalty for drinking (mind), the penalty for zinā (lineage), and deterring the thief (wealth).

| Theorem | Plain English |
| --- | --- |
| `deterrents_cover_the_five` | The deterrents run through the Rawḍa's five in its own order. |
| `deterrent_unique` | No two deterrents keep the same universal. |
| `deterrents_are_jinayat` | Each deterrent keeps its universal from the side of non-existence. |

## 4. When an interest is a proof (istiṣlāḥ)

- **`Shahada`**: the law's witness to an interest: attested (iʿtibār), cancelled (ilghāʾ), or neither (irsāl, the "unattested" maṣlaḥa mursala).
- **`Maslaha`**: an interest's witness, rank, certainty (qaṭʿiyya) and universality (kulliyya).
- **`Stance`**: the three positions on the unattested necessity, pinned and never chosen. The Rawḍa: not a proof. al-Ghazālī: a proof only if certain and universal. Mālik, as the Rawḍa reports him: a proof.
- **`hujja`**: is the interest a proof? Attested: yes, that is qiyās. Cancelled: no, on everyone's view. Unattested need or refinement: no ("we know of no dispute"). Unattested necessity: the stance decides.

| Theorem | Plain English |
| --- | --- |
| `dispute_locus` | The stances disagree only on an unattested necessity. |
| `stances_nested` | Whatever the Rawḍa admits al-Ghazālī admits, and whatever he admits Mālik admits. |
| `refines_recognition` | Ties this to `Usul.Qiyas.Recognition`: the cancelled interest is its never-accepted `mulgha`, and the unattested necessity is its `mursal`, whose disputed acceptance each stance fixes. |
| `tatarrus` | al-Ghazālī: unbelievers shielding themselves with Muslim captives, when all Muslims would otherwise perish, is a certain and universal necessity, so it is a proof. |
| `qala` | The shield at a fortress fails, being uncertain, whatever its rank. |
| `safina` | Throwing one man from a ship, or eating one in a famine, fails, being not universal. |
| `kaffarat_al_malik` | Making a king fast for his expiation, since freeing a slave costs him nothing, is cancelled on every stance. |
| `tatarrus_disputed` | On the Rawḍa's stance the shield is not admitted this way: the question stays open. |

## 5. Complements

Each rank has complements (takmila), whose loss would not undo its purpose. al-Shāṭibī's condition: a complement counts only if counting it does not nullify what it completes.

- **`Nullifies`**: no feasible situation meets both the original and the complement, though some meets the original.
- **`required`**: the requirement in force: the original with its complement, or the original alone when the complement would nullify it.

| Theorem | Plain English |
| --- | --- |
| `takmila_never_cancels_asl` | If the original can be met, the requirement can be met. |
| `required_implies_asl` | The requirement always includes the original. |
| `takmila_considered` | A complement that does not nullify counts in full. |
| `takmila_dropped` | A complement that would nullify drops, and the original stands alone. |
| `najis_for_the_mahja` | Where only impure food is at hand, saving life requires eating it, and avoiding impurity drops. |

## 6. The necessity as the original

- **`Intact`**: which ranks stand. **`Intact.Coherent`**: a need stands only on a necessity, and a refinement only on a need.

| Theorem | Plain English |
| --- | --- |
| `daruri_disrupts_all` | If the necessity falls, the need and the refinement fall with it. |
| `others_need_not_disrupt_daruri` | The converse fails: the other two can fall while the necessity stands. |

## 7. The order in tarjīḥ

- **`Maqsad`**: what an interest serves: one of the universals, a complement of a necessity, a need, or a refinement. **`Maqsad.tier`** ranks them in that order.
- **`DinReading`**: the two positions on religion against the other necessities. al-Kawkab: religion first, "the greatest purpose". The dissent ("it was said"): the other four first, as rights of humans.
- **`taqdim`**: which of two conflicting interests is put first: the higher tier, then within the necessities by rank on the reading, otherwise suspension (tawaqquf).

| Theorem | Plain English |
| --- | --- |
| `tier_refines_rank` | The tiers refine al-Shāṭibī's three ranks: a complement of a necessity sits between it and a need. |
| `Maqsad.mem_all` | The nine values are all listed, so the checks below are exhaustive. |
| `tier_decides` | The higher tier always comes first, on either reading. |
| `taqdim_swap` | Swapping the two interests swaps the verdict. |
| `taqdim_trans` | Precedence is transitive. |
| `din_first` | On al-Kawkab's reading, religion precedes every other necessity. |
| `din_reading_locus` | The two readings differ only where religion meets another necessity. |
| `mal_ird_suspended` | Wealth against honour is suspended: al-Kawkab orders neither over the other. |
| `asl_before_takmila` | A necessity precedes its complement, a complement precedes a need, and a need a refinement. |

## In one line

The law keeps five universals in three ranks; an unattested interest is a proof only as each stance says, and between conflicting interests the higher rank comes first.
