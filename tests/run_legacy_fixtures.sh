#!/usr/bin/env bash
# Optional independent migration reference. Default fixtures run in Lean.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
swipl -q -g run_tests -t halt tests/test_fixture_runner.pl
swipl tests/run_fixture_expectations.pl
swipl tests/run_fixture_expectations.pl -- examples/v40_fatwa_oracle_fixtures.pl
swipl tests/run_fixture_expectations.pl -- examples/v41_typing_fixtures.pl
tests/mutation_test.sh
python3 tests/export_fixture_reference.py
