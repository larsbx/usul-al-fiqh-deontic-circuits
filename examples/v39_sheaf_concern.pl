:- encoding(utf8).
% =========================================================================
%  v3.9 sheaf/gluing concern fixtures
%
%  Owns finite local sections, compatibility, gluing, obstruction records, and
%  named fixture expectations. It consumes the v38 bridge plus the separated
%  affect and temporal concerns.
% =========================================================================

:- ensure_loaded(v38_contextual_affect_deontics).
:- ensure_loaded(v39_affect_concern).
:- ensure_loaded(v39_temporal_concern).

% -------------------------------------------------------------------------
% Finite sheaf-style sections and obstruction records
% -------------------------------------------------------------------------

local_section(World, Agent,
    deontic(Affect, Object, Operator, Modality, Warrant)) :-
    local_affect_hukm(World, Agent, Affect, Object, Operator, Modality, Warrant).

operator_incompatible(o, f).
operator_incompatible(f, o).
operator_incompatible(o, n).
operator_incompatible(n, o).
operator_incompatible(f, n).
operator_incompatible(n, f).

same_section_scope(
    deontic(Affect, Object, _Operator1, _Modality1, _Warrant1),
    deontic(Affect, Object, _Operator2, _Modality2, _Warrant2)).

section_conflict(S1, S2, operator_conflict) :-
    same_section_scope(S1, S2),
    S1 = deontic(_, _, Op1, _, _),
    S2 = deontic(_, _, Op2, _, _),
    operator_incompatible(Op1, Op2).

world_obstruction(World, Reason) :-
    ctx(World, Agent, _),
    local_section(World, Agent, S1),
    local_section(World, Agent, S2),
    S1 @< S2,
    section_conflict(S1, S2, Conflict),
    Reason = obstruction(Conflict, S1, S2).

path_obstruction(World, Path, Reason) :-
    path_affect_violation(World, Path, Reason).

% A world glues when its active local sections do not conflict.
world_gluable(World) :-
    ctx(World, _Agent, _),
    \+ world_obstruction(World, _Reason).

% A path glues when the world glues and the v38 affect-path filter accepts it.
path_gluable(World, Path) :-
    world_gluable(World),
    ideal_path_affect_ok(World, Path).

% -------------------------------------------------------------------------
% Named fixture expectations for future test harnesses
% -------------------------------------------------------------------------

fixture_expectation(allah_fear_path_glues,
    query(path_gluable(w_allah_fear, path_allah_fear_ok)),
    expect_true).

fixture_expectation(other_fear_displacing_taqwa_blocks,
    query(path_obstruction(w_other_fear_defect, path_other_fear_defect,
        forbidden(khawf, other_than_allah, quranic('3:175')))),
    expect_true).

fixture_expectation(qunut_without_raja_blocks_by_forbidden_and_antipair,
    query(path_obstruction(w_rahmah_balance, path_qunut_without_raja, _Reason)),
    expect_true).

fixture_expectation(yusuf_brothers_hasad_blocks,
    query(path_obstruction(w_yusuf_brothers, path_yusuf_brothers,
        forbidden(hasad, creation_blessing, behavioral_profile(hasad)))),
    expect_true).

fixture_expectation(involuntary_panic_not_direct_liability,
    query(path_gluable(w_involuntary_panic, path_panic_only)),
    expect_true).

fixture_expectation(operator_conflict_emits_obstruction,
    query(world_obstruction(w_fixture_conflict, _Reason)),
    expect_true).

% -------------------------------------------------------------------------
% Discriminating vectors
%
% Each guard is pinned from both sides: the positive vectors above show an
% obstruction or section appears when its conditions hold; the vectors below
% show it does not appear when exactly one condition is withdrawn.
% -------------------------------------------------------------------------

% The aggregate qunut vector above accepts any reason; pin each reason.
fixture_expectation(qunut_without_raja_emits_forbidden,
    query(path_obstruction(w_rahmah_balance, path_qunut_without_raja,
        forbidden(qunut, allah_rahmah, quranic('39:53')))),
    expect_true).

fixture_expectation(qunut_without_raja_emits_missing_required,
    query(path_obstruction(w_rahmah_balance, path_qunut_without_raja,
        missing_required(raja, allah_rahmah, quranic('39:53')))),
    expect_true).

fixture_expectation(qunut_without_raja_emits_anti_pair_displacement,
    query(path_obstruction(w_rahmah_balance, path_qunut_without_raja,
        anti_pair_displacement(raja, qunut, allah_rahmah))),
    expect_true).

% Realizing the obligation in scope discharges it.
fixture_expectation(raja_path_glues,
    query(path_gluable(w_rahmah_balance, path_raja_ok)),
    expect_true).

fixture_expectation(raja_path_has_no_missing_required,
    query(path_obstruction(w_rahmah_balance, path_raja_ok,
        missing_required(_, _, _))),
    expect_false).

% Incompatible operators on different affects are not a same-scope conflict.
fixture_expectation(distinct_affects_do_not_conflict,
    query(world_obstruction(w_rahmah_balance, _)),
    expect_false).

% Capacity guard: affect outside direct taklif lifts no section.
fixture_expectation(involuntary_panic_lifts_no_section,
    query(local_section(w_involuntary_panic, agent, _)),
    expect_false).

fixture_expectation(involuntary_panic_path_has_no_obstruction,
    query(path_obstruction(w_involuntary_panic, path_panic_only, _)),
    expect_false).

% Modality guard: withdraw only the modal condition.
fixture_expectation(other_fear_without_displacement_not_forbidden,
    query(path_obstruction(w_other_fear_no_displacement, path_other_fear_defect,
        forbidden(khawf, other_than_allah, _))),
    expect_false).

fixture_expectation(allah_fear_with_precedence_lifts_obligation,
    query(local_section(w_allah_fear, agent,
        deontic(khawf, allah_essence, o,
            comparative(stronger_than(other_than_allah)), quranic('3:175')))),
    expect_true).

fixture_expectation(allah_fear_without_precedence_lifts_no_obligation,
    query(local_section(w_allah_fear_no_precedence, agent,
        deontic(khawf, allah_essence, o, _, _))),
    expect_false).

% Subject guard: a subject-scoped fact lifts only for agents in that subject.
fixture_expectation(subject_scoped_fact_lifts_inside_subject,
    query(local_section(w_subject_inside, member,
        deontic(test_scoped_affect, test_object, f, unconditional,
            fixture(subject_scoped)))),
    expect_true).

fixture_expectation(subject_scoped_fact_does_not_lift_outside_subject,
    query(local_section(w_subject_outside, outsider, _)),
    expect_false).

% -------------------------------------------------------------------------
% Premises for negative vectors
%
% A query over a world, agent, or fact that does not exist fails trivially.
% Each expect_false vector therefore names the data it relies on, so the
% withdrawn guard is the only reason the query can fail.
% -------------------------------------------------------------------------

fixture_premise(raja_path_has_no_missing_required,
    query(path_obligation_scope(path_raja_ok, agent, raja, allah_rahmah))).
fixture_premise(raja_path_has_no_missing_required,
    query(local_section(w_rahmah_balance, agent,
        deontic(raja, allah_rahmah, o, _, _)))).

fixture_premise(distinct_affects_do_not_conflict,
    query(local_section(w_rahmah_balance, agent,
        deontic(raja, allah_rahmah, o, _, _)))).
fixture_premise(distinct_affects_do_not_conflict,
    query(local_section(w_rahmah_balance, agent,
        deontic(qunut, allah_rahmah, f, _, _)))).

fixture_premise(involuntary_panic_lifts_no_section,
    query(ctx_affect(w_involuntary_panic, agent, khawf_panic, threat, _,
        panic_overflow))).
fixture_premise(involuntary_panic_lifts_no_section,
    query(deontic_obligation(khawf_panic, threat, _, _, _, _))).

fixture_premise(involuntary_panic_path_has_no_obstruction,
    query(path_realizes(path_panic_only, agent, khawf_panic, threat))).

fixture_premise(other_fear_without_displacement_not_forbidden,
    query(ctx_affect(w_other_fear_no_displacement, agent, khawf,
        other_than_allah, _, action_guiding))).
fixture_premise(other_fear_without_displacement_not_forbidden,
    query(( ctx(w_other_fear_no_displacement, agent, Conditions),
            \+ memberchk(when_displaces_taqwa, Conditions) ))).
fixture_premise(other_fear_without_displacement_not_forbidden,
    query(path_realizes(path_other_fear_defect, agent, khawf,
        other_than_allah))).

fixture_premise(allah_fear_without_precedence_lifts_no_obligation,
    query(ctx_affect(w_allah_fear_no_precedence, agent, khawf, allah_essence,
        _, oriented))).
fixture_premise(allah_fear_without_precedence_lifts_no_obligation,
    query(( ctx(w_allah_fear_no_precedence, agent, Conditions),
            \+ memberchk(stronger_than(other_than_allah), Conditions) ))).

fixture_premise(subject_scoped_fact_does_not_lift_outside_subject,
    query(ctx_affect(w_subject_outside, outsider, test_scoped_affect,
        test_object, _, action_guiding))).
fixture_premise(subject_scoped_fact_does_not_lift_outside_subject,
    query(\+ agent_subject(outsider, test_subject_class))).
