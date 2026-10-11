# Fatāwā oracle source: IslamQA.info

IslamQA.info (founded and supervised by Muḥammad Ṣāliḥ al-Munajjid, est. 1997) has no advertised export, but its app and website share one offline-reading backend: per-language dumps listed in a public manifest.

```text
https://files.zadapps.info/m.islamqa.info/dumps/manifest.json
  dumps[]  : {lang, folder: dumps/<snapshot>/<lang>, file: data.ndjson.gz}   full snapshot
  deltas[] : {lang, folder: dumps/deltas/<date>/<lang>, …}                   created/updated/deleted since
```

The pinned snapshot (`dumps/2026-10-04-220000`, all 17 languages, sha256 per file) is in [`corpus/fatawa/sources.json`](../../corpus/fatawa/sources.json).

```text
corpus/fatawa/sources.json ──make fatawa──▶ data/islamqa/raw/islamqa-<lang>.ndjson.gz      (committed; fetched only if absent; sha256-checked)
                                          └▶ data/islamqa/answers/islamqa-<lang>.jsonl.gz  (committed; byte-deterministic)
```

Both directories are in Git LFS (`.gitattributes`). After cloning, `git lfs pull --include "data/islamqa/**"` fetches them; CI checkouts skip them. Read the answers with:

```python
import gzip, json
answers = [json.loads(l) for l in gzip.open("data/islamqa/answers/islamqa-ar.jsonl.gz", "rt", encoding="utf-8")]
```

## Dump format

Each line is an event `{serial, op, type, data}` with `op ∈ {created, updated, deleted}`. `fold` applies events in order, keyed by `(type, reference)`, so snapshot ⧺ deltas gives the current database. Types: `answer` (ar: 32,445), plus `source`, `topic`, `subsite`, `file`, `article`, `book`, `research`, `event`, `page`, `learn-with-us`. The raw dump keeps all of them; the JSONL holds answers only.

`reference` is the site-wide answer number, shared across languages (ar ∩ en = 15,313).

## Record shape

```json
{"id": "islamqa.115097", "lang": "ar", "url": "https://islamqa.info/ar/answers/115097",
 "title": "…", "question": "…", "answer": "…", "summary": "…or null (the site's ملخص الجواب, 3,387 ar)",
 "source": {"ref": 5, "title": "الإسلام سؤال وجواب"},
 "topics": [{"ref": 150, "path": ["الفقه وأصوله", "الفقه", "معاملات", "البيوع", "الاستثمار"]}],
 "subsites": [], "see_also": ["islamqa.7535"], "langs": ["ar"], "created": "2008-03-26", "updated": "2020-02-11"}
```

| lang | answers | lang | answers | lang | answers |
|---|---:|---|---:|---|---:|
| ar | 32,445 | ur | 9,039 | ug | 2,447 |
| en | 15,801 | fr | 7,834 | pt | 2,139 |
| id | 5,938 | es | 5,544 | ru | 2,128 |
| zh | 3,805 | tr | 3,403 | ge | 2,024 |
| hi | 1,913 | bn | 1,752 | fa | 1,552 |
| tg | 1,136 | ta | 131 | | |

## Caveats

- `source` attributes the answer: mostly the site itself (28.6k ar), al-Munajjid by name (1.5k), and quoted muftīs (Ibn ʿUthaymīn, Ibn Bāz, the Lajna Dāʾima, …). Attribute rulings per answer.
- `topics` is the site's own taxonomy (ancestor path, top level e.g. الفقه وأصوله: 20,979 ar). 681 ar answers have none.
- `see_also` (the site's `fatawas`) links related answers: a ready-made citation graph.
- The text is © IslamQA (all rights reserved) and is committed only because this repository is private: do not make the repository or `data/islamqa` public. Nothing here is a fatwā issued by this project. Per the harness rule, these answers are **labels to test the kernel against**, not a hidden deontic authority.
- Deltas are not applied by `make fatawa` (the snapshot is pinned for reproducibility); `fold` already handles them.

Training labels: [fatawa-labels.md](fatawa-labels.md).

## Baseline oracle (`make oracle`)

[`oracle.py`](../../pipeline/usul_corpus/oracle.py) predicts a candidate ḥukm from the **question alone** (title + question text). The answer states the verdict, so it is never read. Training uses the `train` split, with each label weighted by `confidence`: basis × bank class × English agreement × act/question match. Rejected and conflicting labels weigh 0. The weighted set is exported for future models as `data/islamqa/train/islamqa-ar.jsonl.gz` (all splits, LFS).

Test split (1,460 answers; dev gives the same picture), accuracy / macro-F1:

| model | all labels | high-confidence labels (weight ≥ 0.7) |
|---|---:|---:|
| majority (ḥarām) | 34.5% / 0.10 | 52.5% / 0.14 |
| retriever, k = 10 | 47.5% / 0.34 | 52.7% / 0.36 |
| Naive Bayes | 50.0% / 0.34 | 51.0% / 0.35 |

Per-class F1 for Naive Bayes on all labels: wajib 0.51, mandub 0.18, mubah 0.52, makruh 0.00, haram 0.50.

Abstaining when the retriever's best match is weak:

| best cosine | coverage | accuracy |
|---|---:|---:|
| ≥ 0.2 | 19% | 54.4% |
| ≥ 0.3 | 5% | 56.2% |
| ≥ 0.5 | 1% | 66.7% |

**Reading.** A surface-text oracle is weak:
- On high-confidence labels its accuracy is no better than always answering ḥarām. Its macro-F1 is higher (≈ 0.35 vs 0.14) only because it spreads its answers over four classes at roughly a coin flip each. It never recovers makrūh.
- The questions are mostly «هل يجوز X؟», and the ruling turns on facts and principles the wording does not carry («يجوز إذا …، ولا يجوز إذا …»).

These numbers are the floor that any real oracle must clear on this fixed split. The retriever's `evidence` (the nearest answered fatwās, their ids and labels) is still useful as a citation layer for whatever decides.

Two directions can clear the floor:
- **A model that reads the question in depth.** For example, an LLM fine-tuned or prompted on the weighted set. Its output stays a candidate, checked by the bank.
- **The kernel itself.** Encode each case's facts (act, addressee, conditions) as the takhrīj encoders do, and let `Usul` derive the ruling. That is the deontic-circuit oracle the project is building, with this corpus as its test bench.

## Kernel oracle: takhrīj over IslamQA (`make fatawa-takhrij`)

The kernel route treats IslamQA as a new takhrīj tranche of *modern* furūʿ: fatwās that fall under the bank's existing encoders.
- Each case is annotated with the facts the encoder takes and the ruling the answer states, plus the answer's own words for it (`quote`).
- The kernel computes its own ruling, and the case is classed as in [takhrij.md](takhrij.md).
- `fatawa_takhrij.check` runs takhrīj's `check_case` and verifies that the answer exists and contains the quote verbatim.
- [`UsulTest/FatawaTakhrij.lean`](../../formal/lean/UsulTest/FatawaTakhrij.lean) guards every derivable and ikhtilāf case (`==`) and every encoding error (`!=`).

**Tranche 1** ([`corpus/fatawa/takhrij/islamqa_tranche1.json`](../../corpus/fatawa/takhrij/islamqa_tranche1.json)): 123 cases from 53 answers, retrieved by keyword and annotated LLM-assisted, one agent per encoder. Status `candidate`, not human-reviewed. A hand reading of 19 cases found 17 sound. Of the two fixed, one was decided under another encoder (`home`) and one was not a case.

| encoder | derivable | ikhtilāf | encoding error | missing fact | missing rule | coverage |
|---|---:|---:|---:|---:|---:|---:|
| `asl_zahir` | 24 | 0 | 0 | 1 | 2 | 24/27 |
| `trust_loss` | 18 | 0 | 0 | 1 | 2 | 18/21 |
| `unknown_owner` | 11 | 1 | 0 | 4 | 1 | 12/17 |
| `luqata` | 10 | 1 | 3 | 12 | 4 | 11/30 |
| `itlaf` | 0 | 0 | 0 | 11 | 16 | 0/27 |

Overall coverage 0.533; 68 Lean guards.

**What the modern cases say about the bank**
- **Doubt and certainty (`asl_zahir`) carries over almost whole.** «اليقين لا يزول بالشك», waswās, a felt wetness put down to the water: 24 of 27 are derived.
  - The rakʿa-count case (islamqa.23424.f002) follows preponderant belief, «ولو بالنظر إلى من بجواره», on equal grades with an external sign. It is derived only through the IQ-20 refinement (ties go to the indicator), so modern evidence now supports that refinement.
- **Trust liability (`trust_loss`) carries over:** deposits, muḍāraba banks, a seller holding sold goods.
  - Two gaps: a current account is a *loan*, a hand of guarantee that is not wrongful (`rule:qard_transfers_ownership`), and something without legal value (`fact:mal_mutaqawwam`).
- **Lost property (`luqata`) has a real encoding error.** For a find in the Ḥaram the text says it is never owned and is announced forever or handed to the authorities. The kernel's not-ownable branch gives charity after the year, a position neither side holds. That happens in 3 cases (4046.f002, 4050.f001, 191459.f001). The encoder needs a "never owned: keep holding" outcome.
  - The other gaps are modern-practical: trivial finds (`fact:trivial` ×5), animals (`fact:animal_kind`), buried treasure (`rule:rikaz` ×4).
- **Unknown owner carries over**, with one telling ikhtilāf (104241.f002). A bribe given to get what was not the payer's right goes to the poor *even though the payer is known*: Ibn Taymiyya and Ibn al-Qayyim, adopted by IslamQA. The kernel takes the other reported position (return it to the owner): the deciding fact is the illicit exchange, which the encoder does not see.
- **Damage (`itlaf`) does not carry over at all.** The bank's rule turns on *purpose*: destroying for one's own benefit versus repelling the thing's harm. Modern cases are accidents with no purpose: car crashes, medical error, breakage. They turn on fault (`fact:negligence` ×10), direct versus indirect causation (`rule:mubashara_tasabbub` ×9), physician liability, and whether a later death follows from the injury (`rule:sirayat_al_jinaya`).

**The gap ledger is the agenda for the next encoders**, ordered by how many modern cases each would open:
1. negligence + mubāshara/tasabbub (19);
2. trivial / animal finds (9);
3. rikāz (4);
4. the Ḥaram luqaṭa outcome (3 encoding errors).

As in M4, nothing here patches a reading; changing one is a review decision.

## Prolog oracle (`make fatawa-prolog`)

The takhrīj tranche tests the *bank* against the texts. The Prolog oracle asks a further question: which rules would close the gap ledger? It runs as ordered, cited rules over the same cases, with the bank as the last rule of each domain.

**Pieces**
- [`examples/v40_fatwa_rules.pl`](../../examples/v40_fatwa_rules.pl), hand-written:
  - `bank/2` mirrors the Lean encoders over the tranche's own facts (`encoder_fact/3`).
  - `oracle(C, Ruling, Rule)` takes the first applicable `rule/4` of the case's domain (liability, doubt, found property, unknown owner). Specific rules come before general ones; `bank` comes last.
  - `rule_source/2` names the ḥadīth, maxim or answer that states each rule.
- [`corpus/fatawa/prolog/tranche1_facts.json`](../../corpus/fatawa/prolog/tranche1_facts.json): each case's further facts and the text's own ruling, read from the answer (LLM-assisted, one agent per encoder, status `candidate`). `null` means the text does not settle the fact. `oracle_gap` records, with its reason, a case the rules knowingly get wrong.
- `examples/v40_fatwa_cases.pl` is generated from the two JSON files. Each case carries vectors for the fail-closed runner:
  - `bank(C)`: the Prolog bank equals the Python/Lean kernel (68 cases);
  - `agrees(C)`: the oracle's ruling is the text's, or `expect_false` for a recorded gap.
- [`examples/v40_fatwa_oracle_fixtures.pl`](../../examples/v40_fatwa_oracle_fixtures.pl) loads both and adds precedence vectors for the rules that the real cases mask.
- `tests/run_all.sh` runs it. `tests/mutation_test.sh` disables each rule in turn, and every mutant is killed.

**Result on tranche 1** ([`report.json`](../../corpus/fatawa/prolog/report.json)): 122 cases, segmentation errors excluded.

| encoder | cases | oracle = text | bank answers | bank = text |
|---|---:|---:|---:|---:|
| `asl_zahir` | 27 | 27 | 24 | 24 |
| `itlaf` | 27 | 27 | 0 | 0 |
| `luqata` | 30 | 29 | 14 | 11 |
| `trust_loss` | 21 | 21 | 18 | 18 |
| `unknown_owner` | 17 | 15 | 12 | 11 |
| **total** | **122** | **119** | **68** | **64** |

**Read this as a fit, not an accuracy.** The rules were written and corrected against these same 122 texts. The first pass agreed on 105. Each of the 14 cases fixed since then rests on a rule that a text states (Majmaʿ al-Fiqh's traffic-accident exemptions as quoted in islamqa.345284, «يضاف الحكم إلى المباشر», «البينة على المدعي»). Only a held-out tranche measures whether the rules generalise.

**The three recorded gaps** are all answers that permit a *choice* between rulings, which a single-valued ruling cannot hold:
- islamqa.126387.f001: charity or the officials, never keeping it;
- islamqa.107436.f001: public money spent on the public, with the state as owner;
- islamqa.287215.f002: hold her share or give it in charity.

The next schema step is a ruling *set* (the permitted options), with agreement meaning the oracle's ruling is a member.

**What the rules add to the bank**, by how often they decide a case:
- trust and fault: `hand_of_trust` 17, `mubashir_liable` 11, `mutasabbib_by_fault` 5;
- the Majmaʿ al-Fiqh exemptions: `victim_fault` 3, `quwwa_qahira` 1, `mubashir_first` 2;
- finds: `trivial_find` 5, `haram_makka` 4 (this rule fixes the 3 encoding errors), `rikaz` 4, and the two animal rules.

The `bank` rule still decides 24 cases, all in `asl_zahir`.

## Against the classical banks

The classical takhrīj banks (`corpus/takhrij`) total 461 cases: Saʿdī, dalāla, and Ibn Rajab's M8 tranches 1–10. `make fatawa-takhrij` now summarises each bank with takhrīj's own report, under `banks` in [`report.json`](../../corpus/fatawa/takhrij/report.json).

| bank | cases | encoders | coverage | madhhab coverage | ikhtilāf | open gaps | encoding errors |
|---|---:|---:|---:|---:|---:|---:|---:|
| `sadi_furu` | 213 | 24 | 0.995 | 0.685 | 107 | 1 | 0 |
| `rajab_m8_*` (10 tranches) | 238 | 3–9 each | 0.962–1.0 | 0.50–0.94 | 152 | 1 | 0 |
| `dalala_furu` | 10 | 4 | 0.556 | 0.444 | 1 | 4 | 0 |
| **`islamqa_tranche1`** | **123** | **5** | **0.533** | **0.525** | **2** | **54** | **3** |

**Why the classical banks are covered and the fatāwā are not.** The two were sampled differently:
- **Classical furūʿ** are the examples a qāʿida's own author gives under it, and 37 gaps were closed by revisiting the readings. Coverage near 1 says the bank reads its sources; it does not say the bank generalises.
- **IslamQA cases** were retrieved by keyword from answers written for other reasons. Their coverage of 0.533 is the first out-of-source measure the bank has had.

**Ikhtilāf runs the other way.** More than half of the classical cases report more than one position, because Ibn Rajab cites the riwāyāt and wujūh. A fatwā gives one answer, so IslamQA has only 2 ikhtilāf cases. Madhhab coverage (the kernel takes the madhhab's position) is therefore the comparable number: 0.691 classical against 0.525 modern.

### The Prolog oracle on held-out classical cases

[`classical_facts.json`](../../corpus/fatawa/prolog/classical_facts.json) brings into the oracle the 52 classical cases of its five encoders. Each case's target is the madhhab's ruling. Rajab q026.f005 is left out because no position in it is marked madhhab. The rules were never written against these cases. Each case gets vectors as before. The 16 cases where the madhhab takes a position the kernel does not are recorded gaps.

| encoder | cases | bank = madhhab | oracle = madhhab (as fitted) | oracle = madhhab (fixed) |
|---|---:|---:|---:|---:|
| `asl_zahir` | 40 | 24 | 24 | 24 |
| `itlaf` | 5 | 5 | **2** | 5 |
| `trust_loss` | 5 | 5 | 5 | 5 |
| `luqata` | 1 | 1 | 1 | 1 |
| `unknown_owner` | 1 | 1 | 1 | 1 |
| **total** | **52** | **36** | **33** | **36** |

**The rules fitted to modern accidents broke the classical itlāf cases.**
- Ibn Rajab's q026 cases are all destruction by the agent's own hand: a muḥrim kills attacking game, an egg is knocked from the eye. «المباشر ضامن وإن لم يتعد» therefore made the agent liable in all of them. Qāʿida 26 holds that repelling the thing's own harm is not compensable.
- The fix is a rule, `itlaf_bi_haqq`, placed before the causation rules. It shares `itlaf_liable/2` with the bank.
- Modern cases carry no `purpose` fact, so they are unchanged at 119/122.

The lesson for the rule order: the classical bank decides when a destruction is *with right*; the modern rules decide *who caused* it.

**`asl_zahir`: the two banks test different regions of the same function.**

| (aṣl, ẓāhir, amāra) | classical: ẓāhir / aṣl | modern: ẓāhir / aṣl |
|---|---:|---:|
| (zann, qat, ✓) | 7 / 0 | 7 / 3 |
| (zann, zann, ✓) — a tie | 14 / 16 | 1 / 0 |
| (zann, zann, ✗) | 0 / 2 | — |
| (zann, shakk or wahm, any) | 0 / 1 | 0 / 16 |

- **Modern cases sit off the tie:** waswās and doubt (shakk, wahm) go to the aṣl, a certain indicator goes to the ẓāhir. The 3 certain-ẓāhir cases that go to the aṣl are decided by `sufra_kudra_after_tuhr` and `bayyina_in_qada`. That is why the fit there is 27/27.
- **Classical cases sit on the tie** (30 of 40). There the madhhab splits 14/16, so the IQ-20 tie rule (ties go to the indicator) can be right only about half the time. Grade and amāra alone cannot decide a tie. The open question is which fact does: the strength of the amāra, or the kind of right at stake. The 16 recorded gaps are the cases to read for it.
