#!/usr/bin/env bash
# The Prolog oracle: self-tests, the corpus mirror of the Lean kernels, then oracle mutants.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

swipl -q -g run_tests -t halt formal/oracle/test_hadith_oracle.pl
swipl formal/oracle/run_oracle.pl
formal/oracle/mutation_test.sh
