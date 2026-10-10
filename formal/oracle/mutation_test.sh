#!/usr/bin/env bash
# Disables one kernel clause of the oracle at a time in a scratch copy and requires it to be
# killed: by the corpus run (exit 1), or else by the self-tests. A kill by the self-tests
# alone is reported as such: no corpus vector depends on that clause yet. A mutant that
# survives both, or breaks loading (exit 2), fails. Disabled guards keep every variable used, so a
# mutant loads without warnings (the runner treats any load warning as exit 2).
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

# name | file | sed expression
mutants=(
  "weakest_link|hadith_oracle.pl|s/foldl(\[L, A, B\]>>(link_verdict(L, LV), weaker(LV, A, B))/foldl([L, A, B]>>(link_verdict(L, LV), stronger(LV, A, B))/"
  "kadhdhab_mawdu|hadith_oracle.pl|s/^martaba(kadhdhab,  12, mawdu)\./martaba(kadhdhab,  12, daifJiddan)./"
  "tuhma_shadid|hadith_oracle.pl|s/^martaba(muttaham,  11, daifJiddan)\./martaba(muttaham,  11, daif)./"
  "gap_caps|hadith_oracle.pl|s/^    \\\\+ get_dict(muttasil, L, false),/    true,/"
  "tadlis_tolerance|hadith_oracle.pl|s/^tolerated(t2)\./tolerated(t2).\ntolerated(t3).\ntolerated(t4)./"
  "unknown_floor|hadith_oracle.pl|s/R is max(R0, 9)/R = R0/"
  "shadid_not_support|hadith_oracle.pl|s/(member(r(V, M, _), Rs), at_least(V, daif))/(member(r(V, M, _), Rs), V = V)/"
  "two_madar|hadith_oracle.pl|s/length(Ms, N), N >= 2/length(Ms, N), N >= 1/"
  "one_rung|hadith_oracle.pl|s/V0 == daif -> V1 = hasan/V0 == daif -> V1 = sahih/"
  "objection_defeats|hadith_oracle.pl|s/memberchk(0, G), mutabar(Pol, Rs)/G = G, mutabar(Pol, Rs)/"
  "strict_floor|hadith_oracle.pl|s/at_least(V, daif), F =< BF/at_least(V, daif), F =< BF + 99/"
  "strict_independent|hadith_oracle.pl|s/M \\\\== BM, at_least/M = M, BM = BM, at_least/"
  "ruling_cap|hadith_oracle.pl|s/( memberchk(Arg, G) -> weaker(Cap, A, C) ; C = A )/( Arg = Arg, G = G, fail -> weaker(Cap, A, C) ; C = A )/"
  "grounded_defence|hadith_oracle.pl|s/( member(\[C, B\], Att), memberchk(C, S) )/( B = B, S = S )/"
  "qati_jarh|hadith_oracle.pl|s/^resolve(qati, _, _, majruh) :- !\./resolve(qati, _, _, tawaqquf) :- !./"
  "qarina_jarh|hadith_oracle.pl|s/^resolve(_, _, jarh, majruh) :- !\./resolve(_, _, jarh, tawaqquf) :- !./"
  "hujja_gate|hadith_oracle.pl|s/^hujja(V) :- at_least(V, hasan)\./hujja(V) :- at_least(V, daif)./"
  "t1_whose_right|tanaqud_oracle.pl|s/qayd(1, \[R, _\]) :- R == adami\./qayd(1, [R, _]) :- R == allah./"
  "t2_claimants|tanaqud_oracle.pl|s/qayd(2, \[K\]) :- K == true\./qayd(2, [K]) :- K == false./"
  "t6_pure_means|tanaqud_oracle.pl|s/( Pure == true -> V = false ; V = true )/V = true, Pure = Pure/"
  "t8_threshold|tanaqud_oracle.pl|s/R > S\./R >= S./"
  "t10_burden|tanaqud_oracle.pl|s/^first(10, \[_\], yamin)\./first(10, [_], bayyina)./"
  "jam_side|tanaqud_oracle.pl|s/( qayd(P, C) -> first(P, C, V0) ; second(P, C, V0) )/( qayd(P, C) -> second(P, C, V0) ; first(P, C, V0) )/"
)

fail=0
for m in "${mutants[@]}"; do
  name="${m%%|*}"; rest="${m#*|}"; file="${rest%%|*}"; expr="${rest#*|}"
  cp "$here"/*.pl "$scratch/"
  sed -e "$expr" "$here/$file" > "$scratch/$file"
  if cmp -s "$here/$file" "$scratch/$file"; then
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
