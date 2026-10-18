# Usul.Typing.Answers in Plain English

Source: [`formal/lean/Usul/Typing/Answers.lean`](../../../../formal/lean/Usul/Typing/Answers.lean)

An encoder's output can be relabelled into the answer type of a legal question without changing what it reads or when it applies. This lets each judgement encoder be typed as answering a specific `Question`.

## 1. Relabelling an encoder

- **Typed encoder**: reads a `Situation` (the facts of a case) and returns a ruling (from `Usul.Typing`).
- **Question**: what a ruling answers (from `Usul.Judgement`).
- **`mapRun`**: the same encoder with its output passed through a function `f`. Examples: reading a yes/no as a validity verdict (`Validity.ofEffects`), or flipping a yes/no whose "yes" means the question's "no".

| Theorem | Plain English |
| --- | --- |
| `judge_mapRun` | The relabelled encoder's ruling is the original ruling, relabelled. |
| `applies_mapRun` | Relabelling never changes which situations the encoder applies to. |

The generated test file `UsulTest/EncoderTypes.lean` uses `mapRun` to type each judgement encoder as answering its question.

## In one line

Relabelling an encoder's output changes only the words of its answer, never what it reads or when it applies.
