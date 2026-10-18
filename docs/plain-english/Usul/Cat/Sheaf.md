# Usul.Cat.Sheaf in Plain English

Source: [`formal/lean/Usul/Cat/Sheaf.lean`](../../../../formal/lean/Usul/Cat/Sheaf.lean)

Several partial rulings combine into one consistent ruling exactly when no two of them disagree on a shared situation. When they don't combine, the disagreement (ikhtilāf) is a concrete, findable fact. This is the sheaf gluing condition applied to legal verdicts.

## 1. Basic vocabulary

- **Situations (`X`)**: the possible cases or facts on the ground.
- **Verdicts (`β`)**: the possible rulings, e.g. wājib, mubāḥ, ḥarām.
- **Context (`Ctx`)**: a set of situations, given as a yes/no test on each situation.
- **Site**: contexts ordered by inclusion. "U ≤ V" means every situation in U is also in V.
- **Section over U**: a local verdict. It assigns a ruling to every situation in U and says nothing outside U.
- **Restriction**: apply a ruling made for a broad context to a narrower one, ruling the same way on what remains. Restricting to the same context changes nothing, and two restrictions in a row equal one. Both laws hold by definition.

## 2. Covers and agreement

- **Cover of U**: patches (sub-contexts) inside U such that every situation in U falls under at least one patch. Think of patches as authorities, sources, or lines of reasoning, each speaking to part of the domain.
- **Matching**: wherever two patches overlap, they give the same ruling.
- **Glues to g**: g is a single ruling over all of U that agrees with every patch on its own territory.
- **Obstruction (ikhtilāf witness)**: a record of two patches, one situation both cover, and proof that they rule differently there.

## 3. The theorems

| Theorem | Plain English |
| --- | --- |
| `matching_of_glues` | If a unified ruling exists, the patches already agree on overlaps. |
| `glue_unique` | There is at most one unified ruling: every situation is covered by some patch, and that patch fixes the answer. |
| `gluing` | **Main lemma.** Patches agree on overlaps ⟺ a unified ruling exists. Build it by picking any patch covering each situation; agreement makes the choice irrelevant. |
| `no_glue_of_obstruction` | One concrete disagreement rules out a unified verdict. |
| `no_glue_iff_obstruction` | **Converse.** No unified ruling ⟺ an explicit disagreement witness exists. Failure to merge is never vague. |

In short: ¬∃ unified ruling ⟺ ∃ ikhtilāf witness.

## 4. The finite, computable version

The abstract part uses arbitrary predicates. This part makes everything checkable by running code.

- **Patch**: a named record with a yes/no test for which situations it covers and a verdict function.
- **`support`**: the situations, out of a finite list, covered by at least one patch.
- **`cover` / `sections`**: turn a patch list into the abstract cover and local rulings from §2.
- **`obstructions`**: checks every pair of patches against every listed situation and returns each disagreement as a (patch, patch, situation) triple. Each disagreement appears twice, as (p, q) and (q, p).
- **`obstructions_nil_iff`**: the checker returns an empty list ⟺ any two patches covering the same listed situation rule the same there.
- **`glues_iff_obstructions_nil`**: the **finite sheaf condition**. The patches merge into one ruling ⟺ the checker finds nothing. Consistency becomes a computation, proven to mean what it claims.

## 5. Takhrīj as a special case

Take a single case, the farʿ (the new case being derived), as a site with one situation.

- **`positions`**: each reported position becomes a patch covering that one situation and ruling as the position does.
- **`positions_glue_iff`**: the positions merge into one ruling ⟺ all reported positions are equal.

In the field's terms: a case has a single settled ruling exactly when there is no ikhtilāf over it. When there is, the checker returns the conflicting positions by name.

## In one line

Rulings from different sources combine exactly when they agree wherever they overlap. When they don't, ikhtilāf is a specific pair of positions at a specific situation, and for finite cases a program lists every such pair, with a proof that the list is right.
