# Hadith.Grade in Plain English

Source: [`formal/lean/Hadith/Grade.lean`](../../../formal/lean/Hadith/Grade.lean)

The module represents Ibn Ḥajar’s twelve narrator ranks and the project’s
five-step scale for the al-Albānī profile. The bridge to uṣūl maps a supplied
verdict into the project’s epistemic scale.

## 1. Narrator ranks (marātib)

- **`Martaba`**: the twelve ranks of the *Taqrīb al-Tahdhīb*, best first. They run from Companion (ṣaḥābī), through thiqa (reliable) and ṣadūq (truthful), down to matrūk (abandoned), muttaham (accused of lying) and kadhdhāb (liar, forger).
- **`rank`**: the rung number, 1 (best) to 12 (worst).
- Rank 5 in the *Taqrīb* covers several different transmitter conditions.
  Rank 6 has a qualifying-follower condition reviewed for the narration in
  question. [Classical criteria](ClassicalCriteria.md)

| Theorem | Plain English |
| --- | --- |
| `Martaba.rank_injective` | Different ranks have different numbers. |
| `Martaba.rank_mem` | Every rank number lies between 1 and 12. |

## 2. Verdicts and their order

- **`Verdict`**: five values, worst first: mawḍūʿ (forged), ḍaʿīf jiddan (very weak), ḍaʿīf (weak), ḥasan (good), ṣaḥīḥ (sound).
- **Order**: verdicts compare by rank 0–4. The order is reflexive, transitive and antisymmetric.
- **`meet`**: the weaker of two verdicts (the weakest link in a chain).
- **`join`**: the stronger of two verdicts (the best route).
- **`Shadid`**: severe weakness that no number of routes repairs. It means mawḍūʿ or ḍaʿīf jiddan.
- **`Hujja`**: usable as proof (ḥujja), meaning ḥasan or better. al-Albānī uses weak ḥadīth neither in rulings nor in virtuous deeds.

| Theorem | Plain English |
| --- | --- |
| `meet_le_left`, `meet_le_right`, `le_meet` | `meet` is the greatest verdict below both inputs. |
| `meet_mono` | Improving either input never worsens the meet. |
| `meet_eq_or`, `join_eq_or` | Meet and join always return one of their two inputs. |

## 3. Bridge to the uṣūl kernel

- **`grade`**: ṣaḥīḥ and ḥasan give ẓann (preponderant belief). Ḍaʿīf gives shakk (doubt). The two worst give wahm (unlikely).
- This projection assigns no qaṭʿ from a `Verdict`. The
  [tawātur branch](Nukhba.md#1-route-multiplicity-and-tawātur) requires its own
  reviewed findings.

| Theorem | Plain English |
| --- | --- |
| `grade_mono` | A better verdict never gets a worse grade. |
| `hujja_iff_yaqin` | A verdict is ḥujja ⟺ its grade reaches the yaqīn (certainty) floor, i.e. ẓann or better. |
| `grade_ne_qat` | No single-chain verdict ever reaches qaṭʿ. |

## 4. From narrator to verdict

- In the project profile, `Martaba.verdict` maps ranks 1–3 to ṣaḥīḥ,
  rank 4 to ḥasan, ranks 5–9 to ḍaʿīf, ranks 10–11 to ḍaʿīf jiddan and
  rank 12 to mawḍūʿ.

| Theorem | Plain English |
| --- | --- |
| `Martaba.verdict_antitone` | A better rank never yields a worse verdict. |
| `Martaba.hujja_iff` | A narrator's verdict is ḥujja ⟺ rank ≤ 4. |
| `Martaba.shadid_iff` | A narrator's verdict is shadīd ⟺ rank ≥ 10. |

Ranks 5–9 form the profile’s iʿtibār band. Checking a qualifying corroboration
in a particular report requires additional findings. [The *Nuzha*’s jabr criterion](Nukhba.md#4-repair-jabr-by-a-corroborating-route)
