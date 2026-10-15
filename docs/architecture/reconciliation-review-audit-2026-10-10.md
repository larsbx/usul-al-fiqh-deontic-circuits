# Reconciliation review audit — 2026-10-10

This contribution mechanically traces and triages all 48 entries in PR #47's review
queue (merge `b3c6937fda76513279c7c075d1322ceda7838bbe`). The audit base is
`3ca9fd9c0954eaad30517ab61dfb13417756ccd8`, after tranches 7 and 8: its live queue
had 54 cases. The six later additions are outside this cohort. This is candidate
evidence review; substantive scholarly adjudication remains open.

The case-by-case records are in
`corpus/reconciliation/review-audit-2026-10-10.json`: original Arabic record and
locator, unchanged original annotation (including the pre-correction note),
imported excerpts and grades, source-lock receipts, computed ruling and explicit
remaining obligation. All complete sources used by this cohort matched the
committed locks. All 359 imported excerpts in the full ledger replayed against
their locked locations. The Arabic records were preserved.

## Supported corrections

**52.f001 — source-grade error, not an automatic annotation replacement.**
Ibn al-Laḥḥām at `src:openiti-lahham-shamela8526/v01:p265#q052.f001` asks whether
the verse supports every useful unprohibited sale: the encoded True position is
universal generality. Ibn Mufliḥ (`src:openiti-ibnmuflih-sham19y122256/v03:p1011`)
and Ibn al-Najjār (`src:openiti-kawkab-shamela12019/v03:p426`) deny ijmāl.
Al-Taḥbīr (`src:openiti-tahbir-shamela6336/v06:p2772`) explicitly distinguishes
shumūl, ʿahd and genus without istighrāq as the issue. Non-ijmāl is not sufficient
to select universal scope. The adjacent Kawkab discussion at v03:p427 does explicitly
call generality the correct reading, in the quoted al-Barmawi discussion. Its
attribution and eligibility as a madhhab-marked grade remain an open question;
the correction concerns the evidence actually admitted, not an assertion that
the later work lacks support for generality. Under the documented rule for support by implication,
the two jazm imports become takhrīj. Excerpts, positions and the al-Ḥulwānī
dissent remain. Tarjīḥ still selects True with unmarked support, so it leaves
`review`; this does not establish a marked madhhab position.

**159.f035 — incorrect English annotation.** The pinned Arabic at
`src:openiti-rajab-shamela21730/v01:p338#q159.f035` makes the unknown-lineage person
the object of qadhf; the accuser alleges the accused person's slavery and the
accused denies it. The old note instead made the unknown-lineage person the
accuser. Correct the note only; retain facts, expected ruling and both riwāyas.

**Drafting — author preference is not taṣḥīḥ by itself.** Remove bare aẓhar/azhar
from the automatic taṣḥīḥ proposal and align the Lean explanatory comment with
the documented distinction. Contextual al-Mardāwī taṣḥīḥ remains a separate
manual attribution question; no blanket downgrade of Taṣḥīḥ al-Furūʿ was made.

## Substantive decisions retained

- **133.f018:** the full Ibn Rajab witness continues beyond the stored excerpt
  and attributes qiyās al-madhhab to al-Talkhīṣ. This makes the claim that nothing
  is marked under the reconciliation convention questionable, while al-Mubdiʿ
  (`v08:p374`) and al-Kāfī (`v04:p316`) support lineage/inheritance, opposed by
  al-Inṣāf (`v07:p340`) and Sharḥ al-Muntahā (`v02:p545`). Resolve the marker
  policy and authority/chronology question separately; preserve all four imports.
- **133.f019:** the original assigns ʿiddas after the wife is selected by lot;
  imported material describes death before determination/lot. Check the time
  condition before treating both as a single Boolean disagreement. The source
  locators and excerpts for each version remain in the audit record.
- **75.f005:** Aḥmad's original text gives recourse against bayt al-māl. Evidence
  denying recourse against the foundling may concern a different debtor. The
  Boolean output loses that distinction; do not replace the original naṣṣ.
- **159.f021:** Taṣḥīḥ al-Furūʿ (`v01:p092`) prefers impurity, whereas al-Iqnāʿ
  (`v01:p011`), Kashshāf (`v01:p047`) and Sharḥ al-Muntahā (`v01:p026`) retain
  purity. The formal ranking selects one candidate; it cannot decide which
  authority should control an accepted madhhab report.
- **31.f004, 75.f007:** original ẓāhir/naṣṣ are marked in the ranking convention
  but the annotations decline an independent madhhab preference. The two uses
  of “marked” require an explicit scope decision, not a generated relabelling.

For the remaining source-scope cases, the original annotation can correctly
record that its paragraph lacks an independently accepted preference while later
material supplies a stronger candidate. The audit proposes retention, with each
original holder, imported locator and note available for substantive review.

## Validation contract

Locked replay is `make source-verify` (`usul_corpus.source_verify`, merged as PR-06), which
supersedes this audit's own `reconcile --verify-source`: it fails on absent caches, full-source
hash drift and wrong excerpt locations, restores missing witnesses without repinning, and runs in
hosted CI before the generated checks. Regression controls cover generality versus non-ijmāl, author preference,
preservation of all 48 audit originals
and the corrected qadhf roles. Generated Lean guards and reports remain aligned
with Python; compilation checks the admitted grades, not their scholarly truth.

After the correction: 144 entries; 15 jamʿ, 121 tarjīḥ, 8 tawaqquf; 61 residues;
53 live reviews. Annotation facts, rulings and matches_madhhab are unchanged.

## Original cohort inventory

Each row points to a full case record in the audit JSON; “open” concerns scholarly
adoption even where the narrow mechanical correction has been applied.

| Case | Triage | Original locator |
|---|---|---|
| q052.f001 | source_grade_error | `src:openiti-lahham-shamela8526/v01:p265#q052.f001` |
| q052.f006 | source_scope_difference | `src:openiti-lahham-shamela8526/v01:p265#q052.f006` |
| q001.f003 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p003#q001.f003` |
| q007.f001 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p009#q007.f001` |
| q008.f003 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p010#q008.f003` |
| q016.f006 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p020#q016.f006` |
| q017.f005 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p022#q017.f005` |
| q018.f004 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p023#q018.f004` |
| q018.f005 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p023#q018.f005` |
| q018.f010 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p023#q018.f010` |
| q018.f011 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p023#q018.f011` |
| q018.f014 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p023#q018.f014` |
| q021.f001 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p028#q021.f001` |
| q021.f002 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p028#q021.f002` |
| q022.f001 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p029#q022.f001` |
| q024.f003 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p033#q024.f003` |
| q024.f004 | position_ambiguity | `src:openiti-rajab-shamela21730/v01:p033#q024.f004` |
| q024.f007 | position_ambiguity | `src:openiti-rajab-shamela21730/v01:p033#q024.f007` |
| q027.f002 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p037#q027.f002` |
| q029.f001 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p039#q029.f001` |
| q031.f004 | annotation_marker_ambiguity | `src:openiti-rajab-shamela21730/v01:p040#q031.f004` |
| q038.f002 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p048#q038.f002` |
| q038.f005 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p048#q038.f005` |
| q038.f006 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p048#q038.f006` |
| q039.f001 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p049#q039.f001` |
| q041.f001 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p053#q041.f001` |
| q041.f002 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p053#q041.f002` |
| q065.f001 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p117#q065.f001` |
| q065.f005 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p117#q065.f005` |
| q065.f007 | position_ambiguity | `src:openiti-rajab-shamela21730/v01:p117#q065.f007` |
| q068.f007 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p120#q068.f007` |
| q075.f001 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p137#q075.f001` |
| q075.f005 | position_ambiguity | `src:openiti-rajab-shamela21730/v01:p137#q075.f005` |
| q075.f007 | annotation_marker_ambiguity | `src:openiti-rajab-shamela21730/v01:p137#q075.f007` |
| q075.f009 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p137#q075.f009` |
| q075.f011 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p137#q075.f011` |
| q075.f012 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p137#q075.f012` |
| q076.f003 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p142#q076.f003` |
| q133.f006 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p298#q133.f006` |
| q133.f010 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p298#q133.f010` |
| q133.f018 | source_conflict | `src:openiti-rajab-shamela21730/v01:p298#q133.f018` |
| q133.f019 | position_ambiguity | `src:openiti-rajab-shamela21730/v01:p298#q133.f019` |
| q159.f021 | source_conflict | `src:openiti-rajab-shamela21730/v01:p338#q159.f021` |
| q159.f031 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p338#q159.f031` |
| q159.f035 | incorrect_annotation_note | `src:openiti-rajab-shamela21730/v01:p338#q159.f035` |
| q159.f039 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p338#q159.f039` |
| q160.f009 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p348#q160.f009` |
| q160.f019 | source_scope_difference | `src:openiti-rajab-shamela21730/v01:p348#q160.f019` |
