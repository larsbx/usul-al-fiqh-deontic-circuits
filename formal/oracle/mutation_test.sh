#!/usr/bin/env bash
# Disables one kernel clause of the oracle at a time in a scratch copy and requires it to be
# killed: by the corpus run (exit 1), or else by the self-tests. A kill by the self-tests
# alone is reported as such: no corpus vector depends on that clause yet. A mutant that
# survives both, or breaks loading (exit 2), fails.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

# name | sed expression on hadith_oracle.pl
mutants=(
  "weakest_link|s/foldl(\[L, A, B\]>>(link_verdict(L, LV), weaker(LV, A, B))/foldl([L, A, B]>>(link_verdict(L, LV), stronger(LV, A, B))/"
  "kadhdhab_mawdu|s/^martaba(kadhdhab,  12, mawdu)\./martaba(kadhdhab,  12, daifJiddan)./"
  "tuhma_shadid|s/^martaba(muttaham,  11, daifJiddan)\./martaba(muttaham,  11, daif)./"
  "gap_caps|s/^    \\\\+ get_dict(muttasil, L, false),/    true,/"
  "tadlis_tolerance|s/^tolerated(t2)\./tolerated(t2).\ntolerated(t3).\ntolerated(t4)./"
  "unknown_floor|s/R is max(R0, 9)/R = R0/"
  "shadid_not_support|s/(member(r(V, M, _), Rs), at_least(V, daif))/(member(r(V, M, _), Rs), true)/"
  "two_madar|s/length(Ms, N), N >= 2/length(Ms, N), N >= 1/"
  "one_rung|s/V0 == daif -> V1 = hasan/V0 == daif -> V1 = sahih/"
  "objection_defeats|s/memberchk(0, G), mutabar(Pol, Rs)/true, mutabar(Pol, Rs)/"
  "strict_floor|s/at_least(V, daif), F =< BF/at_least(V, daif), F =< BF + 99/"
  "strict_independent|s/M \\\\== BM, at_least/true, at_least/"
  "ruling_cap|s/( memberchk(Arg, G) -> weaker(Cap, A, C) ; C = A )/( fail -> weaker(Cap, A, C) ; C = A )/"
  "grounded_defence|s/( member(\[C, B\], Att), memberchk(C, S) )/true/"
  "qati_jarh|s/^resolve(qati, _, _, majruh) :- !\./resolve(qati, _, _, tawaqquf) :- !./"
  "qarina_jarh|s/^resolve(_, _, jarh, majruh) :- !\./resolve(_, _, jarh, tawaqquf) :- !./"
  "hujja_gate|s/^hujja(V) :- at_least(V, hasan)\./hujja(V) :- at_least(V, daif)./"
)

fail=0
for m in "${mutants[@]}"; do
  name="${m%%|*}"; expr="${m#*|}"
  cp "$here/run_oracle.pl" "$here/test_hadith_oracle.pl" "$scratch/"
  sed -e "$expr" "$here/hadith_oracle.pl" > "$scratch/hadith_oracle.pl"
  if cmp -s "$here/hadith_oracle.pl" "$scratch/hadith_oracle.pl"; then
    echo "not ok - $name: the mutation did not apply"; fail=1; continue
  fi
  set +e; swipl "$scratch/run_oracle.pl" -- "$root" >/dev/null 2>&1; code=$?; set -e
  case $code in
    1) echo "ok - $name: killed by the corpus" ;;
    0) if swipl -q -g run_tests -t halt "$scratch/test_hadith_oracle.pl" >/dev/null 2>&1; then
         echo "not ok - $name: survived"; fail=1
       else
         echo "ok - $name: killed by the self-tests only (no corpus vector depends on it)"
       fi ;;
    *) echo "not ok - $name: did not load (exit $code)"; fail=1 ;;
  esac
done
echo "1..${#mutants[@]}"
exit $fail
