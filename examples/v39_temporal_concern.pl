:- encoding(utf8).
% =========================================================================
%  v3.9 temporal/path concern fixtures
%
%  Owns worlds, context conditions, path realization, and local obligation
%  scope. This file intentionally does not own affect-deontic facts or sheaf
%  gluing/obstruction logic.
% =========================================================================

:- discontiguous(ctx/3).
:- discontiguous(path_realizes/4).
:- discontiguous(path_obligation_scope/4).
:- discontiguous(agent_subject/2).

% -------------------------------------------------------------------------
% Fixture worlds and their context conditions
% -------------------------------------------------------------------------

ctx(w_allah_fear, agent, [within_capacity, stronger_than(other_than_allah)]).
ctx(w_other_fear_defect, agent, [within_capacity, when_displaces_taqwa]).
ctx(w_rahmah_balance, agent, [within_capacity]).
ctx(w_yusuf_brothers, brothers, [within_capacity, action_guiding]).
ctx(w_involuntary_panic, agent, [involuntary]).
ctx(w_fixture_conflict, agent, [within_capacity]).

% -------------------------------------------------------------------------
% Path scopes and realizations
% -------------------------------------------------------------------------

path_obligation_scope(path_allah_fear_ok, agent, khawf, allah_essence).
path_realizes(path_allah_fear_ok, agent, khawf, allah_essence).

path_realizes(path_other_fear_defect, agent, khawf, other_than_allah).

path_obligation_scope(path_raja_ok, agent, raja, allah_rahmah).
path_realizes(path_raja_ok, agent, raja, allah_rahmah).

path_obligation_scope(path_qunut_without_raja, agent, raja, allah_rahmah).
path_realizes(path_qunut_without_raja, agent, qunut, allah_rahmah).

path_realizes(path_yusuf_brothers, brothers, hasad, creation_blessing).

path_realizes(path_panic_only, agent, khawf_panic, threat).
