# Usul.Readings.RajabA26 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA26.lean`](../../../../formal/lean/Usul/Readings/RajabA26.lean)

Two of Ibn Rajab's qawāʿid become yes/no rules. Qāʿida 13 asks whether an athar (an effect) is referred to the ʿilla (cause) known to be in its place; qāʿida 23 asks whether the idhn (permission) of someone who wrongly refuses it lapses.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*, from the pinned witness `openiti-rajab-shamela21730`. Status: candidate.
- **Qāʿida 13**: «فهل يحال ذلك الأثر على تلك العلة المعلومة أم لا؟». Its ground is the aṣl (presumption) that there is no ʿilla but the established one. When the ẓāhir (the apparent) agrees, «فيتوافق الأصل الظاهر», the athar is referred to the known ʿilla. When the ẓāhir points elsewhere, «فيختلفان»: that conflict is qāʿida 159's, so this reading only says it is *not secured here*.
- **Qāʿida 23**: «من حرم عليه الامتناع من بدل شيء سئله فامتنع فهل يسقط إذنه بالكلية» (the witness reads «بدل»). Two anwāʿ (kinds): a bare idhn, which lapses; a taṣarruf (a contract or rescission he must make), which does not lapse, since the ḥākim (judge) compels him or acts for him.
- The records' other positions stay recorded in `corpus/takhrij/rajab_m8_rajab_a26_furu.json`.

## 2. Qāʿida 13

| Definition / Theorem | Plain English |
| --- | --- |
| `ihalaOnKnownCause knownCauseFit zahirElsewhere` | The athar is referred to the known ʿilla ⟺ a fit ʿilla is established in its place, and the ẓāhir does not point to another. |
| `agreeing_refers` | Aṣl and ẓāhir agree: the athar is referred to the known ʿilla. |
| `no_known_cause` | No ʿilla established in the place: nothing to refer it to. |
| `conflict_not_secured` | The ẓāhir points elsewhere: this qāʿida does not secure the iḥāla (referral). |

## 3. Qāʿida 23

| Definition / Theorem | Plain English |
| --- | --- |
| `idhnLapses refusalForbidden merePermission` | The idhn lapses altogether ⟺ refusing is ḥarām on him and all that is asked is an idhn. |
| `mere_idhn_lapses` | First kind: a bare idhn wrongly refused lapses, and the asker proceeds without it. |
| `tasarruf_needs_hakim` | Second kind: a refused taṣarruf does not lapse; the ḥākim steps in. |
| `permitted_refusal_stands` | A refusal he is allowed to make lapses nothing. |

## In one line

An effect is put down to the cause known to be present unless appearances point elsewhere, and a permission someone wrongly withholds simply stops being needed, though an act he must perform is forced through the judge instead.
