:- encoding(utf8).
% =========================================================================
%  v3.9 affect concern fixtures
%
%  Owns ADQ-shaped affect-deontic facts, anti-pairs, and local affect tokens.
%  This file intentionally does not own temporal path topology or sheaf gluing.
% =========================================================================

:- discontiguous(deontic_obligation/6).
:- discontiguous(deontic_anti_pair/4).
:- discontiguous(ctx_affect/6).
:- discontiguous(canonical_alias/2).

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

% Deliberate fixture subject scope: the only fact not addressed to
% all_mukallafin, so the subject guard can be exercised. Not source-derived.
deontic_obligation(test_scoped_affect, test_object, test_subject_class,
    f, unconditional, fixture(subject_scoped)).

deontic_anti_pair(raja, qunut, allah_rahmah,
    [warrant(quranic('39:53')), relation(displacement)]).

% -------------------------------------------------------------------------
% Canonical aliases: display form -> canonical ID
% -------------------------------------------------------------------------

canonical_alias('ḥasad', hasad).

% Deliberate fixture ambiguity: one alias, two canonical IDs. Not
% source-derived; it exists only to exercise alias_gluing_failure.
canonical_alias(test_ambiguous_alias, test_conflict_affect).
canonical_alias(test_ambiguous_alias, test_scoped_affect).

% -------------------------------------------------------------------------
% Local affect observations by world/agent
% -------------------------------------------------------------------------

ctx_affect(w_allah_fear, agent, khawf, allah_essence,
    evidence(tier1, quranic('3:175')), oriented).

ctx_affect(w_other_fear_defect, agent, khawf, other_than_allah,
    evidence(tier1, quranic('3:175')), action_guiding).

ctx_affect(w_rahmah_balance, agent, raja, allah_rahmah,
    evidence(tier1, quranic('39:53')), oriented).
ctx_affect(w_rahmah_balance, agent, qunut, allah_rahmah,
    evidence(tier1, quranic('39:53')), action_guiding).

ctx_affect(w_yusuf_brothers, brothers, hasad, creation_blessing,
    evidence(tier2, behavioral_profile(hasad)), action_guiding).

ctx_affect(w_involuntary_panic, agent, khawf_panic, threat,
    evidence(tier3, somatic_context), panic_overflow).

ctx_affect(w_fixture_conflict, agent, test_conflict_affect, test_object,
    evidence(fixture, generated), action_guiding).

% Guard-withdrawal worlds: each repeats an observation above in a context
% that lacks exactly one lifting condition.
ctx_affect(w_other_fear_no_displacement, agent, khawf, other_than_allah,
    evidence(tier1, quranic('3:175')), action_guiding).

ctx_affect(w_allah_fear_no_precedence, agent, khawf, allah_essence,
    evidence(tier1, quranic('3:175')), oriented).

ctx_affect(w_subject_inside, member, test_scoped_affect, test_object,
    evidence(fixture, generated), action_guiding).

ctx_affect(w_subject_outside, outsider, test_scoped_affect, test_object,
    evidence(fixture, generated), action_guiding).

% Claim worlds: observations against which proposed sections are checked.
ctx_affect(w_claim_object, agent, khawf, other_than_allah,
    evidence(tier1, quranic('3:175')), oriented).

ctx_affect(w_claim_subject, outsider, test_scoped_affect, test_object,
    evidence(fixture, generated), action_guiding).

ctx_affect(w_claim_modality, agent, khawf, other_than_allah,
    evidence(tier1, quranic('3:175')), action_guiding).

ctx_affect(w_claim_capacity, agent, hasad, creation_blessing,
    evidence(tier2, behavioral_profile(hasad)), raw_occurrence).

ctx_affect(w_claim_tier, agent, khawf, other_than_allah,
    evidence(tier4, commentary(fixture)), action_guiding).

ctx_affect(w_claim_unsupported, agent, raja, allah_rahmah,
    evidence(tier1, quranic('39:53')), oriented).

ctx_affect(w_subject_unresolved, stranger, test_scoped_affect, test_object,
    evidence(fixture, generated), action_guiding).

% Unknown membership with no claim: undetermined from observation alone.
ctx_affect(w_subject_unresolved_unclaimed, stranger, test_scoped_affect,
    test_object, evidence(fixture, generated), action_guiding).
