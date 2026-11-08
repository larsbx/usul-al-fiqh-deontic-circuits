# UsulTest.Fixtures.Runner in Plain English

Source: [`formal/lean/UsulTest/Fixtures/Runner.lean`](../../../../formal/lean/UsulTest/Fixtures/Runner.lean)

These executable controls test positive and negative answers, undefined-query errors, unknown expectation kinds, duplicate or invalid names, empty suites, and errors or false values in premises. They also verify the failure count and both directions of a polarity flip.

The controls are ordinary Lean fixture values. The separate Contracts module proves the fixed runner obligations; the acceptance driver executes these controls and reverses every expected answer to ensure they can fail.
