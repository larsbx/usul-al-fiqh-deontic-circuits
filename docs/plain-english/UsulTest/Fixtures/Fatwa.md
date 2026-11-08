# UsulTest.Fixtures.Fatwa in Plain English

Source: [`formal/lean/UsulTest/Fixtures/Fatwa.lean`](../../../../formal/lean/UsulTest/Fixtures/Fatwa.lean)

These are the 300 fatwa expectations migrated from the v40 suite. They include kernel-bank checks, source-answer agreement, documented gaps, reported-position membership, and hand-written precedence examples.

The data is evaluated by the native Lean rule model. The gate requires exact agreement with the named legacy inventory and rejects each of the 29 original rule/equivalence mutations. Passing this finite suite preserves its modeled behavior; it does not authenticate source interpretations.
