# Usul al-Fiqh Deontic Circuits

Research repository for crystallizing a database-backed, auditable deontic-circuit harness from the ADQ Prolog corpus.

## Current research direction

The active refactor starts from the authority of each object: pinned source bytes,
textual occurrences, candidate interpretations, admissible evidence, deterministic
inference, and generated views. A proof about an encoding does not establish that
the encoding faithfully represents its source.

The first implementation isolates the pure reconciliation operations in
`pipeline/usul_corpus/reconciliation_kernel.py` and shared value identity in
`pipeline/usul_corpus/values.py`. `reconcile.py` remains the compatible corpus
adapter and generator. Reported alternatives outside an encoder's domain remain
explicit range gaps, and Boolean, numeric, and textual rulings remain distinct.
Mandatory ordered-position receipts now prevent legacy evidence indices from
silently changing subjects, checked independently before ledger/weighing overlays.

The architecture and remaining migration gates are in the existing
[separated concerns](docs/architecture/separated-concerns.md#repository-wide-authority-boundaries)
note and [formalization roadmap](docs/roadmap-hanbali-usul-formalization.md#first-principles-refactor).
This is the first implemented boundary, not a completed repository migration.

The ADQ v37/v38 affect and contextual-path harness remains a supported research
track. The guiding constraint is unchanged: an LLM may propose, normalize, query,
and explain, but it must not become the hidden deontic authority.

## Optional research substrates

Non-authoritative research lanes may be attached to the harness when they provide independently checkable evidence without changing normative semantics.

The first such lane explores **Clifford-even finite-field rotation geometry** as an exact algebraic substrate for representation-invariance tests, associative transformation replay, symmetry experiments, and cross-implementation fixtures.

See `docs/research/clifford-even-rotation-geometry.md`.

This lane is explicitly downstream of canonical/test data. Its invariants are not warrants, and its outputs may not create or modify accepted normative facts.

## Ḥanbalī uṣūl formalization track

- Roadmap: [`docs/roadmap-hanbali-usul-formalization.md`](docs/roadmap-hanbali-usul-formalization.md)
- Pipeline: [`docs/architecture/formalization-pipeline.md`](docs/architecture/formalization-pipeline.md)
- Fatāwā corpus: [`docs/architecture/reception.md`](docs/architecture/reception.md): the canonical fatāwā and rulings collections the modern jurists cite, with citation counts from their own texts
- Citation labels: [`docs/architecture/mentions.md`](docs/architecture/mentions.md): weakly labelled title and author mentions, a review queue and gold labels, for training a citation classifier
- Derivation method: [`docs/architecture/derivation-method.md`](docs/architecture/derivation-method.md): how the bank derives a text's ruling, checks and extends it, and runs in parallel; the agent procedure is the `derivation-tranche` skill (`.claude/skills/`)
- Parallel derivation plan: [`docs/roadmap-parallel-derivation.md`](docs/roadmap-parallel-derivation.md): the source texts by role, and the lanes for running the method over them in parallel
- Qawāʿid (the foundation): [`docs/architecture/schemata.md`](docs/architecture/schemata.md): al-Saʿdī's rules, their readings, and the eight shapes under them
- Types: [`docs/architecture/judgement.md`](docs/architecture/judgement.md): `Usul.Judgement` and `Usul.Typing`, the judgement form and what each encoder's output answers
- Islamic Deontic Algebra: [concise specification](docs/research/islamic-deontic-algebra-spec.md), [Lean–Quint foundation](docs/research/ida-foundation.md), [typed judgment records](docs/research/ida-judgment-records.md), and [source-bound derivations](docs/research/ida-source-derivations.md). The scoped gates check lattice laws, guarded partial answers, complete registry binding, source-bound provenance, receipt revalidation, independent finite comparison, and compiled axioms (`make ida ida-judgment ida-derivation`).
- Categories: [`docs/architecture/category-theory.md`](docs/architecture/category-theory.md): `Usul.Cat`, downstream of the types (`Usul.Cat.Typing`: L-QIY-1 over typed encoders, the category of typed encoders, pinned by `test_layers.py`): the scales as thin categories (σ as a duality, the ḥadīth seam as a functor), qiyās as factorization (L-QIY-1), the gluing lemma with ikhtilāf as obstruction (M10), and the carriers as institutions (M11)
- Joint agency: [Lean–Quint pilot](docs/research/agency-pilot.md), with a [candidate source profile](docs/research/agency-source-profile.md), arbitrary-history proofs, exhaustive finite transition comparison, and negative controls. Install its pinned tooling with `npm --prefix formal/quint ci`.
- Act classification: [the detailed M16 roadmap](docs/research/ida-act-classification-roadmap.md) starts from [ACT-00's structured-target integration](docs/research/ida-target-integration.md), merged through [#144](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/pull/144). ACT-01–ACT-09 cover typed substitution, information-loss/equivalence proofs, supported interpretations, and evidence-bearing transport; the design is accepted, with implementation planned or conditional.
- Context: [the accepted context theory](docs/research/ida-context-theory.md) separates schematic variables, factual situations, evidence, source profiles, time/history, and authority. It refines M16's substitution, forgetting, and judgment-transport contracts using the existing typed encoders, sheaf restrictions, and agency histories.
- `make all` runs source verification, the corpus tests, record validation, the generated-file drift check, the Lean build, TLC, the agency gate, and all three IDA gates. `make fetch build` refreshes the corpus cache and records.

## al-Albānī ḥadīth-methodology track

- Roadmap: [`docs/roadmap-albani-hadith-methodology.md`](docs/roadmap-albani-hadith-methodology.md)
- Lean: `formal/lean/Hadith/` (narrator grades, isnād and tadlīs, ṭuruq aggregation as a defeasible argument), vectors in `formal/lean/HadithTest/`. The only edge into the uṣūl kernel is `Hadith.Verdict.grade : Verdict → Usul.Grade`.
