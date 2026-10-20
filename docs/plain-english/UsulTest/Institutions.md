# UsulTest.Institutions in Plain English

Source: [`formal/lean/UsulTest/Institutions.lean`](../../../formal/lean/UsulTest/Institutions.lean)

The TLA+ model of taklīf (legal accountability) and the Lean kernel speak about the same rules, and translating between them loses nothing. These M11 fixtures check that on concrete behaviours: the spec's invariants hold on the trace TLC replays, fail on two faulty traces, and survive renaming and compilation exactly.

## 1. The state and the rules

Five yes/no variables, as in `formal/tla/Taklif.tla`:

- **`baligh`** (0): has reached bulūgh (maturity).
- **`aqil`** (1): has ʿaql (sound mind).
- **`travelling`** (2): is on a journey.
- **`rukhsa`** (3): is using a rukhṣa (a concession, e.g. shortening prayer).
- **`bound`** (4): is under some duty.
- **`mukallaf`**: baligh ∧ aqil, the condition for being addressed by taklīf.

The spec (`spec`) has four sentences:

- **`init`**: the subject starts sane but not yet mature, home, and bound by nothing.
- **`onlyMukallafBound`**: always, bound → mukallaf.
- **`rukhsaNeedsSabab`**: always, rukhṣa → travelling. A concession needs its sabab (cause).
- **`bulughIrreversible`**: every step keeps baligh true once it is true.

## 2. The behaviour and two faulty traces

| Check | Plain English |
| --- | --- |
| `spec.all (·.holds behaviour)` | The generated behaviour (mature, become unable to fast, travel, take a rukhṣa, return, recover, lose ʿaql) satisfies the whole spec. |
| `!(TSen.always rukhsaNeedsSabab).holds rukhsaAtHome` | Taking a rukhṣa at home breaks the sabab rule. |
| `!(TSen.step bulughIrreversible vars).holds bulughUndone` | Becoming mature and then not mature breaks irreversibility. |
| `(spec.filter …).length == 1` (twice) | Each faulty trace breaks exactly one rule, no more. |

## 3. Stuttering

In TLA+, `[ψ]_w` means "ψ holds, or the variables w are unchanged".

| Check | Plain English |
| --- | --- |
| `[][FALSE]_vars` holds on `⟨s₀, [s₀, s₀]⟩` | A trace that never changes only stutters, so it passes. |
| `[][FALSE]_vars` fails on `behaviour` | A trace that really moves does not. |
| subscript `[0, 1]` vs `[2]` | Departing changes `travelling`. A step watching only baligh and ʿaql cannot see it; one watching travel can. |

## 4. Satisfaction conditions on fixtures

An institution is a logic with signatures, sentences and models. Here they are `propI` (formulas over valuations), `traceI` (TLA+ sentences over finite behaviours) and `execI` (executable predicates). The satisfaction condition says renaming variables in a sentence is the same as restricting the model.

- **`ι`**: embeds the two-variable subject signature (bulūgh, ʿaql) into the five-variable one.
- **`sentences₂`**: five sample sentences over the two variables.

| Check | Plain English |
| --- | --- |
| `(φ.rename ι).holds t == φ.holds (t.map ι)` | For every trace and sample sentence, renaming then checking equals restricting then checking. |
| `(mukallaf₂.rename ι).eval v == mukallaf₂.eval (v ∘ ι)` | The same on all 32 valuations of five variables. |
| `compile.α N φ v == φ.eval (compile.β N v)` | Compiling a formula to an evaluator, as Haskell tests it, changes no answer. |
| `(initial.α N φ).holds t == φ.eval (initial.β N t)` | Reading a formula at a trace's first state is TLA+'s `Init`. |

## 5. The bridge and borrowing

| Statement | Plain English |
| --- | --- |
| `propI.Sat 2 v mukallaf₂ ↔ … IsMukallaf` | The formula `mukallaf₂` is exactly the kernel's `Subject.IsMukallaf`. |
| `propI.Entails N [onlyMukallafBound, bound] mukallaf` | A binding duty proves its bearer is a mukallaf, by truth table. |
| `traceI.Entails … (initial.α N mukallaf)` | The same entailment carries over to every behaviour's initial state, because `initial` is onto. |
| `¬ propI.Entails N [.not aqil] (.not travelling)` | Losing ʿaql does not by itself end a journey. |

## In one line

The TLA+ taklīf spec, the Lean kernel and the executable checks agree on one shared fragment: invariants hold where they should, fail where they should, and translation between carriers is exact.
