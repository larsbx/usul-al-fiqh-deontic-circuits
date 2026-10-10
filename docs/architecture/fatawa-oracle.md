# Fatāwā oracle source: IslamQA.info

IslamQA.info (founded and supervised by Muḥammad Ṣāliḥ al-Munajjid, est. 1997) has no advertised export, but its app and website share one offline-reading backend: per-language dumps listed in a public manifest.

```text
https://files.zadapps.info/m.islamqa.info/dumps/manifest.json
  dumps[]  : {lang, folder: dumps/<snapshot>/<lang>, file: data.ndjson.gz}   full snapshot
  deltas[] : {lang, folder: dumps/deltas/<date>/<lang>, …}                   created/updated/deleted since
```

The pinned snapshot (`dumps/2026-10-04-220000`, all 17 languages, sha256 per file) is in [`corpus/fatawa/sources.json`](../../corpus/fatawa/sources.json).

```text
corpus/fatawa/sources.json ──make fatawa──▶ data/islamqa/raw/islamqa-<lang>.ndjson.gz      (committed; fetched only if absent; sha256-checked)
                                          └▶ data/islamqa/answers/islamqa-<lang>.jsonl.gz  (committed; byte-deterministic)
```

Both directories are in Git LFS (`.gitattributes`). After cloning, `git lfs pull --include "data/islamqa/**"` fetches them; CI checkouts skip them. Read the answers with:

```python
import gzip, json
answers = [json.loads(l) for l in gzip.open("data/islamqa/answers/islamqa-ar.jsonl.gz", "rt", encoding="utf-8")]
```

## Dump format

Each line is an event `{serial, op, type, data}` with `op ∈ {created, updated, deleted}`. `fold` applies events in order, keyed by `(type, reference)`, so snapshot ⧺ deltas gives the current database. Types: `answer` (ar: 32,445), plus `source`, `topic`, `subsite`, `file`, `article`, `book`, `research`, `event`, `page`, `learn-with-us`. The raw dump keeps all of them; the JSONL holds answers only.

`reference` is the site-wide answer number, shared across languages (ar ∩ en = 15,313).

## Record shape

```json
{"id": "islamqa.115097", "lang": "ar", "url": "https://islamqa.info/ar/answers/115097",
 "title": "…", "question": "…", "answer": "…", "summary": "…or null (the site's ملخص الجواب, 3,387 ar)",
 "source": {"ref": 5, "title": "الإسلام سؤال وجواب"},
 "topics": [{"ref": 150, "path": ["الفقه وأصوله", "الفقه", "معاملات", "البيوع", "الاستثمار"]}],
 "subsites": [], "see_also": ["islamqa.7535"], "langs": ["ar"], "created": "2008-03-26", "updated": "2020-02-11"}
```

| lang | answers | lang | answers | lang | answers |
|---|---:|---|---:|---|---:|
| ar | 32,445 | ur | 9,039 | ug | 2,447 |
| en | 15,801 | fr | 7,834 | pt | 2,139 |
| id | 5,938 | es | 5,544 | ru | 2,128 |
| zh | 3,805 | tr | 3,403 | ge | 2,024 |
| hi | 1,913 | bn | 1,752 | fa | 1,552 |
| tg | 1,136 | ta | 131 | | |

## Caveats

- `source` attributes the answer: mostly the site itself (28.6k ar), al-Munajjid by name (1.5k), and quoted muftīs (Ibn ʿUthaymīn, Ibn Bāz, the Lajna Dāʾima, …). Attribute rulings per answer.
- `topics` is the site's own taxonomy (ancestor path, top level e.g. الفقه وأصوله: 20,979 ar). 681 ar answers have none.
- `see_also` (the site's `fatawas`) links related answers: a ready-made citation graph.
- The text is © IslamQA (all rights reserved) and is committed only because this repository is private: do not make the repository or `data/islamqa` public. Nothing here is a fatwā issued by this project. Per the harness rule, these answers are **labels to test the kernel against**, not a hidden deontic authority.
- Deltas are not applied by `make fatawa` (the snapshot is pinned for reproducibility); `fold` already handles them.

Training labels: [fatawa-labels.md](fatawa-labels.md).

## Baseline oracle (`make oracle`)

[`oracle.py`](../../pipeline/usul_corpus/oracle.py) predicts a candidate ḥukm from the **question alone** (title + question text). The answer states the verdict, so it is never read. Training uses the `train` split, with each label weighted by `confidence`: basis × bank class × English agreement × act/question match. Rejected and conflicting labels weigh 0. The weighted set is exported for future models as `data/islamqa/train/islamqa-ar.jsonl.gz` (all splits, LFS).

Test split (1,460 answers; dev gives the same picture), accuracy / macro-F1:

| model | all labels | high-confidence labels (weight ≥ 0.7) |
|---|---:|---:|
| majority (ḥarām) | 34.5% / 0.10 | 52.5% / 0.14 |
| retriever, k = 10 | 47.5% / 0.34 | 52.7% / 0.36 |
| Naive Bayes | 50.0% / 0.34 | 51.0% / 0.35 |

Per-class F1 for Naive Bayes on all labels: wajib 0.51, mandub 0.18, mubah 0.52, makruh 0.00, haram 0.50.

Abstaining when the retriever's best match is weak:

| best cosine | coverage | accuracy |
|---|---:|---:|
| ≥ 0.2 | 19% | 54.4% |
| ≥ 0.3 | 5% | 56.2% |
| ≥ 0.5 | 1% | 66.7% |

**Reading.** A surface-text oracle is weak:
- On high-confidence labels its accuracy is no better than always answering ḥarām. Its macro-F1 is higher (≈ 0.35 vs 0.14) only because it spreads its answers over four classes at roughly a coin flip each. It never recovers makrūh.
- The questions are mostly «هل يجوز X؟», and the ruling turns on facts and principles the wording does not carry («يجوز إذا …، ولا يجوز إذا …»).

These numbers are the floor that any real oracle must clear on this fixed split. The retriever's `evidence` (the nearest answered fatwās, their ids and labels) is still useful as a citation layer for whatever decides.

Two directions can clear the floor:
- **A model that reads the question in depth.** For example, an LLM fine-tuned or prompted on the weighted set. Its output stays a candidate, checked by the bank.
- **The kernel itself.** Encode each case's facts (act, addressee, conditions) as the takhrīj encoders do, and let `Usul` derive the ruling. That is the deontic-circuit oracle the project is building, with this corpus as its test bench.
