# Usul.Tahara in Plain English

Source: [`formal/lean/Usul/Tahara.lean`](../../../formal/lean/Usul/Tahara.lean)

The English word "semen" lumps together fluids that the fuqahāʾ (jurists) keep apart, and their rulings differ. So derivations here run on the Arabic names, each ruling resting on a graded text. The division is the one al-Saʿdī reports.

## 1. The four fluids

- **`Kharij`**: what exits from the front passage, by its Arabic name: al-bawl (urine), al-madhy (pre-seminal fluid), al-wadī (a thick fluid after urination), and al-manī (semen proper).
- **`Purification`**: the ṭahāra (ritual purity) it obliges: wuḍūʾ (ablution) or ghusl (full bath).
- **`Kharij.najis`**: every fluid is najis (ritually impure) except al-manī. The evidence is ʿĀʾisha's report of scraping manī from the Prophet's garment, after which he prayed in it.
- **`Kharij.obliges`**: al-manī obliges ghusl; the others oblige wuḍūʾ only.

The texts behind these rulings are ṣaḥīḥ in al-Albānī's grading (Abū Dāwūd, Muslim, al-Bukhārī; al-Māʾida 6). Al-wadī is ruled like al-madhy on the athar (report) of Ibn ʿAbbās only. Al-Albānī marks it mawqūf (stopping at a Companion), so the file records it as below a marfūʿ (Prophetic) text.

## 2. The theorems

| Theorem | Plain English |
| --- | --- |
| `semen_conflates` | Al-manī and al-madhy differ on both rulings: purity and the washing owed. One English word cannot carry both. |
| `madhy_wady_alike` | Al-madhy and al-wadī agree on both rulings. |
| `nass_admitted` | A ṣaḥīḥ ḥadīth offered as naṣṣ passes the ḥadīth gate (`Seam.admitted`). |
| `q15_f001_turns_on_the_name` | Ibn Rajab's case 15.f001 depends on the name: al-manī obliges ghusl, al-madhy is najis, and his qāʿida 15 does not carry that impurity over to the garment's own presumed purity. |

The last case: a man wakes to find wetness and does not bathe, taking it as madhy. Were it manī, the garment would be pure anyway. Taken as madhy it would be impure, but qāʿida 15 keeps the garment's presumption of purity.

## In one line

Al-manī is pure and obliges ghusl, while al-madhy, al-wadī and urine are impure and oblige wuḍūʾ, so no ruling can be derived from the English "semen".
