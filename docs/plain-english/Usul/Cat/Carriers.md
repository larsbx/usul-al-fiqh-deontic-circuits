# Usul.Cat.Carriers in Plain English

Source: [`formal/lean/Usul/Cat/Carriers.lean`](../../../../formal/lean/Usul/Cat/Carriers.lean)

Lean, TLA+ and Haskell agree on one shared fragment: finitely many yes/no state variables. On that fragment each tool is an institution, and the translations between them are comorphisms whose model maps reach every model. So a Haskell check of a compiled formula, or a TLA+ check at the initial state, proves the matching Lean statement exactly, not approximately. Invariants are handled separately: they reduce to a propositional check at every state.

## 1. Shared vocabulary

- **`finSet`**: signatures are variable counts n. A signature map renames m variables into n.
- **`Form n`**: Boolean formulas over n variables: variables, true, not, and, or, implies.
- **`Form.eval`**: truth under a valuation (an assignment of true/false to each variable).
- **`Form.rename`**: rename the variables in a formula.

| Theorem | Plain English |
| --- | --- |
| `eval_rename` | Evaluating a renamed formula = evaluating the original under the composed valuation. |
| `rename_id`, `rename_comp` | Renaming by the identity changes nothing, and two renamings compose. |

## 2. The three institutions

| Institution | Sentences | Models | Tool |
| --- | --- | --- | --- |
| `propI` | Boolean formulas | valuations | Lean state predicates |
| `execI` | any Boolean function of a valuation | valuations | Haskell / `#eval` |
| `traceI` | `now φ`, `always φ` (□φ), `step ψ w` ([ψ]_w) | finite behaviours | TLA+ under TLC's bounds |

- **`Trace`**: an initial state and a finite list of successors. TLC explores bounded prefixes.
- **`join`**, **`lift2`**: a pair of states (before and after) as one valuation, and renaming both copies at once.
- **`unchanged w`**: a step leaves the variables in w as they were (TLA+'s `UNCHANGED`).
- **`TSen`**: TLA+ sentences. `now φ` holds at the initial state. `always φ` holds at every state. `step ψ w` says every step satisfies ψ or leaves w unchanged.
- **`TSen.holds_rename`**: truth is invariant under renaming, which gives `traceI` its satisfaction condition.

## 3. The comorphisms

- **`compile : propI ⥤ execI`**: a formula goes to its evaluator. What Haskell tests is this image.
- **`initial : propI ⥤ traceI`**: a formula goes to its truth at the initial state (TLA+'s `Init`).

| Theorem | Plain English |
| --- | --- |
| `compile_onto`, `initial_onto` | Both model maps reach every valuation, so borrowing works both ways: checks in either tool are exact. |
| `always_iff` | An invariant □φ holds on a behaviour ⟺ φ holds at every state. This is how TLC checks invariants. |

An invariant is not the image of a comorphism from `propI`, since no single valuation stands for a whole behaviour. It reduces statewise instead.

## 4. Deciding the fragment

- **`cons`**, **`allVals`**: build every valuation of n variables.
- **`mem_allVals`**: the list really contains every valuation.
- **`entailsB`**: propositional consequence decided by truth tables.
- **`entailsB_iff`**: the truth-table check returns true ⟺ the consequence holds in `propI`.

## In one line

On the shared Boolean fragment, Lean, Haskell and TLA+ are institutions linked by exact comorphisms, so a test in one tool proves the statement in another, and invariants reduce to a check at each state.
