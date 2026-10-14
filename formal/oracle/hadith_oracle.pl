:- encoding(utf8).
% =========================================================================
%  Oracle: an independent Prolog model of the al-Albānī kernel.
%
%  It mirrors, without sharing code, what the Lean modules decide:
%    Hadith.Grade      martaba -> verdict, the verdict order
%    Hadith.Isnad      weakest link, tadlīs policy (Ibn Ḥajar), route floor
%    Hadith.Turuq      the lift (ḍaʿīf+ḍaʿīf -> ḥasan), strict muʿtabar (D3),
%                      rulings as caps (D2)
%    Usul.Grounded     the grounded extension of a finite AF
%    Hadith.JarhTadil  resolution of jarḥ against taʿdīl
%  Data enter as SWI dicts read from the corpus JSON, never from generated
%  Lean. run_oracle.pl compares its results with the values the corpus
%  records; Lean checks the same values, so the two agree or a test fails.
% =========================================================================

:- module(hadith_oracle,
          [ verdict_rank/2, martaba/3, chain_verdict/2, chain_floor/2,
            judge/5, judge_rulings/6, grounded/3, jarh_tadil/3, hujja/1 ]).

:- use_module(library(lists)).
:- use_module(library(apply)).

% --- Verdicts ------------------------------------------------------------

verdict_rank(mawdu, 0).
verdict_rank(daifJiddan, 1).
verdict_rank(daif, 2).
verdict_rank(hasan, 3).
verdict_rank(sahih, 4).

weaker(A, B, W) :- verdict_rank(A, RA), verdict_rank(B, RB), ( RA =< RB -> W = A ; W = B ).
stronger(A, B, S) :- verdict_rank(A, RA), verdict_rank(B, RB), ( RA >= RB -> S = A ; S = B ).
at_least(V, Floor) :- verdict_rank(V, R), verdict_rank(Floor, RF), R >= RF.

hujja(V) :- at_least(V, hasan).
shadid(V) :- \+ at_least(V, daif).

% --- Taqrīb marātib: martaba(Name, Rank, Verdict) --------------------------

martaba(sahabi,     1, sahih).
martaba(awthaq,     2, sahih).
martaba(thiqa,      3, sahih).
martaba(saduq,      4, hasan).
martaba(saduqYahim, 5, daif).
martaba(maqbul,     6, daif).
martaba(mastur,     7, daif).
martaba(daif,       8, daif).
martaba(majhul,     9, daif).
martaba(matruk,    10, daifJiddan).
martaba(muttaham,  11, daifJiddan).
martaba(kadhdhab,  12, mawdu).

% --- Isnād ----------------------------------------------------------------

% Ibn Ḥajar's tiers whose ʿanʿana is accepted.
tolerated(t1).
tolerated(t2).

% A link is sound when continuous and its tadlīs, if any, is accepted.
sound_link(L) :-
    \+ get_dict(muttasil, L, false),
    (   \+ get_dict(tadlis, L, _) -> true
    ;   get_dict(sigha, L, anana) -> get_dict(tadlis, L, T), tolerated(T)
    ;   true                                   % taṣrīḥ cures the tadlīs
    ).

link_verdict(L, V) :-
    martaba(L.rawi, _, V0),
    ( sound_link(L) -> V = V0 ; weaker(V0, daif, V) ).

% A gap or unaccepted tadlīs hides an unknown narrator: at least rank 9.
link_rank(L, R) :-
    martaba(L.rawi, R0, _),
    ( sound_link(L) -> R = R0 ; R is max(R0, 9) ).

chain_verdict(Links, V) :- foldl([L, A, B]>>(link_verdict(L, LV), weaker(LV, A, B)), Links, sahih, V).
chain_floor(Links, F) :- foldl([L, A, B]>>(link_rank(L, R), B is max(A, R)), Links, 0, F).

% --- Ṭuruq -----------------------------------------------------------------
% A route is r(Verdict, Madar, Floor).

route(T, r(V, T.madar, F)) :- chain_verdict(T.links, V), chain_floor(T.links, F).

best(Rs, B) :- foldl([r(V, _, _), A, C]>>stronger(V, A, C), Rs, mawdu, B).

supports(Rs, Ms) :- findall(M, (member(r(V, M, _), Rs), at_least(V, daif)), Ms0), sort(Ms0, Ms).

liftable(Rs) :- best(Rs, B), memberchk(B, [daif, hasan]), supports(Rs, Ms), length(Ms, N), N >= 2.

% One rung. Steadfast: the output is bound only after the choice (callers may pass it bound).
bump(V0, V) :- ( V0 == daif -> V1 = hasan ; V0 == hasan -> V1 = sahih ; V1 = V0 ), V = V1.

% The base route: best verdict, then lowest floor; the first wins ties.
base_route(Rs, Base) :-
    best(Rs, B),
    include([r(V, _, _)]>>(V == B), Rs, [First|Rest]),
    foldl([r(V, M, F), r(V0, M0, F0), Out]>>( F < F0 -> Out = r(V, M, F) ; Out = r(V0, M0, F0) ),
          Rest, First, Base).

% «فوقه أو مثله لا دونه»: an independent follower no weaker than the base.
mutabar(lax, _).
mutabar(strict, Rs) :-
    base_route(Rs, r(_, BM, BF)),
    once(( member(r(V, M, F), Rs), M \== BM, at_least(V, daif), F =< BF )).

% judge(+Policy, +Turuq, +N, +Attacks, -Verdict)
judge(Pol, Turuq, N, Att, V) :-
    maplist(route, Turuq, Rs),
    best(Rs, B),
    grounded(N, Att, G),
    (   memberchk(0, G), mutabar(Pol, Rs), liftable(Rs) -> bump(B, V) ; V = B ).

% Rulings cap the verdict when their argument survives (D2).
judge_rulings(Pol, Turuq, N, Att, Rulings, V) :-
    judge(Pol, Turuq, N, Att, V0),
    grounded(N, Att, G),
    foldl([R, A, C]>>( get_dict(arg, R, Arg), get_dict(ceiling, R, Cap),
                       ( memberchk(Arg, G) -> weaker(Cap, A, C) ; C = A ) ), Rulings, V0, V).

% --- Grounded extension: the least fixpoint of the defence function ----------

grounded(N, Att, G) :- fixpoint(N, Att, [], G).

fixpoint(N, Att, S, G) :-
    Max is N - 1,
    findall(A, (between(0, Max, A), defended(Att, S, A)), S1),
    ( S1 == S -> G = S ; fixpoint(N, Att, S1, G) ).

defended(Att, S, A) :-
    forall(member([B, A], Att), ( member([C, B], Att), memberchk(C, S) )).

% --- Jarḥ wa-taʿdīl (al-Muʿallimī) ------------------------------------------

strength_rank(mujmal, 0).
strength_rank(mufassar, 1).
strength_rank(qati, 2).

counts(Q) :- \+ get_dict(mutamad, Q, false), \+ get_dict(hukm, Q, false).

strongest(Side, Qs, S) :-
    findall(R-St, ( member(Q, Qs), counts(Q), get_dict(side, Q, Side),
                    get_dict(strength, Q, St), strength_rank(St, R) ), Ps),
    ( Ps == [] -> S = none ; max_member(_-S, Ps) ).

% jarh_tadil(+Qawl, +Qarina, -Status)
jarh_tadil(Qs, Qarina, Status) :-
    strongest(jarh, Qs, J), strongest(tadil, Qs, T),
    resolve(J, T, Qarina, S0),
    Status = S0.                        % steadfast: resolve/4 commits by cut on its inputs

resolve(none, none, _, tawaqquf) :- !.
resolve(_, none, _, majruh) :- !.
resolve(none, _, _, adl) :- !.
resolve(qati, qati, _, tawaqquf) :- !.
resolve(qati, _, _, majruh) :- !.
resolve(_, qati, _, adl) :- !.
resolve(_, _, jarh, majruh) :- !.
resolve(_, _, tadil, adl) :- !.
resolve(_, _, none, tawaqquf).
