:- encoding(utf8).
% Self-tests: synthetic vectors, one per rule, independent of the corpus.
%   swipl -q -g run_tests -t halt formal/oracle/test_hadith_oracle.pl
:- use_module(library(plunit)).
:- use_module(hadith_oracle).


:- begin_tests(isnad).
test(sound) :- chain_verdict([_{rawi: thiqa}, _{rawi: thiqa}, _{rawi: sahabi}], sahih).
test(saduq) :- chain_verdict([_{rawi: thiqa}, _{rawi: saduq}, _{rawi: sahabi}], hasan).
test(tier2_anana) :- chain_verdict([_{rawi: thiqa, tadlis: t2, sigha: anana}, _{rawi: sahabi}], sahih).
test(tier3_anana) :- chain_verdict([_{rawi: thiqa, tadlis: t3, sigha: anana}, _{rawi: sahabi}], daif).
test(tier3_tasrih) :- chain_verdict([_{rawi: thiqa, tadlis: t3}, _{rawi: sahabi}], sahih).
test(gap) :- chain_verdict([_{rawi: thiqa, muttasil: false}, _{rawi: sahabi}], daif).
test(matruk) :- chain_verdict([_{rawi: thiqa}, _{rawi: matruk}, _{rawi: sahabi}], daifJiddan).
test(kadhdhab) :- chain_verdict([_{rawi: thiqa}, _{rawi: kadhdhab}, _{rawi: sahabi}], mawdu).
test(floor_gap) :- chain_floor([_{rawi: thiqa, muttasil: false}], 9).
test(floor_rank) :- chain_floor([_{rawi: thiqa}, _{rawi: matruk}], 10).
:- end_tests(isnad).

two(R1, R2, [_{madar: a, links: [_{rawi: R1}]}, _{madar: b, links: [_{rawi: R2}]}]).

:- begin_tests(turuq).
test(two_weak_lift) :- two(daif, daif, T), judge(strict, T, 1, [], hasan).
test(one_madar) :- judge(strict, [_{madar: a, links: [_{rawi: daif}]}, _{madar: a, links: [_{rawi: daif}]}], 1, [], daif).
test(one_madar_lax) :- judge(lax, [_{madar: a, links: [_{rawi: daif}]}, _{madar: a, links: [_{rawi: daif}]}], 1, [], daif).
test(shadid_inert) :- two(daif, matruk, T), judge(lax, T, 1, [], daif).
test(strict_weaker_follower) :- two(saduqYahim, majhul, T), judge(strict, T, 1, [], daif).
test(lax_weaker_follower) :- two(saduqYahim, majhul, T), judge(lax, T, 1, [], hasan).
test(defeat) :- two(daif, daif, T), judge(strict, T, 2, [[1, 0]], daif).
test(reinstate) :- two(daif, daif, T), judge(strict, T, 3, [[1, 0], [2, 1]], hasan).
test(ruling_caps) :- two(daif, daif, T), judge_rulings(strict, T, 2, [], [_{arg: 1, kind: hukm, ceiling: mawdu}], mawdu).
test(ruling_defeated) :- two(daif, daif, T), judge_rulings(strict, T, 3, [[2, 1]], [_{arg: 1, kind: hukm, ceiling: mawdu}], hasan).
:- end_tests(turuq).

:- begin_tests(grounded).
test(cycle) :- grounded(2, [[0, 1], [1, 0]], []).
test(chain) :- grounded(3, [[0, 1], [1, 2]], [0, 2]).
:- end_tests(grounded).

:- begin_tests(jarh_tadil).
test(jarh_alone) :- jarh_tadil([_{side: jarh, strength: mujmal}], none, majruh).
test(qati_wins) :- jarh_tadil([_{side: jarh, strength: qati}, _{side: tadil, strength: mufassar}], tadil, majruh).
test(no_qarina) :- jarh_tadil([_{side: jarh, strength: mujmal}, _{side: tadil, strength: mufassar}], none, tawaqquf).
test(not_mutamad) :- jarh_tadil([_{side: tadil, strength: mujmal, mutamad: false}], none, tawaqquf).
:- end_tests(jarh_tadil).

:- use_module(tanaqud_oracle).

:- begin_tests(tanaqud).
test(t1_gods_right_excuses) :- jam(1, [allah, forgetful], false).
test(t1_human_right_liable) :- jam(1, [adami, forgetful], true).
test(t6_pure_means) :- jam(6, [true, true], false).
test(t6_capable_part) :- jam(6, [true, false], true).
test(t8_doubt_keeps_asl) :- jam(8, [shakk], true).
test(t8_zann_displaces) :- jam(8, [zann], false).
test(t10_trustee_on_oath) :- jam(10, [true], yamin).
:- end_tests(tanaqud).
