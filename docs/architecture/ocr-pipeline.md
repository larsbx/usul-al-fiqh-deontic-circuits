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
| Rule headings (chain) | `segment.segment_lines` | Accepts «القاعدة <ordinal>» or a bare ordinal line, because the edition sets the word «القاعدة» as a graphic that OCR turns into junk. Joint headings («الثانية والثالثة والعشرون») cover a range of rules. The longest chain with steps of 1 to 4, with at least one body line per step, drops ordinals in prose and the table of contents |
| Closing index | `segment.segment_index` | «القاعدة <ordinal>: <statement>» lines: an independent witness to the count, and each rule's statement |
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

## Results (first full run)

| Witness | Pages | Mean confidence (chosen pages) | Low-confidence lines | Model chosen per page |
|---|---|---|---|---|
| `archive-pdf1995-tess` | 176 | 79.4 | 495 / 3716 | see `corpus/ocr/archive-pdf1995-tess.json` |
| `archive-manzuma-tess` | 389 | 79.5 | 1193 / 9989 | see `corpus/ocr/archive-manzuma-tess.json` |
| `archive-tariq-tess` | 291 | 70.9 | 1210 / 6733 | see `corpus/ocr/archive-tariq-tess.json` |

**al-Saʿdī, 60 qawāʿid: confirmed.** In `corpus/audit.json`, `consensus:sadi.qawaid_jamia` is `complete: true`, so every number from 1 to 60 is attested by at least one of four witnesses. No single witness is complete:

| Witness | Missing |
|---|---|
| archive.org OCR, body | 2, 3, 12, 32, 56 |
| our OCR, body | 9, 12, 30, 31, 32 |
| archive.org OCR, index | 11, 22, 23, 31, 50 |
| our OCR, index | 22, 23, 33 |

Rules 22 and 23 share one printed heading; that is the edition, not an OCR loss.

**Manẓūma: verse count not yet established.** The archive.org OCR chain reaches verse 132 with 41 gaps. Our OCR cannot read the verse block, because the verses are vocalised two-column hemistichs inside a decorated frame and single-column layout analysis (psm 4) garbles them. The commentary text OCRs well. Next step: detect the verse frames and OCR each hemistich column separately (psm 6 or 7 on crops).

**Ṭarīq al-Wuṣūl: OCR done, not segmented.** The scan quality is lower (mean confidence 71), and no reliable heading pattern has been identified yet.
