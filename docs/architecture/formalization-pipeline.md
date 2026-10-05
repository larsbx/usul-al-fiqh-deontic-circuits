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
| Ibn ʿUthaymīn, *Sharḥ Manẓūmat Uṣūl al-Fiqh* | archive.org scan: archive.org OCR + our OCR | located; verse count open |
| Ibn Rajab, *Taqrīr al-Qawāʿid* | OpenITI 0800AH, Shamela 21730 (`.completed`) | located; segmented |
| Ibn Taymiyya, *al-Qawāʿid al-Nūrāniyya* | OpenITI 0750AH, Shamela 21729 (`.completed`) | located |
| al-Saʿdī, *Ṭarīq al-Wuṣūl* | archive.org scan, our OCR | OCR done; not segmented |
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

**Rights policy.** Full texts live only in `.cache/`. Committed records carry excerpts of at most 400 characters for pre-modern texts and at most 160 characters for modern authors (`records.EXCERPT_LEN`).

## 2. Rule counts checked against pinned editions (M0 exit)

These come from `corpus/audit.json`, produced by `audit_numbering`:

| Claim | Witness | Result |
|---|---|---|
| Ibn Rajab: 160 qawāʿid | Shamela 21730 | **confirmed**: 1…160, no gaps or duplicates |
| Ibn al-Laḥḥām: 66 qawāʿid | Shamela 8526 | **confirmed**: 1…66 |
| Ibn al-Laḥḥām: 66 qawāʿid | ShamAY 34193 | 64 headers, missing 16, 18 and 30. This is a witness defect, so 8526 is the primary witness |
| al-Saʿdī: 60 qawāʿid | 2 OCRs × (body + closing index) | **confirmed**: every number from 1 to 60 is attested by at least one of four witnesses; 22 and 23 share one printed heading (see [`ocr-pipeline.md`](ocr-pipeline.md)) |

## 3. Records

| Type | Count | Meaning |
|---|---|---|
| `qaida` | 160 + 66 + 64 + 54 | numbered rule, heading, statement excerpt, locator |
| `far` | 2117 | a case paragraph opening with «منها/ومنها», linked to its qāʿida. These are the candidate entailments for the M4 takhrīj suite (1056 from Ibn Rajab, 534 from Ibn al-Laḥḥām 8526) |
| `hadd` | 26 | term, lughatan, iṣṭilāḥan, from *al-Uṣūl* (M2 signature) |

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
| `Usul.Qawaid` | `yaqin_la_yazul_bish_shakk`, `update_grade_mono`, `closure_respects_capacity` (*mā lā yatimm al-wājib…* is consistent with *lā wājib maʿa ʿajz*), `darura_bounded` |
| `UsulTest` | 47 shared grounded-extension vectors checked with `#guard`; Σ-map constants checked with `#check` |

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
2. **M3:** encode al-Saʿdī's rules one by one from the reviewed records. Each gets a Lean statement, a Haskell executable and at least one farʿ test.
3. **M4:** turn the Ibn al-Laḥḥām `far` records into golden entailments. This needs a ruling annotation per case, which is human or LLM-assisted and always goes through review.
4. **OCR:** detect the verse frames in the *Manẓūma* and OCR each column; segment *Ṭarīq al-Wuṣūl* (see [`ocr-pipeline.md`](ocr-pipeline.md)).
5. **Proof debt:** prove that `Grounded.grounded` reaches the least fixed point within `n + 1` steps. Today agreement rests on `mem_step_iff` plus the vectors.
