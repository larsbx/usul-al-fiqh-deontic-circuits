:- encoding(utf8).
% =========================================================================
%  Executes every fixture_expectation/3 vector and exits non-zero on any
%  failure.
%
%    swipl tests/run_fixture_expectations.pl [-- FixtureFile]
%
%  FixtureFile defaults to the v39 aggregator. It must follow `--`: swipl
%  loads any other trailing file argument as source, which would mix two
%  fixture sets. The runner refuses to judge expectations defined in a file
%  other than the one it was asked to load.
% =========================================================================

:- use_module(fixture_runner).

:- initialization(main, main).

default_fixture_file(File) :-
    source_file(default_fixture_file(_), Here),
    file_directory_name(Here, Dir),
    directory_file_path(Dir, '../examples/v39_sheaf_obstruction_fixtures.pl', File).

main(Argv) :-
    (   Argv = [File] -> true
    ;   Argv = [] -> default_fixture_file(File)
    ;   format(user_error, "usage: run_fixture_expectations.pl [FixtureFile]~n", []),
        halt(2)
    ),
    absolute_file_name(File, Path, [access(read)]),
    load_files(user:Path, [if(true)]),
    require_expectations_from(Path),
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
