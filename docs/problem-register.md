# Problem register

The register maps every known way the bank could misstate its sources, and tracks each problem to closure. It is kept in the order work is done. New problems are added as they are found, with the item that found them. "Detected by" names the check that measured the problem; "closed by" names the commit and the guard that keeps it closed.

Severity:

* **A**: can change a derivation's output or misattribute a ruling.
* **B**: weakens the guarantee that the text is faithful.
* **C**: hygiene.

## Open and closed

| ID | Sev | Problem | Measured | Status |
|---|---|---|---|---|
| PR-01 | A | English «semen» conflates al-manī, al-madhy and al-wadī; «impurity» conflates al-najāsa and al-ḥadath | 30 fields | closed `021d1d8`: term guards, `Usul.Tahara` |
| PR-02 | A | Other English glosses conflate terms whose rulings differ (families below) | 278 fields across 10 families | closed: every family below has its terms and a guard over the registers and glossary; the Lean docs' generic «cause», «strong», «sound» are out of scope |
| PR-03 | A | One Arabic word, several technical senses, one key: ṣaḥīḥ (valid act / ḥadīth grade / sound farq), ḍaʿīf, ʿilla (ratio legis / ḥadīth defect), ḥukm (ruling / judge's verdict), sharṭ (condition / stipulation, F28); and the transliteration homograph ghusl / ghasl | 6 senses | partly closed: ṣaḥīḥ (act / ḥadīth / view / farq), ḍaʿīf (ḥadīth / view / farq) and ʿilla (ruling / ḥadīth) are sense-keyed terms, and terms sharing an `ar` must declare distinct senses (tested). sharṭ (of a thing) / al-shurūṭ fīhā (a party's stipulation, F28) / al-taʿlīq likewise (guard «condition», 50 sites). The «void» of an ʿilla is al-ibṭāl or al-qadḥ and the «sound» qiyās al-qiyās al-ṣaḥīḥ, each a term (PR-23). ḥukm (the Lawgiver's) / ḥukm al-ḥākim (a judge's verdict, Ibn Rajab Q68), with a guard on «ruling» beside «judge». Closed |
| PR-04 | A | Furūq resting on a naṣṣ (basis `nass`) do not cite it from the foundation | 17 items (F11 … F165), plus the 2 ḍaʿīf ḥadīth of F20, F92 | closed: 12 items cite 5 āyāt, 8 ḥadīth and 1 athar; 6 recorded as «unspecified» by his own wording; al-Saʿdī's «لم يصح» agrees with al-Albānī on both rejected ḥadīth |
| PR-05 | A | The ḥadīth dalīls of the uṣūl records (`irwa_join.json`) are graded but not pinned to a primary collection | 13 links | closed: all 13 links rest on 13 foundation ḥadīth, each verbatim under its number in a primary collection and graded from al-Irwāʾ (one ḍaʿīf report in two wordings; «الصلح جائز» ḥasan apart from «المسلمون على شروطهم» ṣaḥīḥ); a test resolves every link |
| PR-06 | B | CI never runs the verbatim checks: every one skips when the witness is not cached, so textual fidelity is enforced only locally | all verbatim tests | open |
| PR-07 | B | Excerpts that stop just before a qualifier («إلا», «لكن», «بخلاف» …), so the quote reads as unqualified | F126, F127; found by its guard: glossary `amana`, dossier `abstention_possible_condition`, and Ibn Taymiyya's «اعتقاد الرجحان» (glossary, dossier, IQ-21) | closed: quotes extended; guard over furūq, tanāquḍ, glossary and dossier |
| PR-08 | B | Ḥadīth numbers are given without their numbering scheme (Abū Dāwūd 206 in Muḥyī al-Dīn's edition; al-Irwāʾ cites «رقم ٢٠٠ من الصحيح», al-Albānī's own) | 4 sources | closed: `numbering` required on every source and on al-Albānī's entry |
| PR-09 | B | Lean inductives name fiqh concepts in English with no Arabic anchor in their doc comment | 52 of 71 | open |
| PR-10 | B | Cached witnesses are used by tests without checking them against the sha256 pinned in `lock.json` | every verbatim test | closed: `test_witness_integrity.py` |
| PR-11 | B | al-Saʿdī's born-digital witness has no page markers, so glossary refs could not be located in it (raised from C: it blocked defining terms from his own words in PR-02) | 1 witness | closed: refs may anchor to a furūq item or qāʿida (`src:islamhouse-qj-doc#F19`, `#q040`) when the excerpt is unique in the witness (tested) |
| PR-12 | C | Tanzil's terms ask derived files to name the source and link tanzil.net; the registry also called the text `public_domain_text`, though Tanzil licenses it CC BY 3.0 on condition it is not changed | docs, 1 right | closed: right `cc_by_verbatim`; the foundation carries the witness's own notice (schema-required, tested against the cached notice) and the glossary page reproduces it |
| PR-13 | B | Glossary definitions are drafted English paraphrases; a term whose refs carry no Arabic excerpt has nothing verbatim behind it | 4 of 126 (mandūb, mubāḥ, makrūh, khāṣṣ: empty heading records) | closed: Ibn ʿUthaymīn's definitions added verbatim; a test requires every term to rest on a verbatim text |
| PR-15 | B | Witnesses cited by the dossier and glossary are not cached locally, so their excerpt checks skip even on a developer machine (found while closing PR-07) | 172 skipped checks over 11 witnesses | in progress: 7 OpenITI and 1 Shamela fetched, all matching their pins; the OCR witnesses (archive-*-tess) need the OCR run |
| PR-16 | A | The pinned al-Irwāʾ (Shamela 22592) is incomplete: its pages are blank on Shamela itself through much of vol. 6 onward (found while closing PR-04: «لا وصية لوارث» had no entry) | 562 of 2683 (707 before PR-26) entries | mitigated: the gap is pinned (`corpus/hadith/irwa_coverage.json`); verdicts on missing entries come from al-Albānī's Ṣaḥīḥ wa-Ḍaʿīf Sunan al-Tirmidhī (OpenITI, pinned), which cites the Irwāʾ number; a complete witness of al-Irwāʾ is still wanted |
| PR-17 | B | Quotes that occur more than once in their witness do not fix their own place (F63's «… الثابتة بالنص» is the head of F49's «… بالنص والإجماع») | 10 excerpts | closed for unpaged quotes (furūq, tanāquḍ): unique by test; paged refs are fixed by their page |
| PR-18 | A | Matching a matn by its words can land on a false friend: a bāb heading («باب ما جاء لا وصية لوارث»), or another ḥadīth with the same words (al-Bukhārī 50, «رعاة الإبل» in Jibrīl's ḥadīth) | found while closing PR-04 | closed: a matn must fall under its number and never on a heading line (tested); each source may carry its own riwāya wording |
| PR-19 | B | Slicing a Qurʾānic excerpt by letters dropped the last letter's vowel (لِلَّه for لِلَّهِ): the muṣḥaf's text altered | found while closing PR-04 | closed: `span` keeps the final marks |
| PR-20 | A | Two fetches running at once each rewrote `lock.json` from their own copy, so one pin was silently lost (al-Albānī's Ṣaḥīḥ wa-Ḍaʿīf al-Tirmidhī; found while closing PR-04) | 1 pin | closed: `_pin` merges under a file lock and writes atomically; concurrent pins and "cached but unpinned" are tested |
| PR-21 | B | Hash-pinned contribution receipts (M8 tranche 3) could record a revisit but not an English-only note correction, so fixing a gloss broke provenance | 1 case | closed: a `note_revisions` ledger keeps the old English note and position labels; the test restores them and must get the receipt back, so no ruling, class or fact can have changed |
| PR-22 | A | An English note asserted a tarjīḥ its source does not make: q068.f007 «the stronger view» where Ibn Rajab says only «على وجهين». Found while closing PR-03, with q014.f000 «hear a sound» for «سمعا صوتا خارجا» (wind breaking: a ḥadath) and q140.f003 «a sound eye» for «عين الصحيح» (the eye of a man whose eyes are sound) Q19's «إذا تعذر المسمى» was «the stipulated price» in the proposals and the Lean docs: it is the named price (al-musammā), no stipulation PR-23 found two more: Q38's «فسدت» glossed «void» (it is fāsid), and Q65's «لا يصح العفو» rendered «the pardon is void» (it is not ṣaḥīḥ) | 35 claims audited, 1 false; 3 glosses | closed: each corrected from source; a test asks every positive tarjīḥ claim for a tarjīḥ word in its source paragraph |
| PR-23 | A | The guards read the registers, glossary gloss and definition, and Lean docs, but not the other English that states rulings: the foundation's own `en`, the qāʿida glosses (`proposals.gloss_en`), the citation claims (`claim_en`, `hanbali_position`), glossary conditions and ref notes, and the refinement titles and rationales. Found while closing «condition» (the Q19 gloss) | 99 fields: 46 condition, 27 void, 16 sound, 7 compensation, 2 pure, 1 wash; mostly the qiyās citations, where «void» is the buṭlān of an ʿilla and «sound» the ṣaḥīḥ of a qiyās | closed: the guard reads all of them (tested); 3 terms (al-ibṭāl, al-qadḥ, al-qiyās al-ṣaḥīḥ); a term may list `forms`, so quoting the source word («فسدت», «يقدح») names it; 99 fields named from their source |
| PR-24 | B | The six frozen M5 gap cases were re-pinned by hand when an English note changed (q022.f000 for «impurity», then lahham 52.f007 for «divorced»), so the pin no longer proved the case was the original | 2 re-pins | closed: the original hashes are restored and a `GAP_NOTE_REVISIONS` ledger keeps each old note; the test restores it and must get the original hash, as PR-21 does for tranche 3 |
| PR-25 | B | A substitution re-run after a partial failure doubled its own insertion wherever the new text contained the old (e.g. «إطلاق الوجوب أو الفرض» twice); 9 sites, 2 already committed | 9 fields | closed: repaired; a test rejects any quote or parenthetical repeated back to back, and the edit helper skips an edit already applied |
| PR-26 | A | The al-Irwāʾ reader kept a header only if it continued the run greedily, so one misnumbered header («(٣٣٨)» printed for 238) made it drop every entry from 238 to 338, and al-Albānī's verdicts there (e.g. 276, «من عمل عملا ليس عليه أمرنا فهو رد») read as absent. Found while closing PR-05 | 145 entries | closed: the reader takes the longest increasing run of headers; coverage re-pinned (2121 found, 562 missing, of which only 238 and 2555 are present but unread) |
| PR-27 | A | Merging main brought ~400 new annotations written before the term guards existed; 246 English sites named no term, and some mistranslated | 246 fields | closed: each named from its source word (four parallel passes, applied centrally, every guard green); main's independent readings of Ibn Rajab 3, 9, 14, 15 (tranches 7–8) supersede this branch's tranche 6 |
| PR-28 | A | Two readings of Ibn Rajab 3, 9, 14 and 15 coexisted after the merge, and on 14.f000 the M8 reading bound each man to the ghusl where the madhhab binds neither | 4 qawāʿid, 1 farʿ | closed: Q3, Q9, Q15 proved equivalent; Q14 joined (jamʿ) by Ibn Rajab's own ground «متيقن للطهارة شاك في الحدث» (`attachOnCertainty`, conservative), 14.f000 revisited onto the madhhab the ledger's taṣḥīḥ and jazm already held |
| PR-14 | A | The bulk «impurity → najāsa» replacement could mislabel ḥadath | 27 fields | closed `021d1d8`: each reviewed; 18.f015 and 159.f007 corrected from source |

## PR-02 families (English gloss → terms it conflates)

| Family | Terms | Fields using the gloss without the term |
|---|---|---|
| pure, purity, purify | ṭāhir, ṭahūr, ṭahāra, maḥḍ | 26: closed (glossary, guard, 31 sites) |
| wash, bath | ghusl, ghasl | 11: closed (terms vowelled الغُسل / الغَسل, guard, 14 sites) |
| void, invalid, defective | bāṭil, fāsid (the madhhab distinguishes them only in ḥajj and nikāḥ, F98), «لا يصح», ʿayb | 58: closed for the registers and Lean docs (76 sites); the glossary's «void» of an argument moves to PR-03 |
| expiation, compensation, blood-money | kaffāra, fidya, ḍamān, diya, arsh, jazāʾ, fidāʾ | 26: closed (6 terms, 4 āyāt added, 38 sites) |
| strong, stronger | aqwā, ākad, qawiyy, rājiḥ (of a proof, a ẓann, the qarāʾin) | 15: closed (guard; «أقوى/أرجح/قويت/آكد» as forms of al-tarjīḥ; farḍ «آكد» is emphasis, not a stronger proof) |
| condition, conditional, stipulation | sharṭ, al-shurūṭ fīhā, taʿlīq | 50: closed (2 terms, guard, 50 sites; 6 Lean docs) |
| oath, vow | yamīn (binding), yamīn of a claim, nadhr, taʿlīq | 45: closed (3 terms, two senses of al-yamīn; q014.f001 and the raven cases are taʿlīq, not oaths) |
| divorce, annul, dissolve, rescind | ṭalāq, khulʿ, faskh, infisākh | 45: closed (4 terms; Q133.f003's «annulment» is infisākh; Rawḍa's «لا ينعدم» is not «annulled») |
| obligatory, recommended, duty, voluntary | wājib (wujūb), farḍ / nafl, mandūb (mustaḥabb, sunna, taṭawwuʿ) | 60: closed (farḍ a term; F67's «an obligation» is a ʿazīma) |
| binding | ilzām, luzūm (lāzim / jāʾiz), inʿiqād, «غير لازم» of an objection | 30: closed (luzūm a term; Q55 «لا عذر لمن أقر» is not «binds») |
| weak, sound | ḍaʿīf, ṣaḥīḥ (whose: a farq, a ḥadīth, a view), al-aṣaḥḥ | 11: closed (8 sense-keyed terms, guard over registers and glossary, 20 sites) |
| cause | ʿilla (manāṭ), sabab, ḥikma | 48: closed (guard with forms; Q51's «الأسباب والدواعي» are motives; #74's «لمقتض مشترك» a muqtaḍī; Q7's «reason» is ʿaql) |
| charity, alms | zakāt, ṣadaqa | 5: closed (2 terms; Q18 is the clash: a vowed ṣadaqa of a niṣāb against its zakāt) |

## Log

Each item, when worked, gets a paragraph here: what was found, what changed, and the guard that keeps it closed.

**PR-07.** The guard `nusus.cut_before_qualifier` flags an excerpt whose witness goes on, within a few characters, with «إلا», «ما لم», «بشرط», «لكن», «إن لم», «بخلاف», «غير أن» or «إذا لم». It found the two furūq expected. Run over the glossary and dossier, it found two more the map had missed. In Ibn Rajab's trustee «فهو أمين محض» the text goes on «لكن إذا تلفت الوديعة من بين ماله ففي ضمانه خلاف». In the abstention entry «متيقن لحل زوجته شاك في تحريمها» it goes on «بخلاف ما إذا كانت الزوجتان لرجل واحد», which is T-15's own qayd. Once the Majmūʿ was cached (PR-15), the guard found a fifth: Ibn Taymiyya's «فرق بين اعتقاد الرجحان ورجحان الاعتقاد … فهو الظن» goes on «لكن لم يكن ممن قال الله فيه: {إن يتبعون إلا الظن} بل … هذا الظن هو الراجح ورجحانه معلوم». That continuation is IQ-21's own point; it stood cut in the glossary, the dossier and the interpretive-questions register. All quotes now carry their qualifier. One test, `test_no_sourced_excerpt_stops_before_its_qualifier`, covers every excerpt in the corpus that names its witness (806 checked).

**PR-08.** Every ḥadīth source in the foundation names whose numbering it follows. The tests already check the number under that edition's own markers.

**PR-10.** `test_witness_integrity.py` hashes every cached witness against `lock.json` before any excerpt test can lean on it. All 49 cached witnesses match.

**PR-04.** Of the 19 items resting on a naṣṣ, al-Saʿdī cites 12 so that the text can be fixed, and the foundation now holds each one, verified in its pinned witness:
* quoted: al-Māʾida 95 (F15), al-Baqara 179 (F49), al-Baqara 224 with «من حلف على يمين فرأى غيرها خيرا منها» (F63, Muslim 1650), «ليس لعرق ظالم حق» (F148, Abū Dāwūd 3073), and «الشفعة كحل العقال» with Shurayḥ's «إنما الشفعة لمن واثبها» (F92);
* named: al-Baqara 196 (F11), the herders' concession (F16, Abū Dāwūd 1975);
* identified from his allusion: al-Baqara 196 «وأتموا» (F12), al-Māʾida 95 (F17), «لا وصية لوارث» (F48, Abū Dāwūd 2870, al-Tirmidhī 2120), the child's ḥajj (F73, Muslim 1336), the iḥdād ḥadīth (F163, al-Bukhārī 1280), the siwāk ḥadīth (F20, al-Irwāʾ 67).
Six say only «ظاهر النصوص», «الأدلة», «الآثار» or «العموم» (F42, F125, F128, F136, F140, F165); they are recorded as `unspecified`, and nothing is supplied for him. Where he says no sound ḥadīth exists, al-Albānī agrees: al-Irwāʾ 67 «ضعيف», 1542 «ضعيف جدا». Each naṣṣ item's ḥadīth passes the gate and each rejected one fails it, in pytest and in the generated `NususTable.lean`. F16's water-carriers of Zamzam rest on a separate report not yet entered; the note says so.

**PR-16.** Shamela's al-Irwāʾ has blank pages: the page HTML carries only its anchor. The pinned text holds 1976 of the 2683 entries it reaches; the missing numbers are pinned, and no verdict is taken from a missing entry. Where the verdict is needed, al-Albānī's Ṣaḥīḥ wa-Ḍaʿīf Sunan al-Tirmidhī supplies it under al-Tirmidhī's number and names the Irwāʾ entry («صحيح، الإرواء (2114)»). The parser also learnt al-Irwāʾ's three header forms («# (٦) - حديث», «# [(٢٠) - (», «# (١٤٣) (»), read in sequence so that a cross-reference is never taken for a header.

**PR-17.** F63 and F94 now quote enough to be unique; furūq and tanāquḍ quotes must occur exactly once in their witness.

**PR-18, PR-19.** Found while entering the PR-04 texts; see the table.

**PR-11.** A glossary or dossier ref into an unpaged witness may name a furūq item or qāʿida instead of a page; it is valid only if the excerpt occurs exactly once in the witness.

**PR-02, «pure».** Four terms are now defined from the canonical texts.
* al-ṭahūr: al-Furqān 48; «هو الطهور ماؤه» (Abū Dāwūd 83; al-Irwāʾ 9, ṣaḥīḥ); F19.
* al-ṭāhir: F19, F120. It records that the madhhab's division of water has a middle class, ṭāhir but not purifying («يسلبه الطهورية»), which al-Saʿdī grades weak.
* al-ṭahāra: F68, F121, Iʿlām.
* al-maḥḍ: Q40, F13. «Pure» in the sense of «sheer» is not a purity term.

The guard then found 31 sites in the registers and the Lean doc comments. Each was rewritten from its context. Some are ṭāhir (an undeclared carcass's hair; manī; street mud), some ṭahūr (water for wuḍūʾ; making najis water ṭahūr), some ṭahāra (the aṣl of ṭahāra of a person or thing), and some maḥḍ (a pure means, rights purely God's, a trust outright). One was qinn («the pure slave» is the slave outright). The ẓāhir/aṣl notes of Ibn Rajab 159 now say «asl of ṭahāra» against «zahir of najāsa».

**PR-02, «wash».** Unvowelled, الغسل is both al-ghusl and al-ghasl, so the glossary now vowels its Arabic keys (الغُسل, الغَسل) as well as naming them.
* al-ghusl rests on al-Māʾida 6 «فَاطَّهَّرُوا», al-Nisāʾ 43 «حَتَّىٰ تَغْتَسِلُوا», Abū Dāwūd 206 and F52.
* al-ghasl rests on al-Māʾida 6 «فَاغْسِلُوا وُجُوهَكُمْ» (now in the foundation), Muslim 303 and F70.
* The guard found 14 sites. Three of them show why it matters:
  * F52's «major ritual washing» is, in al-Saʿdī's words, «طهارة الحدث الأكبر», that is, ghusl against wuḍūʾ.
  * F115's «washing with usurped water» is «من توضأ بماء مغصوب», wuḍūʾ.
  * Ibn Rajab 14.f000's «neither must wash» was «لا يلزم واحدا منهما غسل ولا وضوء», ghusl and wuḍūʾ; the note now says so.

**PR-02, «void / invalid / defective».** New terms: al-bāṭil, from F98's «وأما بقية الأبواب فجعلوا الباطل والفاسد واحداً، الكل لا يصح», and al-ʿayb (F138, Ibn Rajab 30). al-fāsid and al-ṣaḥīḥ have their one-word glosses replaced by their senses. Each site was rewritten from its source word: «لا يصح» as not ṣaḥīḥ, «بطل/بطلان» as bāṭil, «فاسد» as fāsid. Three sites were not about validity at all:
* F138's «defective sale» is «البيع المعيب», goods with a defect. The sale is ṣaḥīḥ, with an option.
* Ibn Rajab 30.f000's sacrifice that «becomes defective» is «ثم تعيبت», a blemish.
* F30's «contract voided» is a contract undone (infisākh) for a defect, not one bāṭil from its start.

al-Saʿdī's Q53 («إذا تبين فساد العقد، بطل ما بني عليه») holds both terms in one sentence, and its Lean doc had flattened them into «void voids». The guard now also reads the `who` labels of positions, which found 9 more sites across the families already closed. The glossary's «void» of a ʿilla or an argument is the buṭlān of a dalīl, a different sense, and is left to PR-03.

**PR-02, «expiation / compensation».** Six terms are defined from the texts. Four āyāt are added to the foundation: al-Māʾida 89, al-Baqara 184 and the fidya clause of 196, and al-Nisāʾ 92.
* al-kaffāra: al-Māʾida 89; F63 «ففيه الكفارة إذا حنث».
* al-fidya: al-Baqara 196 and 184; F13.
* al-jazāʾ: al-Māʾida 95; F17 «وأن جزاء الصيد يتعين فيه المثل لظاهر النص».
* al-diya: al-Nisāʾ 92; F49 «الذي يوجب الدية فقط».
* al-arsh: F21 «موجب للرد أو الأرش».
* al-fidāʾ, ransoming, not fidya: F145.

Each of the 38 sites names its term from its source:
* game is jazāʾ (F15, F17); a defect in goods is arsh (F21); killing is diya (F44, F49, F66);
* oaths and ẓihār are kaffāra (F59 … F63); what the slave destroys is ḍamān (F43, «قيمة متلف»);
* doubling under Q35 and Ibn Rajab 140 is of ḍamān, in al-Saʿdī's words «ضوعف عليه الضمان»;
* ransoming a slave or a captive is fidāʾ.

Where al-Saʿdī calls the old man's feeding «الكفارة» (F135), the āya says «فدية» (al-Baqara 184). The register keeps his word and notes the āya's.

**PR-03 with PR-02 «weak / sound».** al-Ṣaḥīḥ has four senses in the bank: of an act (valid), of a ḥadīth (al-Nukhba: «بنقل عدل تام الضبط، متصل السند، غير معلل ولا شاذ: هو الصحيح لذاته»), of a view (Ibn Rajab Q84: «والصحيح من المذهب»; al-aṣaḥḥ, Q26 «على أصح الوجهين») and of a farq (al-Saʿdī's «ومن الفروق الصحيحة», F28). al-Ḍaʿīf has three: of a ḥadīth (Ibn al-Ṣalāḥ), of a view (Q34 «وهذا ضعيف»), of a farq (F04). al-ʿIlla has two: the qiyās ʿilla and al-Nukhba's «علة خفية قادحة». Each is its own term, carries a `sense`, and names the others in `distinct_from`; a ḥadīth term links its Lean anchor (`Hadith.Verdict.sahih`, `Usul.Seam.admitted`). Twenty sites now name their sense from the source word.

Three of them were not loose wording but wrong translations (PR-22). «سمعا صوتا خارجا» is a sound of wind breaking, a ḥadath, which is why the case is about wuḍūʾ at all. «عين الصحيح» is the eye of a man whose eyes are both sound, against the one-eyed. And q068.f007 claimed a «stronger view» where Ibn Rajab ranks neither wajh. The audit of all 35 tarjīḥ claims in the takhrīj notes found no other.

A family the audit surfaced: «strong / stronger» (aqwā, ākad, qawiyy, rājiḥ) is generic in the glossary's proof talk and needs its own pass.

**PR-03 with «condition».** English «condition» was three terms. al-Saʿdī's F28 separates the shurūṭ of a thing, «مقوماتها التي لا تتم ولا تصح إلا بها», from the shurūṭ in it, «أمور خارجة عن نفس العقود، وإنما يشرطها أحد المتعاقدين». The third is al-taʿlīq, suspending a contract or divorce on an event. He counts it among the stipulations («ومن أهم الشروط التعليقات», F23), and the glossary says so rather than set the two apart. Each of the 50 sites was named from its source word:

* «لا يصح تعليقه», «علق الطلاق», «معلقا بموته» are taʿlīq;
* «بشرط العتق», «بشرط القطع», «شرط الوقف» are stipulations;
* «شرط الصحة», «لا يشترط», «زال أحد الشرطين» are sharṭ.

Q19's «المسمى» had been rendered «the stipulated price» in the proposals and two Lean docs (PR-22); it is the named price. Measuring that gloss showed the guards do not read the proposals at all, nor several other English fields that state rulings (PR-23).

**PR-23, the unguarded fields.** The guards now read every English field that states a ruling or a claim: the foundation's translations, the qāʿida glosses, the citation claims, glossary conditions and ref notes, and the refinement titles, rationales and conditions. In the qiyās citations, «void» was three different words in the sources: «بطل / إبطال / بطلان» (al-ibṭāl, refuting an ʿilla), «يقدح» (al-qadḥ, impairing it) and «إفساد / فاسد». Each is now a term or a listed form of one. «Sound qiyās» is al-qiyās al-ṣaḥīḥ, after Ibn al-Qayyim's «والقياس الصحيح هو الميزان». Two glosses had changed the ruling (PR-22): al-Saʿdī's Q38 «فسدت» read «it is void», though the madhhab separates bāṭil from fāsid in ḥajj and nikāḥ (F98); and Ibn Rajab Q65's «لا يصح العفو» read «the pardon is void». Q53 now carries both of its terms, «إذا تبين فساد العقد بطل ما بني عليه». One «void» was English for «devoid» (#182).

**PR-03, ḥukm.** Beside a judge, English «ruling» is either the sharʿī ḥukm he applies or his verdict, ḥukm al-ḥākim. Only the verdict is «undone»: Ibn Rajab Q68, «ولم ينقض حكمه إلا أن يكون مخالفا لنص صريح». q068.f009 and its refinement now say «verdict (ḥukm al-ḥākim)». The angry-judge example of a ruling's ʿilla (qiyās citation 143) is the sharʿī ḥukm. PR-03 is closed: every polyseme found has a term per sense, and terms sharing an Arabic word must say which sense they are.

**PR-02, «charity», «strong», «cause».** al-Zakāt and al-ṣadaqa are terms; Ibn Rajab Q18 is where they meet, a vowed ṣadaqa of a niṣāb at the ḥawl. «Strong» was always a weight, in tarjīḥ, of a ẓann, or of the qarāʾin, except wājib's ref note, where farḍ is «آكد» (more emphatic), and Ibn Qudāma's «بدليل آكد منه» for the weightier proof in muʿāraḍa. «Cause» is three terms: the ʿilla (the manāṭ extended by qiyās), the sabab (what a ruling attaches to: Q31, Q39, Q46, dhawāt al-asbāb in F126) and the ḥikma. Three English words had stood for other terms: Q7's «reason» is ʿaql, Q35's «for a reason» is «لموجب», and Q51's «causes and motives» are «الأسباب والدواعي», the motives of a contract. The Lean docs' «cause» (31) and «strong» (15) are mostly logical usage and stay out of scope.

**PR-02, «oath / vow».** «Oath» was three things. One is the binding yamīn, broken by ḥinth and released by kaffāra, with laghw al-yamīn outside it (F63). Another is the yamīn of a claim, a means of proof («واليمين على من أنكر», «بشاهد ويمين»), which is never broken and owes no kaffāra. The third is the «divorce oath», which in the raven cases (q014.f001, q160.f025) is a plain taʿlīq: «إن كان هذا الطائر غرابا فامرأتي طالق». Al-yamīn now has two sense-keyed terms on one Arabic word, under the polysemy test. «Vow» is al-nadhr, fulfilled and not expiated, «فالطاعة فيه مقصودة، بخلاف اليمين» (F59), except the vow that runs as an oath (F61). The regex had also caught «vowel»; it now matches the words only.

**PR-02, «divorce / annul / dissolve».** Four terms. Al-ṭalāq is the husband's word (Q63: «فإن الزوج يستقل بإزالته بالطلاق»). Al-faskh is a party's or a judge's undoing (F99, Q53, the freed wife's option). Al-infisākh is the contract ending of itself: Q133's «ويترتب على ذلك انفساخ النكاح» had been «annulment follows», though no one annuls. Al-khulʿ is disputed between ṭalāq and faskh, with the same ruling through a stranger on both. Ibn Qudāma's «والمصلحة أمر حقيقي لا ينعدم بمعارض» had been «not annulled»; it «does not cease to exist». «Revocable» of a bequest or a juʿāla is rujūʿ or a jāʾiz contract, not a rajʿī divorce, so the guard leaves that word to the divorce sites, which name the rajʿiyya.

**PR-02, «obligatory / binding».** «Obligatory» is al-wājib, one with al-farḍ in the sounder riwāya (Ibn al-Laḥḥām). Against the farḍ stands the nafl, not «the recommended»: F01–F10 set the fard prayer and fast against the nafl, and «recommended» is reserved for al-mandūb / mustaḥabb / sunna. F67's «an obligation» was al-Saʿdī's «وأنها عزيمة لا بد منها»: wiping the splint is a ʿazīma, against the khuff's rukhṣa. «Binding» is four things:

* ilzām, the binding demand of the wājib and the ḥarām;
* the luzūm of a contract: hire is lāzim, the juʿāla «عقد جائز» (F91), and the pledge binds after possession (F144);
* the inʿiqād of an oath;
* the dialectical «غير لازم» of kasr, which the opponent need not answer.

Q55's «لا عذر لمن أقر» had been «binds the confessor». One M5 receipt case (lahham 43.f004) now has a note revision in the plan's own ledger, checked by `m5_commands.validate` and by a test that an unledgered or altered note fails.

**PR-05, the uṣūl ḥadīth on the foundation.** The 13 ḥadīth cited as dalīl in the uṣūl records are now foundation entries. Each is pinned verbatim under its number in a primary collection, never in a heading, and graded from the al-Irwāʾ entry that cites it:

* Muslim 360, al-Nasāʾī 4855, al-Bukhārī 5086 and 6696, Abū Dāwūd 682, 2201, 2834, 3071 and 3594, Ibn Māja 2340 and 4227, Muslim 1718.
* «من عمل عملا ليس عليه أمرنا فهو رد» is pinned in Muslim, since in al-Bukhārī it is a muʿallaq.
* «إنما الأعمال بالنيات» is pinned in Abū Dāwūd and Ibn Māja, because this al-Bukhārī witness quotes it first in the editor's introduction, which would pin it to no number.
* Abū Dāwūd 3071 reads «من سبق إلى ماء» (water) where the uṣūl texts quote «ما». al-Irwāʾ 1555 itself notes «ما وقع للمؤلف هنا وهناك من الوهم».

Two entries were absent only because the Irwāʾ reader had dropped them (PR-26).

**PR-27, merging main.** Main's lane-A rounds and tranches 7–11 had annotated about 400 furūʿ before the guards existed, and 246 English sites named no term. Each was named from its source word, and several were mistranslations:

* **Ibn Rajab 72, 73, 99, and q049's khulʿ:** «عوض / معاوضة / مجانا بغير عوض» had been rendered «compensation», which is no expiation or ḍamān. It is a countervalue, ʿiwaḍ.
* **Qāʿida 102:** «ألغى ذلك السبب وصار وجوده كالعدم» had been rendered «voids». It is ilghāʾ.
* **q038.f005:** «يلغو» had been rendered «void».
* **q100.f005:** «سليمة» had been rendered «sound». It means free of defects.
* **q111.f001:** «موجب القتل القصاص عينا فالدية بدل» had been rendered «the cause».
* **q046.f000:** the note had al-Qāḍī himself swearing. In fact he rules on one who swears.

The tarjīḥ test also learned «ترجيح». This branch's tranche 6 is dropped in favour of main's independent readings of the same qawāʿid. Its Lean readings stay where the tanāquḍ pairs cite them, and reconciling the two readings is left open.

**PR-28, the bank applied to its two readings.** Following the integrator's rule for a duplicate principle, each pair of readings was either proved equivalent or joined.

* **Qāʿida 3:** `wholeObligatory = excessObligatory`.
* **Qāʿida 9:** `worshipValidDespite` is `validDespite` under the bijection of the four sites. The M8 reading thereby inherits the proof that Ibn Rajab 9 refines al-Saʿdī Q38.
* **Qāʿida 15:** `consequenceCarries` is the negation of `eachOnItsAsl`.
* **Qāʿida 14:** the two readings answer different moves of the text. One is each man alone («فهل يلحق الحكم بكل منهما», with the farq «بخلاف إيجاب الطهارة عليهما فإنه لا ضرر فيه»); the other is the two taken together («فينظر إليهما مجتمعين في حكم يتعلق باجتماعهما»).

The ledger already held, for 14.f000, al-Inṣāf «على الصحيح من المذهب», al-Furūʿ «عن الأصح» and Sharḥ al-Muntahā «فلا غسل على واحد». All three give neither man the ghusl, and Sharḥ al-Muntahā adds that neither follows the other in prayer, which is the joint ruling. Yet the entry had no jamʿ, and the M8 reading bound each. The jamʿ `attachOnCertainty` takes the first riwāya's own ground, «كل واحد منهما متيقن للطهارة شاك في الحدث», which is Q15. It is conservative over `attachTo` and departs only on the harmless case, only to «neither» (proved). `reconcile.check` confirms it lands on the prevailing side. The divorce and slave-women cases keep their abstention.

