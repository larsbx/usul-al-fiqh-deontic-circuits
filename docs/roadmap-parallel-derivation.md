# Derivation method and the parallel attack on the source texts

The method itself (how a ruling in a text is derived by the kernel, checked, extended and governed) is specified in [`architecture/derivation-method.md`](architecture/derivation-method.md). Part II maps the 117 cached witnesses (89 of them committed under [`corpus/texts`](../corpus/texts/README.md)) onto the roles the method knows. Part III plans running the method over them in parallel, with the write isolation and integration discipline the parallel tranche 3 (PRs #31, #32) showed to be necessary.

Nothing here changes a status. Every artifact the plan produces is `candidate`, and every interpretive commitment goes to the review gate ([schemata.md](architecture/schemata.md#governance-where-the-explanations-live-and-why-there)).

---

## Part I: the derivation method

The method is specified in [`architecture/derivation-method.md`](architecture/derivation-method.md):
- objects (§1);
- the derivation judgement and its Lean witnesses (§2);
- the tranche procedure S0–S9 with its gates (§3);
- the invariants the history enforced (§4);
- the parallel-run protocol: claims, write isolation, integration, failure modes (§5);
- the method as a fixed point (§6).

This roadmap applies it.

---

## Part II: the texts, by the role the method gives them

Profiled from the cached witnesses: size, headings, numbered masāʾil, Q/A markers. Units are what a segmenter has to produce before S2 can start.

| Role in the method | Texts | Unit | Feeds |
|---|---|---|---|
| **R1 Rule sources**: readings (S1) | Ibn Rajab *Taqrīr al-Qawāʿid* (745 furūʿ pending in 87 qawāʿid, 6 qawāʿid needing segmentation); Ibn al-Laḥḥām (M5 commands); Ibn Taymiyya *al-Qawāʿid al-Nūrāniyya*; the qawāʿid stated inside *Iʿlām* and *Badāʾiʿ al-Fawāʾid* | qāʿida + its furūʿ | 𝔅's readings |
| **R2 Case sources**: takhrīj tranches (S2) | **fatāwā:** *Majmūʿ al-Fatāwā* (≈1,800 «وسئل»), *al-Fatāwā al-Kubrā*, *Jāmiʿ al-Masāʾil*, *al-Mustadrak*, *al-Fatḥ al-Rabbānī*, *al-Durar al-Saniyya*, Fatāwā Muḥammad b. Ibrāhīm, the Lajna (≈4,000 Q/A); **mutūn** as compact ruling statements: *Zād al-Mustaqniʿ*, *ʿUmda*, *al-Muqniʿ*, *al-Muḥarrar*, *Muntahā*, *Iqnāʿ*; **modern citers** (cache-only): Ibn Bāz, Ibn ʿUthaymīn (*Majmūʿ*, *Nūr*, *al-Mumtiʿ*) | one question-answer, or one masʾala | cases for existing encoders; new readings where none fits |
| **R3 Attribution and taṣḥīḥ**: S6/S7 evidence | **naṣṣ:** *Masāʾil* of Aḥmad (al-Kawsaj ≈3,800 entries, Abū Dāwūd, Ḥarb); **taṣḥīḥ:** *al-Inṣāf*, *al-Furūʿ* + *Taṣḥīḥ al-Furūʿ*, *Kashshāf*, *Sharḥ al-Muntahā*, *al-Mubdiʿ*, *al-Sharḥ al-Kabīr*, *al-Mughnī*, al-Baʿlī's *Ikhtiyārāt* | a graded, verbatim evidence item | 𝔏; madhhab-side verification |
| **R4 Position inventories**: the *P* of ikhtilāf cases | Ibn al-Mundhir (*al-Ijmāʿ* ≈400 propositions, *al-Awsaṭ*, *al-Ishrāf*); Ibn Ḥazm (*Marātib al-Ijmāʿ*, *al-Muḥallā*); Ibn Rushd; al-Nawawī *al-Majmūʿ*; Ibn ʿAbd al-Barr *al-Istidhkār*; al-Shawkānī *al-Sayl* | an attributed position per masʾala | positions with cross-madhhab attribution; ijmāʿ reports |
| **R5 Dalīl** | *Bulūgh*, *Nayl al-Awṭār*, *Subul al-Salām*, *Fatḥ al-Bārī*, *al-Talkhīṣ al-Ḥabīr*, *Zād al-Maʿād*, *Maʿālim al-Sunan*, *Sharḥ Muslim*; al-Albānī's *Irwāʾ*, *Tamām al-Minna* | a ḥadīth with its grading | the naṣṣ grade in 𝔏; the al-Albānī track (H-milestones) |
| **R6 Inference and dialectic** | the 23 qiyās works, *Rawḍa*, *Sharḥ al-Kawkab*, *al-Musawwada*, al-Shawkānī *Irshād* … | uṣūl doctrine | M5 schemata (not takhrīj) |

**Ijmāʿ is recorded as a research question: [RQ-01](../corpus/review/research_questions.json).** A reported ijmāʿ that contradicts κ<sub>ρ</sub>(φ) could be an encoding error, or evidence graded above taṣḥīḥ. The kernel already places ijmāʿ three ways: with naṣṣ in `Usul.DalilKind.resort`, above naṣṣ among the masālik in `Usul.Jadal.RespectsSources`, and not at all in `Usul.Reconcile.Grade`. The reports themselves are disputed: Aḥmad's «من ادعى الإجماع فهو كاذب» (*Iʿlām* v1 p24), and Ibn Taymiyya's *Naqd Marātib al-Ijmāʿ*. **Policy in force (human instruction, 2026-10-11): as is.** Ijmāʿ reports enter 𝔏 as evidence and change no class. RQ-01 lists the alternatives and the research steps.

---

## Part III: the parallel attack

### III.1 Why the current layout serialises

Two files would serialise any parallel run, and the history shows what happens otherwise:

- **`takhrij.ENCODERS`**: one dict holding all 100 encoders. Every shard that adds a reading edits it.
- **`Usul/Refinements.lean`**: 1,048 lines holding every reading since round 2. Every shard edits it.
- **Shared generated outputs**: `Takhrij.lean`, `report.json`, the worklist, the dossier and glossary pages, the signature map, `lock.json`. A shard that regenerates them conflicts with every other shard.

Precedents:
- Two parallel tranche-3 contributions needed a dedicated consolidation (case hashes pinned per PR head, disjoint ids, totals regenerated; [m8-tranche3-reconciliation](architecture/m8-tranche3-reconciliation-2026-10-08.md)).
- A long fetch started before a merge wrote back a stale `lock.json` and dropped 23 entries (fixed in #55).

### III.2 Phase 0: prerequisites (serial, small)

**Status.**
- **Done:** P0.1, P0.2 and P0.3 (`pipeline/usul_corpus/shards.py`, method §5.2). Of P0.4, claims with disjoint ownership over the generated worklists (method §5.1).
- **P0.5, three segmenters done.** `qa` (`pipeline/usul_corpus/qa.py`), configured per work in the registry by two line-start patterns. It emits `fatwa` records: question and answer excerpts within rights, the page span, and the `sha256` receipt of the whole unit. `test_committed_unit_records_replay_from_the_pinned_witness` replays them.
  - Seven collections are segmented, totalling 21,168 units (answered share in brackets): *Majmūʿ al-Fatāwā* 1,847 (0.99), *al-Fatāwā al-Kubrā* 971 (0.80), *Jāmiʿ al-Masāʾil* 122 (0.73), *al-Durar al-Saniyya* 1,651 (0.99), the Lajna 10,437 (0.97), Ibn Bāz 4,597 (0.98), Ibn ʿUthaymīn 1,543 (1.00). Page markers and milestones are stripped wherever they fall in a line.
  - `masail` (`qa.segment_entries`) cuts a *Masāʾil* collection at a line-start opening formula; a named group `n` captures the printed number. It emits `masala` records with the same receipt and replay. Three collections give 5,700 entries: al-Kawsaj 3,575 (numbered 1–3,609: 6 duplicates, 40 numbers missing, listed in `corpus/audit.json`), Abū Dāwūd 1,585 (699 on pages the witness leaves unnumbered, `PageV00P000`), Ḥarb 540.
  - `abwab` (`pipeline/usul_corpus/abwab.py`) cuts a matn into kitāb › bāb › faṣl units, ranking each heading by its first word, not its mARkdown level. It emits `bab` records carrying the rank, the heading, the enclosing kitāb and bāb titles (`path_ar`), the excerpt and the receipt, replayed like the others. Six mutūn give 2,613 units: *Zād* 286, *ʿUmda* 207, *al-Muqniʿ* 631, *al-Muḥarrar* 212, *Muntahā* 383, *al-Iqnāʿ* 894 (ranks per witness in `corpus/audit.json`). A unit routes a masʾala to its bāb; splitting units into masāʾil is the next step for R2.
  - *Nūr ʿalā al-Darb*: Ibn Bāz 7,607 units by «س:/ج:» (0.997), Ibn ʿUthaymīn 7,448 (0.997). Ibn ʿUthaymīn's witness prints each question as a section heading with no marker word, so `qa` takes `question_heading`; follow-ups inside an episode open with «فضيلة الشيخ:».
  - Fatāwā Muḥammad b. Ibrāhīm is letters, not Q/A, but the collection numbers them: `masail` with `ordered` opens entries only at the longest increasing run of printed numbers, so a letter's own enumeration and reference numbers stay in its text. 3,974 entries numbered 1–4,575, no duplicates; of the 601 missing numbers, most never occur at a line start in the witness.
  - In *al-Kubrā* and *Jāmiʿ*, many answers begin without a «الجواب» marker. Their unanswered units keep only the question header, so they wait for review rather than absorbing text.
- **Open:**
  - extending the worklist inventory to the new record types;
  - joining al-Irwāʾ to the `masala`, `fatwa` and `bab` records. `hadith.JOIN_TYPES` holds the join to the reviewed types; widening it proposes 1,351 masāʾil candidates, which are a review tranche of their own;
  - P0.6.

| # | Change | Gate |
|---|---|---|
| P0.1 | **Split the encoder registry**: `pipeline/usul_corpus/encoders/<shard>.py`, auto-discovered; `ENCODERS` becomes their union with a duplicate-name check | the existing suite passes unchanged; a test that the union equals today's 100 |
| P0.2 | **Split the readings**: new readings go to `formal/lean/Usul/Readings/<Shard>.lean`, imported by a *generated* `Usul/Readings.lean`; `Refinements.lean` frozen except for conservative refinements of its own encoders | `lake build`; `signature` |
| P0.3 | **Fragment the hand-written ledgers**: dossier entries and reconciliation-ledger entries as per-shard files (`corpus/dossier/entries/<shard>.json`, `corpus/reconciliation/entries/<shard>.json`), loaded as a union (as `takhrij.load_dir` already does for cases) | dossier and reconcile tests unchanged |
| P0.4 | **Generalise the worklist**: `m8-worklist` → `worklist <text>`. Obligations are unit ids per text, with `input_sha256` and owner shard; `--check` adds *disjoint ownership* | `worklist --check` over Ibn Rajab reproduces today's `rajab_m8.json` |
| P0.5 | **Segmenters for the new genres**: `qa` (fatāwā: «سئل/السؤال … الجواب»), `masail` (numbered or «مسألة» entries), `abwab` (kitāb/bāb/faṣl headings), each with receipts and a stability replay | per-text audit in `corpus/audit.json`; excerpt receipts verbatim |
| P0.6 | **A routing index**: encoder → bāb and keyword lexicon, used to retrieve candidate units from R2 texts. This is the IslamQA tranche's retrieval, generalised ([fatawa-oracle](architecture/fatawa-oracle.md): "one agent per encoder") | recall spot-check on a held-out bāb |

### III.3 Phase 1: the lanes (parallel)

Every shard works on its own branch or worktree off **one pinned base commit**, recorded in its plan file. It writes **only new files it owns**, and never regenerates shared outputs. Before handing back it runs the gates locally on its own files: `check_case`, `lake build` of its module, the dossier verbatim check, its slice of `worklist --check`.

| Lane | Shard key | Does (steps) | Size |
|---|---|---|---|
| **A Readings × Ibn Rajab** | ≈5 qawāʿid per shard | S0–S5 on the remaining qawāʿid, exactly as tranches 1–10 | 745 furūʿ / 87 qawāʿid → ≈18 shards; 6 qawāʿid first need segmentation review |
| **B Encoder-routed takhrīj** | one shard per encoder (× source group) | retrieve R2 units by the routing index; S2–S3 against that encoder; a case no encoder fits is recorded as `missing_rule` with its `needs` and not forced | 100 encoders; start with the 20 with the most ikhtilāf, so the cases feed lanes C and E |
| **C Taṣḥīḥ import** | one shard per ledger entry group | S7: verbatim taṣḥīḥ from R3 for the open residues: the 67 tarjīḥ outcomes that go against their reading (across 29 encoders) and the 8 tawaqquf; graded evidence only | 75 entries → ≈8 shards by encoder group |
| **D Side verification** | one shard per tranche file | S7: check every on-madhhab annotation against al-Inṣāf and the muʿtamad; a failure enters 𝔏 | 12 suite files |
| **E Position inventories** | one shard per bāb | R4: attributed positions and ijmāʿ reports for the 260 ikhtilāf cases; additions go to *P* as `revisions`, never edits | ≈10 shards by bāb |
| **F Segmentation** | one shard per R2/R3 text | P0.5 applied per text, with receipts; prerequisite for B, C and E on that text | ≈30 texts |

**Dependencies:**
- F → B, C, E for the texts F opens.
- A and B are independent of each other.
- C, D and E feed 𝔏 and *P* only; they create no readings.

### III.4 Phase 2: the reduce (serial, one integrator)

Integration follows the method's [§5.3](architecture/derivation-method.md#53-integration-serial-one-integrator).

### III.5 Phase 3: review (gated)

The integrator batches the register questions raised by the round: policy points, readings marked uncertain, ijmāʿ conflicts. These go to the Sharīʿah-authority gate. Nothing in Phases 1–2 changes a status beyond `candidate`.

### III.6 Failure modes

The protocol's pre-emptions are in the method's [§5.4](architecture/derivation-method.md#54-failure-modes-the-protocol-pre-empts).

### III.7 Metrics per round

The figures:
- coverage and madhhab coverage, overall and per lane (regenerated);
- encoding errors, which must be 0;
- open gaps, each naming its need;
- revisits made in the round;
- ledger counts (jamʿ / tarjīḥ / tawaqquf / residues);
- IQ questions raised.

For lane B, the share of retrieved units that are real cases, which measures how good the routing index is.

### III.8 First round

1. **Phase 0, P0.1–P0.4.** Refactors only, no new content; they unblock every lane.
2. **Lane A**, 4 shards: the next 20 Ibn Rajab qawāʿid by the worklist's order.
3. **Lane B**, 10 shards: the 10 encoders with the most ikhtilāf. Source groups:
   - *Majmūʿ al-Fatāwā* and *al-Fatāwā al-Kubrā*;
   - *Zād* and *al-Rawḍ*;
   - the Lajna.
4. **Lane C**, 3 shards: the 8 tawaqquf entries, then the residues of qawāʿid 37 and 64–65.
5. **Integration round 1**, then a review batch.

Lanes D, E and F open in round 2. F starts with the fatāwā Q/A segmenter, since lane B's later shards depend on it.
