:- encoding(utf8).
% =========================================================================
%  Oracle: an independent Prolog model of the tanāquḍ pairs (Usul.Tanaqud).
%
%  For each pair of al-Saʿdī's qawāʿid: the first and the second read without
%  their qayd, and the qayd in his own words (corpus/tanaqud/sadi.json; T-11
%  onward Ibn Rajab's, corpus/tanaqud/rajab.json). The
%  jamʿ is the first on the qayd's side and the second elsewhere. Cases are
%  lists of JSON scalars as the register writes them. Outputs are bound after
%  the choice, so a bound caller never selects a clause.
% =========================================================================

:- module(tanaqud_oracle, [reading/4, qayd/2, jam/3]).

% Laid out pair by pair, as the register is.
:- discontiguous first/3, second/3, qayd/2.

% reading(+Pair, +Side, +Case, -Value)
reading(P, first, C, V) :- first(P, C, V0), V = V0.
reading(P, second, C, V) :- second(P, C, V0), V = V0.

% jam(+Pair, +Case, -Value)
jam(P, C, V) :- ( qayd(P, C) -> first(P, C, V0) ; second(P, C, V0) ), V = V0.

% T-01 Q13 ⟂ Q27: destruction (liable?), case [Right, MentalState].
% «الحق في قتل الصيد للمحرم لله، والإثم مترتب على القصد، فكذلك الجزاء»
first(1, [_, _], true).                                     % Q13: whatever the state
second(1, [_, M], V) :- ( M == deliberate -> V = true ; V = false ).   % Q27: the excused discharged
qayd(1, [R, _]) :- R == adami.

% T-02 Q20 ⟂ Q25: an unknown entitled, case [KnownClaimants]. «فمتى تشاح اثنان فأكثر»
first(2, [_], lot).
second(2, [_], publicInterest).
qayd(2, [K]) :- K == true.

% T-03 Q31 ⟂ Q41: performances owed for two acts, case [SamePurpose]. «إذا كان مقصودهما واحد»
first(3, [_], 1).
second(3, [_], 2).
qayd(3, [S]) :- S == true.

% T-04 Q55 ⟂ Q57: bound by the literal words?, case [AnotherDemands].
% «إذا طالبه بمقتضى لفظه لم يكن لنا أن نحكم إلا بالظاهر»
first(4, [_], true).
second(4, [_], false).
qayd(4, [D]) :- D == true.

% T-05 Q17 ⟂ Q39: does the early act stand?, case [AfterCause]. «قبل وجود أسبابها الصحيحة»
first(5, [_], true).
second(5, [_], false).
qayd(5, [A]) :- A == true.

% T-06 Q4 ⟂ Q40: is the part obligatory?, case [CanDoPart, PureMeans].
% «وجب عليه فعل ما قدر عليه، إلا أن يكون المقدور عليه وسيلة محضة»
first(6, [_, Pure], V) :- ( Pure == true -> V = false ; V = true ).
second(6, [_, _], false).
qayd(6, [Can, _]) :- Can == true.

% T-07 Q21 ⟂ Q50: is the sale forbidden?, case [FollowsAKnownWhole]. «لكن إذا بيعت الدار …»
first(7, [_], false).
second(7, [_], true).
qayd(7, [F]) :- F == true.

% T-08 Q11 ⟂ Q52: does the presumption stand?, case [GradeOfTheIndicator].
% «إنما قدمنا الأصل حيث لا مرجح سواه»: what is stronger than doubt displaces it.
first(8, [_], false).
second(8, [_], true).
qayd(8, [G]) :- grade_rank(G, R), grade_rank(shakk, S), R > S.

grade_rank(wahm, 0).
grade_rank(shakk, 1).
grade_rank(zann, 2).
grade_rank(qat, 3).

% T-09 Q12 ⟂ Q45: is the other party's consent required?, case [ConcludesAnExchange].
first(9, [_], true).
second(9, [_], false).
qayd(9, [E]) :- E == true.

% T-10 Q10 ⟂ Q26: what must the holder bring?, case [HeldInTrust]. «لأن صاحبه ائتمنه ونزله منزلة نفسه»
first(10, [_], yamin).
second(10, [_], bayyina).
qayd(10, [T]) :- T == true.

% T-11 Ibn Rajab 66 ⟂ 6: does the act on a mistaken belief stand?, case [BasisExists, OthersRight, Negligent].
% «ثم تبين خطؤه فيه وأن السبب المعتمد غيره وهو موجود»
first(11, [B, _, _], V) :- ( B == true -> V = true ; V = false ).
second(11, [_, O, N], V) :- ( O == false, N == false -> V = true ; V = false ).
qayd(11, [B, _, _]) :- B == true.

% T-12 al-Saʿdī Q28 ⟂ Ibn Rajab 7: must he switch to the original now found?, case [Necessity].
% «الضرب الثاني: أن يكون المتلبس به إنما شرع ضرورة للعجز عن الأصل وتعذره»
first(12, [_], true).
second(12, [_], false).
qayd(12, [N]) :- N == true.

% T-13 Ibn Rajab 32 ⟂ 33: is the excepted benefit of unknown period valid?, case [Implicit, Tolerates].
% «لأن جهالة المدة هنا لا تؤثر»
first(13, [_, T], V) :- ( T == true -> V = true ; V = false ).
second(13, [I, _], V) :- ( I == true -> V = true ; V = false ).
qayd(13, [_, T]) :- T == true.

% T-14 Ibn Rajab 1 ⟂ al-Saʿdī Q9: how is running water reckoned?, case [InAnOath]. «والأيمان مرجعها إلى العرف»
first(14, [_], perJirya).
second(14, [_], whole).
qayd(14, [O]) :- O == false.

% T-15 Ibn Rajab 14 ⟂ 15: does the breach certain in one of two attach?, case [Together].
% «فينظر إليهما مجتمعين في حكم يتعلق باجتماعهما»
first(15, [_], true).
second(15, [_], false).
qayd(15, [T]) :- T == true.
