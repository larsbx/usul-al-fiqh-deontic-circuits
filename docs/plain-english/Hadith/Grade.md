# Hadith.Grade in Plain English

Source: [`formal/lean/Hadith/Grade.lean`](../../../formal/lean/Hadith/Grade.lean)

Narrators sit on Ibn Ḥajar's twelve-rung ladder, and ḥadīth verdicts on a five-step scale from forged to sound. A better narrator never yields a worse verdict, and every verdict maps into the uṣūl kernel's scale of certainty, so a ḥadīth enters legal reasoning only as a grade of confidence.

## 1. Narrator ranks (marātib)

- **`Martaba`**: the twelve ranks of the *Taqrīb al-Tahdhīb*, best first. They run from Companion (ṣaḥābī), through thiqa (reliable) and ṣadūq (truthful), down to matrūk (abandoned), muttaham (accused of lying) and kadhdhāb (liar, forger).
- **`rank`**: the rung number, 1 (best) to 12 (worst).
- The *Taqrīb* is al-Albānī's default valuation. Individual overrides are data elsewhere, not changes to this ladder.

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
- qaṭʿ (certainty) is reserved for tawātur (mass transmission). That is a property of many chains, never of one.

| Theorem | Plain English |
| --- | --- |
| `grade_mono` | A better verdict never gets a worse grade. |
| `hujja_iff_yaqin` | A verdict is ḥujja ⟺ its grade reaches the yaqīn (certainty) floor, i.e. ẓann or better. |
| `grade_ne_qat` | No single-chain verdict ever reaches qaṭʿ. |

## 4. From narrator to verdict

- **`Martaba.verdict`**: ranks 1–3 give ṣaḥīḥ, rank 4 ḥasan, ranks 5–9 ḍaʿīf, ranks 10–11 ḍaʿīf jiddan, rank 12 mawḍūʿ.

| Theorem | Plain English |
| --- | --- |
| `Martaba.verdict_antitone` | A better rank never yields a worse verdict. |
| `Martaba.hujja_iff` | A narrator's verdict is ḥujja ⟺ rank ≤ 4. |
| `Martaba.shadid_iff` | A narrator's verdict is shadīd ⟺ rank ≥ 10. |

Ranks 5–9 form the middle band, the iʿtibār (corroboration) band: weak but repairable.

## In one line

Twelve narrator ranks map monotonically onto five verdicts, split into usable (1–4), repairable (5–9) and hopeless (10–12), and every verdict reaches legal reasoning only as ẓann, shakk or wahm, never certainty.
