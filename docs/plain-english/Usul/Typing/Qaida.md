# Usul.Typing.Qaida in Plain English

Source: [`formal/lean/Usul/Typing/Qaida.lean`](../../../../formal/lean/Usul/Typing/Qaida.lean)

Each qāʿida (legal maxim) defines a type: the list of facts its statement ranges over. Every fact starts unknown and stays so until a text settles it. A qāʿida that builds on another extends that one's type, and two maxims share a fact only when they state the same notion.

## 1. How the types are built

- **One structure per qāʿida**: named after the maxim (e.g. `Yaqin` for al-Saʿdī Q11, `Rajab95` for Ibn Rajab 95). Its docstring quotes the maxim's Arabic statement from the committed records.
- **Fields are `Option`**: each fact is `none` (unknown) by default. A text fills it with `some` value.
- **`extends`**: a maxim that builds on another inherits its fields. Q52's type `Qarain` extends Q11's type `Yaqin`.
- **Shared vs. separate fields**: Lean merges same-named fields of parent types. So a field name is reused only when two maxims mean the same thing. Look-alikes get qualified names, such as `mixedSameKind` (Ibn Rajab 22) and `actsSameKind` (al-Saʿdī Q41), or `negligent` (Q14, safekeeping) and `negligentInquiry` (Ibn Rajab 6, inquiry).
- **"Read by"**: most docstrings name the encoders that read the type, e.g. `Rajab53` is "Read by `attached_right_disposal`".

The file holds 160 structures in three groups.

## 2. The core types and their family tree (18 structures)

| Structure | Maxim | Facts it holds |
| --- | --- | --- |
| `Yaqin` | al-Saʿdī Q11: the presumption stays; certainty (yaqīn) is not removed by doubt | the aṣl and the ẓāhir (apparent), each with an epistemic grade |
| `Qarain` extends `Yaqin` | Q52: strong indicators (qarāʾin) override the presumption | adds the indicator (`amara`) |
| `ItlafHal`, `ItlafQasd` | Q13, Q36 on itlāf (destruction) | the destroyer's state of mind; the purpose of the destruction |
| `Amana` | Q14: loss in a trustee's hand is not compensable unless he transgresses or is negligent | the hand, pure trust (amāna maḥḍa), transgression, negligence |
| `ZannError` | Ibn Rajab 6: an act on a mistaken presumption stands, with two exceptions | another's right attached; negligence in inquiry |
| `MajhulHaqq` | Q20: a right-holder who cannot be known is treated as non-existent | whether the owner can be identified |
| `MajhulMadum` | Ibn Rajab 106: the unknown is treated as non-existent when despaired of or burdensome | unknown, despair, hardship |
| `Luqata`, `Istihlak` extend `MajhulMadum` | 106.f002 on the luqaṭa (lost thing found); Ibn Rajab 22 on a thing absorbed into another | year passed, ownable; consumed |
| `Badal`, `BadalWujub`, `Intiqal` | Q28: the substitute (badal) stands for the original only when the original is impossible; Ibn Rajab 16, 7 | original possible; judged at time of obligation; necessity |
| `Itizal` extends `Yaqin` | Ibn Rajab 160: abstain from the wife while a suspended divorce may have occurred | suspended, possible, absence known |
| `ShakkShart` extends `Qarain` | Ibn Rajab 68: acting while doubting a condition of validity | firm intention needed, presumption continuing |
| `Rukhsa` extends `ShakkShart` | 68.f001: a rukhṣa (dispensation) needs its permission established | needs certainty, permission established |
| `NiyyaMansiyya` extends `Yaqin` | a forgotten iḥrām intention | which component is valid on each possible rite |
| `Mubashara` extends `ItlafHal`, `ItlafQasd` | Ibn Rajab 127: liability falls on the direct act, not the cause, unless the act arises from the cause | arises from cause; transgression in the direct act |

`ShakkShart` notes that 68's ghalabat al-ẓann (preponderant belief) is not its own field. It is Q11's ẓāhir graded at least ẓann, read through `Qarain`.

## 3. The remaining encoders' qawāʿid (69 structures)

One structure per maxim read by an older takhrīj encoder:

- **Ibn al-Laḥḥām**: `Lahham43` (the bare command, read by six encoders including `amr` and the four command-schema readings), `Lahham52` (the definite singular), `Lahham61` (general wording on a specific occasion).
- **Ibn Rajab 1 to 68, 91, 93**: e.g. `Rajab1` (running water), `Rajab9` (worship done in a forbidden way), `Rajab14` (a cause from one of two men), `Rajab47` (liability in a fāsid contract), `Rajab64` (acting before learning of permission).
- **Extensions**: `Rajab14Certainty` extends `Rajab14` with each man's certainty of his own prior state. `Khalt` extends `Istihlak` for mixing. `ShakkShartFuru` extends `ShakkShart` with facts from 68's furūʿ (branch cases).
- **al-Saʿdī paired with Ibn Rajab**: `Sadi9` (custom), `Sadi25` (lot-casting, qurʿa), `Sadi30` (partners), `Sadi32` (recourse), `Sadi35` (doubled liability), `Sadi40` (partial capability), `Sadi41` (tadākhul, merging), `Sadi45`, `Sadi48`, `Sadi50` (tabaʿiyya, dependency), `Sadi55`, `Sadi59` (generality of terms).

## 4. Ibn Rajab's qawāʿid from the parallel shards (73 structures)

Types for Ibn Rajab 53 to 158 (with gaps), read by the encoders of the parallel shards (`Usul.Readings.RajabA…`). Examples:

- `Rajab95`: error over another's property. Holds `externalCause`, `basisVoid`, `rulingOverturned`, `asOwner`, `negligentQ95`.
- `Rajab97`: the absent owner. Holds `ownerKnown`, `trivial`, `despaired`.
- `Rajab98`: handover by description. Holds `described`, `ownerUnknown`, `ownerHand`.
- `Rajab110`: one entitled to one of two things. Seven fields.
- `Rajab155`, `Rajab156`: when the mahr is fully settled or halved.
- `Rajab158`: two conflicting presumptions, the reinforced one governs.

Fields that recur across maxims with different meanings carry a suffix, e.g. `harmlessQ99`, `neededQ130`, `bindingQ69`.

## In one line

Every maxim gets a record of exactly the facts it talks about, unknown until a text says otherwise; maxims that build on others extend their records, and look-alike notions are kept apart by name.
