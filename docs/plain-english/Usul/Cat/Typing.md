# Usul.Cat.Typing in Plain English

Source: [`formal/lean/Usul/Cat/Typing.lean`](../../../../formal/lean/Usul/Cat/Typing.lean)

The legal maxims (qawāʿid) define types, and encoders are typed over them. Each encoder's ruling factors through its type, so qiyās (analogy) between two situations is licensed by the type alone. Encoders form a thin category ordered by how much they read, and a finer encoder's type licenses a coarser encoder's analogies.

## 1. Background

- **Stack**: qawāʿid → types → categories.
- **`Situation`**: the join of all qāʿida types: every fact any maxim reads.
- **`Typed S O`** (from `Usul.Typing`): an encoder over situations. `proj` reads its local signature off a situation, if it applies. `embed` writes one back. `run` gives the answer.
- **`judge`**: apply `run` to the projected signature, if any.

## 2. Encoders and factorization

| Theorem | Plain English |
| --- | --- |
| `retract` | Embedding a local signature and reading it back loses nothing. |
| `judge_factors` | An encoder's ruling factors through its qāʿida type's projection. |
| `qiyas` | Two situations with the same local signature get the same ruling, whatever other facts they carry. |
| `judge_functor` | The ruling is a functor from the kernel of the projection to the rulings (via `Usul.Cat.Factor`). |

## 3. The category of typed encoders

- **`Reads E F`**: E reads at least as much as F. Wherever E applies, F applies, and F's signature is a function of E's.
- **`readsCat S`**: encoders over S, of any answer type, with an arrow E ⟶ F when E reads F. Thin by construction.

| Theorem | Plain English |
| --- | --- |
| `Reads.refl`, `Reads.trans` | Reading is reflexive and transitive. |
| `Reads.factors` | Where the finer encoder applies with one signature, the coarser one gives one ruling. The finer type licenses the coarser one's qiyās. |
| `Reads.applies` | If the finer encoder applies, so does the coarser. |
| `readsCat_thin` | The category is thin. |
| `applies_upSet` | "Applies to this situation" is an up-set along arrows. |
| `rajab16_reads_q28` | Ibn Rajab's maxim 16 (substitute, judged at the time of obligation) reads al-Saʿdī's Q28 (substitute). Its type extends Q28's, giving an arrow. |

## 4. Answers

| Theorem | Plain English |
| --- | --- |
| `Reads.mapRun` | Relabelling an encoder's answer reads the same signature both ways: an isomorphism in `readsCat`. |
| `judge_mapRun_factors` | A relabelled encoder still factors through its type. |

## In one line

Encoders typed by the qawāʿid factor through their types, so the type licenses analogy, and ordering encoders by what they read gives a thin category where finer types license coarser analogies.
