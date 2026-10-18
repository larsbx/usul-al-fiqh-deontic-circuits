# Hadith.Turuq in Plain English

Source: [`formal/lean/Hadith/Turuq.lean`](../../../formal/lean/Hadith/Turuq.lean)

al-Albānī's rule that several weak routes (ṭuruq) strengthen each other is treated as a defeasible argument, not a sound inference. The lift stands only if it survives its objections in a formal argumentation framework. Its own guards are proven conservative: hopeless routes never help, one shared source never lifts, and a lift moves exactly one rung.

## 1. Routes and the lift rule

- **`Tariq`**: one route after its chain is graded: its verdict and its madār (the point where its weakness or common narrator sits). Different madār means independent routes.
- **`best`**: the strongest single route. With no routes, mawḍūʿ.
- **`supports`**: the distinct madārs among routes that are at least ḍaʿīf.
- **`Liftable`**: the best route is ḍaʿīf or ḥasan, and there are at least two independent supports.
- **`bump`**: one rung up. Ḍaʿīf ⇒ ḥasan li-ghayrihi (good through others). Ḥasan ⇒ ṣaḥīḥ li-ghayrihi.
- **`aggregate`**: bump the best route if the lift stands and is liftable; otherwise keep the best route.
- **`judge`**: the lift is argument 0 of a Dung-style framework. It stands ⟺ argument 0 is in the grounded extension.
- Objections attack the lift: hidden defect (ʿilla khafiyya), irregularity against a stronger narrator (shudhūdh), a hidden common source, a critic's explicit faulting. Answers (jawāb) attack objections.

## 2. Guards of the rule

| Theorem | Plain English |
| --- | --- |
| `bump_rank_le`, `le_bump` | A bump raises a verdict by at most one rung, never lowers it. |
| `best_le_aggregate` | Aggregation never goes below the best route. |
| `aggregate_rank_le` | Aggregation never climbs more than one rung. |
| `aggregate_of_shadid` | A severe (shadīd) best route is never lifted, whatever the count. |
| `not_liftable_of_one_madar` | Many routes through one weak narrator count as one: no lift. |
| `supports_cons_shadid`, `liftable_cons_shadid` | Adding a shadīd route changes neither the supports nor whether the rule applies. |

## 3. Defeasibility: worked cases

With two independent weak routes (`twoWeak`):

- No objection ⇒ ḥasan.
- An ʿilla attacks the lift ⇒ ḍaʿīf.
- A jawāb attacks the ʿilla ⇒ ḥasan again (reinstatement).

Two routes sharing one madār (`sameMadar`) stay ḍaʿīf. Two very weak routes stay ḍaʿīf jiddan.

- **`judge_not_monotone`**: there is a file where adding an objection lowers the verdict. The verdict is not monotone in the evidence, which is the shape of a scholar revising a grading (tarājuʿ).

## 4. Rulings that cap the verdict (decision D2)

- **`Ruling`**: a critic's judgement (`hukm`, e.g. "false, objectionable") or a criterion on the text (`matn`). It is an argument with a ceiling verdict.
- **`capWith`**: every surviving ruling caps the verdict at its ceiling.
- **`judgeR`**: `judge`, then apply the surviving rulings. The kind is kept so ruling-based cases are counted apart from rule-derived ones.

| Theorem | Plain English |
| --- | --- |
| `judgeR_nil` | With no rulings, `judgeR` is `judge`. |
| `capWith_le`, `judgeR_le` | A ruling only lowers; it never raises a verdict. |
| `capWith_le_ceiling` | A surviving ruling bounds the verdict by its ceiling. |

Worked: a forgery ruling caps two weak routes at mawḍūʿ. A jawāb that defeats it restores ḥasan.

## 5. Li-dhātihi vs li-ghayrihi

- **`Basis`**: whether a grade was reached by itself (`dhati`) or through others (`ghayri`).
- **`refinedRank`**: same verdict, but the lifted one ranks strictly lower, as the *Nuzha* says.

| Theorem | Plain English |
| --- | --- |
| `bump_ne_of_liftable` | When the rule applies, the bump really changes the verdict. |
| `ghayri_iff` | A verdict is li-ghayrihi ⟺ aggregation moved it off the best route. |
| `ghayri_below_dhati` | Lifted ḥasan ranks below ḥasan by itself. |
| `refinedRank_respects` | The refinement never reorders different verdicts. |

## 6. The qualified follower (decision D3)

The *Nuzha* requires the corroborating route to be "above it or like it, not below".

- **`Itibar`**: two readings. `lax`: any independent supporting route qualifies. `strict`: the base route must have an independent supporter whose worst narrator is no worse than its own.
- **`baseRoute`**: the route a lift builds on: best verdict, then best floor.
- **`mutabar`**: whether the file meets the follower condition under a reading.
- **`judgeI`**: `judge` with the follower condition added.

| Theorem | Plain English |
| --- | --- |
| `judgeI_lax` | The lax reading is exactly the original `judge`. |
| `aggregate_mono_flag` | Letting the lift stand never lowers the verdict. |
| `strict_le_lax` | The strict reading never lifts where the lax one does not. |

Worked: a ṣadūq-yahim route (floor 5) followed only by a majhūl route (floor 9) lifts under lax, not strict. Two majhūl routes lift under both.

## 7. D3 decided: strict

The uṣūl track's rule bank says a weaker challenger never displaces the incumbent (`Usul.Qawaid.update`). Read on the *Taqrīb* ladder, that is the strict reading.

| Theorem | Plain English |
| --- | --- |
| `bank_weaker_never_displaces` | In the bank, a weaker challenger leaves the incumbent in place. |
| `strict_weaker_follower_never_lifts` | Under strict, a weaker follower never qualifies the file. |
| `lax_weaker_follower_lifts` | Under lax, it does: the reading the bank rules out. |
| `bank_scale_blind_in_itibar` | Every rank from 5 to 9 grades as shakk, so the bank's coarse scale is neutral there, not support for lax. |

- **`Itibar.default`**: strict, the project default (2026-10-09).
- **`judgeRI`**, **`judgeRI_lax`**: rulings applied over the follower-aware judgement. Under lax it reduces to `judgeR`.

## In one line

Weak routes lift a ḥadīth one rung only as an argument that must survive objections and critics' rulings, with guards proving hopeless or non-independent routes never help, and the follower must be at least as good as the route it supports.
