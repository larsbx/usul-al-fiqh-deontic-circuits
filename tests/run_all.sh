#!/usr/bin/env bash
# Runner self-tests, fixture expectations, then guard mutation tests.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

swipl -q -g run_tests -t halt tests/test_fixture_runner.pl
swipl tests/run_fixture_expectations.pl
tests/mutation_test.sh
