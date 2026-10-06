# Qiyās: masālik al-ʿilla and qawādiḥ

`formal/lean/Usul/Qiyas.lean` formalises the two bodies of doctrine around the core of qiyās, which Q58 and S1 already state (a ruling that depends only on its ʿilla carries over to every farʿ sharing it). Ibn Taymiyya defines the sound qiyās as «الجمع بين المتماثلين والفرق بين المختلفين», joining like cases and separating unlike ones (Majmūʿ al-Fatāwā v20 p504). That is the pair `Factors.qiyas` / `farq_defeats`.

Model: a waṣf is a Boolean description of cases. The given cases (`Known`) are those whose ruling a text or ijmāʿ fixes. A ruling `Agrees` with them if it reproduces every one.

## Masālik al-ʿilla (how a waṣf is shown to be the ʿilla)

| Maslak | Lean | What is proved |
|---|---|---|
| naṣṣ, ijmāʿ | outside the model | they supply the given cases and the textual ʿilla (`IllaSource.mansusa`) |
| ṭard | `tard`, `tard_iff` | ṭard alone is weak: `tard_vacuous` (a waṣf found in no case satisfies it) |
| dawarān (ṭard wa-ʿaks), Q58's own wording | `dawaran`, `dawaran_iff` | only presumptive: `dawaran_not_unique` (two waṣfs turn with the ruling on all given cases and disagree on a farʿ) |
| al-sabr wa'l-taqsīm | `survivors`, `sabr_sound` | sound when the division is exhaustive and the ʿilla is not refuted; `sabr_needs_hasr` shows exhaustiveness (ḥaṣr) is essential |
| munāsaba | `Munasib`, `munasaba_of_q01` | under Q1, every waṣf on whose cases the law commands is suitable; grades of recognition (`Recognition`: muʾaththir, mulāʾim, gharīb, mursal, mulghā), with the cancelled never accepted and the mursal a parameter |
| shabah | `shabahAsl`, `shabah_optimal` | attach to the aṣl of greatest resemblance: an S8 instance |
| tanqīḥ al-manāṭ | `tanqih_manat` | a feature shown irrelevant (ilghāʾ al-fāriq) drops out: the ruling depends on the rest |
| takhrīj / taḥqīq al-manāṭ | `sabr_sound`, `munasaba_of_q01` / `TahqiqManat` | extraction is sabr or munāsaba; verification in the farʿ is a gate condition |

## Qawādiḥ (objections), each with why it defeats the inference

| Qādiḥ | Lean | Soundness |
|---|---|---|
| manʿ | `man_defeats` | if the farʿ lacks the ʿilla, rulings depending only on it can agree on the aṣl and differ on the farʿ (`underdetermined`) |
| naqḍ | `Naqd`, `naqd_iff_not_tard`, `naqd_defeats` | naqḍ is the failure of ṭard; no ruling agreeing with the given cases can depend only on a contradicted waṣf |
| takhṣīṣ al-ʿilla | `takhsis_repairs`, `NaqdSucceedsBy`, `naqd_answered_by_takhsis` | an impediment present in every counter-case removes the naqḍ; admissibility is a policy depending on the ʿilla's source (IQ-13) |
| kasr | `naqd_gives_kasr`, `kasr_without_naqd` | a naqḍ of the waṣf gives a kasr of its ḥikma, not conversely; admissibility is IQ-15 |
| ʿadam al-taʾthīr | `AdamTathir`, `adamTathir_iff_not_aks`, `AdamTathirSucceeds` | the failure of ʿaks; answered by another ʿilla if plurality is admitted (IQ-14); dawarān excludes it |
| farq / muʿāraḍa fī al-aṣl | `farq_defeats` | a second waṣf in the aṣl and absent in the farʿ leaves the farʿ open unless tanqīḥ removes it |
| qalb | `qalb_defeats` | the same ʿilla and aṣl yield an incompatible ruling, so the ʿilla cannot ground both |
| al-qawl bi'l-mūjab | `qawlBiMujab_defeats` | what is proved does not reach the disputed point |
| fasād al-iʿtibār | `fasad_itibar`, `qiyas_against_text_discarded` | text precedes qiyās (S2): a qiyās against a text is never the outcome |
| fasād al-waḍʿ | `fasad_wad` | a waṣf used for the σ-opposite of its ruling never yields it, except for ibāḥa, the only σ-fixed status |

## The qiyās gate

`gate` is an S3 gate on an `Argument` (aṣl, farʿ, ruling of the aṣl, ʿilla, given cases, text on the farʿ). Its conditions are the aṣl's ruling given, the ʿilla in the aṣl and in the farʿ, and no text on the farʿ. Its impediment is naqḍ.

- `qiyas_sound`: through the gate, every ruling that agrees with the given cases and depends only on the ʿilla gives the farʿ the aṣl's ruling.
- `gate_consistent`: through the gate, such a ruling exists. The naqḍ impediment is exactly what consistency needs: removing it breaks this theorem, which was mutation-checked.

## All objections at once: the debate gate (`Usul.Jadal`)

The sources list twelve objections (Rawḍa v2 p301; al-Ṭūfī v3 p458) or twenty-five (al-Kawkab v4 p229, after Ibn al-Ḥājib and Ibn Mufliḥ). They hold that «all reduce to manʿ or muʿāraḍa» (al-Ṭūfī v3 p565; al-Kawkab v4 p229; Ādāb al-Baḥth p351). `Usul.Jadal` makes that a theorem.

A `Debate` extends the qiyās `Argument` with everything an objection speaks about. Each `Qadih` (eighteen of them) has a success condition and a kind:

| Kind | Objections | Role in the gate |
|---|---|---|
| manʿ (denies a premise) | istifsār, manʿ, taqsīm, muṭālaba, al-qawl bi'l-mūjab, tarkīb, ikhtilāf al-ḍābiṭ, mukhālafat al-ḥukm, ifḍāʾ, inḍibāṭ | its negation is a condition |
| muʿāraḍa (brings a competing source) | fasād al-iʿtibār, fasād al-waḍʿ, naqḍ, kasr, ʿadam al-taʾthīr, farq, qalb, muʿāraḍa | it is an impediment |

- `debateGate_holds_iff`: the gate holds **iff no objection succeeds**. The list of objections is exactly the gate, nothing more and nothing less.
- `objection_blocks`, `kind_spec`: every successful objection blocks, as a missing condition or a present impediment.
- `debateGate_sound`: when none succeeds, every ruling agreeing with the given cases and depending only on the ʿilla gives the farʿ the claimed ruling.
- Qalb and muʿāraḍa produce a taʿāruḍ, which goes to `Usul.resolve` (`counter_resolved_by_tarjih`).

Mutation-checked: dropping an objection from `Qadih.all` breaks `mem_all`, and neutering tarkīb breaks soundness. The classification of each objection is this encoding's reading of the reduction claim, which the sources do not tabulate (IQ-18).

## Kinds of qiyās and tarjīḥ

| | Lean | Source |
|---|---|---|
| qiyās al-ʿaks: the contrary ruling where the ʿilla is absent | `qiyas_aks` | al-Kawkab v4 p8; Ibn ʿUthaymīn p74 |
| qiyās al-dalāla: joining by an indicator of the ʿilla | `dalala_verifies` | Rawḍa v2 p246; al-Kawkab v4 p7 |
| qiyās al-awlā / al-musāwī: a fortiori on a graded ʿilla | `qiyas_awla`, `qiyas_musawi` | Rawḍa v2 p187; al-Kawkab v4 pp. 105–106 |
| shabah only as a fallback after qiyās al-ʿilla (S2) | `farByOrder`, `shabah_never_overrides_illa` | al-Kawkab v4 p190 |
| tarjīḥ: pick an ʿilla of maximal rank (S8) under any scale meeting the stated constraints | `RespectsSources`, `preferred_optimal`, `sabr_beats_shabah` | al-Kawkab v4 p718; Rawḍa v2 p401; al-Ṭūfī v3 p716 |

Tarjīḥ is stated as *constraints* (sabr ≻ munāsaba ≻ shabah, ijmāʿ ≻ naṣṣ ≻ inferred), not as an invented total order. `exampleRank_respects` shows the constraints are consistent.

## Disputed points are parameters, with the established positions cited

| Question | Parameter | Established answer cited |
|---|---|---|
| IQ-13 takhṣīṣ al-ʿilla | `policy : IllaSource → Bool` | al-Musawwada v1 p412: no takhṣīṣ of an inferred ʿilla (Aḥmad), two views among the companions. Rawḍa v2 p274: Ibn Qudāma defends the split by source. Al-Kawkab v4 p58: ten views, most Ḥanbalīs allowing takhṣīṣ. **The sources report al-Qāḍī on both sides** (Rawḍa v2 p271 vs al-Kawkab v4 p58). Ibn al-Qayyim (Iʿlām v3 p27): takhṣīṣ for a missing condition or a present impediment |
| IQ-14 plural ʿilal | `allowPlural` | al-Musawwada v1 p328: permitted when the two require one ruling |
| IQ-15 kasr | `Policy.admitKasr` (an impediment of the debate gate when admitted) | al-Musawwada v1 p428: two views; Abū al-Khaṭṭāb: not valid. Rawḍa v2 p312, al-Ṭūfī v3 p510, al-Kawkab v4 p67: not binding (the sound view among the companions). Al-Shinqīṭī (Mudhakkira p459): like naqḍ |
| IQ-17 shabah | `acceptShabah` in `farByOrder` | al-Kawkab v4 p190: a proof for us only where qiyās al-ʿilla is impossible; Rawḍa v2 p243: two reports from Aḥmad, al-Qāḍī rejecting; Ibn al-Qayyim (Iʿlām v1 p115): reported only from those in error; Ibn Taymiyya (al-Radd p203): folded into ʿilla or dalāla |
| IQ-18 manʿ / muʿāraḍa classification | `Qadih.kind` | al-Ṭūfī v3 p565, al-Kawkab v4 p229, Ādāb al-Baḥth p351 (some: all reduce to manʿ), p344 (muṭālaba and tarkīb under manʿ) |
| IQ-16 the mursal | `acceptMursal` | al-Musawwada v1 p450: not, per the later Ḥanbalī uṣūlīs (Mālik: yes); Rawḍa v1 p477: the threefold division |

These are interpretive commitments for the `SHARIAH-AUTHORITY` gate (see [`schemata.md`](schemata.md#governance-where-the-explanations-live-and-why-there)). Nothing here fixes a parameter.

## Citation map

`corpus/citations/qiyas_principles.json` (schema `citation_map.schema.json`) holds 241 citations from the qiyās chapters of the pinned works:

| Work | Pages |
|---|---|
| Rawḍa | v2 pp. 140–332, 397–401 |
| al-Ṭūfī | v3 pp. 218–574, 713–720 |
| al-Kawkab | v4 pp. 5–396, 716–735 |
| Iʿlām | v1 pp. 102–116, 151–263, 289 to v2 p44 |
| Ibn Taymiyya, al-Radd | pp. 115–121, 200–212, 371–373 |
| al-Shinqīṭī's Mudhakkira | pp. 379–492 |
| al-Shinqīṭī's Ādāb al-Baḥth | pp. 290–355 |
| Ibn ʿUthaymīn | pp. 68–74 |

Every excerpt was re-verified verbatim against the cached witness, and every OpenITI locator against the next page marker, before commit. Its `formalises` table maps each topic to the Lean constants it grounds, and `unformalised` names the rest:
- ḥujjiyya;
- shahādat al-uṣūl;
- jalī versus khafī;
- qiyās in asbāb, fixed amounts and negation;
- Ibn al-Qayyim's catalogue of erroneous qiyās;
- tamthīl versus shumūl.

`test_citation_maps_are_grounded` requires every catalogued `Usul.Qiyas` / `Usul.Jadal` constant to be grounded by a cited topic.

## Sources

The 23 classical works located and pinned for this (`corpus/registry.json`, `layers: inference/dialectic`, each with its qiyās page span in `note`):
- **Ḥanbalī:** Abū Yaʿlā *al-ʿUdda*, Abū al-Khaṭṭāb *al-Tamhīd*, Ibn ʿAqīl *al-Wāḍiḥ*, *al-Musawwada*, Ibn Mufliḥ *Uṣūl*, al-Mardāwī *al-Taḥbīr*, Ibn Taymiyya *Risāla fī maʿnā al-qiyās* (in Majmūʿ al-Fatāwā v20), Ibn Badrān *al-Madkhal*.
- **Foundational and other madhhabs:** al-Shāfiʿī *al-Risāla*, Abū al-Ḥusayn al-Baṣrī *al-Muʿtamad*, al-Shīrāzī *al-Lumaʿ*, *al-Tabṣira*, *al-Maʿūna fī al-Jadal*, al-Juwaynī *al-Burhān*, al-Bājī *al-Ishāra*, al-Ghazālī *al-Mustaṣfā* and *Shifāʾ al-Ghalīl* (the monograph on the ʿilla), al-Sarakhsī *Uṣūl*, al-Rāzī *al-Maḥṣūl*, al-Āmidī *al-Iḥkām*, al-Iṣfahānī *Bayān al-Mukhtaṣar*.
- **Counter-position:** Ibn Ḥazm *al-Iḥkām* (bābs 38 and 39, against qiyās and ʿilal) and *al-Nubdha al-Kāfiya*.

Not on OpenITI: Ibn ʿAqīl's separate *Kitāb al-Jadal*, al-Shīrāzī's *Sharḥ al-Lumaʿ*, al-Bājī's *Minhāj* and *Iḥkām al-Fuṣūl*, Ibn al-Ḥājib's *Mukhtaṣar* as a separate text (its matn is inside *Bayān al-Mukhtaṣar*), and Ibn Ḥazm's *Mulakhkhaṣ Ibṭāl al-Qiyās*.
