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
