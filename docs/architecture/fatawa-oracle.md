# Fatāwā oracle source: IslamQA.info

IslamQA.info (founded and supervised by Muḥammad Ṣāliḥ al-Munajjid, est. 1997) publishes no bulk export. The data comes from a community scrape on Hugging Face, pinned by revision and sha256 in [`corpus/fatawa/sources.json`](../../corpus/fatawa/sources.json).

```text
corpus/fatawa/sources.json ──make fatawa──▶ .cache/corpus/fatawa/islamqa-parallel.parquet  (sha256-checked)
                                          └▶ .cache/corpus/fatawa/islamqa-parallel.jsonl    (normalised)
```

## Chosen source

`kingkaung/islamqainfo_parallel_corpus` (CC BY-NC 4.0, scraped Jan 2025): 19,052 rows → **15,303 answer ids**, **14,820 with Arabic**, every one with English. Ids run 1–518455, so this is a subset of the site, not all of it.

## Record shape

One JSON line per IslamQA answer id; duplicate rows (one per topic) are merged.

```json
{"id": "islamqa.10776", "topics": ["Belief"],
 "ar": {"title": "…", "question": null, "answer": "الحمد لله. …", "url": "https://islamqa.info/ar/answers/10776/…"},
 "en": {"title": "…", "question": "…", "answer": "Praise be to Allah. …", "url": "https://islamqa.info/en/answers/10776/…"}}
```

## Caveats

- `topics` comes from the scraper and is noisy (e.g. `islamqa.1`, on wuḍūʾ, is filed under "Belief in allah"). Treat it as a weak label.
- Many Arabic rows have no separate question (`question: null`); the title carries it.
- Some answers quote other muftīs (Ibn ʿUthaymīn, Ibn Bāz, the Lajna Dāʾima). Attribute rulings per answer, not wholesale to al-Munajjid.
- Licence is non-commercial; the text stays in the cache, as for the modern uṣūl works.
- Per the harness rule, these answers are **labels to test the kernel against**, not a hidden deontic authority.

Other candidates and why they lost are listed under `alternatives` in the manifest.
