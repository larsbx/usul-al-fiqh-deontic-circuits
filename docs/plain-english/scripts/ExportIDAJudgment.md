# scripts.ExportIDAJudgment in Plain English

Source: [`formal/lean/scripts/ExportIDAJudgment.lean`](../../../formal/lean/scripts/ExportIDAJudgment.lean)

This executable emits actual Lean calculations for the complete declared
synthetic judgment family. The gate compares them with the independently
implemented Quint model.

| Section | Ordered input columns | Rows |
|---|---|---:|
| `codec` | Question tag 0..5; answer tag 0..37; zero | 228 |
| `admission` | Question family 0..4; registry status 0..3; variant 0..37 | 760 |
| `revalidation` | Question family 0..4; registry update 0..7; zero | 40 |

The CSV header is `section,a,b,c,result`. Codec result zero means the pair is
rejected; a successful roundtrip produces the answer tag plus one. Admission
and revalidation result codes run from zero for acceptance to eight for record
mismatch, with the intervening diagnostic meanings listed in the
[slice guide](../../research/ida-judgment-records.md).

Each admission variant changes a specific record, request, or registry field.
Each revalidation case first obtains an accepted baseline receipt and then
checks it against the stated registry update. Failure to obtain the initial
receipt is an export error, not evidence that revalidation was safe.

From `formal/lean`, build the module and run the exporter:

```sh
lake build Usul.Typing.IDAJudgment
lake env lean --run scripts/ExportIDAJudgment.lean
```

The full gate is `make ida-judgment` from the repository root, after installing
the pinned Quint dependencies. It separately rejects incomplete, duplicate,
malformed, or disagreeing exports. These calculations concern synthetic data
and do not authenticate any source or approval decision.
