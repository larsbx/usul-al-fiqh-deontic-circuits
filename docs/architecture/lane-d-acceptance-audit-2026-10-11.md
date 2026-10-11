# Lane D: contradiction evidence acceptance audit

Status: **candidate**. Reviewed from PR #62 head
`0d03c6a1a46beafbcc221688bc40d400f7deb2c1` on 2026-10-11.
This review checks source context and the encoded contradiction; it is not
independent scholarly acceptance or a fatwā.

## Validation contract

A failed `side_check` must preserve `from_matches: true`, have a current false
match, and belong to a genuine ikhtilāf case entered in the ledger. It selects
exact evidence indices, not merely pages: one page can report both sides.
Each selected item must have later `tashih` or `jazm`, support a listed ruling
different from `expected`, and carry the case's unchanged facts and an explicit
applicability rationale. The selected evidence must have a unique prevailing
ruling, and the **full** graded ledger must confirm that ruling by tarjīḥ.
Agreeing evidence, weak grades, ties, invalid indices and foreign facts fail.

Fact binding detects stale or differently scoped witnesses. It does not
mechanically prove the Arabic passage's applicability: the rationale remains a
review obligation. Lean verifies the reconciliation of the encoded positions
and grades, not source interpretation. Original facts, expected rulings,
position inventories and source notes are retained. Receipt hashes for earlier
contributions remain pinned; the tranche-3 revision records the extended audit.

## Independent review of the six discrepancies

Identifiers below abbreviate `ibn_rajab.taqrir_qawaid.openiti_rajab_shamela21730`.

| Case | Original side | Later evidence and conclusion | Scope retained for review |
|---|---|---|---|
| q001.f000 | perJirya | Inṣāf v01:p057 calls whole-body accounting the madhhab; Kashshāf v01:p039 and Sharḥ Muntahā v01:p021 expressly adopt it. | Inṣāf also reports per-jirya preference on the same page. Keep that opposing taṣḥīḥ in the full ledger; select only the exact contradictory items. |
| q002.f002 | detached | Inṣāf v01:p255 and Kashshāf v01:p154 require washing hair, including hanging hair, in ghusl. | The case note specifies janāba. Encoder labels attached/detached encode obligation here; this is not a claim about physically cut hair or minor ḥadath. |
| q022.f007 | suspend when lawful_many=false | Taṣḥīḥ al-Furūʿ v04:p396, masʾala 3, rejects a numerical threshold and calls extraction the correct madhhab. | Kashshāf v04:p094 distinguishes a known owner’s permission from charity for an unknown owner. Owner-knownness is missing from the facts; retain this passage as supplemental evidence, not an unconditional takeOut witness. |
| q140.f001 | 2 for all non-ḥirz theft | Inṣāf v10:p277 and Kashshāf v06:p140 prescribe single compensation outside the fruit/palm/livestock exceptions. | This refutes the source note’s universal doubling attribution. `lapsed` alone cannot decide an individual theft. Sharḥ Muntahā v03:p375 affirms doubling within the exceptions and is supplemental, not support for position 1. |
| q160.f006 | divide | Iqnāʿ v02:p073 and Kashshāf v03:p179 prohibit selling either confused slave before lots. | Preserve al-Qāḍī’s preferred joint-sale suggestion as the original annotation; the later adopted side is lot. |
| q160.f012 | lot | Inṣāf v07:p231 and Muntahā v03:p461 invalidate the unqualified shared-name bequest. | Sharḥ Muntahā v02:p471 and Kashshāf v04:p358 distinguish a qarīna indicating an intended beneficiary. The facts lack that distinction; this candidate concerns the unqualified reading and does not reject conditional validity/lot. |

All six retain candidate status and resolve against the original reading under
these scoped interpretations. The original 90 agreements and four unlocated
treatments are inherited from the contribution, not independently re-reviewed
in this six-case audit. The pre-existing q001.f002 muʿtamad disagreement and
q075.f008 factual question remain open; no annotation is silently rewritten.

## Provenance and regenerated outputs

The cached Inṣāf, Kashshāf, Sharḥ Muntahā, Iqnāʿ, Furūʿ and Muntahā witnesses
were SHA-256 checked against `corpus/lock.json`. Verbatim evidence checks replay
the excerpts against their registered page locators. The two excluded items
remain verbatim in `corpus/review/lane_d/qualified_evidence.json`, with reasons.

There are 162 ledger entries and **414 active evidence items** (plus the two
qualified supplemental items). Resolution remains 19 jamʿ, 134 tarjīḥ and nine
tawaqquf; 73 entries remain against their reading. Generated reports now expose
the evidence count and the six side-check identifiers. Source scope limits
remain visible even though the finite kernel outcomes are unchanged.
