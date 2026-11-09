# scripts.ExportIDAContext in Plain English

Source: [`formal/lean/scripts/ExportIDAContext.lean`](../../../formal/lean/scripts/ExportIDAContext.lean)

The exporter computes the bounded Lean results in a fixed row order. Its table
records exact binding outcomes, half-open opportunity phases, and separate
candidate agency observations, including the bounded late-revocation review. The verification gate compares those values
with the independently computed Quint table.

The omission rows cross effective and recording times with completion
and coverage scenarios in the independent comparison's fixed order.
