# UsulTest.TakhrijMirror in Plain English

Source: [`formal/lean/UsulTest/TakhrijMirror.lean`](../../../formal/lean/UsulTest/TakhrijMirror.lean)

The Python copy of every takhrīj encoder computes exactly what its Lean reading computes, on every possible input. Annotators work with the Python copy; Lean is the authority, so any drift between the two fails the build.

## 1. What is being mirrored

- **Takhrīj**: deriving the ruling of a farʿ (particular case) from a qāʿida (legal maxim).
- **Encoder**: ties one formal reading of a qāʿida to the cases it tests. It names the facts a case supplies, the Lean expression that rules on them, and a Python function that should give the same answer.
- **Mirror check**: for each encoder, the generator (`python -m usul_corpus takhrij`) tries every combination of its fact values. It evaluates the Python function and writes the Lean expression with that answer as a `#guard`.

The file has 946 guards over 202 encoders. Facts are mostly yes/no, plus small enumerations: grades of belief (wahm, shakk, ẓann, qaṭʿ), mental states, the five rulings (wājib, mandūb, mubāḥ, makrūh, ḥarām), and others. Because the check is exhaustive, agreement holds on the whole domain, not just on sample cases.

## 2. Core kernel modules

| Module | Guards | What the encoders rule on |
| --- | --- | --- |
| `Usul.Muamalat` | 22 | Liability for itlāf (destruction) with or without a right, compensation owed, loss in a trustee's vs a wrongdoer's hand, who receives, when a partner must join. |
| `Usul.Kulliyyat` | 10 | Continuity, when something counts as established, when an act discharges a duty. |
| `Usul.Sadi` | 6 | Which parts of a command are obliged when only some can be done; when to use a substitute. |
| `Usul.Dalala` | 50 | When a word form is general (ʿāmm) in a given sentence context, what a command (amr) implies by default, whether a ruling reaches beyond its occasion (sabab). |
| `Usul.CommandSchemata` | 66 | How different authorities classify command forms and usages: literal, figurative or unsettled, and the status a command yields. |

Examples:

- `itlafLiable (withRight .benefit) .forgetful == true`: destroying a thing to benefit from it is compensable, even when forgetful.
- `itlafLiable (withRight .repelHarm) .deliberate == false`: destroying it to repel its harm is not.
- `IsGeneralIn .nakira .negation false == true`: an indefinite noun under negation is general, absent a blocking indicator.
- `amrStatus none == .wajib`: a bare command, with no indicator turning it, implies obligation.
- `obligationStatus .abuBarakat .unqualifiedThreat (some .mubah) == .wajib`, while the same input under `.qadi` gives `.mubah`: the two authorities really differ.

## 3. Refinements

`Usul.Refinements` holds most single-qāʿida readings: 86 functions, 326 guards. They cover, among others:

- **Presumption and doubt**: `zahirPrevails`: the ẓāhir (outward indication) beats the aṣl (presumption) when strictly stronger, or equal with supporting indicators (32 rows).
- **Validity**: `validUnderDoubt`, `validWithBasis`, `rukhsaValid`, `conditionedSaleValid`, `naflValid`, `validDespite`.
- **Liability and recourse**: `recourseNec`, `handLiable`, `holderLiable`, `liableAfterEnding`, `takerRecourse`.
- **Contracts and ownership**: `laterContractGoverns`, `priorContractDissolves`, `leaseDissolves`, `bindsWithoutQabd`, `disposeBeforeQabdIn`.
- **Allocation and mixing**: `allocationFull` (lot, divide or to the entitled), `mixedOutcome`, `mixedHaram`, `luqata` (a found item: hold, give in charity, or the finder owns it).

Several functions have an `…In` variant that takes one more fact (for example `countsAsMet` and `countsAsMetIn`). Both are mirrored.

## 4. Readings of Ibn Rajab and others

`Usul.Readings.*` holds readings tied to specific sources: 464 guards.

- **`RajabA1` … `RajabA25`**: readings from Ibn Rajab's *Taqrīr al-Qawāʿid*, 1 to 8 functions each. The largest are `RajabA5` (44 guards, including the five-fact `errorActorLiable`), `RajabA21` (42, including `marriageProhibited` and `mahrEstablished`) and `RajabA9` (40).
- **`Concordance.attachOnCertainty`**: whether a ruling attaches to each, to neither, or judgement abstains.
- **`Maqasid.hujja`** (108 guards): whether a maṣlaḥa is a proof, on each pinned stance. **`Maqasid.taqdim`** (162 guards): which of two conflicting maqāṣid is put first, on each reading of dīn.
- **`Mubashara.damanOn`**: whether ḍamān (liability) falls on the direct actor (mubāshir), the cause (sabab), or both.

Examples:

- `Mubashara.damanOn true true == .shared`: the direct act arises from the cause and involves transgression, so liability is shared.
- `Maqasid.taqdim .kawkab (.daruri .nafs) .haji == .first`: life, a necessity, before a need.
- `RajabA1.rescission true false == .barred`: a rescission that causes harm which cannot be made good is barred.

## 5. Why it matters

Annotators label furūʿ using the Python encoders. If a Python mirror drifted from the Lean reading, those labels would quietly test the wrong rule. This suite makes every such drift a compile error. A Python test also checks that this file equals what the generator would write now, and that the 66 `CommandSchemata` guards are present.

## In one line

Every takhrīj encoder's Python mirror is checked against its Lean reading on every possible input, 946 checks in all, so annotation always tests the formal rule itself.
