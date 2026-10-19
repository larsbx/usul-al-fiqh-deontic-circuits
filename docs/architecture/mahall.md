# Maḥall: what each case rules on, defined by its canonical text (PR-51)

Every case rules on something. That something is its **maḥall**, of one of three kinds:

- an **item** (ʿayn), such as water, a dog or a pledged house;
- an **act** (fiʿl), such as a prayer, a sale or a vow;
- an **issue** (ḥāl), such as doubt, ignorance or compulsion.

This layer does four things:

1. It identifies the maḥall of every case in the bank, in the case's own words.
2. It classifies each maḥall by kind and places it in a label tree rooted in the bābs.
3. It defines each label by the canonical text that names it: an āya, a ḥadīth of the six books, or an ijmāʿ that al-Mughnī reports. The text is quoted verbatim from its pinned witness.
4. It proves how the resulting graph ties the texts, through the furūʿ, to the qawāʿid.

- Module: `pipeline/usul_corpus/mahall.py`.
- Data, under `corpus/mahall/`:
  - `abwab.json`: the 57 roots;
  - `labels/all.json`: the labels;
  - `furu/<shard>.json`: one entry per case;
  - `graph.json`: generated.
- Lean: `Usul.Mahall` holds the theory. `UsulTest.MahallGraph` is generated and holds the guards.
- Gate: `pipeline/tests/test_mahall.py`, and `python -m usul_corpus mahall --check` in `make generated`.

## The gate

- **Every case.** Each of the 1,216 annotated takhrīj cases from Ibn Rajab and Ibn al-Laḥḥām has exactly one primary maḥall. `term_ar` names it and is an exact substring of the case. Optionally, up to two secondary maḥalls are given (`also`).
- **One tree.** Each label has a kind and a broader label. It reaches, within 16 steps, the bāb its id names.
- **Defined, verbatim.** Each label is either anchored or `unanchored` with a reason. An anchored label carries 1–3 nuṣūṣ, each checked against its witness:
  - **Qurʾān:** letters-only, inside the cited āya of the Tanzil text (`#Qsss:aaa`).
  - **Sunnah or athar:** at least three words, somewhere in the cited collection: al-Bukhārī, Muslim, Abū Dāwūd, al-Tirmidhī, al-Nasāʾī or Ibn Mājah.
  - **Ijmāʿ:** a passage of al-Mughnī that states the agreement («أجمع», «لا خلاف», «لا نعلم … خلافا», …).
- The witnesses are those `source_verify.required_witnesses` names, so CI fetches them and a missing one fails rather than skips.

## What was found

| | |
|---|---|
| Cases | 1,216: 733 rule on an act, 378 on an item, 105 on an issue. 339 also have a secondary maḥall. |
| Labels | 541 under 57 bābs: 296 acts, 174 items, 71 issues |
| Anchored labels | **529**. By strongest text: Qurʾān 228, Sunnah 286, athar 6, ijmāʿ 9 |
| Nuṣūṣ | 832 citations, 727 distinct:<br>• Qurʾān 312<br>• al-Bukhārī 244, Abū Dāwūd 107, Muslim 66, al-Tirmidhī 41, Ibn Mājah 32, al-Nasāʾī 11<br>• al-Mughnī's ijmāʿ 19 |
| Cases whose own maḥall is anchored | 1,194 / 1,216. The other 22 fall under the 12 unanchored labels. Their bāb is still reached. |

**The 12 unanchored labels are findings, not gaps.** They are maḥalls that no canonical text names, which the jurists constructed:

- `wasaya.wasiyya_manfaa`: a bequest of usufruct;
- `ghasb.khalt`: the mixing of fungibles;
- `buyu.usul_buqul`: perennial roots;
- `jiala.inqadh_mal`: a wage for rescue, by analogy with the runaway slave;
- `talaq.talaq_mubham`: a divorce of an unspecified wife;
- `ayman.ayman_bayaa`: the oaths of allegiance;
- `usul.ijazat_riwaya`: the licence to transmit;
- `dawa.mata_bayt`: household goods disputed between spouses, which follows ʿurf;
- these rest on reports outside the six books:
  - `faraid.mawt_jamaa`, `faraid.mawt_mutawarithin`: heirs who die together or in unknown order;
  - `nikah.fasakh_ayb`: annulment for a defect;
  - `jinayat.mumsik`: the one who holds the victim.

### How the qawāʿid relate to the texts (the graph)

`Usul.Mahall` defines a qāʿida's **footprint**: the labels its furūʿ fall under, closed upwards. It defines the qāʿida's **grounds**: the nuṣūṣ that define a label in its footprint. It proves:

- `footprint_iff`: the footprint is exactly the least up-closed set holding the maḥalls of the qāʿida's furūʿ. A qāʿida reaches the texts only through its furūʿ.
- `grounded`: every naṣṣ on the path from a farʿ's maḥall up to its bāb grounds the farʿ's qāʿida.
- `bab_in_footprint`: a qāʿida's footprint holds the bāb of each of its furūʿ.
- `bridge`: a maḥall shared by furūʿ of two qawāʿid is common to both footprints.

The decision procedures `belowB`, `footprintB` and `groundsB` are proved sound, and `belowB` complete, for the exported graph. `restrict` is proved not to change a qāʿida's answers. `UsulTest.MahallGraph` then checks the concrete graph:

- every label is rooted (`rootedB 16`);
- for each of the 159 qawāʿid, the footprint and the grounds the Lean procedures compute equal the pipeline's, exactly.

The guards are evaluated, and the soundness theorems carry them to the relations.

On the data:

- **Qawāʿid cut across the bābs.** A qāʿida's footprint spans 6.1 bābs on average, at most 25. Only 4 of the 159 stay within one bāb, the shape of a ḍābiṭ rather than a qāʿida.
- **Grounds.** A qāʿida is grounded by 22 distinct nuṣūṣ on average, at least 1.
- **Shared maḥalls connect the qawāʿid.** 230 of the 539 labels in use occur under more than one qāʿida, and they bridge 2,319 pairs of qawāʿid. By `bridge`, the qawāʿid form one connected component of 153, plus 6 isolated ones. The most shared maḥalls:
  - the bequest, under 31 qawāʿid;
  - hire, 23;
  - manumission, 21;
  - waqf and deposit, 16 each;
  - the oath, pledge and loan for use, 15 each.

  This is the text-defined version of the cross-listing the reproduction study looked for (PR-50). Two qawāʿid touch when their furūʿ rule on the same thing.

## Integration

Six shards annotated about 200 cases each, under the same prompt and gate. Their 833 label declarations were merged into 541:

- 149 ids were declared by more than one shard. For these:
  - kind went by majority;
  - the broader label went by majority within the same bāb, ties going to the more specific;
  - every verified naṣṣ was kept, deduplicated.
- 24 synonyms under different ids were aliased in the furūʿ, e.g. `buyu.radd_bil_ayb` and `buyu.radd_bi_ayb` into `buyu.khiyar_ayb`, and `sadaq.mahr` into `sadaq.sadaq`.
- `shards` on each label records who declared it.

## For review

All entries are `candidate`. The shards flagged these:

- **Loose anchors**, where a naṣṣ governs the maḥall in general rather than naming it:
  - `ghasb.daman_jidar` («لا ضرر ولا ضرار»);
  - `salat.makan_maghsub` («إن دماءكم وأموالكم … حرام»);
  - `nikah.unna` (the Rifāʿa ḥadīth, not ʿUmar's one-year term);
  - `hajr.abd_madhun` (Q16:75);
  - `diyat.arsh`;
  - `buyu.ziyada_fil_bay` («زن وأرجح»);
  - `ihya.tahjir` (a reviving ḥadīth for staking a claim);
  - market pitches and fencing, via the water ḥadīth.
- **Weak ḥadīth.** The gate checks wording, not grading. Some anchors are ḥadīths their own collection marks weak, e.g. `itq.umm_walad` («أعتقها ولدها», Ibn Mājah), and al-Tirmidhī on a minor's wealth. Joining the anchors to al-Albānī's verdicts (`hadith.irwa_join`) is the next step, so that `Usul.Seam.admitted` can grade them.
- **Ijmāʿ via a tacit consensus**, e.g. the case of Tumāḍir («فكان إجماعا»).
- **Conventions that differ between shards:**
  - For the cases on what halves or forfeits the dower (q156), the cause of separation is the primary maḥall. The dower is `also`.
  - For planting on another's land (q077–q078), the usurpation label is primary, whatever the planter's contract.
  - For the unborn child (q084), the bāb label is primary and `amma.haml` is `also`.
