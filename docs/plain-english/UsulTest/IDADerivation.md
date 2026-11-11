# UsulTest.IDADerivation in Plain English

Source: [`formal/lean/UsulTest/IDADerivation.lean`](../../../formal/lean/UsulTest/IDADerivation.lean)

This module supplies deterministic synthetic fixtures and ten kernel-checked
scenario requirements for the [source derivation model](../Usul/Typing/IDADerivation.md).
It contains no real source interpretation or juristic admission. Its two source
references describe the four-byte ASCII fixtures `IDA\n` and `IDB\n`, with
half-open passage range `[1,3)`. The actual source and passage SHA-256 bytes are
included, and the external gate checks all 136 exported source-reference cells
against the independently authenticated byte adapter.

## Adversaries

The source cases exercise candidate, quarantined, and revoked registry entries;
substituted source or passage hashes; changed passage locations; missing, stale,
and duplicate current-version pins; missing, duplicate, conflicting, disputed,
suspended, and unauthenticated evidence; evidence bound to a different question
identity or grade; missing and suspended payloads; claimed derivation premises
on a source leaf; unsupported source-rule identities; and changed snapshots or
implementation revisions.

Pair cases cover all 33 by 33 taklifi payload combinations and all four by four
payload combinations in each of the four sign/validity families. Twelve scope
mutations independently change the question identity, question family, subject
identity, each capacity bit, target identity, target kind, context, time, profile,
profile version, and domain. Three tree shapes check that nested rejection and
duplicate source occurrences preserve every blocker and source.

The shared textual [wire contract](../../research/ida-derivation-wire.md) specifies
these fixtures and their output order. The Lean fixtures were written against
that contract independently of the Quint semantic implementation.

## Fixed scenario requirements

| Theorem | Required behavior |
|---|---|
| `source_catalog_shapes` | Both actual synthetic references have valid digest/range shape and exactly 68 source cells. |
| `leaf_guard_matrix` | Every one of the 160 source variants has its specified primary diagnostic. |
| `source_full_values` | Each family returns the exact expected known answer, question identity, full scope, and original source premise. |
| `taklifi_full_values` | All 1,089 taklifi pairs equal independently specified complete outputs, using numeric mask intersection only in the expected fixture calculation. |
| `typed_full_values` | All 64 sign/validity pairs equal complete expected outputs. |
| `scope_guard_matrix` | The baseline passes and all twelve scope mutations produce out-of-scope, preserving the exact submitted records. |
| `nested_blocker_matrix` | All 30 nested cases retain the specified ordered blockers and every repeated source occurrence. |
| `alternatives_unselected` | Conflicting interpretations remain two ordered alternatives; a candidate alternative stays blocked; conjoining conflicting accepted alternatives is a conflict. |
| `receipt_mutation_matrix` | The original receipt verifies and all fifteen current-environment or stored-data mutations fail. |
| `forged_admission_rejected` | A caller-constructed structurally accepted result with a substituted answer fails receipt verification. |

Full-value equalities compare the typed conclusion, complete scope, ordered
issues, and complete provenance records. They are stronger than comparison of
status codes or compact export projections. All ten are proved by ordinary
kernel-checked finite decisions; none uses `native_decide`, an admitted proof,
or a Quint oracle.

The ACT-00 scenarios cover equal acts, omissions and affects, role and
occurrence changes, a malformed signature, version and source mismatches, and
reuse of legacy authority. Replay also checks a changed target in the stored
conclusion and in the current registry.
