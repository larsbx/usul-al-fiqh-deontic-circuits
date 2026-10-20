# UsulMathlib.Hukm in Plain English

Source: [`formal/lean-mathlib/UsulMathlib/Hukm.lean`](../../../formal/lean-mathlib/UsulMathlib/Hukm.lean)

The five rulings, ordered by their reward and liability for doing and leaving, form a Mathlib linear order, and a span of rulings is a Mathlib closed interval. Later work can use Mathlib's order theory on the kernel's types without the kernel importing Mathlib.

## 1. The scale as a Mathlib order

- **`LinearOrder Hukm`**: the order ḥarām < makrūh < mubāḥ < mandūb < wājib, built from the kernel's own laws (reflexive, transitive, antisymmetric, total). No numeric score is involved.

| Theorem | Plain English |
| --- | --- |
| `hukm_le_iff` | a ≤ b ⟺ doing fares no worse under b and leaving no better. The Mathlib order is the kernel's order. |

## 2. Spans as intervals

| Theorem | Plain English |
| --- | --- |
| `span_eq_Icc` | The rulings in a kernel span are exactly Mathlib's `Set.Icc lo hi`. |
| `meets_iff_Icc` | Two spans meet ⟺ their Mathlib intervals overlap. |

## In one line

The kernel's ruling scale and spans are, by definition, Mathlib's linear orders and closed intervals.
