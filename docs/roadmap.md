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

## Milestone 5 — Contextual path lift

- Treat `deontic_obligation/6` as the local affect-deontic section shape.
- Add world, context, path, and path-realization vocabulary without replacing ADQ facts.
- Require subject, object, modality, tier, and capacity guards before a local section can constrain a path.
- Keep `affect_deontic`, `behavioral_deontic`, `somatic_context`, and `path_deontic` as distinct module boundaries.
- Use anti-pairs as displacement/path-filter constraints, not as global contradictions.

## Milestone 6 — Finite sheaf compatibility layer

- Model a finite context poset as the first site.
- Implement restriction checks from broader contexts to refined contexts.
- Define compatibility of local deontic sections on overlaps.
- Emit structured obstruction records for failed gluing.
- Treat lexical/behavioral/somatic evidence as a cosheaf-like aggregation layer feeding the deontic sheaf.

## Milestone 7 — LLM harness

- Add plain-text candidate extraction.
- Add review queues for extracted records.
- Require explicit acceptance actions before canonical insertion.
- Generate explanations from derivation traces, not free-form verdict invention.

## Milestone 8 — Optional Gleam lane

- Export canonical JSON bundles.
- Validate the bundles with a pure typed checker.
- Treat Gleam output as independent deterministic evidence, not as the database authority.

## First issues to open after this PR

1. Add ADQ corpus manifest.
2. Add canonical ID map for root/display aliases.
3. Add Ash resource skeleton.
4. Add bundle validator and negative fixtures.
5. Add contextual path-lift predicates around `deontic_obligation/6`.
6. Add finite sheaf gluing and obstruction fixtures.
7. Add LLM candidate extraction contract.
