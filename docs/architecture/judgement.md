# The judgement form: what a question asks

`Usul.Judgement` (`formal/lean/Usul/Judgement.lean`) formalises the roadmap's judgement form `Γ ⊢ d : H(a, s) @ g` (§2.1). A question must be typed before its answer is compared with any other. Every type in the module comes from a ḥadd already in the corpus, and each is linked in `corpus/signature_map.json`, so the Lean build `#check`s it.

| Type | What it is | Source |
|---|---|---|
| `Khitab` | ṭalab, takhyīr or waḍʿ: the three things a khiṭāb does | h002 «من طلب، أو تخيير، أو وضع» |
| `Hukm.khitab` | the khiṭāb a taklīfī status answers: takhyīr exactly for ibāḥa, ṭalab for the other four | h003–h007, through `Hukm.mode` |
| `Validity` | ṣaḥīḥ / fāsid, by whether the act's effects follow (`effectsFollow`) | h008, h009 |
| `Sign` | the posited signs a waḍʿī question asks about: sabab, sharṭ, māniʿ, validity | p013 |
| `Question` | `taklifi`, answered by a `Hukm`, or `wadi s`, answered by `s.Value` (`Bool` for sabab, sharṭ and māniʿ; `Validity` for validity) | — |
| `Judgement` | question, act, subject, domain, answer (typed by the question), grade with known preponderance, dalīl kinds | roadmap §2.1 |
| `Judgement.WellTyped` | names some dalīl, and a taklīfī answer is addressed to a mukallaf | h001 «بأدلتها التفصيلية»; Ibn al-Laḥḥām q2 |
| `Judgement.Conflicts` | the same question about the same act and subject, answered differently | — |

**Liability is a sabab, not a kind of its own.** `Question.daman := .wadi .sabab` asks whether a destruction or a wrongful hand is a sabab of liability.

**Theorems**
- `Hukm.khitab_takhyir_iff`, `khitab_talab_iff`, `khitab_ne_wad`: the taklīfī half of h002's split is exact, and no status is a posited sign.
- `Hukm.khitab_σ`: an act and its omission answer the same khiṭāb.
- `Domain.default_khitab`: the aṣl is takhyīr in ʿādāt and ṭalab in ʿibādāt.
- `Question.khitab_wad_iff`: an answer falls under waḍʿ exactly when its question is waḍʿī.
- `taklifi_needs_mukallaf`, and its converse `wadi_without_taklif`: khiṭāb al-waḍʿ reaches the acts of those not under taklīf, such as a child's destruction.
- `no_dalil_ill_typed`: a judgement with no dalīl is not well-typed.
- `not_conflicts_of_question_ne`: answers to different questions never conflict, so tarjīḥ between them is out of point.

`UsulTest/Judgement.lean` guards one worked case: a child's destruction is well-typed as a ḍamān question and ill-typed as a taklīfī one. The theorems were mutation-checked. Dropping the mukallaf clause from `WellTyped`, or sending every status to takhyīr, breaks the build.

**What this does not settle**
- Which question a given fatwā or farʿ asks. That classification is the next step: each encoder declares its `Question`, and a report-only checker runs over the IslamQA labels and the takhrīj cases.
- Epistemic judgements such as the aṣl/ẓāhir encoder, which establish a fact at a `Grade` (`Qawaid.Held`) rather than answer a khiṭāb. They are not `Judgement`s, and the checker will report them as such.
