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
| PR-02 | A | Other English glosses conflate terms whose rulings differ (families below) | 278 fields across 10 families | open |
| PR-03 | A | One Arabic word, several technical senses, one key: ṣaḥīḥ (valid act / ḥadīth grade / sound farq), ḍaʿīf, ʿilla (ratio legis / ḥadīth defect), ḥukm (ruling / judge's verdict), sharṭ (condition / stipulation, F28); and the transliteration homograph ghusl / ghasl | 6 senses | open |
| PR-04 | A | Furūq resting on a naṣṣ (basis `nass`) do not cite it from the foundation | 17 items (F11 … F165), plus the 2 ḍaʿīf ḥadīth of F20, F92 | open |
| PR-05 | A | The ḥadīth dalīls of the uṣūl records (`irwa_join.json`) are graded but not pinned to a primary collection | 13 links | open |
| PR-06 | B | CI never runs the verbatim checks: every one skips when the witness is not cached, so textual fidelity is enforced only locally | all verbatim tests | open |
| PR-07 | B | Excerpts that stop just before a qualifier («إلا», «لكن», «بخلاف» …), so the quote reads as unqualified | F126, F127; found by its guard: glossary `amana`, dossier `abstention_possible_condition`, and Ibn Taymiyya's «اعتقاد الرجحان» (glossary, dossier, IQ-21) | closed: quotes extended; guard over furūq, tanāquḍ, glossary and dossier |
| PR-08 | B | Ḥadīth numbers are given without their numbering scheme (Abū Dāwūd 206 in Muḥyī al-Dīn's edition; al-Irwāʾ cites «رقم ٢٠٠ من الصحيح», al-Albānī's own) | 4 sources | closed: `numbering` required on every source and on al-Albānī's entry |
| PR-09 | B | Lean inductives name fiqh concepts in English with no Arabic anchor in their doc comment | 52 of 71 | open |
| PR-10 | B | Cached witnesses are used by tests without checking them against the sha256 pinned in `lock.json` | every verbatim test | closed: `test_witness_integrity.py` |
| PR-11 | C | al-Saʿdī's born-digital witness has no page markers, so glossary refs cannot be located in it (worked around with the `furuq` field) | 1 witness | open |
| PR-12 | C | Tanzil's terms ask derived files to name the source and link tanzil.net | docs | open |
| PR-13 | B | Glossary definitions are drafted English paraphrases; a term whose refs carry no Arabic excerpt has nothing verbatim behind it | to be measured | open |
| PR-15 | B | Witnesses cited by the dossier and glossary are not cached locally, so their excerpt checks skip even on a developer machine (found while closing PR-07) | 172 skipped checks over 11 witnesses | in progress: 7 OpenITI and 1 Shamela fetched, all matching their pins; the OCR witnesses (archive-*-tess) need the OCR run |
| PR-14 | A | The bulk «impurity → najāsa» replacement could mislabel ḥadath | 27 fields | closed `021d1d8`: each reviewed; 18.f015 and 159.f007 corrected from source |

## PR-02 families (English gloss → terms it conflates)

| Family | Terms | Fields using the gloss without the term |
|---|---|---|
| pure, purity, purify | ṭāhir, ṭahūr, ṭahāra | 26 |
| wash, bath | ghusl, ghasl | 11 |
| void, invalid, defective | bāṭil, fāsid (the madhhab distinguishes them only in ḥajj and nikāḥ, F98) | 58 |
| expiation, compensation, blood-money | kaffāra, fidya, ḍamān, diya, arsh, jazāʾ | 26 |
| oath, vow | yamīn, nadhr | 30 |
| divorce, separation | ṭalāq, khulʿ, faskh | 45 |
| obligatory, recommended, duty | wājib, farḍ, mandūb, sunna | 45 |
| weak, sound | ḍaʿīf, ṣaḥīḥ (whose: a farq, a ḥadīth, a view) | 11 |
| cause, reason | ʿilla, sabab | 24 |
| charity, alms | zakāt, ṣadaqa | 2 |

## Log

Each item, when worked, gets a paragraph here: what was found, what changed, and the guard that keeps it closed.

**PR-07.** The guard `nusus.cut_before_qualifier` flags an excerpt whose witness goes on, within a few characters, with «إلا», «ما لم», «بشرط», «لكن», «إن لم», «بخلاف», «غير أن» or «إذا لم». It found the two furūq expected. Run over the glossary and dossier, it found two more the map had missed. In Ibn Rajab's trustee «فهو أمين محض» the text goes on «لكن إذا تلفت الوديعة من بين ماله ففي ضمانه خلاف». In the abstention entry «متيقن لحل زوجته شاك في تحريمها» it goes on «بخلاف ما إذا كانت الزوجتان لرجل واحد», which is T-15's own qayd. Once the Majmūʿ was cached (PR-15), the guard found a fifth: Ibn Taymiyya's «فرق بين اعتقاد الرجحان ورجحان الاعتقاد … فهو الظن» goes on «لكن لم يكن ممن قال الله فيه: {إن يتبعون إلا الظن} بل … هذا الظن هو الراجح ورجحانه معلوم». That continuation is IQ-21's own point; it stood cut in the glossary, the dossier and the interpretive-questions register. All quotes now carry their qualifier. One test, `test_no_sourced_excerpt_stops_before_its_qualifier`, covers every excerpt in the corpus that names its witness (806 checked).

**PR-08.** Every ḥadīth source in the foundation names whose numbering it follows. The tests already check the number under that edition's own markers.

**PR-10.** `test_witness_integrity.py` hashes every cached witness against `lock.json` before any excerpt test can lean on it. All 49 cached witnesses match.
