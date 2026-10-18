# Usul.Readings.RajabA14 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA14.lean`](../../../../formal/lean/Usul/Readings/RajabA14.lean)

Three of Ibn Rajab's qawāʿid (legal maxims) on specifying general wording become yes/no rules. All three answer one question: does the general wording cover this instance? Custom, the sharʿ, and the rarity of an unintended case can each take an instance out.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*, from the pinned witness `openiti-rajab-shamela21730`.
- **Reading**: a Boolean function of named facts. Status: candidate.
- Where a class is left to khilāf (disagreement), the reading takes one side and names its ground in the text. The other side stays in `corpus/takhrij/rajab_m8_rajab_a14_furu.json`.

## 2. Specification by custom (qāʿida 121)

Three classes of instance:

- **`urfiHaqiqa`**: the general name has come, by custom, to mean only some members.
- **`onlyQualified`**: the instance is never called by the general name without a qualifier.
- **`mostlyQualified`**: it is usually named with a qualifier and rarely understood without one. This class has two wujūh; the reading excludes it, after Aḥmad's naṣṣ on vowing one's property.

| Definition / Theorem | Plain English |
| --- | --- |
| `urfGeneralCovers` | The general wording covers the instance ⟺ it falls in none of the three classes. |
| `urfi_haqiqa_bars` | A customary ḥaqīqa (accepted meaning) always specialises, «بغير خلاف». |
| `only_qualified_bars` | What is named only with its qualifier never enters. |
| `mostly_qualified_bars` | On the reading's side, the mostly-qualified is not covered either. |
| `plain_member_covered` | Outside the three classes, the instance is covered. |

## 3. Specification by the sharʿ (qāʿida 123)

| Definition / Theorem | Plain English |
| --- | --- |
| `sharGeneralCovers sharExcludes` | The wording covers the instance ⟺ the sharʿ (revealed law) does not set it apart. Examples: a forbidden fast-day, forbidden meat, an heir in a bequest. |
| `shar_excluded_not_covered` | What the sharʿ excludes is never covered. |
| `shar_like_urf` | The sharʿ specialises exactly as one class of custom does. |

## 4. Rare or barred instances not intended (qāʿida 126)

| Definition / Theorem | Plain English |
| --- | --- |
| `unintendedCovered rareOrBarred intended` | The wording covers the instance ⟺ the speaker intended it, or it is not rare or barred. |
| `intended_covered` | A declared intention brings any instance in. |
| `ordinary_instance_covered` | An ordinary instance stays covered whatever the speaker says, like the wife in «ما أحل الله علي حرام». |
| `rare_unintended_not_covered` | A rare or barred instance not intended is not covered. |

## In one line

General wording reaches every ordinary instance, but custom, the sharʿ and a rare case the speaker did not mean each carve instances out.
