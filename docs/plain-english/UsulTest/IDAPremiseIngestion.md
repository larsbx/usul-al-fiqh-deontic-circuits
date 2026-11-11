# UsulTest.IDAPremiseIngestion in Plain English

Source: [`formal/lean/UsulTest/IDAPremiseIngestion.lean`](../../../formal/lean/UsulTest/IDAPremiseIngestion.lean)

The guarded repayment fixture supplies four scoped certificates over two
synthetic passages. Its nine cases cover successful replay and failures for
missing source evidence, revoked grants, stale context and interpretation,
cross-profile reuse, mismatched inquiry, duplicate tokens, and missing
certificates. The host separately verifies signatures and SQLite recovery.
