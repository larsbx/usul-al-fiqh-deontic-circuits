# Fatāwā corpus and its reception

The canonical fatāwā, masāʾil and rulings collections that the modern Najdī–Salafī jurists build on, registered as pinned witnesses next to the uṣūl corpus. Each work carries a `reception` block in `corpus/registry.json`:

| `role` | Meaning |
|---|---|
| `cited` | a work the modern jurists cite: its `genre`, `madhhab`, the forms that name it (`cite_as`) and the namesakes that must not count (`not`) |
| `citer` | one of the modern jurists' own collections, tagged with its `scholar` (`ibn_baz`, `ibn_uthaymin`, `albani`, `sadi`) |

The modern oracle data (IslamQA answers that quote these muftīs) is a separate, unregistered source: see [`fatawa-oracle.md`](fatawa-oracle.md). This page covers the classical sources behind those answers.

All works are `layers: ["tests"]`: like *al-Inṣāf* and *al-Sharḥ al-Mumtiʿ* before them, they are sources of furūʿ for the takhrīj suite, not of rules. Nothing here is a fatwā, and the registry makes no claim about which view in a work is correct.

## Selection

The selection is scholarly (what these four are known to rely on), then checked against their texts by the [counts](reception-counts.md).

- **Masāʾil of Imām Aḥmad:** al-Kawsaj, Abū Dāwūd, Ḥarb al-Kirmānī.
- **Ijmāʿ and khilāf:** Ibn al-Mundhir (*al-Ijmāʿ*, *al-Awsaṭ*, *al-Ishrāf*), Ibn Ḥazm (*Marātib al-Ijmāʿ*, *al-Muḥallā*), Ibn ʿAbd al-Barr (*al-Tamhīd*, *al-Istidhkār*), Ibn Rushd (*Bidāyat al-Mujtahid*), al-Nawawī (*al-Majmūʿ*).
- **Ḥanbalī mutūn and shurūḥ:** Ibn Qudāma (*al-Mughnī*, *al-Kāfī*, *al-Muqniʿ*, *ʿUmdat al-Fiqh*), Majd al-Dīn (*al-Muḥarrar*), *al-Sharḥ al-Kabīr*, Ibn Mufliḥ (*al-Furūʿ*), *al-Mubdiʿ*, al-Mardāwī (*al-Inṣāf*, already registered), al-Ḥajjāwī (*Zād al-Mustaqniʿ*, *al-Iqnāʿ*), Ibn al-Najjār (*Muntahā al-Irādāt*), al-Buhūtī (*al-Rawḍ al-Murbiʿ*, *Kashshāf al-Qināʿ*, *Sharḥ al-Muntahā*).
- **Ibn Taymiyya and Ibn al-Qayyim:** *Majmūʿ al-Fatāwā*, *al-Fatāwā al-Kubrā*, *al-Mustadrak*, *Jāmiʿ al-Masāʾil*, al-Baʿlī's *al-Ikhtiyārāt al-Fiqhiyya*; *Zād al-Maʿād*, *Iʿlām al-Muwaqqiʿīn* (already registered), *al-Ṭuruq al-Ḥukmiyya*, *Aḥkām Ahl al-Dhimma*, *Ighāthat al-Lahfān*, *Badāʾiʿ al-Fawāʾid*; Ibn Rajab's *Qawāʿid* (already registered).
- **Ḥadīth al-aḥkām:** al-Khaṭṭābī (*Maʿālim al-Sunan*), al-Nawawī (*Sharḥ Muslim*), Ibn Ḥajar (*Fatḥ al-Bārī*, *Bulūgh al-Marām*, *al-Talkhīṣ al-Ḥabīr*), al-Ṣanʿānī (*Subul al-Salām*), al-Shawkānī (*Nayl al-Awṭār*, *al-Sayl al-Jarrār*, *al-Fatḥ al-Rabbānī*, *al-Durar al-Bahiyya*, the matn of *al-Rawḍa*, and its sharḥ *al-Darārī al-Muḍiyya*), Ṣiddīq Ḥasan Khān (*al-Rawḍa al-Nadiyya*). These are al-Albānī's main interlocutors.
- **Najdī fatāwā:** *al-Durar al-Saniyya*, *Fatāwā wa-Rasāʾil Muḥammad b. Ibrāhīm*, *Fatāwā al-Lajna al-Dāʾima* (first series).

Citers: Ibn Bāz (*Majmūʿ Fatāwā*, *Nūr ʿalā al-Darb*), Ibn ʿUthaymīn (*Majmūʿ Fatāwā wa-Rasāʾil*, *Nūr ʿalā al-Darb*, *al-Sharḥ al-Mumtiʿ*), al-Albānī (*Irwāʾ al-Ghalīl*, *Tamām al-Minna*), al-Saʿdī (*Irshād Ulī al-Baṣāʾir*, *Bahjat Qulūb al-Abrār*).

## Witnesses

The 49 new cited works and four of the citers (53 works in all) are on OpenITI. Each is pinned to the century repository's current commit, and its `#META#` title was checked against the registered title before it was added. The four al-Albānī and al-Saʿdī citers are not on OpenITI and come from Shamela (al-Albānī's author page is 414, al-Saʿdī's 128). Every witness is fetched, and its size and sha256 are in `corpus/lock.json`. Witnesses over 5 MB are `fetch: on_demand` (`make fetch` skips them; `fetch --work ID` gets them), as is *Irwāʾ*, whose page-by-page Shamela fetch takes hours. Works whose authors died after 1340 AH are `noncommercial_text`: cleared for non-commercial study, with 160-character excerpts in records. The text witnesses of these and of the public-domain works are committed under [`corpus/texts`](../../corpus/texts/README.md) (Git LFS).

Known witness limits, also in each work's `note`:
- al-Baʿlī's *Ikhtiyārāt* is a JK text whose page markers end at V01P049, so its completeness is unverified;
- *Fatāwā al-Lajna al-Dāʾima* is the first series only;
- *al-Majmūʿ* includes the takmila of al-Subkī and al-Muṭīʿī;
- *al-Rawḍa al-Nadiyya* includes al-Albānī's own *Taʿlīqāt*;
- *al-Durar al-Bahiyya* has two witnesses. ShamAY 34280 (ed. Ḥallāq) is the bare matn, whose OpenITI `AUTO` headings are split mid-line, so it is not segmented. ShamAY 36516 prints the whole matn with Fayṣal Āl Mubārak's (d. 1376) *al-Ghurar al-Naqiyya* as closing endnotes; the matn's tabwīb is read from it through a witness-level segmenter. Both are held `cache_only`;
- the Shamela fetcher numbers every page as volume 1, so locators into multi-volume Shamela citers give the page number but not the volume.

Not located on OpenITI: the *Masāʾil* of ʿAbd Allāh, Ṣāliḥ and Ibn Hāniʾ; Ibn Qāsim's *Ḥāshiyat al-Rawḍ*; *al-Fatāwā al-Saʿdiyya*; al-Albānī's *Silsila*s (Shamela 9442 and 12762, not registered).

## Counting citations (`reception.py`)

`python -m usul_corpus reception` (or `make reception`) reads every cached citer witness, counts its citations of each `cited` work page by page, and writes `corpus/reception/report.json`. `docs` then renders [`reception-counts.md`](reception-counts.md). Tests check that the committed report agrees with the registry.

The matching rules:

1. Text is normalised with the same function used for segmentation (`arabic.normalize`), and quotes and brackets are dropped, so «المغني», (المغني) and المغنى all match.
2. A **single-word form** counts only after a citation cue (في, صاحب, كتاب, كتابه, انظر, ينظر, راجع, optionally with و/ف before it). «قال في المغني» counts and «الله هو المغني» does not.
3. A **multi-word form** counts as written. Ambiguous short titles are listed only in cued or author-qualified forms: *al-Furūʿ* as «قال في الفروع», «صاحب الفروع» and so on, because «في الفروع» is also the ordinary phrase "in the branch rulings"; *al-Awsaṭ* as «ابن المنذر في الأوسط», because the bare «في الأوسط» is al-Ṭabarānī's *Muʿjam*.
4. **Leftmost-longest:** overlapping hits resolve to the longest at the earliest start, so each span counts once. «المستدرك على مجموع الفتاوى» is one hit for *al-Mustadrak*, not one for each work. The `not` phrases take part as hits for no work, so «الذهبي في المغني» silences *al-Mughnī*. On an identical span a named work beats a `not` phrase, so «ابن مفلح في المبدع» counts for Burhān al-Dīn although it is excluded for his grandfather.

### Author mentions

A second pass counts mentions by name from [`corpus/reception/authors.json`](../../corpus/reception/authors.json): one entry per author, keyed by the work-id prefix of that author's cited works (`ibn_qudama` for `ibn_qudama.mughni`, `ibn_qudama.kafi`, …). The rules are the same, except that a single-word form (النووي, الشوكاني) needs no cue, since a nisba is not an ordinary word. Namesakes are shadowed: «شيخ الإسلام محمد بن عبد الوهاب» is not Ibn Taymiyya, «ابن حجر الهيتمي» is not al-ʿAsqalānī, «المجد ابن تيمية» is Majd al-Dīn. Authors whose name cannot be told apart from a far more frequent namesake have no entry: Abū Dāwūd of the *Masāʾil* would be swamped by the *Sunan*.

Author mentions are an order of magnitude more frequent than titles: «قال شيخ الإسلام» is how Ibn ʿUthaymīn cites Ibn Taymiyya. They are the better measure of reliance; titles show which book.

### Fixed: exclusions were ignored before October 2026

Until the author pass was added, `build()` passed the lexicon to `matcher()` as a generator, which compiled the forms and then found the generator empty when compiling the `not` phrases. Every exclusion was silently dropped from the committed report. The difference was four hits, all the intended namesakes (al-Dhahabī's *Mughnī*, al-Rāfiʿī's *Sharḥ al-Kabīr*). `test_exclusions_apply_when_the_lexicon_is_a_one_shot_iterator` keeps it fixed.

Each count keeps its first three page locators, so a reviewer can spot-check precision.

What the counts measure, and what they don't:
- Title counts miss citations by author only; the author pass covers those, but not mentions by honorific alone («قال الشيخ», «الحافظ») or by pronoun. A low count is not evidence that a work is unused; a high count is evidence that it is used.
- Volume is skewed by genre. *al-Sharḥ al-Mumtiʿ* and *Irwāʾ* cite by title far more often than the fatāwā collections do.
- The labelled dataset ([`mentions.md`](mentions.md)) measures the rules' precision against human review and is the route past their recall limits.
- Zero rows stay in the report on purpose: they show which forms need widening or which citer is missing. They are not a reason to drop a work.
