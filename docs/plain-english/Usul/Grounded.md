# Usul.Grounded in Plain English

Source: [`formal/lean/Usul/Grounded.lean`](../../../formal/lean/Usul/Grounded.lean)

The grounded extension of a finite argument graph can be computed by a short program, and each step of that program provably matches the defence operator of the abstract theory in `Usul.Dung`. This is the bridge that lets executable tests stand in for proofs.

## 1. The finite setting

- **Arguments**: the numbers 0 to n−1.
- **`att`**: a list of pairs (b, a), read "b attacks a".
- **`S`**: a list of currently accepted arguments.

## 2. The program

- **`defended att S a`**: true when every attacker of `a` is itself attacked by some member of `S`.
- **`step n att S`**: all arguments below n that `S` defends. One round of the defence operator.
- **`grounded n att`**: start from the empty set and apply `step` n + 1 times. That many rounds suffice, since the set grows until it stops changing.

## 3. The bridge theorems

| Theorem | Plain English |
| --- | --- |
| `defended_iff` | The Boolean check `defended` returns true ⟺ the abstract `Dung.Defends` holds for the same graph and set. |
| `mem_step_iff` | a is in one `step` ⟺ a < n and a is in the abstract characteristic function `Dung.F` applied to S. |

## In one line

A few lines of list code compute the grounded extension, and the bridge lemmas prove each round of it is exactly the abstract defence operator, so running it is trustworthy.
