# scripts.ExportIDACaseWorkbench in Plain English

Source: [`formal/lean/scripts/ExportIDACaseWorkbench.lean`](../../../formal/lean/scripts/ExportIDACaseWorkbench.lean)

The exporter runs the source-bound synthetic pilot at the implementation
revision supplied by its host. A rejected baseline stops the export. A passing
baseline is presented through `CaseWorkbench.View`, which contains the existing
proof-carrying contextual receipt.

The JSON output has schema `ida-case-workbench-lean-v1`. It includes the complete
snapshot as Lean's structural representation, readable typed inquiry pins,
both signs and the exact status for each report query, grounded formulas as
readable strings and structured syntax, source/destination certificate
occurrences and references, and candidate/compatible history counts. The
representation is for inspection, not a claimed canonical wire codec. The host
checks and binds the revision; the argument alone does not authenticate it.

The exporter computes all 384 existing pilot scenarios. Each row identifies its
report mask, population, authority mode, guard, projection outcome, semantic
assessment, and precise result code. Observation summaries and semantic
assessments remain separately visible even when application admission fails.

All content and authorities in this export are synthetic fixtures. Source and
premise signatures must be checked by the separate native adapters. No arbitrary
uploaded case is accepted, and no adjudicator's or mufti's decision is generated.
