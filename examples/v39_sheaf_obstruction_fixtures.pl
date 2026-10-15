:- encoding(utf8).
% =========================================================================
%  v3.9 sketch — separated finite sheaf obstruction fixtures
%
%
%  This compatibility aggregator keeps the original fixture path stable while
%  the implementation is split into three concerns:
%
%    - v39_affect_concern.pl     affect facts, anti-pairs, affect observations
%    - v39_temporal_concern.pl   worlds, context conditions, path realizations
%    - v39_claim_concern.pl      proposed sections checked by the kernel
%    - v39_sheaf_concern.pl      local sections, gluing, obstructions, tests
%
%  This is not a fiqh authority. It is a harness for testing whether local
%  contextual sections glue cleanly or emit structured obstruction reasons.
% =========================================================================

:- ensure_loaded(v39_affect_concern).
:- ensure_loaded(v39_temporal_concern).
:- ensure_loaded(v39_claim_concern).
:- ensure_loaded(v39_sheaf_concern).

% -------------------------------------------------------------------------
% Smoke queries
% -------------------------------------------------------------------------

% ?- path_gluable(w_allah_fear, path_allah_fear_ok).
% ?- path_obstruction(w_other_fear_defect, path_other_fear_defect, Reason).
% ?- path_obstruction(w_rahmah_balance, path_qunut_without_raja, Reason).
% ?- path_obstruction(w_yusuf_brothers, path_yusuf_brothers, Reason).
% ?- path_gluable(w_involuntary_panic, path_panic_only).
% ?- world_obstruction(w_fixture_conflict, Reason).
% ?- claim_obstruction(World, Agent, Claim, Category, Detail).
