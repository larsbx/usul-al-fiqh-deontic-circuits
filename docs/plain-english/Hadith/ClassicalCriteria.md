# Hadith.ClassicalCriteria in Plain English

Source: [`formal/lean/Hadith/ClassicalCriteria.lean`](../../../formal/lean/Hadith/ClassicalCriteria.lean)

Ibn al-Ṣalāḥ’s conditions for ṣaḥīḥ require a continuous isnād, upright
transmitters with precision throughout the chain, and freedom from shudhūdh
and a disqualifying ʿilla. Ibn Ḥajar uses these criteria for ṣaḥīḥ li-dhātihi
among āḥād reports. Lighter precision, with the other conditions met,
characterizes ḥasan li-dhātihi. [Ibn al-Ṣalāḥ, type 1, pp. 12–14](https://islamweb.net/ar/library/content/90/3/) · [Ibn Ḥajar, *Nukhbat al-Fikar*, v04:p722](https://github.com/OpenITI/0875AH/blob/5835c183b8bbf4ea454d5c1be2b168b669403771/data/0852IbnHajarCasqalani/0852IbnHajarCasqalani.NukhbatFikar/0852IbnHajarCasqalani.NukhbatFikar.Shamela0005940-ara1#L89-L101)

| Input or theorem | Meaning |
| --- | --- |
| `RouteFindings` | The critical findings concern the particular report and route. The first three describe the whole chain. Findings about shudhūdh and ʿilla come from the review of the report. |
| `intrinsic_sahih_iff` | The checker returns ṣaḥīḥ li-dhātihi exactly when the āḥād scope and all five findings hold, with full precision. |
| `intrinsic_hasan_iff` | The checker returns ḥasan li-dhātihi exactly when the āḥād scope and all four common findings hold, with lighter precision. |
| `intrinsic_none_of_unreviewed_defect` | An unresolved finding on a disqualifying ʿilla leaves the intrinsic grade undetermined. The input distinguishes uncertainty from a finding against acceptance. |
| `sixth_rank_maqbul_iff`, `sixth_rank_layyin_iff` | Ibn Ḥajar’s sixth rank is maqbūl where the narration has a qualifying follower, and layyin where review has ruled that out. The checker leaves an unreviewed follower status unresolved. [*Taqrīb al-Tahdhīb*, v01:p074](https://github.com/OpenITI/0875AH/blob/5835c183b8bbf4ea454d5c1be2b168b669403771/data/0852IbnHajarCasqalani/0852IbnHajarCasqalani.TaqribTahdhib/0852IbnHajarCasqalani.TaqribTahdhib.JK000121-ara1.completed) |

These results check what follows from the supplied critical findings.
Sources and qualified review establish those findings for an actual report.
The [chain fixtures](../HadithTest/Chains.md) hold the profile score fixed while
varying the critical record.
