# Reconciliation: the bank's taʿāruḍ procedure applied to its own furūʿ

The bank's kernel already has a procedure for conflicting adilla: `Usul.resolve` (`formal/lean/Usul/Taarud.lean`), after Ibn ʿUthaymīn. It tries jamʿ first, then naskh, then tarjīḥ, and suspends judgement (tawaqquf) when all three fail. The reconciliation points that procedure at the bank's own disputed furūʿ.

## A ruling stands by its proof (redesign, 2026-10-15)

The owner's rule: the madhhab's position is not authoritative; a ruling is valid by its proofs. Until this redesign the tarjīḥ stage ranked positions by *who holds them* (the madhhab's label, then a naṣṣ of Aḥmad, the aṣḥāb, one companion, a wajh). That is now a record, and tarjīḥ weighs proofs.

| | Before | Now |
|---|---|---|
| Which furūʿ | the ikhtilāf off the madhhab's side, then every ikhtilāf with the on-madhhab ones required to confirm their side | every ikhtilāf; no side is a target |
| Tarjīḥ | `Usul.Reconcile.prevail` over attribution grades | `Usul.Tarjih.prevail` over the proofs each position cites |
| Attribution | decided the case | `attribution` in `report.json`: what the labels favour, a record for comparison |
| A farʿ with no proofs recorded | resolved by its holders | `unweighed`: on the weighing worklist, never resolved |

**Tiers** (`Usul.Tarjih.Tier`, weakest first), from Ibn Qudāma's *Rawḍa*, «باب: في ترتيب الأدلة ومعرفة الترجيح» (v02 p389–390), and Aḥmad's order of resort (`DalilKind.resort`, which `Tier.refines_resort` proves the tiers never invert):

1. **ijma**: a stated ijmāʿ, «لكون الإجماع دليلا قاطعا».
2. **qati**: the Book or the mutawātir Sunna, certain in transmission *and* explicit on the point.
3. **zanni**: a text whose proof is a ẓann: an āḥād report, or the Book through its generality, apparent sense, implied sense or an interpretation. «ولا يتصور أن يتعارض علم وظن» holds only of what is ʿilm on the point.
4. **fatwaSahabi**: a ṣaḥābī's fatwā with no ṣaḥābī disagreeing.
5. **aqrabSahabi**: a ṣaḥābī's view where the ṣaḥāba disagreed.
6. **mursalDaif**: a mursal, or a report the source calls weak.
7. **qiyas**: an analogy or a stated rationale.
8. **istishab**: the original state.

**Tarjīḥ.** A ruling's strength is the highest tier any proof cited for it reaches. A higher tier decides, whatever the lower one's advantages. At the same tier, a ruling prevails over another only with a counted advantage over it and none from it back. Where the counted advantages do not settle it, the result is tawaqquf: «رجحنا، فأخذنا الأقوى في أنفسنا» is the mujtahid's own weighing, which the bank does not simulate.

**Murajjiḥāt** (`Usul.Tarjih.Murajjih`). From the *Rawḍa* (v02 p391–401): more narrators, precision, piety, the narrator the event concerns or who took part in it, corroboration, agreed raising, a self-consistent narrator, a connected chain, what moves from the original state, the affirming report, and the ʿilla advantages. From Ibn al-Najjār's *Sharḥ al-Kawkab al-Munīr* (v04 p650–703), the strength of the indication the *Rawḍa* leaves out: what the two Ṣaḥīḥs agree on, what was heard from the Prophet over his silence, his saying over his deed and his deed over his tacit approval, prohibition over command and command over permission, prohibition over permission, the specific over the general, the unspecialised general over the specialised, iqtiḍāʾ over īmāʾ and mafhūm, īmāʾ over mafhūm, the mafhūm of agreement over that of contrast, and a ruling whose ʿilla the Lawgiver states.

**Every murajjiḥ is formalised with its standing, and none is dropped.** `Murajjih.standing` records how the cited sources hold it:

| Standing | Murajjiḥāt | Source |
|---|---|---|
| asserted | the rest | |
| disputed | more narrators; the transitive ʿilla; prohibition over permission; saying over deed; command over permission; what moves from the original state | the source sides with it and reports a dissent (Rawḍa p391, p396, p399; al-Kawkab p656, p659, p679, p687) |
| weak | lightness of the ruling; the sensible ʿilla; fewer properties | «وهي ترجيحات ضعيفة», «ترجيح ضعيف» (Rawḍa p398–399), though al-Kawkab asserts lightness (p692) |
| rejected | what wards off the ḥadd | «ولا يرجح المسقط للحد» (Rawḍa p396), though al-Kawkab gives it «عند الأكثر» (p689) |

Which advantages decide is a `Policy`, itself formal, over their standing and their basis: `strict` (stated, asserted only), `sources` (stated, asserted or disputed: what a cited source holds as its own; the bank's default), `applying` (as `sources`, with the bank's applied advantages) and `all` (every recorded advantage). The policies are nested (`strict_le_sources`), the default leaves out exactly the weak and the rejected (`sources_false_iff`), and across tiers the policy is idle (`beats_policy_irrelevant`). Every weighed entry is guarded in Lean under all three, and `report.json` `policies` lists the furūʿ whose resolution changes under `strict` or `all`.

Proved in Lean: tarjīḥ never invents a ruling (`prevail_mem`), a position that cites no proof outweighs nothing whoever holds it (`beats_unproven`), a higher tier decides (`beats_of_tier`, `not_beats_of_tier`), and outweighing is asymmetric (`beats_asymm`).

**Data.** Proofs live in `corpus/reconciliation/weighing/*.json`, laid over the ledger by `reconcile.load`, each farʿ weighed in one file. A proof records its position, tier, the proof itself (`dalil`), and a verbatim excerpt checked against its pinned witness (`test_proofs_are_verbatim`, and `make source-verify`). A jamʿ still needs a cited farq and a conservativity theorem; that it lands on the side the proofs favour is checked once the farʿ is weighed, and listed in `jam_pending` until then.

**Pilot** (`weighing/pilot.json`): 12 two-position riwāya entries drawn at random, weighed from al-Mughnī and al-Mubdiʿ. Five tiers were revised on review: two āyāt bearing on the farʿ only by generality or interpretation (zanni, not qati), one inheritance āya carried to a gift (qiyas), one tacit consensus (fatwaSahabi, not ijma), and one ṣaḥābī fatwā contradicted in the same passage (aqrabSahabi).

| Result | Furūʿ |
|---|---|
| tarjīḥ for the reading | q072.f001 (a report and a ṣaḥābī practice over a rationale), q095.f012 (two reports over a qiyās) |
| tarjīḥ against the reading | q147.f002 (a report over a qiyās), q158.f018 (a qiyās over istiṣḥāb), q102.f005 (ṣaḥābī against ṣaḥābī, ʿUthmān's report connected, per Aḥmad) |
| tawaqquf | q018.f001, q018.f002, q059.f003, q108.f001, q125.f011, q136.f000, q143.f001 |

In 2 of the 5 resolved furūʿ the proofs side with the madhhab's label; in the other 3 they go against it. Seven of twelve end in tawaqquf, mostly qiyās against qiyās or ẓannī text against ẓannī text. The pilot was weighed before al-Kawkab's murajjiḥāt were added; they are applied in the full weighing.

## The full weighing (2026-10-15)

Every ledger entry is now weighed: 596 entries, 1,855 proofs, 14 advantages, in `weighing/pilot.json` and `weighing/batch-00…38.json`. Each batch was drafted by an agent under one rulebook, every excerpt verified at its page through any qualifier that follows it (`make source-verify`: 4,444 excerpts), and every qaṭʿī or ijmāʿ claim reviewed. No human has reviewed the weighing yet.

| | By proof (`sources` policy) | By attribution (record) |
|---|---|---|
| jamʿ / naskh | 20 / 1 | 20 / 1 |
| tarjīḥ | 235: 156 for the reading, 79 against | 561: 391 for, 170 against |
| tawaqquf | 340 | 14 |

- **Proofs by tier:** qiyās 1,498; ẓannī text 178; istiṣḥāb 91; ṣaḥābī fatwā 36; disputed ṣaḥābī view 35; mursal or weak 17. No qaṭʿī text and no certain ijmāʿ: every claimed consensus was tacit («لم يعرف له مخالف») or reported by one transmitter against a contrary riwāya, and is tiered accordingly.
- **Tawaqquf dominates** because most of these masāʾil are argued by qiyās on both sides, and the sources rarely state an advantage between two qiyāsāt. Seventeen entries have no argued proof on either side (`searched` records where).
- **Labels and proofs:** of the 235 tarjīḥ by proof, the madhhab's labels favour the same ruling in 184. Of the 131 resolved furūʿ annotated on the madhhab's side, the proofs confirm 109 and go against 22.
- **Stated and applied advantages** (`Usul.Tarjih.Basis`, after review): of the 14 advantages, 6 are *stated*, a source comparing the two proofs itself (e.g. «وهذا أخص من حديث أبي سعيد، فيقدم عليه»), and 8 are *applied*, the bank applying an uṣūl murajjiḥ to properties each proof shows where no source compares them. Both are kept; the default policy counts only the stated. A fourth policy, `applying`, also counts the applied: under it five furūʿ move from tawaqquf to tarjīḥ (q007.f001, q081.f002, q132.f003, q145.f005, q159.f027). In q132.f003 the applied saying-over-deed advantage would even reverse al-Mughnī's own preference, which rests on reading Abū Saʿīd's report as a qaḍiyyat ʿayn, a consideration not yet modelled.
- **Policies:** nothing changes under `strict`; under `applying` the five above; under `all` those five and q159.f035, decided by the rejected advantage of warding off the ḥadd.
- **jamʿ:** none is refuted by the proofs. q037.f000 was at first: the weighing found no argued proof for Majd's side. Majd's own ground, Abū Bakr's «شرط منفعة الرهن باطل وهو رهن بحاله», reported by Ibn Rajab (v01:p047), was then added; qiyās against qiyās leaves the jamʿ standing.
- **Residues by proof** (`report.json` `worklist`): 83, led by `two_usul_reinforced_governs` (8), `asl_zahir` (7), `heir_takes_deceased_right` (4) and `lots` (4).

**Not modelled yet.** A proof the source cites only to rebut it (q067.f003 «ولا يصح», q096.f006 «وهذا ممنوع») is recorded as a proof; naqḍ and muʿāraḍa are a further layer. Tābiʿūn views have no tier and appear only in notes.

**Open review items** raised by the weighers. These are doubts about the annotations, recorded and not acted on:

- q156.f017: the case note says al-Muntahā halves the mahr for the excess wives; Sharḥ al-Muntahā v02:p688 reads no mahr («لتبين أن الفرقة وقعت بإسلامهم جميعا»), i.e. with position 0. (b19)
- q033.f000: al-Kāfī v02:p021 holds the sale valid without dispute when the verbal exception of the foetus is valid (these facts); al-Qāḍī's «كأنه مستثنى» yields invalidity only if it is invalid. The framing of al-Qāḍī's side may be off. (b15)
- q028.f001: Ibn Rajab's wording (retaliation, then a fresh aggressive wound) differs from the ledger evidence and al-Mughnī v08:p306 (retaliation done wrongfully: poisoned tool, extreme heat); the Iqnāʿ/Kashshāf ruling is «بقية الدية». (b06)
- q140.f001: in al-Mughnī the restricted view also covers livestock from pasture, not only fruit and palm-pith as the position label has it. (b09)
- q107.f003: al-Mughnī v06:p182 itself accepts the waqf on «من يحدث من ولده» as valid. (b18)
- q096.f005: Ibn Rajab's printed «أنه لا يضمن» for al-Mubhij contradicts the reason he gives next; proof attached to 'liable'. (b22)
- Witness check: openiti-burhanibnmuflih-mubdi-shamela21619bk2 v08:p229–230 quotes «قال الشيخ تقي الدين» and reads like Kashshāf; confirm the file holds al-Mubdiʿ. (b21)
- Rebutted proofs: some proofs are cited and rejected by their own source (q067.f003 «ولا يصح»; q096.f006 «وهذا ممنوع»). The weighing records them; rebuttal (naqḍ/muʿāraḍa) is not yet modelled. (b22, b24)
- q019.f004: al-Mughnī v03:p146 and Kashshāf make the menstruant's make-up due «بغير خلاف»; the khilāf covers the boy reaching puberty, the convert, the recovered insane. The case note may be loose. (b28)
- q128.f006: al-Mughnī's ḍamān wajh and Kashshāf assess the diya less the arsh of the cut; position 1's wording says the full diya of a free man. (b29)
- q018.f005: the case calls position 1 a takhrīj; al-Mughnī v03:p404 and al-Mubdiʿ v03:p234 report it as a riwāya with a reason. (b31)
- q158.f016: the case note calls the muʿtamad's «لأن الأصل عدم لزومه له» (Kashshāf v05:p155) qiyās; by what it is, an appeal to the aṣl, it is istiṣḥāb. (b34)

## The attribution record (before the redesign)

Everything below describes the earlier grading by attribution. Its figures are kept as the record of what the madhhab's labels favour; they are not tarjīḥ.

### What counted as an apparent contradiction

An **apparent contradiction** was an ikhtilāf farʿ where the reading does not land on the madhhab's marked side (`matches_madhhab` is false). From 2026-10-14 every ikhtilāf entered the ledger, the on-madhhab ones required to confirm their side; that requirement is withdrawn, since `matches_madhhab` describes the text and is no target.

### The four stages

`byAttribution jam naskh ps = resolve ⟨jam, naskh, prevail ps⟩`

**Grades (`Usul.Reconcile.Grade`), strongest first.** The first five are the annotation convention's marked sides (`Grade.marked`):

1. **taṣḥīḥ:** the aṣḥāb label a position «المذهب», «المشهور», «الأشهر» or «الصحيح».
2. **naṣṣ:** a riwāya or a manṣūṣ of Aḥmad.
3. **ẓāhir:** the ẓāhir of Aḥmad's words.
4. **qiyās:** qiyās al-madhhab, or qiyās al-manṣūṣ.
5. **jazm:** the aṣḥāb at large: «الأصحاب», most of them, or the ẓāhir of the aṣḥāb.
6. **aṣḥāb:** one named companion's choice. This includes an author's own «الأظهر» or «الصواب».
7. **takhrīj:** a takhrīj or an iḥtimāl.
8. **wajh:** a bare wajh.

Each position listed the distinct grades of its holders; supports were compared lexicographically, unmarked grades counting once per ruling. Marked grades count per holder, so an entry cites a page at most once per position (`reconcile.check` keys evidence on `(ref, position)`; the schema rejects exact copies): a page naming two holders of one position is graded once, at the stronger grade.

**Lean is the authority.** `UsulTest/Reconcile.lean` holds one generated guard per entry, by proof (`Usul.Tarjih.reconcile`) where the farʿ is weighed and by attribution (`Usul.Reconcile.byAttribution`) for every entry, so the Python mirror cannot drift. A test also pins the grade ranks to the Lean definition.

## Imported evidence: the later taṣḥīḥ

Ibn Rajab and Ibn al-Laḥḥām often report a dispute without marking the madhhab. The bank therefore imports the works written to settle exactly that question. All of them were already registered in `corpus/registry.json`, but they had not been fetched before this pass.

| Kind of work | Works used |
|---|---|
| Taṣḥīḥ | al-Mardāwī's *al-Inṣāf* and *Taṣḥīḥ al-Furūʿ* (with Ibn Mufliḥ's *al-Furūʿ*) |
| The later muʿtamad | *al-Muntahā* and *al-Iqnāʿ*, with al-Buhūtī's *Sharḥ al-Muntahā* and *Kashshāf al-Qināʿ* |
| Other furūʿ works | *al-Mubdiʿ*, *al-Mughnī*, *al-Kāfī*, *al-Sharḥ al-Kabīr* |
| Uṣūl, for Ibn al-Laḥḥām's masāʾil | *al-Taḥbīr*, Ibn Mufliḥ's *Uṣūl*, *Sharḥ al-Kawkab al-Munīr* |

**The evidence item.** Each item in a ledger entry's `evidence` adds one graded holder to one listed position. It records:
- a `src:` locator and a verbatim excerpt;
- the excerpt is checked letter by letter, numerals included, against the pinned witness (`test_evidence_is_verbatim`, skipped where the witness is not cached), and it stays within the witness's excerpt limit.

**How evidence is graded.** The grades are the same as above:

| What the source says | Grade |
|---|---|
| «الصحيح من المذهب», «المذهب», «الأصح», or al-Mardāwī's taṣḥīḥ | taṣḥīḥ |
| «وعليه جماهير الأصحاب», or the decisive statement of a muʿtamad matn or sharḥ | jazm |
| A riwāya not already listed | naṣṣ |
| One author's choice | aṣḥāb |

Some evidence does not speak to the farʿ itself, and is graded lower:
- A taṣḥīḥ of the farʿ's premise, of a general rule, or of a cognate masʾala is graded **qiyās**: the madhhab applied to the farʿ, not a ruling on it.
- A ruling only by implication or on a parallel masʾala is graded **takhrīj**.
- Evidence about different facts is dropped (31.f004 concerns a missed vow, not a corrupted one). So is evidence that matches no listed position.
- A source never counts twice for one position, and a holder already listed is not added again.

**What was found.** The later works treat 113 of the 125 contradictions not resolved by jamʿ, and 321 evidence items were imported. Twelve were not found: 16.f005, 25.f000, 25.f002, 45.f005, 65.f006, 68.f003, 133.f007, 133.f014, 133.f020, 159.f032, 160.f035, and 31.f004 (dropped). Each finding's reasoning is kept in the item's `note`.

## Results by attribution (historical)

| Stage | Ibn Rajab's reports alone | With the later taṣḥīḥ | After the refinements (current) |
|---|---|---|---|
| jamʿ | 3 | 3 | 11 (15 after tranche 7) |
| tarjīḥ for the reading | 29 | 52 | 52 |
| tarjīḥ against the reading (residue) | 25 | 67 | 58 |
| tawaqquf | 71 | 6 | 7 |

The first two columns predate two fixes from review:
- unmarked grades now count once per ruling, which turns 64.f003 into a tie;
- every jamʿ entry, not only one whose ruling moves, must land on the prevailing side, which makes 37.f001 a residue.

The later works settle 65 of the 71 suspended cases. They mostly settle them against the reading, because the readings follow the qāʿida while the madhhab often follows its own exceptions.

### First pass, before the import (Ibn Rajab's reports alone)


| Stage | Entries | Standing |
|---|---|---|
| jamʿ | 3 | for the reading |
| tarjīḥ | 54 | 29 for the reading, 25 against |
| tawaqquf | 71 | — |

- **The one jamʿ is qāʿida 37 (`successive_by_binding`).**
  - The tranche-6 reading let the later contract always govern. That ran against Majd's ẓāhir of Aḥmad on the pledge used with permission (37.f000) and against Aḥmad's riwāya on the pledge with a void condition (37.f006).
  - Abū al-Barakāt's own farq is the jamʿ: «ويسقط ضمان العارية لأنها ليست لازمة، وعقد هذه الأمانة لازم» (37.f003). Under it, the later contract governs where it binds, or where the earlier one did not.
  - Two theorems show the refinement is the old reading on every farʿ where that holds: `laterBindingGoverns_conservative` and `laterBindingGoverns_unbound_earlier`. So 37.f002–f005 keep their rulings.
  - 37.f000 and 37.f006 move to the higher-graded side.
  - 37.f001 (the deposit) stays liable under the refinement, as Majd's «وفرق صاحب المحرر بينهما» has it. Because a jamʿ must land on the prevailing side, and the later authors' ẓāhir of Aḥmad outranks Majd there, it remains a residue.
  - Madhhab coverage rises from 0.642 to 0.647.
- **The 25 residues are the refinement worklist** (`corpus/reconciliation/report.json`, `worklist`). These are furūʿ where tarjīḥ goes against the reading, grouped by encoder. The largest groups:
  - `lots` (7): the manṣūṣ and the mashhūr exclude lots where the reading allows them.
  - `asl_zahir` (3) and `tadakhul` (3): the mashhūra riwāya against the reading.
  - `words_out_of_nature` (2): qāʿida 38, where the madhhab follows the wording. No farq is cited there, so no jamʿ is possible, and the residue stands as the record.
- **Nine reviews** (`review`): tarjīḥ gives the reading a marked side while the annotation says no madhhab matches. Examples are the naṣṣ of Aḥmad against a takhrīj (75.f005, 75.f007) and al-Talkhīṣ's qiyās al-madhhab (133.f018). These are questions for the human reviewer. Annotations are never rewritten from here.
- **One naskh.** 100.f003 (the register sweep below): al-Zarkashī reports the riwāya barring an obligatory fast in tashrīq as «التي ذهب إليها أحمد أخيرا». No other annotated paragraph reports the chronology of a retraction. A naskh is admitted only with its witness: `naskh.ref` must be the page of one of the entry's own evidence items whose position holds `naskh.ruling` (`reconcile.check`).

### Refinements from the worklist

The residues against each reading (`report.json` → `worklist`) are where the readings need the next round of refinement. A residue becomes a jamʿ only when the later works cite a farq that separates it from the furūʿ the reading already gets right.

| Refinement | Farq | Result |
|---|---|---|
| `substitute_at_obligation` (`useSubstituteAt`, qāʿida 16) | «والاعتبار في الكفارات بحالة الوجوب» (al-Iqnāʿ; Kashshāf «اعتبارا بوقت الوجوب»). Once the substitute is what fell due, finding the original does not move him. | 5 of the qāʿida's 7 furūʿ move to the taṣḥīḥ side. 16.f002 (the like found before payment) and 16.f006 keep their rulings. |
| `unknown_condition_in_fact` (`countsAsMetIn`, qāʿidas 64–65) | «لأن الاعتبار في العقود بما في نفس الأمر» (Kashshāf). In a transaction whose unknown condition is the actor's own authority, the condition counts as it is in fact. | 4 furūʿ move: the disposal under an unknown permission, the khiyār disposal, the sale by an unknowing heir, the release of an unknown debt. ṭalāq, ʿitq, nikāḥ and the runaway's sale (a condition of the object) keep the reading. |

With these and qāʿida 37 there are 11 jamʿ. The residues fall to 58 and madhhab coverage reaches 0.668.

Tranche 7 added 12 contradictions, and its later taṣḥīḥ gave four more jamʿ:

| Refinement | Farq | Furūʿ moved |
|---|---|---|
| `excessObligatoryIn` (qāʿida 3) | Ibn ʿAqīl's «الاتباع قد يسقط الواجب» | 3.f000: the rakʿa is caught, «هذا المذهب مطلقا» |
| `advancedSufficesIn` (qāʿida 5) | «الاعتبار في الكفارات بحالة الوجوب» | 5.f001 |
| `otherTongueValidIn` (qāʿida 10) | «لأن النكاح غير واجب بأصل الشرع فلم يجب تعلم» | 10.f004, f005 |

Over 140 entries and 347 evidence items (the first pass's 321 plus tranche 7's 26), this gives 15 jamʿ, 117 tarjīḥ (58 residues) and 8 tawaqquf. In 10.f002 the later works split by the dhikr's status, so only the evidence on the obligatory takbīr, the farʿ's leading example, is graded.

Tranche 8 added 4 contradictions and 12 evidence items, and no new jamʿ. Its three new residues follow the later madhhab against Ibn Rajab's own preferences: purification in qāʿida 14, and in qāʿida 19 both tayammum and the conditions of the ḥajj's wujūb. Its raven oaths (14.f001, f002) are not contradictions, because the reading takes Aḥmad's naṣṣ of abstention, which the madhhab confirms. The ledger stands at 144 entries and 359 evidence items, with 15 jamʿ, 121 tarjīḥ (61 residues) and 8 tawaqquf.

Tranche 9 added 2 contradictions and 6 evidence items. On the shufʿa (50.f001) the madhhab's own condition, «إذا كان مليئا بالثمن», is the farq for a jamʿ (`ownedBeforePaymentIn`). On 43.f001 the muʿtamad holds the rescinded object as a trust, which leaves a residue. The ledger stands at 146 entries and 365 evidence items, with 16 jamʿ, 122 tarjīḥ (62 residues) and 8 tawaqquf.

Tranche 10 added 7 contradictions and 23 evidence items, after checking each of its on-the-madhhab annotations against al-Inṣāf and the muʿtamad. Two are jamʿ on farqs the madhhab states: `disposeBeforeQabdIn` (52.f001: a settled debt is sold only to the debtor, «وهو الصحيح من المذهب. وعليه الأصحاب») and `removedWithPrincipalIn` (61.f001: the qāḍī's deputies are his, «لأنهم نوابه»). Five are residues, four of them on qāʿida 56, where the madhhab does not take concurrence as sufficient in the kitāba with a sale, agency before the nikāḥ or the umm walad's ʿidda, and none cites one farq for all three. The ledger stands at 153 entries and 388 evidence items, with 18 jamʿ, 127 tarjīḥ (67 residues) and 8 tawaqquf.

Tranche 11 added 3 contradictions and 8 evidence items, again after checking every on-the-madhhab annotation. `annulsNonexistentIn` (59.f004) is a jamʿ: the arsh is fixed once the defective thing perishes, «وهذا المذهب. وعليه أكثر الأصحاب». The same farq is cited for iqāla after loss (59.f005), but only in the muʿtamad's jazm, which al-Qāḍī's «قياس المذهب» outranks; the jamʿ check therefore keeps iqāla out of the refinement, and tarjīḥ leaves it with the reading, listed for review. 57.f002 rests in tawaqquf: on the branch where the free woman would suffice him, only Ibn Rajab's own fāʾida is found against al-Qāḍī and Abū al-Khaṭṭāb. The ledger stands at 156 entries and 396 evidence items, with 19 jamʿ, 128 tarjīḥ (67 residues) and 9 tawaqquf.

**Lane D: the madhhab sides of tranches 1–9 verified.** Every ikhtilāf case annotated on the madhhab side before tranche 10 (100 cases, the jamʿ entries excepted) was checked against al-Inṣāf and the muʿtamad. 90 agree, 4 have no later treatment (28.f001, 93.f006, 159.f029, 17.f004) and 6 do not agree. Each of the six keeps its annotated value in a `side_check` (`from_matches`, the refs of the evidence that overturned it) and enters the ledger, where `reconcile.check` requires a true original annotation, exact evidence-item indices, case-fact bindings and applicability rationales, and an unambiguous later taṣḥīḥ/jazm ruling against the original side confirmed by the full ledger. Page membership alone is insufficient:

| Farʿ | Later madhhab |
|---|---|
| 1.f000 | running water counted whole like still water, «وهي المذهب» |
| 2.f002 | the hair washed in the janāba ghusl, «وهو المذهب. وعليه جماهير الأصحاب» |
| 22.f007 | the unlawful share taken out whatever the proportion (Taṣḥīḥ al-Furūʿ, «هو الصواب، وهو المذهب») |
| 140.f001 | doubling for fruit, palm-pith and livestock only, «على الصحيح من المذهب» |
| 160.f006 | lots cast, neither slave sold before them (al-Iqnāʿ, Kashshāf) |
| 160.f012 | the bequest with a shared name void, «على الصحيح من المذهب. وعليه الأصحاب» |

All six resolve by tarjīḥ against their readings and join the worklist. 1.f002 is recorded as agreeing (al-Inṣāf, «الصحيح من المذهب») though the muʿtamad holds the other side («نصا»); 75.f008's facts may misstate «مع تعذره». The ledger stands at 162 entries and 414 evidence items, with 19 jamʿ, 134 tarjīḥ (73 residues) and 9 tawaqquf.

**Lane A, round 1** added 17 contradictions and 35 evidence items, every one a residue; the shards named candidate farqs but cited none decisive, so no jamʿ was attempted. The ledger stands at 179 entries and 449 active evidence items, with 19 jamʿ, 151 tarjīḥ (90 residues) and 9 tawaqquf. Candidate farqs and register questions from the round:

| Farʿ / qāʿida | Candidate farq or question |
|---|---|
| 71.f001 | Kashshāf: the ḥākim «يستغنيان بمالهما في بيت المال», the reading's own `compensatedOtherwise` fact, which Ibn Rajab's text does not state |
| 81.f001, f003 | al-Qāḍī's annulment-from-the-root vs divorce-from-now (Ibn Rajab rejects it); the returner's consent to return with the increase |
| 78.f009 | the shufʿa buyer planted by right in his own property, no ʿudwān (al-Kāfī, al-Qāḍī) |
| 80 | the roots as trees for sale and blight but as crops for usurpation and musāqāh: a per-masʾala farq (lasting years vs. no woody stem) |
| 67 (register) | the reading follows Ibn Rajab's gift/release takhrīj, which the madhhab rejects for release; or plain recourse with the takhrīj as residue |
| 80 (register) | the qāʿida states only «فيه وجهان»; the reading takes the wajh whose ground is stated |
| 90.f002 (register) | Ibn Rajab's «المذهب عند صاحب المحرر» against al-Inṣāf's reading of al-Muḥarrar |
| 53.f009 (register) | in al-Furūʿ's «ولا يتصرف», who does not dispose, wife or husband |
| 78 (register) | the qāʿida's «فوجهان» for a bare permission to occupy stays open |

**Lane A, round 2** added 10 contradictions and 23 evidence items: 7 residues, 2 resolved for the reading and 1 tawaqquf (96.f006). No jamʿ was attempted. The ledger stands at 189 entries and 472 active evidence items, with 19 jamʿ, 160 tarjīḥ (97 residues) and 10 tawaqquf. Candidate farqs and register questions from the round:

| Farʿ / qāʿida | Candidate farq or question |
|---|---|
| 104.f010 | Kashshāf: release «إسقاط حق فينفذ مع العلم والجهل»; a refinement must still keep 104.f011 (release from a sale's defects) apart |
| 95.f006 | the agent within his mandate vs beyond it: the madhhab makes the muḍārib's purchase a breach whatever he knew |
| 95.f007 | the loss on whoever directly used and destroyed part, even when misled, against Ibn Rajab's cutting/wearing harmonisation |
| 100.f001 | the vowed uḍḥiya (eaten from, like the uḍḥiya) vs the vowed hady |
| 96.f004, f006 | the owner's intention needed for discharge (al-Qāḍī; Ṣāḥib al-Talkhīṣ): one fact could refine `ownedDischarge` for both |
| 95 (register) | the bare-ijtihād branch is «قولان»; the split by acting as owner or negligence is the shard's reading |
| 100.f003 (register) | al-Zarkashī: Aḥmad's last riwāya bars any obligatory fast in tashrīq; whether that is naskh of the vowed-fast riwāya (`naskh` left null) |
| 104.f012 (register) | no label on ratifying an unknown bequest; annotated off the madhhab pending a decision |
| 105.f009 (register) | whether Ibn Rajab's general qiyās al-madhhab for the lot counts as evidence on the ambiguous waqf deed |
| 99.f002, f003 (register) | derivable for want of a reported counter-position, though the madhhab holds lending recommended: side-check candidates |
| 102.f003 (register) | the child's or madman's killing taken as «on a forbidden manner» |

**Lane A, round 3** added 21 contradictions and 55 evidence items: 19 residues, 1 resolved for the reading (114.f003) and 1 tawaqquf (109.f018). No jamʿ was attempted. At integration the ledger stood at 210 entries and 527 active evidence items, with 19 jamʿ, 180 tarjīḥ (116 residues) and 11 tawaqquf; after the register sweep, 19 jamʿ, 1 naskh, 179 tarjīḥ and 11 tawaqquf, with the same 116 residues. Candidate farqs and register questions from the round:

| Farʿ / qāʿida | Candidate farq or question |
|---|---|
| 113.f003, f005 | several pledgors or guarantors as several contracts (Kashshāf «لأن الراهن متعدد»; al-Qāḍī «تتعدد الصفقة بتعدد الضامنين»): a `contracts_multiply` qarīna for one-to-one |
| 113.f007 | al-Mughnī: equal units (coins, ṭalāqs) are divided by heads, not parts |
| 115.f002 | «لئلا تستوي حال حريتهما الكاملة والمبعضة»: partial freedom limits the claim to the whole |
| 116 | the later madhhab relates back where the cause was complete in the owner's lifetime (f003–f005), not where the acquirer's own act was awaited (f001 taking, f002 acceptance, f007 intention); f006's walāʾ «لا يوقف» is a separate ground |
| 117 | the state at suspension where the question is the suspender's own eligibility then (f004, f006, f005), at occurrence where the effect is measured when it happens (f002, f007, f008); f007 and f003 (tuhma) break the pattern |
| 107.f006 | Ibn Rajab's own farq: a waqf on children may regard those existing, «بخلاف الدرجة والطبقة»; Sharḥ al-Muntahā «لوجود الوصف فيه» |
| 109.f011 | Kashshāf: «لأن الثانية صارت فراشا له»; a firāsh fact would bar both |
| 111.f000 | declining the qasāma oaths is a judgment by nukūl, not proof of one alternative |
| 107.f005 (register) | the muʿtamad split: Tanqīḥ and Muntahā with al-Inṣāf, Iqnāʿ and Kashshāf «خلافا لما في التنقيح»; annotated with al-Inṣāf |
| 108.f004 (register) | al-Inṣāf's madhhab (her word) against Taṣḥīḥ al-Muḥarrar and al-Wajīz (his) |
| 109 (register) | the precedence clause («على الصحيح») against al-Inṣāf v08:p152 voiding both marriages, mother and daughter in one contract |
| 109.f019 (register) | the second position is inferred from «على الأصح», no holder named |
| 112.f002 (register) | derivable: the dispute is over which forbidden thing is lighter, an input judgment |
| 113.f006 (register) | a typological record annotated for its stated instance, two wives and two houses |
| 114.f003 (register) | which cognate governs the count, the sale's inshāʾ (halves) or the iqrār's vagueness |
| 118.f004 (register) | `legitimate_purpose = false` rests on Taqī al-Dīn's own statement of the purpose |

**The tarjīḥ backfill.** The 248 on-madhhab ikhtilāf cases annotated before the rule were given entries by eight evidence groups, from al-Inṣāf, al-Furūʿ with Taṣḥīḥ al-Furūʿ, al-Iqnāʿ, al-Muntahā and their sharḥs (1,245 verbatim items, each located once in its witness). Results:
- **245 confirm the annotated side.** Several rest only on a cognate or a premise (graded `qiyas` or `takhrij`), the later works not treating the farʿ itself: 17.f004, 25.f001, 55.f003, 56.f005, 59.f006, 72.f006, 79.f001, 95.f005, 101.f005, 104.f006, 107.f002, 109.f012, 109.f019, 159.f029.
- **Two go the other way by the grade order alone**, a riwāya of Aḥmad on the same facts (naṣṣ) above the muʿtamad's unlabelled jazm: 65.f004 and 96.f009. Their annotations stand, citing RQ-03, which now covers naṣṣ as well as qiyās al-madhhab against the muʿtamad.
- **One data repair:** 160.f041's position ruling named its conditions ("lot after the claimant's choice and the nearer judge") where the encoder's value is "lot"; the label is normalised, the conditions kept in the holder.
- **Grading conventions confirmed:** Taṣḥīḥ al-Furūʿ's «الصواب» grades taṣḥīḥ (its verdict on the madhhab, as in 8 of the ledger's 9 such items; the ninth, 30.f002, is aligned, its outcome unchanged), while al-Mardāwī's «قلت» in al-Inṣāf stays `ashab`. 62.f000, 124.f001 and 124.f002 turn on that convention. An unlabelled statement in al-Furūʿ was graded `jazm` by some groups and `ashab` by others; no outcome depends on the difference.

With main merged (PR-30's eleven recovered furūʿ add three on-madhhab ikhtilāf, 18.f000, 32.f000 and 95.f000, given entries here; PR #49's 14.f001 and f002 keep their tarjīḥ in `reconciliation/history`, which the rule accepts), every one of the 488 ikhtilāf cases has a tarjīḥ: 486 in the active ledger, 1,812 evidence items, 20 jamʿ, 1 naskh, 451 tarjīḥ and 14 tawaqquf; 139 resolve against the reading (the residues, with the two RQ-03 cases), 333 for it; 247 entries confirm an on-madhhab annotation (65.f004 and 96.f009 stand under RQ-03).

**The register applied to the bank (sweep after round 3).** Following invariant 10 (apply the bank before asking the owner), every register question of lane A rounds 1–3, and those left from tranche 11 and lane D, was put through the bank's own procedure: the annotation convention (readings from the qāʿida's own statement; leading ruling; positions under the same facts; al-Inṣāf first, then the muʿtamad), the grade table, and `Usul.resolve` (jamʿ → naskh → tarjīḥ → tawaqquf). Everything stays `candidate`; what the procedure leaves open goes to the research register, `corpus/review/research_questions.json`.

| Question | Procedure | Outcome |
|---|---|---|
| 100.f003 | naskh: a later riwāya with reported chronology (al-Inṣāf v03:p352, al-Zarkashī «وهي التي ذهب إليها أحمد أخيرا»), which al-Inṣāf v11:p124 ties to the vow | **naskh**, ahead of tarjīḥ; outcome unchanged (against the reading) |
| 104.f012 | tarjīḥ: the Muntahā's cognate ruling (qiyās) over two aṣḥāb ways | for the reading, as the ledger has it; `matches_madhhab` stays false (no later label) |
| 105.f009 | grade table: Ibn Rajab's «على قياس المذهب» is qiyās al-madhhab | counts; for the reading |
| 107.f005 | tarjīḥ over the split muʿtamad: al-Inṣāf's taṣḥīḥ with the Muntahā's jazm against the Iqnāʿ's and Kashshāf's jazm | the annotation (al-Inṣāf's side) stands |
| 108.f004 | al-Inṣāf first («وهو المذهب», v08:p212), with the Muntahā (v04:p122) and the Iqnāʿ (v03:p204) «فقولها»; Taṣḥīḥ al-Muḥarrar and al-Wajīz are reported in al-Inṣāf only | stands, on the madhhab side |
| 90.f002 | al-Inṣāf first: Ibn Rajab's attribution to al-Muḥarrar is one author's report against al-Inṣāf's taṣḥīḥ | the residue stands |
| 1.f002 | tarjīḥ: al-Inṣāf's taṣḥīḥ above the muʿtamad's «نصا» (naṣṣ) | agreeing, as recorded |
| 67 | readings come from the qāʿida's own statement, which includes the gift/release takhrīj | the reading stands; the madhhab's rejection for release is a residue |
| 78 | two bare wujūh: a tie | tawaqquf at the qāʿida level; nothing for the owner |
| 99.f002 | side check: al-Inṣāf v05:p263, Aḥmad's naṣṣ «على عدم اعتبار إذنه في الوضع» | confirmed, derivable |
| 99.f003 | side check: only the general «(وهي) أي الإعارة (مندوب إليها)» (Kashshāf v04:p062; a general rule, qiyās) and al-Qāḍī's and al-Majd's answer in al-Furūʿ v04:p140; no farʿ-level taṣḥīḥ or jazm | no side check applies; stays derivable |
| 102.f003, 118.f004 | facts the text states: Ibn Rajab places the child's killing under Q102; in 118.f004 the positions do not dispute the purpose (al-Talkhīṣ validates on another ground) | stand |
| 109.f019 | «على الأصح» presupposes a contrary wajh, graded `wajh` | the ikhtilāf stands |
| 112.f002 | positions under the same facts: the dispute is over which forbidden thing is lighter | derivable stands |
| 113.f006 | leading ruling: the answer to the record's opening question; the three ṭuruq are its premise | stands |
| 114.f003 | the reading's own split: ṭalāq is an inshāʾ (`isIqrar = false`) | for the reading stands |
| 75.f008 | the recourse output is `true` whether or not seeking permission was impossible | no decision turns on the fact; recorded |
| 109 (precedence clause) | not an obligation (a follow-on of f015); no case exercises it | a refinement candidate, not a question |
| 80, 95 | wajh against wajh is a tie, and choosing a qāʿida's side is a policy point (invariant 8) | **open: RQ-02** |
| 59.f005 | the question is the grade order itself (qiyās above jazm) | **open: RQ-03** |
| 53.f009 | the subject of al-Furūʿ's «ولا يتصرف» | **open: RQ-04** |

**Lane A, round 4** added 21 contradictions and 38 evidence items: 17 residues, 2 resolved for the reading and 2 tawaqquf. No jamʿ was attempted. With main merged (rajab-q127's three entries) the ledger stands at 234 entries and 569 active evidence items, with 19 jamʿ, 1 naskh, 200 tarjīḥ (135 residues) and 14 tawaqquf. The round's register questions went through the bank's procedure first (invariant 10):

| Farʿ / qāʿida | Candidate farq, or the procedure applied | Outcome |
|---|---|---|
| 125.f007 | the only contrary is not a position within the madhhab | derivable |
| 127 | annotated on main (rajab-q127) as ikhtilāf on the same principle: the positions dispute the legal characterization of one scenario | a16's duplicate dropped; candidate farqs: the placer as the pusher (f006, «جعلا له كالدافع»); qawad for the killer alone (f005) |
| 121 | the madhhab includes the instance where the sharʿ or the language names it, «تقديما للشرع واللغة»; the reading's side of the third class is an unmarked choice | farq candidate; **RQ-02** |
| 124.f003 | Sharḥ al-Muntahā v03:p103, «ولأنها سبب الطلاق وسبب الحكم لا يجوز إخراجه من العموم بالتخصيص» (a cognate) | farq candidate (`addressee_is_occasion`) |
| 126.f004, f005 | the text's own farq: an instance absent from intent against one present but unknown | farq candidate |
| 128 | the state at the spread where the victim's status rises, at the injury where only the value falls; Ibn Rajab names no side | farq candidate; **RQ-02** |
| 128.f003 | the witness's «لا» against the argument it opens | **RQ-05** |
| 129 | «القود» extended to every non-liability condition (game, f006); `aqilaBears` grounded in al-Āmidī inside a farʿ | **RQ-06** |
| 120.f001 | «المذهب عند المتأخرين» against «عند المتقدمين»: tashih against tashih, the Iqnāʿ's jazm breaks the tie | the later madhhab, as annotated |
| 119.f001 | Ibn Rajab's takhrīj from Ibn ʿAqīl's ground is a position (`takhrij`) against al-Inṣāf's «بلا نزاع» | ikhtilāf stands, on the madhhab side |
| 121.f007 | «بلا نزاع» is the aṣḥāb at large | `jazm`, as graded |
| 121.f005, 128.f006 | a cognate or a reference back («الخلاف المتقدم») grades `qiyas` | as graded |
| 128.f004 | al-Targhīb's derivation is a Ḥanbalī position against Ibn Rajab's «بالاتفاق» | ikhtilāf stands |
| 119.f003, 124.f001 | the output is the same on either value of the unstated fact | nothing turns on it |

**Lane A, round 5** was the first round under the rule that every ikhtilāf has a tarjīḥ. It added 57 entries and 151 evidence items, one entry for each of its ikhtilāf cases. All 41 on-madhhab entries confirm their side and 16 are residues; there is no tawaqquf and no jamʿ. Two cases went through the bank's procedure at integration (invariant 10):

| Farʿ | The procedure applied | Outcome |
|---|---|---|
| 144.f005 | no later treatment, no label of Ibn Rajab's: Aḥmad's ẓāhir outranks the majority's and a cognate taṣḥīḥ | on the madhhab side, confirmed |
| 146.f004 | two riwāyāt with no madhhab label; al-Mardāwī's «قلت: الصواب أنه يحلها» (ashab) decides | residue, against the reading |

The ledger now holds every one of the 545 ikhtilāf cases: 543 active entries (2 archived) with 1,963 evidence items; 20 jamʿ, 1 naskh, 508 tarjīḥ (155 residues) and 14 tawaqquf; 288 entries confirm an on-madhhab annotation.

**Lane A, round 6** added 53 entries and 155 evidence items. Every one of its ikhtilāf cases has an entry: all 37 on-madhhab entries confirm their side, and 16 are residues. There is no tawaqquf and no jamʿ. Five cases take their contrary side from al-Inṣāf where Ibn Rajab only marks the split. The ledger now holds all 598 ikhtilāf cases: 596 active entries (2 archived) with 2,118 evidence items; 20 jamʿ, 1 naskh, 561 tarjīḥ (171 residues) and 14 tawaqquf; 325 entries confirm an on-madhhab annotation.

**Left as residues, for want of a cited farq:**

| Encoder | Residues / cases | Why no jamʿ |
|---|---|---|
| `asl_zahir` | 12 / 40 | All in Ibn Rajab's category 4 (aṣl and ẓāhir of equal grade), where the madhhab keeps the aṣl. No source separates them from 159.f031, f035, f039 and f021, where the ẓāhir prevails. Moving all of category 4 to the aṣl would move those four to their weaker side, which the jamʿ check forbids. |
| `lots` | 12 / 47 | Each exclusion of lots rests on its own rule: annulment by the ḥākim, the heirs' choice, the wife's word, loss of lineage, nothing binding. |
| `tadakhul` | 4 / 15 | Two rest on the mashhūra on vows, and one on the takbīr shared between a rukn and a non-rukn. |
| `concurrent_condition` | 4 / 6 | The madhhab voids the kitāba with a sale for «باع ماله لماله», agency before the nikāḥ for want of present ownership, and counts no concurrent freedom in the umm walad's clearance: three grounds, none a farq on concurrence itself. 56.f003 has no later treatment. |

`review` lists the cases where the reading holds the prevailing marked side while the annotation says no madhhab matches. These are for the human reviewer to re-annotate. Nothing is rewritten here.

Everything here has status `candidate`. The grades are a reading of the annotated paragraph. A resolution is "derivable under the encoding", never a fatwā.

The independent [lane-D acceptance audit](lane-d-acceptance-audit-2026-10-11.md) records the scope of all six discrepancies. Two qualified passages are preserved in `corpus/review/lane_d/qualified_evidence.json` outside graded reconciliation. The six outcomes remain candidates; textual applicability rationales require human review and are not proved by Lean.

### Review audit, 2026-10-10

The [follow-up audit](reconciliation-review-audit-2026-10-10.md) pins the original
48-case review queue to PR #47's merge and records each original annotation, Arabic
record, imported evidence and unresolved scholarly obligation in
`corpus/reconciliation/review-audit-2026-10-10.json`. It does not promote later
preferences into the original annotations.

In 52.f001, denial of ijmāl is only indirect support for the encoded universal
generality. Two imported grades therefore change from jazm to takhrīj; all excerpts
and competing holders remain. At the audit's base the review queue fell from 54 to 53, with
144 entries, 15 jamʿ, 121 tarjīḥ, 8 tawaqquf and 61 residues unchanged.
The English subject/object error in 159.f035 is corrected without changing its
facts or two riwāyas. Drafting no longer treats an author's own aẓhar as taṣḥīḥ.

The audit's own locked-replay command was superseded on merge by `make source-verify`
(`usul_corpus.source_verify`, PR-06), which replays every excerpt of the active ledger and its
shards against complete locked witnesses and fails closed.

The [PR-33 integration record](pr33-typed-rulings-2026-10-16.md) consolidates #92/#93: one typed identity, one pinned range-gap migration, preserved resolution receipts and independent Lean guards. Merge remains gated by source replay, Lean compilation and CI.
