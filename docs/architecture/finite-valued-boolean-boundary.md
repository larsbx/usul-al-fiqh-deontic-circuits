# Finite-Valued Deontic Boundary for Boolean Circuits

## Purpose

This note fixes the boundary between Boolean circuitry and the five-fold deontic logic used by the ADQ corpus.

The guiding rule is:

```text
Boolean below; finite-valued deontic verdicts above.
```

Boolean circuitry is allowed to compute evidence, applicability, condition satisfaction, path exclusion, and audit predicates. It must not collapse the meaning of the five-fold hukm into a single true/false value.

## Compatibility verdict

Boolean circuits are compatible with the project as an implementation substrate, but not as the semantics of hukm.

A circuit may answer:

- whether a warrant is present;
- whether a context condition is satisfied;
- whether a subject/object pair matches a rule;
- whether a path realizes a forbidden affect;
- whether a candidate derivation is admissible under tier discipline.

A circuit must not replace the verdict set:

```text
wajib | mandub | mubah | makruh | haram | no_ruling
```

with a single Boolean predicate such as `allowed` or `ideal`.

## ADQ operator alignment

The later ADQ layers already point in the right direction with deontic operators:

```text
o = wajib / obligatory
f = haram / forbidden
r = mandub / recommended
d = makruh / discouraged
p = mubah / permitted-neutral
n = no_ruling / outside taklif
```

The migrated kernel should preserve these as finite tags. Boolean projections may be derived from them, but projections are views, not replacements.

## Forbidden collapses

The following reductions are invalid and must not be encoded as kernel axioms:

```text
not haram  = mubah
not wajib  = haram
allowed    = mubah
ideal      = not haram
permitted  = neutral
```

Correctly:

```text
not haram includes wajib, mandub, mubah, and makruh.
not wajib includes mandub, mubah, makruh, haram, and no_ruling.
weak permission is a projection, not a hukm tag.
```

## One-hot finite verdict

A normalized verdict may be encoded as either a tagged value or a one-hot vector.

Tagged form:

```json
{
  "verdict": "wajib"
}
```

One-hot form:

```json
{
  "wajib": true,
  "mandub": false,
  "mubah": false,
  "makruh": false,
  "haram": false,
  "no_ruling": false
}
```

The deterministic kernel, not the LLM harness, must enforce that exactly one verdict bit is active for an accepted classification. Candidate records may remain incomplete or conflicting, but accepted records must be finite-valued and unambiguous.

## Boolean projections

Derived Boolean predicates are allowed when they are explicitly named as projections:

```text
is_required(h)       iff h = wajib
is_forbidden(h)      iff h = haram
is_recommended(h)   iff h = mandub
is_discouraged(h)   iff h = makruh
is_neutral(h)       iff h = mubah
outside_taklif(h)   iff h = no_ruling
```

Additional workflow projections are also allowed:

```text
weak_permissible(h) iff h in {wajib, mandub, mubah, makruh}
ideal_positive(h)  iff h in {wajib, mandub}
path_excluding(h)  iff h = haram
path_demoting(h)   iff h = makruh
```

These projections must always name their semantics. The same verdict may participate in multiple projections.

## Path-filter interpretation

For contextual temporal deontic circuits, the five-fold verdict should control path ranking rather than collapse to a single allowed bit:

1. Remove paths realizing `haram` constraints.
2. Require paths to satisfy applicable `wajib` constraints.
3. Prefer paths realizing `mandub` constraints when available.
4. Demote but do not automatically remove paths realizing `makruh` constraints.
5. Treat `mubah` paths as neutral.
6. Treat `no_ruling` as outside the deontic kernel unless another rule applies.

This gives the path layer a finite-valued deontic ordering without pretending that every verdict is simply true or false.

## Boundary with the LLM harness

The LLM may propose:

- candidate condition gates;
- candidate subject/object normalization;
- candidate verdict tags;
- candidate projection explanations;
- candidate path-filter interpretations.

The LLM may not silently accept a Boolean collapse, infer a verdict from a projection alone, or treat `not forbidden` as `mubah`.

## Kernel obligations

The deterministic kernel should enforce:

1. every accepted deontic classification has exactly one finite verdict tag;
2. Boolean projections are derived from accepted tags only;
3. invalid reductions are rejected in fixtures;
4. path filters preserve the difference between exclusion, requirement, preference, demotion, and neutrality;
5. derivation traces retain the original finite verdict, not only a projected Boolean.

## First executable slice

The first buildable slice should add fixtures for the collapse boundary:

- `not_haram_is_not_mubah`;
- `not_wajib_is_not_haram`;
- `weak_permission_is_not_neutrality`;
- `makruh_is_permitted_but_demoted`;
- `mandub_is_permitted_but_preferred`;
- `haram_excludes_path`;
- `wajib_requires_path`.

These tests can be implemented before the full Ash resource layer because they depend only on the finite verdict algebra and projection table.