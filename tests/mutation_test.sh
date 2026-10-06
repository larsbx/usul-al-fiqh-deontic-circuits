#!/usr/bin/env bash
# Disables one kernel guard at a time in a scratch copy of examples/ and
# requires the fixture suite to fail for every mutant. A mutant that survives
# means no vector depends on that guard.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
runner="$root/tests/run_fixture_expectations.pl"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

# name | file | sed expression
mutants=(
  "capacity_guard|v38_contextual_affect_deontics.pl|s/^outside_direct_taklif(panic_overflow)\./under_taklif_control(panic_overflow)./"
  "modality_guard|v38_contextual_affect_deontics.pl|s/^modality_satisfied(conditional(Cond), Conditions) :-/modality_satisfied(conditional(_), _) :- true.\nmodality_satisfied_unused(Cond, Conditions) :-/"
  "comparative_guard|v38_contextual_affect_deontics.pl|s/^modality_satisfied(comparative(stronger_than(Other)), Conditions) :-/modality_satisfied(comparative(_), _) :- true.\nmodality_satisfied_unused(Other, Conditions) :-/"
  "subject_guard|v38_contextual_affect_deontics.pl|s/^subject_matches(Agent, Subject) :-/subject_matches(_, _) :- true.\nsubject_matches_unused(Agent, Subject) :-/"
  "scope_guard|v39_sheaf_concern.pl|s/deontic(Affect, Object, _Operator2/deontic(_Affect2, Object, _Operator2/"
  "discharge_guard|v38_contextual_affect_deontics.pl|s/^    \\\\+ path_realizes(Path, Agent, Affect, Object)\\./    true./"
  "anti_pair_guard|v38_contextual_affect_deontics.pl|s/^    \\\\+ path_realizes(Path, Agent, Commanded, Object)\\./    fail./"
  "operator_conflict|v39_sheaf_concern.pl|s/^operator_incompatible(o, f)\\./operator_incompatible_unused(o, f)./;s/^operator_incompatible(f, o)\\./operator_incompatible_unused(f, o)./"
)

survivors=0
for spec in "${mutants[@]}"; do
  IFS='|' read -r name file expr <<<"$spec"
  rm -rf "$scratch/examples"
  cp -r "$root/examples" "$scratch/examples"
  target="$scratch/examples/$file"
  sed -i "$expr" "$target"
  if cmp -s "$root/examples/$file" "$target"; then
    echo "not ok - $name: mutation did not apply"
    survivors=$((survivors + 1))
  elif swipl "$runner" -- "$scratch/examples/v39_sheaf_obstruction_fixtures.pl" >/dev/null 2>&1; then
    echo "not ok - $name: mutant survived"
    survivors=$((survivors + 1))
  else
    echo "ok - $name: killed"
  fi
done

echo "1..${#mutants[@]}"
exit $((survivors > 0))
