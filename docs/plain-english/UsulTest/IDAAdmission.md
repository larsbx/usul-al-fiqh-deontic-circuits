# UsulTest.IDAAdmission in Plain English

Source: [`formal/lean/UsulTest/IDAAdmission.lean`](../../../formal/lean/UsulTest/IDAAdmission.lean)

The synthetic repayment fixture swaps two person slots. The debt identity
stays fixed, the source and destination use separately authorized evidence,
and the resulting contextual formula follows from a repeated assumption.

| Theorem | What it establishes |
|---|---|
| `nonidentity_admission` | The checked route succeeds across changed roles, target, formula, and admission policy. |
| `current_receipt_replays` | The derived receipt replays under the same current authority. |
| `nonidentity_semantics` | The fixed history satisfying the destination premise satisfies the reconstructed conjunction. |
| `adverse_controls` | The executable route rejects missing and mismatched premises, stale contexts and registry snapshots, revoked source authority, signature-token substitution, missing grants and evidence, stale replay, and changed inquiry, grounding, or policy. |
