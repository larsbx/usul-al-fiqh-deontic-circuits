# Usul al-Fiqh Deontic Circuits

Research repository for crystallizing a database-backed, auditable deontic-circuit harness from the ADQ Prolog corpus.

## Current research direction

The first branch, `research/deontic-circuits-harness`, established the repository harness and was merged through PR #1.

The follow-up branch, `research/adq-affect-deontic-path-lift`, pulls the second ADQ source pass into the project. It treats the v37 `deontic_obligation/6` layer as the current strongest affect-deontic fact shape and specifies the missing v38 bridge from affect facts into contextual world/path filtering.

The migration is framed around three layers:

1. **Plain-text and LLM authoring harness** for scholarly notes, extraction proposals, explanations, and review workflows.
2. **Database-backed canonical fact graph** for affect roots, warrants, refinements, opposition, compounds, hukm classifications, defeaters, subjects, modalities, and audit history.
3. **Small deterministic deontic kernel** for validity, tier discipline, closure, defeat/blocking semantics, quarantine, derivation traces, and path-level affect constraints.

The guiding constraint is that the LLM may propose, normalize, query, and explain, but it must not become the hidden deontic authority.

## Ḥanbalī uṣūl formalization track

- Roadmap: [`docs/roadmap-hanbali-usul-formalization.md`](docs/roadmap-hanbali-usul-formalization.md)
- Pipeline: [`docs/architecture/formalization-pipeline.md`](docs/architecture/formalization-pipeline.md)
- Fatāwā corpus: [`docs/architecture/reception.md`](docs/architecture/reception.md): the canonical fatāwā and rulings collections the modern jurists cite, with citation counts from their own texts
- Citation labels: [`docs/architecture/labels.md`](docs/architecture/labels.md): weakly labelled title and author mentions, a review queue and gold labels, for training a citation classifier
- `make all` runs the corpus tests, record validation, the generated-file drift check, the Lean build and TLC. `make fetch build` refreshes the corpus cache and records.

## al-Albānī ḥadīth-methodology track

- Roadmap: [`docs/roadmap-albani-hadith-methodology.md`](docs/roadmap-albani-hadith-methodology.md)
- Lean: `formal/lean/Hadith/` (narrator grades, isnād and tadlīs, ṭuruq aggregation as a defeasible argument), vectors in `formal/lean/HadithTest/`. The only edge into the uṣūl kernel is `Hadith.Verdict.grade : Verdict → Usul.Grade`.
