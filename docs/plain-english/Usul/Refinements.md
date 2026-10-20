# Usul.Refinements in Plain English

Source: [`formal/lean/Usul/Refinements.lean`](../../../formal/lean/Usul/Refinements.lean)

When a test case in the takhrīj suite exposes a missing input, the bank adds that input here, with a default that returns the old reading exactly. No earlier result changes, and the cases that needed the input can now be encoded faithfully. The file also holds the bank's readings of many of Ibn Rajab's qawāʿid (legal maxims), added in tranches.

## 1. The method

- **Takhrīj suite**: the corpus of furūʿ (particular cases) used to test readings. An M4 case that could not be encoded names a **gap** (e.g. `fact:confusion_category`).
- **Refinement**: a richer function with the missing input.
- **Conservative theorem** (`*_conservative`): with the new input at its default, the refinement equals the earlier reading.
- A refinement does not settle the related register question. It makes the alternatives expressible.

## 2. Lots, recourse, aṣl and ẓāhir

| Definition / Theorem | Plain English |
| --- | --- |
| `allocationFull entitledKnown divisible confused` | Adds `confused` to allocation: a confused but specific entitlement goes to lots (Ibn Rajab 160). |
| `allocationFull_conservative` | With no confusion, it is the old `allocation`. |
| `confused_goes_to_lot` | A confused specific entitlement goes to lots, even when divisible. |
| `recourseFull gift owedByOther permission` | Recourse for paying ⟺ not a gift, and he paid what another owed or spent by permission (Ibn Rajab 75). |
| `recourseFull_conservative` | For paying another's debt, it is al-Saʿdī's Q32 reading. |
| `no_recourse_unowed_unpermitted` | Neither owed by another nor permitted: no recourse. |
| `zahirPrevails asl zahir amara` | The ẓāhir (apparent) beats the aṣl (presumption) ⟺ it is strictly stronger, or equal and the matter has amārāt (indicators) (Ibn Rajab 159). |
| `zahirPrevails_conservative` | With indicators assumed, it is the kernel's `Qawaid.update`. |
| `tie_without_amara_keeps_asl` | Equal grades without indicators keep the aṣl. |
| `stronger_prevails` | A stronger ẓāhir wins with or without indicators. |

## 3. The unknown, the lowest, trust and abstention

| Definition / Theorem | Plain English |
| --- | --- |
| `treatedAsAbsent unknown despair hardship` | The unknown is treated as non-existent ⟺ it is unknown and one despairs of learning it or taking it into account is a hardship (Ibn Rajab 106). |
| `q20_is_instance` | Al-Saʿdī's Q20, an unidentifiable owner set aside for the public interest, is the despair case. |
| `knowable_not_set_aside` | What may still be learned without hardship is not set aside. |
| `hamlAlaAdna unspecified ranked` | An unspecified intention over ranked referents is read as the lowest (ḥaml ʿalā al-adnā). |
| `adna_is_certain` | Why: if covering a level covers all below it, the lowest is covered whichever was meant. It is the certain. |
| `trustVoided pure transgressed` | A pure trust (amāna maḥḍa) is voided by transgression; a compound one is not (Ibn Rajab 45). |
| `compound_trust_survives` | A compound trust survives transgression. |
| `liability_independent_of_voidance` | Liability for loss follows transgression either way; voidance concerns the contract only. |
| `recourseNec gift owedByOther permission unobtainable` | Adds that permission could not be sought: it counts as permission (Ibn Rajab 75.f006). |
| `recourseNec_conservative` | With permission obtainable, it is `recourseFull`. |
| `abstains suspended possible absenceKnown` | A husband abstains from his wife while the event a divorce was suspended on (taʿlīq) may have occurred and its absence is unknown. |
| `abstention_keeps_status` | The marriage itself stands: doubt does not remove certainty. Abstention governs conduct, not status. |
| `known_absence_ends_abstention` | Knowing the event did not occur ends the abstention. |

## 4. Ẓann and ʿilm

Ibn Taymiyya: knowing *that* a view preponderates is ʿilm (knowledge); the preponderance itself is ẓann (probable belief).

| Definition / Theorem | Plain English |
| --- | --- |
| `yaqinForAmal g rujhanKnown` | Certain enough to act ⟺ the grade is qaṭʿ (decisive), or a ẓann whose preponderance is known. |
| `yaqinForAmal_conservative`, `yaqinForAmal_iff` | It matches the kernel's `IsYaqin` and `Grade.YaqinFor`. |
| `unknown_rujhan_suspends` | A ẓann of unknown preponderance grounds nothing: tawaqquf (suspension). |
| `qat_suffices` | Qaṭʿ needs no second-order knowledge. |
| `Basis`, `basis yaqinAttainable ghalaba` | Build on certainty if attainable, else on preponderant belief (ghalabat al-ẓann), else on the aṣl (Ibn ʿUthaymīn's bayt 90). |
| `attainable_yaqin_excludes_ghalaba` | Where certainty is attainable, preponderant belief is not consulted. |
| `basis_is_first` | `basis` is the first-available rule over [yaqīn, ghalaba] with the aṣl as default. |
| `zannSetAside errorShownBy exempt` | An acted-on ẓann is set aside ⟺ its error is shown by something decisive and the domain is not exempt. |
| `ijtihad_not_overturned_by_ijtihad` | Another ijtihād (reasoned opinion) never overturns it. |
| `evident_error_sets_aside` | A decisively shown error sets it aside. |

## 5. Round 4: the open gaps' own texts

| Definition / Theorem | Plain English |
| --- | --- |
| `bootyTheftBurden`, `ghululForfeits` | A thief from the booty owes the theft once, plus his own share if it counts as ghulūl (misappropriation). |
| `ghulul_is_not_doubling` | This is not doubling: the added share can be less than, equal to, or more than the theft. |
| `heardAfterDenial forHimself` | After denying it, a right *for* oneself is not heard; one *against* oneself is. |
| `against_self_like_confession` | The second half rests on Q55: a confession after any denial binds. |
| `TieBreak`, `fayTieBreak`, `rulerMayLot` | Among equal fayʾ recipients, the first differing criterion decides; if none, the ruler chooses, and may cast lots. |
| `equal_on_all_criteria` | Equal on every criterion: the ruler chooses. |
| `LuqataOutcome`, `luqata yearPassed ownable` | Found property (luqaṭa): held during the year; then the finder owns it, or gives it in charity if it cannot be owned. |
| `luqata_is_instance` | Luqaṭa is an instance of the unknown treated as absent. |
| `Nusuk`, `validOnEvery`, `hajjValid`, `umraValid` | A forgotten iḥrām counts for what is valid under every possible form of pilgrimage. |
| `forgotten_ihram` | The ḥajj suffices; the ʿumra does not, since ifrād may have come first. |
| `second_view_by_treated_as_absent` | The other view: drop the unknown ifrād possibility, and the ʿumra suffices. |
| `jawazAfterSarf sarf`, `sarf_removes_jawaz` | Once a command's obligation is turned away (ṣarf), it no longer proves permissibility. |
| `amrPerItem`, `amrByTakhsis` | Two readings of a command over mixed items: each item by its own status, or obligation specified by the recommended items. |
| `mixed_readings_agree` | They give the same ruling on every item; they differ in meaning only. |

## 6. Ibn Rajab, M8 tranches 1–2 (qawāʿid 6, 7, 22, 27, 28, 64, 65, 68)

| Definition / Theorem | Plain English |
| --- | --- |
| `errorExcused othersRight negligent` | Q6: an act done on a belief later shown wrong stands, unless another's right is attached or he was negligent. |
| `q6_grounds_exemption` | Q6 explains `zannSetAside`'s exemption. |
| `istihlak`, `istihlak_iff` | Q22: what is consumed in another without trace is treated as non-existent. |
| `validUnderDoubt needsFirm ghalaba aslMustashab` | Q68: an act under doubt is valid ⟺ firmness is not needed, or there is preponderant belief, or a continuing aṣl. |
| `firm_by_basis`, `no_firmness_needed` | Firmness comes from ghalaba or an unbroken presumption; without the need, it is valid. |
| `mustSwitch`, `necessity_is_q28` | Q7: switch to the original when the substitute was a necessity, not a general concession; this is al-Saʿdī's Q28. |
| `liableForOthersBenefit` | Q27: destroying for another's benefit makes one liable; for one's own, not. |
| `Share`, `concurrentShare` | Q28: loss from two acts: full liability if the other act was permitted, half otherwise. |
| `countsAsMet knew liabilityOnly` | Q64–65: an unknown condition counts only if known, or if only liability is at stake. |
| `liability_not_by_belief`, `unknown_condition_does_not_count` | Belief alone does not create liability; an unknown condition otherwise fails. |

## 7. Tranche 3 and the third tranche (qawāʿid 1, 17, 31, 47, 66, 91, 93)

| Definition / Theorem | Plain English |
| --- | --- |
| `Body`, `runningBody` | Q1: running water is judged jirya (flow) by jirya; still water as one body. |
| `preferMany` | Q17: many acts beat one noble act when they cost the same. |
| `validWithBasis`, `q65_is_the_unbelieved_basis` | Q66: an act on a mistaken basis is valid if a true basis existed and he believed one; Q65 is the case without belief. |
| `handLiable` | Q91: the hand is liable for what is property, or shares in it. |
| `takerRecourse`, `undertaken_settles` | Q93: one who took from a usurper unaware has recourse unless he undertook the liability. |
| `MakeupFailure`, `MakeupExtent`, `makeupAfterFailure` | Q31: after corruption or faulty loss, make up as begun; after prevention or blameless loss, the baseline form. |
| `prevention_not_corruption`, `fault_changes_replacement` | Prevention differs from corruption; fault changes the replacement. |
| `CompensationBasis`, `defectiveCompensationBasis`, `defectiveCompensation` | Q47: contract liability uses the named price, loss liability the equivalent. |
| `defective_compensation_by_basis`, `defective_loss_ignores_named` | The amount follows the basis; for loss, the named price is irrelevant. |

## 8. Round 5 (gaps after tranches 1–3)

| Definition / Theorem | Plain English |
| --- | --- |
| `rulingUndone`, `own_ijtihad_does_not_undo`, `clear_text_undoes` | A judge's ruling against his own ijtihād stands; only a clear text undoes it. |
| `oathBody`, `oath_follows_custom` | Oaths are read by custom (al-Saʿdī Q9): custom may count a river as one body. |
| `Mixed`, `mixedOutcome` | Mixed goods: distinguishable stay separate; indistinguishable are shared with their own kind, consumed in another kind. |
| `other_kind_is_consumed`, `distinct_stays_separate` | The two edge cases. |
| `MixedHaram`, `mixedHaram` | Lawful money mixed with unlawful: suspend if the lawful is little; take out the unlawful part if much. |
| `rukhsaValid`, `rukhsa_is_firm_condition` | A rukhṣa (concession) needing certainty stands only when its permission is established; this is Q68's firm condition. |
| `conditionedSaleValid` | A sale suspended on a fact known to hold is valid. |
| `pardonOfSpreadValid`, `heirs_right_is_q65` | Pardoning qiṣāṣ before the injury spreads is valid if the right is the victim's; if it is the heirs', it is Q65's unknown condition. |

## 9. Tranches 4–6 (qawāʿid 2, 3, 9, 14, 15, 20–21, 24, 25, 29, 30, 32–35, 37–39, 41)

Each is a small yes/no or two-valued reading.

| Definition / Theorem | Plain English |
| --- | --- |
| `hairStatus` | Q2: hair and nails are as detached from the animal. |
| `growthKind`, `child_is_part` | Q20–21: growth from the substance is a part; the child is a part. |
| `rightSurvivesTransfer` | Q24: after a transfer, a right on the property survives; one on the owner lapses if its reason ceases. |
| `followsProven` | Q25: what follows in sale follows ownership proved by evidence or confession. |
| `Lapse`, `toleranceLapse` | Q29: exceeding a tolerated amount loses all tolerance if at fault, else only the excess. |
| `returnsToOwner` | Q30: what was given as due and did not count is still his. |
| `benefitExceptionValid`, `uncertainExceptionValid` | Q32–33: excepting a benefit is valid for a known period or where uncertainty is tolerated; an implicit exception tolerates uncertainty. |
| `manumissionReachesBenefits`, `binding_is_implicit_exception` | Q34: manumission does not reach benefits owed under a binding contract; Q34 is Q33 applied. |
| `wholeObligatory` | Q3: the whole is obligatory only when the excess is inseparable and the whole was the original duty. |
| `ProhibitionSite`, `worshipValidDespite`, `q9_refines_q38` | Q9: worship is invalid unless the prohibition is external; it agrees with al-Saʿdī's Q38 on every site. |
| `oneOfTwoAttaches`, `consequenceCarries` | Q14–15: a cause from one of two attaches when they are taken together; a presumption does not carry consequences into another aṣl. |
| `priorContractDissolves` | Q35: owning the thing dissolves a perpetual commutative contract (nikāḥ), not a lease. |
| `laterContractGoverns`, `laterBindingGoverns` | Q37: the later contract governs; refined so it governs only if it binds or the earlier did not. |
| `binding_pledge_survives` and two conservative theorems | A binding pledge is not turned into a loan by a non-binding permission. |
| `asKinayaValid`, `kinayaConcludes`, `witnessed_needs_explicit` | Q38–39: words read by meaning; allusions conclude contracts except those needing witnesses (nikāḥ). |
| `rightPassesToSubstitute`, `substitute_as_transfer` | Q41: a bound right passes to the destroyed thing's substitute, as with transfer. |

## 10. Tranches 7–9 (qawāʿid 3–5, 9–12, 14, 15, 19, 36, 42, 43, 46, 49–52, 54–59, 61, 62)

- **Timing and form of worship**: `excessObligatory` (Q3), `advancedSuffices` (Q5), `validDespite` (Q9), `otherTongueValid` (Q10), `combineForms` (Q12), `advanceAllowed` (Q4), `naflValid` with `zakat_carve_out` (Q11), `settlesInDhimma` (Q19).
- **Doubt between two**: `Attach`, `attachTo` (Q14) binds both where harmless, else each abstains; `eachOnItsAsl` (Q15).
- **Contracts and possession**: `leaseDissolves` (Q36), `returnAtOnce` (Q42), `holderLiable` and `liableAfterEnding` (Q43), `voidConcluded` (Q46), `bindsWithoutQabd` (Q49), `ownedBeforePayment` (Q50), `inNewOwnersDaman` (Q51), `disposeBeforeQabd` (Q52), `mayDisposeOver` (Q54), `disposalTakes` (Q55), `conditionMet` (Q56), `holdsAgainstBar` (Q57), `desistIsAct` (Q58), `annulsNonexistent` (Q59).
- **Deputies**: `removedWithPrincipal` (Q61), `removedBeforeKnowledge` (Q62).

Each is one line of logic, with its Arabic ground quoted in the Lean comment. For example, `disposeBeforeQabd mubham settled` is true ⟺ the thing is determined and the disposer's right is settled.

## 11. Reconciliation refinements

Each adds a farq (distinguishing feature) cited by later works, from `corpus/reconciliation/ledger.json`. Each has a conservative theorem back to the earlier reading.

| Definition | Plain English |
| --- | --- |
| `useSubstituteAt` | Q16: a substitute fixed at the time of obligation stands even if the original is found later (kaffārāt). `settled_substitute_stands`. |
| `countsAsMetIn` | Q64–65: in transactions, authority that existed in fact suffices. `authority_in_fact_suffices`. |
| `excessObligatoryIn` | Q3: following the imām makes his extra rukūʿ count. |
| `advancedSufficesIn` | Q5: an advanced kaffāra by fasting fails if he is well off when the oath breaks. |
| `otherTongueValidIn` | Q10: no need to learn Arabic for acts not themselves due (nikāḥ, liʿān). |
| `ownedBeforePaymentIn` | Q50: the shafīʿ (pre-emptor) owns on demand if solvent. Also `ownedBeforePaymentIn_insolvent`. |
| `disposeBeforeQabdIn` | Q52: a debt may not be sold to anyone but the debtor. |
| `removedWithPrincipalIn` | Q61: the qāḍī's deputies fall with him even under a general mandate. |
| `annulsNonexistentIn` | Q59: a defective thing that perished cannot be returned; the arsh is fixed. |

## In one line

Every gap a test case exposes is closed by adding the missing fact with a default that changes nothing, and dozens of Ibn Rajab's maxims are read as small yes/no rules tied back to al-Saʿdī and to the kernel.
