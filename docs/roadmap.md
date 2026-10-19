# Research Roadmap

## Immediate goal

Turn the ADQ Prolog corpus into a database-backed, auditable deontic-circuit research harness.

Long-range Ḥanbalī uṣūl formalization track (Lean 4, TLA+, Haskell, category theory, type theory): see [`roadmap-hanbali-usul-formalization.md`](roadmap-hanbali-usul-formalization.md).

## Active architecture migration

The repository-wide [first-principles refactor](roadmap-hanbali-usul-formalization.md#first-principles-refactor)
now organizes work by source, occurrence, interpretation, evidence admission,
inference and derived-view boundaries. Its first tranche isolates reconciliation
and typed value identity; the remaining stages have explicit migration gates.
The ADQ milestones below remain track-specific, not a separate competing refactor.

## Working principle

Natural language and LLM prompting are allowed at the authoring boundary. They may propose candidate records. They may not directly create accepted normative facts or verdicts.

Optional mathematical research lanes may consume explicit data and emit reproducible findings, but they may not become hidden normative authorities.

## Milestone 1 — Corpus manifest

- Inventory all uploaded ADQ files.
- Identify canonical source generation among early `01_*` through `11_*`, `v3_*`, and `v37_*` layers.
- Mark deprecated, generated, visualization-only, and test-only files.
- Decide whether `v37_*` supersedes earlier modules or remains an overlay.

## Milestone 1a — ADQ v37 contextual path lift

- Treat `deontic_obligation/6` as the current strongest affect-deontic fact shape.
- Keep behavioral signatures, somatic idioms, and tier discipline as context/evidence inputs.
- Preserve the v3.6 capacity guard: bare involuntary affect is not the same as cultivated, endorsed, dominant, or action-guiding affect.
- Lift `deontic_anti_pair/4` into path-level displacement constraints.
- Add a thin `v38_contextual_affect_deontics.pl` bridge before attempting a database rewrite.
- Keep `behavioral_deontic` outside the affect lattice rather than collapsing acts into affect-state facts.

## Milestone 1b — Finite sheaf obstruction fixtures

- Treat active local ADQ verdicts as sections over a finite context site.
- Add gluable world/path predicates over tiny fixture cases.
- Emit structured obstruction records for forbidden realization, missing required realization, anti-pair displacement, and same-scope operator conflict.
- Keep involuntary somatic panic as context evidence rather than direct liability.
- Preserve a clear fixture/source boundary: generated conflict facts prove the failure mode only; they are not source-derived deontic claims.

## Milestone 1c — Concern extraction

- Separate affect-deontic facts and local affect observations from temporal/path fixtures.
- Separate temporal/world/path data from sheaf gluing and obstruction checks.
- Keep `examples/v39_sheaf_obstruction_fixtures.pl` as a compatibility aggregator only.
- Document the concern boundary in `docs/architecture/separated-concerns.md`.
- Preserve independent promotion paths for affect imports, temporal case fixtures, and sheaf compatibility tests.

## Milestone 2 — Canonical schema

- Stabilize canonical IDs.
- Separate display strings from machine IDs.
- Normalize warrant arities.
- Introduce typed targets for roots, compounds, profiles, object clusters, and external concepts.
- Define audit finding types.
- Add canonical fields for `subject`, `operator`, `modality`, and `control_status` so the v37/v38 bridge is not flattened back into prose.

## Milestone 3 — Ash scaffold

- Create resources for roots, warrants, targets, edges, hukm classifications, defeaters, and import batches.
- Add fail-closed validations.
- Add import actions for canonical bundles.
- Add audit actions that produce structured findings.

## Milestone 4 — Deontic kernel

- Implement tier discipline.
- Implement closure computations.
- Implement defeat/blocking semantics.
- Implement subject/object/modality matching before verdict derivation.
- Implement path-level affect violations for forbidden facts, missing in-scope obligations, and anti-pair displacement.
- Implement finite sheaf-style compatibility checks and obstruction reports before accepting glued verdicts.
- Ensure every accepted derivation has a minimal trace.
- Prevent quarantined evidence from supporting normative derivations.

## Milestone 4A — Finite-valued Boolean boundary

- Preserve five-fold hukm as finite verdict tags: `wajib`, `mandub`, `mubah`, `makruh`, `haram`, plus `no_ruling` outside taklif.
- Permit Boolean circuits only as evidence gates, condition checks, admissibility predicates, projection views, and path filters.
- Reject collapse rules such as `not_haram = mubah`, `not_wajib = haram`, `allowed = neutral`, and `ideal = not_haram`.
- Add projection fixtures for `weak_permissible`, `ideal_positive`, `path_excluding`, and `path_demoting`.
- Require accepted classifications to carry the original finite verdict in derivation traces even when a Boolean projection is also emitted.

## Milestone 5 — LLM harness

- Add plain-text candidate extraction.
- Add review queues for extracted records.
- Require explicit acceptance actions before canonical insertion.
- Generate explanations from derivation traces, not free-form verdict invention.

Semantic tagging has a merged development implementation (PR #72) and a candidate
pass covering all 53 IslamQA question IDs: 365 propositions, 1,074 candidate roles
and 58 bank mappings all on hold. Audit segmentation completeness, independently
review interpretations and typed fact entailments, then evaluate on a separately
frozen modern set. The two proposed typed values remain unreviewed. See the
[formalization roadmap's follow-up](roadmap-hanbali-usul-formalization.md#semantic-tagging-development-follow-up-2026-10-19)
for evidence, boundaries and acceptance steps. No semantic accuracy or retrieval
improvement is claimed by this batch.

## Milestone 6 — Optional Gleam lane

- Export canonical JSON bundles.
- Validate the bundles with a pure typed checker.
- Treat Gleam output as independent deterministic evidence, not as the database authority.

## Milestone 7 — Optional Clifford-even algebraic research lane

- Keep the full mathematical development in a dedicated research note.
- Add a machine-readable `F_7` rank-3 fixture for the seven attainable angle-invariant values.
- Add a tiny reference implementation for the quadratic form, bilinear form, angle invariant, and `SL_2(F_7)` conjugation action.
- Define a research-only `AlgebraicFinding` schema that is disjoint from warrants and hukm evidence.
- Require provenance for field, quadratic form, basis/encoding version, operator, input hashes, and output invariants.
- Add a fail-closed test proving that algebraic findings cannot enter normative derivations.
- Demonstrate that disabling the algebraic lane leaves every accepted deontic derivation unchanged.
- Do not promote this lane beyond research status until a concrete migration, replay, or representation-invariance benefit is demonstrated.

## First issues to open after this PR

1. Add ADQ corpus manifest.
2. Add canonical ID map for root/display aliases.
3. Add Ash resource skeleton.
4. Add bundle validator and negative fixtures.
5. Add LLM candidate extraction contract.
6. ~~Convert `fixture_expectation/3` records from `examples/v39_sheaf_concern.pl` into executable tests.~~ Done: `tests/run_all.sh`.
7. Add canonical JSON import adapters for the v38/v39 bridge predicates.
8. Mirror the affect, temporal/path, and sheaf concern split in the Ash resource design.
9. Add the `F_7` Clifford-even research fixture and authority-firewall test.
10. Add finite-valued Boolean-boundary validator fixtures.
11. Add path-filter projection tests for required, excluded, preferred, demoted, and neutral paths.
