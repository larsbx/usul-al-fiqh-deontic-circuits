# Usul.Schema in Plain English

Source: [`formal/lean/Usul/Schema.lean`](../../../formal/lean/Usul/Schema.lean)

Most of al-Saʿdī's legal maxims (qawāʿid) are instances of eight general shapes. Each shape is stated once, with the laws every instance obeys and a transport theorem: the shape survives a translation between domains. So a rule read in one chapter (bāb) keeps its structure when applied in another, which is what takhrīj (deriving rulings by extending a principle) needs.

## 1. S1: a ruling that depends on one feature only

- **`Factors H e`**: the ruling `H` depends only on the feature `e`. Two cases equal on `e` get the same ruling.
- **`Ignores H`**: a two-argument ruling disregards its second argument, such as intent, belief, a claim of error, or harm received.

| Theorem | Plain English |
| --- | --- |
| `Factors.post` | Anything computed from the ruling inherits the same independence. |
| `Factors.pullback` | **Transport.** Reading another domain's cases through a map keeps the independence. |
| `Factors.refine` | A finer feature that determines `e` also suffices. |
| `Factors.qiyas` | Qiyās (analogy): a farʿ (new case) sharing the aṣl's (original case's) feature gets its ruling. |
| `dependsOn_iff_factors` | Al-Saʿdī's Q58 `DependsOn` is exactly this shape, for rulings. |
| `ignores_iff_factors` | Ignoring the second argument ⟺ depending only on the first. |

## 2. S2: priority of sources, first defined wins

- **`first`**: go down a priority-ordered list of sources and take the first that says something.
- **`resolveD`**: the same, with a default when every source is silent.

| Theorem | Plain English |
| --- | --- |
| `first_append` | Joining two lists of sources: the first list decides if it can, else the second. |
| `first_conservative` | Adding lower-priority sources never overturns a decision. |
| `first_eq_none_iff` | No decision ⟺ every source is silent. |
| `first_mem` | The decision always comes from some listed source. |
| `first_map` | **Transport.** Translating every source translates the decision. |
| `resolveD_head`, `resolveD_default`, `resolveD_map` | The first source decides if it speaks; silence gives the default; translation commutes with resolution. |
| `taarud_is_priority` | Taʿāruḍ (conflict) resolution is this shape: jamʿ, then naskh, then tarjīḥ, defaulting to tawaqquf. |
| `ruled_is_priority` | Al-Saʿdī's Q6 is this shape: the proof if there is one, else the domain's default. |

## 3. S3: gates of conditions and impediments

A gate (`Sadi.Gate`, al-Saʿdī's Q8) holds when all its conditions hold and no impediment does.

- **`top`**: the gate with nothing in it; it always holds.
- **`meet`**: join two gates, keeping both sets of conditions and both sets of impediments.
- **`comap`**: read a gate on another domain through a map.
- **`ofBools`**: build a gate from yes/no tests.

| Theorem | Plain English |
| --- | --- |
| `holds_top` | The empty gate always holds. |
| `holds_meet` | A joined gate holds ⟺ both gates hold. |
| `meet_narrows` | Adding conditions or impediments only narrows a rule (the shape of Q29's qualifiers). |
| `holds_comap` | **Transport.** A translated gate holds exactly where the original holds. |
| `comap_meet` | Translating then joining equals joining then translating. |
| `holds_ofBools` | A yes/no gate holds ⟺ every condition is true and no impediment is. |

## 4. S4: closure from seeds

- **`Closure step seed`**: the least set that contains the seeds and is closed under a step.

| Theorem | Plain English |
| --- | --- |
| `Closure.extensive` | The seeds are in the closure. |
| `Closure.least` | Any set holding the seeds and closed under the step contains the closure. |
| `Closure.mono` | More seeds or more steps give a bigger closure. |
| `Closure.idem` | Closing twice changes nothing. |
| `Closure.map` | **Transport.** A map preserving seeds and steps carries the closure along. |
| `wajib_is_closure` | Q2, "what the obligatory cannot be done without is itself obligatory", is this shape: obligation spreads through necessary means. |

## 5. S5: inert events

- **`Inert`**: an event leaves every state of a given kind unchanged.

| Theorem | Plain English |
| --- | --- |
| `inert_fold` | A run of inert events leaves the state as it was, however long the run. |
| `yaqin_doubts_inert` | Q11, "certainty is not removed by doubt": on a certain judgement, any number of doubts change nothing. |

## 6. S6: burden of proof

- **`Proof`**: bayyina (evidence) or yamīn (oath).
- **`burdenOf`**: a claim that agrees with the operative presumption is taken with an oath; a claim that departs from it needs evidence.

| Theorem | Plain English |
| --- | --- |
| `burden_agrees`, `burden_departs` | Agreeing claim → oath; departing claim → evidence. |
| `burden_factors` | The burden depends only on whether the claim agrees with the presumption, not on who makes it. Roles like claimant or trustee are derived, not basic. |
| `burden_after_update` | With Q52: an indication strong enough to displace the presumption also moves the burden. |

## 7. S7: one performance per merge class

- **`Covers`**: what was done discharges what was owed: each owed act merges into some act performed.
- **`reps`**: keep an act only if no kept act already discharges it.

| Theorem | Plain English |
| --- | --- |
| `reps_covers` | For a reflexive merge relation, the kept acts discharge everything owed. |
| `reps_length_le` | Merging never increases the number of acts. |
| `reps_sub` | Every kept act was among those owed. |
| `Covers.map` | **Transport.** A map that preserves merging preserves discharge. |

## 8. S8: choosing the best on one scale

- **`Optimal`**: an option is available and no option scores higher.

| Theorem | Plain English |
| --- | --- |
| `best_optimal` | Q33's `best` always returns an optimal option. |
| `best_eq_none_iff` | No choice ⟺ no options. |
| `Optimal.key_unique` | All optimal options score the same: the scale carries the ruling, not the tie-break. |
| `Optimal.restrict` | Removing other options never unseats the chosen one. |
| `Optimal.mono` | **Transport.** Any order-preserving rescaling keeps the optimum (lighter harm is the reversed case). |
| `Optimal.map` | **Transport.** Renaming the options carries the optimum. |

## 9. Kernel rules as instances

| Theorem | Plain English |
| --- | --- |
| `operative_is_gate` | Q4 is two gates: ability is a condition of obligation; necessity is an impediment to prohibition. |
| `substitute_is_priority` | Q28 is a priority list: the original when possible, else the substitute. |
| `obligedParts_is_gate` | Q40 is a gate per part: a part is owed if one can do it and it is not a mere means (wasīla maḥḍa). |
| `q33_is_optimal` | Q33 picks the greatest benefit and, reversed, the least harm. |

Further instances are proved in `Usul.Muamalat` and `Usul.Kulliyyat`. The interpretive choice each one makes is logged for review in `corpus/review/sadi_interpretive_questions.json`.

## In one line

Al-Saʿdī's maxims reduce to eight shapes (invariance, priority, gates, closure, inert events, burden, merging, optimisation), each with laws and a guarantee that the shape carries over when a rule moves to another domain.
