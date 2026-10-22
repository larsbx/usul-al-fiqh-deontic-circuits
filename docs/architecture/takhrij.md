# M4: the takhrīj suite

*The procedure this suite grew into is specified as one method in [derivation-method.md](derivation-method.md).*

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
| `genuine_ikhtilaf` | the text reports two or more positions; the kernel gives one of them. `matches_madhhab` records whether the source labels that position the madhhab's; it describes the text and is not a target | `#guard expr == expected` |
| `encoding_error` | the case is fully expressible, but the kernel contradicts every stated position: a finding against the reading | `#guard expr != expected` |
| `missing_fact` | the ruling turns on a fact the encoder cannot express | — |
| `missing_rule` | the case is decided by a different principle | — |
| `segmentation_error` | the record is not a case (excluded from coverage) | — |

Coverage = (derivable + genuine_ikhtilāf) / (total − segmentation errors). As the roadmap requires, ikhtilāf cases count as recorded positions, not failures.

**No position is a target by attribution.** A ruling stands by its proof, not by whether a madhhab, a majority or an author holds it. The report therefore scores the kernel only on *decided* cases, those that state one ruling:

    decided coverage = derivable / (derivable + encoding errors + missing facts + missing rules)

Disputed cases (`genuine_ikhtilaf`) are counted apart (`disputed`). Which position is right is a question of tarjīḥ by the evidence. Earlier sections report a *madhhab coverage* (derivable plus ikhtilāf on the madhhab side). That figure is kept as it was recorded, but it is retired: it scored the kernel against an attribution.

## Lean is the oracle, not the annotation

Annotation is LLM-assisted and stays `candidate`. Lean checks its claims at three levels:

- `UsulTest/TakhrijMirror.lean` guards every input of every encoder, so the Python mirror annotators compute with equals the Lean reading.
- `UsulTest/Takhrij.lean` guards each annotated agreement (`==`) and each recorded disagreement (`!=`). A case claimed derivable that the kernel does not derive fails the build.
- `check_case` rejects malformed annotations before generation: facts outside the domains, a class the kernel contradicts, an ikhtilāf with fewer than two positions, or one where no position holds the expected ruling as an encoder code (what the source adds goes in the position's `detail`).

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

**M5 readings on Ibn al-Laḥḥām (`corpus/takhrij/dalala_furu.json`).** Ten furūʿ, under qāʿida 43 (the command) and 61 (wording versus occasion):
- **Qāʿida 61:** all three cases are derivable under ʿumūm al-lafẓ. For f003 (ʿarāyā) one of the text's two reasons is a different principle, so the annotator flagged `missing_rule` as defensible.
- **Qāʿida 43:** none is derivable. Ibn al-Laḥḥām says its furūʿ are «very many» and gives uṣūl points instead (one record is no case at all). Each point names where `amrStatus` is too thin:
  - what counts as a command: writing or gesture, and the Prophet's act;
  - wording no indication may override («farḍ», «wājib», an explicit threat). The kernel lets any qarīna override any command;
  - an indication that only removes obligation without naming another status;
  - one command over items of mixed status;
  - literal versus figurative use of «amr».
  These are now open needs in the ledger. The queue stays empty, because the bank does not provide them yet.

Totals after this round: 214 cases, coverage 0.864, madhhab coverage 0.545, 6 encoding errors, 30 open gaps, 5 revisited.

**Second round: conservative refinements (`Usul.Refinements`).** The cheapest open gaps asked for inputs the readings lacked. Each refinement adds that input with a default that gives back the earlier reading exactly, proved in Lean (`*_conservative`). Existing cases were migrated to the defaults, and all their guards still hold. Each refinement is grounded in the text that exposed it:

| Refinement | Ground | Revisited |
|---|---|---|
| `allocationFull`: a specific entitlement lost in confusion goes to lots, divisible or not | Ibn Rajab 160's own second clause («تمييز المستحق المعين في نفس الأمر عن اشتباهه») | 160.f007, f015, f044 encoding error → derivable; f012 → ikhtilāf on the madhhab side (naṣṣ: valid, lot) |
| `recourseFull`: recourse for paying what another owed, or for spending by permission, unless a gift | Ibn Rajab 75's two types | 75.f004, f010 → derivable; f009 → ikhtilāf (no madhhab marked) |
| `zahirPrevails`: on equal grades the ẓāhir prevails only where the matter has indicators | Ibn Rajab 159 at f013: «لأن الوقت عليه أمارات… بخلاف ما لا أمارة عليه من… الطهارة والحدث» | 159.f007, f008 encoding error → derivable |

Not revisited:
- **75.f006:** it turns on whether asking the owner was *impossible*, a different fact. Its tag was corrected to `fact:permission_unobtainable`.
- **Ibn al-Laḥḥām 43.f004:** it is the uṣūl dispute itself: whether «فرض», «واجب» or an explicit threat is a text immune to reinterpretation (al-Qāḍī: no; Abū al-Barakāt: yes). A refinement would pick a side of a policy question, so it stays open for the register.

The refinements do not decide IQ-09 or IQ-20. They make the alternatives each question names expressible, and are pinned there: adopting one as *the* reading of Q25 or Q52 is the review decision those questions ask for.

After this round: 214 cases, **coverage 0.906**, **madhhab coverage 0.582**, **0 encoding errors** (from 7 at the start of M4), 21 open gaps, 13 revisited.

**Third round: the open gaps' own principles.** The remaining gaps named principles, not inputs. Each was formalised from the text that states it, in `Usul.Refinements`, and given an encoder. The queue then held nine cases, and all closed:

| Principle | Ground | Revisited |
|---|---|---|
| `treatedAsAbsent`: the unknown is treated as non-existent when one despairs of learning it or taking it into account is a hardship. Al-Saʿdī's Q20 is its instance (`q20_is_instance`) | Ibn Rajab 106 («ينزل المجهول منزلة المعدوم… إذا يئس من الوقوف عليه أو شق اعتباره») | 106.f001, f005 missing rule → derivable; f004 → ikhtilāf on the madhhab side |
| `hamlAlaAdna`: an unspecified intention over ranked referents is read as the lowest, because the lowest is certain (`adna_is_certain`) | Ibn al-Laḥḥām 52.f008 («تنزيلا له على الأدنى»), grounded in Aḥmad's naṣṣ «له أخسهم… لأنه المتيقن» (Ibn Rajab v1 p351) | 52.f008 → ikhtilāf on the madhhab side |
| `trustVoided`: a pure trust is voided by transgression, a compound trust is not. Liability is independent of voidance | Ibn Rajab 45 («الأمانة المحضة تبطل بالتعدي…») | 45.f005 missing rule → ikhtilāf (Ibn ʿAqīl's two possibilities, neither marked; the kernel takes the qāʿida's compound-trust position) |
| `recourseNec`: where asking the owner is impossible, recourse as if permitted. Conservative over `recourseFull` | Ibn Rajab 75.f006, and the ground given for the judge's permission: «إذنه قائم مقام إذن الغائب» (v1 p138) | 75.f006 missing fact → derivable |
| `abstains`: while a divorce condition may have occurred, the husband abstains until its absence is known. The status is untouched (`abstention_keeps_status`, from Q11) | Taqī al-Dīn on Aḥmad's texts, cited by Ibn Rajab (v1 p357); «متيقن لحل زوجته شاك في تحريمها» (p356) | 160.f026, f027, f028 missing rule → derivable |

These are not refinements of earlier readings. The new encoders sit beside the old ones, so no earlier guard is touched. `recourseNec` is the exception: it extends `recourseFull` and carries its conservativity theorem.

After this round: 214 cases, **coverage 0.944**, **madhhab coverage 0.620**, **0 encoding errors**, 12 open gaps, 22 revisited. The open gaps are:
- the six command points of Ibn al-Laḥḥām 43, among them the policy dispute 43.f004;
- ghulūl forfeiture (140.f006);
- the speaker inside his own speech (52.f007);
- the negated indefinite by syntactic role (54.f002);
- tie-break criteria for lots (160.f038);
- luqaṭa (106.f002);
- specifying iḥrām (106.f007).

### Citations, rationale and terms

Every closure is documented in [the dossier](dossier.md). For each principle it gives:
- the statement and the texts, with excerpts verified verbatim against the pinned witness;
- the conditions and the rationale;
- the Lean constants and the conservativity theorem;
- the related register questions.

Both the dossier and [the glossary](../glossary.md) are generated (`python -m usul_corpus docs`) from `corpus/dossier/*.json`. `test_dossier.py` keeps them honest:
- no `closed_by` tag without a dossier entry;
- every ref resolves to a record or a registered witness;
- each excerpt is verbatim, checked letters-only against the cache, with its page computed from the next page marker;
- every constant is `#check`-ed;
- every term is a glossary key;
- every refinement by an added fact names its conservativity theorem.

**Fourth round: what the remaining texts say themselves.** Seven of the twelve open gaps quote their own reason, or a reason the bank already holds. Each is formalised in `Usul.Refinements` from that text, given an encoder and revisited (cited in [the dossier](dossier.md)):

| Principle | Ground | Revisited |
|---|---|---|
| `bootyTheftBurden`, `ghululForfeits`: restitution once, plus the share forfeited. `ghulul_is_not_doubling` proves the burden can be below, at or above twice the theft | Ibn Rajab 140.f006 («وقد يكون قدر السرقة وأقل وأكثر») | 140.f006 missing rule → derivable |
| `heardAfterDenial`: after denial, a right *against* oneself is heard and a right *for* oneself is not. The first half is Q55's confession rule (`against_self_like_confession`) | Ibn al-Laḥḥām's own distinction between the two texts («والفرق بين النصين أن الشهادة حق عليه… والبينة حق له») | 54.f002 → ikhtilāf on the madhhab side; the tag corrected from `rule:negated_indefinite_by_role` |
| `fayTieBreak`: ordered criteria by S2 (`resolveD`), then the ruler's choice; here the lot is optional | Ibn Rajab 160.f038 («ثم ولي الأمر مخير إن شاء أقرع… وإن شاء رتبهما») | 160.f038 missing fact → derivable |
| `luqata`: after its year, owned or given in charity. It is an instance of qāʿida 106 (`luqata_is_instance`) | Ibn Rajab 106.f002 («تتملك لجهالة ربها») | 106.f002 missing rule → derivable |
| `validOnEvery`: under a forgotten intention, what holds on every possibility suffices. The second wajh is `treatedAsAbsent` applied to the ifrād possibility | Ibn Rajab 106.f007; the second wajh's «تنزيلا للمجهول كالمعدوم» | 106.f007 → ikhtilāf on the madhhab side (the better-known wajh) |
| `jawazAfterSarf`: permission follows obligation and falls with it. This is Q50 (`Kulliyyat.established`) with no independent proof | Abū al-Ṭayyib and al-Tamīmī («الجواز تبع للوجوب… فإذا سقط الوجوب سقط التابع له») | 43.f005 → ikhtilāf (two wujūh; no madhhab marked) |
| `amrPerItem` and `amrByTakhsis`: `mixed_readings_agree` proves Ibn ʿAbd al-Salām's takhṣīṣ and Abū al-ʿAbbās's per-item reading rule alike on every item | al-Musawwada («أريد به الواجب في الواجبات والمستحب في المستحبات») | 43.f006 missing fact → derivable |

All seven are new encoders beside the old ones, so no earlier guard is touched. The conservativity check now follows the ledger rather than tag names: it requires a conservativity theorem exactly for the cases refined under the encoder they already had.

After this round: 214 cases, **coverage 0.977**, **madhhab coverage 0.648**, **0 encoding errors**, 5 open gaps, 29 revisited. The five that remain are not principles the bank lacks:
- four of Ibn al-Laḥḥām's points on qāʿida 43 are about naming or policy, not a ruling: whether writing, gesture or the Prophet's act is *called* a command, ḥaqīqa versus majāz, and whether «فرض»/«واجب» is immune to reinterpretation;
- 52.f007 has no transmitted ruling to test («هذه المسألة لم أرها منقولة»).

## Apparent contradictions

Every ikhtilāf farʿ off the marked madhhab side is run through the kernel's own taʿāruḍ procedure (jamʿ → naskh → tarjīḥ → tawaqquf): see [reconciliation](taarud-reconciliation.md). The residues it leaves against a reading are that reading's refinement worklist.

## M8: scale-up, first tranche

**Scope reconciliation.** Counts come from committed record IDs minus all existing annotations, not historical estimates. M4 now annotates 196 Ibn Rajab records under 14 qawāʿid, including nine `.f000` additions. PR #29's 1,129 segmented records minus those 196 and tranche 1's 26 left 907 records in 122 qawāʿid with cases. The old “869 in 146” mixed pre-opening counts with all unannotated qawāʿid, including those with no segmented case. PR #30 then added seven segmented records and annotated tranche 2's 25: 1,136 − 196 − 26 − 25 = 889, in 118 qawāʿid. Merged PR #32 then added the list-and-division segmentation and 21 candidate annotations. The unified tranche 3 below preserves those cases and PR #31's eight existing-record annotations, in one 29-record suite; current totals are generated below. Ibn al-Laḥḥām and the global report's totals are separate scopes.

<!-- BEGIN GENERATED M8 SCOPE -->
**Current M8 inventory (generated).** 1,189 segmented Ibn Rajab furūʿ records = 1,189 annotated + **0 awaiting annotation**. Of 160 qawāʿid, 154 have segmented records: 154 are fully annotated and **0 await annotation**. The other **6 need source segmentation review**; zero emitted records does not establish zero examples in the text.

The unit is a committed farʿ record, which can contain multiple examples. Annotated gaps and disagreements are already counted as annotated; annotation does not mean independently reviewed or scholarly accepted. No count is imputed for unsegmented examples. The exact ID worklist and input hashes are in `corpus/worklists/rajab_m8.json`; rebuild with `python -m usul_corpus m8-worklist`.

| Current scope (generated) | Cases | Coverage | Decided coverage | Disputed | Encoding errors | Open gaps |
|---|---|---|---|---|---|---|
| Combined M8 tranche 3 | 29 | 1.000 | 1.000 | 21 | 0 | 0 |
| All annotation suites | 1263 | 0.952 | 0.894 | 684 | 0 | 61 |

Coverage counts derivability under the candidate encoding. Decided coverage scores the kernel only on cases that state one ruling; disputed cases are weighed by their evidence, not by who holds a position. Neither metric establishes scholarly acceptance.
<!-- END GENERATED M8 SCOPE -->

Each selected qāʿida needs an explicitly sourced reading connected to a Lean encoder before its furūʿ can test that reading. An unannotated qāʿida is not proof that no related principle exists in the bank. Every emitted record of a selected qāʿida is inventoried, including `.f000`; known extraction gaps remain separate.

**Tranche 1 (qawāʿid 6, 22, 68; 26 furūʿ with the opening examples).** These are the qawāʿid whose principles the bank had just formalised, so the tranche also tests those principles:

| Qāʿida | Reading | Link to the bank |
|---|---|---|
| 6: an act done in its time on a belief later shown wrong suffices; joined to it, a hidden defect in a condition is excused | `errorExcused`: the act stands unless another's right is attached («لتعلق حق الغير به») or he was negligent («فرط بترك البحث») | `q6_grounds_exemption`: q6 is the ground of `zannSetAside`'s exemption, which until now had no source |
| 22: is what is consumed in another, without trace, as non-existent? («فيه خلاف») | `istihlak`: one side of the khilāf | an instance of qāʿida 106 (`treatedAsAbsent`) |
| 68: doubt in a condition of validity | `validUnderDoubt`: what needs a firm intention is valid only on ghalabat al-ẓann or an aṣl mustaṣḥab; what does not is valid («فالصحيح فيه الصحة») | `firm_by_basis`: the firm basis is bayt 90's `basis` or the presumption |

Results on the tranche:
- **8 derivable, 14 ikhtilāf (8 on the madhhab side), 4 missing rule or fact, 0 encoding errors.** Coverage is 22/26 = 0.846 and madhhab coverage 16/26 = 0.615, with the three opening examples included. Two of them are derivable; q22.f000 (impure water) turns on the quantity of water and is a missing fact (`fact:water_quantity`). Seven ledger entries are now open for this tranche: the four missing cases, and three minority-side ikhtilāf cases that name what they need (22.f003, 22.f004, 68.f007).
- **What the cases say about the readings:**
  - **q22's khilāf is real.** On mixed oil (f003, and the bequest in f004 that follows it) the manṣūṣ is *partnership*, not consumption. Same-kind fungibles mixed together become a shirka, which consumption-as-absence cannot express. The kernel lands on the minority (al-Mujarrad), and the gap is now in the ledger (`rule:khalt_as_shirka`). On milk in water (f001) and grains of wheat in barley (f006) no madhhab is marked.
  - **q22.f008 is decided by another reading.** The mashhūr makes the mixer of a deposit liable *for transgression*. It is annotated under the trust-loss reading and gives the madhhab's ruling. A new optional `home` field records that its qāʿida is 22, so coverage stays exact without pretending the case was revisited.
  - **q68 types 1 and 2 track the madhhab** on the doubtful vessel, the zakāt intention, the night of doubt and the deposited dinars. The exception is f007: the stronger view (al-Qāḍī, Ibn ʿAqīl) rests on the bar on conditional sale, a separate principle (`rule:taliq_al_bay`).
  - **New gaps:** whether a concession needs certainty of its permission (68.f001, `fact:rukhsa_needs_certainty`); dirhams mixed with usurped ones, decided by proportion (22.f007, `rule:mixed_haram_by_proportion`); and a judge ruling against his own ijtihād (68.f009).
- **Segmentation finding, opening examples (found on review, now fixed):** a qāʿida's first example often comes inline before the first «(ومنها)» paragraph, after «صور:» or «مسائل:» («منها», «(ومنها)», «(إحداها)»), or in a paragraph opening «ومن أمثلة ذلك». It used to stay inside the qāʿida record. The segmenter now emits it as `.f000`, so every existing farʿ id is unchanged; the rebuilt corpus differs from the old one only by 74 new records (73 Ibn Rajab, 1 Ibn al-Laḥḥām) and their `furu_count`. Twelve annotated qawāʿid gained one, and all twelve are annotated: q6, 22 and 68 in this tranche, and q8, 16, 26, 45, 63, 75, 76, 140 and 159 from M4. A case now runs from its marker to the next farʿ marker. Before, the text stopped at the first source line break, so page markers cut cases mid-sentence; that affected paragraph furūʿ (e.g. Ibn al-Laḥḥām 43.f006, «دع ما يريبك إلى ما لا») as well as the new opening examples. Ids are unchanged; only `case_ar` grows, up to its excerpt cap. Known rough edges: q9's f000 holds two examples joined by an inline «(ومنها)»; q63's and q147's f000 begin with a fragment from before the marker; for q90 and q150, f000 is the heading of a sub-list.
- **Segmentation finding, other layouts (ordinal cases now segmented):** a qāʿida with no «(و)منها» paragraph may enumerate its cases by ordinal, «(الصورة الثانية)», «المسألة الثالثة:». Such a qāʿida now takes those lines as its farʿ markers; a qāʿida with any «(و)منها» line keeps that marker alone, so no existing id moves. The opening example is also read after «… مسائل إحداها:» and «فمن صور المسألة». The rebuilt corpus gains 7 records (q13.f000; q14.f001–2; q52.f000–3) and changes only q14.f000, which no longer runs on into the second ṣūra; it is not annotated. **Lists and divisions (now segmented)**: a qāʿida with neither marker is cut by its list; an existing opening remains `.f000` and the following ordinal chain starts at 2. First choice is cases by feminine ordinal, «(أحدها)», «(والثانية)», «(اليد السادسة)». Failing those, divisions: one labelled level («النوع/القسم/الضرب/الحالة/المقرر الثاني»), or bare «والثاني:» once the qāʿida announces them («نوعان:», «على قسمين:», «ثلاثة أشياء:»). The list is a chain of consecutive ordinals 1, 2, …, or 2, … when the first item is the opening. For each k the cut is the last k-mark before the first (k+1)-mark, so a second riwāya written «(والثانية)» inside a case stays in it (q1). In a case list, a feminine 2 closes an open «إحداهما» pair before it can open a top-level item. A masculine «أحدهما … والثاني» pair or an already closed feminine pair does not absorb the next top-level «(والثانية)». A labelled level wins over bare marks, so a wajh «والثاني:» inside a division does not cut (q36), and «القسم» and «النوع» are never mixed (q43). The rebuilt corpus gains 43 records in 14 qawāʿid (1, 17, 36, 43, 46, 49, 50, 51, 61, 66, 91, 93, 152, 155); no id moves and no existing case changes. Six qawāʿid still have none: 44 (a restarted القسم sequence with no announcement), 48 and 89 (prose), 83 (a «الحالة الثانية» with no announced first), 135 (two wujūh) and 148 (a dual «مسألتان: إحداهما»). A division is a sub-rule with its own ruling, so it is annotated like a farʿ; its wujūh are the positions.

**Tranche 2 (qawāʿid 7, 27, 28, 64, 65; 25 furūʿ).** Five qawāʿid with no reading yet, each formalised from its own statement (`corpus/takhrij/rajab_m8_tranche2_furu.json`):

| Qāʿida | Reading | Link to the bank |
|---|---|---|
| 7: on finding the original mid-substitute, the switch is due if the substitute was a necessity, not if a concession | `mustSwitch`: the switch follows necessity | `necessity_is_q28`: the complement of al-Saʿdī's `useSubstitute` |
| 27: one who acts for another's benefit bears its cost, for his own does not | `liableForOthersBenefit` | new (al-Saʿdī Q36 divides by a different fact: benefit from the thing destroyed against repelling its harm) |
| 28: a loss from a permitted and a forbidden act together: the forbidden one bears all | `concurrentShare`: `full` if the other act was permitted, else `half` | new |
| 64–65: an act whose condition was met without his knowledge | `countsAsMet knew liabilityOnly`: the condition counts if known, or if only liability turns on it | `liability_not_by_belief`: Ibn Rajab's own ground in 64.f003 |

Results on the tranche:
- **2 derivable, 22 ikhtilāf (8 on the madhhab side), 1 missing rule, 0 encoding errors.** Coverage 24/25 = 0.960, madhhab coverage 10/25 = 0.400. One ledger entry is opened (65.f004, `rule:qisas_belongs_to_whom`).
- **What the cases say about the readings:**
  - **The low madhhab figure is the qāʿidas' own khilāf, not a misreading.** 7, 64 and 65 are stated as disputed («فيه وجهان», «روايتان»), and 14 of the 22 ikhtilāf cases mark no madhhab, which counts against madhhab coverage by convention. Three of those carry Ibn Rajab's own preference: the reading follows it in 64.f003 and 65.f002 («والأظهر عدم اعتباره») and goes against it in 27.f003. Where a side is marked (7.f000, 64.f001, all of 28) the reading is on it.
  - **28 tracks the madhhab throughout:** six cases, the full share on the stated ruling in each, the half a minority wajh. 28.f005 checks the guard: there the act was «غير مأذون فيه», and the stranger owes half, by naṣṣ.
  - **27.f003 goes against its own qāʿida in Ibn Rajab's judgement:** a forced oath to protect another binds (al-Qāḍī), but Abū al-Khaṭṭāb's «لا تنعقد» is «الأظهر». 27.f002 is split the same way (al-Qāḍī against Ibn ʿAqīl and Ibn al-Zāghūnī).
  - **7.f001, tayammum:** Ibn Rajab places it between the two kinds; the riwāya that the prayer is void reads it as necessity, which the reading follows.
  - **64.f003 refines 64–65:** for the usurper who eats food already permitted to him, Ibn Rajab rejects liability («الصواب الجزم بعدم الضمان»), since liability is not established by belief. Hence the reading's second argument; it would otherwise land on Abū al-Khaṭṭāb.

**Tranche 3, PR #32 contribution (qawāʿid 1, 17, 66, 91, 93; 21 furūʿ and divisions).** Five qawāʿid that only the list-and-division segmenter opened (`corpus/takhrij/rajab_m8_tranche3_furu.json`). A division is annotated like a farʿ: it is a sub-rule with its own ruling, and its wujūh are the positions.

| Qāʿida | Reading | Link to the bank |
|---|---|---|
| 1: is running water like still water, or is each jirya water on its own? («فيه خلاف») | `runningBody`: each jirya, the second limb (al-Qāḍī's madhhab on its first farʿ) | new |
| 17: one noble act against many of the same cost | `preferMany`: «ظاهر كلام أحمد ترجيح الكثرة» | new |
| 66: acting on a mistaken basis while the true one exists | `validWithBasis`: valid in both types («والمذهب هنا الصحة بلا ريب») | `q65_is_the_unbelieved_basis`: the contrast with q65's `countsAsMet` |
| 91: what the hand takes in | `handLiable`: what has a share of property, not the free person | new |
| 93: the ten hands that take from a usurper unaware | `takerRecourse`: recourse on the usurper unless he undertook the liability («دخل على ضمان … استقر ضمانها عليه») | `undertaken_settles` |

Results on the tranche:
- **5 derivable, 16 ikhtilāf (12 on the madhhab side), 0 encoding errors.** Coverage 21/21 = 1.000, madhhab coverage 17/21 = 0.810. One ledger entry is opened (1.f003, `rule:ayman_by_urf`).
- **What the cases say about the readings:**
  - **Qāʿida 93 tracks the madhhab in all eight segments**, on the thing and on the benefit alike: whoever undertook a liability bears it, and whoever did not has recourse. Ibn Rajab argues against the madhhab twice. In 93.f003 he holds that the taker who did not undertake the liability cannot be made liable at all («وينبغي أن يكون هو المذهب»). In 93.f005 he holds that the buyer's loss settles on the usurper («وهو عندي قياس المذهب»).
  - **Qāʿida 1's khilāf divides by subject.** Each jirya counts on its own for najāsa (al-Qāḍī's madhhab) and for lifting ḥadath (al-ashhar). The water counts as one body for washing a vessel (the ẓāhir of the aṣḥāb) and for the oath, where «الأيمان مرجعها إلى العرف» decides (Ibn Rajab's qiyās al-manṣūṣ). The oath case is the new gap.
  - **Qāʿida 17 holds where Aḥmad speaks** (prayer, sacrifice, the one who forces himself to obey). Where Aḥmad's narrations divide (recitation with reflection) or only later authorities speak (the precious slave), Ibn Rajab and Taqī al-Dīn prefer the noble act.
  - **Qāʿidas 66 and 65 are each other's complement:** the act stands when he relied on a basis he believed (66), and fails when he believed the basis absent (65).
- **Segmentation finding:** in qāʿida 93 the ninth and tenth hands begin mid-line («بخلاف ما على الشجر (اليد التاسعة)»), so they stay inside 93.f008. Both agree with the reading, as its note records.

**Tranche 3, PR #31 contribution (qawāʿid 31 and 47; eight existing records).** This continues after merged PR #30 rather than repeating tranche 2. Both full source sections are available in the locked OpenITI witness; the source replays the complete current Ibn Rajab record set exactly, including the 43 added list-and-division records. No record, identifier, source lock, earlier annotation or accepted conclusion is changed. The exact obligations, page-correct source excerpts, excerpt hashes, related Lean definitions, additional contrast guards and all nine open human-review questions (the original four plus five concerning PR #32's readings) are in [`rajab_m8_tranche3_plan.json`](../../corpus/worklists/rajab_m8_tranche3_plan.json).

| Qāʿida | Source-backed reading and regression value | Boundary |
|---|---|---|
| 31 (f001–f004) | `makeupAfterFailure`: corruption of a binding undertaking retains its begun description; prevention has a different make-up description. Faulty and non-faulty loss are separate inputs. Additional guards check both contrasts within f002 and f003 | The no-fault branch follows the author of al-Mughnī; the other wajh remains recorded. Apparent Aḥmad text in f004 is not assigned a new positive madhhab label. “Baseline” describes a subsequent make-up, not a newly inferred duty to make it up |
| 47 (f000–f003) | `defectiveCompensationBasis`: the selected sale/lease positions require equivalent compensation; the stated kitāba outcome and selected nikāḥ position use the named consideration. `defectiveCompensation` reuses `Muamalat.priceDue` only after the source fixes the basis; distinct test amounts catch incorrect price leakage | Both amount positions and their attributions remain explicit. The prohibited-consideration/void branch of kitāba is excluded. Agreement on an outcome does not resolve the contract-versus-condition explanations |

Selection used source availability, bounded size, case diversity and regression value. Q31 supplies pilgrimage, prayer, offerings and retreat cases; q47 supplies four transaction contexts and an opening record. Larger or less clean tranches such as q3 (several examples inside a record) and q12 (variant preferences) remain in the exact worklist. The neighboring substitute definitions are context, not an asserted equivalence with q31.

Results: **3 derivable, 5 ikhtilāf (3 with a source-marked madhhab label), no new encoding errors or capability gaps**. Record-level coverage is 8/8; madhhab coverage is 6/8 = 0.750. These are candidate annotations. Lean checks their stated encoding, not whether an independent scholar accepts that encoding, attribution or preference. The original four interpretation questions remain open; no register decision is adopted. Both contributions share one suite, with exact case fingerprints pinned to their original PR heads. The aggregate report, inventory and roadmap metrics are regenerated from the combined corpus. PR #32's oath/custom gap remains open, and the candidate statuses and 29 prior revisits are preserved.

Replay after caching the registered full witness and checking its lock hash:

```sh
cd pipeline
python -m usul_corpus takhrij
python -m usul_corpus m8-worklist
python -m usul_corpus docs
python -m usul_corpus signature
python -m pytest -q
cd ..
make validate generated lean
```

`m8-worklist --check` checks both the JSON inventory and the generated scope paragraphs in this note and the roadmap. The suite's source check verifies the full witness hash, exact record replay and all selected excerpt/page receipts when that witness is cached. Tests for other uncached witnesses report skips; they are not claimed as full-source replays.

**Round 5: the bank applied to its own gaps, after tranches 1–3.** Of the 14 open gaps, 8 close, each by the principle the case itself names. Every closure is cited in the [dossier](dossier.md) and is a new reading beside the old one (`revisit.from_encoder`), so no earlier result changes:

| Case | Was | Closed by | Ground |
|---|---|---|---|
| 68.f009 | missing rule | `rulingUndone`: undone only by a clear text | IQ-21's adopted principle, `ijtihad_not_overturned_by_ijtihad` (Ibn Abī Mūsā) |
| 1.f003 | ikhtilāf, needs ʿurf | `oathBody`: the oath's object measured by custom | al-Saʿdī Q9 (`Kulliyyat.measure`); «والأيمان مرجعها إلى العرف» |
| 22.f003, 22.f004 | ikhtilāf, minority side | `mixedOutcome`: same kind, indistinct, means shared | the manṣūṣ «أنه اشتراك» |
| 22.f007 | missing rule | `mixedHaram`: few, suspend; many, take out the share | Aḥmad's naṣṣ (al-Marrūdhī) |
| 68.f001 | missing fact | `rukhsaValid`: a concession needs its permission established | `rukhsa_is_firm_condition`: qāʿida 68's first type |
| 68.f007 | ikhtilāf, needs taʿlīq | `conditionedSaleValid`: a condition both know to hold adds nothing | al-Kāfī, with Aḥmad's naṣṣ on the absent sale |
| 65.f004 | missing rule | `pardonOfSpreadValid`: void if the right is the heirs' | `heirs_right_is_q65`; al-Qāḍī's jazm |

Four of the eight now land on the madhhab side (22.f003, 22.f004, 22.f007, 65.f004). The other four are disputes with no madhhab marked; the reading follows Ibn Rajab in 1.f003. Six gaps stay open:
- the four command gaps of Ibn al-Laḥḥām 43, which are uṣūl proper and wait for M5's schemata;
- 52.f007, which has no transmitted ruling;
- 22.f000, which bundles a case agreed «بغير خلاف» (much water) with a disputed one (little water) in a single record.

**Tranche 4 (qawāʿid 2, 20, 21, 24; 21 furūʿ).** Read from each qāʿida's own statement (`corpus/takhrij/rajab_m8_tranche4_furu.json`):

| Qāʿida | Reading | Link to the bank |
|---|---|---|
| 2: hair and nails are as detached («هذا هو جادة المذهب») | `hairStatus` | new |
| 20: growth from the substance is as a part; growth from earnings is not («على الصحيح») | `growthKind` | new |
| 21: is the child a part or earnings? («والأظهر أنه جزء») | the same encoder | `child_is_part`: 21 is 20 applied |
| 24: property that a due right attaches to may be transferred; the right survives if it is on the property, or if its reason does not cease with the transfer | `rightSurvivesTransfer` | `owner_right_lapses_with_its_reason`, `property_right_survives` |

Results on the tranche:
- **7 derivable, 14 ikhtilāf (5 on the madhhab side), 0 encoding errors, no new gaps.** Coverage 21/21 = 1.000, madhhab coverage 12/21 = 0.571.
- **What the cases say about the readings:**
  - **Qāʿida 2 holds wherever a madhhab is marked**, for wuḍūʾ, impurity, divorce attached to the hair, and the beard as covering in prayer (Aḥmad's naṣṣ). The exception is inside 2.f002: the hanging hair is washed in the minor ḥadath «على الصحيح», against the qāʿida.
  - **Qāʿidas 20 and 21 mark a madhhab only where the aṣḥāb take the yield as a part** (20.f003, the ashhar; 20.f005, many aṣḥāb). Elsewhere two riwāyas stand, and the qāʿida's «على الصحيح» decides only between substance and earnings, not each farʿ.
  - **Qāʿida 24 separates the punitive from the remedial right.** Burning the thief's goods (24.f000) punishes a past act, so the sale does not end it. Lowering the dhimmī's building (24.f002) removes an ongoing harm, which ends with the transfer, as the text itself contrasts («لا عقوبة للتعلية الماضية»).
- **Segmentation finding:** qāʿida 21's first example opens mid-line («والأظهر أنه جزء فمن ذلك …»), so it has no `.f000`. Qāʿida 9, whose inline «(ومنها)» joins several cases in one record, is left for the segmenter.

**Tranche 6 (qawāʿid 3, 9, 14, 15; 15 furūʿ).** Read from each qāʿida's own statement (`corpus/takhrij/rajab_m8_tranche6_furu.json`):

| Qāʿida | Reading | Link to the bank |
|---|---|---|
| 3: doing more than suffices: is the whole obligatory? («ففيه وجهان») | `wholeObligatory`: only when the excess cannot be told apart and the whole was the original duty, lightened («وصف الكل بالوجوب على الصحيح»); an excess over the due is taṭawwuʿ (al-Qāḍī, «وهو الصواب») | `separable_excess_is_nafl` |
| 9: worship done in a prohibited way | `worshipValidDespite` over four sites; the general condition takes «أشهرهما عدمها», the non-condition «الأكثرون» | `q9_refines_q38`: agrees with al-Saʿdī Q38 on every site |
| 14: a cause from one of two, unknown which («فيه خلاف») | `oneOfTwoAttaches`: only when the two are taken together, «فينظر إليهما مجتمعين في حكم يتعلق باجتماعهما» | T-15 |
| 15: a presumption does not carry its consequence into another («على الصحيح») | `consequenceCarries` | T-15 |

Tranche 6: 5 derivable, 10 ikhtilāf (3 matching the madhhab); coverage 1.000, madhhab coverage 0.533, no new gaps. Q14 with Q15 is the register's pair T-15.

**Tranche 5 (qawāʿid 25, 29, 30, 32, 33, 34; 27 furūʿ).** Read from each qāʿida's own statement (`corpus/takhrij/rajab_m8_tranche5_furu.json`):

| Qāʿida | Reading | Link to the bank |
|---|---|---|
| 25: does what is attached to or born of a thing follow ownership proven by evidence or confession? («فيه خلاف») | `followsProven`: Ibn Rajab's recurring measure, what follows in sale follows here | new |
| 29: a tolerated amount exceeded: does tolerance lapse in all, or in the excess? («فيه وجهان») | `toleranceLapse`: in all when at fault, in the excess otherwise, Ibn Rajab's distinction in 29.f003 | new |
| 30: what was given out as due and failed to count: does it return? («فيه خلاف») | `returnsToOwner` | new |
| 32: excepting the benefit of a transferred thing («يصح عندنا … مدة معلومة») | `benefitExceptionValid`: a known period, or a transfer that tolerates uncertainty (waqf, manumission) | `known_period_suffices` |
| 33: the implicit exception tolerates uncertainty («والصحيح … الصحة، وهو قياس المذهب») | `uncertainExceptionValid` | new |
| 34: benefits owed under a binding contract are not reached by manumission | `manumissionReachesBenefits` | `binding_is_implicit_exception`: 34 is 33 applied |

Results on the tranche:
- **12 derivable, 15 ikhtilāf (7 on the madhhab side), 0 encoding errors, no new gaps.** Coverage 27/27 = 1.000, madhhab coverage 19/27 = 0.704.
- **What the cases say about the readings:**
  - **Qawāʿid 32–34 form one chain.** An exception of benefit is valid when stated for a known period (32). When it arises by law it is valid even for an unknown period (33: the leased house, the married slave, the muḥrim). A binding contract over the benefits is such an exception, so manumission stops at it (34). Qāʿida 33's madhhab side is «قياس المذهب» against al-Qāḍī, and 34's is the madhhab against Taqī al-Dīn's spreading of manumission.
  - **Qāʿida 29's dispute resolves by fault.** The ashhar in 29.f003 (impurity beyond its place) limits the lapse to the excess, and Ibn Rajab grounds it in the absence of negligence «بخلاف الوكيل والمضحي». The reading takes that as its parameter, so the agent and the sacrificer land on the whole; no madhhab is marked for them.
  - **Qāʿidas 25 and 30 are stated as khilāf throughout.** 25 tracks the madhhab where it is marked (the trees, the ashhar on containers); 30 marks none.
- **Segmentation finding:** 32's first example follows «مسائل منها:» without the colon the opening rule expects, so it has no `.f000`; 29's first case is a «(منها)» paragraph and is `.f001`.

**Tranche 6 (qawāʿid 35, 37, 38, 39, 41; 24 furūʿ).** Read from each qāʿida's own statement (`corpus/takhrij/rajab_m8_tranche6_furu.json`):

| Qāʿida | Reading | Link to the bank |
|---|---|---|
| 35: owning the benefit by contract, then the thing | `priorContractDissolves`: only a perpetual commutative contract (nikāḥ); a lease stands («لا ينفسخ وهو الصحيح») | new |
| 37: successive contracts on one thing | `laterContractGoverns`: the later contract's ruling governs the hand | new |
| 38: contract words joined with what takes them out of their nature («المغلب هل هو اللفظ أو المعنى») | `asKinayaValid`: the meaning, a kināya for what can be valid | new |
| 39: contracts by allusion | `kinayaConcludes`: every contract but one that needs witnessing | `witnessed_needs_explicit` |
| 41: a bound right and the destroyed thing's substitute («فيه خلاف») | `rightPassesToSubstitute` | `substitute_as_transfer`: qāʿida 24's right on the property |

Results on the tranche:
- **7 derivable, 17 ikhtilāf (3 on the madhhab side), 0 encoding errors, no new gaps.** Coverage 24/24 = 1.000, madhhab coverage 10/24 = 0.417.
- **What the cases say about the readings:**
  - **Qāʿida 38's marked madhhab is the wording, not the meaning.** Where a side is marked it is against the reading: the ẓāhir of Aḥmad that salam does not conclude a present sale (38.f004), and Abū al-Khaṭṭāb calling the loan with a countervalue void «المذهب» (38.f000). The meaning prevails only where a naṣṣ rules on validity (38.f003) or no side is marked. The reading is kept, being the qāʿida's stated alternative, and the result is recorded: on this qāʿida the madhhab leans to the word.
  - **Qāʿida 37 splits the same way.** The later contract governs where it binds (the pledge on usurped goods, the pledge of the sold thing, Abū al-Barakāt's qiyās al-madhhab). Majd al-Dīn reports the ẓāhir of Aḥmad against it where it does not bind: a pledge or deposit used with permission is not liable. Reconciled afterwards by jamʿ on Abū al-Barakāt's binding farq (`successive_by_binding`; see [reconciliation](taarud-reconciliation.md)).
  - **Qāʿida 35 tracks the madhhab** (the ṣaḥīḥ, al-Qāḍī's Khilāf), and 41's single marked side, the ẓāhir of the aṣḥāb on the pledge's value, is the reading.
  - **39.f002 contains Aḥmad's own exception to 39's exception:** «أجعل عتقك صداقك … كل ذلك جائز إذا كانت له نية», an allusion concluding a marriage. The farʿ is annotated for the rajʿa it opens with.
- **Segmentation finding:** 39's prelude is its general statement, so it has no `.f000`; its two furūʿ are `.f001` and `.f002`.

**Tranche 7 (qawāʿid 3, 5, 9, 10, 12; 24 furūʿ).** Read from each qāʿida's own statement (`corpus/takhrij/rajab_m8_tranche7_furu.json`):

| Qāʿida | Reading | Link to the bank |
|---|---|---|
| 3: an undistinguished excess over what suffices («ففيه وجهان») | `excessObligatory`: obligatory only where the whole was the duty, lightened («على الصحيح»); otherwise voluntary (al-Qāḍī, «وهو الصواب») | new |
| 5: an act advanced before its time, the state then changing | `advancedSuffices`: it suffices when it was the duty at performance («كان فرضه في الظاهر فبرئ به») | new |
| 9: worship performed in a prohibited way | `validDespite`: valid only where the prohibition returns to what is no condition («وخالفه الأكثرون») | new |
| 10: wordings in worship and contracts | `otherTongueValid`: where only the meaning counts, or he cannot manage the Arabic | new |
| 12: worship transmitted in several forms | `combineForms`: not where the forms are substitutes («لا يصح الجمع بين البدل والمبدل») | new |

Results on the tranche:
- **9 derivable, 15 ikhtilāf (3 on the madhhab side), 0 encoding errors, no new gaps.** Coverage 24/24 = 1.000, madhhab coverage 12/24 = 0.500.
- **What the cases say about the readings:**
  - **Qāʿidas 3, 10 and 12 are stated as khilāf**, and Ibn Rajab marks no madhhab on their disputed furūʿ. The readings take his own resolutions: the lightened whole (3), the meaning-or-inability rule (10), and Taqī al-Dīn's substitute criterion (12). That criterion also explains why Aḥmad combines the two Friday sunnas («جمعت فعله وأمره»): two prayers are not substitutes for one another.
  - **Qāʿida 5** follows the unqualified statements of most aṣḥāb against al-Mughnī and Ibn al-Zāghūnī. It also follows the manṣūṣ on the boy's prayer, which discharged no duty.
- **Reconciliation:** the 12 new apparent contradictions entered the ledger (`corpus/reconciliation/`), with their later taṣḥīḥ imported as for the earlier tranches. Four became jamʿ, each on a farq the later works cite: following (3.f000, `excessObligatoryIn`), the kaffāra at its wujūb (5.f001, `advancedSufficesIn`), and no duty to learn the Arabic for an act not itself due (10.f004, f005, `otherTongueValidIn`). The tranche's madhhab coverage rises to 16/24 = 0.667.
- **Segmentation finding:** 9.f000 and 9.f001 each run several «(ومنها)» examples together, because the inline examples sit mid-line (the known 9 edge). Each is annotated for its leading example.

**Tranche 8 (qawāʿid 4, 11, 14, 15, 19; 27 furūʿ).** Read from each qāʿida's own statement (`corpus/takhrij/rajab_m8_tranche8_furu.json`):

| Qāʿida | Reading | Link to the bank |
|---|---|---|
| 4: advancing worship | `advanceAllowed`: once its cause exists («ويجوز تقديمها بعد سبب الوجوب وقبل الوجوب») | qāʿida 5 (the advanced act's sufficiency) |
| 11: the voluntary before the obligatory of its kind | `naflValid`: not while the obligatory is narrow («لم تصح على الصحيح»), except a financial duty (`zakat_carve_out`) | new |
| 14: a cause from one of two men, not known which («في المسألة خلاف») | `attachTo`: both where it costs no right («لا ضرر فيه»), else neither bound with each abstaining (Aḥmad's naṣṣ) | new |
| 15: an aṣl's corollary against another aṣl | `eachOnItsAsl` («لم يلتفت إلى ذلك اللازم على الصحيح») | new |
| 19: ability and the dhimma | `settlesInDhimma`: ability is no condition, except for making up («على ظاهر المذهب») | new |

Results on the tranche:
- **15 derivable, 12 ikhtilāf (8 on the madhhab side), 0 encoding errors, no new gaps.** Coverage 27/27 = 1.000, madhhab coverage 23/27 = 0.852.
- **What the cases say about the readings:**
  - **Qāʿida 4 is wholly derivable.**
  - **Qāʿida 11 has a carve-out for zakāt.** A voluntary ṣadaqa is valid before an immediate zakāt («فقال الأصحاب يصح»). The reading therefore carries it as a fact (`financial`), and the narrowness test belongs to pure acts of worship of one kind.
  - **Qāʿida 14's raven oaths repeat Ibn Rajab's qāʿida 160 under another name.** The reading takes Aḥmad's naṣṣ: neither is bound, and each abstains until certain. The later madhhab confirms this («لم تطلقا … وحرم الوطء عليهما»).
- **Reconciliation:** the 4 apparent contradictions entered the ledger, with their later taṣḥīḥ imported as before. Three are residues against the reading, and none of them has a cited farq for a jamʿ:
  - On qāʿida 14 the later madhhab rules for purification as for divorce: neither must wash (14.f000, «على الصحيح من المذهب»), against Ibn Rajab's own «لا ضرر فيه».
  - On qāʿida 19, al-Mardāwī's taṣḥīḥ and the muʿtamad give tayammum to the traveller as the time runs out (19.f001), and make ability a condition of the ḥajj's wujūb (19.f005).

**Tranche 9 (qawāʿid 36, 42, 43, 46, 49, 50, 51; 16 furūʿ).** These qawāʿid are typological: each record is a division, annotated for its leading ruling (`corpus/takhrij/rajab_m8_tranche9_furu.json`):

| Qāʿida | Reading |
|---|---|
| 36: a lease whose lessor's authority ends | `leaseDissolves`: unless the new holder succeeds the lessor («بل هو منفذ لها») |
| 42: returning what is held for another | `returnAtOnce`: where held without consent, or guaranteed («فتجب المبادرة إلى الرد بكل حال») |
| 43: liability for continued holding | `holderLiable`: only one who withholds («فهو غاصب»; «لتعديه بترك الرد مع إمكانه»); after a contract ends, `liableAfterEnding`: where he caused the ending (al-Mughnī's ẓāhir) |
| 46: whether a void contract is concluded | `voidConcluded`: only a binding one with a pervasive effect (iḥrām, nikāḥ, kitāba) |
| 49: qabḍ in contracts | `bindsWithoutQabd`: unless qabḍ completes the contract (salam, ribawī) |
| 50: forced acquisitions and the price | `ownedBeforePayment`: only under necessity («والضرر لا يزال بالضرر»); reconciled to `ownedBeforePaymentIn`: or, on the shufʿa only, by a solvent shafīʿ |
| 51: ḍamān without qabḍ | `inNewOwnersDaman`: what is determined |

Results on the tranche:
- **12 derivable, 4 ikhtilāf (3 on the madhhab side), 0 encoding errors, no new gaps.** Coverage 16/16 = 1.000, madhhab coverage 15/16 = 0.938. 43.f001's wujūh turn on who caused the contract's ending, so it gets its own reading on that fact rather than a gap. The bank's gaps stay the six original ones.
- **Reconciliation:** the two new apparent contradictions entered the ledger. The madhhab on the shufʿa (50.f001), «يملكه بمجرد المطالبة إذا كان مليئا بالثمن، وهو المذهب», became a jamʿ on that solvency farq (`ownedBeforePaymentIn`), restricted to the shufʿa by a `shufa` fact since the farq is cited for it alone, and solvency answers Ibn Rajab's own «والضرر لا يزال بالضرر». On 43.f001 the muʿtamad (al-Muntahā, Kashshāf) makes the rescinded sale object a trust in the buyer's hand, against `liableAfterEnding`. That is a residue.

**Tranche 10 (qawāʿid 52, 54, 56, 58, 61, 62; 19 furūʿ).** Typological records are annotated for their leading ruling (`corpus/takhrij/rajab_m8_tranche10_furu.json`):

| Qāʿida | Reading |
|---|---|
| 52: disposal before qabḍ | `disposeBeforeQabd`: barred only in the undetermined («جادة المذهب ... إلا في المبهم خاصة») and where the right is not settled; reconciled to `disposeBeforeQabdIn`: and a debt to any but the debtor |
| 54: disposing so as to extinguish another's right | `mayDisposeOver`: not without his leave, «والصحيح أنه لا يجوز أيضا» |
| 56: conditions concurrent with the contract | `conditionMet`: concurrence suffices («المنصوص عن أحمد الاكتفاء بالمقارنة») |
| 58: desisting from what one is engaged in | `desistIsAct`: only where he began knowing the prohibition imminent |
| 61: the imām and his deputies | `removedWithPrincipal`: unless the mandate is general; reconciled to `removedWithPrincipalIn`: the qāḍī's deputies are removed with him |
| 62: removal before it is known | `removedBeforeKnowledge`: at once, except a public office («شبيه بنسخ الأحكام») |

Results on the tranche:
- **5 derivable, 14 ikhtilāf (9 on the madhhab side), 0 encoding errors, no new gaps.** Coverage 19/19 = 1.000, madhhab coverage 14/19 = 0.737. The bank's gaps stay the six original ones.
- **Verification:** every ikhtilāf annotated as on the madhhab side was checked against al-Inṣāf and the muʿtamad. Four were not (56.f002, 56.f004, 58.f001, 61.f001) and entered the ledger. 62.f002 was re-read: the keeper's annulment by word dissolves the deposit at once (al-Qāḍī's usual statement and the muʿtamad), so no keeper fact is needed.
- **Reconciliation:** 7 new apparent contradictions, 23 evidence items. Two are jamʿ on farqs the madhhab states: the deeds (52.f001) fall under «ولا يجوز لغيره», a debt sold only to the debtor (`disposeBeforeQabdIn`), and the qāḍī's general deputies (61.f001) are removed with him, «لأنهم نوابه» (`removedWithPrincipalIn`). Five are residues: on qāʿida 56 the madhhab voids the sale joined to a kitāba (f002) and agency to divorce a woman not yet married (f004), and clears the umm walad by one period (f006), each against concurrence; 56.f003 has no later treatment and leans to al-Qāḍī's «الأشبه»; on 58.f001 the muʿtamad owes the kaffāra «لأن النزع جماع».

**Tranche 11 (qawāʿid 55, 57, 59; 22 furūʿ).** Typological records are annotated for their leading ruling (`corpus/takhrij/rajab_m8_tranche11_furu.json`):

| Qāʿida | Reading |
|---|---|
| 55: disposal by one with a right to own | `disposalTakes`: not a taking and not effective («المذهب المشهور»), unless the cause of ownership is complete (the legatee after the death) or his own tie never lapsed (the rajʿiyya) |
| 57: a ruling coinciding with its bar | `holdsAgainstBar`: does not hold («المذهب المشهور أنه لا يثبت»); coinciding only with the bar's cause, it holds |
| 59: annulment of what no longer exists | `annulsNonexistent`: annulments fall on the non-existent («على الصحيح»); reconciled to `annulsNonexistentIn`: no return for a defect once the thing perishes |

Results on the tranche:
- **5 derivable, 17 ikhtilāf (15 on the madhhab side), 0 encoding errors, no new gaps.** Coverage 22/22 = 1.000, madhhab coverage 20/22 = 0.909. The bank's gaps stay the six original ones.
- **Verification:** every ikhtilāf was checked against al-Inṣāf and the muʿtamad before the ledger. Three annotated off the madhhab were on it (57.f003, f005, f006); for 57.f005 the muʿtamad has the two coinciding gifts share («فيتحاصان لتقارنهما»), so the reading needs no separate «bar first» fact. Two annotated on it were not (59.f004, f005). 55.f003 and 59.f006 have no later treatment and keep their annotation.
- **Reconciliation:** 3 contradictions, 8 evidence items. 59.f004 is a jamʿ on the madhhab's farq, the return impossible once the defective thing perishes («وهذا المذهب. وعليه أكثر الأصحاب»; `annulsNonexistentIn`). 59.f005 (iqāla after loss) stays with the reading by tarjīḥ, al-Qāḍī's «قياس المذهب» outranking the muʿtamad's jazm while al-Inṣāf is undecided, and is listed for review. 57.f002 is annotated for the branch where the free woman would suffice him, the only one with a bar to coincide (where she would not, the madhhab validates both, as the reading gives); there only Ibn Rajab's own fāʾida, quoted in al-Inṣāf, is found against al-Qāḍī and Abū al-Khaṭṭāb, so it rests in tawaqquf. 57.f004 is annotated for its leading ruling, divorced by the repetition («المشهور عند الأصحاب»; al-Inṣāf, «على الصحيح من المذهب»).

**Lane A, round 1 (parallel; qawāʿid 53, 60, 67, 69, 71, 72, 73, 74, 77, 78, 79, 80, 81, 90, 92; 91 furūʿ).** The first parallel run of the [method](derivation-method.md#5-parallel-runs): four shards (`rajab-a1` … `rajab-a4`) each worked from the pinned base `8cd49f8` in an isolated worktree, writing only their own claim, Lean module (`Usul/Readings/RajabA1` … `A4`), encoder fragment, suite and ledger fragment, and verified every madhhab side against al-Inṣāf and the muʿtamad before setting it. One integrator merged them in order and regenerated once. Readings, by shard:

| Shard | Qāʿida: reading |
|---|---|
| a1 | 60 `rescission` (barred, with remedy, free); 67 `recourseAfterReturn` (gift founds recourse, release not); 69 `mayDelegate`; 71 `mayEat` |
| a2 | 72 `nafaqaStipulable`, `nafaqaOwned`; 73 `benefitConditionValid`; 74 `wageWithoutStipulation`; 79 `ownerTakesCrop`; 80 `asTree` |
| a3 | 53 `disposalStands` (fails only where the right is demanded and fixed in the thing); 78 `lossLiable` |
| a4 | 77 `takenOverAtValue`; 81 `attachedGrowthFollows`, `cutSaleVoid`; 90 `seizingHandLiable`; 92 `liableWithOwnerHand` |

Results on the round:
- **37 derivable, 54 ikhtilāf (37 on the madhhab side), 0 encoding errors, no new gaps.** Coverage 91/91 = 1.000, madhhab coverage 74/91 = 0.813. Facts a reading lacked were added to it rather than recorded as gaps (71's `compensatedOtherwise`, 81's second reading for the cut sale).
- **Reconciliation:** 17 contradictions with 35 evidence items, all residues against their readings. At integration 77.f006's grades were corrected: Ibn Rajab's own «والصحيح الأول» is an author's preference (`ashab`), not a taṣḥīḥ, so al-Inṣāf's «هذا المذهب مطلقا» prevails.
- **Register questions** raised by the shards are listed in [`taarud-reconciliation.md`](taarud-reconciliation.md).

**Lane A, round 2 (parallel; qawāʿid 94–102, 104, 105; 89 furūʿ).** Four shards (`rajab-a5` … `rajab-a8`) from the pinned base `b796eb5`, as in round 1. Readings, by shard:

| Shard | Qāʿida: reading |
|---|---|
| a5 | 94 `secondReceiverLiable`; 95 `errorActorLiable` (an apparent external cause frees; a void basis binds when the ruling is overturned; otherwise as owner or negligent); 97 `disposeWithoutJudge` |
| a6 | 96 `ownedDischarge`, `unownedDischarge` (the qāʿida's two kinds); 98 `byDescription`; 99 `freeAyn`, `freeBenefit` |
| a7 | 100 `vowedRuling` (the vow as an obligation of the sharʿ); 101 `splitSuffices` (halves counted in one unit); 102 `causeVoided`, with its attached qāʿida `hastenedForfeited` |
| a8 | 104 `unknownConsentBinds`; 105 `vagueInshaValid`, `vagueReportAccepted`, `sharedNameValid`, `lotDistinguishes` |

Results on the round:
- **45 derivable, 44 ikhtilāf (34 on the madhhab side), 0 encoding errors, no new gaps.** Coverage 89/89 = 1.000, madhhab coverage 79/89 = 0.888. In review two cases moved to derivable because their positions differed on the facts, not on the reading: 96.f004 is annotated for its leading ruling (the uḍḥiya designated from the outset; the dhimma branch, where Ṣāḥib al-Talkhīṣ requires the owner's intention, needs a fact the reading lacks), and in 95.f002 the khilāf is antecedent, over whether the ruling is overturned, and each side's ruling is the reading's output on its own facts.
- **Reconciliation:** 10 contradictions with 23 evidence items: 7 residues against their readings, 2 with them (104.f012, 105.f009, both register questions) and 1 tawaqquf. At integration 96.f006's grades were corrected: al-Qāḍī with Ibn ʿAqīl are two named companions (`ashab`), not the aṣḥāb at large (`jazm`), so against Abū al-Khaṭṭāb with Ibn Rajab's preference the entry rests in tawaqquf.
- **Register questions** are listed in [`taarud-reconciliation.md`](taarud-reconciliation.md).

**Lane A, round 3 (parallel; qawāʿid 107–118; 89 furūʿ).** Four shards (`rajab-a9` … `rajab-a12`) from the pinned base `3cd93a8`, with round 2's review lessons in the brief (positions must disagree under the same facts; a disputed fact is never an input). Readings, by shard:

| Shard | Qāʿida: reading |
|---|---|
| a9 | 107 `maadumGrantValid`; 108 `judgedSequential`; 110 by branch: `otherOptionStands`, `refusalExactedForHim`, `refusalRightFalls`, `refusalCompelledToChoose`, `rightOnRefuserExacted`, `substituteRefusalJudgedByOriginal` |
| a10 | 109 `vagueOneBarsAll`, `combinationBarsItsAmount`, `simultaneousCombinationVoids`, `commonAmountGeneral`; 111 `alternativeProvenAlone` |
| a11 | 112 `necessityPermits`; 113 `eachOverWhole`; 114 `sharikaHalves`; 115 `accruesToRest` |
| a12 | 116 `ruledFromCause`, `worshipFromStart`; 117 `occurrenceGoverns`; 118 `cancelOnExistenceValid` |

Results on the round:
- **35 derivable, 54 ikhtilāf (33 on the madhhab side), 0 encoding errors, no new gaps.** Coverage 89/89 = 1.000, madhhab coverage 68/89 = 0.764. Q113 (distribution over the whole), Q116 (relating back) and Q117 (the state at occurrence) carry most of the residues: on each, the later madhhab follows the other side in a class of furūʿ (see the candidate farqs).
- **Reconciliation:** 21 contradictions with 55 evidence items: 19 residues, 1 for the reading (114.f003, on cognate rulings only) and 1 tawaqquf (109.f018). At integration two iḥtimālāt graded as bare wujūh were regraded `takhrij` (109.f018, 114.f003); neither outcome changed.
- **Register questions** are listed in [`taarud-reconciliation.md`](taarud-reconciliation.md).

**Lane A, round 4 (parallel; qawāʿid 119–126, 128–131; 80 furūʿ).** Four shards (`rajab-a13` … `rajab-a16`) from the pinned base `50f04fc`; the brief added round 3's review lessons (an iḥtimāl grades takhrīj; every reading total over its facts, a bar forcing the output false whatever else holds, with a theorem). Readings, by shard:

| Shard | Qāʿida: reading |
|---|---|
| a13 | 119 `specificSingledOut`, with its attached qawāʿid `takesOnlyBySpecial` and `entitlementMultiplies`; 120 `doubleKinshipPreferred`; 122 `customRestricts`; 124 `causeRestricts` |
| a14 | 121 `urfGeneralCovers`; 123 `sharGeneralCovers`; 126 `unintendedCovered` |
| a15 | 125 `intentionGoverns`; 128 `spreadFollowsInjury`, `measuredAtInjury` |
| a16 | 129 `hitStateGoverns`, `aqilaBears`; 130 `countsAsSurplus`; 131 `countsAsRich` |

Results on the round:
- **31 derivable, 49 ikhtilāf (28 on the madhhab side), 0 encoding errors, no new gaps.** Coverage 80/80 = 1.000, madhhab coverage 59/80 = 0.738. Q127 was annotated on main meanwhile (shard rajab-q127, `mubashara_tasabbub`); a16's duplicate reading and nine cases of it were dropped when main was merged, each farʿ being annotated once. Q121 (custom specialising the general) carries eight of the residues: its reading takes specialisation for the qāʿida's unmarked third class (RQ-02).
- **At integration** 125.f007 moved to derivable (the only contrary is a Shāfiʿī's «مقتضى مذهبكم», not a position within the madhhab), with its ledger entry. Moving 127.f004, f006 and f008 too was reverted in review: there the positions dispute the *legal characterization* of one concrete scenario (is the stone-placer a pusher or a holder; does compulsion excuse), not a fact of the case, and Ibn Rajab's own placement of each in the qāʿida's classes fixes the reading's facts. Unlike 95.f002 (round 2), where the dispute is over a separate antecedent ruling, such cases stay `genuine_ikhtilaf` (main's rajab-q127 annotates them so).
- **Reconciliation:** 21 contradictions with 38 evidence items: 17 residues, 2 for the reading, 2 tawaqquf.
- **Register questions** are listed in [`taarud-reconciliation.md`](taarud-reconciliation.md).

**Lane A, round 5 (parallel; qawāʿid 132, 134, 136–139, 141–146; 92 furūʿ).** Four shards (`rajab-a17` … `rajab-a20`) from the pinned base `c780c5f`, under the owner's rule that every ikhtilāf has a tarjīḥ: on-madhhab cases get ledger entries too, and each must confirm its side. The brief added round 4's lessons and the source gate (no excerpt may stop before a qualifier). Readings, by shard:

| Shard | Qāʿida: reading |
|---|---|
| a17 | 132 `craftCountsAsRich`; 134 `impedimentOperates`; 136 `preliminariesForbidden`; 139 `unfixedMayReachFixed`; 141 `dueTimeGoverns` |
| a18 | 137 `forfeitsAttachedRight`, `sulhReplacesWealth`; 138 `mustCompensate` |
| a19 | 142 `returnedIsFirst`; 143 `badalStands`; 145 `bainAsWife` |
| a20 | 144 `heirInherits`, `heirStandsIn`; 146 `wifeRuleApplies` |

Results on the round:
- **35 derivable, 57 ikhtilāf (41 on the madhhab side), 0 encoding errors, no new gaps.** Coverage 92/92 = 1.000, madhhab coverage 76/92 = 0.826.
- **At integration** 144.f005 moved to the madhhab side. No later work treats its facts and Ibn Rajab gives no label, so the bank's grade order decides (invariant 10): Aḥmad's ẓāhir outranks the majority's and a cognate taṣḥīḥ. The fourteen new encoders were typed (`Usul.Typing`, Ibn Rajab 132–146), and a leading paragraph mark was removed from twelve excerpts.
- **Reconciliation:** 57 entries with 151 evidence items, one for every ikhtilāf. All 41 on-madhhab entries confirm their side; the 16 others are residues. No research question was needed.

**Lane A, round 6 (parallel; qawāʿid 147, 149–158; 103 furūʿ).** Five shards (`rajab-a21` … `rajab-a25`) from the pinned base `4ab6af7`, under the rule that every ikhtilāf has a tarjīḥ. The brief added round 5's lessons: no markup in an excerpt (now failed by the excerpt check), the grade of a single named companion, and fact names specific to their qāʿida. Readings, by shard:

| Shard | Qāʿida: reading |
|---|---|
| a21 | 147 `womanHalf`; 149 `determinateHolderRule`; 150 `causeGovernsTransfer`; 152 `marriageProhibited`; 155 `mahrEstablished` |
| a22 | 151 `halCarriesClaim`; 154 `budExitCharged` |
| a23 | 153 `grandchildCountsAsChild`; 157 `transfersToNewIdda` |
| a24 | 156 `mahrHalved` |
| a25 | 158 `firstAslGoverns` |

Results on the round:
- **50 derivable, 53 ikhtilāf (37 on the madhhab side), 0 encoding errors, no new gaps.** Coverage 103/103 = 1.000, madhhab coverage 87/103 = 0.845.
- **Readings that pin an unmarked side.** Two readings choose where their qāʿida leaves a choice open (RQ-02). Q156 halves the mahr for a separation shared by the wife and another, the first-named of two unmarked riwāyāt. Q158 takes the first-stated wajh when neither aṣl is reinforced, which is so in 16 of its 18 furūʿ. Each choice is a named constant with its theorem, and the ledger carries the tarjīḥ of every case.
- **A side named only in al-Inṣāf.** Where Ibn Rajab marks a split («على ظاهر المذهب», «فالمعروف») without naming the other side, the contrary riwāya is taken from al-Inṣāf and the case is ikhtilāf, with its tarjīḥ (147.f003, 150.f002, 153.f010, f011, f018).
- **Reconciliation:** 53 entries with 155 evidence items, one for every ikhtilāf. All 37 on-madhhab entries confirm their side; the 16 others are residues. Q151 (dalālat al-ḥāl) carries five of them: the madhhab takes the stated words over the circumstance. No research question was needed.

**Coverage trend:**

| Stage | Cases | Coverage | Madhhab coverage | Encoding errors | Open gaps |
|---|---|---|---|---|---|
| M4 first tranche | 204 | 0.873 | 0.534 | 7 | — |
| M4 rounds 1–4 (the bank applied to itself) | 214 | 0.977 | 0.648 | 0 | 5 |
| M8 tranche 1 alone | 23 | 0.870 | 0.609 | 0 | 6 |
| M4 with its 9 opening examples | 223 | 0.977 | 0.658 | 0 | 5 |
| M8 tranche 1 with its 3 opening examples | 26 | 0.846 | 0.615 | 0 | 7 |
| All, after the opening-example fix | 249 | 0.964 | 0.653 | 0 | 12 |
| M8 tranche 2 alone | 25 | 0.960 | 0.400 | 0 | 1 |
| All, after tranche 2 | 274 | 0.963 | 0.630 | 0 | 13 |
| PR #32 contribution alone | 21 | 1.000 | 0.810 | 0 | 1 |
| All, after PR #32 merged (historical) | 295 | 0.966 | 0.643 | 0 | 14 |
| All, after round 5 (the bank applied to its gaps) | 303 | 0.980 | 0.659 | 0 | 6 |
| M8 tranche 4 alone | 21 | 1.000 | 0.571 | 0 | 0 |
| All, after tranche 4 | 324 | 0.981 | 0.653 | 0 | 6 |
| M8 tranche 5 alone | 27 | 1.000 | 0.704 | 0 | 0 |
| All, after tranche 5 | 351 | 0.983 | 0.657 | 0 | 6 |
| M8 tranche 6 alone | 24 | 1.000 | 0.417 | 0 | 0 |
| All, after tranche 6 | 375 | 0.984 | 0.642 | 0 | 6 |
| All, after reconciliation (jamʿ on qāʿida 37) | 375 | 0.984 | 0.647 | 0 | 6 |
| All, after the reconciliation refinements (qāʿidas 16, 64–65) | 375 | 0.984 | 0.668 | 0 | 6 |
| M8 tranche 7 alone | 24 | 1.000 | 0.500 | 0 | 0 |
| All, after tranche 7 | 399 | 0.985 | 0.658 | 0 | 6 |
| All, after tranche 7's reconciliation | 399 | 0.985 | 0.668 | 0 | 6 |
| M8 tranche 8 alone | 27 | 1.000 | 0.852 | 0 | 0 |
| All, after tranche 8 | 426 | 0.986 | 0.680 | 0 | 6 |
| M8 tranche 9 alone | 16 | 1.000 | 0.938 | 0 | 0 |
| All, after tranche 9 | 442 | 0.986 | 0.689 | 0 | 6 |
| M8 tranche 10 alone | 19 | 1.000 | 0.737 | 0 | 0 |
| All, after tranche 10 | 461 | 0.987 | 0.691 | 0 | 6 |
| M8 tranche 11 alone | 22 | 1.000 | 0.909 | 0 | 0 |
| All, after tranche 11 | 483 | 0.988 | 0.701 | 0 | 6 |
| All, after lane D (sides verified) | 483 | 0.988 | 0.689 | 0 | 6 |
| Lane A round 1 alone | 91 | 1.000 | 0.813 | 0 | 0 |
| All, after lane A round 1 | 574 | 0.990 | 0.709 | 0 | 6 |
| Lane A round 2 alone | 89 | 1.000 | 0.888 | 0 | 0 |
| All, after lane A round 2 | 663 | 0.991 | 0.733 | 0 | 6 |
| Lane A round 3 alone | 89 | 1.000 | 0.764 | 0 | 0 |
| All, after lane A round 3 | 752 | 0.992 | 0.736 | 0 | 6 |
| Lane A round 4 alone | 80 | 1.000 | 0.738 | 0 | 0 |
| All, after lane A round 4 and main (rajab-q127, lane B R2 sample) | 881 | 0.951 | 0.706 | 0 | 44 |
| Lane A round 5 alone | 92 | 1.000 | 0.826 | 0 | 0 |
| All, after lane A round 5 and main (PR #76) | 981 | 0.955 | 0.716 | 0 | 44 |
| Lane A round 6 alone | 103 | 1.000 | 0.845 | 0 | 0 |
| All, after lane A round 6 | 1,084 | 0.959 | 0.729 | 0 | 44 |

A fresh tranche starts lower than the self-applied bank, as expected. Its new gaps go into the ledger, and the next round of the bank applied to itself will run over them.

The current combined result is the generated M8 table above. Segmentation review receipts and the exact validation boundary are recorded in [the reconciliation audit](m8-tranche3-reconciliation-2026-10-08.md).
