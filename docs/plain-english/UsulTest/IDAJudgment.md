# UsulTest.IDAJudgment in Plain English

Source: [`formal/lean/UsulTest/IDAJudgment.lean`](../../../formal/lean/UsulTest/IDAJudgment.lean)

These examples exercise question-indexed decoding and source-bound replay.
They check that invalid answer types, changed source or scope bindings, stale
derivations and unadmitted records cannot become accepted judgments. Successful
replay preserves missing, suspended, conflicting and out-of-scope outcomes.

The finite examples use synthetic references and admission snapshots. They are
verification fixtures, not admitted legal positions. Universal binding claims
are stated separately in the implementation module.
