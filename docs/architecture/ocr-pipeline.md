# OCR Pipeline

This pipeline covers image-only witnesses. Its output feeds the same reader, segmenters and records as the text witnesses, so no downstream code is OCR-specific.

```text
archive.org PDF ─fetch─▶ .cache/corpus/<id>.pdf (sha256 in lock.json)
   │
   ├─ pdftoppm -r 300 -gray        → .cache/ocr/<id>/png/pNNNN.png        (cached per page)
   ├─ tesseract -l ara --psm 4 tsv  × {ara_std, ara_best} (pinned sha256)
   │                                → .cache/ocr/<id>/tsv/<model>/pNNNN.tsv (cached per page and model)
   ├─ parse_tsv → clean_line → drop is_noise → choose (best mean confidence per page)
   ├─ strip_running_heads
   ▼
.cache/corpus/<id>.txt   mARkdown, closing PageV01Pnnn markers (n = PDF page index)
corpus/ocr/<id>.json     metrics only: per-page model, confidence, low-confidence lines
lock.json                ocr_sha256 of the produced text
```

Run it with `make fetch ocr build`. It needs `tesseract-ocr` 5 and `poppler-utils`; the models are downloaded and verified automatically. The run is resumable because every page and model result is cached.

## Design

| Step | Function | Notes |
|---|---|---|
| Line assembly | `ocr.parse_tsv` | Groups words by (block, paragraph, line). Tesseract's word order is logical (right-to-left reading order). Line confidence is the mean of its word confidences |
| Normalisation | `ocr.clean_line` | Applies NFKC (presentation forms to letters), maps Persian lookalikes (ی→ي, ک→ك, ہ→ه) and removes bidi marks. A «»» glued to a word with no matching «« on the line becomes the Arabic comma. Real orthography such as final hamza is never touched |
| Noise filter | `ocr.is_noise` | Drops a line with fewer than 3 Arabic letters or an Arabic share below 50% (rules, footnote debris, folio numbers) |
| Model choice | `ocr.choose` | The two models fail on different pages. Per page, the higher mean confidence wins and the choice is recorded |
| Running heads | `ocr.strip_running_heads` | Drops a line that recurs verbatim on at least 20% of pages |
| Rule headers | `segment.segment_lines` | «القاعدة <ordinal>» lines. Ordinals are parsed with OCR-tolerant fuzzy matching, which is flagged in the record |
| Verse numbers | `segment.segment_numbered` | «١ - …», «۹۔ …». A dynamic programme finds the longest numbering chain with steps of 1 to 3. Footnotes «(١)» never match. OCR that dropped a leading digit (10 read as «۰») is repaired to the smallest consistent value and flagged `ocr_corrected` |
| Cross-check | `segment.consensus_numbering` | For a work with several witnesses (archive.org OCR and our OCR), lists which witness found each rule number and which numbers no witness found |

## Witnesses

| Work | Witnesses | Segmenter |
|---|---|---|
| al-Saʿdī, *al-Qawāʿid al-Jāmiʿa* | `archive-pdf1995` (archive.org OCR), `archive-pdf1995-tess` (this pipeline) | `lines` on «القاعدة» |
| Ibn ʿUthaymīn, *Sharḥ Manẓūmat Uṣūl al-Fiqh* | `archive-manzuma-djvu` (archive.org OCR), `archive-manzuma-tess` | `numbered` (verses) |
| al-Saʿdī, *Ṭarīq al-Wuṣūl* | `archive-tariq-tess` | none yet (see status) |

Correction to the earlier registry: the archive.org item first listed for the *Manẓūma* holds audio lessons, not a scan. The witness is now Ibn ʿUthaymīn's printed sharḥ, which quotes every verse.

All OCR records stay `status: candidate` and `quality: ocr_unreviewed`. Confidence measures the engine's certainty, not accuracy; the review queue is the authority.
