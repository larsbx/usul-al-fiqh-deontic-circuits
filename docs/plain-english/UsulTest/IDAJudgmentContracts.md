# UsulTest.IDAJudgmentContracts in Plain English

Source: [`formal/lean/UsulTest/IDAJudgmentContracts.lean`](../../../formal/lean/UsulTest/IDAJudgmentContracts.lean)

These witnesses fix the propositions required for acceptance of source-bound
judgment replay. They refer directly to the corresponding implementation
theorems, so retaining a theorem name with a weaker type cannot satisfy the
contract.

Compiled axiom auditing independently checks the proofs and their imported
dependencies. Passing both checks proves the stated replay model, while trust
in the external snapshot and correspondence to actual legal sources remain
separate obligations.
