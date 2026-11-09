# Checked act registry and source bindings

Companion to [Usul.Typing.IDAActRegistry](../../../../formal/lean/Usul/Typing/IDAActRegistry.lean).

A performed-action description declares a versioned kind and ordered named
arguments. This module checks that declaration against a complete registry.
Duplicate kind/version keys invalidate the registry before lookup. Unresolved
argument sorts remain unresolved; successful resolution proves the supplied
operation and argument schema match the unique definition.

Qualifications carry their predicate/version, typed arguments, polarity, and
source-mention identifier as candidate data. A snapshot retains context/time
coordinates, profile/interpretation pins, evidence revision, and explicit clock
and temporal metadata. Structural checking does not establish their meaning or
truth.

The existing target representation retains only the action. The projection is
explicitly lossy, so the source-binding gate compares the full envelope and
premise against a unique trusted binding entry. It independently checks the
target and repeated snapshot coordinates, then calls the existing source
evaluator. Its universal contracts require actual source admissibility and a
known answer. There is no request-supplied admission flag.

Receipts retain the complete authority, request, definition, and source result.
Verification recomputes the gate. Structural wire round trips preserve all
declared data, including role order and unresolved markers. The host separately
verifies canonical JSON bytes and definition SHA-256.

See the [ACT-01 implementation contract](../../../research/ida-act-registry.md)
for scope, trusted inputs, and reproduction.
