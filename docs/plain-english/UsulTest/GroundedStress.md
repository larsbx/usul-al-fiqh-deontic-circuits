# UsulTest.GroundedStress in Plain English

Source: [`formal/lean/UsulTest/GroundedStress.lean`](../../../formal/lean/UsulTest/GroundedStress.lean)

The executable grounded extension in Lean gives the same answers as the Python reference and the Haskell oracle on 10,000 pseudo-random argument frameworks. This is the M5 differential exit test: three independent implementations must agree on one fingerprint.

## 1. The setup

- **Argument framework (AF)**: arguments numbered 0 to n−1 and a list of attacks (a, b), "a attacks b". In fiqh terms, competing proofs or riwāyāt (reports) and which undermines which.
- **Grounded extension (`Usul.Grounded.grounded`)**: the arguments that survive with certainty. These are the unattacked ones, plus whatever they defend, repeated until nothing changes.
- **`lcg`**: a fixed pseudo-random number generator (Knuth's MMIX constants). All three implementations use it, so all draw the same frameworks.
- **`afs seed count nMax num den`**: draws `count` frameworks, each with 1 to `nMax` arguments. Each possible attack is included with probability `num/den`.

## 2. The fingerprint

- **`mask`**: encodes a grounded set as one number, one bit per member.
- **`digest`**: folds every framework's result into a triple: a rolling hash of all masks, the number of non-empty extensions, and the total number of members.

| Check | Plain English |
| --- | --- |
| `digest (afs 1421 10000 7 1 4) == (2254257084300117683, 7428, 12783)` | Seed 1421, 10,000 frameworks of up to 7 arguments, each attack present with probability ¼. 7,428 extensions are non-empty, with 12,783 members in all. The hash matches the other two implementations. |

## In one line

On ten thousand random frameworks, Lean's grounded semantics reproduces exactly the fingerprint that Python and Haskell compute.
