# HadithTest.Chains in Plain English

Source: [`formal/lean/HadithTest/Chains.lean`](../../../formal/lean/HadithTest/Chains.lean)

The first fixtures replay the project’s chain and route profiles. Further
checks exercise the criteria in Ibn Ḥajar’s *Nukhba*, *Nuzha* and *Taqrīb*.

## 1. Setup

- **`chain`**: grade a list of links under Ibn Ḥajar's default tadlīs policy.
- **`thiqa`**, **`sahabi`**: a connected, explicitly heard link from a reliable narrator and from a Companion.

## 2. Chain vectors (9 checks)

| Check | Plain English |
| --- | --- |
| thiqa, thiqa, ṣaḥābī ⇒ ṣaḥīḥ | The connected chain gets the profile’s strongest score. |
| one ṣadūq link ⇒ ḥasan | The weakest narrator determines the profile score in this fixture. |
| tier-2 "from" ⇒ ṣaḥīḥ | Ibn Ḥajar tolerates tier-2 concealment (tadlīs). |
| tier-3 "from" ⇒ ḍaʿīf | Tier 3 needs explicit hearing. |
| tier-3 explicit hearing ⇒ ṣaḥīḥ | Explicit hearing cures it. |
| tier-5 ḍaʿīf, explicit hearing ⇒ ḍaʿīf | Explicit hearing cures the tadlīs, not the narrator's own weakness. |
| broken link ⇒ ḍaʿīf | A gap caps the chain at weak. |
| matrūk link ⇒ ḍaʿīf jiddan | An abandoned narrator makes the chain severely weak. |
| kadhdhāb link ⇒ mawḍūʿ | The narrator rank forces that score under the profile. |

## 3. Route vectors (6 checks)

| Check | Plain English |
| --- | --- |
| two independent ḍaʿīf ⇒ ḥasan | Two weak routes lift to ḥasan li-ghayrihi. |
| ḥasan + ḍaʿīf ⇒ ṣaḥīḥ | Ḥasan plus support lifts to ṣaḥīḥ li-ghayrihi. |
| ḍaʿīf + ḍaʿīf jiddan + mawḍūʿ ⇒ ḍaʿīf | Severely weak routes neither lift nor support. |
| ʿilla attacks the lift ⇒ ḍaʿīf | A hidden defect (ʿilla) defeats the lift. |
| jawāb attacks the ʿilla ⇒ ḥasan | An answer (jawāb) reinstates it. |
| second unanswered ʿilla ⇒ ḍaʿīf | A fresh objection defeats it again. |

## 4. Source criteria

The same structural input can accompany different intrinsic grading
findings. The checks exercise full and lighter precision, unresolved
continuity, integrity, precision and hidden defects, and established
shudhūdh. They also check the sixth rank with and without qualifying
corroboration, the rank-9 distinction in jabr, and the evidence required
for tawātur. The intentions example replays the singular early route
reported by Ibn Ḥajar. [Classical criteria](../Hadith/ClassicalCriteria.md) · [Route multiplicity and jabr](../Hadith/Nukhba.md)
