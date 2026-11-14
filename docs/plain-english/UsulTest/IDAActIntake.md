# UsulTest.IDAActIntake in Plain English

Source: [`formal/lean/UsulTest/IDAActIntake.lean`](../../../formal/lean/UsulTest/IDAActIntake.lean)

These synthetic fixtures exercise candidate preparation against the existing
ACT-01 registry data. They do not assign fiqh rulings or treat candidate source
interpretations as admitted.

## Fixture domain

`fromEnvelope` retains kind/version, digest, snapshot, qualifications, context,
and operands from the older structural fixtures. It deliberately has no input
operation/signature field. The two older fixtures that changed only a caller's
operation therefore become the same intake value. This test-only conversion does
not mean that the JSON intake accepts extra operation fields: its strict decoder
rejects those fields.

The priority matrix covers 14 registry variants and 36 input variants, or 504
cases. `expectedPreparation` states the expected outcomes independently from the
preparation implementation. Cases distinguish whole-registry ambiguity, malformed
registry data, snapshot mismatch, unknown kinds, changed digest pins, unresolved
roles, operand mismatch, and malformed descriptions.

| Theorem | Observation |
| --- | --- |
| `preparation_matrix` | Every declared case matches the independent diagnostic table. |
| `signature_is_derived` | The valid fixture reconstructs the registered operation; operation-only changes are absent from the input type. |
| `same_sort_swap_retained` | Swapping person references can remain structurally valid but changes the complete envelope. |
| `qualifications_and_context_retained` | Changed polarity or evidence revision survives in the result instead of being discarded. |
| `unresolved_is_not_unknown` | A known definition with an unresolved role is different from an unknown definition; neither produces a draft. |
| `malformed_operands_rejected` | Wrong order, wrong sort, empty reference names, and missing operands are rejected. |

Positive cases prevent an always-rejecting implementation from satisfying the
fixture suite. The universal preservation and rejection properties are in the
[implementation companion](../Usul/Typing/IDAActIntake.md). Finite fixture success
is reported separately from the source interpretation and authority boundaries.
