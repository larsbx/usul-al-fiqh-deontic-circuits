# UsulTest.IDAOmissionEventBridge in Plain English

Source: [`formal/lean/UsulTest/IDAOmissionEventBridge.lean`](../../../formal/lean/UsulTest/IDAOmissionEventBridge.lean)

The fixtures stipulate an empty checkpoint and a populated checkpoint with
direct and alternate events independently of the observation batch. The
production checker and native evaluator run on both. The wire fixture also
uses the repository's synthetic context resolver and typed observation view.

| Case | Checked behavior |
|---|---|
| Empty and populated checkpoints | A guarded negative proves absence in the empty checkpoint. Timely reports for both populated modes yield an observed completion. |
| Missing and fabricated observations | An empty or partial batch fails against a populated source. An unbacked matching report fails against either fixture. |
| Scope and timing | A different scope, changed cutoff, late report, inverted occurrence and recording ticks, or report predating capture is rejected. Recording exactly at the cutoff is permitted. A pinned source row with inverted chronology also fails. |
| Ordering and multiplicity | Report permutation and repeated reports preserve the existential outcome. Duplicate source IDs fail. Distinct IDs can carry the same native event content. Reordering the source snapshot changes its pin comparison. |
| Current authority and complete snapshot | No active pin, an old revision, truncated rows, and an insufficient seal each fail. |
| Structural coverage | An accepted empty event checkpoint with no coverage claim still yields `coverageMissing`. |
| Boundary with actual history | An empty pinned checkpoint and empty batch can pass while missing an independently stipulated event. A populated checkpoint and matching batch can pass even when an independently stipulated history is empty. |
| Wire and current context | Covered review of the exact current wire snapshot yields source-relative absence. A wrong wire scope or stale context fails the respective required guard. |

Run `lake build UsulTest.IDAOmissionEventBridge` from `formal/lean` for the
targeted controls. Run `make lean` from the repository root for the compiled
whole-core audit, including the bridge and these controls.
