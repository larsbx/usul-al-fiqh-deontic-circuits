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
| Frame crop | `ocr.frame_box`, `ocr.prepare` | Applies to books with a decorative page border (*Ṭarīq al-Wuṣūl*). Within the outer 12% of each side, the innermost band of at least 25 consecutive rows or columns with at least 25% ink is the border; dips of up to 5 px are bridged, because zigzag bands dip. The page is cropped 20 px inside it, and pages without a frame keep their full extent. Text columns measure at most about 0.1 ink, border bands 0.3–0.45 |
| Denoise | `ocr.prepare` (`"denoise": "median3"`) | A 3×3 median filter against scanner speckle on a grey background. On *Ṭarīq al-Wuṣūl* p. 29 it lifts mean confidence from 57 to 85 and cuts low-confidence words from 164 to 31; plain thresholding does not help |
| Line assembly | `ocr.parse_tsv` | Groups words by (block, paragraph, line). Tesseract's word order is logical (right-to-left reading order). Line confidence is the mean of its word confidences |
| Normalisation | `ocr.clean_line` | Applies NFKC (presentation forms to letters), maps Persian lookalikes (ی→ي, ک→ك, ہ→ه) and removes bidi marks. A «»» glued to a word with no matching «« on the line becomes the Arabic comma. Real orthography such as final hamza is never touched |
| Noise filter | `ocr.is_noise` | Drops a line with fewer than 3 Arabic letters or an Arabic share below 50% (rules, footnote debris, folio numbers) |
| Model choice | `ocr.choose` | The two models fail on different pages. Per page, the higher mean confidence wins and the choice is recorded |
| Running heads | `ocr.strip_running_heads` | Drops a line that recurs verbatim on at least 20% of pages |
| Rule headings (chain) | `segment.segment_lines` | Accepts «القاعدة <ordinal>» or a bare ordinal line, because the edition sets the word «القاعدة» as a graphic that OCR turns into junk. Joint headings («الثانية والثالثة والعشرون») cover a range of rules. The longest chain with steps of 1 to 4, with at least one body line per step, drops ordinals in prose and the table of contents |
| Closing index | `segment.segment_index` | «القاعدة <ordinal>: <statement>» lines: an independent witness to the count, and each rule's statement |
| Verse numbers | `segment.segment_numbered` | «١ - …», «۹۔ …». A dynamic programme finds the longest numbering chain with steps of 1 to 3. Footnotes «(١)» never match. OCR that dropped a leading digit (10 read as «۰») is repaired to the smallest consistent value and flagged `ocr_corrected` |
| Verse lines | `verses.is_verse`, `verses.ocr_verses` | A bayt is printed as one line whose two hemistichs are separated by a wide, roughly central gap. The test: the line spans at least 80% of the text width, its widest internal gap is 4–25% of its width, and the gap starts 30–70% of the way across. Justified prose has only word gaps (about 35 px at 300 dpi, against about 120 px between hemistichs). Each hemistich is cropped and OCR'd as a single line (psm 7) with both models, keeping the better read. The verse replaces the page-level lines it overlaps (`merge_verses`). Hemistichs are joined with « * » |
| Verse numbering | `verses.segment_verse_block` | The longest contiguous block of verse lines (the matn) is numbered by position; shorter blocks such as gapped front-matter lines are ignored. Verse lines are lines carrying our « * » separator, or page-level lines where tesseract kept the gap as «|» with at least two Arabic words on each side. The bold printed number defeats tesseract even when cropped alone, so it serves only as a check: a unit is flagged `ocr_corrected` unless its readable printed digits agree with its position |
| Commentary links | `verses.link_commentary` | In a sharḥ, each verse quotation after the matn is matched to its matn verse by character-trigram Jaccard similarity, after normalisation. On this book genuine quotations score at least 0.3 (mostly 0.7–1.0), while other poems, the table of contents and prose score 0.2 or below. The longest increasing chain is kept, the first quotation opening each verse's commentary, which runs to the next linked quotation and stops at the index («فهرس»). Output: `sharh` records linking each commentary to its `bayt` record |
| Cross-check | `segment.consensus_numbering` | For a work with several witnesses (archive.org OCR and our OCR), lists which witness found each rule number and which numbers no witness found. Numbers above the expected count are reported separately as `beyond_expected`: they are a witness's errors, not evidence about the count |

## Witnesses

| Work | Witnesses | Segmenter |
|---|---|---|
| al-Saʿdī, *al-Qawāʿid al-Jāmiʿa* | `archive-pdf1995` (archive.org OCR), `archive-pdf1995-tess` (this pipeline) | `lines` on «القاعدة» |
| Ibn ʿUthaymīn, *Sharḥ Manẓūmat Uṣūl al-Fiqh* | `archive-manzuma-tess` (our OCR, verse reader on PDF pp. 1–371), `archive-manzuma-djvu` (archive.org OCR) | `verse_block`; the archive.org witness overrides to `numbered` |
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

**Manẓūma: 103 verses.** Three independent observations agree:

1. The printed matn ends at «١٠٣», followed by its closing ornament (PDF p. 27).
2. The author's handwritten autograph, reproduced in facsimile on PDF p. 22, also ends at «١٠٣».
3. Verse-line detection finds exactly 103 verse lines in the matn block (PDF pp. 23–27: 16 + 24 + 24 + 24 + 15).

**Commentary: 102 of 103 verses linked** (minimum similarity 0.30). Verse 60's quotation was not recovered by OCR, so its commentary currently runs inside verse 59's. Each `sharh` record carries the page span, the quoted verse and a capped excerpt.

The pipeline reproduces this. `archive-manzuma-tess` yields verses 1 to 103 with no gaps, and `matches_expected` is true. 27 of the 103 printed numbers were readable and every one agrees with its position; the other 76 are numbered from position and flagged `ocr_corrected`. The archive.org OCR chain, which reached 132, was an overshoot of the digit repair. Its numbers above 103 appear under `beyond_expected`, and `consensus:ibn_uthaymin.manzuma` is `complete: true`. Elsewhere in the book, the commentary (pp. 29–371) holds 136 verse-shaped lines. That count is higher because each verse is re-quoted, sometimes more than once, and other poems are quoted in the same two-hemistich layout. The two-column index (pp. 372–389) is excluded through `verse_pages`, since its column gutter imitates a hemistich gap.

**Ṭarīq al-Wuṣūl: OCR done, not segmented.** The scan quality is lower (mean confidence 71), and no reliable heading pattern has been identified yet.
