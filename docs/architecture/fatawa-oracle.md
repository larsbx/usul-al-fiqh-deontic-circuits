# Fatāwā oracle source: IslamQA.info

IslamQA.info (founded and supervised by Muḥammad Ṣāliḥ al-Munajjid, est. 1997) has no advertised export, but its app and website share one offline-reading backend: per-language dumps listed in a public manifest.

```text
https://files.zadapps.info/m.islamqa.info/dumps/manifest.json
  dumps[]  : {lang, folder: dumps/<snapshot>/<lang>, file: data.ndjson.gz}   full snapshot
  deltas[] : {lang, folder: dumps/deltas/<date>/<lang>, …}                   created/updated/deleted since
```

The pinned snapshot (`dumps/2026-10-04-220000`, all 17 languages, sha256 per file) is in [`corpus/fatawa/sources.json`](../../corpus/fatawa/sources.json).

```text
corpus/fatawa/sources.json ──make fatawa──▶ .cache/corpus/fatawa/islamqa-<lang>.ndjson.gz  (sha256-checked)
                                          └▶ .cache/corpus/fatawa/islamqa-<lang>.jsonl     (answers)
```

## Dump format

Each line is an event `{serial, op, type, data}` with `op ∈ {created, updated, deleted}`. `fold` applies events in order, keyed by `(type, reference)`, so snapshot ⧺ deltas gives the current database. Types: `answer` (ar: 32,445), plus `source`, `topic`, `subsite`, `file`, `article`, `book`, `research`, `event`, `page`, `learn-with-us`. The raw dump keeps all of them; the JSONL holds answers only.

`reference` is the site-wide answer number, shared across languages (ar ∩ en = 15,313).

## Record shape

```json
{"id": "islamqa.115097", "lang": "ar", "url": "https://islamqa.info/ar/answers/115097",
 "title": "…", "question": "…", "answer": "…",
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
- Text stays in the cache; nothing here is a fatwā issued by this project. Per the harness rule, these answers are **labels to test the kernel against**, not a hidden deontic authority.
- Deltas are not applied by `make fatawa` (the snapshot is pinned for reproducibility); `fold` already handles them.
