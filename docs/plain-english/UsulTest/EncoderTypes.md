# UsulTest.EncoderTypes in Plain English

Source: [`formal/lean/UsulTest/EncoderTypes.lean`](../../../formal/lean/UsulTest/EncoderTypes.lean)

Each judgement encoder returns an answer of the type the question it claims to answer requires. If an encoder declared to answer "is this valid?" returned a ḥukm instead, the build would fail.

## 1. How the file works

- **Generated**: written by `python -m usul_corpus judgement` from `corpus/types/encoders.json`. It is not edited by hand.
- **One check per encoder**: 120 `example`s. Each states that a typed encoder over `Situation` has the answer type of its declared question, with a comment naming the encoder and the question.
- **Adapters**: an encoder that returns yes/no for a validity question is wrapped with `mapRun Usul.Validity.ofEffects`, which turns "effects follow" into ṣaḥīḥ (valid) and "they do not" into fāsid (invalid). A "(negated)" question flips the yes/no first.

## 2. The questions

A question is either taklīfī (the act's fivefold status) or waḍʿī (a posited sign: sabab, sharṭ, māniʿ or validity). Yes/no questions about the taklīfī status ask whether the act is obligatory or permitted.

| Question | Answer type | Encoders |
| --- | --- | --- |
| `taklifi` | a ḥukm | 3, e.g. `amr`, `amrMixed`, `commandObligationStatus` |
| `wadi .sabab` (cause, e.g. of liability) | yes/no | 47, e.g. `itlaf`, `trustLoss`, `recourse`, `mahrFullyEstablished` |
| `wadi .validity` | ṣaḥīḥ / fāsid | 34, e.g. `naflBeforeFard`, `prohibitedWorship`, `taliqAlBay` |
| `wadi .validity` (negated) | ṣaḥīḥ / fāsid | 3: `cutSaleLeftToRipen`, `simultaneousCombinationVoids`, `trustVoidance` |
| `wadi .mani` (impediment) | yes/no | 7, e.g. `rulingWithBar`, `vagueOneBarsAll` |
| `wadi .shart` (condition) | yes/no | 5, e.g. `knowledge`, `unknownCondition`, `worshipRuledFromStart` |
| aspect: obligatory | yes/no | 10, e.g. `partialCapability`, `partners`, `switchToOriginal` |
| aspect: permitted | yes/no | 10, e.g. `advanceAfterCause`, `combiningForms`, `eatingWithoutPermission` |
| aspect: permitted (negated) | yes/no | 1: `superveningBarExtendsToPreliminaries` |

## 3. Why it matters

Each encoder's ruling is routed into a judgement about a question. These checks make sure the encoder and the question agree on what kind of answer comes back. A liability encoder answers a sabab question; a contract encoder answers a validity question. A mismatch between corpus metadata and Lean is caught at build time.

## In one line

All 120 judgement encoders are checked, at build time, to answer the kind of question they are declared to answer.
