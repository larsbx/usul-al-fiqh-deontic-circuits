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
:- ensure_loaded(v39_claim_concern).

:- discontiguous(fixture_expectation/3).
:- discontiguous(fixture_premise/2).

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

world_obstruction(World, obstruction(Category, claim(Agent, Section), Detail)) :-
    claim_obstruction(World, Agent, Section, Category, Detail).

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
% Claim obstructions
%
% A claim is checked, never lifted. Each clause names one failed check and
% uses the same guard that local_affect_hukm/7 uses to lift, so a claim is
% obstructed exactly when it is not a lifted section.
% -------------------------------------------------------------------------

obstruction_category(object_collision).
obstruction_category(subject_collision).
obstruction_category(modality_unsatisfied).
obstruction_category(capacity_violation).
obstruction_category(tier_quarantine).
obstruction_category(anti_pair_failure).
obstruction_category(operator_conflict).
obstruction_category(alias_gluing_failure).
obstruction_category(unsupported_claim).

% resolve_id(+Term, -Resolution): id(Canonical) or ambiguous(Candidates).
% A term with no alias entry is taken as canonical.
resolve_id(Term, Resolution) :-
    findall(Id, canonical_alias(Term, Id), Ids0),
    sort(Ids0, Ids),
    (   Ids = [] -> Resolution = id(Term)
    ;   Ids = [Id] -> Resolution = id(Id)
    ;   Resolution = ambiguous(Ids)
    ).

normalized_section(deontic(Affect0, Object0, Operator, Modality, Warrant),
                   deontic(Affect, Object, Operator, Modality, Warrant)) :-
    resolve_id(Affect0, id(Affect)),
    resolve_id(Object0, id(Object)).

claim_lifted(World, Agent, Claim) :-
    normalized_section(Claim, Section),
    local_section(World, Agent, Section).

claim_obstruction(World, Agent, Claim, alias_gluing_failure,
        ambiguous_alias(Term, Ids)) :-
    section_claim(World, Agent, Claim, _Origin),
    Claim = deontic(Affect, Object, _, _, _),
    member(Term, [Affect, Object]),
    resolve_id(Term, ambiguous(Ids)).
claim_obstruction(World, Agent, Claim, Category, Detail) :-
    section_claim(World, Agent, Claim, _Origin),
    normalized_section(Claim, Section),
    section_obstruction(World, Agent, Section, Category, Detail).

section_obstruction(_World, _Agent,
        deontic(Affect, Object, Operator, Modality, Warrant),
        object_collision, claimed_object(Object, source_object(Source))) :-
    \+ deontic_obligation(Affect, Object, _, Operator, Modality, Warrant),
    deontic_obligation(Affect, Source, _, Operator, Modality, Warrant),
    Source \== Object.
section_obstruction(_World, _Agent,
        deontic(Affect, _Object, Operator, Modality, Warrant),
        unsupported_claim, no_source_fact) :-
    \+ deontic_obligation(Affect, _, _, Operator, Modality, Warrant).
section_obstruction(World, Agent, Section, unsupported_claim, no_context) :-
    source_fact(Section, _Subject),
    \+ ctx(World, Agent, _).
section_obstruction(_World, Agent, Section, subject_collision,
        outside_subject(Agent, Subject)) :-
    source_fact(Section, Subject),
    \+ subject_matches(Agent, Subject).
section_obstruction(World, Agent, Section, modality_unsatisfied,
        inactive(Modality)) :-
    source_fact(Section, _Subject),
    Section = deontic(_, _, _, Modality, _),
    ctx(World, Agent, Conditions),
    \+ modality_satisfied(Modality, Conditions).
section_obstruction(World, Agent, Section, unsupported_claim, no_observation) :-
    source_fact(Section, _Subject),
    Section = deontic(Affect, Object, _, _, _),
    \+ ctx_affect(World, Agent, Affect, Object, _, _).
section_obstruction(World, Agent, Section, capacity_violation,
        control_status(ControlStatus)) :-
    unsupported_observation(World, Agent, Section, _Evidence, ControlStatus),
    \+ under_taklif_control(ControlStatus).
section_obstruction(World, Agent, Section, tier_quarantine,
        quarantined_evidence(Evidence)) :-
    unsupported_observation(World, Agent, Section, Evidence, _ControlStatus),
    quarantined_evidence(Evidence).

source_fact(deontic(Affect, Object, Operator, Modality, Warrant), Subject) :-
    deontic_obligation(Affect, Object, Subject, Operator, Modality, Warrant).

% Observations are diagnosed only when none of them supports lifting.
unsupported_observation(World, Agent, Section, Evidence, ControlStatus) :-
    source_fact(Section, _Subject),
    Section = deontic(Affect, Object, _, _, _),
    \+ supporting_observation(World, Agent, Affect, Object),
    ctx_affect(World, Agent, Affect, Object, Evidence, ControlStatus).

% Path reasons that carry a documented obstruction category.
path_reason_category(anti_pair_displacement(_, _, _), anti_pair_failure).

emitted_category(Category) :-
    world_obstruction(_World, obstruction(Category, _, _)).
emitted_category(Category) :-
    path_obstruction(_World, _Path, Reason),
    path_reason_category(Reason, Category).

claim_obstruction_categories(World, Categories) :-
    findall(Category, claim_obstruction(World, _, _, Category, _), Found),
    sort(Found, Categories).

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

% -------------------------------------------------------------------------
% Claim obstruction vectors
%
% Each claim world fails exactly one check, so its category set is a
% singleton. Clean claims pin the other side.
% -------------------------------------------------------------------------

fixture_expectation(claim_with_alias_ambiguity_emits_only_alias_gluing_failure,
    query(claim_obstruction_categories(w_claim_alias, [alias_gluing_failure])),
    expect_true).

fixture_expectation(alias_gluing_failure_names_alias_and_candidates,
    query(claim_obstruction(w_claim_alias, agent, _, alias_gluing_failure,
        ambiguous_alias(test_ambiguous_alias,
            [test_conflict_affect, test_scoped_affect]))),
    expect_true).

fixture_expectation(claim_on_wrong_object_emits_only_object_collision,
    query(claim_obstruction_categories(w_claim_object, [object_collision])),
    expect_true).

fixture_expectation(object_collision_names_claimed_and_source_objects,
    query(claim_obstruction(w_claim_object, agent, _, object_collision,
        claimed_object(other_than_allah, source_object(allah_essence)))),
    expect_true).

fixture_expectation(claim_outside_subject_emits_only_subject_collision,
    query(claim_obstruction_categories(w_claim_subject, [subject_collision])),
    expect_true).

fixture_expectation(subject_collision_names_agent_and_subject,
    query(claim_obstruction(w_claim_subject, outsider, _, subject_collision,
        outside_subject(outsider, test_subject_class))),
    expect_true).

fixture_expectation(claim_with_inactive_modality_emits_only_modality_unsatisfied,
    query(claim_obstruction_categories(w_claim_modality, [modality_unsatisfied])),
    expect_true).

fixture_expectation(modality_unsatisfied_names_modality,
    query(claim_obstruction(w_claim_modality, agent, _, modality_unsatisfied,
        inactive(conditional(when_displaces_taqwa)))),
    expect_true).

fixture_expectation(claim_on_involuntary_affect_emits_only_capacity_violation,
    query(claim_obstruction_categories(w_claim_capacity, [capacity_violation])),
    expect_true).

fixture_expectation(capacity_violation_names_control_status,
    query(claim_obstruction(w_claim_capacity, agent, _, capacity_violation,
        control_status(raw_occurrence))),
    expect_true).

fixture_expectation(claim_on_quarantined_evidence_emits_only_tier_quarantine,
    query(claim_obstruction_categories(w_claim_tier, [tier_quarantine])),
    expect_true).

fixture_expectation(tier_quarantine_names_evidence,
    query(claim_obstruction(w_claim_tier, agent, _, tier_quarantine,
        quarantined_evidence(evidence(tier4, commentary(fixture))))),
    expect_true).

fixture_expectation(claim_without_source_fact_is_unsupported,
    query(claim_obstruction(w_claim_unsupported, agent, _, unsupported_claim,
        no_source_fact)),
    expect_true).

fixture_expectation(claim_without_observation_is_unsupported,
    query(claim_obstruction(w_claim_unobserved, agent, _, unsupported_claim,
        no_observation)),
    expect_true).

fixture_expectation(claim_without_context_is_unsupported,
    query(claim_obstruction(w_claim_no_context, agent, _, unsupported_claim,
        no_context)),
    expect_true).

% Quarantined evidence lifts nothing and so supports no path verdict.
fixture_expectation(quarantined_evidence_lifts_no_section,
    query(local_section(w_claim_tier, agent, _)),
    expect_false).

fixture_expectation(quarantined_evidence_supports_no_forbidden_path,
    query(path_obstruction(w_claim_tier, path_other_fear_defect,
        forbidden(_, _, _))),
    expect_false).

% Clean claims.
fixture_expectation(lifted_claim_is_clean,
    query(claim_obstruction(w_allah_fear, agent, _, _, _)),
    expect_false).

fixture_expectation(display_alias_claim_normalizes_and_is_clean,
    query(claim_obstruction(w_yusuf_brothers, brothers, _, _, _)),
    expect_false).

% A world with an obstructed claim does not glue.
fixture_expectation(claim_obstruction_blocks_world_gluing,
    query(world_obstruction(w_claim_subject,
        obstruction(subject_collision, claim(outsider, _), _))),
    expect_true).

fixture_expectation(world_with_obstructed_claim_is_not_gluable,
    query(world_gluable(w_claim_subject)),
    expect_false).

% The emitter and the lifting guards agree on every claim:
% obstructed ⇔ not lifted.
fixture_expectation(claim_obstruction_agrees_with_lifting,
    query(forall(section_claim(W, A, S, _),
        (   claim_obstruction(W, A, S, _, _)
        ->  \+ claim_lifted(W, A, S)
        ;   claim_lifted(W, A, S)
        ))),
    expect_true).

% Every obstruction category in docs/architecture/sheaf-context-site.md is
% emitted by at least one fixture world or path.
fixture_expectation(every_obstruction_category_is_emitted,
    query(forall(obstruction_category(C), emitted_category(C))),
    expect_true).

% -------------------------------------------------------------------------
% Premises for claim negatives
% -------------------------------------------------------------------------

fixture_premise(quarantined_evidence_lifts_no_section,
    query(ctx_affect(w_claim_tier, agent, khawf, other_than_allah,
        evidence(tier4, _), action_guiding))).
fixture_premise(quarantined_evidence_lifts_no_section,
    query(( ctx(w_claim_tier, agent, Conditions),
            memberchk(when_displaces_taqwa, Conditions) ))).

fixture_premise(quarantined_evidence_supports_no_forbidden_path,
    query(path_realizes(path_other_fear_defect, agent, khawf,
        other_than_allah))).
fixture_premise(quarantined_evidence_supports_no_forbidden_path,
    query(ctx(w_claim_tier, agent, _))).

fixture_premise(lifted_claim_is_clean,
    query(section_claim(w_allah_fear, agent, _, _))).

fixture_premise(display_alias_claim_normalizes_and_is_clean,
    query(section_claim(w_yusuf_brothers, brothers, deontic('ḥasad', _, _, _, _), _))).
fixture_premise(display_alias_claim_normalizes_and_is_clean,
    query(canonical_alias('ḥasad', hasad))).

fixture_premise(world_with_obstructed_claim_is_not_gluable,
    query(ctx(w_claim_subject, outsider, _))).

fixture_premise(claim_obstruction_agrees_with_lifting,
    query(aggregate_all(count, section_claim(_, _, _, _), N), N >= 10)).
