# UsulTest.Fixtures.Typing in Plain English

Source: [`formal/lean/UsulTest/Fixtures/Typing.lean`](../../../../formal/lean/UsulTest/Fixtures/Typing.lean)

These are the 31 named typing expectations migrated from v41. They check routing, missing facts, field inheritance, intentional sharing, detection of unrelated field collisions, stated-fact priority, relation direction, and partial coverage.

The migration gate preserves the original premises and exact names. Seven compiling semantic mutations challenge the routing and relation guards. The cases test the finite routing model and complement the existing universal typed-encoder laws.
