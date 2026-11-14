# UsulTest.IDAStructuralCasesContracts in Plain English

Source: [`formal/lean/UsulTest/IDAStructuralCasesContracts.lean`](../../../formal/lean/UsulTest/IDAStructuralCasesContracts.lean)

These wrappers require the exact propositions used by the ACT-08 structural
examples. They preserve the types of the occurrence-preservation laws,
qualification and unresolved-role witnesses, positive native admissions,
compatible-history witnesses, and rejection controls.

The verification gate checks that the wrappers are present in the compiled
environment. It also deliberately replaces an occurrence-distinction theorem with the
weaker statement `True`. That replacement must fail to satisfy the fixed
wrapper, even though the weakened theorem itself compiles.

The contracts retain the hypotheses and synthetic scope of the underlying
statements. Compiling them does not establish the truth of source reports or
admit the unresolved agency-revocation interpretation.

