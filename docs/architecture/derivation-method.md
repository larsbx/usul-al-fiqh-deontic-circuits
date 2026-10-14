# The derivation method

This is how the bank derives a ruling stated in a text from its formal readings, and how that claim is checked, extended and governed. It was not designed up front: it is the procedure the bank converged on over M4 (rounds 1–5) and M8 (tranches 1–10), recorded here as one specification. Each step and invariant names the commit or document where it was established.

Three records keep it current:
- **This document**, which specifies the method.
- **[`.claude/skills/derivation-tranche/SKILL.md`](../../.claude/skills/derivation-tranche/SKILL.md)**, the operating procedure an agent follows for one shard or one integration round.
- **`test_method_names_resolve`**, which fails if a test, CLI command, module or file named here or in the skill no longer exists.

The plan that applies the method to the source texts is [`roadmap-parallel-derivation.md`](../roadmap-parallel-derivation.md).

## 1. Objects

| Symbol | Object | Where it lives |
|---|---|---|
| *W* | a pinned witness: commit/book id, sha256 | `corpus/registry.json`, `corpus/lock.json`, `corpus/texts/` |
| *u* | a unit: a segmented record of *W* with a locator and an excerpt receipt | `corpus/records/*.jsonl` |
| ρ | a **reading**: a qāʿida's own statement formalised. It has fact fields *F*<sub>ρ</sub> with finite domains, a Lean expression κ<sub>ρ</sub>, a Python mirror *m*<sub>ρ</sub>, and link theorems into the bank | `Usul.Refinements` and the other `Usul.*` modules; `takhrij.ENCODERS` |
| *c* | a **case**: (*u*, ρ, φ, *r*, *P*, class, `matches_madhhab`, `needs`, `home`, `revisit`). φ ∈ ∏ dom(*F*<sub>ρ</sub>) are the facts, *r* is the ruling the text states, *P* the reported positions | `corpus/takhrij/*.json`, `corpus/fatawa/takhrij/*.json` |
| 𝔅 | the **bank**: all readings and cases, plus the gap ledger (`needs` / `provides`) | the above, with `corpus/takhrij/report.json` |
| 𝔏 | the **reconciliation ledger**: one graded evidence set per apparent contradiction | `corpus/reconciliation/ledger.json` |

## 2. The derivation judgement

A case is classified by what the kernel computes from its facts, κ<sub>ρ</sub>(φ). [takhrij.md](takhrij.md#classes) gives the classes:

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

## 3. The tranche procedure (S0–S9)

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

## 4. Invariants

These are the rules the history enforced, each after a failure it fixed:

1. **Readings come from the qāʿida's own words.** A reading is formalised from the statement that grounds it, and its dossier excerpt is verbatim.
2. **Conservativity.** A refinement of an existing encoder has a default equal to the earlier reading, proved in Lean. Otherwise the principle is a *new* reading beside the old ones. No earlier guard changes meaning.
3. **Supersede, never rewrite.** Revisits, `revisions` (receipt hash → current hash) and ledger entries keep history. "Annotations are never rewritten from here" (taarud-reconciliation.md §review).
4. **Ledger closure.** An extension cannot land while a gap it could close is unrevisited.
5. **Exactly-once inventory.** Every obligation id is annotated once. Ids are disjoint across contributors, and their union is the inventory.
   - **Scrutinised (2026-10-14).** A farʿ often turns on more than one qāʿida, and forcing one label hides that. So invariant 5 holds for the *home* annotation only, and a farʿ may also carry *co-annotations*.
     - A co-annotation (`corpus/takhrij/co/*.json`, id `far@encoder`) records that a second encoder derives the same stated ruling, on the farʿ's own words (`basis`, verbatim in the record; milestones are not words).
     - It is admitted only if:
       - its farʿ has its home annotation, and the home is kernel-derived or one side of an ikhtilāf;
       - its encoder is not the home's;
       - it is itself `derivable`, so a second failure is never recorded beside a first;
       - it appears once per encoder.
     - A gap at home is closed by revisiting it (S4), never by a co-annotation.
     - Co-annotations are guarded apart (`UsulTest/TakhrijCo.lean`) and counted apart (`report.json` `co_annotations`). Coverage, the ledger and routing labels still see one case per farʿ (`takhrij.co_errors`; `tests/test_multiple_annotations.py`, mutation-checked).
6. **Regenerate, don't sum.** Totals are rebuilt from the merged tree (`f927fb1`, `ed283bf`/`861de80`).
7. **Gaps name their need, and are not invented.** A case that a reading should cover gets a reading, not a new gap (`ed283bf`). Need tags are corrected on revisit when the text names another principle.
8. **Policy points stay open** (43.f004). Pinning the alternatives so they are expressible is allowed; choosing one is not.
9. **Apply the bank before asking the owner** (D3 `d21241e`, D5 `5cfbe02`). A question reaches a human only after the bank's own procedure leaves it open.
10. **Rights.** Pre-modern excerpts may run to 400 characters; modern ones are capped at 160 characters and their contexts stay in `.cache`.

### Research questions

A question the method surfaces that is neither a reading of one of al-Saʿdī's rules (those go to the IQ register, `corpus/review/sadi_interpretive_questions.json`) nor decidable by the bank's own procedure is recorded in the research register, `corpus/review/research_questions.json` (`schemas/research_question.schema.json`). Each entry:
- states the **policy in force** until a human decides;
- pins the Lean constants it bears on;
- cites verbatim sources;
- lists alternatives and concrete research steps.

`test_research_questions_are_grounded` checks every excerpt against its cited page in the pinned witness, and checks that no entry is decided except by a human. RQ-01 is the first: a reported ijmāʿ that contradicts the kernel's ruling. Its policy is to record such reports as evidence that changes no class.

## 5. Parallel runs

The method parallelises because a tranche only *adds* to the bank (§6). Shards can do the annotation steps S0–S3 and S5 independently. The steps where shards interact, self-application (S4) and reconciliation (S6–S7), run once over their union. Two failures shaped the protocol:
- Parallel tranche-3 contributions needed a dedicated consolidation ([m8-tranche3-reconciliation](m8-tranche3-reconciliation-2026-10-08.md)).
- A long-running process wrote back a stale shared file (`lock.json`, #55).

### 5.1 Claims

Before starting, a shard commits `corpus/worklists/claims/<shard>.json`. It records the shard name, its lane, the **full** base commit it works from, and the obligation ids it will annotate. `test_committed_shard_state_is_consistent` (`shards.check_claims`) requires:
- the ids are pending in a generated worklist;
- no id is claimed twice;
- the base commit is pinned.

### 5.2 Write isolation

A shard writes **only files it owns**. Every shared registry is a committed base plus per-shard fragments, merged by `pipeline/usul_corpus/shards.py` with a hard error on a duplicate key:

| Registry | Base | A shard's fragment |
|---|---|---|
| encoders | `takhrij.CORE` | `pipeline/usul_corpus/encoders/<shard>.py` (`ENCODERS`) |
| Lean readings | `Usul/Refinements.lean` (frozen except for conservative refinements of its own encoders) | `formal/lean/Usul/Readings/<Shard>.lean`, indexed by the generated `Usul/Readings.lean` |
| cases | — | `corpus/takhrij/<suite>.json` (already one file per suite) |
| dossier | `corpus/dossier/refinements.json` | `corpus/dossier/entries/<shard>.json` |
| reconciliation ledger | `corpus/reconciliation/ledger.json` | `corpus/reconciliation/entries/<shard>.json` |

A shard **never** regenerates shared outputs: `Takhrij.lean`, `TakhrijMirror.lean`, `report.json`, worklists, dossier and glossary pages, the signature map, the readings index, `lock.json`. It runs its own gates (`check_case`, the build of its module, the dossier verbatim check), then hands back. A shard's Lean module imports the specific `Usul.*` modules it needs, never the root `Usul`, which imports the readings index.

### 5.3 Integration (serial, one integrator)

An integration round merges a batch of finished shards in a fixed order (by lane, then shard id):

1. **Verify each contribution against its plan.** Base commit; case `sha256` per id; ids ⊆ owned obligations; disjoint union (the tranche-3 consolidation rules).
2. **Resolve collisions.**
   - *Duplicate principle* (two shards formalised the same statement): keep both and prove them equivalent, or retire one through `revisions`.
   - *Name clash*: shard namespaces make this a build error, not a silent overwrite.
3. **Regenerate everything once.** Run `takhrij`, `reconcile`, `worklist`, `docs`, `signature`.
4. **Self-apply across shards.** The revisit queue now sees the union: a principle formalised in shard *i* may close a gap recorded in shard *j*. Closures are made here, with dossier entries, and only here.
5. **Reconcile over the union.** New off-madhhab cases from lanes A and B meet the evidence from C and E.
6. **Run `make all`.** Report the round's figures (regenerated), the ledger counts, and the IQ questions raised.

### 5.4 Failure modes the protocol pre-empts

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

## 6. The method as a fixed point

One tranche is a monotone step on the bank.

    𝔅ₙ₊₁ = reconcile(selfapply(guard(annotate(read(𝔅ₙ, Qₙ), Uₙ))))

Qₙ is the tranche's qawāʿid and Uₙ its units.
- Readings are only added, or refined conservatively, so every earlier derivable or ikhtilāf guard stays true.
- `selfapply` iterates to a fixed point: the revisit queue is empty.
- `reconcile` is the kernel's own `resolve`, whose order is proved (`resolve_jam_first`, `resolve_naskh_before_tarjih`).

The quantities that must not regress are the encoding errors (= 0), the guards (all hold) and the open gaps (only ones that name their need). Coverage figures are reported, not optimised. A refinement that raises madhhab coverage by picking a side of a policy point is barred by invariant 8.

This fixed-point form is what makes parallelism possible. Within a phase, every shard's step reads the same base bank and only *adds* to it. The serial reduce (`selfapply` and `reconcile` over the union) is where shards interact.

