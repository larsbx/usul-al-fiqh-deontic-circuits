:- encoding(utf8).
% =========================================================================
%  v4.0 fatwā oracle — rules
%
%  A rule-based oracle over the IslamQA takhrīj cases (corpus/fatawa).
%
%    bank(Case, Value)            the Lean bank's encoder, mirrored: what
%                                 Usul computes from the case's encoder facts
%                                 (encoder_fact/3, the tranche's annotation)
%    oracle(Case, Ruling, Rule)   the first applicable rule of the case's
%                                 domain, the bank's rule last
%    agrees(Case)                 the oracle's ruling is the text's
%
%  Each rule names the source that states it (rule_source/2). Specific rules
%  come before the general one (takhṣīṣ before ʿumūm). This is a test
%  harness for readings, not a fiqh authority. Cases are generated into
%  v40_fatwa_cases.pl: encoder/2, encoder_fact/3 (the encoder's inputs),
%  fact/3 (those extended by the text's other facts) and text_ruling/2.
% =========================================================================

:- discontiguous(rule/4).

% -------------------------------------------------------------------------
% The bank, mirrored (formal/lean/Usul; the Python mirrors in takhrij.py)
% -------------------------------------------------------------------------

grade_rank(wahm, 0).
grade_rank(shakk, 1).
grade_rank(zann, 2).
grade_rank(qat, 3).

itlaf_liable(benefit, true).
itlaf_liable(repelHarm, false).

% Muamalat.lossLiable
bank(C, true) :-
    encoder(C, trust_loss),
    (   encoder_fact(C, hand, wrongdoer) ; encoder_fact(C, transgressed, true) ; encoder_fact(C, negligent, true) ), !.
bank(C, false) :-
    encoder(C, trust_loss), encoder_fact(C, hand, _), !.
% Muamalat.itlafLiable (withRight purpose) mental
bank(C, V) :-
    encoder(C, itlaf), encoder_fact(C, purpose, P), itlaf_liable(P, V), !.
% Refinements.zahirPrevails: a < z ∨ (a = z ∧ amara)
bank(C, Prevails) :-
    encoder(C, asl_zahir),
    encoder_fact(C, asl_grade, A), encoder_fact(C, zahir_grade, Z), encoder_fact(C, amara, Amara),
    grade_rank(A, RA), grade_rank(Z, RZ), !,
    (   RA < RZ -> Prevails = true
    ;   RA =:= RZ, Amara == true -> Prevails = true
    ;   Prevails = false ).
% Refinements.luqata
bank(C, R) :-
    encoder(C, luqata), encoder_fact(C, year_passed, Y), encoder_fact(C, ownable, O), !,
    (   Y == false -> R = hold ; O == true -> R = finderOwns ; R = charity ).
% Muamalat.recipient
bank(C, R) :-
    encoder(C, unknown_owner), encoder_fact(C, owner_identifiable, I), !,
    (   I == true -> R = owner ; R = publicInterest ).

% -------------------------------------------------------------------------
% Domains
% -------------------------------------------------------------------------

domain(C, liability) :- encoder(C, E), memberchk(E, [trust_loss, itlaf]).
domain(C, doubt) :- encoder(C, asl_zahir).
domain(C, found_property) :- encoder(C, luqata).
domain(C, unknown_owner) :- encoder(C, unknown_owner).

oracle(C, Ruling, Rule) :-
    domain(C, D),
    once(rule(D, Rule, C, Ruling)).

% Rulings the texts use interchangeably: never owned, kept for the owner.
same_ruling(R, R).
same_ruling(hold, handToAuthority).
same_ruling(handToAuthority, hold).

agrees(C) :-
    oracle(C, R, _), text_ruling(C, T), same_ruling(R, T).

% -------------------------------------------------------------------------
% Liability (ḍamān): trust_loss and itlaf cases
% -------------------------------------------------------------------------

rule(liability, no_legal_value, C, false) :-
    fact(C, has_legal_value, false).
rule(liability, lawful_authority, C, false) :-
    fact(C, lawful_authority_act, true).
rule(liability, sirayat_al_jinaya, C, Death) :-
    fact(C, death_from_injury, Death).
rule(liability, unattributed_death, C, false) :-
    fact(C, later_death, true),
    \+ fact(C, death_from_injury, _).
rule(liability, itlaf_bi_haqq, C, V) :-
    fact(C, purpose, P),
    itlaf_liable(P, V).
rule(liability, physician, C, Fault) :-
    fact(C, physician, true),
    fact(C, permitted, true),
    fact(C, fault, Fault).
rule(liability, guarantee_by_contract, C, true) :-
    fact(C, hand, guarantor_by_contract).
rule(liability, hand_of_trust, C, Liable) :-
    fact(C, hand, Hand), Hand \== guarantor_by_contract,
    fact(C, transgressed, T), fact(C, negligent, N),
    (   ( Hand == wrongdoer ; T == true ; N == true ) -> Liable = true ; Liable = false ).
rule(liability, quwwa_qahira, C, false) :-
    fact(C, unavoidable, true),
    \+ fact(C, fault, true).
rule(liability, victim_fault, C, false) :-
    fact(C, victim_fault, true),
    fact(C, fault, false).
rule(liability, mubashir_liable, C, true) :-
    fact(C, causation, direct).
rule(liability, mubashir_first, C, false) :-
    fact(C, causation, indirect),
    fact(C, other_direct_actor, true).
rule(liability, mutasabbib_by_fault, C, Fault) :-
    fact(C, causation, indirect),
    fact(C, fault, Fault).
rule(liability, no_causation, C, false) :-
    fact(C, causation, none).
rule(liability, bank, C, V) :-
    bank(C, V).

% -------------------------------------------------------------------------
% Doubt: the presumption (aṣl) and the indicator (ẓāhir)
% -------------------------------------------------------------------------

rule(doubt, sufra_kudra_after_tuhr, C, false) :-
    fact(C, discharge_after_purity, true).
rule(doubt, bayyina_in_qada, C, false) :-
    fact(C, forum, qada),
    \+ fact(C, bayyina, true).
rule(doubt, bank, C, V) :-
    bank(C, V).

% -------------------------------------------------------------------------
% Found property (luqaṭa)
% -------------------------------------------------------------------------

rule(found_property, rikaz, C, rikazFifth) :-
    fact(C, buried_treasure, true),
    \+ fact(C, muslim_buried, true).
rule(found_property, trivial_find, C, keepNow) :-
    fact(C, trivial, true).
rule(found_property, haram_makka, C, hold) :-
    fact(C, location, makka_haram).
rule(found_property, dallat_al_ibil, C, leave) :-
    (   fact(C, animal, self_preserving) ; fact(C, self_keeping, true) ).
rule(found_property, perishable_find, C, hold) :-
    fact(C, perishable, true).
rule(found_property, dallat_al_ghanam, C, R) :-
    fact(C, animal, vulnerable),
    (   fact(C, year_passed, true) -> R = finderOwns ; R = hold ).
rule(found_property, announced_year, C, R) :-
    fact(C, year_passed, Y),
    (   Y == true -> R = finderOwns ; R = hold ).
rule(found_property, bank, C, V) :-
    bank(C, V).

% -------------------------------------------------------------------------
% Property of an unknown owner
% -------------------------------------------------------------------------

rule(unknown_owner, illicit_exchange, C, publicInterest) :-
    fact(C, illicit_exchange, true).
rule(unknown_owner, owner_appears_after_charity, C, ownerChooses) :-
    fact(C, owner_later_appears, true).
rule(unknown_owner, family_recipient, C, familyAllowed) :-
    fact(C, owner_identifiable, false),
    fact(C, recipient_is_own_family, true).
rule(unknown_owner, recipient, C, R) :-
    fact(C, owner_identifiable, I),
    (   I == true -> R = owner ; R = publicInterest ).
rule(unknown_owner, bank, C, V) :-
    bank(C, V).

% -------------------------------------------------------------------------
% Sources
% -------------------------------------------------------------------------

rule_source(bank, 'formal/lean/Usul: the encoder the case was annotated under').
rule_source(no_legal_value, 'ما لا قيمة له شرعًا لا يُضمن: sorcery books, islamqa.152192').
rule_source(lawful_authority, 'a lawful confiscation or destruction by the authority (taʿzīr bi\'l-māl), islamqa.140833').
rule_source(sirayat_al_jinaya, 'sirāyat al-jināya: a later death follows the injury that caused it').
rule_source(unattributed_death, 'al-aṣl barāʾat al-dhimma: a later death is not his until it is attributed to the injury, islamqa.348122').
rule_source(itlaf_bi_haqq, 'Ibn Rajab, qāʿida 26: destroying to repel the thing\'s own harm is not compensable, for one\'s own benefit it is; before «المباشر ضامن»').
rule_source(physician, '«من تطبب ولا يُعلم منه طب فهو ضامن»: the qualified, permitted physician is liable only for fault').
rule_source(guarantee_by_contract, 'a loan is a hand of guarantee by contract: a current account, islamqa.252463').
rule_source(hand_of_trust, 'Saʿdī 14: a trustee is liable only by transgression or negligence; a wrongdoer always').
rule_source(quwwa_qahira, 'Majmaʿ al-Fiqh al-Islāmī on traffic accidents (a): an unavoidable force exempts the driver, islamqa.345284').
rule_source(victim_fault, 'Majmaʿ al-Fiqh al-Islāmī on traffic accidents (b): the harm came from the injured party\'s own act').
rule_source(mubashir_liable, '«المباشر ضامن وإن لم يتعد»: direct destruction is liable without fault').
rule_source(mubashir_first, '«إذا اجتمع المباشر والمتسبب يضاف الحكم إلى المباشر» (Majalla 90)').
rule_source(mutasabbib_by_fault, '«المتسبب لا يضمن إلا بالتعدي»: indirect causation is liable only by fault').
rule_source(no_causation, 'no causal part in the harm').
rule_source(sufra_kudra_after_tuhr, 'Umm ʿAṭiyya: «كنا لا نعد الصفرة والكدرة بعد الطهر شيئا»').
rule_source(bayyina_in_qada, '«البينة على المدعي واليمين على من أنكر»: before a judge the presumption stands without evidence, islamqa.198294').
rule_source(rikaz, '«وفي الركاز الخمس»: pre-Islamic buried treasure is the finder\'s, a fifth is due; treasure with a Muslim mark is a find').
rule_source(haram_makka, '«ولا تحل ساقطتها إلا لمنشد»: a find in the Ḥaram of Makka is never owned').
rule_source(dallat_al_ibil, '«ما لك ولها، معها سقاؤها وحذاؤها»: a stray camel is left, and by qiyās what keeps itself, islamqa.5049').
rule_source(perishable_find, 'a perishable find is eaten owing its value or sold and its price kept for the owner, islamqa.5049').
rule_source(trivial_find, 'what people do not seek may be kept without announcement').
rule_source(dallat_al_ghanam, '«هي لك أو لأخيك أو للذئب»: a stray sheep may be taken, and is held for the owner until the year ends, islamqa.10284').
rule_source(announced_year, '«عرفها سنة… فإن لم تعرف فاستنفقها»: owned after a year of announcement').
rule_source(illicit_exchange, 'Ibn Taymiyya, Ibn al-Qayyim: the payer of a forbidden exchange who got what he paid for does not get it back').
rule_source(owner_appears_after_charity, 'the owner who appears after the charity chooses to ratify it or be compensated').
rule_source(family_recipient, 'charity for an unknown owner may go to one\'s own poor relatives whose maintenance one does not owe, islamqa.196584').
rule_source(recipient, 'Saʿdī 20: to the owner when identifiable, otherwise to the public interest').
