# Derivation method and the parallel attack on the source texts

Part I distils the method the bank has used since M4: how a ruling in a text is derived by the kernel, and how that claim is checked, extended and governed. It cites the commits and documents where each rule was established. Part II maps the 117 cached witnesses (89 of them committed under [`corpus/texts`](../corpus/texts/README.md)) onto the roles the method knows. Part III plans running the method over them in parallel, with the write isolation and integration discipline the parallel tranche 3 (PRs #31, #32) showed to be necessary.

Nothing here changes a status. Every artifact the plan produces is `candidate`, and every interpretive commitment goes to the review gate ([schemata.md](architecture/schemata.md#governance-where-the-explanations-live-and-why-there)).

---

## Part I: the derivation method

### I.1 Objects

| Symbol | Object | Where it lives |
|---|---|---|
| *W* | a pinned witness: commit/book id, sha256 | `corpus/registry.json`, `corpus/lock.json`, `corpus/texts/` |
| *u* | a unit: a segmented record of *W* with a locator and an excerpt receipt | `corpus/records/*.jsonl` |
| ρ | a **reading**: a qāʿida's own statement formalised. It has fact fields *F*<sub>ρ</sub> with finite domains, a Lean expression κ<sub>ρ</sub>, a Python mirror *m*<sub>ρ</sub>, and link theorems into the bank | `Usul.Refinements` and the other `Usul.*` modules; `takhrij.ENCODERS` |
| *c* | a **case**: (*u*, ρ, φ, *r*, *P*, class, `matches_madhhab`, `needs`, `home`, `revisit`). φ ∈ ∏ dom(*F*<sub>ρ</sub>) are the facts, *r* is the ruling the text states, *P* the reported positions | `corpus/takhrij/*.json`, `corpus/fatawa/takhrij/*.json` |
| 𝔅 | the **bank**: all readings and cases, plus the gap ledger (`needs` / `provides`) | the above, with `corpus/takhrij/report.json` |
| 𝔏 | the **reconciliation ledger**: one graded evidence set per apparent contradiction | `corpus/reconciliation/ledger.json` |

### I.2 The derivation judgement

A case is classified by what the kernel computes from its facts, κ<sub>ρ</sub>(φ). [takhrij.md](architecture/takhrij.md#classes) gives the classes:

| Class | Condition | Lean witness |
|---|---|---|
| derivable | φ ⊆ *F*<sub>ρ</sub> decides it and κ<sub>ρ</sub>(φ) = *r* | `#guard expr == r` |
| genuine ikhtilāf | \|*P*\| ≥ 2 and κ<sub>ρ</sub>(φ) ∈ *P* (`matches_madhhab` says whether it is the madhhab's side) | `#guard expr == p` |
| encoding error | the case is fully expressible and κ<sub>ρ</sub>(φ) ∉ *P* | `#guard expr != r` |
| missing fact / missing rule | decided by a fact ∉ *F*<sub>ρ</sub> / by another principle; carries `needs: fact:… \| rule:…` | none (a gap) |
| segmentation error | *u* is not a case | excluded |

Coverage and madhhab coverage are defined as follows:

    cov = (derivable + ikhtilāf) / (total − segmentation errors)
    cov_m = (derivable + ikhtilāf on the madhhab side) / (total − segmentation errors)

**Lean is the oracle, not the annotation** (takhrij.md §"Lean is the oracle").
- `UsulTest/TakhrijMirror.lean` checks the mirror against κ on every input, exhaustively.
- `UsulTest/Takhrij.lean` checks every claim.
- `check_case` rejects malformed cases before any Lean is generated (`takhrij.py:486-509`).

A case claimed derivable that the kernel does not derive fails the build.

### I.3 The tranche procedure (S0–S9)

Each step names its gate; a step's output is only usable once its gate passes. This is the procedure M8 tranches 1–10 followed (commits `4c9624c` … `78309e7`).

| Step | Does | Gate |
|---|---|---|
| **S0 Pin and segment** | fix *W* (lock sha256); segment it into units with stable ids and receipts; inventory the obligations (every unit to be annotated exactly once, `.f000` included) | lock check; `m8-worklist --check` (duplicate/orphan ids, count and input-hash drift); a segmentation-stability replay (m8-tranche3-reconciliation §segmentation) |
| **S1 Read** | formalise each selected qāʿida from its *own statement* as a reading ρ, with link theorems to existing principles (`child_is_part`, `q20_is_instance`, …) | `lake build`, no `sorry`; `signature` `#check`s every named constant |
| **S2 Annotate** | for every unit: facts φ, stated ruling *r*, positions *P* with attributions, class, `needs` on gaps. LLM-assisted, status `candidate` | `check_case` |
| **S3 Guard** | regenerate `Takhrij.lean`, `TakhrijMirror.lean`, `report.json` (`python -m usul_corpus takhrij`) | `lake build`; test: generated files in sync |
| **S4 Apply the bank to itself** | every gap whose needs 𝔅 now `provides` is revisited. A closure is either a **conservative refinement** of the encoder it had (a default that gives back the earlier reading, proved by `*_conservative`, existing cases migrated) or a **new reading beside** the old ones; history kept in `revisit{from_class, from_encoder, closed_by}` | `test_bank_is_applied_to_itself` (revisit queue empty, mutation-checked); `test_refinement_closures_are_conservative` |
| **S5 Cite** | a dossier entry per closure: statement, verbatim excerpts, conditions, rationale, Lean constants, conservativity theorem | `test_dossier.py`: excerpts letters-only verbatim against the cache, page from the next marker, every constant `#check`ed, every term a glossary key |
| **S6 Reconcile** | every ikhtilāf with `matches_madhhab = false` enters 𝔏 with graded evidence (taṣḥīḥ ≻ naṣṣ ≻ ẓāhir ≻ qiyās ≻ jazm ≻ aṣḥāb ≻ takhrīj ≻ wajh), resolved by the kernel's own procedure **jamʿ → naskh → tarjīḥ → tawaqquf** (`Usul.Reconcile`, `Usul.resolve`) | `reconcile.check` (`reconcile.py:81-122`): every candidate is in the ledger; one grade per position; a jamʿ needs a conservative refinement that lands on the prevailing side and actually moves something |
| **S7 Import the later taṣḥīḥ and verify the sides** | verbatim evidence from al-Inṣāf, Taṣḥīḥ al-Furūʿ, the Muntahā/Iqnāʿ with al-Buhūtī (`30db5c5`); re-check every on-madhhab annotation against al-Inṣāf and the muʿtamad (`78309e7`) | `test_evidence_is_verbatim`; a failed side check enters 𝔏 instead of being edited |
| **S8 Regenerate** | report, worklist, docs, signature; never sum counts by hand | `make all` = test, validate, generated (signature, reconcile, worklist check, `git diff --exit-code`), lean, tla; Prolog fixtures |
| **S9 Govern** | everything stays `candidate`; policy points (a side of an uṣūl dispute, a ranking) go to the IQ register, never into a refinement | `Review.tla` (`LLMPropose` reaches only `candidate`; `AcceptedWasReviewed`, `SupportIsAccepted`); `Usul.Process.never_adopts` |

**Exit per tranche:**
- 0 encoding errors;
- every unit classified and linked (none silently patched);
- the revisit queue empty;
- the ledger checked;
- coverage figures regenerated.

The roadmap's M4 and M8 exits (roadmap §M4, §M8) are this conjunction.

### I.4 Invariants

These are the rules the history enforced, each after a failure it fixed:

1. **Readings come from the qāʿida's own words.** A reading is formalised from the statement that grounds it, and its dossier excerpt is verbatim.
2. **Conservativity.** A refinement of an existing encoder has a default equal to the earlier reading, proved in Lean. Otherwise the principle is a *new* reading beside the old ones. No earlier guard changes meaning.
3. **Supersede, never rewrite.** Revisits, `revisions` (receipt hash → current hash) and ledger entries keep history. "Annotations are never rewritten from here" (taarud-reconciliation.md §review).
4. **Ledger closure.** An extension cannot land while a gap it could close is unrevisited.
5. **Exactly-once inventory.** Every obligation id is annotated once. Ids are disjoint across contributors, and their union is the inventory.
6. **Regenerate, don't sum.** Totals are rebuilt from the merged tree (`f927fb1`, `ed283bf`/`861de80`).
7. **Gaps name their need, and are not invented.** A case that a reading should cover gets a reading, not a new gap (`ed283bf`). Need tags are corrected on revisit when the text names another principle.
8. **Policy points stay open** (43.f004). Pinning the alternatives so they are expressible is allowed; choosing one is not.
9. **Apply the bank before asking the owner** (D3 `d21241e`, D5 `5cfbe02`). A question reaches a human only after the bank's own procedure leaves it open.
10. **Rights.** Pre-modern excerpts may run to 400 characters; modern ones are capped at 160 characters and their contexts stay in `.cache`.

### I.5 The method as a fixed point

One tranche is a monotone step on the bank.

    𝔅ₙ₊₁ = reconcile(selfapply(guard(annotate(read(𝔅ₙ, Qₙ), Uₙ))))

Qₙ is the tranche's qawāʿid and Uₙ its units.
- Readings are only added, or refined conservatively, so every earlier derivable or ikhtilāf guard stays true.
- `selfapply` iterates to a fixed point: the revisit queue is empty.
- `reconcile` is the kernel's own `resolve`, whose order is proved (`resolve_jam_first`, `resolve_naskh_before_tarjih`).

The quantities that must not regress are the encoding errors (= 0), the guards (all hold) and the open gaps (only ones that name their need). Coverage figures are reported, not optimised. A refinement that raises madhhab coverage by picking a side of a policy point is barred by invariant 8.

This fixed-point form is what makes parallelism possible. Within a phase, every shard's step reads the same base bank and only *adds* to it. The serial reduce (`selfapply` and `reconcile` over the union) is where shards interact.

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

**Ijmāʿ is a policy point.** A reported ijmāʿ that contradicts κ<sub>ρ</sub>(φ) could be read as an encoding error, or graded as evidence above taṣḥīḥ. Ijmāʿ reports are themselves disputed (Ibn Taymiyya's *Naqd Marātib al-Ijmāʿ*). Until the register decides, ijmāʿ items enter 𝔏 as evidence and change no class (IQ, invariant 8).

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

An integration round merges a batch of finished shards in a fixed order (by lane, then shard id):

1. **Verify each contribution against its plan.** Base commit; case `sha256` per id; ids ⊆ owned obligations; disjoint union (the tranche-3 consolidation rules).
2. **Resolve collisions.**
   - *Duplicate principle* (two shards formalised the same statement): keep both and prove them equivalent, or retire one through `revisions`.
   - *Name clash*: shard namespaces make this a build error, not a silent overwrite.
3. **Regenerate everything once.** Run `takhrij`, `reconcile`, `worklist`, `docs`, `signature`.
4. **Self-apply across shards.** The revisit queue now sees the union: a principle formalised in shard *i* may close a gap recorded in shard *j*. Closures are made here, with dossier entries, and only here.
5. **Reconcile over the union.** New off-madhhab cases from lanes A and B meet the evidence from C and E.
6. **Run `make all`.** Report the round's figures (regenerated), the ledger counts, and the IQ questions raised.

### III.5 Phase 3: review (gated)

The integrator batches the register questions raised by the round: policy points, readings marked uncertain, ijmāʿ conflicts. These go to the Sharīʿah-authority gate. Nothing in Phases 1–2 changes a status beyond `candidate`.

### III.6 Failure modes and how the plan pre-empts them

| Failure (commit that fixed it) | Pre-emption |
|---|---|
| opening examples / `.f000` missed; inline lists and nested duals (`f927fb1`, tranche-3 audit) | lane F audits per text with a stability replay; obligations include `.f000` |
| counts stated by hand, then stale (`f927fb1`, `ed283bf`) | only the integrator regenerates; shard reports carry no totals |
| evidence graded against different facts; counts drifted; double-counted sources (`4560abd`, `6f28b8d`) | `reconcile.check` per round; lane C writes evidence only, with a verbatim receipt |
| a fact the encoder should not take; distinct mixtures merged; a closure on the wrong fact (`78309e7`, `9e0276a`) | `check_case` and the exhaustive mirror per shard; lane D re-verifies sides |
| a new gap where a reading was due (`ed283bf`) | lane B records `missing_rule` with `needs`; deciding that a reading is due is lane A's job at integration (invariant 7) |
| oracle gaps passing vacuously (`3da8400`) | gaps must be oracle answers in the Prolog fixtures; no vacuous pass |
| lexical false cues («تركيب» → «ترك»; plurals) (`5bd2c90`) | the routing index is recall-oriented, and every retrieved unit is read, never auto-classed |
| a stale shared file written back (`lock.json`, #55) | shards never write shared generated files; `fetch` re-reads the lock before writing (#55) |

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
