# UsulTest.IDAActRegistryContracts in Plain English

Source: [`formal/lean/UsulTest/IDAActRegistryContracts.lean`](../../../formal/lean/UsulTest/IDAActRegistryContracts.lean)

Each wrapper states a required proposition explicitly and assigns the
corresponding core or fixture theorem to that type. Keeping a theorem name while
weakening its statement to `True` cannot satisfy this module.

The contracts cover registry uniqueness, original role-schema preservation,
valid target projection, full source binding, actual inherited source
admissibility, receipt revalidation, and lossless structured-wire round trips.
Finite scenario witnesses are recorded separately from universal statements.

The gate audits the compiled declarations and runs a concrete proposition
weakening control. Its private-axiom and admitted-proof probes must also be
rejected. These checks preserve the proof boundary; they do not certify supplied
source interpretations or binding-authority governance.
