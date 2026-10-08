:- encoding(utf8).
% =========================================================================
%  Executes every fixture_expectation/3 vector.
%
%    swipl tests/run_fixture_expectations.pl [-- FixtureFile]
%
%  Exit status: 0 all vectors pass; 1 a vector failed; 2 the fixtures could
%  not be judged (bad usage, a load warning or error, a stray source, or a
%  malformed or orphaned expectation or premise).
%
%  FixtureFile defaults to the v39 aggregator. It must follow `--`: swipl
%  loads any other trailing file argument as source, which would mix two
%  fixture sets. The runner refuses to run if any source outside the fixture
%  directory was loaded.
% =========================================================================

:- use_module(fixture_runner).

:- initialization(main, main).

:- dynamic(load_problem/2).

% Record every warning or error; the message is still printed.
:- multifile(user:message_hook/3).
user:message_hook(Message, Kind, _Lines) :-
    memberchk(Kind, [warning, error]),
    assertz(load_problem(Kind, Message)),
    fail.

default_fixture_file(File) :-
    source_file(default_fixture_file(_), Here),
    file_directory_name(Here, Dir),
    directory_file_path(Dir, '../examples/v39_sheaf_obstruction_fixtures.pl', File).

main(Argv) :-
    (   Argv = [File] -> true
    ;   Argv = [] -> default_fixture_file(File)
    ;   format(user_error, "usage: run_fixture_expectations.pl [-- FixtureFile]~n", []),
        halt(2)
    ),
    absolute_file_name(File, Path, [access(read)]),
    load_files(user:Path, [if(true)]),
    require_clean_load,
    require_expectations_from(Path),
    require_well_formed_fixtures,
    findall(expectation(Name, user:Query, Kind, Premises),
        ( user:fixture_expectation(Name, query(Query), Kind),
          findall(user:P, user:fixture_premise(Name, query(P)), Premises) ),
        Expectations),
    run_expectations(Expectations, Results),
    report(Results),
    failure_count(Results, Failures),
    (   Failures =:= 0 -> halt(0) ; halt(1) ).

% Every loaded source outside the Prolog home must come from the fixture
% directory or from this runner's own directory.
require_expectations_from(Path) :-
    file_directory_name(Path, FixtureDir),
    source_file(require_expectations_from(_), Here),
    file_directory_name(Here, RunnerDir),
    current_prolog_flag(home, Home),
    forall(( source_file(Source),
             \+ sub_atom(Source, 0, _, _, Home),
             file_directory_name(Source, SourceDir),
             \+ memberchk(SourceDir, [FixtureDir, RunnerDir]) ),
        (   format(user_error, "refusing: ~w was loaded but is outside ~w~n",
                [Source, FixtureDir]),
            halt(2)
        )).

require_clean_load :-
    aggregate_all(count, load_problem(_, _), Problems),
    (   Problems =:= 0
    ->  true
    ;   format(user_error, "refusing: ~d load warning(s) or error(s)~n", [Problems]),
        halt(2)
    ).

% Every expectation is fixture_expectation(Name, query(Goal), Kind) and every
% premise is fixture_premise(Name, query(Goal)) naming an expectation. A
% premise of another shape would otherwise be skipped silently.
require_well_formed_fixtures :-
    findall(Problem, fixture_problem(Problem), Problems),
    (   Problems == []
    ->  true
    ;   forall(member(P, Problems), format(user_error, "malformed: ~q~n", [P])),
        halt(2)
    ).

fixture_problem(expectation(Name, Query)) :-
    catch(user:fixture_expectation(Name, Query, _), _, fail),
    Query \= query(_).
fixture_problem(premise(Name, Query)) :-
    catch(user:fixture_premise(Name, Query), _, fail),
    Query \= query(_).
fixture_problem(orphan_premise(Name)) :-
    catch(user:fixture_premise(Name, _), _, fail),
    \+ user:fixture_expectation(Name, _, _).
