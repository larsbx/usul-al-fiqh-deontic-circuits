# scripts.CheckIDAActIntake in Plain English

Source: [`formal/lean/scripts/CheckIDAActIntake.lean`](../../../formal/lean/scripts/CheckIDAActIntake.lean)

This executable adapter reads a JSON array of cases, each with exactly a
`registry` and an `input`. It independently decodes the allowed semantic fields
and invokes the actual Lean `ActIntake.prepare` function.

The input permits exactly `key`, `definitionDigest`, `registrySnapshot`,
`qualifications`, `context`, and `operands`. It has no field for an operation,
parameter signature, source premise, admission status, or application authority.
Unknown or missing JSON fields cause an adapter error.

For each well-decoded case, the output contains exactly `code`, `envelope`, and
`definition`. A structural rejection uses the existing ACT-01 failure code and
JSON null for both payloads. Success uses code zero and emits the complete
prepared envelope and registered definition. Comparing all output fields makes
loss of qualifications, context, role order, or reference identity observable.

The outer host boundary is responsible for canonical bytes, duplicate JSON keys,
numeric bounds, and recomputation of definition hashes. General correctness of
Lean's JSON parser is not a theorem of this adapter. The output is structural
candidate data; it carries no legal ruling, source admission, or application grant.

Run the compiled adapter with one argument naming the JSON array fixture file.
The dedicated intake gate supplies independent expected outputs and Quint
comparisons and records their exact input revision.
