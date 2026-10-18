# Usul.Cat.Institution in Plain English

Source: [`formal/lean/Usul/Cat/Institution.lean`](../../../../formal/lean/Usul/Cat/Institution.lean)

The project checks claims in three tools: Lean, TLA+ and Haskell. Treating each as an institution makes precise when a check in one tool proves a claim stated in another. A translation always carries valid consequences forward. It also carries them back, so the check is a proof, when every source model arises from some target model.

## 1. Institutions

- **`Institution`** (Goguen–Burstall): a logic packaged as
  - **signatures**: vocabularies, forming a category;
  - **sentences** over each signature, translated along signature maps;
  - **models** over each signature, with a **reduct** that reads a model of a larger vocabulary in a smaller one;
  - **satisfaction**: when a model makes a sentence true.
- **Satisfaction condition** (a field): translating a sentence then checking it in a model ⟺ checking the original in the model's reduct. Truth does not depend on notation.
- **`Entails S Γ φ`**: every model satisfying all of Γ satisfies φ.

| Theorem | Plain English |
| --- | --- |
| `entails_sen` | Consequence survives a change of vocabulary. |

## 2. Comorphisms

- **`Comorphism I J`**: translates signatures and sentences from I to J, and models from J back to I. Both translations respect vocabulary changes, and satisfaction is preserved.
- **`Comorphism.comp`**: comorphisms compose.

| Theorem | Plain English |
| --- | --- |
| `entails_map` | **Borrowing forward.** Every comorphism preserves consequence. |
| `entails_of_map` | **Borrowing back.** If every I-model is the image of some J-model, a consequence checked in J holds in I. |
| `entails_iff` | Under that condition: J-consequence ⟺ I-consequence. |

Without the surjectivity condition, a pass in J only approximates the I-statement. The concrete tools are in `Usul.Cat.Carriers`.

## In one line

A check in another tool proves a claim when the translation is a comorphism whose model map reaches every model of the original logic; otherwise it only approximates it.
