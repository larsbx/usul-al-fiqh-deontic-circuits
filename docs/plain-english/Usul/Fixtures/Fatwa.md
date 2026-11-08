# Usul.Fixtures.Fatwa in Plain English

Source: [`formal/lean/Usul/Fixtures/Fatwa.lean`](../../../../formal/lean/Usul/Fixtures/Fatwa.lean)

This module implements the finite fatwa fixture rule evaluation in Lean. Rules are ordered, and the answer retains the selected rule so a specific exception cannot be silently replaced by a general fallback. Bank evaluation reuses the existing Lean kernel where applicable.

Documented oracle gaps remain explicit, and a disputed case is checked against its reported positions without choosing one universally authoritative ruling. The migration covers the declared cases and controls; it is not a claim of equivalence for arbitrary Prolog programs.
