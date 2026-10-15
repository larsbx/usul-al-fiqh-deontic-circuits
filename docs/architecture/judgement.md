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

## Every encoder typed (`make judgement`)

[`corpus/types/encoders.json`](../../corpus/types/encoders.json) gives each of the 191 takhrīj encoders a *sort*. A *judgement* answers a `Question` or a yes/no `Aspect`. The other sorts are outputs that answer no khiṭāb, so they must never be compared with one:

| Sort | What the output is | Encoders | Cases |
|---|---|---:|---:|
| judgement / `wadi:sabab` | a sabab holds: liability, ownership, a right arising or lapsing | 45 | 275 |
| judgement / `wadi:validity` | ṣaḥīḥ or fāsid | 37 | 180 |
| judgement / `aspect:obligatory`, `aspect:permitted` | must he? may he? | 21 | 87 |
| judgement / `wadi:shart`, `wadi:mani` | a condition met, an impediment present | 11 | 63 |
| judgement / `taklifi` | the act's five-fold status | 3 | 5 |
| effect | a waḍʿī effect that is not yes/no: to whom, how much, which outcome | 26 | 176 |
| dalāla | what a text or utterance means or covers | 18 | 87 |
| takyīf | what a thing or fact is classified as (taḥqīq al-manāṭ) | 19 | 114 |
| epistemic | which presumption or grade establishes a fact | 4 | 80 |
| procedure | adjudication and evidence | 7 | 35 |

**How it is checked**
- `judgement.check` requires that a question fit the output domain: a `Hukm` for a taklīfī question, a Bool for a yes/no one.
- `UsulTest/EncoderTypes.lean` (generated) ascribes each judgement encoder's typed form from `Usul.Typing` to `Typed Situation (Question.Answer q)`. `Typed.mapRun` relabels the output where needed: `Validity.ofEffects` for validity, and `not` for a *negated* encoder, whose `true` is the question's no.
- `Usul.Typing` types what an encoder reads; this file types what its output answers.

**What it shows**
- **Only 0.554 of the 1,102 cases (classical and IslamQA) answer a khiṭāb at all.** The rest are effects, dalāla, takyīf, epistemic and procedure. A single "ruling" field across the bank compares answers to different questions.
- **The IslamQA tranche is a case in point.** Its five encoders split three ways. `itlaf` and `trust_loss` are sabab questions (ḍamān). `luqata` and `unknown_owner` are effects (which outcome, to whom). `asl_zahir` is epistemic. So the Prolog oracle's agreement figure mixes three sorts.
- **Classification is uncertain.** 84 of the 191 encoders carry an `alt`, a second defensible reading. The commonest splits are validity vs aspect:permitted («لا يجوز» in worship or disposal), sabab vs effect, and dalāla vs takyīf. These are the review items.
- **Four encoders had their polarity reversed:** `trust_voidance`, `cut_sale_left_to_ripen` and `simultaneous_combination_voids` return true for *void*, and `supervening_bar_extends_to_preliminaries` true for *forbidden*. They are typed negated (validity, and may-he), rather than given a polarity that reads the other way.
- **The IslamQA labels:** 2,326 of 14,352 taklīfī labels (0.162) sit on a question that asks about a posited sign or a report:
  - validity: 1,772;
  - milk: 357;
  - ḍamān: 299;
  - riwāya: 47, listed under `labels.riwaya` in [`report.json`](../../corpus/types/report.json).

  These are flags for review, never relabelled automatically.

**What this does not settle**
- Whether the classification is right. Every entry is a candidate: classified with LLM assistance, adjudicated on the hard cases, not reviewed by a person.
- The non-judgement sorts have no answer type in Σ yet: an effect's codomain (who, how much) and a dalāla's (what is covered) are still each encoder's own enum.
