# Fatāwā training labels

`make labels` turns the Arabic IslamQA answers ([fatawa-oracle.md](fatawa-oracle.md)) into **candidate** labels for training the oracle. The rules are lexical and auditable. Each label names the passage it was read from and the cue that decided it. Nothing here is a reviewed ruling.

```text
data/islamqa/answers/islamqa-ar.jsonl.gz ──make labels──▶ data/islamqa/labels/islamqa-ar.labels.jsonl.gz   (LFS, byte-deterministic)
                                                       ├▶ corpus/fatawa/labels_report.json                (counts)
                                                       └▶ corpus/fatawa/review/labels-sample.jsonl         (25 per class, gold: null)
```

## Record

```json
{"id": "islamqa.306277", "split": "train", "domain": "الفقه وأصوله", "chapter": "معاملات",
 "hukm": "haram", "basis": "lead", "conditional": false, "also": [],
 "evidence": {"cue": "لا يجوز", "passage": "لا يجوز للانسان ان يبيع شيئا من اعضائه …"},
 "wad": [], "status": "candidate"}
```

| field | meaning |
|---|---|
| `hukm` | `wajib · mandub · mubah · makruh · haram` (the constructors of `Usul.Hukm`, [Hukm.lean](../../formal/lean/Usul/Hukm.lean)), or `null` when no ruling cue was found |
| `basis` | where it was read: `summary` (the site's ملخص الجواب) › `conclusion` (a «الحاصل / الخلاصة» paragraph) › `lead` (first three lines) |
| `also`, `conditional` | other statuses in the same passage; `conditional` also fires on «إلا إذا / إن كان / بشرط» |
| `wad` | validity (ḥukm waḍʿī): `sahih` / `batil`, read from the same passage |
| `domain`, `chapter` | from the site's topic tree (`الفقه` skipped as a level) |
| `split` | `train/dev/test` = 80/10/10 by sha1 of the answer number, so every language of one answer shares a split (no cross-lingual leakage) |

To train on another language, join on `id`: answer numbers are shared across languages.

## Method

Text is normalised: tashkīl and taṭwīl are stripped and alef forms unified. Then a cue lexicon (`LEXICON` in [`labels.py`](../../pipeline/usul_corpus/labels.py)) is matched:

- Negated forms claim their span first: «لا يجوز» is ḥarām, never mubāḥ. «لا/لم/لن يجب», «ليس بواجب» and «ليست حراما ولا مكروهة» cast no vote.
- A cue inside a «هل …» question is not a ruling.
- Narrow frames: «من السنة أن», «الأفضل أن», «يكره أن/ذلك/هذا/فعل», «مكروه» unless followed by a noun, «كراهة تحريم» is ḥarām. Bare «يكره» («he dislikes») and «لا ينبغي» are excluded.

The label is the first affirmative cue in the highest-ranked passage that has one.

## Counts (snapshot 2026-10-04)

14,360 of 32,445 answers are labelled; [`labels_report.json`](../../corpus/fatawa/labels_report.json) has the breakdown.

| hukm | all | via summary | via conclusion | via lead |
|---|---:|---:|---:|---:|
| ḥarām | 5,200 | 341 | 434 | 4,425 |
| mubāḥ | 5,099 | 570 | 489 | 4,040 |
| wājib | 3,351 | 217 | 265 | 2,869 |
| mandūb | 597 | 100 | 44 | 453 |
| makrūh | 113 | 4 | 13 | 96 |
| none | 18,085 | | | |

## Spot-check (not a gold set)

Claude read random samples against their evidence. This is a sanity check of the rules, not human review:

| class | correct / read | typical error |
|---|---|---|
| ḥarām | 6 / 6 | — |
| mandūb | 6 / 6 | — |
| wājib | 4 / 6 | the first cue rules on a side issue (e.g. the husband's duty when the wife's was asked) |
| mubāḥ | 4 / 6 | same; a general rule stated before the specific verdict |
| makrūh | 2–3 / 8 | «الأصل في النذر أنه مكروه»-style side remarks |

Implications for training:
- Weight by `basis` (summary > conclusion > lead).
- Treat makrūh as unreliable until reviewed.
- The dominant error is *relevance*: the right status attached to the wrong act. A question-aware selector, or human review, is the next step.
- `null` mostly means a non-normative answer (creed, history, tafsīr), not "no ruling".

## Review

[`corpus/fatawa/review/labels-sample.jsonl`](../../corpus/fatawa/review/labels-sample.jsonl) holds 25 answers per class plus 25 unlabelled ones, chosen deterministically, each with the bank's verdict and a review `priority` (see below). Fill `gold` (a `Hukm` value, or `"none"`) and `note`, `high` priority first. This is the human gold set that the precision figures above should be replaced with.


## Bank review (`make bank-review`)

[`bank_review.py`](../../pipeline/usul_corpus/bank_review.py) re-reads each candidate's deciding clause through the kernel. Each cue denotes the set of `Hukm` values a bank function allows:

| cue | kernel reading |
|---|---|
| explicit status («حرام», «مستحب», …) | `Dalala.amrStatus (some h)` |
| prohibition («لا يجوز», «لا يحل») | `Dalala.nahyStatus none` (= σ ∘ amrStatus none) |
| obligation label («يجب», «فرض عين») | `CommandSchemata.obligationStatus r e none`, both readings |
| jawāz («يجوز», «لا حرج», «حلال») | `¬(mode = talabTark ∧ binding)`, i.e. everything but ḥarām |
| negated status («لا يجب») | everything but that status |
| ruling on the omission («ترك X حرام», «لا يجوز تركه») | σ applied to the set |

Cues in one clause are intersected; «إلا إذا / لكن / أما إذا» open a new clause. The Python mirrors of σ, `mode`, `binding`, jawāz and the amr/nahy defaults are guarded exhaustively in [`UsulTest/FatawaBank.lean`](../../formal/lean/UsulTest/FatawaBank.lean). Output: `data/islamqa/labels/islamqa-ar.bank.jsonl.gz`, [`bank_review_report.json`](../../corpus/fatawa/bank_review_report.json), and `bank` + `priority` on each review-sample item.

| class | answers | English version agrees |
|---|---:|---:|
| confirmed (the clause fixes one status, the candidate's) | 8,619 | 82% (2,846/3,457) |
| consistent (candidate allowed; clause underdetermines, e.g. jawāz) | 4,481 | 87% (1,626/1,874) |
| rejected (candidate excluded) | 139 | 71% (55/77) |
| conflict (the clause's cues are jointly unsatisfiable) | 1,120 | 73% (415/565) |

### Why the bank does not fill `gold`

Confirmed labels are no more accurate than the rest. Their English agreement is no higher than for consistent ones. Of 12 would-be auto-gold items read by hand, 9 were right, and of 14 low-priority sample items about 10 were: the base rate. The reasons:

- **The bank reads the same cue the labeller read.** It can show the clause is deontically coherent, but not that it rules on the act the question asks about. That relevance error is the dominant one.
- **Its intersection assumes one act per clause.** Fatwa clauses often rule on several: «يجوز أن يقسم … ويلزمه العدل», «محرم، يلزمك التوبة». Most rejections and many conflicts come from this, not from a wrong label.

So the bank's verdict is **triage**, not gold:
- `priority: high` (conflict, rejected, or the English version disagrees) is reviewed first;
- `low` (confirmed and corroborated by English) last;
- `gold` stays human-only.

Making the bank a real reviewer needs act-relative readings, i.e. (act, ḥukm, condition) per cue, which is what `hukm_classification` already models. Then cues are intersected only when they rule on the same act, and the verdict is the ruling on the act the question names.
