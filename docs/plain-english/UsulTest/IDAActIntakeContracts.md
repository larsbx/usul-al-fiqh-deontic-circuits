# UsulTest.IDAActIntakeContracts in Plain English

Source: [`formal/lean/UsulTest/IDAActIntakeContracts.lean`](../../../formal/lean/UsulTest/IDAActIntakeContracts.lean)

This module fixes 20 required proposition types for candidate act intake. Each
contract is written explicitly, then discharged by the corresponding theorem;
it does not infer the required proposition from the implementation. Weakening an
implementation theorem to `True` must therefore fail the relevant contract.

Fourteen universal contracts require exact input and field retention, actual
registry resolution, registration and uniqueness, registered signatures and
ordered roles, exact pins, structural validity, exact target projection,
rejection of unresolved roles and conflicting registries, and distinction of
changed qualifications or operands.

Six finite contracts retain the 14-by-36 diagnostic matrix and the positive and
negative examples described in [UsulTest.IDAActIntake](IDAActIntake.md). They
include successful preparation and same-sort reference changes, so success
cannot be simulated by rejecting every input.

The contracts certify the stated structural program. They do not authenticate a
registry, admit a source interpretation, prove an observation true, or issue a
legal judgment. The result type has no source receipt or application authority.
Compiled-axiom checks and independent model comparisons remain separate parts of
the verification gate.
