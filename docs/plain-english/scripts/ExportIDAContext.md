# scripts.ExportIDAContext in Plain English

Source: [`formal/lean/scripts/ExportIDAContext.lean`](../../../formal/lean/scripts/ExportIDAContext.lean)

The exporter computes the bounded Lean results in a fixed row order. Its table
records exact binding outcomes, half-open opportunity phases, and separate
candidate agency observations, including the bounded late-revocation review and omission observations. The verification gate compares those values
with the independently computed Quint table.
