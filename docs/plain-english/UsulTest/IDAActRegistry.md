# Act-registry verification cases

Companion to [UsulTest.IDAActRegistry](../../../formal/lean/UsulTest/IDAActRegistry.lean).

These synthetic fixtures exercise the actual registry resolver and bound source
gate. They provide 14 registry variants, 36 description variants, 10 binding
configurations, and 12 source-environment changes. The exporter compares 504
registry cases and 4,320 bound cases with the independently written Quint model.

Named finite proofs check registry ambiguity, unknown/unresolved kinds, complete
role schemas, same-sort role swaps, qualifications omitted by target projection,
six repeated snapshot coordinates, actual source rejection, and separately
authorized renewed bindings. Two different source entries may support the same
envelope, while a single entry cannot carry ambiguous bindings.

The wrong-target and wrong-snapshot fixtures have otherwise matching trusted
rows. Source-guard fixtures preserve the binding and mutate the source authority.
This ensures each intended guard is reached. The test also changes definition
version, digest, and registry snapshot under a newly valid registry while keeping
the old binding, to demonstrate independent envelope rejection.

The bounded fixtures do not make these statements universal. The companion core
module supplies the arbitrary-input theorems; fixed contracts preserve their
exact statements. Source fixture values are synthetic and do not admit a fiqh
interpretation.
