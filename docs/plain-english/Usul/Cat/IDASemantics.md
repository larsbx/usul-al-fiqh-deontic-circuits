# Usul.Cat.IDASemantics in Plain English

Source: [`formal/lean/Usul/Cat/IDASemantics.lean`](../../../../formal/lean/Usul/Cat/IDASemantics.lean)

This module packages the type-layer ACT-04 interpretation in the existing
category interface. Valuations form a functor on typed contexts; functions
from valuations form meaning presheaves. The interpretation and formula
evaluation commute with the corresponding presheaf maps.

The underlying valuations, interpreters, conditional soundness proofs, and
finite candidate assessment are defined independently in
[`Usul.Typing.IDASemantics`](../Typing/IDASemantics.md). Admission and pilot
code use that type-layer module without importing these categorical adapters.

| Theorem | What it establishes |
|---|---|
| `description_naturality`, `formula_naturality` | The two interpretations commute with the maps of their valuation-based meaning presheaves. |

The `valuations` and `meanings` functors use the already proved identity and
composition laws. These constructions do not authenticate reports or admit a
ruling.
