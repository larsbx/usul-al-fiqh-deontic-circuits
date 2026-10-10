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
| ruling on the omission or the opposite act («ترك X حرام», «لا يجوز تركه», «التهاون», «الكف عن», «الحذر من») | σ applied to the set |
| «مكروه أو محرم», «جائز أم غير جائز» | union |

Only predications on the act are compared (see *Conflicts* below for what is set aside), and each predication has its own scope. The Python mirrors of σ, `mode`, `binding`, jawāz and the amr/nahy defaults are guarded exhaustively in [`UsulTest/FatawaBank.lean`](../../formal/lean/UsulTest/FatawaBank.lean). Output: `data/islamqa/labels/islamqa-ar.bank.jsonl.gz`, [`bank_review_report.json`](../../corpus/fatawa/bank_review_report.json), and `bank` + `priority` on each review-sample item.

| class | answers | English version agrees |
|---|---:|---:|
| confirmed (the predication fixes one status, the candidate's) | 8,028 | 82% (2,713/3,292) |
| consistent (candidate allowed; the text underdetermines, e.g. jawāz) | 4,633 | 87% (1,720/1,987) |
| misread (the candidate's own cue is not a ruling on the act) | 1,678 | 74% (505/679) |
| rejected (candidate excluded) | 5 | 33% (1/3) |
| ikhtilāf (reported positions, no preference stated) | 1 | 0% (0/1) |
| conflict (tawaqquf) | 12 | 67% (6/9) |

80 confirmations are of a label that rules on the *omission* (`act: omission`): «لا يجوز التفريط فيها» is ḥarām of neglect, which is σ of wājib of the act (`RespectsDidd`). They were the bulk of the earlier "rejected" class.

### Why the bank does not fill `gold`

Confirmed labels are no more accurate than the rest. Their English agreement is no higher than for consistent ones. Of 12 would-be auto-gold items read by hand, 9 were right, and of 14 low-priority sample items about 10 were: the base rate. The reasons:

- **The bank reads the same cue the labeller read.** It can show the clause is deontically coherent, but not that it rules on the act the question asks about. That relevance error is the dominant one.
- **Its intersection assumes one act per clause.** Fatwa clauses often rule on several: «يجوز أن يقسم … ويلزمه العدل», «محرم، يلزمك التوبة». Most rejections and many conflicts come from this, not from a wrong label.

So the bank's verdict is **triage**, not gold:
- `priority: high` (conflict, rejected, or the English version disagrees) is reviewed first;
- `low` (confirmed and corroborated by English) last;
- `gold` stays human-only.

Making the bank a real reviewer needs act-relative readings, i.e. (act, ḥukm, condition) per cue, which is what `hukm_classification` already models. Then cues are intersected only when they rule on the same act, and the verdict is the ruling on the act the question names.

## Conflicts: the bank applied to its own conflicts

A conflict is a predication set the kernel cannot satisfy. `Usul.resolve` ([Taarud.lean](../../formal/lean/Usul/Taarud.lean), after Ibn ʿUthaymīn) orders their resolution: jamʿ ≻ naskh ≻ tarjīḥ ≻ tawaqquf. The reviewer follows that order. Each round adds one principle, and is tested on the corpus sentences that motivated it (`test_bank_review.py`):

| round | principle | conflicts left |
|---|---|---:|
| R0 bare reading | every cue is a ruling on one act | 959 |
| R1 reading | only predications on the act take part: not cues inside another cue's complement, a relative, reason or reported clause («أن يلزم», «التي لا يجوز», «لأن …», «بأنه»); not status words used as ordinary words (after a preposition, attributive «بتجارة مباحة», inside a proof-text); not homographs (مَحْرَم kinsman, مُحْرِم pilgrim); not frames («يجب أن تعلم أن», «لا يلزم منه»), questions or «قد» | 570 |
| R2 jamʿ via σ | a ruling on the opposite act is the same ruling: H(ḍidd a) = σ(H a) (`Dalala.amr_nahy_didd_of`) | 547 |
| R3 jamʿ by scope | each predication rules on its own act: «،», «:», «بل», «وإنما», «أما», «ما عدا», «ومنه ما», conditional branches «فإن / وإذا / وإلا», and «و» before a verbal ruling open a new scope; «أو / أم» between statuses is a union | 15 |
| R4 tarjīḥ | `resolve ⟨none, none, some p⟩ = .tarjih p` when the text prefers p, forward («والصواب أنها …») or backward («… وهو الصحيح»); a reported disagreement without preference is `ikhtilaf` | **13** |

`resolve`'s Python mirror is guarded on all eight stage combinations in `UsulTest/FatawaBank.lean`. Naskh never fires, because fatwa text gives no chronology. `bank_review_report.json` → `conflicts_by_round` reproduces the table.

**Why the conflicts arose.** Almost none were contradictions in the fatwas:
- R1: about 40% were cues that are not rulings on the act.
- R3: about 55% were two rulings on two different acts in one clause («الغصب محرم ويجب رد المغصوب»).
- R2: a few percent were one ruling stated on the act and on its opposite («لا يجوز التهاون … بل يجب المحافظة»).

**The 13 that remain, all read by hand:**

| cause | n | what would resolve it |
|---|---:|---|
| genuine ikhtilāf, three positions, no preference stated (Eid prayer) | 1 | correctly `ikhtilaf`: the madhhab or a reviewer decides |
| a different Sharīʿa: «جائزة في شريعة سليمان … محرمة في شرعنا» | 2 | a scope for *sharʿ man qablanā* |
| opposites by meaning, not by the word ترك: «يعدل / تفضيل», «تمتنع / تبقى» | 3 | an antonym table for σ, i.e. act identity |
| different subject or addressee: «على الرجال … عليهن», «والتي زارت جهلاً» | 3 | act-relative readings (subject as part of the act) |
| proof-texts quoted without delimiters («وسلم في مكة : "…"», an athar) | 2 | quotation segmentation |
| homograph مُحْرِم without a ḥajj word nearby («اغتسل وهو محرم») | 1 | a lexicon |
| a bare «إنما» marking contrast | 1 | splitting there without breaking reason clauses |

The bank's verdict stays triage, not gold: it reads the same cues the labeller read. But the conflicts it found were nearly all misreadings, and fixing them is what turned `misread` into a usable signal for flawed labels.
