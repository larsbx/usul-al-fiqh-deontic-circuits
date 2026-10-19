# Routing after round 7: category labels, and what 0.9 would take (PR-48)

Lane A round 7 annotated the last ten Ibn Rajab qawāʿid with pending furūʿ: 13, 23, 40, 70, 82 and 84–88. Most are typological: a qāʿida that sorts its subject into anwāʿ, each formalised as its own encoder. Q85 has eight encoders and Q82 five. The routing index's headline (audit PR-38) holds out whole qawāʿid. Held out that way, these furūʿ route poorly, and grouped recall@5 fell below the test floor of 0.5. Every figure below comes from `corpus/routing/index.json` or from a re-run of the folds there. The prior, ranking by frequency under the same split, is 0.0008 at every k.

## Where the recall went

Recall@5, whole qawāʿid held out (`by_qaida`):

| | All (1216) | Old cases (1044) | Round 7 (172) |
|---|---|---|---|
| Before round 7, per encoder | 0.5077 | 0.5077 | – |
| After round 7, per encoder | 0.4605 | 0.4943 | 0.2558 |
| Category label, encoder ranking collapsed | 0.4794 | 0.5134 | 0.2733 |
| **Category label, pooled profiles (adopted)** | **0.4827** | 0.5153 | 0.2849 |
| Per encoder, plus nawʿ headings | 0.4564 | 0.4847 | 0.2849 |
| Category, plus nawʿ headings | 0.4811 | 0.5057 | 0.3314 |

The old cases fell slightly because 31 more encoders compete. The new cases fail for a different reason. With the qāʿida held out, the only evidence left is its statement record: 400 characters, which for a typological qāʿida is only its opening. Its ṣuwar run across many bābs (pledge, lease, waqf, nikāḥ…) in words the statement does not use. Typology explains Q82 and Q85, 56 of the 172 cases. Single-encoder qawāʿid fail as well: Q13 hits 1 of 16 at k = 5, Q70 2 of 17.

**Adopted: route to the category.** A case's category is the qāʿida type its encoder reads (`routing.category`: the encoder's qawāʿid). The anwāʿ of one typology share it. The router is then credited for finding the qāʿida, and the typed facts choose the nawʿ. `held_out` scores the category and reports the per-encoder figures beside it (`recall.encoder`). The test floor is 0.45.

**Consumers that need encoders still rank encoders.** These are typed routing's lexical tiebreak and the lane-B proposals. A pilot that expanded each ranked category to its encoders lowered the per-encoder measures: out-of-domain lexical@5 fell from 0.21 to 0.15, and fold-0 hybrid@5 from 0.86 to 0.85. The cause is that Q85's eight anwāʿ fill a top 5 by themselves.

**Tried, not adopted: nawʿ headings as evidence.** These are 108 headings in 41 qawāʿid, of the forms «[النوع الثاني …]» and «النوع/القسم/الضرب + ordinal», taken from the qāʿida's own span. They lift the new cases (0.28 → 0.33 by category) but cost the old as much: they are short and generic («الضرب الثاني»).

**Out of domain** (the IslamQA tranche), category recall@5 is 0.16 against 0.21 per encoder. Both sit at the prior, 0.22, as before.

## The strict figure for the typed route

The typed coverage scores (Prolog over the Lean export) are trained on nothing, so they do not depend on the split. The typed-routing report's lexical tiebreak, however, folds by record. Re-scored with whole qawāʿid held out, the 240 blind-typed fold-0 cases give:

| Recall@5 | Folded by record (as reported) | Folded by qāʿida (strict) |
|---|---|---|
| Lexical alone | 0.800 | 0.463 |
| Hybrid, types first | 0.879 | **0.725** |
| Hybrid, scored on category | 0.896 | **0.754** |
| Hybrid, round 7's 43 cases | 0.791 | 0.512 |

These figures follow a fix to round 7's typed wrappers. Their `def` names had been shortened, so the Prolog export, which takes an encoder's name from its `def` in snake_case, named the new encoders wrongly, and their typed coverage was lost. Before the fix the hybrid read 0.863 / 0.696.

## What 0.9 would take, legitimately

Legitimate means four things hold:
- no held-out farʿ or its annotation reaches training;
- the formalised qāʿida statements stay in, as they do when the index is used;
- method choices are fixed before scoring, or chosen on inner folds;
- the prior is reported beside every figure.

1. **A typed signal that discriminates.** On its own the typed route reaches 0.59 at k = 5. Two things limit it:
   - **Thin situations.** 32 of the 240 cases settle no field. The blind typist saw bare field names, and a catalogue that gives each field its qāʿida type's statement (encoder names stripped) is legitimate, since the statements are known when the router is used.
   - **Ties.** Ranking by the *share* of an encoder's fields settled ties every one-field encoder at 1.0. Ranking by count settled, then share, with the type hierarchy (`extends`) breaking ties, uses what the types already carry.
2. **Category scoring at the type layer** (done for the lexical headline).
3. **Blind typing beyond fold 0.** Fold 0 is too small to claim a figure at the qāʿida level.
Re-weighting TF-IDF or lifting the excerpt cap will not get there: a typological farʿ's words are its bāb's, not its qāʿida's.

## Pilot: semantic routing does not help with a general embedding model

The pilot used `intfloat/multilingual-e5-base` at revision `d128750597153bb5987e10b1c3493a34e5a4502a`, on CPU, with e5's `query:`/`passage:` prefixes. Each fold's evidence was embedded without the fold, as for the lexical model. Fusion is reciprocal rank with the standard k = 60, not tuned. The pilot was run outside the repository; nothing is adopted.

| Recall@5 under the strict split | Category, all | Old | Round 7 | Typed hybrid, fold 0 (by encoder / by category) |
|---|---|---|---|---|
| Lexical (the index) | **0.483** | 0.515 | 0.285 | **0.696** / 0.721 (before the wrapper fix) |
| Semantic, category centroids | 0.063 | 0.072 | 0.012 | 0.554 / 0.571 |
| Semantic, centred, nearest example | 0.255 | 0.265 | 0.192 | 0.613 / 0.629 |
| Lexical and semantic fused | 0.355 | 0.376 | 0.227 | 0.650 / 0.675 |

The centroid run collapses because e5's vectors share one dominant direction, so the categories with the most evidence win every query. The fix, centring on the mean and scoring each category by its nearest example, is the method's standard correction, fixed before scoring. Corrected, the embedding still scores half of TF-IDF, and fusing the two lowers the lexical figure. A general multilingual model does not separate what the bank routes on: furūʿ of a pledge and of a lease are near each other as commerce, yet fall under different qawāʿid. Semantic routing would need a classical-Arabic encoder fine-tuned on the bank's cases fold by fold. That is its own project, with the same leakage discipline, and is not pursued here.

**So the path to 0.9 is the typed route** (items 1–3), with the lexical index as its tiebreak.

## Pilot: the typed route on fold 0, re-typed with a richer catalogue

The 240 fold-0 cases were re-typed blind by four agents, under fresh shuffled opaque ids. Each field came with the statements of the qāʿida types that contain it («stated_in»), with no encoder names. The scratch situations are not committed; the committed fold-0 typing is unchanged. Scored under the strict split:

| | Situations / facts / nothing settled | @1 | @5 | @10 | Category @5 |
|---|---|---|---|---|---|
| Committed typing | 312 / 378 / 32 | 0.512 | 0.725 | 0.746 | 0.754 |
| Re-typed, richer catalogue | 281 / 320 / 39 | **0.629** | **0.762** | 0.783 | **0.792** |

Ranking by count of fields settled before share changes nothing, in either typing.

**The ceiling is the typing step, not the ranking.** In the re-typed set:
- When any field of the case's own encoder is settled (159 of 240, 66 %), the encoder is in the top five every time.
- All 57 misses are cases where the typist settled none of the right qāʿida's fields. The lexical tiebreak rescues 24 of those 81.

Recall@5 is therefore about 0.66 + 0.34 × (the lexical rescue rate, here 0.30). Reaching 0.9 needs the typist to land on the right qāʿida about 86 % of the time, up from 66 %. The remaining lever is the typist's search over about 160 statements: for example, a shortlist from the strict-fold router, given as well as the full catalogue. Whether that is a real gain, and not circular, has to be measured on a fold it was not designed on.
