# scripts.ExportIDAProjection in Plain English

Source: [`formal/lean/scripts/ExportIDAProjection.lean`](../../../formal/lean/scripts/ExportIDAProjection.lean)

The exporter emits finite comparisons in a fixed order. It reports direct
and projected outcomes, both signs of each report query, and equality of the
dependency, core, and kind projections.

## Row families

The CSV header remains `family,default,shape,left,right,results`. The first five
fields identify a row; the remaining fields contain the family's observations.
Each family has its own meaning for the four numeric coordinates:

| Family | `default` | `shape` | `left` | `right` | Rows | Observations per row |
|---|---|---|---|---|---:|---:|
| `case` | Fallback flag | Scope shape, 0–14 | Four-sign mask, 0–15 | Report-list variant, 0–5 | 2,880 | 10 |
| `pair` | Fallback flag | Fixed zero | Left four-sign mask | Right four-sign mask | 512 | 4 |
| `relabel` | Enabled flag | Fixed zero | `Hukm` feature code, 0–4 | Noise Boolean | 20 | 8 |
| `unattested` | Candidate known-feature ruling code, 0–4 | Candidate unseen-feature ruling code, 0–4 | Feature Boolean | Noise Boolean | 100 | 8 |
| `fivefold` | First ruling code, 0–4 | Second ruling code, 0–4 | Fixed zero | Fixed zero | 25 | 8 |

The original `case` and `pair` families come first, followed by `relabel` and
`unattested`, then `fivefold`. Ruling loops use the existing wire order
`haram, makruh, mubah, mandub, wajib`; the other loops increase from zero. The
complete output has 3,537 data rows and 32,008 observation cells. Row identity, order, width, and
value ranges are part of the comparison contract.

## New observation columns

The total ruling encoding from `Usul.IDA.encodeHukm` is `haram = 0`,
`makruh = 1`, `mubah = 2`, `mandub = 3`, and `wajib = 4`. These are constructor
codes, not numerical strengths or Boolean truth values.

For `relabel`, the projection and answer columns contain `Option Hukm` values.
Their container encoding is `0 = none` and `1 + encodeHukm h = some h`.
Consequently, `some mubah` has container code 3 and remains distinct from
absence. Container codes 1–5 encode the same five rulings; they do not extend
the total ruling encoding with a sixth value. Flags use `0 = false` and
`1 = true`.

| Column | Observation |
|---:|---|
| 1 | Original projection |
| 2 | Relabeled projection |
| 3 | Original applicability |
| 4 | Relabeled applicability |
| 5 | Original optional `Hukm` answer |
| 6 | Answer after applying the existing `sigma` duality |
| 7 | Whether the two projections are equal |
| 8 | Whether the two answers are equal |

For `unattested`, answer columns 1, 6, and 7 use the total ruling codes 0–4.
The other columns are Boolean checks. The first witness extension uses
`knownValue = wajib, unseenValue = mubah`; the second uses
`knownValue = wajib, unseenValue = mandub`. Each is an actual function on all
four situations. Both agree with the two known cases, whose supplied ruling
is `wajib`.

| Column | Observation |
|---:|---|
| 1 | Candidate extension's answer at this situation |
| 2 | Consistency of the actual known list under the feature projection |
| 3 | Candidate agreement with every known case |
| 4 | Candidate factorization across every pair of situations in the domain |
| 5 | Whether the situation's feature occurs in the known list |
| 6 | First witness extension's ruling |
| 7 | Second witness extension's ruling |
| 8 | Whether the two witness rulings are equal |

For `fivefold`, columns 1–6 use total ruling codes and columns 7–8 are Boolean
checks. All twenty-five pairs are evaluated through the actual Lean operations.

| Column | Observation |
|---:|---|
| 1 | First ruling `h` |
| 2 | Second ruling `k` |
| 3 | `meet h k` |
| 4 | `join h k` |
| 5 | `sigma h` |
| 6 | `sigma k` |
| 7 | Whether `sigma h = h`; true exactly for `mubah` |
| 8 | Whether `meet h k = haram` and `join h k = wajib`; true only for the two ordered endpoint pairs |

These columns compare synthetic functions, supplied examples, and the existing
fivefold algebra. They contain no source-authority or admission result. The
independent Quint model computes the same relations without importing the Lean
table. The report and snapshot-pair families retain their separate diagnostic
codes; those outcomes are not alternative encodings of `Hukm`.
