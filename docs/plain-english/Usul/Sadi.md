# Usul.Sadi in Plain English

Source: [`formal/lean/Usul/Sadi.lean`](../../../formal/lean/Usul/Sadi.lean)

Al-Saʿdī's *al-Qawāʿid wa'l-Uṣūl al-Jāmiʿa*, a book of 60 legal maxims, gets formal readings for about twenty of its rules. Each section names the rule number (`Qnn`) of the Dār al-Waṭan edition. The statements are readings, not the text, and each is a candidate until reviewed.

## 1. Benefit and harm (Q1)

- **`Weighing`**: an act's benefit and harm on a common scale.
- **`Q01`**: the Lawgiver demands an act only if its benefit exceeds its harm, and forbids it only if harm exceeds benefit.

| Theorem | Plain English |
| --- | --- |
| `q01_balanced_is_mubah` | Under Q1, an act whose benefit and harm are equal is mubāḥ (permitted, neither demanded nor forbidden). |

## 2. Means and capacity (Q2, Q4)

- **`operative capable darura`**: the ruling in force given capacity and ḍarūra (necessity). A wājib (obligation) without capacity becomes mubāḥ. A ḥarām under necessity becomes mubāḥ.

| Theorem | Plain English |
| --- | --- |
| `q02_means_of_wajib` | What an obligation necessarily needs is itself obligatory. |
| `q04_no_wajib_with_inability` | No obligation with inability. |
| `q04_no_haram_with_necessity` | No prohibition with necessity. |
| `q04_ordinary_case` | With capacity and no necessity, the ruling stands unchanged. |
| `q04_relief_never_binds` | Relief only loosens: the operative ruling is never more binding than the original. |

## 3. Defaults and gates (Q6, Q8)

- **`ruled d dalil`**: the ruling is the dalīl's (proof's), if there is one; else the domain's default.
- **`Gate`**: a list of conditions and impediments. **`Gate.Holds`**: all conditions met and no impediment present.

| Theorem | Plain English |
| --- | --- |
| `q06_no_worship_without_dalil` | In ʿibādāt (worship), the default with no proof is prohibition. |
| `q06_customs_permitted_by_default` | In ʿādāt (customs), the default is permission. |
| `q06_dalil_prevails` | A proof, when present, decides. |
| `q08_missing_condition` | One missing condition stops the ruling. |
| `q08_present_impediment` | One present impediment stops the ruling. |

## 4. Certainty and indicators (Q11, Q52)

| Theorem | Plain English |
| --- | --- |
| `q11_yaqin` | Certainty (yaqīn) is not removed by doubt (shakk). |
| `q52_strong_qarina_prevails` | A strong indicator (qarīna), at least as strong as the presumption, prevails over it. |

## 5. Justice, settlements, excuses and substitutes (Q16, Q22–23, Q27, Q28)

- **`Conduct`**: ʿadl (justice) is wājib; faḍl (generosity) is mandūb (recommended).
- **`Voids before after`**: a settlement or condition that turns the ḥarām into the non-ḥarām, or the reverse.
- **`dischargedByExcuse`**: for omitting a command, an excuse of ignorance or forgetting does not discharge it; for committing a prohibition, it does.
- **`useSubstitute`**, **`permits`**, **`Means`**: the substitute (as tayammum for water) is used only when the original is impossible, and then permits what the original permits.

| Theorem | Plain English |
| --- | --- |
| `q16_adl_binding_fadl_not` | Justice binds, generosity does not. |
| `q22_valid_iff_preserves_prohibition` | A settlement or condition is valid ⟺ it keeps the ḥarām exactly where it was. |
| `q27_asymmetry` | An excused omission must still be made up; an excused prohibited act is forgiven. |
| `q28_substitute_only_when_needed` | Use the substitute ⟺ the original is not possible. |
| `q28_stands_in_everything` | Once in use, the substitute permits exactly what the original does. |

## 6. Crowding benefits and harms (Q33)

- **`best key xs`**: the first item with the largest key in a list.

| Theorem | Plain English |
| --- | --- |
| `best_mem` | The chosen item is in the list. |
| `best_cons_ne_none` | A non-empty list always yields a choice. |
| `best_max` | No item has a larger key than the chosen one. |
| `q33_higher_benefit` | Among competing benefits, the chosen one is the greatest. |
| `q33_lighter_harm` | Among unavoidable harms, the chosen one is the lightest. |

## 7. Prohibition and partial performance (Q38, Q40)

- **`ProhibitionTarget`**: a prohibition aims at the act's essence, its condition, or something external.
- **`obligedParts`**: of a command's parts, those he can do and that are not pure means (wasīla maḥḍa).

| Theorem | Plain English |
| --- | --- |
| `q38_voids_iff_intrinsic` | A prohibition makes the worship fāsid (invalid) ⟺ it targets the essence or a condition, not something external. |
| `q40_only_capable_parts` | Only parts he can do are obliged. |
| `q40_every_capable_part` | Every part he can do, that is not a pure means, is obliged. |

## 8. The ʿilla and qiyās (Q58)

- **`DependsOn H e`**: the ruling depends only on the feature `e`, the ʿilla (operative cause).

| Theorem | Plain English |
| --- | --- |
| `q58_qiyas` | Qiyās (analogy) is sound: a farʿ (new case) sharing the aṣl's (base case's) ʿilla shares its ruling. |
| `q58_factors` | The ruling depends only on the ʿilla ⟺ it is a function of the ʿilla. |
| `q58_naqd` | Naqḍ (counterexample): same ʿilla with a different ruling disproves dependence. |

## 9. Words of generality (Q59, Q60)

- **`Context`**: affirmation, negation, prohibition, condition, question.
- **`NounForm`**: indefinite noun (nakira), particles like man and mā, generic al-, the annexed singular.
- **`IsGeneral`**: an indefinite is general (ʿāmm) after negation, prohibition or condition. The other forms are general in every context.

| Theorem | Plain English |
| --- | --- |
| `q59_nakira_general_in_negation` | An indefinite under negation is general. |
| `q59_nakira_absolute_in_affirmation` | An indefinite in plain affirmation is absolute (muṭlaq), not general. |
| `q60_markers_general` | Every other marker is general in any context. |

## In one line

Al-Saʿdī's maxims on benefit, capacity, defaults, certainty, substitutes, competing harms, prohibition, analogy and general words become checkable rules, each proved to say what the maxim says.
