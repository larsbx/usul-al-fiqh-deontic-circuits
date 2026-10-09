:- encoding(utf8).
% =========================================================================
%  v3.9 claim concern fixtures
%
%  Owns proposed local sections: candidate verdicts from an LLM harness, an
%  import adapter, or a restriction from another context. A claim never adds
%  a section. The sheaf concern checks it against the same guards that lift
%  sections and emits an obstruction naming the check that failed.
%
%  section_claim(World, Agent, deontic(Affect, Object, Operator, Modality,
%      Warrant), Origin).
% =========================================================================

:- discontiguous(section_claim/4).

% Clean claims: each matches a section the kernel lifts.
section_claim(w_allah_fear, agent,
    deontic(khawf, allah_essence, o,
        comparative(stronger_than(other_than_allah)), quranic('3:175')),
    fixture(candidate)).

section_claim(w_yusuf_brothers, brothers,
    deontic('ḥasad', creation_blessing, f, conditional(action_guiding),
        behavioral_profile(hasad)),
    fixture(display_alias)).

% Obstructed claims: each fails exactly one check.
section_claim(w_claim_alias, agent,
    deontic(test_ambiguous_alias, test_object, f, unconditional,
        fixture(haram_side)),
    fixture(ambiguous_alias)).

% The allah_essence obligation applied to other_than_allah.
section_claim(w_claim_object, agent,
    deontic(khawf, other_than_allah, o,
        comparative(stronger_than(other_than_allah)), quranic('3:175')),
    fixture(wrong_object)).

section_claim(w_claim_subject, outsider,
    deontic(test_scoped_affect, test_object, f, unconditional,
        fixture(subject_scoped)),
    fixture(outside_subject)).

section_claim(w_claim_modality, agent,
    deontic(khawf, other_than_allah, f, conditional(when_displaces_taqwa),
        quranic('3:175')),
    fixture(inactive_modality)).

% Bare involuntary affect treated as culpable.
section_claim(w_claim_capacity, agent,
    deontic(hasad, creation_blessing, f, conditional(action_guiding),
        behavioral_profile(hasad)),
    fixture(involuntary)).

section_claim(w_claim_tier, agent,
    deontic(khawf, other_than_allah, f, conditional(when_displaces_taqwa),
        quranic('3:175')),
    fixture(quarantined_evidence)).

% Inverted operator: no source fact carries it.
section_claim(w_claim_unsupported, agent,
    deontic(raja, allah_rahmah, f, unconditional, quranic('39:53')),
    fixture(invented_verdict)).

section_claim(w_claim_unobserved, agent,
    deontic(raja, allah_rahmah, o, unconditional, quranic('39:53')),
    fixture(no_observation)).

% No ctx/3 for this world: the claim has no context to be checked against.
section_claim(w_claim_no_context, agent,
    deontic(raja, allah_rahmah, o, unconditional, quranic('39:53')),
    fixture(no_context)).

% Membership of `stranger` is unknown: the claim is undetermined, not obstructed.
section_claim(w_subject_unresolved, stranger,
    deontic(test_scoped_affect, test_object, f, unconditional,
        fixture(subject_scoped)),
    fixture(unknown_membership)).

% Unknown membership and no observation: the observation failure is a
% determined obstruction, so the claim is obstructed, not undetermined.
section_claim(w_claim_unresolved_unobserved, stranger,
    deontic(test_scoped_affect, test_object, f, unconditional,
        fixture(subject_scoped)),
    fixture(unknown_membership_without_observation)).
