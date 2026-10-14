# Formalization Pipeline

This is the executable form of milestones M0–M2 from [`../roadmap-hanbali-usul-formalization.md`](../roadmap-hanbali-usul-formalization.md), with first slices of M3, M5 and M6.

```text
corpus/registry.json ──fetch──▶ .cache/corpus/*.txt (pinned, sha256 in corpus/lock.json; never committed)
        │                              │
        │                       build (segment)
        │                              ▼
        │                corpus/records/*.jsonl  ── validate ──▶ schemas/usul_rule.schema.json
        │                (qāʿida · farʿ · ḥadd candidates)          + corpus/signature_map.json
        │                corpus/audit.json (edition counts)
        ▼
formal/fixtures/grounded-v1.json ──▶ Lean #guard (UsulTest)  ·  Haskell laws (semantic-categorical-oracle)
formal/lean/Usul/*.lean          ──▶ lake build (no sorry)
formal/tla/*.tla                 ──▶ TLC (bounded)
```

Run everything with `make all`. CI runs `.github/workflows/formalization.yml`.

## 1. Sources located (M0)

Each witness is pinned: the OpenITI ones by commit SHA, the others by Shamela book id or archive.org item. `corpus/lock.json` records the size and sha256 of every fetched file.

| Work | Witness | Status |
|---|---|---|
| Ibn ʿUthaymīn, *al-Uṣūl min ʿIlm al-Uṣūl* | Shamela 9942 (Dār Ibn al-Jawzī, 1430; print pagination) | located; 26 ḥudūd extracted |
| Ibn Qudāma, *Rawḍat al-Nāẓir* | OpenITI 0625AH, Shamela 12010 | located |
| al-Ṭūfī, *Sharḥ Mukhtaṣar al-Rawḍa* | OpenITI 0725AH, Shamela 10781 | located |
| Ibn al-Najjār, *Sharḥ al-Kawkab al-Munīr* | OpenITI 0975AH, Shamela 12019 | located |
| al-Saʿdī, *al-Qawāʿid wa'l-Uṣūl al-Jāmiʿa* | archive.org `Pdf1995` (Dār al-Waṭan): archive.org OCR + our OCR | located; 60 confirmed; text needs review |
| Ibn ʿUthaymīn, *Sharḥ Manẓūmat Uṣūl al-Fiqh* | archive.org scan: archive.org OCR + our OCR with verse reader | located; 103 verses confirmed and segmented |
| Ibn Rajab, *Taqrīr al-Qawāʿid* | OpenITI 0800AH, Shamela 21730 (`.completed`) | located; segmented |
| Ibn Taymiyya, *al-Qawāʿid al-Nūrāniyya* | OpenITI 0750AH, Shamela 21729 (`.completed`) | located |
| al-Saʿdī, *Ṭarīq al-Wuṣūl* | archive.org scan, our OCR (frame crop, denoise, number reader) | 1015 paragraphs confirmed; 997 segmented |
| al-Saʿdī, *Risāla Laṭīfa fī Uṣūl al-Fiqh* *(addition)* | Shamela 9527 | located |
| Ibn al-Laḥḥām, *al-Qawāʿid wa'l-Fawāʾid al-Uṣūliyya* | OpenITI 0825AH: Shamela 8526 + ShamAY 34193 | located; segmented |
| Ibn al-Qayyim, *Iʿlām al-Muwaqqiʿīn* | OpenITI 0775AH, Shamela 11496 | located |
| Ibn ʿUthaymīn, *al-Sharḥ al-Mumtiʿ* | Shamela 10649 | located; fetched only on demand (`--work`) because of its size |
| al-Shinqīṭī, *Ādāb al-Baḥth wa'l-Munāẓara* | Shamela 266 | located |
| al-Shinqīṭī, *Mudhakkira* | Shamela 282, 9885 | located |
| Ibn Taymiyya, *al-Radd ʿalā al-Manṭiqiyyīn* | OpenITI 0750AH, Shamela 7626 | located |
| Ibn ʿUthaymīn, *al-Qawāʿid al-Muthlā* | Shamela 8874 | located |
| Ibn Taymiyya, *al-Tadmuriyya* | OpenITI 0750AH, Shamela 22666 | located |
| Ibn ʿUthaymīn, *Taqrīb al-Tadmuriyya* | Shamela 11100 | located |
| al-Mardāwī, *al-Inṣāf* *(addition)* | OpenITI 0900AH, Shamela 21609 | located |
| 23 classical works on qiyās (8 Ḥanbalī, 13 other madhhabs, Ibn Ḥazm against) | OpenITI, pinned commits | located and fetched; see [`qiyas.md`](qiyas.md#sources) |
| 49 fatāwā, masāʾil and aḥkām collections cited by Ibn Bāz, Ibn ʿUthaymīn, al-Albānī and al-Saʿdī (52 with three already registered), plus 8 of their own collections as citers (9 with *al-Sharḥ al-Mumtiʿ*) | OpenITI (pinned commits) and Shamela | located and fetched; titles and authors counted; see [`reception.md`](reception.md); mentions labelled for a classifier, see [`mentions.md`](mentions.md) |

**Rights policy.** Full texts are fetched into `.cache/`. The 89 public-domain text witnesses (works with `rights: public_domain_text`, all OpenITI) are also committed under [`corpus/texts`](../../corpus/texts/README.md) via Git LFS, byte-identical to their pinned source; modern texts are never committed. Committed records carry excerpts of at most 400 characters for pre-modern texts and at most 160 characters for modern authors (`records.EXCERPT_LEN`).

## 2. Rule counts checked against pinned editions (M0 exit)

These come from `corpus/audit.json`, produced by `audit_numbering`:

| Claim | Witness | Result |
|---|---|---|
| Ibn Rajab: 160 qawāʿid | Shamela 21730 | **confirmed**: 1…160, no gaps or duplicates |
| Ibn al-Laḥḥām: 66 qawāʿid | Shamela 8526 | **confirmed**: 1…66 |
| Ibn al-Laḥḥām: 66 qawāʿid | ShamAY 34193 | 64 headers, missing 16, 18 and 30. This is a witness defect, so 8526 is the primary witness |
| Ibn ʿUthaymīn, *Manẓūma*: 103 abyāt | printed matn, autograph facsimile, our OCR (verse reader) | **confirmed**: the matn and the autograph both end at ١٠٣, and the pipeline numbers 1…103 with no gaps (see [`ocr-pipeline.md`](ocr-pipeline.md)) |
| al-Saʿdī, *Ṭarīq al-Wuṣūl*: 1015 paragraphs | printed last number ١٠١٥, part-two opening ٨٢٤, pipeline | **confirmed**: 997 segmented, all 8 eye-checked positions agree (see [`ocr-pipeline.md`](ocr-pipeline.md)) |
| al-Saʿdī: 60 qawāʿid | 2 OCRs × (body + closing index) | **confirmed**: every number from 1 to 60 is attested by at least one of four witnesses; 22 and 23 share one printed heading (see [`ocr-pipeline.md`](ocr-pipeline.md)) |

## 3. Records

| Type | Count | Meaning |
|---|---|---|
| `qaida` | 160 + 66 + 64 + 54 | numbered rule, heading, statement excerpt, locator |
| `far` | 2117 | a case paragraph opening with «منها/ومنها», linked to its qāʿida. These are the candidate entailments for the M4 takhrīj suite (1056 from Ibn Rajab, 534 from Ibn al-Laḥḥām 8526) |
| `hadd` | 26 | term, lughatan, iṣṭilāḥan, from *al-Uṣūl* (M2 signature) |

The interpretive commitments the readings make are kept as 12 review questions in `corpus/review/sadi_interpretive_questions.json`. Each cites established answers from the pinned Ḥanbalī corpus (Ibn Rajab, al-Inṣāf, Iʿlām, Sharḥ al-Kawkab) and offers analogies, and all are routed to the Sharīʿah-authority gate (see [`schemata.md`](schemata.md#governance-where-the-explanations-live-and-why-there)).

Every record has `status: candidate`. Promotion to `reviewed` and `accepted` follows the `Review.tla` protocol below.

Known extraction defect: h014 is labelled «فمن المخصص المتصل» but is the ḥadd of *al-istithnāʾ*. It should be fixed during review, not in code.

## 4. Formal kernel

### Lean 4 (`formal/lean`, core only, no Mathlib, zero `sorry`)

| Module | Results |
|---|---|
| `Usul.Hukm` | `σ_involutive`, `σ_antitone`, `σ_valence`, `amr_nahy_didd`, `σ_fixed_iff` (only ibāḥa is fixed), `mode_binding_injective` (ṭalab/takhyīr × ilzām separates all five statuses), `σ_preserves_binding` |
| `Usul.Signature` | `Mukallaf` as a refinement type, `no_taklif_without_mukallaf`, `Grade`, `DalilKind.resort` with `qiyas_after_athar`, `Domain.default` (ʿāda → mubāḥ, ʿibāda → tawqīf), waḍʿī gate `applies` |
| `Usul.Dung` | `F_mono`, `admissible_F`, `approx_admissible`, `approx_conflictFree`, `approx_succ`, `approx_sub_complete` (grounded ⊆ every complete extension), `unattacked_in_approx_one` |
| `Usul.Grounded` | executable grounded extension; `defended_iff` and `mem_step_iff` show that one step equals `Dung.F` |
| `Usul.Taarud` | `resolve` (jamʿ → naskh → tarjīḥ → tawaqquf), `resolve_jam_first`, `resolve_naskh_before_tarjih`, `resolve_tawaqquf_iff` |
| `Usul.Sadi` | al-Saʿdī's rules: `q01_balanced_is_mubah` (under maṣlaḥa weighing, a balanced act is mubāḥ); `q04_*` (no obligation with inability, no prohibition with necessity, relief never binds); `q06_*` (domain defaults); `q08_*` (conditions, pillars, impediments); `q11_yaqin`, `q52_strong_qarina_prevails`; `q16`; `q22_valid_iff_preserves_prohibition`; `q27_asymmetry` (omission versus commission under an excuse); `q28`; `q33_higher_benefit`, `q33_lighter_harm`; `q38_voids_iff_intrinsic`; `q40_*` (partial capability); `q58_qiyas`, `q58_factors` (a ruling depends only on its ʿilla iff it factors through it), `q58_naqd`; `q59`/`q60` generality markers |
| `Usul.Schema` | eight shapes, each with laws and a transport theorem: S1 invariance (`Factors`, `pullback`), S2 priority (`first`, a monoid hom, `first_map`), S3 gate algebra (`holds_meet`, `holds_comap`), S4 closure (`least`, `idem`, `map`), S5 inert events (`inert_fold`), S6 presumption and burden (`burden_factors`), S7 merge classes (`reps_covers`, `Covers.map`), S8 optimisation (`best_optimal`, `Optimal.restrict`, `Optimal.mono`). Kernel instances: `wajib_is_closure` (Q2), `operative_is_gate` (Q4), `ruled_is_priority` (Q6), `yaqin_doubts_inert` (Q11), `substitute_is_priority` (Q28), `q33_is_optimal`, `obligedParts_is_gate` (Q40), `dependsOn_iff_factors` (Q58), `taarud_is_priority`. See [`schemata.md`](schemata.md) |
| `Usul.Process` | the review process read with its own principles: `status` by S2 (cited text ≻ analogy ≻ tawaqquf), `analogy_never_outranks_text`, `order_is_resort` (Aḥmad's order), `never_adopts`, analogy as qiyās (`Licensed`, `naqd`), deadlock freedom (`no_deadlock_of_stratified`, `no_cycle_of_rank`). See [`schemata.md`](schemata.md#dogfooding-the-review-runs-on-its-own-principles) |
| `Usul.Qiyas` | masālik al-ʿilla (ṭard, dawarān, sabr wa-taqsīm, munāsaba, shabah, tanqīḥ/takhrīj/taḥqīq al-manāṭ) and qawādiḥ (manʿ, naqḍ with takhṣīṣ, kasr, ʿadam al-taʾthīr, farq, qalb, al-qawl bi'l-mūjab, fasād al-iʿtibār, fasād al-waḍʿ), each with a soundness theorem; the qiyās gate with `qiyas_sound` and `gate_consistent`. Disputed points are parameters. See [`qiyas.md`](qiyas.md) |
| `Usul.Jadal` | the eighteen objections as one debate gate: manʿ-kinds as conditions, muʿāraḍa-kinds as impediments (`Qadih.kind`); `debateGate_holds_iff` (the gate holds iff no objection succeeds), `debateGate_sound`; qiyās al-ʿaks, al-dalāla, al-awlā/musāwī; shabah as fallback (S2); tarjīḥ under source constraints (S8). See [`qiyas.md`](qiyas.md#all-objections-at-once-the-debate-gate-usuljadal) |
| `Usul.QiyasLimits` | how qiyās fails (an added description stays sound, an omitted one does not), why no sound qiyās contradicts a text, the Ḥanbalī scope (rationale understood; ḥudūd and kaffārāt included; the Ḥanafī scope strictly narrower), jalī/khafī, shahādat al-uṣūl, tamthīl ≡ shumūl. See [`qiyas.md`](qiyas.md#the-limits-of-qiyās-usulqiyaslimits) |
| `Usul.Dalala` | M5 inference schemata: generality with ʿahd/taʿyīn (`IsGeneralIn`, conservative over Q59/60), takhṣīṣ (`takhsis_not_naskh`), muṭlaq/muqayyad, amr ⇒ wujūb and nahy ⇒ taḥrīm as defeasible defaults (`nahy_default_is_sigma`), al-amr bi'l-shayʾ nahy ʿan ḍiddih from σ (`amr_nahy_didd_of`), mafhūm al-mukhālafa with its blockers, tarjīḥ ≺ strict and well-founded (`prefers_wf`), ʿumūm al-lafẓ |
| `Usul.Refinements` | conservative refinements driven by the takhrīj gaps, each with a `*_conservative` proof that its default is the earlier reading: `allocationFull` (confused entitlement → lots), `recourseFull` (owed-by-other, permission), `zahirPrevails` (indicators on equal grades), `recourseNec` (permission unobtainable); and the open gaps' own principles: `treatedAsAbsent` (Ibn Rajab 106), `hamlAlaAdna` (Aḥmad's naṣṣ: the lowest is certain), `trustVoided` (Ibn Rajab 45), `abstains` (Taqī al-Dīn); round 4: `ghululForfeits`, `heardAfterDenial`, `fayTieBreak`, `luqata`, `validOnEvery`, `jawazAfterSarf`, `amrPerItem` (with `mixed_readings_agree`); for IQ-21, `yaqinForAmal` (Ibn Taymiyya: knowledge of preponderance), `basis` (bayt 90: yaqīn ≻ ghalabat al-ẓann ≻ aṣl) and `zannSetAside` («لا عبرة بالظن البين خطؤه», limited by «الاجتهاد لا ينقض بالاجتهاد»). See [`takhrij.md`](takhrij.md#the-bank-applied-to-itself); each is cited in the [dossier](dossier.md), terms in the [glossary](../glossary.md) |
| `Usul.Muamalat` | al-Saʿdī's transaction rules over a small model of possession, liability and contract: `q10` (burden of proof), `q12_*` (mutual consent, via Q8's gate), `q13_q36_consistent` (strict liability for destruction applies exactly to destruction without right), `q14_*` (trustee vs. wrongdoer), `q18`/`q19` (compensation in kind or value), `q21_forbidden_iff` (gharar), `q24_first_has_priority` and `q37_strongest_prevails` (both instances of Q33's `best`), `q26_q43_consistent`, `q46_never_more_than_due`, `q49`, `q53_distinction`, `q54`–`q56`; co-ownership and motive: `q30_*`, `q32_*` (recourse, unless given as a gift), `q42_instance_of_q21`, `q45_*` (knowledge required only where consent is), `q51_valid_iff`, `q51_q54_consistent` |
| `Usul.Kulliyyat` | the general maxims: `q05_both_foundations` (sincerity ∧ following, via Q8's gate); `q09_*` (custom fills undefined measures); `q15_*`; `q17_*`; `q29_attach_narrows` (qualifiers only narrow); `q31_each_cause_its_effect`; `q34_best_admissible` (Q33's `best` discharges a guardian's choice); `q39_*` (after the cause, before the condition); `q41_*` (merging of like worship); `q48_custom_monotone`; `q50_*`; `q57_*` (intent read where possible) |
| `Usul.Qawaid` | `yaqin_la_yazul_bish_shakk`, `update_grade_mono`, `closure_respects_capacity` (*mā lā yatimm al-wājib…* is consistent with *lā wājib maʿa ʿajz*), `darura_bounded` |
| `UsulTest` | 47 shared grounded-extension vectors checked with `#guard`; Σ-map and catalogue constants checked with `#check`; every catalogue schema tag pinned by a typed `example` (`Schemata.lean`) |

### TLA+ (`formal/tla`, TLC, bounded)

| Spec | Checked |
|---|---|
| `Istishab` | `Explained`, plus the action property `DoubtIsInert` |
| `Taklif` | `OnlyMukallafBound`, `OughtImpliesCan`, `RukhsaNeedsSabab`, `BulughIrreversible` |
| `Naskh` (via `MCNaskh`) | `NoAbrogatedIsActive`, `NasikhIsLater`, `NasikhIsNass` (ijmāʿ never abrogates), `NoSelfOrCycle` |
| `Review` | `AcceptedWasReviewed`, `SupportIsAccepted` |

Each invariant was mutation-checked once: a seeded bug in the spec makes TLC report exactly that invariant.

### Haskell (`semantic-categorical-oracle`, `advisory_oracle`)

`Oracle.Usul.{Hukm,Argumentation,Taarud}` mirror the Lean kernel. Their laws are registered in `registry/laws.toml` as `spike` with `proof_authority = false`. Finite-domain laws are checked exhaustively. The grounded-extension laws are checked by brute force over every subset of frameworks with up to 6 arguments, and the Haskell implementation also checks the same 47 vectors as Lean. So three independent implementations (the Python reference, Lean and Haskell) agree on `grounded-v1.json`.

## 5. Next steps

1. **Review queue (M0/M4):** review the 26 ḥudūd and the al-Saʿdī OCR units; correct h014; classify qawāʿid `kind` (meta / default / taqsīm / farq / closure).
2. **M3:** review `corpus/proposals/sadi_qawaid.json`, which needs a human to check the readings, especially the three emendations (Q9, Q32, Q45), and to confirm the kinds. All 60 rules now have a formal reading (`test_sadi_catalogue_is_formalised_and_checked` keeps it so). The readings are deliberately thin; review should judge each against the text, especially where a reading adds a condition the heading leaves implicit (Q15 outside prescribed retaliation, Q32 unless given as a gift).
3. **M4:** the first tranche is in (204 furūʿ, Lean-guarded; see [`takhrij.md`](takhrij.md)). Next: review the annotations, decide IQ-09 and IQ-20 (IQ-21, the yaqīn threshold, was adopted on human review: `Grade.YaqinFor`, Ibn Taymiyya's second-order reading; amended so that `update` treats a ẓann of unknown preponderance as tawaqquf: inert as a challenger, shakk-strength as the incumbent, `update_conservative` otherwise), then extend to the remaining Ibn Rajab furūʿ (911 furūʿ and divisions in 127 qawāʿid, plus 6 qawāʿid with no segmented furūʿ, after M8 tranches 1–3, which took qawāʿid 6, 22, 68; 7, 27, 28, 64, 65; and 1, 17, 66, 91, 93; opening examples are now segmented as `.f000`, see [`takhrij.md`](takhrij.md#m8-scale-up-first-tranche)) and, after M5, to Ibn al-Laḥḥām's uṣūl rules.
4. **OCR:** recover the 18 missing *Ṭarīq* paragraphs and verse 60's commentary link; split *Ṭarīq* into its source sections («ومن رسالة …») (see [`ocr-pipeline.md`](ocr-pipeline.md)).
5. **Proof debt:** prove that `Grounded.grounded` reaches the least fixed point within `n + 1` steps. Today agreement rests on `mem_step_iff` plus the vectors.
