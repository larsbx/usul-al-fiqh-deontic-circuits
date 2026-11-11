# UsulTest.IDAProjectionContracts in Plain English

Source: [`formal/lean/UsulTest/IDAProjectionContracts.lean`](../../../formal/lean/UsulTest/IDAProjectionContracts.lean)

These fixed Lean statements independently specify exact projection,
equivalence, append, fallback, and counterexample obligations for the gate.
The categorical contract requires a functor from the complete dependency
projection's kernel to discrete observation outcomes, with the concrete
evaluator as its exact object map. This checks the statement of
`Usul.Cat.IDAProjection.evaluation_functor`; the gate also requires that named
theorem in its compiled proof inventory.
