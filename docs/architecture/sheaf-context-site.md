# Finite Sheaf Context Site for ADQ Deontics

## Purpose

This note crystallizes the sheaf-theoretic layer for the ADQ/contextual-deontic branch. It does not replace the deterministic kernel or the ADQ fact graph. It gives the project a precise language for local contextual verdicts, restrictions, compatibility, gluing, and obstruction.

The practical thesis is:

```text
ADQ facts provide local deontic sections.
Context refinements provide restriction maps.
Path/case synthesis is a finite gluing problem.
Failed synthesis emits explicit obstruction records.
```

## Why this belongs above the kernel

The existing ADQ v37 shape already separates affect, object, subject, operator, modality, and warrant:

```prolog
deontic_obligation(Affect, Object, Subject, Operator, Modality, Warrant).
```

That is the local verdict atom. The sheaf layer asks when several such local verdicts can coexist across overlapping contexts.

It should remain an architectural and validation layer. It must not become a hidden juristic oracle.

## Base site

Use a finite context poset as the first site. A context is a named collection of features relevant to rule activation and restriction:

- subject class, such as `all_mukallafin`, `believers`, `leaders`, or `prophets`;
- object scope, such as `allah_essence`, `other_than_allah`, `allah_rahmah`, or a behavioral object;
- circumstance, such as `duress`, `sickness`, `travel`, `combat`, `authority_context`, or `low_capacity`;
- affect-control status, such as `involuntary`, `cultivated`, `dominant`, or `action_guiding`;
- evidence status, such as lexical, behavioral, somatic, or quarantined inferential evidence.

The refinement relation is read as:

```text
refines(Smaller, Larger)
```

meaning `Smaller` carries all constraints of `Larger` plus additional context.

## Presheaf of deontic sections

Define a finite presheaf:

```text
D : Context^op -> Set
```

where `D(U)` is the set of local deontic sections active over context `U`.

A section is represented by the normalized ADQ fact shape:

```text
section(Context,
        deontic(Affect, Object, Subject, Operator, Modality, Warrant))
```

Restriction maps are deterministic adapters:

```text
restrict(Section, FromContext, ToContext, RestrictedSection)
```

A restriction may preserve, weaken, suspend, or refine the local verdict only when the kernel has an explicit rule for doing so. No silent LLM rewrite is allowed.

## Compatibility and gluing

Two local sections are compatible on an overlap when their restrictions do not conflict after object, subject, modality, warrant, and priority discipline are applied.

```text
compatible(S1, S2, Overlap)
```

A family of local sections glues when every pair is compatible on the appropriate overlap and the kernel can produce a unique normalized result:

```text
gluable(Cover, Sections)
global_section(Cover, Sections, GlobalVerdict)
```

This is the finite, executable version of the sheaf condition. It can be implemented as ordinary Prolog, Datalog, Ash validations, or SAT/CSP checks.

## Obstruction records

The main payoff is failed gluing. A failed global section should emit a structured obstruction instead of a vague contradiction:

```text
obstruction(Cover, Sections, Reason)
```

Initial obstruction categories:

| Category | Meaning |
|---|---|
| `object_collision` | Two sections were treated as if they shared an object, but object scopes differ. |
| `subject_collision` | A verdict was applied outside its subject class. |
| `modality_unsatisfied` | A conditional, comparative, or scalar modality was not active in the target context. |
| `capacity_violation` | Bare involuntary affect was treated as culpable action-guiding realization. |
| `tier_quarantine` | Tier 4 or otherwise quarantined evidence supported a normative derivation directly. |
| `anti_pair_failure` | A forbidden/displacing affect was realized while the commanded counterpart failed in scope. |
| `operator_conflict` | Same affect/object/subject scope carries incompatible operators without a defeater or priority resolution. |
| `alias_gluing_failure` | Display/Unicode/root aliases fail to normalize to one canonical ID. |
| `unsupported_claim` | A claimed section has no source fact, no context, or no observation. |

### Where obstructions come from

`operator_conflict` arises between lifted sections. `anti_pair_failure` arises on a path; it is emitted as `anti_pair_displacement/3`.

The other categories describe a *misapplication*: something treated as active where a guard says it is not. A guard that correctly declines to lift is not an obstruction. For example, involuntary panic lifts no section, and its world still glues.

These categories are therefore emitted against claims. A claim, `section_claim/4` in `examples/v39_claim_concern.pl`, is a proposed section from an LLM candidate, an import, or a restriction from another context. `claim_obstruction/5` checks a claim with the same guards that lift sections; claims never add sections. A fixture vector enforces the correspondence: a claim is obstructed exactly when it is not a lifted section.

The checks run in this order:
1. **Alias normalization.** An ambiguous alias stops the remaining checks.
2. **Source-fact resolution.** No fact at all gives `unsupported_claim`; a fact only for another object gives `object_collision`.
3. **Subject.**
4. **Context and modality.**
5. **Observations.** These are diagnosed only when none of them supports lifting, which yields `capacity_violation` and/or `tier_quarantine`.

## Evidence cosheaf feeding the deontic sheaf

Evidence moves in the opposite direction from deontic restriction. Lexical, behavioral, and somatic observations aggregate upward into an affect diagnosis:

```text
local evidence patches -> affect diagnosis -> local deontic section
```

So the clean architecture is two-layered:

```text
cosheaf of evidence
        -> affect/context diagnosis
        -> sheaf of deontic sections
        -> gluing or obstruction
```

This preserves ADQ tier discipline:

- lexical, behavioral, and somatic evidence may contribute to accepted context when their warrant and profile checks pass;
- quarantined inferential/commentary material may annotate or guide review, but cannot directly generate a normative section.

## Path-indexed lift

For the contextual deontic-circuit model, the base site can be refined from static contexts to action-prefix contexts:

```text
ContextPatch = world + agent + path_prefix + evidence + object + subject + modality conditions
```

Restriction then follows prefix extension:

```text
prefix(Prefix, LongerPrefix)
refines(ctx(World, Agent, LongerPrefix), ctx(World, Agent, Prefix))
```

This explains why a permission can become forbidden later without contradiction: the later prefix is a smaller context with more information and fewer admissible continuations.

## Immediate implementation target

The first buildable target is deliberately finite:

1. model a small context poset;
2. derive local sections from `deontic_obligation/6`-shaped facts;
3. implement restriction guards for subject, object, modality, capacity, and tier status;
4. implement pairwise compatibility;
5. emit obstruction records;
6. add tests for non-contradictory context separation, true operator conflict, anti-pair failure, and tier quarantine.

The accompanying executable sketch is `examples/v38_contextual_affect_deontics.pl`.

## Non-goals

- No general infinite topos machinery.
- No replacement of the existing ADQ fact graph.
- No claim that the sheaf layer itself decides fiqh.
- No hidden LLM authority.
- No direct normative use of quarantined evidence.

The sheaf layer is a disciplined compatibility engine: local data in, gluing or obstruction out.
