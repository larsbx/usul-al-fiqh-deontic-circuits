# Reconciliation: the bank's taʿāruḍ procedure applied to its own furūʿ

The bank's kernel already has a procedure for conflicting adilla: `Usul.resolve` (`formal/lean/Usul/Taarud.lean`), after Ibn ʿUthaymīn. It tries jamʿ first, then naskh, then tarjīḥ, and suspends judgement (tawaqquf) when all three fail. `Usul.Reconcile` (`formal/lean/Usul/Reconcile.lean`) points that procedure at the bank itself, so the bank works through its apparent contradictions by its own rule rather than by an outside judgement.

## What counts as an apparent contradiction

An **apparent contradiction** is an ikhtilāf farʿ where the reading does not land on the madhhab's marked side (`matches_madhhab` is false). There are two adilla in play:

- the reading, which is the qāʿida as formalised;
- the reported positions on that farʿ.

All of them sit in `corpus/reconciliation/ledger.json`. When a new tranche adds one, `reconcile.check` fails until it gets a ledger entry, and `python -m usul_corpus reconcile --draft` proposes grades for the reviewer to correct.

## The four stages

`reconcile jam naskh ps = resolve ⟨jam, naskh, prevail ps⟩`

| Stage | Offered when | Checked by |
|---|---|---|
| jamʿ | The source cites a farq. The case is re-encoded under a refinement whose dossier entry names a conservativity theorem over the earlier reading. | Python checks that every farʿ the refinement moves away from the earlier reading lands on its prevailing side, and that at least one farʿ moves. Lean checks the theorem and the re-encoded guards. |
| naskh | A later riwāya or a retraction (rujūʿ) with reported chronology. | The ledger's `naskh.ref`. |
| tarjīḥ | Some ruling's graded support strictly exceeds every other ruling's. | `prevail`, which carries `prevail_mem` (it never invents a ruling) and `prevail_unanimous`. |
| tawaqquf | Every earlier stage fails. | `reconcile_tawaqquf_iff`. |

**Grades (`Usul.Reconcile.Grade`), strongest first.** The first five are the annotation convention's marked sides (`Grade.marked`):

1. **taṣḥīḥ:** the aṣḥāb label a position «المذهب», «المشهور», «الأشهر» or «الصحيح».
2. **naṣṣ:** a riwāya or a manṣūṣ of Aḥmad.
3. **ẓāhir:** the ẓāhir of Aḥmad's words.
4. **qiyās:** qiyās al-madhhab, or qiyās al-manṣūṣ.
5. **jazm:** the aṣḥāb at large: «الأصحاب», most of them, or the ẓāhir of the aṣḥāb.
6. **aṣḥāb:** one named companion's choice. This includes an author's own «الأظهر» or «الصواب»: an author weighing the evidence is not labelling the madhhab.
7. **takhrīj:** a takhrīj or an iḥtimāl.
8. **wajh:** a bare wajh.

**Tarjīḥ.** Each position lists the distinct grades of the people who hold it. Positions with the same ruling pool their grades, and a ruling's support is its pooled grades sorted strongest first. Supports are compared lexicographically, so a weaker grade never outweighs a stronger one, however many hold it. When two supports share every grade, the longer one wins, following «الأكثرون». Unmarked grades (one companion, a takhrīj, a wajh) count once per ruling, however many hold them, so two named companions against one is still a tie. Marked grades count per holder.

**Lean is the authority.** `UsulTest/Reconcile.lean` holds one generated guard per entry, so the Python mirror cannot drift from `Usul.Reconcile.reconcile`. A test also pins the grade ranks to the Lean definition.

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
- the excerpt is checked letter by letter against the pinned witness (`test_evidence_is_verbatim`, skipped where the witness is not cached), and it stays within the witness's excerpt limit.

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

## Results

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
- **No naskh yet.** None of the annotated paragraphs reports the chronology of a retraction.

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
