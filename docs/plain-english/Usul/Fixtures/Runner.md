# Usul.Fixtures.Runner in Plain English

Source: [`formal/lean/Usul/Fixtures/Runner.lean`](../../../../formal/lean/Usul/Fixtures/Runner.lean)

The runner checks finite, explicitly named expectations. Queries and premises return either a Boolean answer or an explicit error. All premises must succeed before the expected answer is considered, and a negative expectation needs at least one premise. Errors are never interpreted as negative answers.

It rejects empty suites, repeated names, and names that would corrupt the result table. Its universal contracts establish the premise and error boundaries and prove that reversing a correct Boolean expectation produces an answer mismatch. These are claims about this test runner, not about the authority of a fixture's source interpretation.
