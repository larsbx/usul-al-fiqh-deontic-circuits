:- encoding(utf8).
% =========================================================================
%  Fixture expectation runner
%
%  Evaluates fixture_expectation(Name, query(Query), Kind) vectors, each with
%  zero or more fixture_premise(Name, query(Premise)) facts.
%
%    expect_true   Query succeeds at least once.
%    expect_false  Query fails finitely.
%
%  Every premise must hold before the query is judged. A negative vector must
%  declare at least one premise: a query over a world, agent, or fact that does
%  not exist fails trivially, so without premises an expect_false vector
%  cannot fail.
%
%  Fails closed: a raised exception, an unknown kind, a failed premise, a
%  premise-free negative, a duplicate name, or an empty expectation set is
%  reported as a failure.
% =========================================================================

:- module(fixture_runner,
    [ check_expectation/4,
      flip_kind/2,
      run_expectations/2,
      failure_count/2,
      report/1
    ]).

flip_kind(expect_true, expect_false).
flip_kind(expect_false, expect_true).

%!  check_expectation(:Query, +Kind, :Premises, -Outcome) is det.
%
%   Outcome is `pass` or `fail(Reason)`. Unqualified goals in Query and
%   Premises run in the caller's module.
:- meta_predicate check_expectation(0, +, :, -).

check_expectation(Query, Kind, Module:Premises0, Outcome) :-
    maplist(qualify(Module), Premises0, Premises),
    catch(judge(Kind, Query, Premises, Judged), Error,
          Judged = fail(error(Error))),
    Outcome = Judged.

qualify(_, Qualified, Qualified) :-
    Qualified = _:_, !.
qualify(Module, Goal, Module:Goal).

judge(Kind, _, _, fail(unknown_kind(Kind))) :-
    \+ flip_kind(Kind, _), !.
judge(expect_false, _, [], fail(vacuous_negative)) :- !.
judge(_, _, Premises, fail(premise_failed(Premise))) :-
    member(Premise, Premises),
    \+ once(Premise), !.
judge(Kind, Query, _, Outcome) :-
    query_outcome(Kind, Query, Outcome).

query_outcome(expect_true, Query, Outcome) :-
    (   once(Query) -> Outcome = pass ; Outcome = fail(query_failed) ).
query_outcome(expect_false, Query, Outcome) :-
    (   once(Query) -> Outcome = fail(query_succeeded) ; Outcome = pass ).

%!  run_expectations(+Expectations, -Results) is det.
%
%   Expectations is a list of expectation(Name, Query, Kind, Premises);
%   Results is a list of result(Name, Outcome).
run_expectations([], [result('<suite>', fail(no_expectations))]) :- !.
run_expectations(Expectations, Results) :-
    findall(Name, member(expectation(Name, _, _, _), Expectations), Names),
    maplist(run_one(Names), Expectations, Results).

run_one(Names, expectation(Name, Query, Kind, Premises), result(Name, Outcome)) :-
    (   duplicated(Name, Names)
    ->  Outcome = fail(duplicate_name)
    ;   check_expectation(Query, Kind, Premises, Outcome)
    ).

duplicated(Name, Names) :-
    include(==(Name), Names, [_, _|_]).

failure_count(Results, Count) :-
    aggregate_all(count, member(result(_, fail(_)), Results), Count).

%!  report(+Results) is det.
%
%   Prints TAP-style lines followed by a plan line.
report(Results) :-
    forall(nth1(I, Results, result(Name, Outcome)), report_line(I, Name, Outcome)),
    length(Results, N),
    failure_count(Results, F),
    format("1..~d~n# ~d passed, ~d failed~n", [N, N - F, F]).

report_line(I, Name, pass) :-
    format("ok ~d - ~w~n", [I, Name]).
report_line(I, Name, fail(Reason)) :-
    format("not ok ~d - ~w~n#   ~q~n", [I, Name, Reason]).
