# UsulTest.IDAJudgmentContracts in Plain English

Source: [`formal/lean/UsulTest/IDAJudgmentContracts.lean`](../../../formal/lean/UsulTest/IDAJudgmentContracts.lean)

This module fixes the required proposition types for the typed judgment slice.
Each named witness states its required proposition explicitly and refers
directly to the corresponding implementation or scenario theorem.

The contract checks complement the compiled axiom audit. An axiom audit can
show that a proof uses only allowed logical foundations while missing a weakened
claim. A witness with an explicit type must stop compiling if its referenced
theorem is changed to a weaker statement, even when its name is preserved.

The contracts cover typed serialization, preservation of returned records,
registry selection and complete binding, rejection boundaries, and the declared
finite scenarios. They are checked by `make ida-judgment`, alongside the
independent Quint model, output comparison, and negative controls.

They establish properties of the encoded registry check. Source authentication,
interpretation fidelity, approval authority, and application refinement retain
the separate obligations stated in the
[judgment slice guide](../../research/ida-judgment-records.md).
