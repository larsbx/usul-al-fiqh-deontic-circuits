# Usul.Jadal in Plain English

Source: [`formal/lean/Usul/Jadal.lean`](../../../formal/lean/Usul/Jadal.lean)

The uṣūl works say that all objections to qiyās (analogy) "reduce to manʿ or muʿāraḍa": denial or counter-evidence. Here that claim is a theorem. A qiyās passes a gate built from the objections exactly when no objection succeeds, and then its conclusion is sound. The file also covers the kinds of qiyās and preference (tarjīḥ) between ʿilal (ratios).

## 1. The debate

- **`Policy`**: the disputed positions an objection presupposes, left as parameters. May a naqḍ be answered by specification (takhṣīṣ)? May a ruling have several ʿilal? Is kasr (breaking the purpose) admitted?
- **`Debate`**: an analogy argument (aṣl = source case, farʿ = new case, ʿilla, ruling, known cases) plus everything an objector can speak to. This includes the ruling claimed and the ruling in dispute, how the ʿilla was established, its purpose (ḥikma), rival features, other senses of the term, and any counter-ruling.
- **`Qadih`**: the eighteen objections (qawādiḥ), from istifsār (asking for clarification) to inḍibāṭ (the ʿilla is not a fixed criterion).
- **`Qadih.kind`**: each objection is either **manʿ** (denies something the qiyās needs) or **muʿāraḍa** (brings a competing source). Eight are muʿāraḍa: fasād al-iʿtibār, fasād al-waḍʿ, naqḍ, qalb, ʿadam al-taʾthīr, muʿāraḍa, farq, kasr. The rest are manʿ. The file notes this split is its own reading; the sources do not tabulate it.
- **`Qadih.succeeds`**: when each objection wins. Examples:
  - **manʿ**: the ʿilla is absent from the aṣl or the farʿ.
  - **muṭālaba**: no method (maslak) has shown the feature is the ʿilla.
  - **al-qawl bi'l-mūjab**: the claimed ruling is not the disputed one.
  - **fasād al-iʿtibār**: a text already rules on the farʿ.
  - **farq**: a rival feature of the aṣl is absent from the farʿ.
  - **qalb**: the same ʿilla and aṣl yield a different ruling; **muʿāraḍa**: a different source yields one.

## 2. The objections are the gate

- **`debateGate`**: a gate whose conditions are "this manʿ objection fails" and whose impediments are "this muʿāraḍa objection succeeds".

| Theorem | Plain English |
| --- | --- |
| `Qadih.mem_all` | The list of objections is complete. |
| `debateGate_holds_iff` | The gate holds ⟺ no objection succeeds. |
| `objection_blocks` | Any one successful objection blocks the qiyās. |
| `kind_spec` | A manʿ objection is literally a negated gate condition; a muʿāraḍa objection is literally a gate impediment. |
| `debateGate_sound` | **Soundness.** If the gate holds, every ruling that fits the known cases and depends only on the ʿilla gives the farʿ the claimed ruling. |
| `counter_resolved_by_tarjih` | Competing analogies are a conflict (taʿāruḍ). Sent to the general resolver, with no reconciliation or abrogation available, preference decides. |

## 3. Kinds of qiyās

| Theorem | Plain English |
| --- | --- |
| `qiyas_aks` | **Qiyās al-ʿaks.** If the ruling turns exactly with the feature, a farʿ lacking the feature gets the contrary ruling. |
| `dalala_verifies` | **Qiyās al-dalāla.** An indicator that implies the ʿilla, found in the farʿ, verifies the ʿilla there. |
| `qiyas_awla` | **Qiyās al-awlā.** If the ruling rises with a graded ʿilla, a farʿ with more of it has the ruling a fortiori. |
| `qiyas_musawi` | **Qiyās al-musāwī.** Equal degree gives the same ruling. |

- **`farByOrder`**: rule the farʿ by text first, then qiyās al-ʿilla, then shabah (resemblance) if admitted, else suspend (tawaqquf).

| Theorem | Plain English |
| --- | --- |
| `shabah_never_overrides_illa` | When qiyās al-ʿilla gives an answer, shabah is never used. |
| `shabah_only_as_fallback` | Shabah decides only when nothing earlier does. |
| `shabah_rejected` | If shabah is not admitted and nothing else answers, the result is suspension. |

## 4. Preference between ʿilal

- **`Maslak`**: how an ʿilla was established: ijmāʿ, naṣṣ, īmāʾ, sabr (probing), munāsaba (suitability), shabah, dawarān (co-variation), ṭard.
- **`RespectsSources`**: the source constraints on any ranking. Munāsaba < sabr, shabah < munāsaba, naṣṣ < ijmāʿ, sabr < naṣṣ.
- **`exampleRank`**: one concrete ranking (ijmāʿ 7 down to ṭard 0).
- **`preferred`**: pick a candidate ʿilla of highest rank.

| Theorem | Plain English |
| --- | --- |
| `exampleRank_respects` | The example ranking meets every constraint, so the constraints are consistent. |
| `preferred_optimal` | Whatever `preferred` picks has no higher-ranked rival. |
| `sabr_beats_shabah` | Under any admissible ranking, an ʿilla by sabr beats one by shabah. |

## In one line

Every objection to qiyās is either a missing condition or a present impediment, so "no objection succeeds" is exactly the gate under which the analogy's conclusion is guaranteed.
