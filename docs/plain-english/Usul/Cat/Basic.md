# Usul.Cat.Basic in Plain English

Source: [`formal/lean/Usul/Cat/Basic.lean`](../../../../formal/lean/Usul/Cat/Basic.lean)

Every scale in the kernel (ruling strength, certainty, ḥadīth verdicts) is an ordering, and an ordering is a category with at most one arrow between two objects. In such a category the functor laws come free, so any order-preserving map between scales is automatically a functor. That is what lets the links between the sciences be stated as functors.

## 1. Categories

- **`Cat`**: objects, arrows between them, identity arrows and composition, with the usual laws (identity, associativity). Built without Mathlib, like the rest of the kernel.
- **`Cat.op`**: the same category with every arrow reversed. Reversing twice gives back the original (`op_op`).
- **`Cat.thin`**: the category of a preorder. An arrow a ⟶ b is a proof that a ≤ b.
- **`Cat.scale`**: the thin category of a ranking into the natural numbers: a ⟶ b ⟺ rank a ≤ rank b.
- **`Cat.disc`**: only identity arrows. Arrows are equalities.
- **`Thin`**: any two parallel arrows are equal.

| Theorem | Plain English |
| --- | --- |
| `thin_thin` | The category of a preorder is thin. |
| `Thin.op` | Reversing arrows keeps a category thin. |
| `scale_thin`, `disc_thin` | Scales and discrete categories are thin. |

## 2. Functors

- **`Functor`**: a map on objects and arrows that keeps identities and composition.
- **`Functor.id`**, **`Functor.comp`**: the identity functor, and composition (first F, then G).
- **`Functor.intoThin`**: into a thin category, any object map that carries arrows is a functor. The laws hold automatically.
- **`Functor.ofMono`**: an order-preserving map between scales is a functor.
- **`Functor.ofAnti`**: an order-reversing map is a functor into the opposite scale.
- **`Functor.mono`**: conversely, a functor between scales preserves order.
- **`ObjIso`**: two functors inverse on objects. Between thin categories this is an isomorphism.

## 3. Up-sets

- **`UpSet`**: a set of objects closed along arrows. On a scale it is a threshold: once in, everything above is in.

| Theorem | Plain English |
| --- | --- |
| `UpSet.comap` | Up-sets pull back along functors: "F of a is in S" is again an up-set. |
| `UpSet.threshold` | On a scale, every set {a : t ≤ rank a} is an up-set. |

## In one line

Scales are thin categories, so order-preserving maps between them are functors for free, and thresholds are up-sets that pull back along those functors.
