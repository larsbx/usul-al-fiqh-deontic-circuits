# Usul in Plain English

Source: [`formal/lean/Usul.lean`](../../formal/lean/Usul.lean)

The root of the uṣūl al-fiqh (legal theory) kernel. Importing `Usul` brings in every formal module: rulings, argumentation, conflict resolution, the legal maxims (qawāʿid), analogy (qiyās), textual inference, the seam to the ḥadīth track, the type system and the category-theory layer.

## What it imports

- **Rulings and signature**: `Usul.Hukm` (the five rulings, wājib to ḥarām), `Usul.Signature` (grades of certainty, sources of evidence), `Usul.Judgement` (the judgement form).
- **Argumentation**: `Usul.Dung`, `Usul.Grounded`, `Usul.FiniteGrounded` (abstract argumentation and a verified runner for its grounded extension).
- **Conflict and preference**: `Usul.Taarud` (resolving conflicting evidence, taʿāruḍ), `Usul.Reconcile` (attribution of reported positions), `Usul.Tarjih` (preference, tarjīḥ, by proof).
- **Legal maxims**: `Usul.Qawaid`, `Usul.Sadi`, `Usul.Muamalat`, `Usul.Kulliyyat`, `Usul.Schema`, plus `Usul.Refinements`, `Usul.Tanaqud` and `Usul.Furuq` (the maxim bank applied to its own cases, contradictions and distinctions).
- **Process**: `Usul.Process` (the project's review process, read by its own principles).
- **Analogy**: `Usul.Qiyas`, `Usul.Jadal`, `Usul.QiyasLimits` (establishing the ʿilla, the objections, and the limits of qiyās).
- **Textual inference**: `Usul.Dalala`, `Usul.CommandSchemata`, `Usul.CommandDerivation`.
- **Applications**: `Usul.Tahara` (ritual purity by its Arabic names), `Usul.Readings` (the formal readings of each maxim, one module per shard).
- **The ḥadīth seam**: `Usul.Seam`, the only edge into the ḥadīth track.
- **Types**: `Usul.Typing`, `Usul.Typing.Encoders`, `Usul.Typing.Relations`, `Usul.Typing.Answers`, `Usul.DerivedTypes`.
- **Categories**: `Usul.Cat`, which gathers the category-theory submodules.

## In one line

One import gives the whole formal kernel of legal theory, from the five rulings to the category-theory specification layer.
