#!/usr/bin/env bash
# Native Lean fixture expectations, semantic mutants, and compiled axiom audit.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
exec python3 formal/check-lean-fixtures.py
