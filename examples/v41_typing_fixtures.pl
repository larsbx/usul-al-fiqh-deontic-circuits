:- encoding(utf8).
% =========================================================================
%  v4.1 typing — fixtures
%
%    swipl tests/run_fixture_expectations.pl -- examples/v41_typing_fixtures.pl
%
%  The theorems of Usul.Typing, restated over the exported types and run by
%  the typing rules. Lean proves them for the kernel; these pin the mirror.
% =========================================================================

:- ensure_loaded(v41_typing).

:- multifile([sit/3, encoder_reads/3, type_field/3, fixture_expectation/3, fixture_premise/2]).
:- discontiguous([sit/3, encoder_reads/3, type_field/3, fixture_expectation/3, fixture_premise/2]).

% A trustee who did not transgress but was negligent in safekeeping, in a
% matter touching another's right; nothing said of inquiry.
sit(s_trustee, hand, trustee).
sit(s_trustee, transgressed, false).
sit(s_trustee, negligent, true).
sit(s_trustee, others_right, false).

% Only the purpose of a destruction is known.
sit(s_purpose, purpose, benefit).

% Every exported encoder reads only fields some qāʿida type declares; a
% reader of an undeclared field (fx_untyped, not an exported encoder) is caught.
encoder_reads(fx_untyped, 1, no_such_field).
fixture_expectation(well_typed, query(\+ (encoder_type(E, _), ill_typed(E, _))), expect_true).
fixture_expectation(ill_typed_caught, query(ill_typed(fx_untyped, no_such_field)), expect_true).

% transgression_is_shared: Q14 types both trust encoders.
fixture_expectation(q14_shared_transgression,
    query(shares(transgressed, trust_loss, trust_voidance)), expect_true).

% original_possibility_is_shared: Q28 types both substitute encoders.
fixture_expectation(q28_shared_original,
    query(shares(original_possible, substitute, substitute_at_obligation)), expect_true).

% negligence_is_qualified: Q14's «يفرط» is not Ibn Rajab Q6's «فرط بترك البحث».
fixture_expectation(negligence_routes_trust_loss,
    query(route(s_trustee, trust_loss)), expect_true).
fixture_expectation(negligence_does_not_settle_inquiry,
    query(applies(excused_error, s_trustee)), expect_false).
fixture_premise(negligence_does_not_settle_inquiry, query(sit(s_trustee, negligent, true))).
fixture_expectation(inquiry_is_the_missing_fact,
    query(missing_fact(excused_error, s_trustee, negligent_inquiry)), expect_true).
fixture_expectation(negligence_fields_not_shared,
    query(shares(negligent, excused_error, trust_loss)), expect_false).
fixture_premise(negligence_fields_not_shared, query(reads(trust_loss, negligent))).

% itlaf_reads_two_qawaid: the purpose alone (Q36) leaves Q13's fact missing.
fixture_expectation(itlaf_needs_q13,
    query(applies(itlaf, s_purpose)), expect_false).
fixture_premise(itlaf_needs_q13, query(sit(s_purpose, purpose, benefit))).
fixture_expectation(itlaf_missing_mental,
    query(missing_fact(itlaf, s_purpose, mental)), expect_true).

% Types that extend their qāʿida's carry its fields.
fixture_expectation(luqata_extends_majhul, query(field_of(luqata, unknown)), expect_true).
fixture_expectation(rukhsa_reaches_yaqin, query(field_of(rukhsa, asl)), expect_true).
fixture_expectation(amana_is_not_yaqin, query(field_of(amana, asl)), expect_false).
fixture_premise(amana_is_not_yaqin, query(qaida_type(amana, _))).

% A field the situation settles is never reported missing.
fixture_expectation(known_field_not_missing,
    query(missing_fact(trust_loss, s_trustee, hand)), expect_false).
fixture_premise(known_field_not_missing, query(sit(s_trustee, hand, trustee))).

% No field is shared by two qāʿida types unless one extends the other: an
% identification across qawāʿid is a decision, never a name collision. The
% planted pair (fx_left, fx_right) shows the rule catches one.
type_field(fx_left, fx_field, 'Option Bool').
type_field(fx_right, fx_field, 'Option Bool').
fixture_expectation(no_silent_identification,
    query(\+ (unrelated_shared_field(_, T1, T2), \+ sub_atom(T1, 0, _, _, fx_), \+ sub_atom(T2, 0, _, _, fx_))), expect_true).
fixture_expectation(silent_identification_caught,
    query(unrelated_shared_field(fx_field, fx_left, fx_right)), expect_true).

% Relations (Usul.Typing.Relations), as the Lean theorems state them.
sit(s_luqata, year_passed, true).
sit(s_luqata, unknown, true).
sit(s_luqata, hardship, false).
fixture_expectation(year_settles_despair, query(holds(s_luqata, despair, true)), expect_true).
fixture_expectation(luqata_routes_to_majhul, query(route(s_luqata, unknown_as_nonexistent)), expect_true).

sit(s_hoped, year_passed, true).
sit(s_hoped, despair, false).
fixture_expectation(stated_fact_kept, query(holds(s_hoped, despair, true)), expect_false).
fixture_premise(stated_fact_kept, query(sit(s_hoped, despair, false))).

sit(s_within_year, year_passed, false).
fixture_expectation(premise_required, query(holds(s_within_year, despair, true)), expect_false).
fixture_premise(premise_required, query(sit(s_within_year, year_passed, false))).

sit(s_consumed, consumed, true).
fixture_expectation(consumed_is_unidentified, query(holds(s_consumed, owner_identifiable, false)), expect_true).

sit(s_rukhsa, rukhsa_needs_certainty, true).
fixture_expectation(rukhsa_settles_firmness, query(holds(s_rukhsa, needs_firm, true)), expect_true).

% The shards' look-alikes: 95's negligence is 6's, both ways.
sit(s_q95, negligent_q95, true).
fixture_expectation(q95_negligence_is_inquiry, query(holds(s_q95, negligent_inquiry, true)), expect_true).
sit(s_q6, negligent_inquiry, false).
fixture_expectation(q6_diligence_is_q95, query(holds(s_q6, negligent_q95, false)), expect_true).

% 97's despair is 106's; its known owner leaves 106's unknown open.
sit(s_q97, owner_known, true).
sit(s_q97, despaired, true).
fixture_expectation(q97_despair_is_106, query(holds(s_q97, despair, true)), expect_true).
fixture_expectation(q97_known_owner_not_majhul, query(holds(s_q97, unknown, _)), expect_false).

% 97's unknown owner, despaired of, chains through 98 and 106 to Q20.
sit(s_q97_unknown, owner_known, false).
sit(s_q97_unknown, despaired, true).
fixture_expectation(q97_unknown_owner_is_unidentified, query(holds(s_q97_unknown, owner_identifiable, false)), expect_true).

% 98's unknown owner is 106's unknown, never the converse.
sit(s_q98, owner_unknown, true).
fixture_expectation(q98_owner_is_106_unknown, query(holds(s_q98, unknown, true)), expect_true).
fixture_expectation(q106_unknown_not_q98, query(holds(s_luqata, owner_unknown, _)), expect_false).

% Identified: doubt_in_condition's ghalaba is the ẓāhir reaching ẓann.
sit(s_doubt, needs_firm, true).
sit(s_doubt, zahir, zann).
sit(s_doubt, asl_mustashab, false).
fixture_expectation(ghalaba_is_zahir, query(applies(doubt_in_condition, s_doubt)), expect_true).

% Coverage ranks a partly typed situation: s_purpose settles one of itlaf's two fields.
fixture_expectation(coverage_counts_known_fields, query(coverage(itlaf, s_purpose, 1, 2)), expect_true).
