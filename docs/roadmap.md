# Research Roadmap

## Immediate goal

Turn the ADQ Prolog corpus into a database-backed, auditable deontic-circuit research harness.

## Working principle

Natural language and LLM prompting are allowed at the authoring boundary. They may propose candidate records. They may not directly create accepted normative facts or verdicts.

Optional mathematical research lanes may consume explicit data and emit reproducible findings, but they may not become hidden normative authorities.

## Milestone 1 — Corpus manifest

- Inventory all uploaded ADQ files.
- Identify canonical source generation among early `01_*` through `11_*`, `v3_*`, and `v37_*` layers.
- Mark deprecated, generated, visualization-only, and test-only files.
- Decide whether `v37_*` supersedes earlier modules or remains an overlay.

## Milestone 2 — Canonical schema

- Stabilize canonical IDs.
- Separate display strings from machine IDs.
- Normalize warrant arities.
- Introduce typed targets for roots, compounds, profiles, object clusters, and external concepts.
- Define audit finding types.

## Milestone 3 — Ash scaffold

- Create resources for roots, warrants, targets, edges, hukm classifications, defeaters, and import batches.
- Add fail-closed validations.
- Add import actions for canonical bundles.
- Add audit actions that produce structured findings.

## Milestone 4 — Deontic kernel

- Implement tier discipline.
- Implement closure computations.
- Implement defeat/blocking semantics.
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
6. Add the `F_7` Clifford-even research fixture and authority-firewall test.
7. Add finite-valued Boolean-boundary validator fixtures.
8. Add path-filter projection tests for required, excluded, preferred, demoted, and neutral paths.
