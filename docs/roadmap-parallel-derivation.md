# Derivation method and the parallel attack on the source texts

The method itself (how a ruling in a text is derived by the kernel, checked, extended and governed) is specified in [`architecture/derivation-method.md`](architecture/derivation-method.md). Part II maps the 138 registered text witnesses (89 of them committed under [`corpus/texts`](../corpus/texts/README.md); 38 are held `cache_only` by the [PR #88 publication audit](architecture/pr88-source-publication-audit-2026-10-15.md)) onto the roles the method knows. Part III plans running the method over them in parallel, with the write isolation and integration discipline the parallel tranche 3 (PRs #31, #32) showed to be necessary.

Nothing here changes a status. Every artifact the plan produces is `candidate`, and every interpretive commitment goes to the review gate ([schemata.md](architecture/schemata.md#governance-where-the-explanations-live-and-why-there)).

---

<!-- BEGIN GENERATED TRACK PATHS -->
**Paths this track owns** (generated from [`roadmap-tracks.json`](roadmap-tracks.json)). A change to one updates this roadmap, or its commit says why not: `Roadmap-Unchanged: <reason>`.

| Under | Paths |
|---|---|
| `.claude/skills/derivation-tranche/` | `**` |
| `docs/architecture/` | `derivation-method.md` |
| `corpus/worklists/` | `**` |
| `corpus/routing/` | `**` |
| `corpus/segmentation/` | `**` |
| `corpus/reconciliation/` | `**` |
| `examples/` | `v41_*.pl` |
| `pipeline/usul_corpus/` | `shards.py`, `r2_sample1.py`, `routing.py`, `units.py`, `typed_routing.py`, `semantic_*.py`, `bank_review.py` |
| `pipeline/tests/` | `test_units.py` |
<!-- END GENERATED TRACK PATHS -->

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
| **R1 Rule sources**: readings (S1) | Ibn Rajab *Taqrīr al-Qawāʿid* (172 furūʿ pending in 10 qawāʿid, 6 qawāʿid needing segmentation; `python -m usul_corpus worklist`); Ibn al-Laḥḥām (M5 commands); Ibn Taymiyya *al-Qawāʿid al-Nūrāniyya*; the qawāʿid stated inside *Iʿlām* and *Badāʾiʿ al-Fawāʾid* | qāʿida + its furūʿ | 𝔅's readings |
| **R2 Case sources**: takhrīj tranches (S2) | **fatāwā:** *Majmūʿ al-Fatāwā* (≈1,800 «وسئل»), *al-Fatāwā al-Kubrā*, *Jāmiʿ al-Masāʾil*, *al-Mustadrak*, *al-Fatḥ al-Rabbānī*, *al-Durar al-Saniyya*, Fatāwā Muḥammad b. Ibrāhīm, the Lajna (≈4,000 Q/A); **mutūn** as compact ruling statements: *Zād al-Mustaqniʿ*, *ʿUmda*, *al-Muqniʿ*, *al-Muḥarrar*, *Muntahā*, *Iqnāʿ*, and al-Shawkānī's *al-Durar al-Bahiyya* (segmented from the *al-Ghurar al-Naqiyya* witness into 128 abwāb and 776 masāʾil) with his own sharḥ *al-Darārī al-Muḍiyya*; **modern citers** (cache-only): Ibn Bāz, Ibn ʿUthaymīn (*Majmūʿ*, *Nūr*, *al-Mumtiʿ*) | one question-answer, or one masʾala | cases for existing encoders; new readings where none fits |
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
- **Done:** P0.1, P0.2 and P0.3 (`pipeline/usul_corpus/shards.py`, method §5.2), and P0.4. Claims have disjoint ownership over the generated worklists (method §5.1). `python -m usul_corpus worklist` (alias `m8-worklist`) regenerates both inventories and `--check` verifies them. The Ibn Rajab inventory is unchanged. The unit inventory `corpus/worklists/units.json` pins each line-segmented witness's records file by sha256 and lists only the annotated ids; pending ids are derived from the pinned file (`units.pending`), and a drifted file is refused. Unit records are therefore claimable obligations (`test_unit_records_are_pending_obligations_a_shard_can_claim`).
- **P0.5, three segmenters done.** `qa` (`pipeline/usul_corpus/qa.py`), configured per work in the registry by two line-start patterns. It emits `fatwa` records: question and answer excerpts within rights, the page span, and the `sha256` receipt of the whole unit. `test_committed_unit_records_replay_from_the_pinned_witness` replays them.
  - Seven collections are segmented, totalling 21,168 units (answered share in brackets): *Majmūʿ al-Fatāwā* 1,847 (0.99), *al-Fatāwā al-Kubrā* 971 (0.80), *Jāmiʿ al-Masāʾil* 122 (0.73), *al-Durar al-Saniyya* 1,651 (0.99), the Lajna 10,437 (0.97), Ibn Bāz 4,597 (0.98), Ibn ʿUthaymīn 1,543 (1.00). Page markers and milestones are stripped wherever they fall in a line.
  - `masail` (`qa.segment_entries`) cuts a *Masāʾil* collection at a line-start opening formula; a named group `n` captures the printed number. It emits `masala` records with the same receipt and replay. Three collections give 5,700 entries: al-Kawsaj 3,575 (numbered 1–3,609: 6 duplicates, 40 numbers missing, listed in `corpus/audit.json`), Abū Dāwūd 1,585 (699 on pages the witness leaves unnumbered, `PageV00P000`), Ḥarb 540.
  - `abwab` (`pipeline/usul_corpus/abwab.py`) cuts a matn into kitāb › bāb › faṣl units, ranking each heading by its first word, not its mARkdown level. It emits `bab` records carrying the rank, the heading, the enclosing kitāb and bāb titles (`path_ar`), the excerpt and the receipt, replayed like the others. Six mutūn give 2,613 units: *Zād* 286, *ʿUmda* 207, *al-Muqniʿ* 631, *al-Muḥarrar* 212, *Muntahā* 383, *al-Iqnāʿ* 894 (ranks per witness in `corpus/audit.json`). Two more give 255: *al-Durar al-Bahiyya* 128, read from its *al-Ghurar al-Naqiyya* witness, which prints its headings as body lines, some numbered (`body_headings`), and its commentary as closing endnotes (cut by `end`), and *al-Darārī al-Muḍiyya* 127. A unit routes a masʾala to its bāb. The *Durar*'s units are also split into their **776 masāʾil** (`masail`: the edition prints one per line), each a `masala` record `…b<unit>.m<n>` after its bāb record. Its masāʾil, not its units, are the obligations; the bāb records stay routing targets. Splitting the other mutūn into masāʾil is the next step for R2.
  - **The masāʾil path**, end to end. `build` (`cmd_build` → `_segment` in `pipeline/usul_corpus/__main__.py`) takes each witness's segmenter from `units.segmenter_of` (the witness's own, else its work's). `units.unit_records` cuts the text with `abwab.segment_abwab` and writes each unit as a `records.bab_record`. Under `masail: true`, each unit is followed by one `records.unit_masala_record` per masʾala that `abwab.split_masail` cuts from it. The records go to `corpus/records/<witness>.jsonl`, and `unit_audit` counts units and masāʾil apart in `corpus/audit.json`. `units._obligations` makes a split unit's masāʾil, not the unit, the obligations, for `worklist` (`corpus/worklists/units.json`) and `routing` (`corpus/routing/`). Owners, per [`roadmap-tracks.json`](roadmap-tracks.json): `abwab.py`, `records.py`, `tests/test_abwab.py` and `corpus/records/**` belong to uṣūl; `units.py`, `tests/test_units.py`, the worklists and the routing belong to derivation; the CLI is shared. A change along the path updates both roadmaps, or carries `Roadmap-Unchanged`.
  - *Nūr ʿalā al-Darb*: Ibn Bāz 7,607 units by «س:/ج:» (0.997), Ibn ʿUthaymīn 7,448 (0.997). Ibn ʿUthaymīn's witness prints each question as a section heading with no marker word, so `qa` takes `question_heading`; follow-ups inside an episode open with «فضيلة الشيخ:».
  - Fatāwā Muḥammad b. Ibrāhīm is letters, not Q/A, but the collection numbers them: `masail` with `ordered` opens entries only at the longest increasing run of printed numbers, so a letter's own enumeration and reference numbers stay in its text. 3,974 entries numbered 1–4,575, no duplicates; of the 601 missing numbers, most never occur at a line start in the witness.
  - In *al-Kubrā* and *Jāmiʿ*, many answers begin without a «الجواب» marker. Their unanswered units keep only the question header, so they wait for review rather than absorbing text.
- **Open:**
  - joining al-Irwāʾ to the `masala`, `fatwa` and `bab` records. `hadith.JOIN_TYPES` holds the join to the reviewed types; widening it proposes 1,351 masāʾil candidates, which are a review tranche of their own;
  - P0.6's transfer gap: routing modern questions (below) is far weaker than routing classical furūʿ; profiles need modern evidence, i.e. lane B's first annotated fatāwā;
  - validating the encoder → bāb assignments, which nothing measures yet.
- **Routing by type, not by wording (human instruction, 2026-10-11): the type system is Lean.** Encoders are typed, so whether a text falls under an encoder is a typing question: does the situation it describes inhabit the encoder's fact signature? The wording, classical or modern, then stops being the limit. The types, signatures and laws are declared and proved in Lean (`formal/lean/Usul/Typing.lean`). The executable mirror is Prolog, generated from the kernel, with no Python in between (human instruction, 2026-10-11). The lexical index is the baseline to beat.
  - **Where it started.** The 104 encoders read 167 facts under 144 local names: 147 are bare `Bool` propositions, and only `Usul.Grade` and `Option Usul.Hukm` are read by more than one fact. There was no common type.
  - **T1, done: the framework and a first slice.**
    - `Usul.Typing.Typed S O` is an encoder typed over situations `S`, ruling in `O`. It has `proj : S → Option Local`, `embed`, the law `proj_embed`, and `run`, which is the existing kernel function, so typing changes no ruling.
    - `applies` is the typing judgement and `judge` the ruling. `judge_embed`, `applies_embed` and `applies_iff_judge` are proved once for every encoder.
    - **The qawāʿid define the types (human instruction, 2026-10-11).** Each qāʿida's statement ranges over certain facts, and `Usul.Typing.Qaida` holds a structure per qāʿida with exactly those facts, each `Option` until a text settles it:
      - `Yaqin` (al-Saʿdī Q11), and `Qarain` (Q52), which extends it;
      - `ItlafHal` (Q13) and `ItlafQasd` (Q36);
      - `Amana` (Q14);
      - `ZannError` (Ibn Rajab Q6).

      `Usul.Typing.Situation` is their join. A field is shared only where qawāʿid state the same notion, and Lean checks that a field merged through `extends` has one type.
    - Five encoders are typed so far: `itlaf` (Q13 ⊔ Q36), `trust_loss` and `trust_voidance` (Q14), `excused_error` (Ibn Rajab Q6), and `asl_zahir` (Q52 ⊒ Q11).
    - The theorems:
      - `transgression_is_shared`: Q14 types both trust encoders;
      - `negligence_is_qualified`: Q14's «يفرط» (in safekeeping) is not Ibn Rajab Q6's «فرط بترك البحث» (in inquiry);
      - `itlaf_reads_two_qawaid`: the purpose alone leaves a missing fact;
      - `qarain_extends_yaqin`.
    - **The Prolog mirror.** `formal/lean/scripts/ExportTypes.lean` reads the type system from the kernel's own declarations. It writes `examples/v41_types.pl`, containing:
      - the qāʿida types with their statements, `extends` parents and fields;
      - each typed encoder's output type, and the fields its elaborated `proj` reads, in order.

      `make lean` regenerates it and fails if it is stale. `examples/v41_typing.pl` runs the typing judgement on situations stated as `sit/3`: `applies`, `missing_fact`, `route`, `shares`, `field_of` and `ill_typed`. `examples/v41_typing_fixtures.pl` restates the Lean theorems as fixture vectors (`tests/run_all.sh`), and `tests/mutation_test.sh` kills a mutant of each typing guard. A typed encoder's ruling is its existing kernel function (`run`), so typing changes no ruling by construction.
  - **T2, done: all 104 encoders are typed.** Each fact goes into the type of the qāʿida that states it (`Usul.Typing.Qaida`, `formal/lean/Usul/Typing/Qaida.lean`): 85 types. Where a Lean doc says one qāʿida is an instance of another, the type extends it.
    - The first slice covered al-Saʿdī Q11, Q20 and Q28 with their Ibn Rajab qawāʿid: `MajhulHaqq`, `MajhulMadum` and its extensions `Luqata` and `Istihlak`, `Badal` and its extensions `BadalWujub` and `Intiqal`, `Itizal`, `NiyyaMansiyya`, `ShakkShart` and `Rukhsa`.
    - The other 88 encoders (`formal/lean/Usul/Typing/Encoders.lean`) read types named by their qāʿida (`Sadi35`, `Rajab64`, `Lahham43`, …), each documented with the qāʿida's statement quoted from the committed records. Ibn Rajab 22's and 68's new encoders read `Khalt` (extending `Istihlak`) and `ShakkShartFuru` (extending `ShakkShart`).
    - Unrelated qawāʿid that use one word get qualified fields, because Lean merges same-named parent fields:
      - `mixedSameKind` (Ibn Rajab 22) / `actsSameKind` (Q41);
      - `commandForm` (Ibn al-Laḥḥām 43) / `nounForm` (Q59);
      - `acquisitionNecessity` (Ibn Rajab 50) / `necessity` (Ibn Rajab 7);
      - each command schema's `…Reading`.

      `unrelated_shared_field` in `examples/v41_typing.pl` flags any field two types declare when neither extends the other, and a fixture requires there be none.
    - `test_every_encoder_is_typed_with_its_arity` checks the Lean export against the registry: a new encoder lands typed or not at all.
    - Theorems: `original_possibility_is_shared` (Q28 types both substitute encoders over one field), `luqata_extends_majhul`.
  - **Identifications and relations (human decision, 2026-10-11).** Five pairs of facts stated at two levels were decided as follows:
    - **Identified:** Ibn Rajab 68's «غلبة ظن» is Q11's ẓāhir graded at least ẓann (`Grade.IsYaqin`). `ShakkShart` has no `ghalaba` field, and `doubt_in_condition` reads `zahir` (`proj_embed` by cases).
    - **Related**, by `Implication`s in `Usul.Typing.Relations`, in the direction the texts give:
      - 68.f001 ⇒ 68 (`rukhsaNeedsFirm`);
      - the luqaṭa year ⇒ 106's despair (`yearDespair`);
      - Q20 ⇔ 106's unknown ∧ despaired (`unidentifiedIsMajhul`, `majhulIsUnidentified`, `knownIsIdentified`, `hopedIsIdentified`);
      - consumed (22) ⇒ 106 (`consumedIsMajhul`).

      `saturate` fills an implied field only where a situation leaves it open; a stated fact is never overridden (`stated_fact_kept`). Chains settle (`consumed_is_unidentified`). The fifth relation is what the kernel already assumed: `istihlak_agrees` proves 106's encoder on the saturated situation rules as `istihlak` does. The export carries the relations as `implies/3`; Prolog's tabled `holds/3` mirrors `saturate`, with fixture vectors and two mutants killed.
  - **T3, done on the IslamQA tranche: typing as routing.** Four agents typed the tranche's 53 answers blind, seeing only the texts and a field catalogue generated from the Lean export, never the encoder labels: 138 situations, 179 fields, each with a verbatim quote of at most 160 characters (`corpus/typing/islamqa_tranche1_situations.json`, candidate).
    - A first pass exposed a catalogue bug: `yaqin`'s grades had been matched by short name to `Usul.Reconcile.Grade`. The exporter now emits each field type's constructors from the kernel (`type_value/2`), the test checks every value against them, and the agents revisited those fields.
    - `python -m usul_corpus typed-routing` writes the situations as `sit/3` (`examples/v41_islamqa_situations.pl`) and routes them through the Prolog typing rules, relations included. Encoders are ranked by `coverage/4`, the share of their fields a situation settles, with ties counted against the true encoder.
  - **T4, measured** (`corpus/typing/islamqa_tranche1_report.json`, 123 cases). Recall@1/5/10 by type is 0.30 / 0.69 / 0.69, against 0.09 / 0.29 / 0.35 lexical on the same cases. The true encoder applies outright (every field settled) in 0.36 of cases. Routing is selective: an answer touches 2.1 of the 104 encoders on average, and 0.51 apply in full.
    - **The finding is itlāf:** 25 of its 27 cases are unrouted. Its type is Q13 ⊔ Q36 (state of mind, purpose), but these answers (accidents, damage) turn on causation and fault: the mubāshir and the mutasabbib, the facts the v4.0 oracle reads. The type system lacks the qāʿida type those texts inhabit. Outside itlāf, the true encoder ranks in the top 5 for 83 of 96 cases.
    - **Causation, decided from the sources and the method (2026-10-12).** None of the 27 itlāf cases is derivable: the tranche left them as gaps, 9 of them `rule:mubashara_tasabbub`. Ibn Rajab's qāʿida 127 states that rule over itlāf itself: «إذا استند إتلاف … إلى مباشرة وسبب تعلق الضمان بالمباشرة دون السبب إلا إذا كانت المباشرة مبنية على السبب وناشئة عنه». The v4.0 oracle's causation rules cite the Majalla and unattributed maxims, not the corpus. So:
      - itlāf's type and reading are unchanged;
      - Q127 gets its own reading (`Usul.Readings.Mubashara.damanOn`, three divisions instanced by its furūʿ f000, f003, f005, linked to Q13) and encoder (`mubashara_tasabbub`);
      - its type extends itlāf's (`Usul.Typing.Qaida.Mubashara`);
      - a dossier entry closes the named need;
      - a cause with no direct act is outside its statement and stays a gap.
    - **Q127's own furūʿ, annotated (2026-10-14, shard rajab-q127).** The bank was applied to its nine furūʿ: five are derivable (f000–f002 direct, f003 cause alone, f007 shared). Four are ikhtilāf:
      - f004 (the coerced destroyer) is on the madhhab side, per al-Iqnāʿ «وإن أكره على إتلافه ضمنه مكرهه».
      - f005 (the holder with the killer) and f006 (the stone beside the well) land against it. al-Inṣāf makes the direct actor's, and the placer's, alone the madhhab, and al-Iqnāʿ states both. Both enter the ledger with that evidence.
      - f008 (game held in iḥrām, killed by another) has al-Qāḍī's two iḥtimālāt and no stated side. It enters the ledger at tawaqquf.

      f006's roles follow Ibn Rajab's own classing of its companion case («وهي من صور القسم الثاني»).
    - **Re-measured.** All answers were re-typed blind for Q127's two fields; labels are not rewritten.
      - Of the 9 cases that named the rule, 7 now rank it in the top 3 (6 were unrouted before); 348122's two cases settle none of its fields.
      - With tranche-named rules counted, recall@5 is 0.74 (from 0.69).
      - Modern texts rarely settle whether a direct act arose from another's cause: `arising_from_sabab` was stated twice in 53 answers.
    - **The shards' encoders typed (2026-10-14).** The parallel shards RajabA1–A12 added 55 encoders on Ibn Rajab 53–118, typed the same way: 38 new qāʿida types, Lean-inferred fact types, statements quoted from the records. That makes 160 encoders over 124 types.
      - Six names collide with unrelated qawāʿid's fields and are qualified by qāʿida number: `bindingQ69`, `necessityQ71`, `bindingContractQ72`, `negligentQ95`, `harmlessQ99`, `financialQ110`.
      - Three looked like notions already typed. They were decided from the texts (2026-10-14), by the rule of the five before: identify only where one type builds on the other, otherwise relate in the texts' direction.
        - **95's negligence is 6's, both ways.** 95 explains its «لتفريطه» as «تركه الفحص عن حاله تفريط»; 6 has «فرط بترك البحث والتحقيق». Both concern one who acted on a presumption later shown wrong. Neither qāʿida builds on the other, so the fields stay apart, related at both values (`q95IsInquiry…`, `inquiryIsQ95…`).
        - **97 ⇒ 106 on despair.** 97 rests its despair of the absent owner's return on the mafqūd, whose life is presumed (106: «وإن كان الأصل بقاءه»), and its furūʿ say «وأيس من الاطلاع عليه». 106's despair is wider (the mustaḥāḍa's blood), so the relation runs one way, at both values (`despairedIsDespair`, `hopedIsNotDespair`).
        - **97's known owner is 98's owner not unknown, and 98 ⇒ 106 on the unknown.** 97 says «وإن لم يعرف مالكه بل جهل», 98 «إذا جهل ربه», so the two are related both ways, negated. 98's unknown owner is an instance of 106's unknown, as 106.f002 «لجهالة ربها» is. 106's unknown is wider, so the relation is one-way and only when unknown (`unknownOwnerIsMajhul`). 97's despaired-of owner is known, so 106's unknown stays open (`q97_despair_is_106`).

        Theorems `q95_negligence_is_inquiry`, `q97_despair_is_106`, `q97_unknown_owner_is_unidentified` and `q98_owner_is_106_unknown` are proved by `decide`; the Prolog fixtures mirror them. Recall on both sets is unchanged.
      - Typed routing on the IslamQA set is unchanged. The lexical baseline, refitted over 160 encoders, falls to 0.00 / 0.24 / 0.33.
    - **Shards RajabA13–A16 typed (2026-10-14, at the merge of main).** Their 16 encoders on Ibn Rajab 119–131 are typed the same way: 12 new qāʿida types, statements quoted from the records. That makes 176 encoders over 136 types.
      - Two names collide with unrelated qawāʿid's fields and are qualified: `intendedQ126` (Lahham 43's `intended` is a ruling) and `neededQ130` (99's `needed` is the community's need for the thing).
      - No relation was added. Three look-alikes are left for review: 124's prompting cause and Lahham 61's `inOccasion`; 121's ʿurf classes and 122's `customaryUsage`; 130's need and 99's.
      - Fold 0 gains these shards' 17 cases (156 in all). They were typed by an agent that had seen their annotations, so not blind. Recall@1 / 5 / 10 on the classical set: typed 0.56 / 0.72 / 0.72, lexical 0.61 / 0.85 / 0.88, hybrid 0.73 / 0.95 / 0.96. On IslamQA the lexical baseline over 176 encoders is 0.00 / 0.22 / 0.31 and the hybrid 0.52 / 0.69 / 0.76.
    - **Classical units (2026-10-14).** Fold 0 of the routing index's held-out split (139 Ibn Rajab and Ibn al-Laḥḥām furūʿ) was typed blind under opaque ids, because record ids name the qāʿida: 187 situations, 210 fields (`corpus/typing/rajab_fold0_situations.json`). The lexical baseline is the index refitted without that fold. `typed_routing.TestSet` carries both sets; each report gives typed, lexical, prior and hybrid recall on the same cases.

      | Recall@1 / 5 / 10 | typed | lexical | **types first, words breaking ties** |
      |---|---|---|---|
      | classical furūʿ (139) | 0.55 / 0.73 / 0.73 | 0.61 / 0.86 / 0.88 | **0.70 / 0.94 / 0.96** |
      | modern fatāwā (123) | 0.30 / 0.69 / 0.69 | 0.00 / 0.24 / 0.33 | **0.52 / 0.69 / 0.74** |

      Types and words fail on different cases. On classical text, words alone are strong in-domain (the profiles were fitted on the same book) but types decide where a farʿ settles its qāʿida's facts. On modern text, words carry nothing and types carry the routing. The routing rule for lane B is therefore the hybrid: encoders by the share of their fields a situation settles, then lexical rank. It beats either alone on both sets.
    - **R2 routed by the hybrid, on a sample (2026-10-14).** The hybrid needs typed situations, and no R2 unit was typed, so it was applied to a deterministic sample: per witness, the pending records whose ids hash lowest. That gives 10 from each of the Masāʾil of Abū Dāwūd, Ḥarb and al-Kawsaj, and 5 bābs from each of Zād and al-ʿUmda (`typed_routing.PROPOSALS`, `r2_sample1`). Two agents typed them blind under opaque ids: 19 situations, 17 fields.
      - 11 of the 40 settle a field, over 14 encoders. Examples: Barīra's choice routes to `other_option_stands`, and tayammum when the time runs short to `substitute`.
      - The other 29 (ḥadīth, ādāb, ʿibādāt details) get the lexical order alone.
      - `corpus/routing/r2_sample1_proposals.json` holds each unit's first five encoders as a lane-B proposal, not a ruling. `ProposalSet` reproduces the draw, and a test holds it to pending units.
    - **Next:** widen the R2 sample by the same draw, then annotate the proposals in lane B. Then repeat T3 on classical units (mutūn bābs, Masāʾil entries), where the routing index's lexical profiles were strong.
- **P0.6 done, as a ranker:** `python -m usul_corpus routing` writes `corpus/routing/index.json`. Profiles are derived from the bank's evidence, never written: each of the 100 encoders gets the TF-IDF centroid of the records its annotated cases rest on plus its own qawāʿid, with words found in over 10 % of the evidence dropped. Per encoder the index gives its case support, its lexicon (the heaviest profile words) and its nearest matn units.
  - **Held-out cases** (1216 cases, 5 folds; true category in the top 1 / 5 / 10, against ranking by frequency under the same split; audit PR-38). Since round 7 the label is the case's *category*, the qāʿida type its encoder reads, which the anwāʿ of one typology share; the typed facts choose the nawʿ (audit PR-48). Per-encoder recall is reported beside it:
    - **By qāʿida** (headline: whole qawāʿid held out, their formalised statements kept): 0.30 / 0.48 / 0.57, prior 0.00 / 0.00 / 0.00; per encoder 0.27 / 0.46 / 0.55. Before round 7, over 1044 cases and per encoder: 0.29 / 0.51 / 0.59.
    - **Within qāʿida** (folds by record-id hash, so a test farʿ's siblings train the model): 0.57 / 0.81 / 0.87, prior 0.04 / 0.13 / 0.19; per encoder 0.51 / 0.79 / 0.85.
    - **Unseen qāʿida** (its statement held out too): 0.01 / 0.02 / 0.03, prior 0.00 / 0.00 / 0.00. The index does not route a qāʿida the bank has not formalised.
  - **Out-of-domain** (`corpus/routing/ood.json`, the 123 IslamQA tranche cases, title and question): by category 0.02 / 0.16 / 0.20, per encoder 0.00 / 0.21 / 0.28, against the prior's 0.00 / 0.22 / 0.22: no better than frequency. The stopword share was chosen on the held-out folds, not on this set.
  - 13 encoders have no annotated case and route by their qawāʿid alone.

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
| **A Readings × Ibn Rajab** | ≈5 qawāʿid per shard | S0–S5 on the remaining qawāʿid, exactly as tranches 1–10 | 172 furūʿ / 10 qawāʿid → ≈2 shards; 6 qawāʿid first need segmentation review (rounds 1–4 done: 16 shards, 50 qawāʿid, 349 furūʿ; Q127 by rajab-q127) |
| **B Encoder-routed takhrīj** | one shard per encoder (× source group) | retrieve R2 units by the routing index; S2–S3 against that encoder; a case no encoder fits is recorded as `missing_rule` with its `needs` and not forced | 100 encoders; start with the 20 with the most ikhtilāf, so the cases feed lanes C and E |
| **C Taṣḥīḥ import** | one shard per ledger entry group | S7: verbatim taṣḥīḥ from R3 for the open residues: the 73 tarjīḥ outcomes that go against their reading (across 32 encoders) and the 9 tawaqquf; graded evidence only | 82 entries → ≈8 shards by encoder group |
| **D Side verification** | one shard per tranche file | S7: check every on-madhhab annotation against al-Inṣāf and the muʿtamad; a failure enters 𝔏 with a `side_check` | **done** for all 12 suites (tranches 10–11 in their own PRs; tranches 1–9 and al-Saʿdī's: 100 cases, 6 failed) |
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
- coverage, decided coverage and the disputed count, overall and per lane (regenerated);
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

### R2 sample 1 lane B semantic triage (2026-10-14)

The 40-unit candidate tranche has source/segmentation receipts and individual proposal audits; see [r2-sample1-lane-b](architecture/r2-sample1-lane-b.md) and the generated `corpus/routing/r2_sample1_lane_b_report.json`. Scoped component guards do not establish whole-unit routing labels. Harb chronological precedence does not fill the simultaneous-combination encoder's structural priority field. Named rule/fact gaps, five incomplete page locators, three finer-boundary reviews, pending disagreements, and later al-Insaf/mutamad verification remain explicit. Continue lane A/F/C work on these needs; do not describe this triage as completed S0–S9 closure.
