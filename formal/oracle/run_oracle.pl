:- encoding(utf8).
% =========================================================================
%  Runs the oracle over the corpus and compares it with what the corpus records.
%
%    swipl formal/oracle/run_oracle.pl [-- RepoRoot]
%
%  Vectors (each one TAP line):
%    grounded/<id>          formal/fixtures/grounded-v1.json
%    daifa-<n>/kernel       corpus/hadith/daifa_tranche*.json: the strict kernel
%    daifa-<n>/rulings      … with the cited rulings (D2)
%    daifa-<n>/undefeated   … without the objections
%    daifa-<n>/lax          … without the objections, lax muʿtabar (D3 alternative)
%    daifa-<n>/dispute-<k>  … each jarḥ/taʿdīl dispute
%    seam/<k>               corpus/hadith/irwa_join.json: the ḥujja gate (D4)
%    tanaqud/<T>/<row>/<side>  corpus/tanaqud/*.json: each truth-table value (first, second, jamʿ)
%    tanaqud/<T>/clash      the two readings really disagree somewhere (oracle's own model)
%    tanaqud/<T>/resolution the register's resolution is jamʿ, the first stage
%    furuq/<F>/madhhab, furuq/<F>/ruling  corpus/furuq/*.json: each item's two rulings from its grade
%    furuq/<F>/overturns    an item that overturns an earlier one: a bare report, overturned by his own grade
%    term/<key>/<ruling>    corpus/dossier/glossary.json: each ruled term's rulings (al-manī, al-madhy, al-wadī)
%
%  Exit status: 0 all agree; 1 a vector disagrees; 2 nothing could be judged
%  (no data found, or a load warning or error).
% =========================================================================

% Declared before any module loads, so a load warning anywhere is caught (exit 2).
:- dynamic(load_problem/1).
:- dynamic(result/2).

:- multifile(user:message_hook/3).
user:message_hook(Message, Kind, _) :-
    memberchk(Kind, [warning, error]),
    assertz(load_problem(Message)),
    fail.

:- use_module(library(http/json)).
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(filesex)).
:- use_module(hadith_oracle).
:- use_module(tanaqud_oracle).
:- use_module(furuq_oracle).
:- use_module(tahara_oracle).

:- initialization(main, main).


main(Argv) :-
    (   Argv = [Root] -> true
    ;   Argv = [] -> default_root(Root)
    ;   format(user_error, "usage: run_oracle.pl [-- RepoRoot]~n", []), halt(2)
    ),
    (   load_problem(_) -> halt(2) ; true ),
    catch(run(Root), E, (print_message(error, E), halt(2))),
    findall(x, result(_, _), All), length(All, N),
    (   N =:= 0 -> format(user_error, "no vectors found under ~w~n", [Root]), halt(2) ; true ),
    format("1..~d~n", [N]),
    (   result(_, fail) -> halt(1) ; halt(0) ).

default_root(Root) :-
    source_file(default_root(_), Here),
    file_directory_name(Here, Dir),
    directory_file_path(Dir, '../..', Root0),
    absolute_file_name(Root0, Root, [file_type(directory)]).

read_json(File, D) :-
    setup_call_cleanup(open(File, read, S, [encoding(utf8)]),
                       json_read_dict(S, D, [value_string_as(atom), tag('')]),
                       close(S)).

check(Name, Expected, Got) :-
    (   Expected == Got
    ->  assertz(result(Name, pass)), format("ok - ~w~n", [Name])
    ;   assertz(result(Name, fail)),
        format("not ok - ~w: expected ~w, oracle ~w~n", [Name, Expected, Got])
    ).

run(Root) :-
    directory_file_path(Root, 'formal/fixtures/grounded-v1.json', GFile),
    read_json(GFile, G),
    forall(member(V, G.vectors), grounded_vector(V)),
    directory_file_path(Root, 'corpus/hadith', HDir),
    directory_files(HDir, Fs0), msort(Fs0, Fs),
    forall(( member(F, Fs), sub_atom(F, 0, _, _, daifa_tranche), file_name_extension(_, json, F) ),
           ( directory_file_path(HDir, F, P), read_json(P, T), forall(member(C, T.cases), daifa_case(C)) )),
    directory_file_path(HDir, 'irwa_join.json', JFile),
    read_json(JFile, J),
    forall(nth1(K, J.links, L), seam_link(K, L)),
    directory_file_path(Root, 'corpus/tanaqud', TDir),
    directory_files(TDir, TFs0), msort(TFs0, TFs),
    forall(( member(F, TFs), file_name_extension(_, json, F) ),
           ( directory_file_path(TDir, F, P), read_json(P, R), forall(member(Pair, R.pairs), tanaqud_pair(Pair)) )),
    directory_file_path(Root, 'corpus/furuq', FDir),
    directory_files(FDir, FFs0), msort(FFs0, FFs),
    findall(I, ( member(F, FFs), file_name_extension(_, json, F),
                 directory_file_path(FDir, F, P), read_json(P, T), member(I, T.items) ), Items),
    forall(member(I, Items), furuq_item(I)),
    forall(( member(I, Items), get_dict(overturns, I, PId) ), furuq_overturn(Items, I, PId)),
    directory_file_path(Root, 'corpus/dossier/glossary.json', GlFile),
    read_json(GlFile, Gl),
    forall(( member(T, Gl.terms), get_dict(rulings, T, Rs), atom_string(K, T.key) ),
           forall(get_dict(N, Rs, Exp), term_ruling(K, N, Exp))).

term_ruling(K, N, Exp) :-
    format(atom(Name), "term/~w/~w", [K, N]),
    ( ruling(K, N, Got) -> true ; Got = none ),
    check(Name, Exp, Got).

furuq_item(I) :-
    rulings(I.grade, M, A),
    format(atom(N1), "furuq/~w/madhhab", [I.id]), check(N1, I.madhhab, M),
    format(atom(N2), "furuq/~w/ruling", [I.id]), check(N2, I.ruling, A).

% The overturned item must come earlier in the book.
furuq_overturn(Items, I, PId) :-
    format(atom(Name), "furuq/~w/overturns", [I.id]),
    (   nth1(KP, Items, P), P.id == PId, nth1(KI, Items, I), KP < KI, overturn_ok(P.grade, I.grade)
    ->  Got = true ; Got = false ),
    check(Name, true, Got).

tanaqud_pair(Pair) :-
    atom_concat('T-', Num, Pair.id), atom_number(Num, N),
    forall(nth1(I, Pair.table, Row),
           forall(member(Side, [first, second, jam]),
                  ( ( Side == jam -> jam(N, Row.case, Got) ; reading(N, Side, Row.case, Got) ),
                    format(atom(Name), "tanaqud/~w/~w/~w", [Pair.id, I, Side]),
                    check(Name, Row.get(Side), Got) ))),
    (   member(Row, Pair.table), reading(N, first, Row.case, A), reading(N, second, Row.case, B), A \== B
    ->  Clash = true ; Clash = false ),
    format(atom(CName), "tanaqud/~w/clash", [Pair.id]), check(CName, true, Clash),
    format(atom(RName), "tanaqud/~w/resolution", [Pair.id]), check(RName, jam, Pair.resolution).

grounded_vector(V) :-
    grounded(V.n, V.attacks, Got),
    msort(V.grounded, Exp),
    format(atom(Name), "grounded/~w", [V.id]),
    check(Name, Exp, Got).

opt(C, Key, Default, Val) :- ( get_dict(Key, C, Val) -> true ; Val = Default ).

daifa_case(C) :-
    N = C.n,
    opt(C, args, 1, Args), opt(C, attacks, [], Att),
    judge(strict, C.turuq, Args, Att, K),
    format(atom(N1), "daifa-~w/kernel", [N]), check(N1, C.kernel, K),
    (   get_dict(rulings, C, Rs)
    ->  judge_rulings(strict, C.turuq, Args, Att, Rs, KR),
        format(atom(N2), "daifa-~w/rulings", [N]), check(N2, C.kernel_with_rulings, KR)
    ;   true ),
    (   get_dict(kernel_undefeated, C, KU)
    ->  judge(strict, C.turuq, 1, [], GU),
        format(atom(N3), "daifa-~w/undefeated", [N]), check(N3, KU, GU)
    ;   true ),
    (   get_dict(kernel_lax_undefeated, C, KL)
    ->  judge(lax, C.turuq, 1, [], GL),
        format(atom(N4), "daifa-~w/lax", [N]), check(N4, KL, GL)
    ;   true ),
    opt(C, disputes, [], Ds),
    forall(nth1(I, Ds, D),
           ( opt(D, qarina, none, Q), jarh_tadil(D.qawl, Q, S),
             format(atom(N5), "daifa-~w/dispute-~w", [N, I]), check(N5, D.expected, S) )).

seam_link(K, L) :-
    (   L.verdict == null
    ->  true
    ;   ( hujja(L.verdict) -> Got = true ; Got = false ),
        format(atom(Name), "seam/~w", [K]), check(Name, L.hujja, Got)
    ).
