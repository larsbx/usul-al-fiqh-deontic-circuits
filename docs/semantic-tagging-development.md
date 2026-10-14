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
PYTHONPATH=pipeline python -m pytest pipeline/tests/test_semantic_tags.py pipeline/tests/test_bank_review.py pipeline/tests/test_oracle.py -q
```

Development generation and deterministic checking were run against the recovered
archive on 2026-10-14. The focused suite passed 48 tests. No new tagging accuracy,
encoder accuracy or legal accuracy is reported. Tests exercise the boundary with
synthetic observations; they do not validate Arabic semantic interpretation.

## Next obligation

Annotate complete act-relative propositions and their scopes on this development
workset, preserving distinct subcases of each question. Add field-specific
entailment checks and reviewed evidence before admitting fact values. Only then
evaluate tag accuracy, typed fact accuracy, encoder retrieval and kernel agreement
separately. Freeze a different question-held-out modern set before tuning; these
published cases are development data and cannot be a fresh blind test.
