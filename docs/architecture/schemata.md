# Schemata: the structure under al-Saʿdī's rules

On its own, a thin reading such as `confessionBinds _ := true` or `itlafLiable r _ := !r` says almost nothing. Its only content is a structural fact: it ignores an argument, falls back to a default, or absorbs later events. `Usul.Schema` (`formal/lean/Usul/Schema.lean`) makes those facts explicit. It states seven shapes once, over arbitrary types. Each shape comes with:

- **laws** that hold for every instance;
- a **transport** theorem: the shape survives a map between domains. This is what lets a rule stated in one bāb be applied in another (takhrīj, qiyās of rules, the M6 institutions) and keep its structure;
- **instance** theorems: the existing reading *is* that shape (`*_is_*`, `*_from_*`, `*_ignores_*`). The readings were not redefined, so every earlier theorem and catalogue link still stands.

## The seven shapes

| | Schema | Shape | Laws | Transport |
|---|---|---|---|---|
| S1 | `Factors H e`, `Ignores H` | the ruling depends only on a feature | `of_eq`, `post` (consequences inherit invariance), `refine`, `qiyas` | `pullback` along any `φ : α' → α` |
| S2 | `first`, `resolveD` | sources in priority order, the first defined one wins, else a default | `first_append` (monoid hom `(List, ++) → (Option, orElse)`), `first_conservative` (a lower source never overrides), `first_eq_none_iff`, `first_mem` | `first_map`, `resolveD_map` (naturality) |
| S3 | `Gate` algebra | conditions ∧ ¬impediments | `holds_top`, `holds_meet`, `meet_narrows`, `holds_ofBools` | `holds_comap`, `comap_meet` |
| S4 | `Closure step seed` | least set containing the seeds and closed under a step | `extensive`, `least`, `mono`, `idem` | `map` |
| S5 | `Inert step P e` | events that leave a state unchanged | `inert_fold` (any sequence of inert events) | — |
| S6 | `burdenOf presumption claim` | proof falls on whoever departs from the presumption | `burden_agrees`, `burden_departs`, `burden_factors` (roles are derived, not primitive), `burden_after_update` (with Q52) | through S1 |
| S7 | `Covers r`, `reps r` | one performance per merge class | `reps_covers` (needs only reflexivity), `reps_length_le`, `reps_sub` | `Covers.map` |

## Instances

The `schemata` field in `corpus/proposals/sadi_qawaid.json` records these tags. Each (rule, schema) pair is pinned by a typed `example` in `formal/lean/UsulTest/Schemata.lean`, and `test_schemata_tags_are_pinned` requires the tags and the pins to coincide.

| Schema | Rules | What the instance fixes |
|---|---|---|
| S1 invariance | Q10, 13, 15, 36, 39, 47, 54, 58 | which argument is ignored: intent (13), harm received (15), the time of the condition (39), the source of an obligation (47), belief (54). Q36 adds that liability for destruction factors through *withRight*. Q47 adds `q47_consequences`: every ruling computed from the status (making up, expiation) is the same for a vow as for the law. Q58's `DependsOn` *is* S1 at codomain `Hukm` |
| S2 priority | Q6, 9, 19, 20, 57; also taʿāruḍ `resolve` | the order of sources: dalīl ≻ domain default (6), law ≻ custom (9), stipulated ≻ value (19), owner ≻ public interest (20), possible intent ≻ literal (57); jamʿ ≻ naskh ≻ tarjīḥ ≻ tawaqquf |
| S3 gate | Q5, 8, 12, 17, 29, 51 | conditions and impediments. Q17's hastening is an *impediment*, not a missing condition. Q29's qualifiers are conditions, so `meet_narrows` proves they only narrow. `Deal.gate` = Q12's gate read on deals (comap) ⊓ Q51's motive gate |
| S4 closure | Q2, 50, 53 | Q2: obligation under necessary means. Q50: established under "follows" (`q50_least`: nothing is established from nothing). Q53: void under "built on" (`q53_rescission_inert`: rescinding a contract that was not proved void leaves the closure unchanged) |
| S5 inert | Q11, 55 | doubts on a certain judgement (11); every plea after a confession (55, rights of persons) |
| S6 presumption | Q10, 26, 43, 52 | Q10: the presumption is barāʾat al-dhimma, so claimant and denier are *derived* roles. Q26/43: a trustee holding for the owner is presumed to have returned the thing, unless sense or custom belies him; holding for himself he is presumed not to have. Q52: a strong qarīna moves the burden |
| S7 merge | Q41 | the merge relation is same kind and same purpose, *any occasion*. It is an equivalence (`q41_merges_refl/symm/trans`) |

Rules already tied to each other outside these seven shapes: Q24, Q34 and Q37 reuse Q33's `best` (optimisation); Q42 is proved an instance of Q21; Q13 and Q14 share `liable ⇔ ¬authorized` (`q14_liable_iff_unauthorized`); Q45's `normalize` is an interior operator (coherent, fixes coherent requirements, idempotent). Q48 and Q39 are invariant under shifting the calendar.

## What review must judge

The schemata make interpretive commitments visible. They do not settle them:

- **S6, Q10:** taking barāʾat al-dhimma as *the* presumption is a reading of «البينة على المدعي». The same schema with a different presumption, such as the apparent state (ẓāhir), gives different roles.
- **S6, Q26/43:** `returnPresumption` assumes that being belied by sense or custom displaces the presumption entirely, rather than only weakening it.
- **S5, Q55:** the plea model is for the rights of persons. In the ḥudūd, retracting a confession is accepted, so a different `plead` is needed there, with `retract` *not* inert.
- **S7, Q41:** "one purpose" is modelled as equality of a purpose label. Whether two ghusls with different intentions share a purpose is a fiqh question, encoded by the choice of label.
- **S1 instances whose proof is `rfl`** are not trivial claims. The content lies in *which* coordinate the reading declares irrelevant. A reviewer who thinks intent does matter for Q13 must change the reading, and the pin in `UsulTest/Schemata.lean` will then fail.
