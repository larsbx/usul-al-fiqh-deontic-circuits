# Evidence-linked semantic tagging: development boundary

The oracle's label triage cannot establish that a ruling concerns the act asked
about. This prototype establishes the interface for annotating acts, actors,
objects, affected parties, conditions, exceptions, negation, omission, time and
scope before mapping them into the bank's typed inputs.

`pipeline/usul_corpus/semantic_tags.py` builds a candidate workset from the 53
distinct questions behind the existing 123 IslamQA cases. It reads title and
question only. Existing encoder labels are stored separately as development
references and never enter the tagger. The complete Arabic archive must match
SHA-256 `621fcd30c854a45407a5c303de8656c402eab4c59abde884a06038348ffbb205`
and 54,803,328 bytes before generation.

Each proposed span records its source ID, exact text hash, Unicode character
offsets and verbatim quote. Literal Arabic condition, exception, negation,
omission and time markers supply annotation aids. They do not resolve meaning,
scope or semantic roles: all role values remain explicitly unknown. No encoder
fact is inferred and no kernel is executed during workset generation.

`admit` accepts explicitly supplied fact observations for one encoder. It
rejects wrong types (including integers passed as Boolean values), invalid
domains, duplicate fields, altered evidence and cross-question spans. Missing,
unknown and candidate facts hold execution. A complete reviewed map can execute
the existing Python mirror and produces its Lean expression, with status
`candidate_kernel_result`. Output types belong to the encoder: a Boolean result
must not be presented as a five-valued hukm.

Review status is caller-attested, with a required review evidence locator. This
API checks integrity and completeness, not semantic entailment, authentication
of a reviewer, or proof acceptance. A correct quote can still support an incorrect
interpretation. No real observation in the workset has been promoted to reviewed.
The existing scholarly and formal acceptance gates remain necessary.

## Reproduce

From the repository root with the pinned Arabic archive materialized:

```sh
PYTHONPATH=pipeline python -m usul_corpus.semantic_tags . corpus/fatawa/semantic-tags-development.json
PYTHONPATH=pipeline python -m usul_corpus.semantic_tags . corpus/fatawa/semantic-tags-development.json --check
PYTHONPATH=pipeline python -m usul_corpus.semantic_propositions .
PYTHONPATH=pipeline python -m usul_corpus.semantic_propositions . --check
PYTHONPATH=pipeline python -m pytest pipeline/tests/test_semantic_tags.py pipeline/tests/test_semantic_propositions.py pipeline/tests/test_bank_review.py pipeline/tests/test_oracle.py -q
```

Development generation and deterministic checking were run against the recovered
archive on 2026-10-14. The focused suite passed 58 tests. No new tagging accuracy,
encoder accuracy or legal accuracy is reported. Tests exercise the boundary with
synthetic observations; they do not validate Arabic semantic interpretation.

## First authored proposition batch

The first batch in `corpus/fatawa/semantic-propositions-development.json`
contained LLM-authored, purposively selected annotations for 12 of the 53 questions: 21
act-relative propositions, 72 candidate roles and 13 proposed bank mappings.
Eighteen propositions are asserted; one each is hypothetical, questioned and
uncertain. Polarity is recorded separately. Exact evidence for every role and
proposed fact must lie inside its proposition's span and the question body.
Editorial titles are excluded from factual evidence; answer text is unused.

The validator rejects cross-proposition fact pooling, out-of-scope evidence,
claimed review status and factual bindings from non-asserted or negative
propositions. These structural checks do not establish that the authored actor,
scope or interpretation is correct. Unspecified conditions stay unknown.

That batch supplied one candidate field value: `trust_loss.hand = trustee` for
the explicit entrustment in question 4652. All 13 initial mappings remain on hold.
These original 12 records are preserved unchanged in the expanded workset.

The batch exposes distinctions that literal matching must preserve:

- In 4588, four years of possession does not establish `luqata.year_passed`,
  which requires a year of announcement. The field remains unknown.
- In 104241, inability to return money does not establish an unidentified owner.
- In 305083, the other driver's collision, the questioner's denial of contact,
  and the assumed death are separate propositions.
- In 83827, lack of consultation alone does not establish lack of permission.

## Remaining-question candidate pass (2026-10-19)

The pinned archive was materialized and verified again at 54,803,328 bytes and
the SHA-256 above. Direct reading of its question bodies adds the remaining 41
question IDs: 344 propositions, 1,001 candidate roles and 45 proposed bank
mappings. The generated report now records:

| Development quantity | Total |
|---|---:|
| Questions with candidate annotations | 53 / 53 |
| Act-relative propositions | 365 |
| Candidate roles | 1,074 |
| Asserted / hypothetical / questioned / uncertain propositions | 248 / 18 / 73 / 26 |
| Proposed bank mappings, all on hold | 58 |
| Candidate typed fact bindings, all unreviewed | 2 |
| New kernel executions | 0 |
| Semantic accuracy / retrieval improvement | Unmeasured |

The additional candidate binding is `trust_loss.hand = trustee` for the explicit
entrustment in question 152192. It does not establish negligence, transgression,
or permission to destroy the entrusted book. Together with question 4652, these
are the only proposed non-null typed values; neither has been promoted.

Each new record has a `review_note` identifying unresolved scope or interpretation
issues. These notes are advisory, not review receipts. An `asserted` proposition
records what the question narrates, including attributed speech or reports; it
does not independently authenticate a medical report, police assessment, contract
description or claimed legal consequence. Intentions and requests remain distinct
from completion of the contemplated act. Hypothetical outcomes and disputed or
remembered events retain their conditions and uncertainty.

Examples requiring independent interpretation:

- Question 13717 asks only for deposit rules; it supplies no concrete deposit or
  loss event and has no bank mapping.
- Questions 131070 and 146191 report a general buried-treasure scenario. They are
  kept as separate source IDs and are not forced into the lost-property encoder.
- Question 209303 reports two months of announcement; neither that duration nor
  an intention to announce for a year establishes a completed announcement year.
- Questions 165409 and 286486 ask about financial arrangements and interest;
  asking how to dispose of money does not alone justify an unknown-owner mapping.
- Question 198294 preserves the wife's suspicion and the husband's denial;
  her stated 99-percent confidence is not converted into a reviewed epistemic grade.
- Questions 315435, 317604, 348122 and 363963 distinguish collision or fall,
  injuries, subsequent death, uncertain causes and attributed reports. Sequence
  does not establish legal causation, negligence or liability.

All evidence is checked against exact question-body spans in the verified archive.
The unchanged workset and regenerated proposition report pass both deterministic
`--check` commands. The 58 focused tests pass, including a full-workset guard that
fails if any development mapping calls an executable mirror. `make validate`
also passes for the registry, 52,637 corpus records, signature map and M5 receipts.
These tests validate source integrity, schema and admission boundaries, not Arabic
interpretation.

All 53 question IDs now have an initial candidate pass. This is not a claim of
exhaustive segmentation, reviewed interpretations, independent gold labels or an
automatic semantic tagger. The initial 12 records still need the same review as
the new 41. All subcases of a question must remain together in later evaluation;
near-duplicate questions also require leakage review before any split is frozen.

## PR #110 scope correction

For question 128887, `p1` still asserts only the performed farewell
circumambulation, with its act evidence unchanged at `[177,208)`. Its enclosing
scope now extends to `[177,635)` to include the questioner's reported uncertainty
about major ritual impurity and possible semen marks. A candidate condition role
cites the exact body spans of `p3`, `p4` and `p6`, explicitly as uncertainty.
The wider scope does not merge those propositions: their uncertain modalities,
prior purity, inspection, omitted washing and other rites remain separate and
unchanged. All three `doubt_in_condition` typed fields remain unknown.

This adds one candidate role (1,074 total) without adding propositions, typed
values or kernel executions. The focused regression exercises in-scope candidate
fact probes on a copy solely to test structure, rejects the old narrow scope,
and still rejects factual bindings from the separate uncertain propositions.
Probe values are not annotations or entailment findings. A source-backed test
also replays both deterministic artifacts against the pinned archive when
materialized; CI requires that archive and fails if it is unavailable.

## Next obligation

Independently audit act-relative propositions, segmentation completeness and their
scopes across all 53 development questions, preserving distinct subcases and
correcting candidate interpretations where necessary. Add field-specific
entailment checks and reviewed evidence before admitting fact values. Only then
evaluate tag accuracy, typed fact accuracy, encoder retrieval and kernel agreement
separately. Freeze a different question-held-out modern set before tuning; these
published cases are development data and cannot be a fresh blind test.
