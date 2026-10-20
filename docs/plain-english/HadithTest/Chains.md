# HadithTest.Chains in Plain English

Source: [`formal/lean/HadithTest/Chains.lean`](../../../formal/lean/HadithTest/Chains.lean)

Fifteen hand-built test vectors pin the chain (isnād) and route (ṭuruq) rules to their textual sources. Each names the rule it guards. None is a transcribed al-Albānī entry; real entries live as data elsewhere.

## 1. Setup

- **`chain`**: grade a list of links under Ibn Ḥajar's default tadlīs policy.
- **`thiqa`**, **`sahabi`**: a connected, explicitly heard link from a reliable narrator and from a Companion.

## 2. Chain vectors (9 checks)

| Check | Plain English |
| --- | --- |
| thiqa, thiqa, ṣaḥābī ⇒ ṣaḥīḥ | Upright, accurate and connected at every link gives sound (the *Nuzha*'s definition). |
| one ṣadūq link ⇒ ḥasan | A single merely truthful narrator gives ḥasan li-dhātihi. |
| tier-2 "from" ⇒ ṣaḥīḥ | Ibn Ḥajar tolerates tier-2 concealment (tadlīs). |
| tier-3 "from" ⇒ ḍaʿīf | Tier 3 needs explicit hearing. |
| tier-3 explicit hearing ⇒ ṣaḥīḥ | Explicit hearing cures it. |
| tier-5 ḍaʿīf, explicit hearing ⇒ ḍaʿīf | Explicit hearing cures the tadlīs, not the narrator's own weakness. |
| broken link ⇒ ḍaʿīf | A gap caps the chain at weak. |
| matrūk link ⇒ ḍaʿīf jiddan | An abandoned narrator makes the chain severely weak. |
| kadhdhāb link ⇒ mawḍūʿ | A liar makes it forged. |

## 3. Route vectors (6 checks)

| Check | Plain English |
| --- | --- |
| two independent ḍaʿīf ⇒ ḥasan | Two weak routes lift to ḥasan li-ghayrihi. |
| ḥasan + ḍaʿīf ⇒ ṣaḥīḥ | Ḥasan plus support lifts to ṣaḥīḥ li-ghayrihi. |
| ḍaʿīf + ḍaʿīf jiddan + mawḍūʿ ⇒ ḍaʿīf | Severely weak routes neither lift nor support. |
| ʿilla attacks the lift ⇒ ḍaʿīf | A hidden defect (ʿilla) defeats the lift. |
| jawāb attacks the ʿilla ⇒ ḥasan | An answer (jawāb) reinstates it. |
| second unanswered ʿilla ⇒ ḍaʿīf | A fresh objection defeats it again. |

## Why it matters

These vectors fix the kernel's behaviour on textbook cases. Any change to the chain or route rules that alters a textbook outcome breaks the build.

## In one line

Fifteen small cases check that chains grade as the weakest link and that weak routes lift one rung only while their objections stay answered.
