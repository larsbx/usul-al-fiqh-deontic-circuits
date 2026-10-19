# Usul.Readings.RajabA29 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA29.lean`](../../../../formal/lean/Usul/Readings/RajabA29.lean)

Two of Ibn Rajab's typological qawāʿid become small rules. Qāʿida 84 asks whether the ḥaml (an unborn child) has a ḥukm (legal standing) before it separates from its mother; qāʿida 86 sorts milk (ownership) into four kinds.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*, from the pinned witness `openiti-rajab-shamela21730`. Status: candidate.
- **Qāʿida 84** reports two riwāyāt (reports from Aḥmad) and says «الصحيح من المذهب أن له حكما». It splits the rulings into two anwāʿ (kinds): those that bear on someone else by sabab of the ḥaml, which hold «بالاتفاق» once the amāra (outward sign) of the ḥaml shows; and those the ḥaml has in itself (milk, ʿitq, nasab, ḍamān, nafaqa), which are where the two riwāyāt part.
- **Qāʿida 86**: «ملك عين ومنفعة، وملك عين بلا منفعة، وملك منفعة بلا عين، وملك انتفاع من غير ملك المنفعة». The reading decides the kind from two facts: whether the raqaba (the thing itself) is his, and whether the benefit is his by a tamlīk (a transfer of it) rather than a bare permission.
- The records' other positions stay recorded in `corpus/takhrij/rajab_m8_rajab_a29_furu.json`.

## 2. Qāʿida 84

| Definition / Theorem | Plain English |
| --- | --- |
| `hukmBeforeSeparationOn hasHukm forAnother evident` | Both riwāyāt pinned: a ruling takes effect before birth ⟺ the amāra shows, and either it bears on another or the riwāya gives the ḥaml a ḥukm. |
| `hamlHukm forAnother evident` | The reading: the same on the ṣaḥīḥ riwāya. |
| `first_nawa_agreed` | Rulings on others by sabab of the ḥaml do not depend on the riwāya. |
| `second_nawa_is_the_riwayat` | Rulings of the ḥaml in itself are where the two riwāyāt differ. |
| `sahih_evident_grounds` | On the ṣaḥīḥ, an evident ḥaml grounds the ruling of either kind. |
| `no_amara_no_hukm` | Without the outward sign nothing attaches. |
| `haml_in_contract_is_part` | Link to qawāʿid 20–21: in a contract on the pregnant animal or slave, the ḥaml is treated as a part of its mother. |
| `inheritance_precedes_islam_bar` | Link to qāʿida 57: the ḥaml's inheritance at the father's death comes with the cause of the bar (Islam by that death), not the bar itself, so it stands. |

## 3. Qāʿida 86

| Definition / Theorem | Plain English |
| --- | --- |
| `MilkKind` | The four kinds: ʿayn with manfaʿa, ʿayn without manfaʿa, manfaʿa without ʿayn, bare intifāʿ (use). |
| `milkKind holdsAyn benefitByTamlik` | Holding the thing and owning the benefit gives the first kind; the thing alone the second; the benefit alone the third; neither, only a permitted use, the fourth. |
| `owns_manfaa_iff_tamlik` | One owns the benefit itself exactly when it came by a tamlīk. |
| `milkKind_injective` | The four kinds are really four. |
| `reserved_benefit_is_manfaa` | Link to qāʿida 32: a seller who reserves the benefit for a known period owns the manfaʿa without the ʿayn. |
| `buyer_holds_ayn_without_manfaa` | The buyer meanwhile holds the ʿayn without its manfaʿa. |

## In one line

An unborn child counts before birth once its sign shows (for others by agreement, for itself on the sounder report), and ownership comes in four kinds set by whether one holds the thing and whether the benefit was transferred to one.
