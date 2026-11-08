# Usul.IDAJudgment in Plain English

Source: [`formal/lean/Usul/IDAJudgment.lean`](../../../formal/lean/Usul/IDAJudgment.lean)

This module adds records whose possible answers depend on the question asked.
A taklifi record carries rulings; a validity record carries validity values;
sabab, shart and mani records carry Boolean values. Known answer sets cannot be
empty. Missing answers, suspension, conflict and out-of-scope outcomes remain
distinct.

The replay rule checks a submitted record against a frozen derivation and an
external trusted snapshot. It binds all scope and provenance fields, checks
source enablement and current admission, and preserves the decoded answer.
Changing the submitted admission label cannot grant authority.

The proofs are conditional on the snapshot's trust. The module does not
authenticate a source, establish an interpretation or implement an admission
service. See the [judgment contract](../../research/ida-judgments.md).
