# UsulTest.IDAJudgment in Plain English

Source: [`formal/lean/UsulTest/IDAJudgment.lean`](../../../formal/lean/UsulTest/IDAJudgment.lean)

These executable Lean checks exercise the typed judgment and registry contract
implemented by [Usul.Typing.IDAJudgment](../Usul/Typing/IDAJudgment.md). They use
explicitly synthetic records; no fixture declares a real source interpretation
admitted.

The cases distinguish taklifi sets, Boolean signs, and validity answers, while
retaining missing and suspended states. They check the ordered validation
diagnostics, evidence and capacity requirements, source-reference shape, exact
metadata binding, registry status, duplicates, snapshot changes, and receipt
revalidation.

These finite examples complement the implementation's general theorems. The
independent Quint comparison covers the separately declared 1,028-row family;
neither finite exercise enumerates every possible source, context, or registry.
The [slice guide](../../research/ida-judgment-records.md) states the precise bounds
and the distinction between registry consistency and source fidelity.
