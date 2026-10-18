# Usul.Qiyas in Plain English

Source: [`formal/lean/Usul/Qiyas.lean`](../../../formal/lean/Usul/Qiyas.lean)

Qiyās (analogy) is sound when the ruling depends only on the ʿilla (ratio): a new case (farʿ) sharing it with the source case (aṣl) shares the ruling. The file formalises how an ʿilla is established (masālik) and why each classical objection (qawādiḥ) defeats an inference. It then proves the whole qiyās is a gate that licenses the farʿ's ruling. Where the Ḥanbalī madhhab is divided, the position is a parameter, never a choice made here.

## 1. Basic vocabulary

- **`Wasf`**: a description (waṣf), a yes/no feature of cases.
- **`Known`**: cases whose ruling is given by text (naṣṣ) or consensus (ijmāʿ).
- **`Agrees H known`**: ruling H matches every given case.
- **`Factors H w`**: H depends only on w. Cases alike in w get the same ruling.

## 2. Establishing the ʿilla: ṭard and dawarān

- **`tard`**: wherever the feature appears among given cases, the ruling appears.
- **`aks`**: wherever the feature is absent, the ruling is absent.
- **`dawaran`** (co-variation): both together.

| Theorem | Plain English |
| --- | --- |
| `tard_iff`, `aks_iff`, `dawaran_iff` | The Boolean checks mean what they say. Dawarān ⟺ on every given case, feature present ⟺ ruling present. |
| `tard_vacuous` | Ṭard alone is weak: a feature found in no case passes it trivially. |
| `dawaran_not_unique` | Dawarān is only presumptive (ẓannī). Two features can both co-vary with the ruling on all given cases yet disagree on a new one. |

## 3. Establishing the ʿilla: probing, suitability, resemblance

- **`survivors`**: al-sabr wa'l-taqsīm (probing and division). Keep the candidates a refutation test does not eliminate.
- **`refutedByNaqd`**: the usual test: a counter-case eliminates a candidate.
- **`Munasib`**: munāsaba (suitability). Every case the feature marks carries more benefit than harm.
- **`Recognition`**: how far the law recognises a suitable feature: muʾaththir, mulāʾim, gharīb, mursal (neither recognised nor cancelled), mulghā (cancelled). Whether mursal is accepted is a parameter.
- **`resemblance`**, **`shabahAsl`**: qiyās al-shabah. Attach the farʿ to the aṣl it shares most features with.
- **`TahqiqManat`**: verifying the ʿilla in the farʿ (taḥqīq al-manāṭ).

| Theorem | Plain English |
| --- | --- |
| `sabr_sound` | If the true ʿilla is among the candidates and is not refuted, a sole survivor is the ʿilla. |
| `sabr_needs_hasr` | Without an exhaustive list (ḥaṣr), the sole survivor need not be the ʿilla. |
| `munasaba_of_q01` | Under al-Saʿdī's Q1 (commands carry preponderant benefit), any feature on whose cases the law demands the act is suitable. |
| `mulgha_never_accepted` | A cancelled feature is never accepted. |
| `shabah_optimal` | The chosen aṣl resembles the farʿ at least as much as any other. |
| `tanqih_manat` | Tanqīḥ al-manāṭ: if a ruling stated on two features ignores one, it depends on the other alone. |

## 4. The objections

| Theorem | Plain English |
| --- | --- |
| `underdetermined` | If a feature separates farʿ from aṣl, two rulings can depend on it, agree on the aṣl, and differ on the farʿ. |
| `man_defeats` | **Manʿ.** If the ʿilla differs between farʿ and aṣl, the aṣl does not fix the farʿ. |
| `farq_defeats` | **Farq.** A second feature present in the aṣl but absent in the farʿ leaves the farʿ open, unless it is shown irrelevant. |
| `naqd_iff_not_tard` | **Naqḍ** (a given case with the feature and a different ruling) ⟺ ṭard fails. |
| `naqd_defeats` | Naqḍ is decisive: no ruling that fits the given cases and depends only on the feature gives the aṣl its ruling. |
| `takhsis_repairs` | **Takhṣīṣ al-ʿilla.** If an impediment explains every counter-case, the ʿilla restricted by its absence has no naqḍ. |
| `naqd_succeeds_without_takhsis` | If takhṣīṣ is refused for this source of ʿilla (`IllaSource`: text-stated or inferred), every naqḍ succeeds. |
| `naqd_answered_by_takhsis` | If takhṣīṣ is admitted, a naqḍ fully explained by the impediment fails. |
| `naqd_gives_kasr` | **Kasr** is naqḍ against the purpose (ḥikma). A naqḍ of a feature yields a kasr of any purpose it stands for. |
| `kasr_without_naqd` | The converse fails: kasr can hold without naqḍ. |
| `adamTathir_iff_not_aks` | **ʿAdam al-taʾthīr** (the ruling found without the feature) ⟺ ʿaks fails. |
| `dawaran_answers_adamTathir` | Dawarān rules out ʿadam al-taʾthīr. With several ʿilal admitted, `AdamTathirSucceeds` needs a case no other ʿilla covers. |
| `qalb_defeats` | **Qalb.** If the same ʿilla from the same aṣl gives an incompatible ruling, it cannot ground both. |
| `qawlBiMujab_defeats` | **Al-qawl bi'l-mūjab.** Conceding what was proved, while it does not reach the disputed point, breaks the inference. |
| `fasad_itibar`, `qiyas_against_text_discarded` | **Fasād al-iʿtibār.** With a text on the farʿ, the text decides and a contrary analogy is discarded. |
| `fasad_wad` | **Fasād al-waḍʿ.** If the feature is the ʿilla, it never yields the opposite (σ) of the ruling the law attaches to it, unless that ruling is mubāḥ. |

## 5. The qiyās gate

- **`Argument`**: aṣl, farʿ, ruling, ʿilla, given cases, and any text on the farʿ.
- **`gate`**: conditions: the aṣl's ruling is given, the ʿilla is in the aṣl and the farʿ, and no text rules the farʿ. Impediment: naqḍ.

| Theorem | Plain English |
| --- | --- |
| `qiyas_sound` | **Soundness.** Through the gate, every ruling that fits the given cases and depends only on the ʿilla gives the farʿ the aṣl's ruling. |
| `gate_consistent` | Through the gate, such a ruling always exists. The naqḍ impediment is exactly what consistency needs. |

## In one line

Analogy is sound exactly when the ruling depends only on the ʿilla, the ʿilla is verified in both cases, no text intervenes and no counter-case breaks it; each classical objection is a proof that one of these fails.
