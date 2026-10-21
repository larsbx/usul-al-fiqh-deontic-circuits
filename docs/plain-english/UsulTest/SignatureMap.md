# UsulTest.SignatureMap in Plain English

Source: [`formal/lean/UsulTest/SignatureMap.lean`](../../../formal/lean/UsulTest/SignatureMap.lean)

Every Lean name that the corpus links to a ḥadd (definition) or qāʿida (legal maxim) really exists. The file is 709 generated `#check` lines; if any linked constant is renamed or deleted, the Lean build fails.

## 1. Why the map exists

- **Signature map**: `corpus/signature_map.json` ties each Lean constant to the ḥadd it formalises, and `corpus/proposals/*.json` adds the constants that proposals cite.
- **Two sides**: the Python validator checks the record side (the ḥadd and its source). This file checks the Lean side.
- **`#check @Name`**: asks Lean to look the name up. It proves nothing about the content; it only guarantees the name resolves.
- **Why it matters**: corpus records cite Lean by name. Without this file, a refactor could silently leave records pointing at nothing.
- The file is generated (`python -m usul_corpus signature`) and must not be edited by hand.

## 2. What is checked, by area

| Namespace | Count | What the names cover |
| --- | --- | --- |
| `Usul.Refinements` | 115 | Refined readings of maxims, many with a `_conservative` theorem showing the refinement agrees with the older reading by default. |
| `Usul.Muamalat` | 107 | Transactions: consent, liability (ḍamān), trust, gharar (excessive uncertainty), burden of proof, inheritance; maxims Q10–Q56. |
| `Usul.Kulliyyat` | 58 | General maxims: worship's two foundations, custom (ʿurf), harm, utterances and intent. |
| `Usul.Qiyas` | 56 | Analogy (qiyās): the ʿilla (operative cause), its tests (ṭard, ʿaks, dawarān) and the objections that defeat it. |
| `Usul.Tanaqud` | 53 | Fifteen apparent contradictions between maxims (`t1`–`t15`), each with its clash and its reconciliation (jamʿ). |
| `Usul.Sadi` | 52 | Al-Saʿdī's maxims Q01–Q60: gates, priority, substitutes, generality. |
| `Usul.Jadal` | 41 | Disputation: objections (qawādiḥ), their kinds, the debate gate, order of sources. |
| `Usul.Dalala` | 28 | Linguistic signification: command and prohibition, specification (takhṣīṣ), implied meaning (mafhūm). |
| `Usul.CommandSchemata` | 27 | How commands are expressed and read: gesture, writing, Prophetic acts, intended rulings. |
| `Usul.Readings` | 81 | Ibn Rajab readings (`RajabA*`), `Mubashara`, `Concordance`, and the 58 names of `Maqasid`. |
| `Usul.Schema` | 22 | The eight shared schemata and the theorems that place maxims in them. |
| `Usul.QiyasLimits` | 21 | Where qiyās is not admitted, and Ḥanbalī vs Ḥanafī scope. |
| `Usul.Furuq` | 16 | Distinctions (furūq) between look-alike cases. |
| `Usul.Hukm` | 15 | The five rulings and their structure. |
| Others | 75 | `Qawaid`, `Process`, `Grade`, `DalilKind`, `Seam`, `Resolution`, `Wad`, `Tahara`, `Validity`, `Reconcile`, `Judgement`, core names in `Usul`, and two `Hadith.Verdict` names. |

## 3. Representative checks

| Check | Plain English |
| --- | --- |
| `Usul.Hukm.wajib` … `Usul.Hukm.mubah` | The five rulings exist: obligatory, recommended, forbidden, disliked, permitted. |
| `Usul.Judgement.wadi_without_taklif` | A declaratory (waḍʿī) judgement about someone not under duty (taklīf) is well-typed once it names a dalīl (evidence). |
| `Usul.Sadi.q04_no_wajib_with_inability` | No obligation without the ability to perform it. |
| `Usul.Qawaid.yaqin_la_yazul_bish_shakk` | Certainty is not removed by doubt. |
| `Usul.Qiyas.qiyas_sound` | Analogy that passes its gate gives the right ruling. |
| `Usul.Tanaqud.t1_clash`, `Usul.Tanaqud.t1_jam` | The first apparent contradiction, and its reconciliation. |
| `Usul.resolve_jam_first` | In a conflict of evidence, an available reconciliation (jamʿ) is what resolution returns. |
| `Usul.Readings.Mubashara.q127_three_divisions` | Ibn Rajab's three divisions of liability (direct actor, cause, shared) cover every case exactly once. |
| `Usul.Readings.Maqasid.dispute_locus` | The stances on istiṣlāḥ disagree only on an unattested necessity. |
| `Hadith.Verdict.sahih` | The ḥadīth module's "sound" (ṣaḥīḥ) verdict exists too. |

## In one line

Each of 709 Lean names cited by the corpus is looked up at build time, so no record can point at a definition that no longer exists.
