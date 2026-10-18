# UsulTest.Judgement in Plain English

Source: [`formal/lean/UsulTest/Judgement.lean`](../../../formal/lean/UsulTest/Judgement.lean)

A legal judgement answers a specific question about a specific act and subject, and must rest on a dalīl (proof). These checks guard that shape: what khiṭāb (form of address) each status answers, what validity means, and when a judgement is well-typed. Liability and permissibility answer different questions, so they never conflict.

## 1. The khiṭāb of each status

| Check | Plain English |
| --- | --- |
| `[wajib, mandub, mubah, makruh, haram].map Hukm.khitab == [talab, talab, takhyir, talab, talab]` | Mubāḥ is takhyīr (a free choice); the other four are ṭalab (a demand). |

## 2. Validity

- **Ṣaḥīḥ** (valid) and **fāsid** (invalid): validity means whether the act's legal effects follow.

| Check | Plain English |
| --- | --- |
| `[sahih, fasid].map Validity.effectsFollow == [true, false]` | Effects follow a valid act and not an invalid one. |
| `[true, false].map Validity.ofEffects == [sahih, fasid]` | Going back from effects to validity gives the same answer. |

## 3. Typing a judgement

- **`child`**: a subject with ʿaql but not bulūgh, so not a mukallaf (not legally accountable).
- **`adult`**: a subject with both, so a mukallaf.
- **`childDaman`**: a child breaks a neighbour's vessel. The question is ḍamān (liability): is the destruction a sabab (cause) of liability? It cites a naṣṣ.
- **`childTaklifi`**: the same act, asked as a taklīfī question (is it ḥarām for the child?).
- **`adultNoDalil`**: a taklīfī answer for an adult that cites no dalīl.

| Check | Plain English |
| --- | --- |
| `decide childDaman.WellTyped` | A liability question about a child is well-formed. Khiṭāb al-waḍʿ (declaratory rules) reaches non-mukallafs. |
| `!decide childTaklifi.WellTyped` | A taklīfī ruling addressed to a child is ill-formed. |
| `!decide adultNoDalil.WellTyped` | A judgement with no dalīl is ill-formed. |
| `{ childTaklifi with subject := adult }` is well-typed | The same question put to an adult is fine. |
| `childDaman.khitab == .wad && childTaklifi.khitab == .talab` | Liability is a declaratory address; prohibition is a demand. |
| `¬ childDaman.Conflicts childTaklifi` | Liability and the taklīfī status of the same act answer different questions, so they cannot conflict. Proved by `Judgement.not_conflicts_of_question_ne`. |

## In one line

A child who breaks a vessel can be liable without the act being ḥarām for him: different questions, different addressees, no contradiction.
