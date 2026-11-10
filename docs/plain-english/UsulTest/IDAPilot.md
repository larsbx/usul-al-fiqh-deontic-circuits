# UsulTest.IDAPilot in Plain English

Source: [`formal/lean/UsulTest/IDAPilot.lean`](../../../formal/lean/UsulTest/IDAPilot.lean)

The shared fixture swaps the two people in a synthetic repayment inquiry.
The debt reference, clock and opportunity retain their identities. The
destination needs its own support and exception-exclusion certificates.
Lean checks one successful case and rejects missing or mismatched
certificates, stale authority, contradictory reports, and empty or
incompatible history populations.

The fixture also reviews a supplied omission batch for the same destination
snapshot. Its coverage and completion results are separate from the premise
certificates. Adding a report for the wrong participant preserves the guard
result while changing the snapshot. Adding a matching exception changes the
guard even though the target stays the same.
