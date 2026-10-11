# Candidate type-aware routing: bounded classical experiment

Baseline snapshot: `cdebdb7a49642082ba39a191b7b707dcef44080b` (PR #59).
The original `corpus/routing/index.json`, `ood.json`, annotations, encoders and
scholarly review gates are unchanged. This experiment is **candidate** retrieval;
it does not compute a ruling, select a binding reading, or promote evidence.

## What can be extracted

The executable encoder registry ties fact dictionaries to Lean expression templates
and Python mirrors. Inspection of `Usul/Signature.lean` confirms Boolean capacities,
finite epistemic grades, domain sorts and explicit preconditions; the encoder
adapters expose Boolean and finite-enumeration domains, including integer outputs
and input alternatives. The registry at this snapshot actually has **104** encoder
entries (the roadmap's 100 is historical); this evaluation ranks all 104 profiles.
The generated report preserves every input domain verbatim and identifies field
coverage. There are 483 evaluable classical cases; 476 have nonempty fact annotations.

Fact-field names and admissible values are reliable **schema** features. Truth values
such as necessity, negligence, permission, the presence of a legal indicator, or
epistemic grade cannot reliably be inferred merely because a question mentions a
related word. No factual truth values are inferred here. No encoder mirror or Lean
ruling computation is called by routing.

`typed_routing.Model` learns field relevance from the classical annotated cases:
each fact key receives a TF-IDF centroid of texts carrying that key. A query yields
a soft vector of field relevance; cosine similarity against each encoder's declared
field signature supplies the structural score. Field weights downweight keys shared
by many encoders. This is a **lexical proxy for structural relevance**, not a semantic
parser or verified extraction of facts. Shared signatures remain indistinguishable,
unannotated fields cannot be learned, and word-level transfer problems remain.
The full classical detector learns 139 of 144 declared field names.

For explicitly supplied partial observations, `compatible` checks exact Python
types and domain membership (so `1` does not masquerade as `True`). `Model.rank`
can filter by these observations. Missing fields remain unknown; an extra field
means this encoder does not consume that observation, not that its ruling is false.
This manual observation path is not used in the text-only recall evaluation:
feeding test annotations' field names or values would leak the target signature.

## Evaluation and measured failure

Outer folds are the original SHA-256 record-id folds, grouping all annotations of
the same record. Each field detector and lexical model trains without that fold.
Qawāʿid remain in lexical training exactly as in the original baseline; related
qāʿida context can cross folds, so this is record-held-out, not source-held-out.
The structural detector uses only training case annotations, never test field keys.
The field learning has no modern-question annotations or modern tuning.

Hybrid scores are `(1 - weight) * lexical + weight * signature`. Inner record-grouped
folds select from `0, .25, .5, 1` using recall@5, then recall@1, then lower weight.
Each outer fold selects zero; fitting on all classical cases also selects zero.
Selection does not use outer test labels or the published modern labels.

| Method / structural weight | Top-1 | Top-5 | Top-10 |
|---|---:|---:|---:|
| Original lexical / 0 | 61.49% | 85.30% | 90.68% |
| Fixed hybrid / .25 | 60.46% | 84.27% | 88.20% |
| Fixed hybrid / .5 | 55.28% | 79.71% | 86.34% |
| Signature relevance alone / 1 | 50.52% | 73.71% | 79.92% |
| Nested-selected hybrid | 61.49% | 85.30% | 90.68% |

These are empirical retrieval scores, not legal accuracy. No improvement is
demonstrated: the pure signature proxy loses 11.80 percentage points at top-5;
even the smallest nonzero weight loses 1.03 points. The selected hybrid changes
no top-k retrieval result. The report includes per-case top-ten rankings for
lexical, structural and selected hybrid methods, enabling failure inspection.
The safe conclusion is to retain lexical retrieval while developing better,
reviewed structural extraction rather than increase this proxy's weight.

## Original OOD remains blocked

The original 123-case IslamQA evaluation is preserved, with committed lexical
recall 8.94% / 29.27% / 34.96%. Its Arabic question file is only a 133-byte Git LFS
pointer in the accessible checkouts, naming SHA-256
`621fcd30c854a45407a5c303de8656c402eab4c59abde884a06038348ffbb205`
and 54,803,328 bytes. The generated partial report explicitly has
`blocked_missing_questions`, zero evaluated modern cases, and empty new recall
metrics. It embeds the original report with its original denominator; those
historical numbers are not represented as a local replay.

Once the pinned file is available, the default evaluation uses the original
title-plus-question inputs and all 123 annotations. It fails on missing questions
or failure to reproduce the original lexical metrics before reporting new ones.
It hashes the exact selected question texts and all committed training inputs.
The published OOD set is not a new blind test. Future modern training requires
new provenance-linked candidate annotations split by question ID (including all
subcases), with a frozen held-out modern set separated before tuning. Original
tranche labels must not be used to tune this model.

## Bāb assignments and review

The report lists the five candidate bābs per encoder under lexical and selected
hybrid scoring. Zero assignments change because the selected weight is zero.
There are no reviewed encoder-to-bāb gold labels in the routing evidence, so
accuracy is explicitly null. Candidate proximity is not validated assignment.
No source record, worklist ownership, source receipt, annotation class, review
status or legal evidence attribution changes.

## Reproduce

From the repository root:

```sh
PYTHONPATH=pipeline python -m usul_corpus.typed_routing . --classical-only
PYTHONPATH=pipeline python -m usul_corpus.typed_routing . --classical-only --check
PYTHONPATH=pipeline python -m pytest pipeline/tests/test_typed_routing.py pipeline/tests/test_routing.py -q
```

For the full original OOD comparison, materialize the pinned Arabic answers at
`data/islamqa/answers/islamqa-ar.jsonl.gz` and run without `--classical-only`.
Review the resulting report before replacing the explicitly partial artifact.
Regressions cover strict types, unknown fields, held-out field isolation,
lexical equivalence at zero weight, conservative selection on ties, deterministic
classical replay and preservation of the original OOD report.
