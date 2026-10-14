:- encoding(utf8).
% =========================================================================
%  Oracle: an independent Prolog model of al-Saʿdī's grades of the furūq
%  (Usul.Furuq), from the aṣl of his part two: «الشارع لا يفرق بين المتشابهات
%  من كل وجه، بل لا بد فيها من فوارق معنوية».
%
%    sahih    the fuqahāʾ rule them apart, and a meaning separates them: apart
%    daif     they rule them apart, but nothing meaningful does: alike
%    jamDaif  they rule them alike, but a naṣṣ or a meaning separates them: apart
%    reported he reports their farq without grading it: as they rule, apart
%
%  The register applied to itself: a later item may overturn an earlier one on a
%  shared case only when the earlier is a bare report (not his own ruling) and
%  the later is his own, ruling the other way.
% =========================================================================

:- module(furuq_oracle, [rulings/3, overturn_ok/2]).

% rulings(+Grade, -Madhhab, -Author)
rulings(G, M, A) :- grade(G, M0, A0), M = M0, A = A0.

grade(sahih,   apart, apart).
grade(daif,    apart, alike).
grade(jamDaif, alike, apart).
grade(reported, apart, apart).

% his(+Grade): the ruling is his own, not a bare report.
his(G) :- G \== reported, grade(G, _, _).

% overturn_ok(+ParentGrade, +ChildGrade)
overturn_ok(P, C) :-
    \+ his(P), his(C),
    grade(P, _, AP), grade(C, _, AC), AP \== AC.
