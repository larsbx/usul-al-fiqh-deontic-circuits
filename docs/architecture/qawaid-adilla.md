# The adilla of the qawāʿid

The basis is the Qurʾān and the Sunna. `corpus/dossier/qawaid_adilla.json` records, for each qāʿida,
the texts of the foundation (`corpus/nusus/foundation.json`) it is derived from, and for each one the
*istidlāl*: a verbatim excerpt of a work that states the derivation, with who states it. No author is
the reference by his name; what the annotation records is the dalīl and the place a scholar adduces it.

- `stated`: the source names the text as the qāʿida's dalīl («والدليل على هذه القاعدة…», «ودليل هذا الأصل…»).
- `indicated`: the source adduces the text for the qāʿida's ruling or its central farʿ without calling it
  the qāʿida's dalīl; the note says how.
- `adilla: []` is a result: `searched` names every witness read. A text is never attached for its theme,
  and an example of a form (an āya quoted to show an ʿumūm form) is not its dalīl.
- A ḍaʿīf ḥadīth a source gives is recorded with al-Albānī's verdict; the ḥujja gate does not admit it.

`usul_corpus.qawaid_adilla` checks that each entry names a committed qāʿida once, that every ref is in
the foundation, and that every excerpt is verbatim (Arabic letters) in its cached witness.

## al-Saʿdī, al-Qawāʿid al-Jāmiʿa

All 57 qawāʿid with a record are annotated, from al-Saʿdī's own explanation (archive-pdf1995-tess), Ibn
ʿUthaymīn's Sharḥ al-Manẓūma (archive-manzuma-tess) and Ibn al-Qayyim's Iʿlām; Ṭarīq al-Wuṣūl,
al-Risāla al-Laṭīfa and al-Qawāʿid al-Nūrāniyya were searched too. Qawāʿid 12, 23 and 32 have no record
(problem register PR-33).

| | qawāʿid |
|---|---|
| a stated dalīl | 1, 3–7, 10, 11, 13, 15, 16, 18, 21, 22, 24, 25, 27, 28, 30, 31, 33, 36, 38, 40, 43, 46, 47, 51, 55, 57 |
| an indicated dalīl only | 2, 9, 14, 17, 29, 34, 35, 42, 50, 58 |
| none found | 8, 19, 20, 26, 37, 39, 41, 44, 45, 48, 49, 52, 53, 54, 56, 59, 60 |

Q24's stated dalīl, «من سبق إلى ما لم يسبق إليه مسلم فهو أحق به», is ḍaʿīf (al-Irwāʾ 1555), so the
qāʿida rests on no admitted naṣṣ. Left out for want of a verified verdict: the Prophet's lot among his
wives (Bukhārī 2593, Q25), «أمك ثم أمك» (Muslim 2548, Q33), and «لا يقبل الله صلاة أحدكم إذا أحدث» in the
wording al-Saʿdī gives (Q58); al-Zumar 39:18 (Q33) is unreadable in both OCR witnesses.

## Required source replay (PR #86 correction)

Every cited `istidlal.witness` is part of `source_verify.required_witnesses`, in addition to the
reconciliation and textual-foundation witnesses. Its `ref` must name that same witness and a closing-page locator. Missing
bytes, missing pins, altered bytes, invented excerpts, and wrong pages fail verification. The
annotation checker also rejects unavailable witnesses and empty normalized excerpts.

The two PDF-derived witnesses use the existing `ocr_sha256` locks. Verification requires the exact
pinned OCR text in `.cache/corpus/<witness>.txt` and never rewrites a lock. With `--fetch-source`, an
absent OCR output is recreated by the existing OCR pipeline: first verify the downloaded PDF's
original size and hash, then use the registry configuration and pinned Tesseract models, and admit
the output only if it equals the existing `ocr_sha256`. A different toolchain or extraction result
fails closed; it cannot authorize a new pin. CI installs Tesseract and Poppler for this restoration.

Receipts distinguish verification of the pinned derived text from validation of OCR interpretation.
Modern witness text and OCR intermediates remain cache-only under the existing rights policy.
