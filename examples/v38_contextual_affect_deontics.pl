:- encoding(utf8).
% =========================================================================
%  v3.8 sketch — Contextual affect-deontic path lift
%
%  This is a thin bridge over the ADQ v3.7 deontic facts. It is intentionally
%  not an alternate source of normative facts.
%
%  Expected ADQ predicates supplied by the corpus:
%    deontic_obligation/6
%    deontic_anti_pair/4
%
%  New execution/context predicates supplied by a caller or future harness:
%    ctx/3
%    ctx_affect/6
%    path_realizes/4
%    path_obligation_scope/4
%    agent_subject/2
% =========================================================================

:- multifile(ctx/3).
:- multifile(ctx_affect/6).
:- multifile(path_realizes/4).
:- multifile(path_obligation_scope/4).
:- multifile(agent_subject/2).

:- discontiguous(ctx/3).
:- discontiguous(ctx_affect/6).
:- discontiguous(path_realizes/4).
:- discontiguous(path_obligation_scope/4).
:- discontiguous(agent_subject/2).

% -------------------------------------------------------------------------
% Context schema hooks
% -------------------------------------------------------------------------

% ctx(World, Agent, Conditions).
% Conditions is a list of contextual atoms/terms such as:
%   within_capacity
%   when_displaces_taqwa
%   in_war_context
%   causes_dispersal
%   stronger_than(other_than_allah)
%
% ctx_affect(World, Agent, Affect, Object, Evidence, ControlStatus).
% ControlStatus separates bare involuntary feeling from taklif-eligible affect.
%
% Accepted control statuses for direct hukm lifting:
%   cultivated
%   dominant
%   endorsed
%   action_guiding
%   oriented
%
% Non-liability statuses should remain context evidence only:
%   raw_occurrence
%   involuntary_startle
%   panic_overflow
%   descriptive_only

under_taklif_control(cultivated).
under_taklif_control(dominant).
under_taklif_control(endorsed).
under_taklif_control(action_guiding).
under_taklif_control(oriented).

outside_direct_taklif(raw_occurrence).
outside_direct_taklif(involuntary_startle).
outside_direct_taklif(panic_overflow).
outside_direct_taklif(descriptive_only).

% all_mukallafin is the default broad subject in ADQ v37.
subject_matches(_Agent, all_mukallafin) :- !.
subject_matches(Agent, Subject) :-
    agent_subject(Agent, Subject).

modality_satisfied(unconditional, _Conditions) :- !.
modality_satisfied(conditional(Cond), Conditions) :-
    memberchk(Cond, Conditions).
modality_satisfied(comparative(stronger_than(Other)), Conditions) :-
    memberchk(stronger_than(Other), Conditions).
modality_satisfied(scalar(within_capacity), Conditions) :-
    memberchk(within_capacity, Conditions).
modality_satisfied(scalar(Scale), Conditions) :-
    Scale \= within_capacity,
    memberchk(Scale, Conditions).

% -------------------------------------------------------------------------
% Local hukm lifting
% -------------------------------------------------------------------------

local_affect_hukm(World, Agent, Affect, Object, Operator, Modality, Warrant) :-
    ctx(World, Agent, Conditions),
    ctx_affect(World, Agent, Affect, Object, _Evidence, ControlStatus),
    under_taklif_control(ControlStatus),
    deontic_obligation(Affect, Object, Subject, Operator, Modality, Warrant),
    subject_matches(Agent, Subject),
    modality_satisfied(Modality, Conditions).

% -------------------------------------------------------------------------
% Path-level violations
% -------------------------------------------------------------------------

% A forbidden affect/object realized along a path blocks affect-ideality.
path_affect_violation(World, Path, forbidden(Affect, Object, Warrant)) :-
    ctx(World, Agent, _Conditions),
    path_realizes(Path, Agent, Affect, Object),
    local_affect_hukm(World, Agent, Affect, Object, f, _Modality, Warrant).

% Obligatory affects only fail a path when the path is explicitly in that
% obligation's local scope. This avoids requiring every obligation everywhere.
path_affect_violation(World, Path, missing_required(Affect, Object, Warrant)) :-
    ctx(World, Agent, _Conditions),
    path_obligation_scope(Path, Agent, Affect, Object),
    local_affect_hukm(World, Agent, Affect, Object, o, _Modality, Warrant),
    \+ path_realizes(Path, Agent, Affect, Object).

% Anti-pair displacement: realizing the forbidden pole without the commanded
% pole is an affect-deontic path defect.
path_affect_violation(_World, Path, anti_pair_displacement(Commanded, Forbidden, Object)) :-
    path_realizes(Path, Agent, Forbidden, Object),
    deontic_anti_pair(Commanded, Forbidden, Object, _Meta),
    \+ path_realizes(Path, Agent, Commanded, Object).

ideal_path_affect_ok(World, Path) :-
    \+ path_affect_violation(World, Path, _Reason).
