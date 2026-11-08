# scripts.ExportIDAJudgment in Plain English

Source: [`formal/lean/scripts/ExportIDAJudgment.lean`](../../../formal/lean/scripts/ExportIDAJudgment.lean)

This executable evaluates every declared source-bound judgment fixture and
emits a canonical CSV row for each. The family contains six question tags,
36 answer tags, four admission states and 34 variants (the unchanged base plus
33 perturbations), for 29,376 rows.
It includes invalid inputs and attempts to retain or rewrite a derivation after
changing the claim.

The independent Quint implementation computes its own result for each input.
The gate compares all rows and checks malformed exports and independently
stated examples. This is full coverage of the declared fixture family, not all
possible source registries or context strings.
