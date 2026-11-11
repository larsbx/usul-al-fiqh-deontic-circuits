import Usul.Cat.Factor
import Usul.Typing.IDAProjection

/-! ACT-03 categorical adapter for the type-layer report evaluator. Equal
complete dependencies form a kernel groupoid; the proved factorization sends
its arrows to equal observation outcomes. This adds no evidence admission. -/

namespace Usul.Cat.IDAProjection

open Usul.IDA.Projection

/-- The concrete report evaluator is a functor from dependency equivalence to
strict equality of outcomes, using the independently proved exact projection. -/
theorem evaluation_functor (rule : Rule) :
    ∃ Φ : Functor (ker (project (r := r) rule)) (Cat.disc Outcome),
      Φ.obj = evaluate rule :=
  factors_iff_functor.mp (factors rule)

end Usul.Cat.IDAProjection
