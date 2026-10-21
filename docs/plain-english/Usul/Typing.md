# Usul.Typing in Plain English

Source: [`formal/lean/Usul/Typing.lean`](../../../formal/lean/Usul/Typing.lean)

All encoders of legal maxims read from one common record of facts, the `Situation`, whose fields are fixed by the maxims (qawāʿid) themselves. A fact is shared between encoders only where two maxims state the same notion. Typing an encoder this way changes none of its rulings. Cases are then routed by their facts, not by their wording.

## 1. Typed encoders

- **Encoder**: a function that reads a small record of facts (its local signature) and returns a ruling.
- **`Typed S O`**: an encoder typed over situations `S`, ruling in `O`. It has four parts:
  - `proj` reads its local record off a situation, if every fact it needs is known;
  - `embed` writes a local record into a situation;
  - `run` is the encoder's existing kernel function;
  - `proj_embed` is the law that writing then reading loses nothing.
- **`Typed.applies`**: the situation supplies every fact the encoder reads. A missing field is a "missing fact".
- **`Typed.judge`**: the encoder's ruling on a situation, when it applies.

| Theorem | Plain English |
| --- | --- |
| `judge_embed` | On a situation built from a local record, the ruling is the encoder's own ruling on that record. |
| `applies_embed` | An encoder always applies to a situation built from its own record. |
| `applies_iff_judge` | Applies ⟺ gives a ruling. |

## 2. The situation type

- **`Situation`**: the join of all the maxim types in `Usul.Typing.Qaida`, 168 of them: al-Saʿdī's, Ibn Rajab's and Ibn al-Laḥḥām's, and the two of the maqāṣid. Each field is optional until a text settles it.
- A maxim that builds on another extends its type: Q52 extends Q11.
- Same word, different notion, different field. Negligence in safekeeping (Q14, «يفرط») and negligence in inquiry (Ibn Rajab Q6, «فرط بترك البحث») are kept apart. Lean checks that a field merged through `extends` has one type.
- Two encoders that apply to one situation and disagree are material for taʿāruḍ (conflict of proofs, `Usul.Taarud`).

## 3. Encoders typed over the situation

Sixteen encoders are typed here, named as in `takhrij.ENCODERS`; the rest are in `Usul.Typing.Encoders`.

| Definition | Plain English |
| --- | --- |
| `itlaf` | Q13 with Q36: destruction is compensable unless done with right, whatever the state of mind. |
| `trustLoss` | Q14: a trustee is liable for loss only by transgression or negligence. |
| `trustVoidance` | Q14: a pure trust (amāna maḥḍa) is voided by transgression. |
| `excusedError` | Ibn Rajab Q6: an act on a mistaken belief and whether it is excused. |
| `aslZahir` | Q52 extending Q11: when the apparent (ẓāhir) prevails over the presumption (aṣl). |
| `unknownOwner` | Q20: who receives property whose owner cannot be identified. |
| `unknownAsNonexistent` | Ibn Rajab 106: the unknown treated as absent, given despair and hardship. |
| `luqata` | Found property (luqaṭa): outcome by whether the year passed and the thing is ownable. |
| `istihlak` | Ibn Rajab 22: consumption of the thing. |
| `substitute` | Q28: use the substitute only if the original is impossible. |
| `substituteAtObligation` | Ibn Rajab 16, extending Q28: judged at the time of obligation. |
| `switchToOriginal` | Ibn Rajab 7: must switch to the original once found, if the substitute was a necessity. |
| `abstentionUnderPossibleCondition` | Ibn Rajab 160: abstaining when a suspending condition may hold. |
| `doubtInCondition` | Ibn Rajab 68: validity under doubt about a condition; "prevailing" means the ẓāhir reaches ẓann. |
| `rukhsaUnderDoubt` | 68.f001: a rukhṣa (concession) under doubt. |
| `ihramSpecification` | A forgotten intention in iḥrām: valid only if valid on every rite it could be. |

## 4. What typing by maxim buys

| Theorem | Plain English |
| --- | --- |
| `original_possibility_is_shared` | Q28 types both substitute encoders: whether the original is possible is settled once and serves both. |
| `luqata_extends_majhul` | A type that extends another carries its fields: a luqaṭa situation is an Ibn Rajab 106 situation. |
| `transgression_is_shared` | Q14 types both trust encoders: one text settling "transgressed" serves both. |
| `negligence_is_qualified` | Settling negligence in safekeeping does not settle negligence in inquiry; `excusedError` still lacks a fact. |
| `itlaf_reads_two_qawaid` | `itlaf` needs both maxims' facts: the purpose alone (Q36) leaves it short (Q13's state of mind). |
| `qarain_extends_yaqin` | Q52 extends Q11: the presumption's fields are Q11's, read through Q52's type. |

## In one line

Every encoder reads the same fact record, shaped by the maxims themselves, so a classical case and a modern fatwā that describe the same facts reach the same encoders, and no ruling changes in the process.
