# UsulTest.Schemata in Plain English

Source: [`formal/lean/UsulTest/Schemata.lean`](../../../formal/lean/UsulTest/Schemata.lean)

Each of al-Saʿdī's qawāʿid (legal maxims) that the corpus tags with a shared shape really has that shape in Lean. There are eight shapes, S1–S8, defined in `Usul.Schema`. This suite pins 42 tags with 41 typed `example`s, so the build breaks the moment a reading drifts away from its schema.

## 1. How the pinning works

- **Tag**: a comment line `-- @schema Q<n> <schema>`, mirroring a tag in `corpus/proposals/sadi_qawaid.json`.
- **Pin**: the `example` right under the tag. It states the schema's defining property of that qāʿida's reading and proves it, usually by citing a named theorem.
- **Two checks**: Lean fails if a pinned property no longer holds. A Python test (`test_schemata_tags_are_pinned`) fails if a JSON tag and a Lean tag disagree.
- **Why it matters**: the schemata claim that dozens of maxims are a few patterns. The pins make that claim checked, not asserted.

## 2. The eight schemata and their pins

| Schema | Meaning | Pinned maxims |
| --- | --- | --- |
| S1 invariance (`Factors` / `Ignores`) | The ruling depends only on one feature and ignores another. | Q10, Q13, Q14, Q15, Q36, Q39, Q47, Q54, Q58 (9) |
| S2 priority (`resolveD`) | Sources are tried in order; the first that speaks decides, else a default. | Q6, Q9, Q19, Q20, Q25, Q28, Q57, Q58 (8) |
| S3 gate (`Gate`) | A ruling holds ⟺ all conditions hold ∧ no impediment is present. | Q4, Q5, Q8, Q12, Q17, Q21, Q29, Q32, Q40, Q51, Q58 (11) |
| S4 closure (`Closure`) | The least set that contains the seeds and is closed under a step. | Q2, Q50, Q53 (3) |
| S5 inert | Some events leave a state exactly as it was. | Q11, Q55 (2) |
| S6 presumption (`burdenOf`) | Proof falls on whoever departs from the presumption. | Q10, Q26, Q43, Q52 (4) |
| S7 merge (`Covers` / `reps`) | One performance per class of acts that merge. | Q41 (1) |
| S8 optimal (`Optimal`) | Choose a best option on a single scale. | Q24, Q33, Q34, Q37 (4) |

## 3. Representative pins

| Pin | Plain English |
| --- | --- |
| Q2 `wajib_is_closure` | *Mā lā yatimm al-wājib illā bihi* (what the obligation needs is itself obligatory): wājib acts are the closure of the base duties under "needs". |
| Q5 `q05_both_foundations` | Worship passes its gate ⟺ it is sincere ∧ it follows the Sunna. |
| Q6 `ruled_is_priority` | A domain's ruling is the dalīl (evidence) if there is one, else the domain's default presumption. |
| Q8 `holds_comap`, `holds_meet` | Gates combine: pulling back a joined gate holds ⟺ both gates hold on the pulled-back case. |
| Q11 `yaqin_doubts_inert` | Once a judgement is certain (yaqīn), any number of doubts (shakk) leave it unchanged. |
| Q13 `q13_ignores_intent` | Liability for destroying property (itlāf) ignores intent. |
| Q24 `q24_is_optimal` | The first claimant, the one with the earliest time, is optimal on the scale "earliest wins". |
| Q26/Q43 `q26_q43_from_presumption` | A return claim is accepted ⟺ the claimant needs only an oath (yamīn) under the return presumption. |
| Q41 `q41_representatives` | The chosen representatives cover every owed act under the merge relation. |
| Q51 (by `deal_holds_iff`) | A deal with an unlawful motive never passes the deal gate. |
| Q55 `q55_confession_absorbs` | A confession anywhere in a sequence of pleas fixes the outcome as bound. |
| Q58 `qiyas_sound` | A qiyās (analogy) that passes its gate, with a ruling that depends only on the ʿilla (operative cause), gives the right ruling for the new case. |
| Q58 `farByOrder` | The new case is ruled by text first, then ʿilla-analogy, then resemblance (shabah) only if allowed, then the default. |

Q58 carries three schemata: S1 (dependence), S3 (the qiyās gate) and S2 (the order of sources).

## In one line

Forty-two tags say which of eight patterns each Saʿdī maxim follows, and forty-one compiled proofs keep every tag true.
