# IslamQA itlāf routing audit — 20 October 2026

Status: **candidate, source-checked, not human-reviewed**. The targeted corrections
are **unblinded development work**, not a new blind accuracy measurement.

Baseline: main at `1b33a22cb90a22ec33c92a8c80b1966ff6bb4764` (PR #114).
All 53 answers, 123 cases and 223 encoders remain in the evaluation. The original
blind situations, canonical sources, takhrīj annotations, qawāʿid bindings,
semantic annotations, Lean/Prolog rules and hybrid ranking function are unchanged.

## Finding

The 25 null ranks are **zero type-coverage ranks**, not absent hybrid results.
They belong to 27 itlaf cases in 14 answers; the two non-null controls are the
two cases of 344230. Every one of the 27 was already a `missing_fact` or
`missing_rule` annotation, with no executable facts or expected result.
Thus the historical encoder label records a rule examined during gap triage.
It is not evidence that this rule is an appropriate complete target.

The existing qāʿida metric has another qualification: `mahall.links` supplies
classical bank links, and the IslamQA units fall back to the examined encoder's
qawāʿid. For itlaf this is al-Saʿdī Q13/Q36. The score does **not** automatically
treat a named missing rule such as Q127 as a correct alternative. The enriched
report exposes the gold set and its basis per row. Neither gold is rewritten.

## Source and type checks

The canonical archive's SHA-256 is checked against
`signature_routing.ANSWERS_SHA256`. Each audit case carries a short verbatim
answer receipt and a hash of its canonical record. Withdrawal receipts replay
against the question/answer, with the old value and old evidence checked exactly.

The declared type contracts explain the principal gaps:

- `Purpose` has only `benefit` and `repelHarm`; a traffic accident has no
  automatically inferable value. A useful journey or medical treatment is not
  the purpose of destroying the damaged thing.
- `MentalState` has deliberate, ignorant and forgetful, not accidental.
  Neither accident nor absence of an explicit intent justifies fabricating one.
  Ignorance of liability is explicitly present in 344230 and remains recorded.
- `itlaf` reads both purpose and mental state. It does not read fault,
  avoidability, medical skill, causal consequence, shared-fault fractions, or
  employment role. Changing its rank cannot supply those conditions.
- `transgressed` and `negligent` belong to Amana: trusteeship and safekeeping.
  The anchors explicitly say “the trustee” and “its safekeeping”.
  General road/medical injury does not establish this scoped field.
- `mubashara_tasabbub` reads arising-from-cause and direct-actor transgression.
  Merely naming it, stating that harm occurred, or knowing the liability outcome
  does not settle its inputs or its exceptions.

The 25 type-unrouted cases divide into **10 encoder-field coverage gaps** and
**15 legitimate mismatches with the purpose encoder**. Some also contain
incorrectly scoped candidate facts. These categories explain the failure of
the examined encoder; they do not certify a replacement rule.

## Applied candidate corrections

The executable withdrawal overlay is
[`islamqa_itlaf_corrections.json`](../../corpus/typing/islamqa_itlaf_corrections.json).
It withdraws 16 assignments across eight answers, leaving each field unknown:

- 14 Amana field assignments used for traffic, medical or other injury causation;
- 223512's affirmative direct-actor-transgression assignment: its cited branch
  says lack of skill **or** transgression **or** shortcoming;
- 164604's negative consent assignment: taking without permission **or**
  bumping into furniture does not establish lack of consent in every branch.

The actual safekeeping fact in 164604 is retained. Conditional statements are
not promoted to observations about the real event. No inferred opposite value,
new ruling, new constructor, gold relabelling or label-based ranking boost is
introduced. The frozen blind file remains the baseline; the overlay is executed
in a temporary Prolog situation file and affects only the explicitly labelled
audit comparison.

This audit found no source-supported missing value that would make the 25 cases
inhabit itlaf's type. It also found no evidence that a special rank boost would
be a legitimate correction. The source/encoder gap must remain visible.

## Case ledger

Each row below identifies the original cases, not just their shared answer.
The JSON audit provides separate entries, source receipts, qawāʿid targets,
before/after typed and hybrid ranks, remaining needs, and correction references
for all 27 cases.

| Answer | Case suffixes | Primary unresolved issue |
|---|---|---|
| 164604 | f002 | Accidental breakage; purpose/mental-state field coverage |
| 223512 | f001; f002 | Direct/indirect actor allocation; physician skill and causation |
| 242731 | f001 | Physician error and treatment boundary |
| 266167 | f001; f002 | Accident fault; allocation to actor rather than employer |
| 272160 | f001 | At-fault accident and depreciation |
| 286486 | f001 | Accident fault; source's additional interest question stays separate |
| 305083 | f001–f003 | Direct/indirect causation and avoidability exception |
| 315435 | f001–f002; f003 | Avoidability/fault; shared fault, diya and kaffāra allocation |
| 317604 | f001–f002 | Causation between drivers and direct-actor exception |
| 328808 | f001 | Common hired worker's special liability |
| 344230 | f001; f002 | Control: stated ignorance, but missing purpose; actor allocation |
| 345284 | f001–f002 | Traffic negligence and avoidability |
| 348122 | f001–f002; f003 | Indirect cause/transgression; causal spread of injury |
| 363963 | f001–f002; f003 | Avoidability/fault; death attributed to a separate cause |

## Before and after

Both runs use the same source corpus, ranker, gold labels and denominators.
The after column is **unblinded**, even though its inputs contain no gold labels.

| Metric (123 cases) | Frozen blind baseline | Candidate withdrawals |
|---|---:|---:|
| Hybrid encoder recall @1 | 0.5203 | 0.5203 |
| Hybrid encoder recall @5 | 0.6911 | 0.6911 |
| Hybrid encoder recall @10 | 0.7236 | 0.7236 |
| Hybrid qāʿida recall @1 | 0.6016 | 0.6016 |
| Hybrid qāʿida recall @5 | 0.7398 | 0.7398 |
| Hybrid qāʿida recall @10 | 0.7398 | 0.7398 |
| itlaf cases with full typed coverage | 0/27 | 0/27 |
| itlaf cases with zero typed coverage | 25/27 | 25/27 |

There is **no measured recall improvement**. Every encoder family's @1/@5/@10
encoder and qāʿida recall is unchanged; the machine report includes every
family, including those without changes. Some deep hybrid positions and
pessimistic ranks for named alternatives change as unrelated candidate fields
are withdrawn. These movements do not cross any reported recall threshold.

For 223512.f001 the original `best_rank_with_named=2` concerns the separate
Q127 candidate, not itlaf. The physician case f002 has no such named executable
alternative. Both now have distinct stable case IDs in the report.

The historical aggregate metrics are retained for comparability, with
additional annotation-class stratification. The qualified statement is
“retrieval against existing development-bank labels”, not validated legal or
scholarly accuracy.

## Replay and next step

From `pipeline/`, using Python 3.11 and SWI-Prolog 9+:

```sh
python -m usul_corpus typed-routing --check
python -m usul_corpus.itlaf_audit --check
python -m pytest -q --integration-gate tests/test_itlaf_audit.py
```

The full machine comparison is
[`islamqa_itlaf_audit.json`](../../corpus/typing/islamqa_itlaf_audit.json).
The audit test validates the canonical pin, every case receipt, exact
withdrawals, stale/forged-edit rejection, unknown preservation, frozen-input
behaviour and deterministic replay with actual Prolog.

The next substantive work is to specify accident/avoidability, physician,
causal-consequence and employment-role contracts with their exceptions, then
annotate an independently withheld set using the corrected field catalogue.
Q127 cases need actor-specific branch annotations before claiming its encoder
closes their gap. Source-checked corrections here remain candidate; neither
reviewed semantic facts nor an accuracy claim is promoted.

Validation used Python 3.11.17 and SWI-Prolog 9.0.4. Both fail-on-skip integration
gates passed: 85 committed-data tests and 37 external-source tests, including
35 new audit regressions. All pre-existing aggregate metrics replayed unchanged
for IslamQA and both classical folds. The generated lane-B proposals also
remained unchanged.
The repository's complete `make generated` check also passed, with no changes
to its governed generated surfaces.
