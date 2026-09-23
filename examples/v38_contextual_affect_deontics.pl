% v38_contextual_affect_deontics.pl
%
% Finite scaffold for lifting ADQ affect-deontic facts into contextual
% path filtering and sheaf-style gluing/obstruction checks.
%
% This file is intentionally small and standalone. It is not a fiqh authority
% and does not import the full ADQ corpus. Replace the sample facts with the
% accepted canonical ADQ bundle when the import layer is ready.

% ---------------------------------------------------------------------------
% Sample ADQ-shaped local deontic facts
% ---------------------------------------------------------------------------

% deontic_obligation(Affect, Object, Subject, Operator, Modality, Warrant).
% Operators: o obligatory, f forbidden, r recommended, d discouraged,
% p permitted, n outside taklif / descriptive-only.

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

% deontic_anti_pair(Commanded, Forbidden, Object, Metadata).

deontic_anti_pair(raja, qunut, allah_rahmah,
    [warrant(quranic('39:53')), relation(displacement)]).

% ---------------------------------------------------------------------------
% Finite context site
% ---------------------------------------------------------------------------

% context(Context).

context(base).
context(ctx_allah_fear).
context(ctx_other_fear_displacing_taqwa).
context(ctx_rahmah_hope).
context(ctx_creation_blessing_action_guiding_hasad).
context(ctx_involuntary_panic).
context(ctx_yusuf_brothers_path).

% refines(Smaller, Larger).
% Smaller contexts carry more information.

refines(ctx_allah_fear, base).
refines(ctx_other_fear_displacing_taqwa, base).
refines(ctx_rahmah_hope, base).
refines(ctx_creation_blessing_action_guiding_hasad, base).
refines(ctx_involuntary_panic, base).
refines(ctx_yusuf_brothers_path, ctx_creation_blessing_action_guiding_hasad).
refines(ctx_yusuf_brothers_path, base).

% transitive refinement closure.

refines_star(C, C).
refines_star(Smaller, Larger) :-
    refines(Smaller, Mid),
    refines_star(Mid, Larger).

% Context features.

ctx_subject(_, all_mukallafin).

ctx_object(ctx_allah_fear, allah_essence).
ctx_object(ctx_other_fear_displacing_taqwa, other_than_allah).
ctx_object(ctx_rahmah_hope, allah_rahmah).
ctx_object(ctx_creation_blessing_action_guiding_hasad, creation_blessing).
ctx_object(ctx_yusuf_brothers_path, creation_blessing).
ctx_object(ctx_involuntary_panic, threat).

ctx_condition(ctx_allah_fear, stronger_than(other_than_allah)).
ctx_condition(ctx_other_fear_displacing_taqwa, when_displaces_taqwa).
ctx_condition(ctx_rahmah_hope, ordinary_capacity).
ctx_condition(ctx_creation_blessing_action_guiding_hasad, action_guiding).
ctx_condition(ctx_yusuf_brothers_path, action_guiding).
ctx_condition(ctx_involuntary_panic, involuntary).

ctx_evidence_tier(ctx_allah_fear, tier1).
ctx_evidence_tier(ctx_other_fear_displacing_taqwa, tier1).
ctx_evidence_tier(ctx_rahmah_hope, tier1).
ctx_evidence_tier(ctx_creation_blessing_action_guiding_hasad, tier2).
ctx_evidence_tier(ctx_yusuf_brothers_path, tier2).
ctx_evidence_tier(ctx_involuntary_panic, tier3).

% ---------------------------------------------------------------------------
% Modality, subject, object, and tier guards
% ---------------------------------------------------------------------------

subject_active(Context, Subject) :-
    ctx_subject(Context, Subject).
subject_active(Context, Subject) :-
    refines_star(Context, Parent),
    ctx_subject(Parent, Subject).

object_active(Context, Object) :-
    ctx_object(Context, Object).
object_active(Context, Object) :-
    refines_star(Context, Parent),
    ctx_object(Parent, Object).

condition_active(Context, Condition) :-
    ctx_condition(Context, Condition).
condition_active(Context, Condition) :-
    refines_star(Context, Parent),
    ctx_condition(Parent, Condition).

modality_satisfied(_, unconditional).
modality_satisfied(Context, conditional(Condition)) :-
    condition_active(Context, Condition).
modality_satisfied(Context, comparative(Condition)) :-
    condition_active(Context, Condition).
modality_satisfied(Context, scalar(Condition)) :-
    condition_active(Context, Condition).

normative_tier(tier1).
normative_tier(tier2).
normative_tier(tier3).

ctx_normative_evidence_ok(Context) :-
    ctx_evidence_tier(Context, Tier),
    normative_tier(Tier).

% ---------------------------------------------------------------------------
% Local sections and restrictions
% ---------------------------------------------------------------------------

section(Context, deontic(Affect, Object, Subject, Operator, Modality, Warrant)) :-
    deontic_obligation(Affect, Object, Subject, Operator, Modality, Warrant),
    subject_active(Context, Subject),
    object_active(Context, Object),
    modality_satisfied(Context, Modality),
    ctx_normative_evidence_ok(Context).

% Restriction is identity when a section remains active after refinement.
% Later revisions may add explicit weakening/suspension transforms.

restrict(Section, From, To, Section) :-
    refines_star(To, From),
    Section = deontic(_, _, _, _, _, _),
    section(To, Section).

% ---------------------------------------------------------------------------
% Path realization and affect path filters
% ---------------------------------------------------------------------------

% path_realizes(Path, Agent, Affect, Object).

path_realizes(path_yusuf_brothers, brothers, hasad, creation_blessing).
path_realizes(path_qunut_without_raja, agent, qunut, allah_rahmah).
path_realizes(path_panic_only, agent, khawf_panic, threat).
path_realizes(path_raja_balance, agent, raja, allah_rahmah).

path_context(path_yusuf_brothers, ctx_yusuf_brothers_path).
path_context(path_qunut_without_raja, ctx_rahmah_hope).
path_context(path_panic_only, ctx_involuntary_panic).
path_context(path_raja_balance, ctx_rahmah_hope).

path_affect_violation(Path, forbidden(Affect, Object, Warrant)) :-
    path_context(Path, Context),
    path_realizes(Path, _, Affect, Object),
    section(Context, deontic(Affect, Object, _, f, _, Warrant)).

path_affect_violation(Path, missing_required(Affect, Object, Warrant)) :-
    path_context(Path, Context),
    section(Context, deontic(Affect, Object, _, o, _, Warrant)),
    \+ path_realizes(Path, _, Affect, Object).

path_affect_violation(Path, anti_pair_failure(Commanded, Forbidden, Object)) :-
    path_realizes(Path, _, Forbidden, Object),
    deontic_anti_pair(Commanded, Forbidden, Object, _),
    \+ path_realizes(Path, _, Commanded, Object).

% Descriptive/outside-taklif facts do not create path liability by themselves.

outside_taklif_realization(Path, Affect, Object) :-
    path_context(Path, Context),
    path_realizes(Path, _, Affect, Object),
    section(Context, deontic(Affect, Object, _, n, _, _)).

ideal_path_affect_ok(Path) :-
    \+ path_affect_violation(Path, _).

% ---------------------------------------------------------------------------
% Compatibility, gluing, and obstruction
% ---------------------------------------------------------------------------

conflicting_operator(o, f).
conflicting_operator(f, o).
conflicting_operator(o, n).
conflicting_operator(n, o).
conflicting_operator(f, n).
conflicting_operator(n, f).

same_scope(deontic(Affect, Object, Subject, _, _, _),
           deontic(Affect, Object, Subject, _, _, _)).

compatible_sections(S1, S2) :-
    \+ (
        same_scope(S1, S2),
        S1 = deontic(_, _, _, Op1, _, _),
        S2 = deontic(_, _, _, Op2, _, _),
        conflicting_operator(Op1, Op2)
    ).

obstruction(Context, operator_conflict(S1, S2)) :-
    section(Context, S1),
    section(Context, S2),
    S1 @< S2,
    \+ compatible_sections(S1, S2).

obstruction(Context, tier_quarantine(Tier)) :-
    ctx_evidence_tier(Context, Tier),
    \+ normative_tier(Tier).

obstruction(Path, path_violation(Reason)) :-
    path_affect_violation(Path, Reason).

% A context is gluable when all active sections are pairwise compatible and no
% local obstruction is emitted.

gluable_context(Context) :-
    context(Context),
    \+ obstruction(Context, _).

% A path is gluable when its local context glues and its affect realization is
% ideal-path compatible.

gluable_path(Path) :-
    path_context(Path, Context),
    gluable_context(Context),
    ideal_path_affect_ok(Path).

% ---------------------------------------------------------------------------
% Expected smoke queries
% ---------------------------------------------------------------------------

% ?- section(ctx_allah_fear, S).
% ?- obstruction(path_yusuf_brothers, Reason).
% ?- obstruction(path_qunut_without_raja, Reason).
% ?- outside_taklif_realization(path_panic_only, A, O).
% ?- gluable_path(path_raja_balance).
