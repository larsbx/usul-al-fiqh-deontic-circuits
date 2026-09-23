# Research Roadmap

## Immediate goal

Turn the ADQ Prolog corpus into a database-backed, auditable deontic-circuit research harness.

## Working principle

Natural language and LLM prompting are allowed at the authoring boundary. They may propose candidate records. They may not directly create accepted normative facts or verdicts.

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
- Ensure every accepted derivation has a minimal trace.
- Prevent quarantined evidence from supporting normative derivations.

## Milestone 5 — LLM harness

- Add plain-text candidate extraction.
- Add review queues for extracted records.
- Require explicit acceptance actions before canonical insertion.
- Generate explanations from derivation traces, not free-form verdict invention.

## Milestone 6 — Optional Gleam lane

- Export canonical JSON bundles.
- Validate the bundles with a pure typed checker.
- Treat Gleam output as independent deterministic evidence, not as the database authority.

## First issues to open after this PR

1. Add ADQ corpus manifest.
2. Add canonical ID map for root/display aliases.
3. Add Ash resource skeleton.
4. Add bundle validator and negative fixtures.
5. Add LLM candidate extraction contract.
6. Add v38 contextual path-lift tests over a tiny fixture world/path graph.
