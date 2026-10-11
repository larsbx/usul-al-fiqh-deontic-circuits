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

:- multifile([sit/3, encoder_reads/3, fixture_expectation/3, fixture_premise/2]).
:- discontiguous([sit/3, encoder_reads/3, fixture_expectation/3, fixture_premise/2]).

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
