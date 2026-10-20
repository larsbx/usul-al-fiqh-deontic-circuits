# Field anchors: every fact defined by its source's words (PR-48)

A typed situation settles facts named by the fields of the qāʿida types (`Usul.Typing.Qaida`). The names are the bank's; their meanings must be the sources'. Each declared field now carries a gloss and an **anchor**: the phrase of its own qāʿida (statement or body) that states the fact, copied verbatim and located in the pinned witness. A field no phrase states is recorded `unanchored`, with the reason.

- Module: `pipeline/usul_corpus/anchors.py`.
- Data: `corpus/types/anchors/<shard>.json`, keyed `type.field`.
- Gate: `pipeline/tests/test_anchors.py`.
  - Every declared field is covered.
  - Every excerpt passes `source_verify.check_quote`: it is at its declared closing page, in whole words, keeps a negation just before it, and does not stop before a qualifier.
  - For al-Saʿdī's unpaged witness (`#qNNN`), the excerpt occurs exactly once.
- The typist's catalogue (`typed_routing.catalogue`) carries each field's gloss and its defining phrase.

## Coverage

| | Fields |
|---|---|
| Declared (365, in 170 types) | 365 |
| Anchored verbatim | **351**: Ibn Rajab 319, al-Saʿdī 19, Ibn al-Laḥḥām 13 |
| Unanchored, with the reason | **14** |

Six parallel shards wrote the fragments, one per group of types; each ran the gate before handing back. All entries are `candidate`.

## Facts the bank reads that its source does not state (the 14)

These are findings, not gaps in the anchoring. In each case the reading introduced the fact.

- **Selectors over reported positions** (Ibn al-Laḥḥām 43): `intended_reading`, `nonverbal_reading`, `obligation_reading`, `prophetic_act_reading`. The text reports the positions; which one holds is the reading's input, not a fact of the case.
- **Taken from a later work, introduced by a refinement:**
  - `rajab10.need_not_learn`: al-Kashshāf's ground; the qāʿida leaves the case at two wujūh.
  - `rajab50.solvent`: al-Inṣāf's and al-Iqnāʿ's condition; the qāʿida names none.
- **The reading's generalisation:**
  - `rajab85.rival_in_dhimma_only`: the same qāʿida ties the creditors' right to the estate after death, so this may conflict with the text.
  - `rajab101.common_unit`: the furūʿ it generalises rest on different grounds.
  - `rajab111.proof_establishes_cause`: the text leaves it «على روايتين».
- **A complement case the text never states:**
  - `rajab108.known_simultaneous`: the qāʿida speaks only of an unknown order.
  - `rajab131.has_wealth` and `rajab132.has_wealth_q132`: the qawāʿid speak only of the capacity to earn.
- **A default, or a construction from a source the type does not cite:**
  - `sadi30.consents`: both sources speak of compelling the refuser; consent is the reading's default.
  - `niyya_mansiyya.component`: built from Ibn Rajab 106.f007, which the type does not cite.

## Readings that part from their anchors (for review)

Anchoring against the source surfaced places where a reading says more, less or other than its text. None is changed here; each goes to review.

- **A reading follows a later work against the qāʿida's own report:**
  - Q52: Aḥmad's naṣṣ permits selling a debt to a third party, «وقد نص على جوازه»; the reading bars it, with al-Inṣāf.
  - Q59: Ibn Rajab calls the no-return view «ضعيف».
  - Q61: he answers the qāḍī-deputy ground «ويجاب عنه».
- **A connective that seems wrong:** Q46's `voidConcluded = binding && pervasive`. Its own docstring and the source (iḥrām «فهو منعقد») read *or*.
- **A fact the text states that the reading ignores:**
  - Q82 `shares_ground` (the second wajh reads it);
  - Q117 `suspension_barred`;
  - Q132 `beyond_own_maintenance`, which the text leaves «على روايتين»;
  - Q142 `old_materials`.
- **A field wider or narrower than its anchor:**
  - Q74 `professional`: the source's condition is «ودلالة حاله تقتضي المطالبة بالعوض»;
  - Q126 `intended`: a declaration only;
  - Q146 `listed_difference`: several listed points are only «على روايتين»;
  - Q158's first/second ordering of the two uṣūl is the reading's, not the text's;
  - Q9's `target` merges the act-specific and the non-specific prohibition;
  - Q11's `financial` names a different thing from the qāʿida's «المالية».
- **The witness:** Q90 reads «اليد العارية» where the reading quotes «اليد العادية». The anchor keeps the witness's reading.

## Does it make the reading step reproducible?

Two independent typings of the same 80 fold-1 cases, each by two blind typists, under the frozen procedure (the strict router's reading list, then the catalogue):

| | Without anchors | With anchors |
|---|---|---|
| The case's own reading settled in both typings, or in neither | 86 % | **90 %** |
| Cohen's κ on that | 0.58 | **0.69** |
| Settled rate (the two typings) | 0.800 / 0.787 | 0.825 / 0.775 |
| Identical sets of settled facts | 54 / 80 | 53 / 80 |
| Disjoint choice of qāʿida | 9 / 80 | 9 / 80 |
| Strict recall@5 | 0.887 / 0.850 | 0.887 / 0.850 |

The anchors fix **how** a field is settled once its qāʿida is chosen, and agreement rises. With 80 cases, κ's standard error is about 0.09, so the rise is suggestive rather than established. They do not change **which** qāʿida a reader picks, which is as variable as before (9 of 80 disjoint), and so neither recall nor the settled rate moves. The judgement left in the derivation is the qāʿida's **scope**: whether a farʿ falls under it. In the text, that is fixed by the qāʿida's own furūʿ, its extension, which the strict split withholds for the case's own qāʿida. Defining scope from the text is the next step for reproducibility.

## Scope: which qāʿida a farʿ falls under (PR-50)

In the texts a qāʿida is followed by its furūʿ, so the author fixes its extension. A type's **scope** is the opening clause (the question, before the ruling) of every farʿ the segmented witness places under a qāʿida the type cites. It is verbatim by construction, as a prefix of the witness text.

- Module: `pipeline/usul_corpus/scope.py`. Gate: `pipeline/tests/test_scope.py`.
- 158 of 169 types have a scope. The 11 without one are read only from al-Saʿdī, whose qawāʿid are not segmented, or have no cited source.
- The catalogue carries the scope. In evaluation the cases under test are withheld, so a typist never sees the case's own head.

The same 80 cases were typed twice more, blind, with scope in the catalogue:

| | Anchors | Anchors and scope |
|---|---|---|
| The case's own qāʿida type chosen (two typings) | 66 / 62 | **67 / 66** |
| Strict recall@1 | 0.700 / 0.688 | **0.750 / 0.725** |
| Strict recall@5 | 0.887 / 0.850 | 0.875 / 0.887 |
| Settled rate | 0.825 / 0.775 | 0.838 / 0.825 |
| Identical qāʿida types touched | 59 / 80 | 63 / 80 |
| Disjoint choice of qāʿida (excluding both-empty) | 6 / 80 | 11 / 80 |
| Own reading settled in both or neither; κ | 90 %, 0.69 | 86 %, 0.51 |

Scope makes the typists slightly more **accurate** (own type found in 133 of 160 typings, against 128 before; recall@1 up 0.04–0.05), and both settle more. It does not make them **agree** more. At n = 80 these differences are within run-to-run noise.

The disjoint cases show why. In 11 of the 15 type disagreements one side found the case's own type. The rival is mostly a qāʿida whose scope also fits the case:
- q013.f010: rajab13 against rajab151, the taking of one's right;
- q085.f010: rajab85 against rajab99;
- q158.f014: itizal against yaqin, for rajab158.

One explanation is cross-listing: a farʿ turns on two qawāʿid, and each reader picks one. The set-level measure below tests that explanation and rejects it.

## Agreement on the set of qawāʿid touched

A typing touches a **set** of source qawāʿid. Each fact maps to its types, and each type maps to the qawāʿid its statement cites, so `sadi32` and `rajab75` count as one. Two typings are compared set against set with Krippendorff's α and the MASI distance, the usual measure for set-valued labels. The module is `pipeline/usul_corpus/agreement.py`. The ten typings are committed in `corpus/typing/reproduction/`; the first plain typing is `rajab_fold1_situations.json`. `test_agreement.py` pins the figures.

| 80 cases, two typings | Plain | Anchors | Anchors and scope |
|---|---|---|---|
| α (MASI) | 0.820 | 0.827 | 0.826 |
| 95 % bootstrap interval | 0.74–0.89 | 0.75–0.90 | 0.74–0.90 |
| Identical sets | 63 | 62 | 65 |
| Overlapping sets | 71 | 71 | 67 |
| Disjoint (excluding both-empty) | 8 | 6 | 11 |
| Own reading's qawāʿid found (a / b) | 65 / 63 | 66 / 62 | 67 / 66 |
| Found by either typing | 69 | 68 | 72 |
| Mean qawāʿid per typing | 1.19 | 1.26 | 1.24 |

- **Agreement on qawāʿid is substantial and flat.** α ≈ 0.82 under every condition, so neither anchors nor scope moved it. The intervals overlap almost entirely.
- **Cross-listing is not the cause.** A typing touches 1.2 qawāʿid on average, and in about 59 of 80 cases both typings touch at most one. So readers do not touch two qawāʿid and agree on one. Each picks a single qāʿida, and in the disagreements they pick different ones.
- **What the disjoint cases are** (anchors and scope, 11):
  - In 3, one reader settled nothing (q073, q133, q153).
  - In 8, the readers named rival single qawāʿid. In 6 of those 8, one side named the case's own qāʿida:
    - q013.f010 and f013: 13 against 151;
    - q029.f002: 29 against 138;
    - q082.f004: 116 against 20, 21 and 82;
    - q085.f010: 85 and 87 against 99;
    - q068.f008: al-Saʿdī 11 against Ibn Rajab 68.
  - In the remaining 2, neither side did: q060.f007 (62 against 95, own 60) and q158.f014 (160 against al-Saʿdī 11, own 158).
- **Over all six typings** (47 cases have one set, 23 two, 10 three or four), the own qāʿida is found by at least one typing in 74 of 80 cases, and by a majority (≥ 4 of 6) in 62.

The reading step, at the level of which qāʿida, is therefore about as reproducible as the text allows a single reader: α 0.82. The residue is mostly a single reader's miss, which a second reading recovers: "found by either" is 68–72 against 62–67 for one typing. Pooling independent typings is the procedural remedy, not more definition: take the union to propose and the majority to decide.

## Accuracy

Agreement says whether two readers concur; accuracy says whether they are right. A case's truth is a **set** of qawāʿid, so accuracy is set accuracy, against two golds:

- **reading:** the qawāʿid cited by the types the case's own encoder reads;
- **bank:** every qāʿida the bank ties the case to (`mahall.links`: placement, encoder, types, co-annotation).

On this sample the two nearly coincide: 1.20 against 1.23 qawāʿid per case. `agreement.accuracy` computes the figures, and `test_agreement.py` pins them.

| 80 cases, F1 against the bank | Plain | Anchors | Anchors and scope |
|---|---|---|---|
| Typing a | 0.784 | 0.736 | 0.769 |
| Typing b | 0.746 | 0.731 | 0.794 |
| Union of the two | 0.777 | 0.739 | **0.802** |
| Union, recall | 0.816 | 0.796 | **0.867** |
| Union, precision | 0.741 | 0.690 | 0.746 |

- **Single readers are right about three times in four** (F1 0.73–0.79). Neither anchors nor scope changes this beyond noise.
- **Pooling two readings raises recall to 0.80–0.87**, at the cost of 3–5 points of precision. With scope, the union finds the right qāʿida in 72 of 80 cases.
- **Where single readings go wrong** (per 160 typings):
  - Misses are mostly a wrong qāʿida (19–24) rather than nothing settled (6–9).
  - About a third of the wrong qawāʿid picked are defensible: the qāʿida's other furūʿ rule on the same maḥall. A sixth share only the bāb, and the rest are unrelated.

### Routing accuracy, by qāʿida

The routing figures so far ask whether the case's own **encoder** is in the top k. The bank's truth is the set of qawāʿid the case is tied to, and most qawāʿid have several encoders. `hybrid_recall_by_qaida` in the typed-routing reports therefore counts a hit when a top-k encoder reads a qāʿida tied to the case:

| Hybrid recall, @1 / @5 / @10 | By encoder | By qāʿida |
|---|---|---|
| Fold 1 (held out, frozen) | 0.685 / 0.860 / 0.877 | **0.779** / 0.872 / 0.885 |
| Fold 0 | 0.554 / 0.879 / 0.913 | 0.633 / 0.896 / 0.933 |
| IslamQA tranche 1 | 0.520 / 0.691 / 0.724 | 0.602 / 0.740 / 0.740 |

At the first rank, between a fifth (fold 0: 0.079 of 0.446) and a third (fold 1: 0.094 of 0.315) of the encoder-level misses route to the right qāʿida through a sibling encoder. Deeper in the list the gain is small: the remaining misses route to the wrong qāʿida altogether.

