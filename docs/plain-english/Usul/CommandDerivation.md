# Usul.CommandDerivation in Plain English

Source: [`formal/lean/Usul/CommandDerivation.lean`](../../../formal/lean/Usul/CommandDerivation.lean)

Every answer from the command schemata comes with a derivation recording which reported reading licensed it. The derivation rules are stated independently and proven to match the executable functions exactly. A derivation still counts only as a candidate: admitting it requires external premises, such as an admissible indication, that no flag can stand in for.

## 1. Derivations per question

Each derivation keeps its rule and premises (it lives in `Type`, so it is data, not just a yes/no fact).

| Derivation | Rules |
| --- | --- |
| `NonverbalDerivation` | al-Qāḍī's denial; the writing argument; gesture unanswered. |
| `PropheticActDerivation` | figurative report; literal report; author's inference with imitation; author unanswered without it. |
| `ObligationDerivation` | decisive text (naṣṣ) ⇒ wājib; no indication ⇒ wājib; an indication ⇒ its ruling. |
| `IntendedDerivation` | one rule per report and intended ruling, seven in all. |

For each, `sound` shows a derivation gives what the function computes, and `complete` builds a derivation for whatever the function computes.

## 2. One request type

- **`CommandRequest`**: any of the four questions with its inputs.
- **`CommandRequest.Result`**: the answer type: a usage, a ruling, or a usage paired with a ruling.
- **`CommandRequest.evaluate`**: run the matching schema.
- **`CommandDerivation`**: a derivation for any request.

| Theorem | Plain English |
| --- | --- |
| `CommandDerivation.sound` | A derivation's answer is what evaluation gives. |
| `CommandDerivation.complete` | Every evaluation has a derivation. |
| `CommandDerivation.iff_evaluation` | A derivation exists ⟺ evaluation gives that answer. |
| `CommandDerivation.deterministic` | Two derivations for the same request give the same answer. |

## 3. The admission boundary

- **`CommandPremises`**: what the caller must justify from outside: which indications are admissible, the first-command-position context, and whether imitation is established.
- **`CommandPremises.Holds`**: the premises a given request needs.
- **`AdmittedCommand`**: a derivation plus proof that its premises hold. Still only a candidate, not a fatwā.

| Theorem | Plain English |
| --- | --- |
| `admitted_iff` | Admitted ⟺ premises hold and evaluation gives that answer. |
| `no_admission_without_premises` | Missing premises ⇒ no admission, whatever the answer. |
| `no_author_admission_without_imitation` | Setting the imitation flag to true cannot replace evidence of imitation. |
| `author_literal_requires_imitation` | The author's literal verdict is derivable only with the imitation flag set. |
| `no_positive_gesture_derivation` | Nothing derives "gesture is literally a command" from the writing argument. |
| `no_karkhi_permission_classification` | The Karkhī/Rāzī report only ever leaves permission unsettled. |
| `derivation_preserves_intended_ruling` | Every derivation keeps the intended ruling. |

## In one line

Every command-schema answer has a matching derivation and vice versa, and admission needs independently justified premises that no Boolean flag can supply.
