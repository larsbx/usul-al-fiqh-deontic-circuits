# Usul.Typing.IDAContext in Plain English

Source: [`formal/lean/Usul/Typing/IDAContext.lean`](../../../../formal/lean/Usul/Typing/IDAContext.lean)

This module checks exact ground snapshots and ties them to an existing IDA
source premise without changing the premise or issuing a ruling.

| Theorem | What it establishes |
|---|---|
| `decode_encode`, `encode_decode`, `encode_injective` | The versioned typed wire has an exact inverse on successful decoding and identifies the entire payload. |
| `resolve_iff`, `resolve_unique`, `resolve_rigid` | A successful lookup is well-formed, identifies one catalog row, and preserves the complete target, accountable participant, named performer, and temporal view. |
| `typed_arguments`, `resolved_target_wellFormed` | A declared predicate has the requested ordered argument sorts and a resolved target satisfies the existing structured target checker. |
| `changed_snapshot_stale`, `changed_qualification_stale`, `no_target_factorization` | Changing an exact snapshot makes it stale against the selected row. Even a qualification change that leaves the target identical can invalidate lookup. |
| `ambiguous_rejected`, `inconsistent_rejected`, `time_identity_unique` | Catalog conflicts block lookup and a legacy time ID fixes its effective clock and tick within the catalog. |
| `bind_iff` | Success returns the original source premise and exact snapshot after the declared inquiry fields match. |
| `omission_clock`, `phase_closes` | An omission uses the inquiry clock and its well-formed opportunity is closed at the closing tick. |

The bounded ACT-08 agency review uses one fixed appointment, one execution
attempt, one revocation report, and optional explicit notice to A. The report
records the revocation's effective time and the evaluator's recording time
separately. `reviewAgency_unseen` proves that a well-formed report outside
the cutoff cannot change replay in that view.
