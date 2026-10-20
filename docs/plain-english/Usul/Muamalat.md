# Usul.Muamalat in Plain English

Source: [`formal/lean/Usul/Muamalat.lean`](../../../formal/lean/Usul/Muamalat.lean)

Al-Saʿdī's transaction rules (muʿāmalāt) become a small model of possession, liability and contract. Each rule is a total function over its cases, with a theorem per branch; where rules touch, a theorem shows they agree. Each is also proved an instance of a shared pattern in `Usul.Schema`, so its structure carries to other chapters. Every reading is a candidate until reviewed.

## 1. Proof and claims: Q10, Q26/Q43, Q37, Q55

- **Q10**: proof (bayyina) on the claimant, oath (yamīn) on the denier. The claimant says the defendant's liability (dhimma) is occupied; the denier says it is free.
- **Q26/Q43**: a trustee's word is accepted unless sense or custom belies it. On *returning* the thing, only if he held it for the owner's benefit.
- **Q37**: when contracting parties disagree, the stronger evidence prevails.
- **Q55**: one who confessed has no excuse, even if he later claims error.

| Theorem | Plain English |
| --- | --- |
| `q10_burden_injective` | The two parties never bear the same burden. |
| `q10_from_presumption` | The burdens follow from the presumption of free liability (barāʾat al-dhimma): whoever departs from it must prove. |
| `q43_self_interest_not_believed` | One who held the thing for his own benefit is not believed on its return. |
| `q26_q43_consistent` | Q43 refines Q26: an accepted return claim is always an accepted word. |
| `q26_q43_from_presumption` | The trustee takes the oath exactly when his claim matches the presumption; contradiction by sense or custom displaces it. |
| `q37_strongest_prevails`, `q37_is_optimal` | The prevailing claim has evidence at least as strong as every other. |
| `q55_error_claim_irrelevant` | A confession binds whatever error is claimed. |
| `q55_confession_absorbs` | After a confession, no later plea (claiming error, retracting) unbinds him. |

## 2. Consent and validity: Q12, Q51, Q54

- **Q12**: an exchange needs both parties' consent.
- **Q51**: the motives of contracts count. A valid form with an unlawful motive is invalid.
- **Q54**: in transactions the actual facts count, not belief.
- **`Deal.gate`**: Q12 combined with Q51.

| Theorem | Plain English |
| --- | --- |
| `q12_no_contract_without_consent` | Missing either consent blocks the exchange. |
| `q12_mutual_consent_suffices` | Both consents let it through. |
| `q51_form_insufficient` | Valid form with an unlawful motive fails. |
| `q51_valid_iff` | Valid ⟺ valid form and lawful motive. |
| `q54_belief_irrelevant`, `q54_ignores_belief` | Validity depends on actual entitlement, not what one believed. |
| `q51_q54_consistent` | Q51 and Q54 agree: motive counts, belief about entitlement does not. |
| `deal_holds_iff` | A deal passes ⟺ both consent and the motive is lawful. |

## 3. Destruction and loss: Q13/Q36, Q14

- **`MentalState`**: deliberate, ignorant, forgetful.
- **Q13**: destruction (itlāf) without right is compensable, whatever the mental state.
- **Q36**: destroying to benefit makes one liable; destroying to repel the thing's own harm does not.
- **Q14**: loss in a trustee's hand needs transgression or negligence for liability; in a wrongdoer's hand liability is absolute.
- **`authorizedHold`**: a trustee without fault holds with authorisation; a wrongdoer never does.

| Theorem | Plain English |
| --- | --- |
| `q13_intent_irrelevant`, `q13_ignores_intent` | Liability for destruction ignores the mental state. |
| `q36_benefit_liable`, `q36_repel_not_liable` | Destroying for benefit: liable. Repelling harm: not liable. |
| `q13_q36_consistent` | Liable ⟺ the purpose was benefit. Q13's strict liability covers only destruction without right. |
| `q13_q36_factor_through_right` | Liability depends only on whether there was a right. |
| `q14_trustee_without_fault`, `q14_wrongdoer_always`, `q14_fault_makes_trustee_liable` | The three branches of Q14. |
| `q14_liable_iff_unauthorized`, `q13_liable_iff_unauthorized` | Q13 and Q14 share one shape: liability = absence of authorisation. |
| `q14_factors_through_authorization` | Liability for loss depends only on authorisation. |

## 4. Compensation and price: Q18/Q19, Q35, Q44

- **Q18**: fungible goods are compensated by their like; others by value.
- **Q19**: if the named price (al-musammā) cannot be had, revert to value.
- **Q35**: whoever escapes punishment for a reason owes doubled compensation.
- **Q44**: whoever performs what is due earns what was set for him.

| Theorem | Plain English |
| --- | --- |
| `q18_partition` | Compensation in kind ⟺ the good is fungible. |
| `q19_stipulated_binds`, `q19_unattainable_reverts_to_value`, `q19_is_priority` | The named price if any, else value. |
| `q35_doubled`, `q35_never_less` | Doubled when punishment lapsed, never less than value. |
| `q44_performance_earns` | Performance earns the full wage. |

## 5. Who gets what: Q20, Q24, Q25, Q30, Q32, Q46

- **Q20**: an unidentifiable owner is treated as non-existent; the thing goes to the public interest.
- **Q24**: whoever reaches an unowned permissible thing first has the better right.
- **Q25**: lots (qurʿa) when the entitled is unknown and division is impossible.
- **Q30**: a refusing co-owner is compelled to what the common holding necessarily requires.
- **Q32**: paying another's obligation gives recourse, unless it was a gift.
- **Q46**: a creditor with an evident cause may take his due from a refusing debtor's property, up to the amount; with a hidden cause he may not.

| Theorem | Plain English |
| --- | --- |
| `q20_unknown_owner`, `q20_is_priority` | Owner if identifiable, else public interest. |
| `q24_first_has_priority`, `q24_is_optimal` | The chosen claimant came no later than any other. |
| `q25_lot_iff`, `q25_lot_is_last_resort` | Give to the known entitled, else divide, else cast lots. Lots ⟺ neither known nor divisible. |
| `q30_necessity_compels`, `q30_otherwise_by_consent` | Necessity compels; otherwise only by consent. |
| `q32_recourse_for_paid`, `q32_gift_no_recourse`, `q32_never_more_than_paid`, `q32_is_gate` | Recourse for what was paid, none for a gift, never more than paid. |
| `q46_hidden_cause_forbids`, `q46_never_more_than_due` | Hidden cause forbids taking; never more than the claim. |

## 6. Contract form and dependence: Q21, Q42, Q45, Q53

- **Q21**: uncertainty (gharar) and gambling are forbidden in exchanges and contests, not in gifts.
- **Q42**: a reserved usufruct must be known in exchanges; in gifts it may be unknown.
- **Q45**: whose consent is not required, his knowledge is not required either.
- **Q53**: if a contract proves fāsid (defective), what was built on it is bāṭil (void). A voluntary rescission leaves dependent contracts standing.

| Theorem | Plain English |
| --- | --- |
| `q21_forbidden_iff`, `q21_is_gate` | Forbidden ⟺ gharar is present and the contract is not a gift. |
| `q42_instance_of_q21` | Q42 is Q21 applied to the reserved usufruct. |
| `q45_normalize_coherent`, `q45_normalize_fixes_coherent`, `q45_normalize_idem` | Dropping an unsupported knowledge requirement makes any requirement coherent, leaves coherent ones alone, and is stable when repeated. |
| `q53_distinction` | Proved voidness and rescission differ for dependents. |
| `q53_void_propagates` | What is built on a void contract is void. |
| `q53_rescission_inert` | Rescinding a contract voids nothing. |

## 7. Obligation, wealth and inheritance: Q47, Q49, Q56

- **Q47**: what a vow (nadhr) makes obligatory is treated as what the law makes obligatory.
- **Q49**: basic needs are not surplus wealth.
- **Q56**: the heir stands in the deceased's place in all of the estate. The well-known (mashhūr) view in the madhhab excepts the option of condition (khiyār al-sharṭ) and an unclaimed pre-emption right (shufʿa). Al-Saʿdī calls that exception very weak. Both readings are kept as a parameter.

| Theorem | Plain English |
| --- | --- |
| `q47_vow_as_law`, `q47_ignores_source` | A vowed obligation has the same status as a legal one. |
| `q47_consequences` | So every consequence of that status (making up, expiation) is the same. |
| `q49_needs_excluded` | Surplus plus the needs portion makes up the whole. |
| `q56_heir_in_everything` | On al-Saʿdī's reading, the heir inherits every right. |
| `q56_mashhur_exceptions` | On the mashhūr, exactly the two excepted rights are not inherited. |
| `q56_readings_differ_iff` | The readings differ exactly on those two rights. |

## In one line

Each transaction rule is a total case split with a theorem per branch, interacting rules are proved consistent, and the deep shapes (presumption, priority, gate, optimum, closure) are shared across them.
