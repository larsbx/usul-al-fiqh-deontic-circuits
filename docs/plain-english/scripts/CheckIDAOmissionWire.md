# scripts.CheckIDAOmissionWire in Plain English

Source: [`formal/lean/scripts/CheckIDAOmissionWire.lean`](../../../formal/lean/scripts/CheckIDAOmissionWire.lean)

The replay adapter constructs its registry and current snapshots from the
existing synthetic Lean fixtures. The host sends the authenticated batch
through standard input. The adapter parses it into the typed wire format
and re-encodes it to check the exact field shape, then calls omission
review. It emits a JSON assessment or failure for the host test runner.
The template mode supplies a sample scope for building signed fixtures.

The pilot mode uses the exact guarded repayment destination fixture and
offers its scope in a separate template mode. A correctly signed batch
from the earlier transfer fixture fails scope comparison in pilot mode.
