# UsulTest.IDACaseWorkbench in Plain English

Source: [`formal/lean/UsulTest/IDACaseWorkbench.lean`](../../../formal/lean/UsulTest/IDACaseWorkbench.lean)

The workbench fixture reuses the existing ACT-08 repayment application and the
four source-bound certificates from authenticated premise ingestion. The
implementation revision is an argument of `sourceBoundTrial`; the host supplies
the exact clean revision for the export. The fixed proof fixture uses an explicit
synthetic revision. Supplying compiled source references to this formal fixture
does not authenticate external bytes or confer juristic authority.

| Theorem | What it checks |
| --- | --- |
| `source_bound_baseline_checked` | The source-bound synthetic baseline passes the existing pilot checker. |
| `source_bound_destination_unchanged` | Source binding preserves the exact destination snapshot. |
| `four_report_states` | The four possible report sign pairs have four distinct presentation labels. |
| `missing_and_conflicting_reports_block` | Missing exception exclusion or contradictory support/exception reports block the case. |
| `nonvacuity_controls` | Empty and incompatible history populations are rejected; the two compatible populations pass. |
| `current_authority_controls` | Missing/mismatched premise certificates, missing evidence, stale snapshots, and missing destination grants remain distinct rejection cases. |
| `kind_does_not_transfer_guard` | Equal act kind cannot preserve acceptance after an exception report changes. |

The exporter also evaluates the existing 384 pilot scenarios: sixteen report
masks, four supplied history populations, and six authority modes. This is a
declared finite family, not exhaustive checking of arbitrary real cases.
