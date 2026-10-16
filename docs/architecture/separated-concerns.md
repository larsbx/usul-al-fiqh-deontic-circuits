# Separated Concerns: Affect, Temporal Path, and Sheaf Gluing

## Purpose

This note records the repo boundary introduced after the v38 contextual bridge and v39 obstruction fixtures. The earlier fixture file proved the idea, but it mixed three concerns in one Prolog module:

1. affect-deontic facts and local affect evidence;
2. temporal/world/path fixture structure;
3. sheaf-style compatibility, gluing, and obstruction logic.

The repo should keep those concerns separate so future imports can replace one layer without rewriting the others.

## Concern 1 — affect-deontic kernel data

The affect concern owns ADQ-shaped local normative facts and affect observations:

```prolog
deontic_obligation(Affect, Object, Subject, Operator, Modality, Warrant).
deontic_anti_pair(Commanded, Forbidden, Object, Meta).
ctx_affect(World, Agent, Affect, Object, Evidence, ControlStatus).
```

It does **not** own path topology, action prefixes, gluing, or obstruction. It answers only: which affect/object/subject/modal facts and observed affect tokens are available?

Fixture module:

```text
examples/v39_affect_concern.pl
```

## Concern 2 — temporal/path execution context

The temporal concern owns finite worlds, context conditions, and path realization:

```prolog
ctx(World, Agent, Conditions).
path_realizes(Path, Agent, Affect, Object).
path_obligation_scope(Path, Agent, Affect, Object).
agent_subject(Agent, Subject).
subject_closed(Agent).          % Agent's agent_subject/2 facts are complete
```

It does **not** decide whether a realized affect is forbidden, obligatory, or gluable. It only says what context and path data are present.

Fixture module:

```text
examples/v39_temporal_concern.pl
```

## Concern 3 — sheaf compatibility and obstruction

The sheaf concern owns finite local sections and gluing failure reports:

```prolog
local_section(World, Agent, Section).
section_conflict(Section1, Section2, ConflictKind).
world_obstruction(World, Reason).
path_obstruction(World, Path, Reason).
world_gluable(World).
path_gluable(World, Path).
```

It consumes the affect concern and temporal concern through the v38 bridge. It should emit explicit obstruction reasons rather than silently accepting inconsistent local sections.

Fixture module:

```text
examples/v39_sheaf_concern.pl
```

## Concern 4 — claims

The claim concern owns proposed local sections:

```prolog
section_claim(World, Agent, Section, Origin).
```

A claim is a candidate verdict, for example from the LLM harness or an import adapter. It never adds a section. The sheaf concern checks it and emits `claim_obstruction/5` records.

Fixture module:

```text
examples/v39_claim_concern.pl
```

## Aggregator compatibility

The original public fixture path is retained as an aggregator:

```text
examples/v39_sheaf_obstruction_fixtures.pl
```

It loads the concern modules and contains only smoke-query documentation. This keeps existing links stable while making the separation explicit.

## Boundary rules

- Affect data may be source-derived or fixture-generated, but fixture-generated conflict facts must remain marked as fixtures.
- Temporal/path facts may describe test worlds and paths but must not create normative verdicts.
- Sheaf predicates may derive gluing/obstruction status but must not invent new ADQ source facts.
- The v38 bridge remains the adapter between ADQ-shaped facts and path filters.
- LLM-authored fixtures remain proposals/test vectors, not accepted normative facts.
- Claims are checked, never lifted. A claim cannot create a section, only an obstruction.

## Promotion path

1. Keep the Prolog fixture split as the executable reference.
2. Mirror the three concerns in the Ash schema as separate resource groups.
3. Add import adapters that populate affect facts independently from temporal/case fixtures.
4. Add test runners that can exercise the sheaf concern against multiple temporal fixtures.
5. Preserve the aggregator file until no downstream scripts rely on it.

## Repository-wide authority boundaries

Refactor baseline: main `57a3b1c` (2026-10-16 inspection). The original ADQ concern
split above remains valid. The corpus/Lean track now needs the same discipline
across the entire evidence-to-inference path. PR #91's audit is an input to this
migration, not a claim that all its proposed remedies have shipped.

### First principles

1. A witness attests bytes, not an interpretation. Verification must bind a quote
   to a pinned witness and its context, including negation and qualifications.
2. Equal text is not equal occurrence. Two bābs quoting the same words create two
   source obligations; normalized text is a search key, never occurrence identity.
3. A position is a reported interpretation, not a fact supplied to win a case.
   Disputed causal characterizations stay disputed; holders' grades remain attribution.
4. Missing evidence is epistemic state, not evidence against an opponent. A
   derivation must disclose search coverage and unresolved applicability claims.
5. A kernel proves the consequence of supplied premises under a named policy.
   Source fidelity, admissibility and scholarly acceptance require separate receipts.
6. A report, router, category-theoretic construction or LLM explanation cannot
   promote its own inputs into accepted normative premises.

### Ownership and allowed dependencies

| Boundary | Owns | Existing location / migration target | Exit evidence |
|---|---|---|---|
| Witnesses | Bytes, pins, locators, restoration receipts | `fetch`, `source_verify`, `arabic`, `corpus/lock.json` | Hash and contextual quotation replay; unavailable required bytes fail |
| Occurrences | Work/witness-local spans, segmentation and source obligations | `segment`, `units`, `records` | Every repeated occurrence accounted for; stable IDs and explicit redirects |
| Interpretations | Cases, encoder domains, positions, attribution and review state | `takhrij`, `corpus/takhrij`, `corpus/review` | Typed values, explicit range gaps, preserved competing readings |
| Evidence admission | Position-bound proofs, applicability, search coverage and policy inputs | `reconcile.check` now; dedicated admission adapter next | Reject stale references, unknown fields and unsupported strength claims |
| Inference | Finite operations on supplied values and admissible premises | `reconciliation_kernel`, Lean `Usul.Tarjih` / `Usul.Reconcile` | Differential replay and adversarial vectors under each policy |
| Views | Reports, routing proposals, exports, explanations and obstruction summaries | CLI/generators, routing and sheaf modules | Reproducible outputs tied to input receipts; no reverse authority edge |

Dependencies point from adapters to the pure kernel and shared value vocabulary.
The kernel imports neither the corpus registry nor file/network I/O, CLI, routing,
report generators, or review workflows. Lean remains authoritative for the stated
finite procedures. Exporting a Python expectation into a Lean guard verifies
agreement on supplied premises; it does not independently verify those premises.

### Implemented first boundary

`values.code` gives encoded JSON values one representation identity; `same`,
`among` and `distinct` use it. `takhrij.code/among` remain compatibility imports.
This identity is local to an encoding, not semantic equivalence between encoders.
The Python reconciliation operations and Lean String export use that identity:
`false`, `0`, and `"false"` cannot collapse. The pure module retains the current
proof-tier and murajjiḥ policies; extraction does not change their scholarly scope.

Both case validation and the reconciliation adapter reject malformed position
rulings. Direct calls to `resolve` and `attribution` also check this boundary.
A nonempty textual alternative outside the encoder's output domain must carry a
nonempty `outside` explanation. This retains a range gap without silently treating
it as an encoder result. The annotation is not evidence of source fidelity or
scholarly acceptance. Numeric/Boolean mismatches cannot use this escape hatch.

The migration adds this metadata to all 53 existing out-of-domain textual positions:
36 in the `lots` cases and 17 in the lane-B missing-rule cases. It preserves each
ruling, holder, detail, fact, case classification and source reference. Historical
audit snapshots stay unchanged. Current reconciliation report equality is a
regression requirement, not an endorsement of its input adequacy.

### Remaining structural work

Position indices still carry evidence associations. Replace them with stable,
case-scoped position IDs plus versioned content receipts; a digest of the ordered
legacy positions is an interim fail-closed migration gate. Never regenerate that
digest merely to accept an unexplained reorder. Stable IDs survive reorder;
changed content invalidates the receipt and requires evidence revalidation.

Admission must eventually return either an explicit blocked/pending result with
obligations or validated kernel inputs with receipts. Keep these states distinct:
unsearched, searched-with-no-proof, disputed applicability, rejected proof,
admissible proof, and human-reviewed interpretation. Do not invent search records
for the existing incomplete entries. Preserve current conditional outputs during
migration, label their adequacy separately, and review policy changes in Lean and
Python together. In particular, the existing rule that a proved side can beat a
side without recorded proof remains in this tranche; PR #91's PR-34 is still open.

Do not start by moving all directories, introducing a database, or replacing the
formal kernels. Extract a boundary with a compatibility adapter, replay its corpus,
and remove the old path only after the new path demonstrates equivalent behavior
on valid inputs and rejection of the audited invalid inputs.
