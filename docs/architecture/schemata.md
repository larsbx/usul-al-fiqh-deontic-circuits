# Schemata: the structure under al-Saʿdī's rules

On its own, a thin reading such as `confessionBinds _ := true` or `itlafLiable r _ := !r` says almost nothing. Its only content is a structural fact: it ignores an argument, falls back to a default, or absorbs later events. `Usul.Schema` (`formal/lean/Usul/Schema.lean`) makes those facts explicit. It states eight shapes once, over arbitrary types. Each shape comes with:

- **laws** that hold for every instance;
- a **transport** theorem: the shape survives a map between domains. This is what lets a rule stated in one bāb be applied in another (takhrīj, qiyās of rules, the M6 institutions) and keep its structure;
- **instance** theorems: the existing reading *is* that shape (`*_is_*`, `*_from_*`, `*_ignores_*`). The readings were not redefined, so every earlier theorem and catalogue link still stands.

## The eight shapes

| | Schema | Shape | Laws | Transport |
|---|---|---|---|---|
| S1 | `Factors H e`, `Ignores H` | the ruling depends only on a feature | `of_eq`, `post` (consequences inherit invariance), `refine`, `qiyas` | `pullback` along any `φ : α' → α` |
| S2 | `first`, `resolveD` | sources in priority order, the first defined one wins, else a default | `first_append` (monoid hom `(List, ++) → (Option, orElse)`), `first_conservative` (a lower source never overrides), `first_eq_none_iff`, `first_mem` | `first_map`, `resolveD_map` (naturality) |
| S3 | `Gate` algebra | conditions ∧ ¬impediments | `holds_top`, `holds_meet`, `meet_narrows`, `holds_ofBools` | `holds_comap`, `comap_meet` |
| S4 | `Closure step seed` | least set containing the seeds and closed under a step | `extensive`, `least`, `mono`, `idem` | `map` |
| S5 | `Inert step P e` | events that leave a state unchanged | `inert_fold` (any sequence of inert events) | — |
| S6 | `burdenOf presumption claim` | proof falls on whoever departs from the presumption | `burden_agrees`, `burden_departs`, `burden_factors` (roles are derived, not primitive), `burden_after_update` (with Q52) | through S1 |
| S7 | `Covers r`, `reps r` | one performance per merge class | `reps_covers` (needs only reflexivity), `reps_length_le`, `reps_sub` | `Covers.map` |
| S8 | `Optimal key xs b` | choose a best option on one scale | `best_optimal`, `best_eq_none_iff`, `Optimal.key_unique` (optimal options are equally good), `Optimal.restrict` (removing other options never unseats the choice) | `Optimal.mono` (monotone re-scaling; lighter harm is the antitone case), `Optimal.map` |

## Instances

The `schemata` field in `corpus/proposals/sadi_qawaid.json` records these tags. Each (rule, schema) pair is pinned by a typed `example` in `formal/lean/UsulTest/Schemata.lean`, and `test_schemata_tags_are_pinned` requires the tags and the pins to coincide.

| Schema | Rules | What the instance fixes |
|---|---|---|
| S1 invariance | Q10, 13, 14, 15, 36, 39, 47, 54, 58 | which argument is ignored: intent (13), harm received (15), the time of the condition (39), the source of an obligation (47), belief (54). Q36 adds that liability for destruction factors through *withRight*. Q14: loss liability factors through authorised holding. Q47 adds `q47_consequences`: every ruling computed from the status (making up, expiation) is the same for a vow as for the law. Q58's `DependsOn` *is* S1 at codomain `Hukm` |
| S2 priority | Q6, 9, 19, 20, 25, 28, 57; also taʿāruḍ `resolve` | the order of sources: dalīl ≻ domain default (6), law ≻ custom (9), stipulated ≻ value (19), owner ≻ public interest (20), known entitled ≻ division ≻ lots (25), original ≻ substitute (28), possible intent ≻ literal (57); jamʿ ≻ naskh ≻ tarjīḥ ≻ tawaqquf |
| S3 gate | Q4, 5, 8, 12, 17, 21, 29, 32, 40, 51, 58 | conditions and impediments. Q4: capability is a condition of obligation, necessity an impediment of prohibition. Q21: gharar is an impediment outside gifts. Q32: having paid as a gift is the impediment to recourse. Q40: per part, capability is the condition and being a pure means the impediment. Q17's hastening is an *impediment*, not a missing condition. Q29's qualifiers are conditions, so `meet_narrows` proves they only narrow. `Deal.gate` = Q12's gate read on deals (comap) ⊓ Q51's motive gate |
| S4 closure | Q2, 50, 53 | Q2: obligation under necessary means. Q50: established under "follows" (`q50_least`: nothing is established from nothing). Q53: void under "built on" (`q53_rescission_inert`: rescinding a contract that was not proved void leaves the closure unchanged) |
| S5 inert | Q11, 55 | doubts on a certain judgement (11); every plea after a confession (55, rights of persons) |
| S6 presumption | Q10, 26, 43, 52 | Q10: the presumption is barāʾat al-dhimma, so claimant and denier are *derived* roles. Q26/43: a trustee holding for the owner is presumed to have returned the thing, unless sense or custom belies him; holding for himself he is presumed not to have. Q52: a strong qarīna moves the burden |
| S7 merge | Q41 | the merge relation is same kind and same purpose, *any occasion*. It is an equivalence (`q41_merges_refl/symm/trans`) |
| S8 optimal | Q24, 33, 34, 37 | the scale: benefit and (negated) harm (33), earliest time (24), the interest of the one chosen for (34: admissible ⇔ optimal), strength of evidence (37) |

Rules tied to each other outside these shapes: Q42 is proved an instance of Q21; Q13 and Q14 share `liable ⇔ ¬authorized` (`q14_liable_iff_unauthorized`); Q45's `normalize` is an interior operator (coherent, fixes coherent requirements, idempotent). Q48 and Q39 are invariant under shifting the calendar.

## Governance: where the explanations live, and why there

A schema proves *structure*. Which coordinate a rule ignores, which source ranks first, what counts as an impediment: those are *interpretive commitments*. In this estate they belong to the Sharīʿah authority, not to this repository:

| Layer | Authority | Here |
|---|---|---|
| Structure (laws, transport, instance-of) | Lean holds proof authority | `Usul.Schema`, `UsulTest/Schemata.lean` |
| Bounded cross-checks | advisory oracle, never proof (`semantic-categorical-oracle/docs/authority-boundary.md`) | `Oracle.Usul.Schema`, `registry/laws.toml` spikes |
| Interpretive commitments | class C, `SHARIAH-AUTHORITY` gate (`halaqa/shared/STUB-CLASSIFICATION.md`) | surfaced as questions, with cited established answers and analogies; never adopted |
| Admission of any reading | human review (`Review.tla`, `deontic-circuits-harness.md`) | every record stays `candidate` |

So the explanations of *what each reading commits to* are not prose in this note. They are a register of review questions: [`corpus/review/sadi_interpretive_questions.json`](../../corpus/review/sadi_interpretive_questions.json), validated by `schemas/review_question.schema.json`. Each question records:

- the **rules** and the **schema** whose instance makes the commitment;
- the **pins**, the Lean constants that fail if the commitment changes. The test requires each pin to be linked in the catalogue, and therefore `#check`-ed;
- the **commitment**, the **alternatives** found in the tradition, and what changes formally **if changed**;
- **established** answers: the positions of the Ḥanbalī tradition the commitment should be weighed against, cited from the pinned corpus by record id (e.g. Ibn Rajab's qāʿida) or by source locator (al-Inṣāf, Iʿlām, Sharḥ al-Kawkab), each marked `agrees`, `refines`, `contradicts` or `bears-on`;
- **analogies**: *internal* ones from another of al-Saʿdī's rules sharing the schema (qiyās: the shared schema is the ʿilla, and a transported Lean law carries the structure), and *illustrative* ones from other legal traditions, which explain but never count as evidence;
- a suggested **route**: the halaqa `shared/usul-k/` file where an eventual ruling would live (`evidence-order`, `derogation`, `operators`, `specificity`, `resolution-schema`).

The register follows the halaqa rules for agents. It may classify, compare, identify uncertainty and surface questions (ICM-H §17). Citing an established answer is comparison, not adoption. It does not adopt or rank, and it does not write to `usul-k/`. Its existence does not satisfy the gate (§32). `test_interpretive_questions_are_grounded` keeps it honest: every question must name rules that actually carry the schema it cites, and every pin must be a linked constant. On the first run this test caught two errors, a wrong schema tag (Q32 is S3, not S2) and a pin that was never `#check`-ed.

When a question is answered under the gate, the reading changes, its pins fail, and the change is made deliberately: the reading, its pin and, if the shape changes, its tag.

## Dogfooding: the review runs on its own principles

Principles that are formalised and not themselves under question are applied to the review process (`formal/lean/Usul/Process.lean`, the `process` block of the register):

| Principle | Applied as | Check |
|---|---|---|
| Aḥmad's order of resort, taʿāruḍ order (S2) | status = `referenced` if an established answer is cited, else `analogized` if an internal analogy is offered, else `open` (tawaqquf). An analogy never outranks a cited text (`analogy_never_outranks_text`, `order_is_resort`) | `test_status_is_computed_from_evidence_on_file` |
| Q11, istiṣḥāb | a status is exactly what the evidence on file supports; nothing else moves it | same test |
| Q58, qiyās (S1) | an internal analogy is licensed only if aṣl and farʿ both carry the schema; a missing tag is manʿ, denial that the ʿilla is present (`Licensed`, `man`) | `test_internal_analogies_are_licensed` |
| Q8, gate (S3) | no status means "adopted" (`never_adopts`); adoption is the `SHARIAH-AUTHORITY` gate | schema: no such status |
| Q41, merging (S7) | two questions on the same rules and schema would merge into one | `test_questions_do_not_overlap` |

**Bootstrap deadlocks.** The review cannot use a principle whose reading is itself under live review. Otherwise the review waits on the question and the question waits on the review. `no_deadlock_of_stratified` proves the condition sufficient: if the rules the process uses are disjoint from the rules under live questions, nothing waits on anything. `no_cycle_of_rank` gives the general form: a rank that every wait lowers rules out any cycle through the wait relation's closure. The register declares `uses` (Q8, 11, 58) and `avoids` (Q33: IQ-10 is open on its tie-break, so choosing among cited answers "by the best" is not done).

Stratification is checked at the level of Lean constants, not rules. Q58 is both used by the process (analogies are qiyās) and under question (IQ-13 to IQ-16 ask about takhṣīṣ, plural ʿilal, kasr and the mursal). This is not a deadlock: the process `relies_on` only the undisputed core of qiyās (`Factors.qiyas`, `Licensed`, `man`, `Qiyas.man_defeats`), and the questions pin only the disputed parameters. Building this exposed a misnomer. The process's rejection of an analogy whose ʿilla is missing on one side had been called naqḍ, but it is manʿ, so it was renamed `man`. Naqḍ is exactly the disputed doctrine (takhṣīṣ), so the old name would have tied the process to a live question. `test_process_is_stratified` checks the disjointness on the data. Mutation-checked: making the process rely on `NaqdSucceedsBy` fails it.

So the principles are applied while building, except where applying them would make the process depend on its own unanswered questions.

