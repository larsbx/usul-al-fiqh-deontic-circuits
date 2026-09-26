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
