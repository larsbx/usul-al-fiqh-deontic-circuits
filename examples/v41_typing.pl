:- encoding(utf8).
% =========================================================================
%  v4.1 typing — the type system's executable mirror
%
%  The type system is Lean (formal/lean/Usul/Typing.lean): the qawāʿid
%  define the types, a situation is their join, and an encoder is typed by
%  the fields its projection reads. v41_types.pl is generated from the Lean
%  kernel's declarations (formal/lean/scripts/ExportTypes.lean); these rules
%  run the typing judgement on situations stated as sit(Situation, Field, Value).
%
%    applies(E, S)          S settles every field E reads: S inhabits E's type
%    missing_fact(E, S, F)  E reads F and S leaves it open
%    route(S, E)            the encoders a situation is routed to
%    shares(F, E1, E2)      two encoders read one field (one qāʿida's notion)
%    field_of(T, F)         F belongs to qāʿida type T, through `extends`
%    ill_typed(E, F)        E reads a field no qāʿida type declares
%    unrelated_shared_field(F, T1, T2)  two types declare F though neither
%                           extends the other: a silent identification (Lean
%                           merges same-named parent fields)
% =========================================================================

:- ensure_loaded(v41_types).
:- discontiguous(sit/3).
:- dynamic(sit/3).

reads(E, F) :- encoder_reads(E, _, F).
typed_field(F) :- type_field(_, F, _).

field_of(T, F) :- type_field(T, F, _).
field_of(T, F) :- type_extends(T, P), field_of(P, F).

situation(S) :- setof(S0, F^V^sit(S0, F, V), Ss), member(S, Ss).
known(S, F) :- sit(S, F, _).

applies(E, S) :-
    encoder_type(E, _), situation(S),
    forall(reads(E, F), known(S, F)).
missing_fact(E, S, F) :-
    situation(S), reads(E, F), \+ known(S, F).
route(S, E) :- applies(E, S).

shares(F, E1, E2) :- reads(E1, F), reads(E2, F), E1 @< E2.

ill_typed(E, F) :- reads(E, F), \+ typed_field(F).

type_below(T, T).
type_below(T, A) :- type_extends(T, P), type_below(P, A).
related(T1, T2) :- type_below(T1, T2) ; type_below(T2, T1).
unrelated_shared_field(F, T1, T2) :-
    type_field(T1, F, _), type_field(T2, F, _), T1 @< T2, \+ related(T1, T2).
