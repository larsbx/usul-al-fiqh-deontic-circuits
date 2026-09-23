:- encoding(utf8).
% =========================================================================
%  v3.9 sketch — finite sheaf obstruction fixtures
%
%
%  This fixture layer makes the sheaf/context-site architecture executable in
%  small examples. It imports the v3.8 contextual affect-deontic bridge and
%  adds sample ADQ-shaped facts plus finite gluing/obstruction predicates.
%
%  This is not a fiqh authority. It is a harness for testing whether local
%  contextual sections glue cleanly or emit structured obstruction reasons.
% =========================================================================

:- ensure_loaded(v38_contextual_affect_deontics).

:- discontiguous(deontic_obligation/6).
:- discontiguous(deontic_anti_pair/4).
:- discontiguous(ctx/3).
:- discontiguous(ctx_affect/6).
:- discontiguous(path_realizes/4).
:- discontiguous(path_obligation_scope/4).
:- discontiguous(agent_subject/2).

% -------------------------------------------------------------------------
% Minimal ADQ-shaped facts for fixtures
% -------------------------------------------------------------------------

deontic_obligation(khawf, allah_essence, all_mukallafin,
    o, comparative(stronger_than(other_than_allah)), quranic('3:175')).

deontic_obligation(khawf, other_than_allah, all_mukallafin,
    f, conditional(when_displaces_taqwa), quranic('3:175')).

deontic_obligation(raja, allah_rahmah, all_mukallafin,
    o, unconditional, quranic('39:53')).

deontic_obligation(qunut, allah_rahmah, all_mukallafin,
    f, unconditional, quranic('39:53')).

deontic_obligation(hasad, creation_blessing, all_mukallafin,
    f, conditional(action_guiding), behavioral_profile(hasad)).

deontic_obligation(khawf_panic, threat, all_mukallafin,
    n, conditional(involuntary), somatic_context_only).

% Deliberate fixture conflict: same scope, incompatible operators. This is not
% source-derived; it exists only to prove the obstruction lane fails closed.
deontic_obligation(test_conflict_affect, test_object, all_mukallafin,
    o, unconditional, fixture(wajib_side)).

deontic_obligation(test_conflict_affect, test_object, all_mukallafin,
    f, unconditional, fixture(haram_side)).

deontic_anti_pair(raja, qunut, allah_rahmah,
    [warrant(quranic('39:53')), relation(displacement)]).

% -------------------------------------------------------------------------
% Fixture worlds and paths
% -------------------------------------------------------------------------

ctx(w_allah_fear, agent, [within_capacity, stronger_than(other_than_allah)]).
ctx_affect(w_allah_fear, agent, khawf, allah_essence,
    evidence(tier1, quranic('3:175')), oriented).
path_obligation_scope(path_allah_fear_ok, agent, khawf, allah_essence).
path_realizes(path_allah_fear_ok, agent, khawf, allah_essence).

ctx(w_other_fear_defect, agent, [within_capacity, when_displaces_taqwa]).
ctx_affect(w_other_fear_defect, agent, khawf, other_than_allah,
    evidence(tier1, quranic('3:175')), action_guiding).
path_realizes(path_other_fear_defect, agent, khawf, other_than_allah).

ctx(w_rahmah_balance, agent, [within_capacity]).
ctx_affect(w_rahmah_balance, agent, raja, allah_rahmah,
    evidence(tier1, quranic('39:53')), oriented).
ctx_affect(w_rahmah_balance, agent, qunut, allah_rahmah,
    evidence(tier1, quranic('39:53')), action_guiding).
path_obligation_scope(path_raja_ok, agent, raja, allah_rahmah).
path_realizes(path_raja_ok, agent, raja, allah_rahmah).
path_obligation_scope(path_qunut_without_raja, agent, raja, allah_rahmah).
path_realizes(path_qunut_without_raja, agent, qunut, allah_rahmah).

ctx(w_yusuf_brothers, brothers, [within_capacity, action_guiding]).
ctx_affect(w_yusuf_brothers, brothers, hasad, creation_blessing,
    evidence(tier2, behavioral_profile(hasad)), action_guiding).
path_realizes(path_yusuf_brothers, brothers, hasad, creation_blessing).

ctx(w_involuntary_panic, agent, [involuntary]).
ctx_affect(w_involuntary_panic, agent, khawf_panic, threat,
    evidence(tier3, somatic_context), panic_overflow).
path_realizes(path_panic_only, agent, khawf_panic, threat).

ctx(w_fixture_conflict, agent, [within_capacity]).
ctx_affect(w_fixture_conflict, agent, test_conflict_affect, test_object,
    evidence(fixture, generated), action_guiding).

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
% Smoke queries
% -------------------------------------------------------------------------

% ?- path_gluable(w_allah_fear, path_allah_fear_ok).
% ?- path_obstruction(w_other_fear_defect, path_other_fear_defect, Reason).
% ?- path_obstruction(w_rahmah_balance, path_qunut_without_raja, Reason).
% ?- path_obstruction(w_yusuf_brothers, path_yusuf_brothers, Reason).
% ?- path_gluable(w_involuntary_panic, path_panic_only).
% ?- world_obstruction(w_fixture_conflict, Reason).
