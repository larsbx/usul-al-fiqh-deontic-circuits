# M4: the takhrīj suite

A formal reading is tested the way the jurists tested a qāʿida: against its furūʿ. Each case paragraph (`far` record) listed under a qāʿida is annotated with the facts the reading takes and the ruling the text states. The formal kernel then computes its own ruling, and the two are compared.

## Which furūʿ test which reading

The roadmap names Ibn al-Laḥḥām for M4. His rules, however, are almost all uṣūl proper (taklīf, the command, generality, particles), which belong to M5's inference schemata. What the kernel formalises today are al-Saʿdī's rules. Many of these are compressions of Ibn Rajab's *Taqrīr al-Qawāʿid*, sometimes nearly verbatim (Q45 ≈ Ibn Rajab 63, Q48 ≈ 103, Q50 ≈ 133, Q36 ≈ 26, Q35 ≈ 140, Q20 ≈ 106). So the first tranche tests each Saʿdī reading on the furūʿ Ibn Rajab derives from the corresponding qāʿida, and al-Saʿdī's generality rules (Q59/60) on Ibn al-Laḥḥām's furūʿ for qawāʿid 52–54. The rest of Ibn al-Laḥḥām follows with M5.

`pipeline/usul_corpus/takhrij.py` holds one table, `ENCODERS`, and everything else is derived from it. Each encoder gives:
- the Saʿdī rule and the qāʿida whose furūʿ test it;
- the fact fields and their domains;
- the Lean expression that computes the kernel's ruling;
- a Python mirror of that expression for annotators.

## Classes

| Class | Meaning | Checked by |
|---|---|---|
| `derivable` | the case falls under the rule, its deciding facts are the encoder's fields, and the kernel gives the text's ruling | `#guard expr == expected` |
| `genuine_ikhtilaf` | the text reports two or more positions; the kernel gives one of them (and `matches_madhhab` says whether it is the madhhab's) | `#guard expr == expected` |
| `encoding_error` | the case is fully expressible, but the kernel contradicts every stated position: a finding against the reading | `#guard expr != expected` |
| `missing_fact` | the ruling turns on a fact the encoder cannot express | — |
| `missing_rule` | the case is decided by a different principle | — |
| `segmentation_error` | the record is not a case (excluded from coverage) | — |

Coverage = (derivable + genuine_ikhtilāf) / (total − segmentation errors). As the roadmap requires, ikhtilāf cases count as recorded positions, not failures.

## Lean is the oracle, not the annotation

Annotation is LLM-assisted and stays `candidate`. Lean checks its claims at three levels:

- `UsulTest/TakhrijMirror.lean` guards every input of every encoder, so the Python mirror annotators compute with equals the Lean reading.
- `UsulTest/Takhrij.lean` guards each annotated agreement (`==`) and each recorded disagreement (`!=`). A case claimed derivable that the kernel does not derive fails the build.
- `check_case` rejects malformed annotations before generation: facts outside the domains, a class the kernel contradicts, or an ikhtilāf with fewer than two positions.

`python -m usul_corpus takhrij` regenerates both Lean files and `corpus/takhrij/report.json`. `test_takhrij.py` requires every furūʿ record of an annotated qāʿida to appear exactly once, and the generated files to be in sync.

## First tranche: results

204 furūʿ across 15 readings:
- 187 from Ibn Rajab, under the qāʿida each Saʿdī rule compresses;
- 17 from Ibn al-Laḥḥām, under his generality qawāʿid 52–54.

Lean checks 185 guarded claims (`UsulTest/Takhrij.lean`).

| | Cases |
|---|---|
| derivable | 80 |
| genuine ikhtilāf | 98, of which the kernel takes the madhhab position in 29 |
| encoding error | 7 |
| missing rule | 13 |
| missing fact | 6 |
| **coverage** (derivable + ikhtilāf) | **0.873** |
| **madhhab coverage** (derivable + ikhtilāf on the madhhab side) | **0.534** |

The second figure is the honest one: in 69 ikhtilāf cases the reading lands on a minority position. `corpus/takhrij/report.json` has the per-encoder breakdown.

### What the cases say about the readings

- **Lots (Q25 ← Ibn Rajab 160): four encoding errors (IQ-09).** Where a specific entitled person is *lost in confusion*, Ibn Rajab prescribes lots even though the property could be divided. The reading's order (known entitled ≻ division ≻ lots) fits only his first category, an unspecified entitlement among equals. The reading also lacks his exclusions (lineage, an unspecified obligation such as a forgotten oath). The annotation reads `divisible` as "the law would split it between the claimants". Under a purely physical reading two of the four would become derivable.
- **Aṣl and ẓāhir (Q11/Q52 ← Ibn Rajab 159): two encoding errors (IQ-20).** With a known state and preponderant belief of its removal, the text holds to the aṣl (f007, f008). Yet with the same grades it allows breaking the fast at believed sunset (f013), «because time has indicators by which it is known». The deciding fact is the indicator, not the grade. Ibn Rajab's fourth category (aṣl and ẓāhir equal) is a khilāf, but the reading sends every tie to the ẓāhir.
- **Generality (Q59/60 ← Ibn al-Laḥḥām 52–54): one encoding error.** «أوصيت لجاري محمد» with two neighbours of that name: the annexed singular is pinned by a proper name and is not general, which Ibn al-Laḥḥām himself marks «مخالف للقاعدة». Five of the six ikhtilāf cases split on ʿahd versus genus, and the reading always takes genus. It needs an ʿahd field.
- **Merging (Q41 ← Ibn Rajab 18): no encoding error.** I expected the same-time, make-up and intention conditions (IQ-04) to surface as errors. No case turns on them, so the empirical support for IQ-04 is limited to cases where the madhhab denies merging and the kernel matches only the minority.
- **Recourse (Q32 ← Ibn Rajab 75): four missing facts.** The cases need fields the reading lacks: a judge's or owner's permission, and whether the expense was owed by the other party. In f010 Aḥmad denies the lessee recourse although he gave no gift.
- **Unknown owner (Q20 ← Ibn Rajab 106): six missing rules.** Ibn Rajab's qāʿida is broader («the unknown is treated as non-existent»). Most of its furūʿ, such as the duration of istiḥāḍa, are not about a right-holder at all.

None of these were patched in the readings. Changing a reading is a review decision, and its guards will show what changes.

## The bank applied to itself

Every gap carries `needs`: the capability that would close it, as `fact:<field>` for a missing input or `rule:<principle>` for a missing principle. Every encoder `provides` its rule and its fact fields. `revisit_queue` lists the gaps whose needs the bank now provides in full. `test_bank_is_applied_to_itself` requires that queue to be empty, so an extension of the bank cannot land without being run back over the earlier gaps.

A revisited case keeps its history in `revisit` (`from_class`, `from_encoder`, `closed_by`): artifacts are superseded, not silently rewritten. Mutation-checked: making an open gap's need a provided one fails the test.

**First round (M5's ʿahd-aware generality, `Usul.Dalala.IsGeneralIn`).** The generality encoder was refined in place. By `isGeneralIn_no_ahd` its old cases are unchanged, and the Lean guards confirm it. The queue then held five gaps:

| Case | Before | After |
|---|---|---|
| Ibn al-Laḥḥām 52.f003, «تنزهوا من البول» | missing fact | derivable (al- read as ʿahd by an indication) |
| 52.f004, «تحريمها التكبير» | ikhtilāf, kernel on the minority side | ikhtilāf on the **madhhab** side: the positions differ on the ʿahd fact, and the kernel reproduces each from its reading of it |
| 53.f006, «أوصيت لجاري محمد» | encoding error | derivable (a proper name pins the annexed singular) |
| Ibn Rajab 106.f006, the forgotten divorced wife | missing rule | derivable under the lots reading, which the bank already had |
| 52.f008, tayammum for «الصلاة» | ikhtilāf | **not closed**: the majority's restriction is «تنزيلا له على الأدنى», a different principle; the tag was corrected to `rule:haml_ala_adna` on revisit |

Coverage rose from 0.873 to 0.887 and madhhab coverage from 0.534 to 0.554, with encoding errors down from 7 to 6. The other 24 gaps stay open. Each names what it waits for: the indicator (amāra) for aṣl/ẓāhir, the confusion category for lots, permission and owed-by-other for recourse, and principles such as abstention under a possible condition.
