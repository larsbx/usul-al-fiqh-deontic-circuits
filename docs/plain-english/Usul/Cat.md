# Usul.Cat in Plain English

Source: [`formal/lean/Usul/Cat.lean`](../../../formal/lean/Usul/Cat.lean)

The category-theory layer of the kernel, gathered in one import. Its job is compositional specification: the scales of the sciences become categories, and the links between them become functors.

## What it imports

- **`Usul.Cat.Basic`**: categories, opposites, thin categories of preorders, functors, up-sets.
- **`Usul.Cat.Scales`**: the rulings, certainty and ḥadīth scales as categories, and the seams as functors.
- **`Usul.Cat.Factor`**: qiyās (analogy) as factorization of a ruling through its ʿilla (effective cause).
- **`Usul.Cat.Sheaf`**: gluing partial rulings, and ikhtilāf (disagreement) as the obstruction.
- **`Usul.Cat.Institution`**: institutions and comorphisms: when checking a claim in another tool proves it.
- **`Usul.Cat.Carriers`**: Lean, TLA+ and Haskell as institutions on a shared Boolean fragment.
- **`Usul.Cat.Typing`**: the category of typed encoders, built on the qāʿida types.

## In one line

One import brings in the whole category-theory specification layer.
