# Usul.Typing.IDACaseWorkbench in Plain English

Source: [`formal/lean/Usul/Typing/IDACaseWorkbench.lean`](../../../../formal/lean/Usul/Typing/IDACaseWorkbench.lean)

This module provides a checked presentation boundary for the existing synthetic
contextual pilot. Its four report statuses describe observations in the supplied
report list: unknown means neither sign, supported means positive only, refuted
means negative only, and conflicted means both signs. These statuses are not
truth values, evidence-admission decisions, probabilities, or juristic rulings.

The four status equivalences prove the exact sign pair for every label. The
round-trip laws show that the presentation loses neither sign. It still forgets
individual source rows; the checked view retains the complete snapshot and
certificate lists separately.

A `View` contains an existing `Pilot.Receipt`. Its snapshot, dependencies,
premises, conclusion, and certificate occurrences are derived from that receipt.
There is no input that accepts an agent's prose or a submitted verified flag as
such a receipt. This is a typed Lean boundary; it is not a proof of a browser,
the host runtime, or general uploaded-case ingestion.

| Theorem | What it establishes |
| --- | --- |
| `unknown_iff`, `supported_iff`, `refuted_iff`, `conflicted_iff` | Each status identifies exactly one of the four sign pairs. |
| `signs_roundtrip`, `status_roundtrip` | Converting between the status and its signs preserves either value exactly. |
| `status_injective` | Equal report status implies equal positive and negative existence signs. |
| `guard_requires_supported_refuted` | A successful existing pilot guard has exact scope, positive-only support, and negative-only exception reports. |
| `support_conflict_blocks`, `exception_conflict_blocks` | A conflict in either required query blocks the pilot guard. |
| `unknown_exception_blocks` | Missing exception reports cannot stand in for an explicit negative exception report. |
| `View.exact_snapshot`, `View.current_snapshot` | The view retains the complete admitted destination snapshot, resolved against the receipt's supplied current authority. |
| `View.exact_premises`, `View.exact_certificates` | Displayed grounded premises match the destination plan and the ordered certificate formulas exactly. |
| `View.all_source_occurrences` | Source and destination certificate occurrences remain in their original concatenated order. |
| `View.explicit_report_states` | A checked view has the guard's precise support and exception states. |
| `View.nonvacuous` | At least one of the supplied histories is compatible with the destination premises. |
| `View.conditional_sound` | The displayed conclusion holds in a history when the destination premises hold there. The premise-satisfaction assumption remains explicit. |

The host must separately authenticate source and premise bytes and provide
current authority inputs. A human adjudicator's or mufti's determination remains
separate from the conditional calculation and its descriptive report statuses.
