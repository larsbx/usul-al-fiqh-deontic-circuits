# scripts.ExportIDA in Plain English

Source: [`formal/lean/scripts/ExportIDA.lean`](../../../formal/lean/scripts/ExportIDA.lean)

This executable prints the complete declared finite family of IDA computations as
CSV. The [IDA gate](../../research/ida-foundation.md) compares this actual Lean output
with output from the independently written Quint model.

## 1. Output and bounds

The header is exactly `section,a,b,c,result`. The following 8,767 rows appear in
the section order below, with the loop inputs in ascending numerical order.

| Section | Input columns | Rows |
| --- | --- | ---: |
| `meet` | `a` and `b` are carrier tags `0..4`; `c` is zero. | 25 |
| `join` | `a` and `b` are carrier tags `0..4`; `c` is zero. | 25 |
| `sigma` | `a` is a carrier tag `0..4`; `b` and `c` are zero. | 5 |
| `refine` | `a` is a key variant `0..7`; `b` and `c` are the left and right input tags `0..32`. | 8,712 |

For `refine`, the left key is fixed to seven zero coordinates. Right-key variant
zero matches it; variants 1 through 7 change exactly one coordinate to one, in
the order question, subject, target, context, time, profile, and version. This
exhausts the declared audit family, not all pairs of arbitrary keys.

Carrier results use tags `0..4`. Conjunction results use known-set masks `1..31`
or the tags no ruling (`0`), suspension (`32`), conflict (`33`), and out of scope
(`34`). These numerical encodings belong to separate typed interfaces.

## 2. Definitions and execution

| Definition | Plain English |
| --- | --- |
| `emitIDA` | Prints one successful encoded result; a rejected wire input raises an error and cannot silently become an output row. |
| `main` | Prints the header and evaluates every input in the declared loops through `meetCode`, `joinCode`, `sigmaCode`, or `refineCode`. |

From `formal/lean`, build the imported module and run the exporter:

```sh
lake build Usul.IDA
lake env lean --run scripts/ExportIDA.lean
```

For the full scoped acceptance gate, run `make ida` from the repository root
after installing the pinned Quint dependency as the foundation guide describes.
The gate separately checks missing, duplicate, malformed, noncanonical, and
disagreeing exports. Running this exporter alone does not perform those checks
or certify any source interpretation.
