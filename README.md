# Usul al-Fiqh Deontic Circuits

Research repository for crystallizing a database-backed, auditable deontic-circuit harness from the ADQ Prolog corpus.

## Current research branches

- `research/deontic-circuits-harness` frames the base migration harness.
- `crystallize/sheaf-contextual-adq` lifts the ADQ affect-deontic layer toward contextual path filtering and finite sheaf-style compatibility checks.

The repository frames the migration around five layers:

1. **Plain-text and LLM authoring harness** for scholarly notes, extraction proposals, explanations, and review workflows.
2. **Database-backed canonical fact graph** for affect roots, warrants, refinements, opposition, compounds, hukm classifications, defeaters, and audit history.
3. **Small deterministic deontic kernel** for validity, tier discipline, closure, defeat/blocking semantics, quarantine, and derivation traces.
4. **Contextual path lift** for worlds, agents, local action paths, modality satisfaction, capacity guards, and affect realization.
5. **Finite sheaf compatibility layer** for restrictions, overlap checks, gluing, and explicit obstruction records.

The guiding constraint is that the LLM may propose, normalize, query, and explain, but it must not become the hidden deontic authority.

## Branch artifacts

The contextual/sheaf branch adds:

- `docs/architecture/adq-contextual-path-lift.md` — maps the ADQ v37 `deontic_obligation/6` shape into contextual path filtering.
- `docs/architecture/sheaf-context-site.md` — specifies the finite context site, section, restriction, gluing, and obstruction vocabulary.
- `examples/v38_contextual_affect_deontics.pl` — standalone Prolog scaffold for local sections, path violations, anti-pair failure, outside-taklif realization, and gluable paths.
