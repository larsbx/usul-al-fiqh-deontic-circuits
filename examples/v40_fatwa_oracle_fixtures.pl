:- encoding(utf8).
% =========================================================================
%  v4.0 fatwā oracle — fixtures
%
%    swipl tests/run_fixture_expectations.pl -- examples/v40_fatwa_oracle_fixtures.pl
%
%  Loads the rules and the generated cases. Each case carries its own
%  vectors (bank/1 against the Python/Lean kernel, agrees/1 against the
%  text); the hand-written vectors below pin rule precedence.
% =========================================================================

:- ensure_loaded(v40_fatwa_rules).
:- ensure_loaded(v40_fatwa_cases).

:- multifile([encoder/2, fact/3, fixture_expectation/3]).
:- discontiguous([encoder/2, fact/3, fixture_expectation/3]).

% -------------------------------------------------------------------------
% Precedence: each pair differs only in the fact the specific rule reads,
% so the vector fails if the rule is removed and the general one answers.
% -------------------------------------------------------------------------

% A lawful destruction by the authority: not liable though direct.
encoder(fx_lawful_authority, itlaf).
fact(fx_lawful_authority, causation, direct).
fact(fx_lawful_authority, lawful_authority_act, true).
fixture_expectation(precedence(lawful_authority),
    query(oracle(fx_lawful_authority, false, lawful_authority)), expect_true).

% A qualified, permitted physician without fault: not liable though direct.
encoder(fx_physician, itlaf).
fact(fx_physician, causation, direct).
fact(fx_physician, physician, true).
fact(fx_physician, permitted, true).
fact(fx_physician, fault, false).
fixture_expectation(precedence(physician),
    query(oracle(fx_physician, false, physician)), expect_true).

% A year announced, no encoder facts for the bank: the finder owns it.
encoder(fx_announced_year, luqata).
fact(fx_announced_year, year_passed, true).
fixture_expectation(precedence(announced_year),
    query(oracle(fx_announced_year, finderOwns, announced_year)), expect_true).

% An identifiable owner, no encoder facts for the bank: return it.
encoder(fx_recipient, unknown_owner).
fact(fx_recipient, owner_identifiable, true).
fixture_expectation(precedence(recipient),
    query(oracle(fx_recipient, owner, recipient)), expect_true).
