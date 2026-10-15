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

- **A title**: a body line beginning with «كتاب» or «باب», which is a heading printed as a body line
  («# كتاب الصلاة» after «### | كتاب الصلاة»). In both witnesses every such line is a short title.
- **No letters**: a paragraph with no Arabic letters, such as the editor's «...», a stray footnote
  number «1», or «No pages».

Loose lines are also reported in the audit. The audit lists `page_break_candidates` as well: kept
masāʾil that open on a later page than the previous paragraph of their unit, where that previous
paragraph ends without terminal punctuation. Shamela starts a new `# ` line at a page break, so such
a masʾala may be the second half of one sentence («… ويعم بدنه غسلا ثلاثا PageV01P032» / «ويدلكه
ويتيامن …»). The list is a review hint only. Paragraphs are not joined on that guess.

## Occurrence identity and corrected attribution

Equal Arabic letters do not establish duplication. Every occurrence is retained, including two
occurrences within one bāb or on the same page. The record id identifies the occurrence; `sha256`
identifies its text and may repeat. The audit's `duplicates` list is retained for compatibility
but is empty: no source occurrence is discarded on textual equality.

A body title matching the immediately following unit's heading on the same page assigns subsequent
paragraphs to that unit. The existing bāb records remain unchanged. Each moved occurrence is recorded
in `reattributions` with its original bāb and paragraph index, destination record, page span, and
reason. A similar title on another page does not authorize reassignment.

This restores «وهي نوعان» in ʿUmda's `b00199`, independently of `b00190`. It also retains both printed
sale passages in Zād under `b00089`; the copy formerly called `b00088.p04` becomes `b00089.p01`, and
the occurrence beneath the explicit heading becomes `b00089.p02`. Two repeated paragraphs in
ʿUmda's `b00041` are retained as independent source occurrences. None of the pilot's annotated
paragraph ids changes.

## Counts

| | ʿUmda | Zād |
|---|---:|---:|
| units (bāb records) | 207 | 286 |
| paragraphs | 891 | 1,220 |
| masʾala records | 834 | 1,167 |
| duplicates dropped | 0 | 0 |
| titles | 25 | 23 |
| without letters | 32 | 30 |
| loose lines | 1 | 0 |
| reassigned occurrences | 0 | 1 |

These figures are regenerated from the locked witnesses in `corpus/audit.json`; the obligation
inventory is generated in `corpus/worklists/units.json`.

## Replay

`pipeline/tests/test_masail.py` checks the two witnesses' records and audits byte for byte and
accounts for every source occurrence exactly once, including the audited attribution change.
`test_pr86_integrity.py` covers repeated text within and across bābs, the copied sale passage,
and false disagreement obligations. Source replay still needs the pinned witness bytes.
