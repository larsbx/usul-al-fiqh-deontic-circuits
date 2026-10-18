import Mathlib.Order.Lattice
import Mathlib.Order.Interval.Set.Basic
import Usul.Cat.Interval

/-!
# The hook: kernel scales as Mathlib orders

The kernel stays Mathlib-free; this package shows the bridge works at the pinned revision. The
taklīfī scale becomes a Mathlib `LinearOrder` through `Hukm.valence` (injective), and a kernel
`Span` is exactly a Mathlib `Set.Icc`. Later work can reach Mathlib's order theory from here
without touching `usul`.
-/

namespace UsulMathlib

open Usul Usul.Cat.Interval

/-- The valence chain Ḥ < K < M < N < W as a Mathlib linear order. -/
instance : LinearOrder Hukm :=
  LinearOrder.lift' Hukm.valence fun _ _ => Hukm.valence_injective

theorem hukm_le_iff {a b : Hukm} : a ≤ b ↔ a.valence ≤ b.valence := Iff.rfl

/-- A kernel span is the closed interval of its ends. -/
theorem span_eq_Icc (s : Span) : {h | Span.Mem h s} = Set.Icc s.lo s.hi := rfl

/-- Two spans meet iff the Mathlib intervals intersect. -/
theorem meets_iff_Icc (s t : Span) : Span.Meets s t ↔ (Set.Icc s.lo s.hi ∩ Set.Icc t.lo t.hi).Nonempty := by
  rw [Span.meets_iff_exists]; rfl

end UsulMathlib
