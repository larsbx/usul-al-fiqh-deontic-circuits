# UsulTest.IDADerivationContracts in Plain English

Source: [`formal/lean/UsulTest/IDADerivationContracts.lean`](../../../formal/lean/UsulTest/IDADerivationContracts.lean)

This module fixes 48 explicit proposition types, including 36 universal
derivation requirements and 12 deterministic scenario requirements. Each
witness writes its expected type directly and uses the corresponding theorem.
It does not obtain the required proposition by asking Lean for the implementation
theorem's type.

The universal contracts cover exact authorization, arbitrary-tree source
preservation, admission and known-payload requirements for every leaf, full scope
guards, no silent promotion, exact taklifi intersection, preservation of source
grades and alternatives, and current-environment receipt replay. Their complete
meanings are listed in the [derivation companion](../Usul/Typing/IDADerivation.md).
The ten finite contracts are listed in the
[scenario companion](IDADerivation.md).

The `unauthorized_evidence_promotion` endpoint is intentionally not used by the
ordinary scenarios. The gate's weakening control changes that theorem's
conclusion to `True` and supplies a trivial proof. The model and scenarios should
still compile, while this module's original, stronger proposition must fail to
compile. This distinguishes theorem-name retention from preservation of the
actual required claim.

The compiled declaration and axiom audit is a separate check. Fixed proposition
types catch weakened requirements; the axiom audit catches inadmissible proof
dependencies. Neither establishes source-interpretation correctness or authority
of the externally supplied registry, catalog, and evidence decisions.

Four ACT-00 witnesses require target equality across accepted leaves,
well-formedness of each accepted target, the fixed structured target scenario
matrix, and the three replay results.
