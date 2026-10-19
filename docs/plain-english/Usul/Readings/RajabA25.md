# Usul.Readings.RajabA25 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA25.lean`](../../../../formal/lean/Usul/Readings/RajabA25.lean)

Ibn Rajab's qāʿida 158 becomes a yes/no rule: when two uṣūl (base presumptions) conflict, the reinforced one governs. When they are equal, the reading takes the first-stated wajh (view), and the case is marked as a genuine ikhtilāf (disagreement).

## 1. How the reading works

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*, from the pinned witness `openiti-rajab-shamela21730`. Status: candidate.
- Each record names two uṣūl, one behind each position. The *first* aṣl stands behind the position the record states first.
- **`firstReinforced`** / **`secondReinforced`**: the record says that aṣl is reinforced («معتضد», «عضده الظاهر»).
- With equal uṣūl the text gives only two wujūh. Those stay recorded in `corpus/takhrij/rajab_m8_rajab_a25_furu.json`, to be checked against later works.

## 2. The rule

| Definition / Theorem | Plain English |
| --- | --- |
| `firstAslGoverns firstReinforced secondReinforced` | The ruling follows the first aṣl ⟺ it is reinforced, or the second is not. |
| `reinforced_first_governs` | A reinforced first aṣl governs, whatever is said of the second. |
| `reinforced_second_alone_governs` | A second aṣl reinforced alone wins: «عمل بالأرجح منهما». |
| `equal_usul_take_first_stated` | Neither reinforced: equal, so the first-stated wajh. |
| `both_reinforced_equal` | Both reinforced is again equality, with the same result. |

## In one line

Between two conflicting presumptions, the one with support wins; with no difference in support, the first-stated view is taken and the case is flagged as real disagreement.
