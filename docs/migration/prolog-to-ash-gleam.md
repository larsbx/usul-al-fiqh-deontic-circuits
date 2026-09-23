# Prolog to Ash/Gleam Migration Plan

## Migration decision

The main migration should target **Elixir + Ash**. Gleam should be considered a later optional validation kernel, not the primary system of record.

## Why Ash first

The ADQ Prolog corpus is mostly canonical domain data plus audit queries:

- roots and lexical metadata,
- tiered warrants,
- refinement and opposition edges,
- behavioral and somatic mappings,
- compounds,
- hukm classifications,
- corpus counts,
- consistency checks.

That shape is better represented as resources, relationships, validations, actions, and persisted audit records than as pure application code.

## Why not Gleam-only

Gleam is attractive for a small checker because it provides typed records and pure validation. But a full Gleam-only migration would require rebuilding persistence, query APIs, admin workflows, review queues, import jobs, and report generation. Those are central to this project.

## Target Ash resources

```text
AffectRoot
CanonicalAlias
Warrant
RefinementEdge
OppositionEdge
CompoundAffect
BehavioralSignature
BehavioralProfile
BehavioralAttestation
SomaticIdiom
ObjectCluster
HukmClassification
Defeater
CorpusCount
AuditFinding
ImportBatch
```

## Canonical target typing

The Prolog corpus mixes roots, compounds, profiles, and external concepts. The migration should not pretend all targets are affect roots.

```text
Target =
  Root(id)
  Compound(id)
  Profile(id)
  ObjectCluster(id)
  ExternalConcept(id)
```

This prevents behavioral patterns such as `nifaq_affect_pattern` from being forced into the same namespace as canonical affect roots.

## Identifier normalization

Separate machine IDs from display strings.

Bad:

```text
ḥubb and hubb treated as different implicit atoms.
```

Good:

```json
{
  "id": "hubb",
  "display": "ḥubb",
  "arabic_root": "ح-ب-ب",
  "aliases": ["ḥubb"]
}
```

All edges, warrants, compounds, and verdicts should use canonical IDs only. Display strings are metadata.

## Warrant normalization

The Prolog corpus contains warrant forms that are close but not consistently arity-stable. The migration should replace free Prolog terms with typed warrant records.

```text
Warrant =
  Quranic(reference, note)
  Lexical(source, lemma, note)
  Behavioral(verse_range, target, signatures)
  Somatic(body_part, state, verses)
  Tafsir(source, reference, note)
  Inferred(reason, dependencies)
  Commentary(author, work, locator, note)
```

Every warrant record must have:

- stable ID,
- tier,
- source kind,
- review status,
- provenance locator,
- optional quarantine reason.

## Ash action boundaries

Recommended first actions:

```text
import_canonical_bundle
validate_bundle
accept_candidate_fact
quarantine_candidate_fact
compute_refinement_closure
compute_opposition_closure
derive_hukm_candidates
explain_derivation
```

The LLM harness may prepare `candidate_fact` records, but only actions can accept them into canonical tables.

## Optional Gleam checker boundary

A later Gleam package can consume a canonical JSON bundle and return a deterministic audit result.

```text
Input: canonical_fact_bundle.json
Output: audit_result.json
```

This checker should not access the database. It should be pure and reproducible.

Suggested checks:

- `unknown_affect_id`
- `unknown_target_id`
- `unknown_warrant_id`
- `tier4_normative_use`
- `invalid_edge_endpoint`
- `compound_component_missing`
- `hukm_without_warrant`
- `defeater_without_target`

## Migration phases

### Phase 0 — Corpus manifest

Inventory the uploaded ADQ source files and decide which pass/version is canonical.

### Phase 1 — Canonical bundle

Produce JSON/JSONL records from a small, reviewed subset:

- roots,
- warrants,
- refinement edges,
- opposition edges,
- one hukm classification,
- one defeater.

### Phase 2 — Ash resource scaffold

Add resources and migrations, but keep domain data as seed fixtures.

### Phase 3 — Audit actions

Implement fail-closed validations and structured audit findings.

### Phase 4 — LLM harness

Add candidate extraction from plain text into reviewable candidate records. The LLM may not directly mutate accepted canonical tables.

### Phase 5 — Optional Gleam kernel

Generate canonical JSON and run a typed checker as an independent deterministic evidence lane.

## Acceptance criteria for the first implementation PR

- A canonical sample bundle validates.
- A bundle with an unknown ID fails closed.
- Tier 4 material cannot support a normative hukm derivation.
- Every accepted hukm classification exposes its warrant path.
- LLM-generated candidates are marked `candidate` until accepted by an explicit action.
