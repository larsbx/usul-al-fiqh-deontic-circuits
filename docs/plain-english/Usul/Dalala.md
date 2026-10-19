# Usul.Dalala in Plain English

Source: [`formal/lean/Usul/Dalala.lean`](../../../formal/lean/Usul/Dalala.lean)

The standard rules for drawing rulings from texts (dalāla, signification) become small formal schemata. Each is a defeasible default or a policy, not a fixed law: generality yields to a known referent, the specific governs its own scope, a command obligates unless an indication says otherwise, and contrary implication yields to its blockers.

## 1. Generality with ʿahd

- **ʿĀmm**: a general expression. **ʿAhd**: "al-" pointing to a known referent. **Taʿyīn**: a proper name fixing the referent.
- **`IsGeneralIn`**: al-Saʿdī's Q59/Q60 test of generality, blocked when ʿahd or taʿyīn is present (Ibn al-Laḥḥām 52).

| Theorem | Plain English |
| --- | --- |
| `isGeneralIn_no_ahd` | Without ʿahd, the test is exactly al-Saʿdī's. The refinement is conservative. |
| `ahd_blocks` | With ʿahd, the expression is not general. |
| `isGeneralIn_is_gate` | It is a gate: the generality marker is the condition, ʿahd the impediment. |

## 2. Takhṣīṣ: the specific governs its scope

- **`Takhsis`**: a general rule and a specific one inside it, each with its ruling.
- **`Takhsis.ruling`**: the specific ruling where it applies, otherwise the general.

| Theorem | Plain English |
| --- | --- |
| `takhsis_specific_governs` | Inside the specific scope, the specific ruling holds. |
| `takhsis_not_naskh` | Outside it, the general still holds. Specification (takhṣīṣ) is not abrogation (naskh). |

## 3. Muṭlaq and muqayyad

- **Muṭlaq / muqayyad**: an unrestricted expression and a restricted one.
- **`carryRestriction`**: read the unrestricted as restricted when both share the ruling and the cause. With the same ruling but a different cause, it depends on a policy (two reports from Aḥmad). With different rulings, never.

| Theorem | Plain English |
| --- | --- |
| `carry_same_hukm_same_sabab` | Same ruling and same cause: always carry. |
| `no_carry_different_hukm` | Different rulings: never carry. |
| `carry_narrows` | Carrying only narrows the scope (Q29). |

## 4. Command and prohibition as defaults

- **`amrStatus`**: a command (amr) obligates (wājib) unless an indication (qarīna) gives another ruling.
- **`nahyStatus`**: a prohibition (nahy) forbids (ḥarām) unless an indication says otherwise.

| Theorem | Plain English |
| --- | --- |
| `amr_default`, `amr_defeasible` | No indication ⇒ wājib. An indication decides when present. |
| `nahy_default_is_sigma` | The prohibition's default is the mirror (σ) of the command's. |

## 5. A command forbids the opposite

- **`RespectsDidd`**: a ruling assignment gives each act's opposite (ḍidd) the mirror ruling σ.

| Theorem | Plain English |
| --- | --- |
| `amr_nahy_didd_of` | Under that assumption, if an act is wājib its opposite is ḥarām. |
| `nahy_amr_didd_of` | And if an act is ḥarām its opposite is wājib. |

## 6. Contrary implication (mafhūm al-mukhālafa)

- **`Blocker`**: none, the usual case, an answer to a question, or emphasis.
- **`mafhum`**: inside the stated condition, the ruling holds. Outside it, the ruling fails, unless a blocker suspends the implication; then nothing follows.

| Theorem | Plain English |
| --- | --- |
| `mafhum_contrary` | No blocker, outside the condition ⇒ the ruling does not hold. |
| `mafhum_blocked` | With a blocker, outside the condition ⇒ no conclusion. |

## 7. Tarjīḥ as a preference

- **`Prefers rank a b`**: b is preferred to a, by the strength of its proof.

| Theorem | Plain English |
| --- | --- |
| `prefers_irrefl`, `prefers_trans`, `prefers_asymm` | Preference is a strict partial order. |
| `prefers_wf` | It is well-founded: no endless chain of ever-weaker proofs. |

## 8. Wording over occasion

- **`coversBeyondSabab`**: whether a general wording on a specific occasion covers other cases. It always covers its own occasion. Beyond it, it depends on the policy "the generality of the wording, not the specificity of the occasion" (Ibn al-Laḥḥām 61).
- **`occasion_always_covered`**: the occasion itself is always covered.

## In one line

The textual rules of uṣūl become small defaults and policies: generality, specification, restriction, command, prohibition and contrary implication each hold until a named indication or blocker says otherwise.
