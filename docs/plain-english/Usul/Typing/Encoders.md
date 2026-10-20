# Usul.Typing.Encoders in Plain English

Source: [`formal/lean/Usul/Typing/Encoders.lean`](../../../../formal/lean/Usul/Typing/Encoders.lean)

Every remaining takhrīj encoder (a rule that derives a ruling from a case's facts) now reads its facts from one shared `Situation`, through the type its qāʿida (legal maxim) defines. Each typed encoder runs the encoder's existing kernel function, so typing changes no ruling.

## 1. The shape of a typed encoder

Each of the file's 209 definitions is a `Typed Situation O` (defined in `Usul.Typing`), ruling in some answer type `O`. It has five parts:

- **`Local`**: the encoder's own facts, e.g. `Bool × Bool`.
- **`proj`**: reads those facts off a situation. It succeeds only if every fact is known.
- **`embed`**: writes a set of local facts into an otherwise empty situation.
- **`run`**: the encoder's existing function in the kernel (`Usul.Refinements`, `Usul.Dalala`, `Usul.Muamalat`, `Usul.Kulliyyat`, `Usul.CommandSchemata` or a `Usul.Readings` module).
- **`proj_embed`**: writing facts in and reading them back loses nothing. Each encoder proves it by `rfl`.

Each docstring names the encoder as in `takhrij.ENCODERS` and the qāʿida type it reads, e.g. "`advance_after_cause` reads `Qaida.Rajab4`". A typical one: `advanceAfterCause` reads the field `causePresent` and runs `Usul.Refinements.advanceAllowed`.

Most encoders answer yes/no (`Bool`). Others return richer values: a ḥukm (`amr`, `commandObligationStatus`), a naming verdict (`CommandUsage`), a share of liability (`concurrentCauses`), an allocation (`lots`), or a count (`doubled`).

## 2. The remaining encoders (89 definitions)

These cover the older encoders, grouped by the maxims they read:

- **Ibn al-Laḥḥām 43, the bare command (amr)**: `amr`, `amrMixed` and four command-schema readings (`commandIntendedUsage`, `commandNonverbalUsage`, `commandObligationStatus`, `commandPropheticActUsage`).
- **Ibn al-Laḥḥām 52, 61**: `hamlAlaAdna`; `umumLafz` (general wording on a specific occasion).
- **Ibn Rajab 1 to 68, 91, 93**: e.g. `runningWater`, `hairDetached`, `prohibitedWorship`, `naflBeforeFard`, `causeFromOneOfTwo`, `khaltAsShirka`, `makeupAfterFailure`, `defectiveCompensation`.
- **al-Saʿdī's maxims paired with Ibn Rajab's**: e.g. `aymanByUrf` (custom, ʿurf), `lots` (lot-casting, qurʿa), `partners`, `recourse`, `doubled`, `partialCapability`, `tadakhul` (merging of acts), `continuity`, `tabaa` (dependency), `generality`.
- **`mubasharaTasabbub`**: reads Ibn Rajab 127's type, which extends itlāf's (destruction), and rules on liability between the direct act and the cause.

## 3. Encoders of the parallel shards (96 definitions)

One or more encoders per Ibn Rajab maxim from 53 to 158, each running a function from a `Usul.Readings.RajabA…` module. Representative examples:

| Encoder | Reads | Question |
| --- | --- | --- |
| `attachedRightDisposal` | `Rajab53` | Does a disposal of a thing with a right attached stand? |
| `errorActorLiable` | `Rajab95` | Is one who erred over another's property liable? |
| `disposeWithoutJudge` | `Rajab97` | May the holder dispose of an absent owner's property without the judge? |
| `refusalCompelledToChoose` and five siblings | `Rajab110` | What follows when one entitled to one of two things refuses both? |
| `vagueOneBarsAll` and three siblings | `Rajab109` | How does a ban on one unidentified item affect the rest? |
| `mahrFullyEstablished`, `mahrHalvedBySeparation` | `Rajab155`, `Rajab156` | When is the mahr settled in full, and when halved? |
| `twoUsulReinforcedGoverns` | `Rajab158` | Of two conflicting presumptions, does the reinforced one govern? |

The most-used types are `Rajab110` and `Lahham43` (six encoders each), then `Rajab109` and `Rajab105` (four each).

## 4. Integration: reconciling Ibn Rajab 14

- **`causeOnCertainty`**: reads `Rajab14Certainty`, which extends Ibn Rajab 14's type with whether each man is certain of his own prior state. It runs `Usul.Readings.Concordance.attachOnCertainty`. This is the jamʿ (reconciliation) of 14's two readings.

## 5. The maqāṣid

- **`istislah`**: reads `Istislah`. It runs `Usul.Readings.Maqasid.hujja`: is the interest a proof, on the pinned stance?
- **`maqasidTarjih`**: reads `MaqasidTarjih`. It runs `Usul.Readings.Maqasid.taqdim`: which of two conflicting interests is put first, on the pinned reading?

## In one line

All 209 remaining encoders are wired to the shared situation through their maxim's type, each with a proof that nothing is lost, and each still computing exactly the ruling it did before.
