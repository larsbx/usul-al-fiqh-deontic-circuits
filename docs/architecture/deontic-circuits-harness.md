# Deontic Circuits Harness

## Purpose

This note crystallizes the migration target for the uploaded ADQ Prolog corpus. The goal is not to hard-code every defeasible deontic structure into application code. The goal is to move the evolving scholarly material into a canonical database-backed graph, while keeping a small deterministic kernel responsible for admissibility, closure, quarantine, and audit traces.

## Core thesis

Use plain text, prompts, and LLM interaction as the **authoring and explanation harness**. Use a database as the **canonical store of normalized facts and warrants**. Use code as the **small formal kernel**.

```text
plain text / notes / Prolog facts
        ↓
LLM-assisted extraction and normalization
        ↓
canonical database fact graph
        ↓
small deterministic deontic kernel
        ↓
audits, derivations, explanations, reports
```

The LLM is useful for translation, candidate extraction, query planning, summarization, and natural-language explanation. It is not the deontic authority.

Optional mathematical or computational research substrates may consume explicit canonical/test data and emit non-authoritative findings. They do not gain a reverse authority edge into the normative graph.

## Prolog corpus shape

The current corpus is primarily a knowledge lattice and audit system, not a heavy Prolog search engine. Representative modules include:

- `00_spec-1.md` — tier and ontology discipline.
- `01_roots-1.pl` — affect roots, glosses, clusters, and verse anchors.
- `01_tier_meta-1.pl` — warrant tier metadata and quarantine discipline.
- `02_prec-1.pl` — refinement / precedence edges and transitive closure.
- `02_signatures-1.pl` — behavioral signatures and profiles.
- `03_behavioral-1.pl` — behavioral attestations and profile mappings.
- `04_opp-1.pl` — opposition edges and symmetric opposition.
- `04_somatic-1.pl` — somatic idioms and affect mappings.
- `06_compose-1.pl` — compound affect composition.
- `07_hukm-1.pl` — affect/object/hukm classification facts.
- `11_corpus-1.pl` — corpus counts, frequency tiers, and edge strength.
- `v37_*` modules — later deontic fact, consistency, positive/negative lemma, and test layers.

## Proposed authority split

| Layer | Authority | Mutable? | Notes |
|---|---:|---:|---|
| Plain text notes | Source material only | Yes | Research prose, commentary, draft prompts, unresolved scholarly disagreement. |
| LLM harness | Candidate generation only | Yes | Proposes normalized records and explanations. Never silently accepts facts. |
| Database fact graph | Canonical domain data | Yes, versioned | Stores accepted roots, warrants, edges, classifications, exceptions, audit status. |
| Deontic kernel | Formal admissibility | Rarely | Enforces validity, tier discipline, closure, quarantine, defeat semantics. |
| Algebraic research substrate | Research evidence only | Yes | May compute exact finite-field invariants, symmetry/replay evidence, and equivalence candidates. Never acts as a warrant or normative rule. |
| Reports/API/UI | Presentation | Yes | Exposes derivations and review queues without changing authority. |

## Do not encode the corpus as application logic

Hard-coding every `affect_root`, `prec`, `opposes`, `composes`, and `hukm_aff` record into Elixir/Gleam code would make the system brittle. Each scholarly correction would require a code change. The corpus should be data with provenance, not hidden control flow.

Hard-code only the semantics that protect the corpus:

- Canonical IDs and target typing.
- Warrant shape and tier discipline.
- Tier 4 quarantine behavior.
- Valid edge source/target requirements.
- Defeater and exception mechanics.
- Closure computation.
- Audit-error emission.
- Derivation trace requirements.

## Candidate circuit model

A deontic circuit is a finite, inspectable graph of typed nodes and edges.

### Nodes

- `AffectRoot`
- `CompoundAffect`
- `BehavioralProfile`
- `ObjectCluster`
- `Warrant`
- `Defeater`
- `HukmClassification`
- `AuditFinding`

### Edges

- `refines`
- `opposes`
- `composes`
- `maps_somatic_to_affect`
- `supports_hukm`
- `defeats`
- `requires_profile`
- `cites_warrant`

### Computed outputs

- Transitive refinement closure.
- Symmetric opposition closure.
- Admissible hukm derivations.
- Blocked or quarantined derivations.
- Minimal warrant path for each accepted claim.
- Audit findings for orphan IDs, tier violations, unknown warrants, and schema drift.

## Optional Clifford-even research lane

The Clifford-even finite-field work is admitted only as an **experimental representation and verification lane**.

Potential uses:

- exact representation-invariance tests;
- associative composition and replay of declared transforms;
- symmetry/equivalence experiments over finite encodings;
- deterministic cross-language regression fixtures.

It may emit an `AlgebraicFinding` or equivalent research record. Such a record is not a warrant and cannot support a normative derivation.

Forbidden shortcuts include:

- treating orthogonality as deontic opposition;
- treating geometric proximity as semantic similarity;
- treating an orbit as deontic equivalence;
- deriving normative strength from norms, inner products, angle invariants, or group structure;
- using an algebraic result to bypass quarantine, defeaters, or tier discipline.

The detailed boundary and mathematical reference are documented in `docs/research/clifford-even-rotation-geometry.md`.

## Preferred implementation direction

Use **Elixir + Ash** as the system of record and application framework.

Use **Gleam** optionally as a small generated checker over canonical JSON facts.

```text
Ash/Postgres owns mutable canonical data.
Gleam, if added, owns a pure typed validation pass.
Optional algebraic research lanes own only reproducible research evidence.
None replaces the deontic authority boundary.
```

## Non-goals for the first branch

- No production UI.
- No final fiqh authority claims.
- No LLM-only verdict generation.
- No rewrite of the full Prolog corpus.
- No hard-coded domain fact enum explosion.
- No geometric or algebraic scoring of normative claims.

## First implementation target

The first buildable slice should import a small canonical bundle and run deterministic audits:

1. Validate all canonical IDs.
2. Validate all warrants are typed and tiered.
3. Reject Tier 4 material from normative derivations.
4. Detect orphan affect/object/profile references.
5. Compute refinement transitive closure.
6. Emit structured audit findings.
