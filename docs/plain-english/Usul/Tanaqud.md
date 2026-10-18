# Usul.Tanaqud in Plain English

Source: [`formal/lean/Usul/Tanaqud.lean`](../../../formal/lean/Usul/Tanaqud.lean)

Pairs of maxims (qawāʿid) that seem to contradict each other are reconciled by the author's own qualifying sentence (qayd). Read without the qayd, each pair rules opposite ways on some case. With it, each rule governs its own side, so every pair reaches jamʿ (reconciliation), the first stage of resolution, and none needs tawaqquf (suspension).

## 1. The general machinery

- **`Pair`**: two rules read without their qayd, plus the qayd itself, which sorts each case to the first or second rule.
- **`Pair.jam`**: the reconciliation: apply the first rule where the qayd says so, the second elsewhere.
- **`Pair.Clash`**: the bare readings disagree on at least one case.

| Theorem | Plain English |
| --- | --- |
| `Pair.jam_first`, `Pair.jam_second` | On each side of the qayd, the reconciliation equals that side's rule. |
| `resolve_takes_jam` | Once a reconciliation exists, the bank's resolution order takes it before naskh, tarjīḥ or tawaqquf. |

For each pair, the file proves three things: the clash is real, the qayd gives one ruling, and that ruling matches the rule's existing encoding. The qayd sentences are quoted and located in `corpus/review/sadi_tanaqud.json` and `corpus/tanaqud/rajab.json`. Earlier pairs (Q13/Q36, Q26/Q43, Q51/Q54) are proved in `Usul.Muamalat`.

## 2. Pairs within al-Saʿdī (T1–T10)

| Pair | Clash | The qayd's split |
| --- | --- | --- |
| `t1` · Q13 ⟂ Q27 | A muḥrim (pilgrim in iḥrām) forgetfully kills game: compensate always (Q13), or excused by forgetfulness (Q27)? | A human's right follows Q13; God's right follows Q27. `t1_jam`: liable ⟺ a human's right, or the act was deliberate. |
| `t2` · Q20 ⟂ Q25 | Unknown entitled party, indivisible thing: public interest (Q20) or casting lots (Q25)? | Known competing claimants → lots; no one identifiable → public interest. |
| `t3` · Q31 ⟂ Q41 | Two kaffārāt (expiations) owed: one each (Q31) or merged (Q41)? | One performance ⟺ they share a purpose (Q41's own `discharges`). |
| `t4` · Q55 ⟂ Q57 | A confessor says he meant otherwise: bound by words (Q55) or by intent (Q57)? | Bound by words ⟺ another's right is attached and he demands it. |
| `t5` · Q17 ⟂ Q39 | Acting early: forfeited (Q17) or allowed (Q39)? | After the cause, Q39; before it, Q17 (`timelyPerformance`). |
| `t6` · Q4 ⟂ Q40 | Unable to do the whole: nothing owed (Q4) or the doable part owed (Q40)? | Inability lifts what it reaches, part by part, except a mere means. `t6_obligedParts` ties this to Q40's `obligedParts`. |
| `t7` · Q21 ⟂ Q50 | The unseen foundations of a sold house: forbidden gharar (uncertainty, Q21) or allowed as a follower (Q50)? | Forbidden unless the uncertain item follows a known whole. |
| `t8` · Q11 ⟂ Q52 | The presumption against an indicator: keep it (Q11) or yield (Q52)? | It holds against doubt and yields to anything stronger than doubt (`Refinements.zahirPrevails`). |
| `t9` · Q12 ⟂ Q45 | Is the other party's consent needed? | Concluding an exchange needs it (Q12's gate); a unilateral right such as cancellation, divorce or pre-emption does not. |
| `t10` · Q10 ⟂ Q26 | A trustee claims the thing perished: proof on the claimant (Q10), or his word accepted (Q26)? | Held in trust for the owner, his claim is the presumption, so an oath suffices (`Schema.burdenOf`). |

## 3. Pairs from Ibn Rajab (T11–T15)

These carry the method to Ibn Rajab's *Taqrīr al-Qawāʿid*: three pairs inside his book, two across to al-Saʿdī.

| Pair | Clash | The qayd's split |
| --- | --- | --- |
| `t11` · Rajab 66 ⟂ Rajab 6 | An act done on a mistaken belief. | It stands if a valid basis exists in fact (Q66), or else if Q6 excuses the error. |
| `t12` · Saʿdī Q28 ⟂ Rajab 7 | The original is found while using the substitute: switch or not? | Switch only if the substitute was taken from necessity (`Refinements.mustSwitch`); a general concession stands. |
| `t13` · Rajab 32 ⟂ Rajab 33 | A waqf (endowment) excepting its benefit for the founder's lifetime: an exception of unknown length. | Valid where the transfer already bears that uncertainty, or where the law itself makes the exception. |
| `t14` · Rajab 1 ⟂ Saʿdī Q9 | An oath not to stand in running water: each flow (jirya) separately, or the river as one body by custom? | Oaths follow custom (Q9); ṭahāra (purity) follows the flow-by-flow reckoning. |
| `t15` · Rajab 14 ⟂ Rajab 15 | Two people find al-manī in a shared garment: does the certain breach attach? | Taken together in one ruling, Q14 attaches it (`Refinements.oneOfTwoAttaches`); each alone keeps his purity (Q15). |

Each pair `tN` has a `tN_clash` theorem with a concrete disagreeing case, and a `tN_jam` theorem stating the reconciled ruling (T9 has `t9_exchange_side` instead).

## 4. A pair that does not clash

- **`rajab_q93_q75_consistent`**: Ibn Rajab Q93 gives one who took from a usurper unknowingly recourse against him, "unless he entered on liability for it". Q75 gives recourse for paying what another owed. What he entered on liability for was his own due, so Q75 gives no recourse there either. The two agree.

## In one line

Every apparent contradiction among these maxims dissolves under the author's own qualifying sentence, so the bank's own resolution order settles each pair at the first stage, reconciliation.
