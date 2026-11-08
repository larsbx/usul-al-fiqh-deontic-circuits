# UsulTest.IDA in Plain English

Source: [`formal/lean/UsulTest/IDA.lean`](../../../formal/lean/UsulTest/IDA.lean)

These checks fix the wire format and exercise the boundary cases of
[Usul.IDA](../Usul/IDA.md). Each theorem is checked by Lean's decision procedure.
They complement the general algebra and conjunction theorems and the independent
Lean–Quint export comparison.

## 1. Declared finite domain

| Theorem | Plain English |
| --- | --- |
| `wire_tags` | The five carrier values encode as `haram = 0`, `makruh = 1`, `mubah = 2`, `mandub = 3`, and `wajib = 4`. |
| `all_masks_decode` | Every mask from 1 through 31 constructs a known nonempty constraint. |
| `all_inputs_decode` | Every input tag from 0 through 32 decodes: no ruling, a known constraint, or suspension. |
| `all_key_variants_decode` | All eight declared key variants decode: the matching key and one mismatch for each of its seven fields. |

The five carrier tags and the partial-answer tags use separate interfaces. For
example, the partial-answer mask `4` denotes `{mubah}`, while the carrier tag `4`
denotes `wajib`.

## 2. Required-premise and scope cases

| Theorem | Plain English |
| --- | --- |
| `missing_required` | A missing input combined with the explicit all-five constraint stays missing, on either side. |
| `suspension_priority` | With equal keys, suspension takes precedence over a missing input, on either side. |
| `key_priority` | Each individual key mismatch produces out of scope, even when both inputs are suspended or both are missing. |
| `intersect_compatible` | `{haram, makruh, mubah}` combined with `{makruh, mubah}` gives exactly `{makruh, mubah}`. |
| `intersect_conflict` | The disjoint known answers `{haram}` and `{wajib}` produce conflict. |
| `all_constraint_identity_on_known` | For every nonempty known set, intersecting with the explicit all-five constraint returns that set. This statement assumes a known second input. |
| `mubah_explicit` | A specific `{mubah}` answer survives intersection with the all-five constraint. |
| `invalid_codes` | The listed out-of-range carrier, key-variant, and partial-answer codes return `none` rather than a result tag. |

`none` here means a rejected wire input. It differs from the successfully decoded
no-ruling result `some 0`. These examples do not supply source evidence, resolve
juristic alternatives, or assert that every possible pair of natural-number keys
has been enumerated.
