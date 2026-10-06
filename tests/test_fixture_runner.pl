:- encoding(utf8).
% =========================================================================
%  Runner self-tests
%
%  The fixture runner must fail closed: a wrong expectation, an unknown
%  expectation kind, a query or premise that raises, a failed premise, a
%  negative vector without premises, a duplicate name, or an empty expectation
%  set is a failure, never a pass or a skip.
% =========================================================================

:- use_module(library(plunit)).
:- use_module(fixture_runner).

runner_probe_true.

:- begin_tests(fixture_runner).

test(expect_true_passes_when_query_succeeds) :-
    check_expectation(user:runner_probe_true, expect_true, [user:true], pass).

test(expect_true_fails_when_query_fails) :-
    check_expectation(user:fail, expect_true, [user:true], fail(query_failed)).

test(expect_false_passes_when_query_fails) :-
    check_expectation(user:fail, expect_false, [user:true], pass).

test(expect_false_fails_when_query_succeeds) :-
    check_expectation(user:runner_probe_true, expect_false, [user:true], fail(query_succeeded)).

test(undefined_predicate_is_failure_not_skip) :-
    check_expectation(user:runner_probe_undefined_xyz, expect_false, [user:true],
        fail(error(_))).

test(unknown_kind_is_failure) :-
    check_expectation(user:true, expect_maybe, [user:true], fail(unknown_kind(expect_maybe))).

test(flipped_polarity_always_fails) :-
    forall(member(Q-K, [runner_probe_true-expect_true, fail-expect_false]),
        ( flip_kind(K, Flipped),
          check_expectation(user:Q, Flipped, [user:true], fail(_)) )).

test(empty_expectation_set_fails) :-
    run_expectations([], Results),
    Results = [result('<suite>', fail(no_expectations))].

test(duplicate_names_fail) :-
    run_expectations(
        [ expectation(dup, user:true, expect_true, []),
          expectation(dup, user:true, expect_true, []) ],
        Results),
    memberchk(result(dup, fail(duplicate_name)), Results).

test(expect_false_without_premise_is_vacuous) :-
    check_expectation(user:fail, expect_false, [], fail(vacuous_negative)).

test(failing_premise_fails_negative_vector) :-
    check_expectation(user:fail, expect_false, [user:fail],
        fail(premise_failed(user:fail))).

test(failing_premise_fails_positive_vector) :-
    check_expectation(user:true, expect_true, [user:fail],
        fail(premise_failed(user:fail))).

test(raising_premise_is_failure) :-
    check_expectation(user:true, expect_true, [user:runner_probe_undefined_xyz],
        fail(error(_))).

test(failure_count_counts_only_failures) :-
    failure_count(
        [ result(a, pass), result(b, fail(query_failed)), result(c, fail(error(x))) ],
        2).

:- end_tests(fixture_runner).
