# scripts.ExportIDADerivation in Plain English

Source: [`formal/lean/scripts/ExportIDADerivation.lean`](../../../formal/lean/scripts/ExportIDADerivation.lean)

This executable emits 11,032 deterministic cells for independent replay of the
source-bound derivation semantics. It reads no Quint output. The CSV header is
`section,a,b,c,result`. The gate checks the exact domain, order, uniqueness,
numeric representation, and agreement of the two exports.

| Section | Fixture domain | Cells |
|---|---|---:|
| `source` | Two source references, each 68 cells | 136 |
| `leaf` | Five question families, 32 variants, eight projections | 1,280 |
| `taklifi` | 33 by 33 payload pairs, eight projections | 8,712 |
| `typed` | Four families, 16 payload pairs, eight projections | 512 |
| `scope` | Baseline plus twelve independent mutations, eight projections | 104 |
| `tree` | Ten variants, three tree shapes, eight projections | 240 |
| `alternatives` | Two scenarios, two ordered alternatives, eight projections | 32 |
| `replay` | Original receipt plus fifteen mutations | 16 |

Except for source references and replay flags, the eight projections encode the
primary diagnostic, candidate/admitted classification, question identity, question
family, known answer, provenance length, ordered issues, and ordered entry
identities. The exact format and fixture edits are fixed by the
[wire contract](../../research/ida-derivation-wire.md).

The issue fold uses base 32, and the entry-identity fold uses base 16. These are
compact fixture projections, not cryptographic hashes or encodings of arbitrary
complete records. Complete output preservation is checked separately by the
universal Lean proofs, full-value finite Lean theorems, and independent Quint
tests. The source section includes both full digests and passage locations so
the gate can bind the finite replay to the actual synthetic byte adapter.

From `formal/lean`, build the scenario module and run:

```sh
lake build UsulTest.IDADerivation
lake env lean --run scripts/ExportIDADerivation.lean
```

The repository-level gate is `make ida-derivation`. Its receipt binds revision,
inputs, tool versions, outputs, and adversarial controls. Successful bounded
replay supports this declared fixture domain; the arbitrary-tree claims come
from the Lean proofs. These fixtures do not establish any real legal ruling.
