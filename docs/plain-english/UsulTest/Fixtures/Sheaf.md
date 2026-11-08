# UsulTest.Fixtures.Sheaf in Plain English

Source: [`formal/lean/UsulTest/Fixtures/Sheaf.lean`](../../../../formal/lean/UsulTest/Fixtures/Sheaf.lean)

These are the 58 named contextual/sheaf expectations migrated from the v39 Prolog suite. They exercise lifting guards, complete obstruction categories and details, path discharge, alias normalization, and the distinction between obstructed, gluable, and undetermined states.

Negative expectations retain their original premises. The migration gate compares every name, expected answer, actual answer, and premise result against the source-bound legacy reference. It also changes each guard or emitter in a temporary compiling model and requires a named expectation to fail.
