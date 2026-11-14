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
| `relabel` | Enabled flag | Fixed zero | Feature Boolean | Noise Boolean | 8 | 8 |
| `unattested` | Candidate known-feature answer | Candidate unseen-feature answer | Feature Boolean | Noise Boolean | 16 | 8 |

The original `case` and `pair` families come first, followed by `relabel` and
`unattested`. Each numeric loop increases from zero. The complete output has
3,416 data rows and 31,040 observation cells. Row identity, order, width, and
value ranges are part of the comparison contract.

## New observation columns

For `relabel`, optional Boolean values use `0 = none`, `1 = some false`, and
`2 = some true`. Flags use `0 = false` and `1 = true`.

| Column | Observation |
|---:|---|
| 1 | Original projection |
| 2 | Relabeled projection |
| 3 | Original applicability |
| 4 | Relabeled applicability |
| 5 | Original optional answer |
| 6 | Relabeled optional answer |
| 7 | Whether the two projections are equal |
| 8 | Whether the two answers are equal |

For `unattested`, every observation is Boolean-coded. The low extension uses
`knownValue = true, unseenValue = false`; the high extension uses both values
true. Each is an actual function on all four situations.

| Column | Observation |
|---:|---|
| 1 | Candidate extension's answer at this situation |
| 2 | Consistency of the actual known list under the feature projection |
| 3 | Candidate agreement with every known case |
| 4 | Candidate factorization across every pair of situations in the domain |
| 5 | Whether the situation's feature occurs in the known list |
| 6 | Low extension's answer |
| 7 | High extension's answer |
| 8 | Whether the low and high answers are equal |

These columns compare synthetic functions and supplied examples. They contain
no source-authority or admission result. The independent Quint model computes
the same relations without importing the Lean table.
