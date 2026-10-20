# Usul.Judgement in Plain English

Source: [`formal/lean/Usul/Judgement.lean`](../../../formal/lean/Usul/Judgement.lean)

A legal judgement says what question it answers, about which act and person, on what evidence, and how firmly. Two judgements can only conflict when they answer the same question about the same act and person. A taklīfī answer also needs a legally responsible subject; a waḍʿī answer does not.

## 1. The three kinds of address (khiṭāb)

Following Ibn ʿUthaymīn, the Lawgiver's address either demands (ṭalab), gives a choice (takhyīr), or posits a sign (waḍʿ).

- **`Khitab`**: talab, takhyir, wad.
- **`Hukm.khitab`**: the address each of the five rulings answers. Mubāḥ is choice; the other four are demand.

| Theorem | Plain English |
| --- | --- |
| `Hukm.khitab_takhyir_iff` | A ruling falls under choice ⟺ it is mubāḥ. |
| `Hukm.khitab_talab_iff` | A ruling falls under demand ⟺ it is not mubāḥ. |
| `Hukm.khitab_ne_wad` | No taklīfī ruling is a posited sign. |
| `Hukm.khitab_σ` | An act and its omission answer the same kind of address. |
| `Domain.default_khitab` | The default for customs (ʿādāt) is choice; the default for worship (ʿibādāt) is demand. |

## 2. Waḍʿī questions: signs and validity

- **`Validity`**: ṣaḥīḥ (valid: its effects follow) or fāsid (invalid: they do not).
- **`Sign`**: what a waḍʿī question asks about: a sabab (cause), sharṭ (condition), māniʿ (impediment), or validity. The first three are yes/no; validity is ṣaḥīḥ/fāsid.
- **`Question`**: either taklīfī (answered by one of the five rulings) or waḍʿī about a sign.
- **`Question.daman`**: liability (ḍamān) is not its own kind. It is asked as "is this a sabab?".

| Theorem | Plain English |
| --- | --- |
| `Validity.ofEffects_effectsFollow`, `Validity.effectsFollow_ofEffects` | Validity and "effects follow" are the same information. |
| `Question.khitab_wad_iff` | An answer falls under waḍʿ ⟺ the question is not taklīfī. |

## 3. Yes/no taklīfī questions

- **`Aspect`**: "is it obligatory?" (yajib) or "is it permitted?" (yajūz, meaning not forbidden). Each is a projection of the full ruling.

| Theorem | Plain English |
| --- | --- |
| `Aspect.permitted_iff` | Permitted ⟺ not ḥarām. |
| `Aspect.obligatory_permitted` | What is obligatory is permitted. |
| `Aspect.omission_of_obligatory` | Omitting an obligatory act is not permitted. |

## 4. The judgement

- **`Judgement`**: a record of question, act, subject, domain, answer, epistemic grade (wahm, shakk, ẓann, qaṭʿ), whether the preponderance is known, and the kinds of dalīl (evidence) it rests on.
- **`held`**: the answer with its grade, in the form `Usul.Qawaid` uses for updating.
- **`WellTyped`**: it names at least one dalīl, and a taklīfī answer is addressed to a mukallaf (an adult of sound mind).
- **`Conflicts`**: two judgements answer the same question about the same act and subject, differently.

| Theorem | Plain English |
| --- | --- |
| `no_dalil_ill_typed` | A judgement with no evidence is not well-typed. Fiqh is knowledge of rulings *from their detailed evidence*. |
| `taklifi_needs_mukallaf` | A well-typed taklīfī judgement has a mukallaf subject. |
| `wadi_without_taklif` | A waḍʿī judgement is well-typed for anyone, once it names a dalīl. A child's destruction can still cause liability in his wealth. |
| `not_conflicts_of_question_ne` | Answers to different questions never conflict. A waḍʿī answer does not contradict a taklīfī one. |

## In one line

A judgement is an answer to a typed question on named evidence, and preference between judgements is only in point when they answer the same question about the same act and person.
