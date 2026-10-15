# The masāʾil of a matn (lane F)

The `abwab` segmenter cuts a matn into kitāb › bāb › faṣl units, and the R2 sample cites those
units' records. This step splits each unit into its masāʾil, so that each masʾala can be annotated
against the bank's readings and aligned with other works. Two Ḥanbalī mutūn are opted in: *ʿUmdat
al-Fiqh* and *Zād al-Mustaqniʿ*. Their bāb records and records files are unchanged.

## The unit

In the OpenITI mARkdown witness a **masʾala is a paragraph**: a body line beginning with `# ` (not
a `### ` heading), together with the `~~` lines that continue it. Lines are cleaned and pages closed
as in `qa._lines`, so a page marker closes the page it follows. `abwab.segment_masail` walks the same
lines as `abwab.segment_abwab` and returns the same units, so every paragraph sits in exactly one
unit: the one it is printed in. Each unit is returned with:

- its opening line: the heading, or the body «فصل» line that opens a faṣl. This line is not a masʾala.
- its paragraphs, in text order.
- its loose lines: `~~` lines that come before the unit's first paragraph.

The unit's text is exactly its opening line, its loose lines and its paragraphs, joined in that
order. `test_the_units_are_those_of_segment_abwab_and_their_text_is_covered_exactly` checks this, so
no text is lost.

## Records and ids

`units.paragraph_records` turns paragraphs into `masala` records, written to
`corpus/records/<witness>.masail.jsonl`. Each record is a child of its bāb record:

- `id` is `<bāb record id>.p<NN>`, numbered from `p01` within the bāb in text order, counting kept
  paragraphs only.
- `bab` is the parent bāb's id. `heading_ar` and `path_ar` are copied from the parent.
- The locator is anchored at the paragraph's first page, with the tag `b<NNNNN>.p<NN>`.
- `page_span`, `excerpt_ar` (within the work's `EXCERPT_LEN`) and `sha256` (of the full paragraph
  text) are set as for the other unit records.
- `status` is `candidate`, and the extraction method is `abwab_paragraphs`.

A work opts in through its registry segmenter, `{"kind": "abwab", "paragraphs": true}`. The `abwab`
cut ignores the flag, so the bāb records still replay unchanged. `python -m usul_corpus build` also
writes the masāʾil file and an audit entry `<witness>#masail` in `corpus/audit.json`. The obligation
inventory `corpus/worklists/units.json` gives each opted-in witness a second row, of kind
`abwab_paragraphs`. The bāb rows are unchanged.

## What is not a record, and the audit

A paragraph is reported in the audit, with its bāb id and its position in the bāb, instead of
becoming a record when it is one of these:

- **A duplicate**: its Arabic letters (`arabic.letters`) equal those of an earlier paragraph in the
  witness. The first occurrence is kept, and the audit names the id of the record it duplicates. No
  two masʾala records of a witness share letters.
- **A title**: a body line beginning with «كتاب» or «باب», which is a heading printed as a body line
  («# كتاب الصلاة» after «### | كتاب الصلاة»). In both witnesses every such line is a short title.
- **No letters**: a paragraph with no Arabic letters, such as the editor's «...», a stray footnote
  number «1», or «No pages».

Loose lines are also reported in the audit. The audit lists `page_break_candidates` as well: kept
masāʾil that open on a later page than the previous paragraph of their unit, where that previous
paragraph ends without terminal punctuation. Shamela starts a new `# ` line at a page break, so such
a masʾala may be the second half of one sentence («… ويعم بدنه غسلا ثلاثا PageV01P032» / «ويدلكه
ويتيامن …»). The list is a review hint only. Paragraphs are not joined on that guess.

## Counts

| | ʿUmda | Zād |
|---|---:|---:|
| units (bāb records) | 207 | 286 |
| paragraphs | 891 | 1,220 |
| masʾala records (kept) | 831 | 1,166 |
| duplicates dropped | 3 | 1 |
| titles | 25 | 23 |
| without letters | 32 | 30 |
| loose lines | 1 | 0 |
| page-break candidates | 39 | 101 |

The unit inventory grows by these 1,997 records, from 48,510 to 50,507 obligations.

Both witnesses repeat page markers: ʿUmda has 284 markers for 129 pages, and Zād has 327 for 225.
Shamela closes a page again at every chapter boundary on it. This repeats markers, not text: few
paragraphs repeat.

- **ʿUmda, «باب صيام التطوع».** The witness prints the start of p. 42 twice. The abwab segmenter
  therefore emits two bāb records with this heading. `b00040` holds the bāb's first two paragraphs,
  and `b00041` repeats them before continuing. The two repeats are dropped, so `b00041.p01` is
  «ونهى رسول الله …».
- **ʿUmda, «وهي نوعان:».** A short opener in `b00199` coincides letter for letter with `b00190.p01`.
  It is a different masʾala, but it is dropped under the letters rule.
- **Zād, «باب بيع الأصول والثمار».** The start of p. 109 is printed first at the end of `b00088`: a
  body-line copy of the title, then the bāb's first paragraph. It is printed again under the
  heading. The first occurrence (`b00088.p04`) is kept, so that paragraph sits under the preceding
  unit (a faṣl). Its repeat, `b00089`'s first paragraph, is dropped.
- **ʿUmda, `b00206`.** A `~~` continuation line begins with the verb «فصل» («وإن فصل بينهما
  بسكوت …»), so `abwab` opens a spurious faṣl in the middle of a sentence of `b00205`. That line is
  the unit's opening line, and the rest of the sentence is the witness's one loose line. The bāb
  records are left as they are.

No bāb record duplicates another's letters.

## Replay

`pipeline/tests/test_masail.py` replays both witnesses from the locked bytes. It checks that the
masāʾil files and their audit entries are reproduced byte for byte, that every parent bāb exists,
that no two masāʾil share letters, and that each bāb's text is covered by its masāʾil plus what the
audit reports. Without the cached witness bytes, the replay tests skip with that reason.
