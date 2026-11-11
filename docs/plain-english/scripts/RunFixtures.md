# scripts.RunFixtures in Plain English

Source: [`formal/lean/scripts/RunFixtures.lean`](../../../formal/lean/scripts/RunFixtures.lean)

This standalone Lean executable runs the runner, sheaf, fatwa, and typing suites, individually or together. It exports a strict tab-separated table containing suite, name, expected answer, actual answer, premises, and outcome. Any failing fixture returns exit status 1; invalid command use or an unknown suite is an error.

The --flipped mode reverses each expectation and provides a true premise where a newly negative case needs one. The acceptance driver requires every flipped case to fail for an answer mismatch. The script is compiled and audited as a standalone module.
