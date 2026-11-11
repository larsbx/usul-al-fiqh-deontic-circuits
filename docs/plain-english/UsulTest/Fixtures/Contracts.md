# UsulTest.Fixtures.Contracts in Plain English

Source: [`formal/lean/UsulTest/Fixtures/Contracts.lean`](../../../../formal/lean/UsulTest/Fixtures/Contracts.lean)

These declarations restate the runner's required propositions with fixed types. A theorem with the same name but a weakened statement cannot satisfy the corresponding witness. The contracts cover required negative premises, the exact Boolean answer needed for success, query and premise errors, false premises, polarity reversal, and empty suites.

This module also verifies the runner's executable self-test set. It is compiled and included in the axiom audit during baseline acceptance. Semantic mutants are executed through the separate runtime suite, so a syntax or proof-compilation error cannot be mistaken for a failing fixture.

Typing contracts check the full exported inventory, retention of competing derived values, and the priority of originally stated facts. A universal preservation witness requires every existing fact to survive relation closure. Fatwa witnesses require first-applicable rule priority and ensure a selected decision came from the actual candidate list.
