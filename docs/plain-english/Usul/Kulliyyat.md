# Usul.Kulliyyat in Plain English

Source: [`formal/lean/Usul/Kulliyyat.lean`](../../../formal/lean/Usul/Kulliyyat.lean)

Eleven of al-Saʿdī's general maxims (kulliyyāt) get small formal models of custom, intent, speech, time and worship. Each is also proved an instance of a shared pattern from `Usul.Schema` (a priority fallback, a gate, a closure, an optimum), which fixes what must carry over when the maxim is applied outside its original chapter (bāb). Every reading is a candidate until reviewed.

## 1. Q5: the two foundations of worship

- **`Worship`**: an act of worship, sincere (ikhlāṣ) or not, following the Messenger or not.
- **`Worship.gate`**: a gate with both as conditions and no impediments.

| Theorem | Plain English |
| --- | --- |
| `q05_both_foundations` | Worship passes ⟺ it is both sincere and follows the Messenger. |

## 2. Q9: custom decides where the law sets no measure

- **`measure`**: the law's measure if it defines one, else custom's (ʿurf).

| Theorem | Plain English |
| --- | --- |
| `q09_law_prevails` | A measure set by the law wins. |
| `q09_custom_decides` | Where the law is silent, custom decides. |
| `q09_follows_custom` | Where the law is silent, a change in custom changes the ruling. |
| `q09_is_priority` | Q9 is the priority pattern: the law's measure, falling back to custom. |

## 3. Q15: no harm and no reciprocal harm

- **`mayInflict`**: outside prescribed retaliation, harm may be inflicted only if it is zero, whatever harm was received.

| Theorem | Plain English |
| --- | --- |
| `q15_no_harm` | Inflicting is allowed ⟺ the harm is zero (*lā ḍarar*). |
| `q15_no_reciprocal_harm`, `q15_ignores_received` | The harm received makes no difference (*wa-lā ḍirār*). |

## 4. Q17: hastening a thing before its time deprives one of it

- **`obtains`**: one gets a thing only if entitled and did not unlawfully hasten it. Examples: the heir who kills his legator; marrying during the waiting period (ʿidda).

| Theorem | Plain English |
| --- | --- |
| `q17_hastening_deprives` | Whoever hastens gets nothing. |
| `q17_never_beyond_entitlement` | No one obtains what they were not entitled to. |
| `q17_is_gate` | Q17 is a gate: entitlement the condition, hastening the impediment. |

## 5. Q29: an utterance is qualified by its attachments

- **`Utterance`**: a base meaning narrowed by qualifiers (a description, condition, exception).
- **`meaning`**: x falls under it ⟺ the base and every qualifier hold of x.

| Theorem | Plain English |
| --- | --- |
| `q29_unqualified` | With no qualifiers, the meaning is the base. |
| `q29_qualifiers_narrow` | Whatever the qualified utterance covers, the base covers. |
| `q29_is_gate` | An utterance is a gate of its base and qualifiers. |
| `q29_attach_narrows` | Attaching one more qualifier can only narrow the meaning. |

## 6. Q31: each cause operates in its own effect

- **`rulings`**: a ruling holds when some present cause produces it.

| Theorem | Plain English |
| --- | --- |
| `q31_each_cause_its_effect` | A ruling holds ⟺ some present cause has it as effect. |
| `q31_absent_cause_inert` | An absent cause removes only its own effects. |
| `q31_join` | Rulings from two groups of causes are the union of each group's rulings. |
| `q31_monotone` | More causes present never yields fewer rulings. |

## 7. Q34: choice for oneself vs for another

- **`ChoiceFor`**: self or other.
- **`Admissible`**: the pick is one of the options; if choosing for another, nothing serves their interest better.

| Theorem | Plain English |
| --- | --- |
| `q34_other_stricter` | Any pick admissible for another is admissible for oneself. |
| `q34_best_admissible` | The best option (from Q33's `best`) always discharges a guardian's choice. |
| `q34_other_iff_optimal` | Choosing for another ⟺ choosing an optimal option. |

## 8. Q39: not before the cause, but possibly before the condition

- **`timelyPerformance t cause cond`**: valid ⟺ the cause (sabab) has occurred by time t. The condition's time is ignored. Example: a kaffāra (expiation) may follow the oath and precede its breaking.

| Theorem | Plain English |
| --- | --- |
| `q39_not_before_cause` | Performing before the cause is invalid. |
| `q39_before_condition_after_cause` | After the cause but before the condition is valid. |
| `q39_ignores_condition` | The condition's time does not matter. |
| `q39_shift_invariant` | Shifting the whole calendar changes nothing. |

## 9. Q41: like acts of worship merge

- **`Act`**: an owed act with kind, purpose and occasion (e.g. two janābas, two missed prayers of one name).
- **`discharges`**: a performance discharges an owed act of the same kind and purpose, whatever the occasion.
- **`Merges`**: the same relation, used as an equivalence.

| Theorem | Plain English |
| --- | --- |
| `q41_one_performance` | One performance discharges every owed act of its kind and purpose. |
| `q41_distinct_purposes_stay_apart` | Different purposes never merge. |
| `q41_merges_refl`, `q41_merges_symm`, `q41_merges_trans` | Merging is an equivalence. |
| `q41_representatives` | One performance per class covers everything owed, and never needs more performances than owed acts. |

## 10. Q48: parts of one act join when customarily continuous

- **`continuous g ts`**: each consecutive gap between the parts' times is at most the customary gap g.

| Theorem | Plain English |
| --- | --- |
| `q48_custom_monotone` | A more lenient custom never breaks continuity a stricter one accepted. |
| `q48_shift_invariant` | Shifting every part by the same time preserves continuity. |

## 11. Q50: what cannot stand alone may stand as a dependent

- **`established`**: proved independently, or following something established.
- **`Established`**: the closure of the independently proved under "follows".

| Theorem | Plain English |
| --- | --- |
| `q50_dependent_suffices`, `q50_independent_suffices`, `q50_neither_fails` | Either route suffices; with neither, nothing is established. |
| `q50_follower_established` | What follows something established is established. |
| `q50_least` | Nothing is established from nothing: any property of all proved things that passes along "follows" holds of everything established. |

## 12. Q57: words are read by their speakers' intent where possible

- **`reading`**: the intended sense if known and possible; otherwise the literal sense.

| Theorem | Plain English |
| --- | --- |
| `q57_possible_intent_prevails` | A possible intent wins. |
| `q57_impossible_intent_falls_back` | An impossible intent falls back to the literal. |
| `q57_unknown_intent_literal` | Unknown intent gives the literal. |
| `q57_is_priority` | Q57 is the priority pattern: intent if possible, else literal. |

## In one line

Each maxim becomes a small exact rule, and each rule is shown to be a case of a shared pattern, so its structure survives when it is carried to new chapters.
