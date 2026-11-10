# Usul.Typing.IDAOmission in Plain English

Source: [`formal/lean/Usul/Typing/IDAOmission.lean`](../../../../formal/lean/Usul/Typing/IDAOmission.lean)

This module distinguishes a missing completion report from a covered
observation view. It uses separate effective and recording times and
exact scope for a modeled opportunity.

| Theorem | What it establishes |
|---|---|
| `covered_iff` | A covered no-completion status requires effective closure, complete coverage, and no matching or malformed visible completion. |
| `observed_precedes_coverage` | A valid visible completion takes precedence over a coverage-based outcome. |
| `opening_boundary_included`, `closing_boundary_excluded` | The observation interval includes its opening tick and excludes its closing tick. |
| `unseen_append` | Appending a report beyond the cutoff preserves the current observation status. |
| `review_current` | Successful review requires exact current ACT-01 snapshot resolution. |
