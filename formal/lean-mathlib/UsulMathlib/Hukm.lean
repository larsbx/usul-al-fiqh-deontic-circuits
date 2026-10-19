import Mathlib.Order.Lattice
import Mathlib.Order.Interval.Set.Basic
import Usul.Cat.Interval

/-!
# The hook: kernel scales as Mathlib orders

The kernel stays Mathlib-free; this package shows the bridge works at the pinned revision. The
taklīfī order, read off each status's reward and liability for doing and leaving, is a Mathlib
`LinearOrder` with no rank behind it, and a kernel `Span` is exactly a Mathlib `Set.Icc`. Later work can reach Mathlib's order theory from here
without touching `usul`.
-/

namespace UsulMathlib

open Usul Usul.Cat.Interval

/-- The chain Ḥ < K < M < N < W as a Mathlib linear order, from the kernel's own laws. -/
instance : LinearOrder Hukm where
  le := (· ≤ ·)
  le_refl := Hukm.le_refl
  le_trans _ _ _ := Hukm.le_trans
  le_antisymm _ _ := Hukm.le_antisymm
  le_total := Hukm.le_total
  toDecidableLE := inferInstance

/-- The Mathlib order is the kernel's: doing fares no worse, leaving no better. -/
theorem hukm_le_iff {a b : Hukm} : a ≤ b ↔ a.fil.leb b.fil = true ∧ b.tark.leb a.tark = true := Iff.rfl

/-- A kernel span is the closed interval of its ends. -/
theorem span_eq_Icc (s : Span) : {h | Span.Mem h s} = Set.Icc s.lo s.hi := rfl

/-- Two spans meet iff the Mathlib intervals intersect. -/
theorem meets_iff_Icc (s t : Span) : Span.Meets s t ↔ (Set.Icc s.lo s.hi ∩ Set.Icc t.lo t.hi).Nonempty := by
  rw [Span.meets_iff_exists]; rfl

end UsulMathlib
