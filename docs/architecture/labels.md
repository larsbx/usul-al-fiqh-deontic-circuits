# Citation-mention labels

A dataset for training a small classifier that decides, for a mention of a title or author in a modern fatwā or sharḥ, **which registered work or author it names, or none**. The [reception](reception.md) matcher is the weak labeller; human review supplies gold labels. Code: `pipeline/usul_corpus/labels.py`. Row format: [`schemas/citation_mention.schema.json`](../../schemas/citation_mention.schema.json).

```text
registry (cite_as, not) ─┐                      ┌─▶ .cache/labels/<task>.jsonl              all candidates
authors.json ────────────┼─ labels ─ candidates ─┼─▶ .cache/labels/<task>.{train,dev,test}.jsonl  labelled rows + text
cached citer witnesses ──┘     ▲   + rule labels └─▶ .cache/labels/review-<task>.jsonl       queue with choices
corpus/labels/gold.jsonl ──────┘   + gold labels ──▶ corpus/labels/summary.json             counts only (committed)
```

## Tasks

| Task | Label space | Lexicon | Single-word forms |
|---|---|---|---|
| `work` | the 52 `cited` work ids, `none` | registry `reception.cite_as` / `not` | need a cue (في, صاحب, …) |
| `author` | the author ids in `corpus/reception/authors.json`, `none` | `authors.json` | count as written |

## How a row is made

1. **Candidates (high recall).** Every form's *head* is its citation form with the cue stripped: «قال في الفروع» → «الفروع», «ابن المنذر في الأوسط» → «الأوسط». Every occurrence of any head in a citer's page is a candidate, after the same normalisation the counts use (`reception.plain`). Overlapping heads resolve leftmost-longest.
2. **Rule labels (high precision).** If the precise matcher resolves a span that covers the candidate, the row gets that work, or `none` when the covering span is a `not` phrase (الطبراني في الأوسط). Otherwise the row is unlabelled. The rules never guess: a bare «المغني» without a cue stays unlabelled.
3. **Gold labels override rules.** `rule_label` keeps the rule's verdict, so `summary.json` can report rule-vs-gold agreement: that is the measured precision of the counts.
4. **Splits by page.** sha256 of `witness/locator`: 0 → test, 1 → dev, otherwise train (≈ 80/10/10). Every mention on a page shares a split, so no context crosses train and test.

Each row keeps `WINDOW = 200` normalised characters of context on each side. Split files add `text = left [[surface]] right` for classifiers that take one string.

## First run

All nine citers (Ibn Bāz ×2, Ibn ʿUthaymīn ×3, al-Albānī ×2, al-Saʿdī ×2):

| Task | Candidates | Rule-labelled | Unlabelled | of which `none` |
|---|---:|---:|---:|---:|
| `work` | 2,863 | 1,298 | 1,565 | 15 |
| `author` | 4,783 | 4,268 | 515 | 23 |

The unlabelled `work` rows are mostly heads that are also ordinary words or other books: «الإجماع» (471; usually the concept), «الأوسط» (290; mostly al-Ṭabarānī, but also «الشرق الأوسط»), «القواعد» (233), «الفروع» (170), «الإنصاف», «المجموع», «الكافي». They also include real citations the rules miss, such as «من شرح مسلم للنووي» and «قال الإمام النووي في كتاب المجموع». That is the classifier's job.

## Reviewing

```sh
make labels                                    # or: python -m usul_corpus labels [--review N]
# edit .cache/labels/review-<task>.jsonl: set "label" to one of the row's "choices"
python -m usul_corpus labels --import .cache/labels/review-work.jsonl
```

- The review queue is unlabelled rows taken round-robin over surfaces (default 300 per task), so a rare title is not buried under 471 «الإجماع».
- Each row lists its `choices`: the entries one of whose heads it is, plus `none`. `--import` rejects any other label and leaves rows with `label: null` alone.
- Gold labels go to `corpus/labels/gold.jsonl` as `{id, label}` only, with no text. `summary.json` lists `gold_unmatched` ids if a lexicon or witness change orphans one.

Ids are `task:witness/locator@offset`, and the offset is into the page's normalised text. They stay stable while the witness is pinned (`lock.json`) and the normaliser is unchanged.

## Training on it

- **Positives are rule-shaped.** Rule-labelled rows are nearly all positives found by cue words, so a model trained on them alone learns the rules. Train on gold + rule rows, weight gold up, and **evaluate on gold rows of the test split only** (`label_source == "gold"`).
- **Negatives come from review.** Rule `none` is rare, and most negatives will be reviewed rows.
- **Class balance.** The 52 work classes are long-tailed (*Zād al-Maʿād* 155, several 0). Report macro-F1 alongside accuracy, and consider grouping classes that can never be separated in the training data.
- **Inputs.** Train on the normalised text the rows carry, and normalise at inference with `reception.plain`.

## Rights

The contexts come from modern texts (`modern_cache_only`), so they live in `.cache/labels` and are never committed, like the witnesses themselves. Gold labels and the summary carry ids and counts only.
