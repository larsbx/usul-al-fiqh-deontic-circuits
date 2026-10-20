# Hadith.Nukhba in Plain English

Source: [`formal/lean/Hadith/Nukhba.lean`](../../../formal/lean/Hadith/Nukhba.lean)

Ibn Ḥajar's *Nukhbat al-Fikar*, with its commentary *Nuzhat al-Naẓar*, classifies ḥadīth by nested divisions (taqāsīm). Each division here is a total function, so every ḥadīth falls into exactly one class by construction. The proofs show each class matches the text's own definition, and compare the text's list of repairable weaknesses with the kernel's.

## 1. Number of routes (ṭuruq)

- **`Turuq`**: either unbounded routes, or exactly k + 1 counted routes.
- **`kathra`**: the classification by number. Unbounded ⇒ mutawātir (mass-transmitted). One route ⇒ gharīb (singular). Two ⇒ ʿazīz (rare). Three or more ⇒ mashhūr (well known).
- **`Ahad`**: everything except mutawātir is āḥād (solitary report).
- **`knowledge`**: what a report yields. Mutawātir gives qaṭʿ (certainty). Āḥād give only the grade of their verdict.
- The *Nukhba* also allows certain knowledge from āḥād backed by qarāʾin. That upgrade is disputed and not encoded.

| Theorem | Plain English |
| --- | --- |
| `gharib_iff`, `aziz_iff`, `mashhur_iff`, `mutawatir_iff` | Each class is exactly its defining count. |
| `ahad_iff` | Āḥād ⟺ the routes are a finite count. |
| `knowledge_qat_iff` | A report yields qaṭʿ ⟺ it is mutawātir. |

## 2. Dropped narrators (saqṭ)

- **`Saqt`**: where narrators were dropped (`Place`: compiler's end, final end after the Successor, or middle), how many, and whether consecutive.
- **`name`**: compiler's end ⇒ muʿallaq (suspended). Final end ⇒ mursal. Middle, two or more consecutive ⇒ muʿḍal. Otherwise munqaṭiʿ (broken).
- **`visibility`**: a hidden drop from someone the narrator met is tadlīs (mudallas). From a contemporary he never met, irsāl khafī. Otherwise the gap shows from the dates.

| Theorem | Plain English |
| --- | --- |
| `muadal_iff` | Muʿḍal ⟺ middle drop of at least two consecutive narrators. |
| `mudallas_iff` | Mudallas ⟺ the narrator met the one he dropped. |

## 3. Ten causes of criticism (ṭaʿn)

- **`Taan`**: ten causes, most severe first: lying, accusation of lying, gross error, heedlessness, open sin (fisq), mistakes (wahm), contradicting stronger narrators, being unknown (jahāla), heresy (bidʿa), poor memory.
- **`severity`**: the position 1–10 in this order.
- **`adala`**: five causes concern uprightness (ʿadāla). The other five concern accuracy (ḍabṭ).

| Theorem | Plain English |
| --- | --- |
| `all_complete` | The list contains every cause. |
| `severity_injective`, `severity_is_order` | Severities are distinct and run 1 to 10 in list order. |
| `five_and_five` | Exactly five uprightness causes and five accuracy causes. |

## 4. Repair (jabr) by a corroborating route

- **`Cause`**: a ṭaʿn, the mastūr (status unknown), a named gap, or tadlīs with the dropped narrator unknown.
- **`liftable`**: the *Nuzha* names exactly four repairable causes: poor memory, the mastūr, the mursal, and the mudallas. Nothing else.
- **`Martaba.cause`**: the cause behind each weak *Taqrīb* rank, where its wording names one.

| Theorem | Plain English |
| --- | --- |
| `not_liftable_of_adala` | No uprightness defect is ever repaired. |
| `liftable_in_itibar` | Every rank whose cause the text repairs sits in the kernel's repairable band. The kernel agrees with the text there. |
| `kadhib_tuhma_shadid` | Ranks caused by lying or accusation of lying are severe (shadīd). |
| `majhul_gap` | **Where the kernel goes wider.** Majhūl al-ʿayn (rank 9) is repairable in the kernel, but the *Nuzha* does not list it. |

The project owner kept rank 9 repairable (decision D1, 2026-10-09), following *Tamām al-Minna*. That text withholds repair only for accusations against honesty or religion, and unknown status is not that. `majhul_gap` stays as the record of the divergence.

## 5. Conflicting accepted reports (muʿāraḍa)

- **`muarada`**: the *Nukhba*'s order (reconcile, else abrogation, else preference, else suspend) is exactly the uṣūl kernel's `Usul.resolve`, reused, not restated.
- **`muarada_tawaqquf_iff`**: the result is suspension (tawaqquf) ⟺ no reconciliation (jamʿ), abrogation (naskh) or preference (tarjīḥ) is available.

## In one line

Ibn Ḥajar's classifications become total functions with exact characterisations, and the comparison with the kernel shows it agrees with the text everywhere except one recorded, deliberate widening: majhūl narrators remain repairable.
