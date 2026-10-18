# Usul.Cat in Plain English

Source: [`formal/lean/Usul/Cat.lean`](../../../formal/lean/Usul/Cat.lean)

The category-theory layer of the kernel, gathered in one import. Its job is compositional specification: the scales of the sciences become categories, and the links between them become functors.

## What it imports

- **`Usul.Cat.Basic`**: categories, opposites, thin categories of preorders, functors, up-sets.
- **`Usul.Cat.Scales`**: the rulings, certainty and ḥadīth scales as categories, and the seams as functors.
- **`Usul.Cat.Factor`**: factoring a rule through the case data it reads.
- **`Usul.Cat.Sheaf`**: gluing partial rulings, and ikhtilāf (disagreement) as the obstruction.
- **`Usul.Cat.Institution`**: rules and readings as an institution (logic-independent specification).
- **`Usul.Cat.Carriers`**: the categories carrying each kind of derivation.
- **`Usul.Cat.Typing`**: typed encoders as a category.

## In one line

One import brings in the whole category-theory specification layer.
