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

## M8: scale-up, first tranche

**The size of the remaining work.** The segmented Ibn Rajab records held 1,056 furūʿ, and 1,129 now that opening examples are segmented (see below). The 187 annotated in M4 cover 14 qawāʿid, so **869 remain, in 146 qawāʿid** (earlier estimates of ~1,900 were wrong). None of those qawāʿid has a formal reading yet, and a farʿ can only test a reading. So each tranche first formalises its qawāʿid from their own statements in `Usul.Refinements`, then annotates every farʿ of each qāʿida against that reading (`corpus/takhrij/rajab_m8_furu.json`).

**Tranche 1 (qawāʿid 6, 22, 68; 26 furūʿ with the opening examples).** These are the qawāʿid whose principles the bank had just formalised, so the tranche also tests those principles:

| Qāʿida | Reading | Link to the bank |
|---|---|---|
| 6: an act done in its time on a belief later shown wrong suffices; joined to it, a hidden defect in a condition is excused | `errorExcused`: the act stands unless another's right is attached («لتعلق حق الغير به») or he was negligent («فرط بترك البحث») | `q6_grounds_exemption`: q6 is the ground of `zannSetAside`'s exemption, which until now had no source |
| 22: is what is consumed in another, without trace, as non-existent? («فيه خلاف») | `istihlak`: one side of the khilāf | an instance of qāʿida 106 (`treatedAsAbsent`) |
| 68: doubt in a condition of validity | `validUnderDoubt`: what needs a firm intention is valid only on ghalabat al-ẓann or an aṣl mustaṣḥab; what does not is valid («فالصحيح فيه الصحة») | `firm_by_basis`: the firm basis is bayt 90's `basis` or the presumption |

Results on the tranche:
- **8 derivable, 14 ikhtilāf (8 on the madhhab side), 4 missing rule or fact, 0 encoding errors.** Coverage is 22/26 = 0.846 and madhhab coverage 16/26 = 0.615, with the three opening examples included. Two of them are derivable; q22.f000 (impure water) turns on the quantity of water and is a missing fact (`fact:water_quantity`). Six ledger entries are opened: the three missing cases, and three minority-side ikhtilāf cases that name what they need (22.f003, 22.f004, 68.f007).
- **What the cases say about the readings:**
  - **q22's khilāf is real.** On mixed oil (f003, and the bequest in f004 that follows it) the manṣūṣ is *partnership*, not consumption. Same-kind fungibles mixed together become a shirka, which consumption-as-absence cannot express. The kernel lands on the minority (al-Mujarrad), and the gap is now in the ledger (`rule:khalt_as_shirka`). On milk in water (f001) and grains of wheat in barley (f006) no madhhab is marked.
  - **q22.f008 is decided by another reading.** The mashhūr makes the mixer of a deposit liable *for transgression*. It is annotated under the trust-loss reading and gives the madhhab's ruling. A new optional `home` field records that its qāʿida is 22, so coverage stays exact without pretending the case was revisited.
  - **q68 types 1 and 2 track the madhhab** on the doubtful vessel, the zakāt intention, the night of doubt and the deposited dinars. The exception is f007: the stronger view (al-Qāḍī, Ibn ʿAqīl) rests on the bar on conditional sale, a separate principle (`rule:taliq_al_bay`).
  - **New gaps:** whether a concession needs certainty of its permission (68.f001, `fact:rukhsa_needs_certainty`); dirhams mixed with usurped ones, decided by proportion (22.f007, `rule:mixed_haram_by_proportion`); and a judge ruling against his own ijtihād (68.f009).
- **Segmentation finding, opening examples (found on review, now fixed):** a qāʿida's first example often comes inline before the first «(ومنها)» paragraph, after «صور:» or «مسائل:» («منها», «(ومنها)», «(إحداها)»), or in a paragraph opening «ومن أمثلة ذلك». It used to stay inside the qāʿida record. The segmenter now emits it as `.f000`, so every existing farʿ id is unchanged; the rebuilt corpus differs from the old one only by 74 new records (73 Ibn Rajab, 1 Ibn al-Laḥḥām) and their `furu_count`. Twelve annotated qawāʿid gained one, and all twelve are annotated: q6, 22 and 68 in this tranche, and q8, 16, 26, 45, 63, 75, 76, 140 and 159 from M4. A case now runs from its marker to the next farʿ marker. Before, the text stopped at the first source line break, so page markers cut cases mid-sentence; that affected paragraph furūʿ (e.g. Ibn al-Laḥḥām 43.f006, «دع ما يريبك إلى ما لا») as well as the new opening examples. Ids are unchanged; only `case_ar` grows, up to its excerpt cap. Known rough edges: q9's f000 holds two examples joined by an inline «(ومنها)»; q63's and q147's f000 begin with a fragment from before the marker; for q90 and q150, f000 is the heading of a sub-list.
- **Segmentation finding, other layouts:** qāʿida 14 enumerates «(إحداها)», «(الصورة الثانية)»…: its first case is now `.f000`, but the later ones are still unsegmented. Qāʿida 66 is written as two types with «مثل» examples and has none. Twenty-one qawāʿid in all have no segmented farʿ. Covering ordinal and «فمن ذلك» paragraphs would give them ids after the existing ones, which is the next segmenter step.

**Coverage trend:**

| Stage | Cases | Coverage | Madhhab coverage | Encoding errors | Open gaps |
|---|---|---|---|---|---|
| M4 first tranche | 204 | 0.873 | 0.534 | 7 | — |
| M4 rounds 1–4 (the bank applied to itself) | 214 | 0.977 | 0.648 | 0 | 5 |
| M8 tranche 1 alone | 23 | 0.870 | 0.609 | 0 | 6 |
| M4 with its 9 opening examples | 223 | 0.977 | 0.658 | 0 | 5 |
| M8 tranche 1 with its 3 opening examples | 26 | 0.846 | 0.615 | 0 | 7 |
| All, after the opening-example fix | 249 | 0.964 | 0.653 | 0 | 12 |

A fresh tranche starts lower than the self-applied bank, as expected. Its new gaps go into the ledger, and the next round of the bank applied to itself will run over them.
