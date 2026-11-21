# Hadith.Nukhba in Plain English

Source: [`formal/lean/Hadith/Nukhba.lean`](../../../formal/lean/Hadith/Nukhba.lean)

The module checks classifications from Ibn Ḥajar’s *Nukhbat al-Fikar* and
its commentary *Nuzhat al-Naẓar* on supplied evidence. It includes the
findings for tawātur and the identified weaknesses addressed by a qualifying
follower.

## 1. Route multiplicity and tawātur

`Turuq.tawatur` requires findings that the narrators are sufficiently
numerous to rule out ordinary agreement on falsehood, that this multiplicity
holds throughout, that the report rests on sensory perception, and that it
imparts knowledge to the hearer. `Turuq.routes k` records an āḥād assessment
with minimum multiplicity `k + 1` across the route levels. Counts of one,
two and at least three give gharīb, ʿazīz and mashhūr within that branch.
Ibn Ḥajar uses the intentions report to illustrate the singular early
transmission even though it spread more widely later. [*Nuzha*, v01:p041–p043 and v01:p048–p049](https://github.com/OpenITI/0875AH/blob/5835c183b8bbf4ea454d5c1be2b168b669403771/data/0852IbnHajarCasqalani/0852IbnHajarCasqalani.NuzhatNazar/0852IbnHajarCasqalani.NuzhatNazar.Shamela0001565-ara1)

The project’s `knowledge` projection uses the established tawātur findings
or the supplied āḥād verdict. Ibn Ḥajar’s preferred view also allows
inferential knowledge (ʿilm naẓarī) from some āḥād reports supported by
qarāʾin. That view concerns a separate assessment. [*Nuzha*, v01:p044–p045](https://github.com/OpenITI/0875AH/blob/5835c183b8bbf4ea454d5c1be2b168b669403771/data/0852IbnHajarCasqalani/0852IbnHajarCasqalani.NuzhatNazar/0852IbnHajarCasqalani.NuzhatNazar.Shamela0001565-ara1)

| Theorem | Plain English |
| --- | --- |
| `gharib_iff`, `aziz_iff`, `mashhur_iff` | The āḥād classes correspond to the respective minimum multiplicities in the input. |
| `mutawatir_iff`, `ahad_iff` | The class identifies the corresponding reviewed branch of `Turuq`. |
| `knowledge_qat_iff` | The project projection returns qaṭʿ precisely for a tawātur assessment backed by the four findings. |

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
- **`liftable`** tests the cited passage’s list. It names poor memory
  (including unseparated ikhtilāṭ), the mastūr, the mursal and tadlīs with an
  unidentified omitted narrator.
- **`jabr`** also needs a critical finding that a matching follower is at
  least as reliable as the narrator followed. [*Nuzha*, v01:p104–p105](https://github.com/OpenITI/0875AH/blob/5835c183b8bbf4ea454d5c1be2b168b669403771/data/0852IbnHajarCasqalani/0852IbnHajarCasqalani.NuzhatNazar/0852IbnHajarCasqalani.NuzhatNazar.Shamela0001565-ara1#L1104-L1118)
- **`Martaba.cause`**: the cause behind each weak *Taqrīb* rank, where its wording names one.

| Theorem | Plain English |
| --- | --- |
| `jabr_iff` | The cited criterion requires both a listed cause and a reviewed qualifying follower. |
| `not_liftable_of_adala` | The passage’s list excludes the modeled causes of criticism in uprightness. |
| `liftable_in_itibar` | Whenever the profile assigns a listed cause to a rank, that rank sits in the profile’s iʿtibār band. |
| `kadhib_tuhma_shadid` | Ranks caused by lying or accusation of lying are severe (shadīd). |
| `majhul_gap` | **Where the kernel goes wider.** Majhūl al-ʿayn (rank 9) is repairable in the kernel, but the *Nuzha* does not list it. |

Decision D1 keeps rank 9 in the project’s candidate support band. The
decision is an interpretation used to replay al-Albānī’s worked cases.
His *Tamām al-Minna*, Q10, describes repairable weakness such as poor
memory and excludes suspicion against honesty or religion. The *Nuzha*
passage names the mastūr. [Roadmap decisions](../../roadmap-albani-hadith-methodology.md#31-decisions)

## 5. Conflicting accepted reports (muʿāraḍa)

- **`muarada`**: the *Nukhba*'s order (reconcile, else abrogation, else preference, else suspend) is exactly the uṣūl kernel's `Usul.resolve`, reused, not restated.
- **`muarada_tawaqquf_iff`**: the result is suspension (tawaqquf) ⟺ no reconciliation (jamʿ), abrogation (naskh) or preference (tarjīḥ) is available.
