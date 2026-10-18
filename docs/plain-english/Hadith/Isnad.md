# Hadith.Isnad in Plain English

Source: [`formal/lean/Hadith/Isnad.lean`](../../../formal/lean/Hadith/Isnad.lean)

A chain of narrators (isnād) is only as strong as its weakest link. A gap or an unaccepted concealment caps a link at weak, and a single liar anywhere makes the whole chain forged.

## 1. Tadlīs and policy

- **Tadlīs**: a narrator concealing a gap, by saying "from" (ʿan) someone instead of "he told us".
- **`Tier`**: Ibn Ḥajar's five tiers of mudallis (concealing) narrators, from *Taʿrīf Ahl al-Taqdīs*.
- **`Sigha`**: the wording of transmission. `tasrih` is explicit hearing (ḥaddathanā, samiʿtu); `anana` is the ambiguous "from".
- **`Policy`**: which tiers' ambiguous "from" is accepted. Scholars disagree over tier 3, so this is a parameter.
- **`Policy.ibnHajar`**: the default. Only tiers 1–2 are tolerated.
- **`Policy.Le p q`**: p is at most as tolerant as q.
- **`acceptsTadlis`**: no tadlīs, or explicit hearing, is always accepted. Ambiguous "from" by a mudallis is accepted only if the policy tolerates his tier.

## 2. Links and chains

- **`Link`**: one narrator's rank, whether the link is connected (muttaṣil), his tadlīs tier if any, and the wording used.
- **`Link.verdict`**: the narrator's verdict if the link is connected and accepted; otherwise capped at ḍaʿīf.
- **`Isnad`**: a list of links.
- **`Isnad.verdict`**: the meet (weakest) of all link verdicts. The empty chain counts as ṣaḥīḥ.
- Hidden defects (ʿilla, shudhūdh) are not decided here. They enter as objections in `Hadith.Turuq`.

## 3. The theorems

| Theorem | Plain English |
| --- | --- |
| `tasrih_cures_tadlis` | Explicit hearing always cures tadlīs. |
| `acceptsTadlis_mono` | A more tolerant policy accepts everything a stricter one does. |
| `Link.verdict_le_rawi` | A link is never stronger than its narrator. |
| `Link.verdict_le_daif_of_defect` | A gap or unaccepted tadlīs leaves the link at most ḍaʿīf. |
| `Link.verdict_mono` | A more tolerant policy never weakens a link. |
| `Isnad.verdict_le_link` | The chain is no stronger than any of its links. |
| `Isnad.verdict_attained` | The chain's verdict equals one of its links (or ṣaḥīḥ if empty). It is the weakest link. |
| `Isnad.verdict_mono_policy` | A more tolerant policy never weakens a chain. |
| `Isnad.verdict_mono_links` | Improving any link, position by position, never weakens the chain. |
| `Isnad.mawdu_of_kadhdhab` | One kadhdhāb (liar) anywhere makes the chain mawḍūʿ. |
| `Isnad.not_hujja_of_gap` | A break (inqiṭāʿ) anywhere keeps the chain below ḥujja. |

## 4. The chain's floor

- **`Isnad.floor`**: the worst narrator rank in the chain, on the 1–12 scale. A gap or unaccepted tadlīs hides an unknown narrator, counted as majhūl (rank 9). `Hadith.Turuq` uses it to test whether a follower is good enough.

## In one line

Chain verdict = weakest link, where gaps and unaccepted tadlīs cap a link at ḍaʿīf, one liar makes it forged, and a laxer tadlīs policy can only help.
