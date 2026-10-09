# Lean semantic contracts

The earlier M5 command contribution supplied executable classifications and contrast
guards. The grounded runner had a one-step bridge to Dung semantics. Neither amounted
to the full corresponding metatheory. The modules below add general contracts while
preserving every corpus annotation, receipt, review question and generated report.

## The actual grounded runner

`Usul.FiniteGrounded` proves correctness of the existing `Usul.Grounded.grounded`
implementation, rather than replacing it with a second algorithm.

| Contract | Lean statement | Scope |
|---|---|---|
| Runner equals recursive iteration | `grounded_eq_iterate` | All edge lists and vertex counts |
| Iteration increases and is bounded | `iterate_increasing`, `iterate_bounded` | Lists stay in canonical vertex order and have length at most `n` |
| Finite convergence | `stable_or_growing`, `iterate_stable`, `grounded_fixed` | Before stability each step increases length; by `n` steps the chain is stable |
| Full semantic bridge | `finite_step_iff`, `iterate_iff_approx` | Every step agrees with `Dung.F` and every iterate with `Dung.approx` on `Fin n`, given well-formed endpoints |
| Complete and conflict-free | `grounded_complete`, `grounded_conflictFree` | Every well-formed finite framework, including cycles, duplicate edges and the empty framework |
| Least and unique | `grounded_least`, `grounded_exists_unique` | The returned extension lies in every complete extension; the least complete extension exists and is unique |
| Checked input boundary | `checkedGrounded_some_iff`, `checkedGrounded_complete`, `checkedGrounded_least` | A successful checked run certifies well-formed edges and the semantic result |

The proof uses sublist monotonicity and a finite growth bound. It does not infer a
universal theorem from the 47 existing differential fixtures. `Fin n` is the semantic
carrier: using all natural numbers would incorrectly treat out-of-range vertices as
unattacked arguments. The bridge's well-formedness hypothesis checks both endpoints.
The new `checkedGrounded` entry point rejects malformed edges rather than discarding
an attacker or a target. The older raw runner remains available for compatibility;
its fixed-point law holds for the restricted operator, but its Dung correctness
requires well-formedness.

## Candidate command derivations

`Usul.CommandDerivation` provides four independently stated inductive rule systems
in `Type`: `NonverbalDerivation`, `PropheticActDerivation`, `ObligationDerivation` and
`IntendedDerivation`. A trace retains its rule constructor and premises. Each system
has a `sound` theorem and a constructive `complete` function linking it to its existing
M5 evaluator. The `unsettled` constructors record an unanswered branch; they do not
derive a positive literal or figurative classification.

`CommandRequest` combines the four request families with a dependent result type.
Nonverbal and prophetic-act naming return `CommandUsage`; obligation returns `Hukm`;
intended use returns `IntendedCommand`. These results cannot be silently interchanged.
`CommandDerivation.iff_evaluation` proves that a trace exists exactly for the evaluator's
result. `CommandDerivation.deterministic` proves uniqueness after fixing the entire
request, including the reading. It does not identify conflicting readings.

The admission boundary adds external premises through `CommandPremises.Holds`:

- Obligation requires the first-command-position context and evidence of admissibility
  for every supplied qarīna.
- Intended use requires the first-command-position context; its intended ruling is
  supplied and preserved by `derivation_preserves_intended_ruling`.
- The author's conditional prophetic-act inference carries evidence that the imitation
  input is true. `author_literal_requires_imitation` excludes the unsupported branch.
- `no_positive_gesture_derivation` and `no_karkhi_permission_classification` preserve
  the source's unanswered branches.

`admitted_iff` characterizes a candidate admitted trace as both valid premises and the
correct evaluation. `no_admission_without_premises` prevents evaluation from replacing
missing context or admissibility evidence. Those predicates are external parameters;
the module does not decide whether real-world evidence establishes them.

All readings and interpretation records remain candidates. These derivations are
conditional facts about the supplied formal reading, not accepted fatwās. The four M5
questions stay open, and the six original gaps retain their complete governed records.

## Remaining proof debt

This contribution strengthens two bounded parts of the Lean implementation. It does
not complete the roadmap. In particular:

- The finite grounded theorem does not prove existence on arbitrary infinite frameworks
  or that every admissible extension extends to a preferred extension.
- The M5 trace calculus covers the four command capabilities, not the complete structured
  argumentation calculus over all adilla. General attacks on subderivations and propagation
  of defeat remain to be integrated.
- Command-context and qarīna admissibility are supplied premises. They need their own
  governed source-backed formalizations before a live case can be revisited.
- `Taarud.resolve` orders already-supplied reconciliation, chronology and preference
  results. It does not construct those results or their evidence.
- The dialogue-game/grounded correspondence and the broader cross-carrier metatheory
  remain roadmap work.

`UsulTest.KernelContracts` exercises empty frameworks, cycles, repeated edges, a
multi-step defense chain, malformed endpoints and missing command premises. Existing
Python/Lean mirrors still check the unchanged evaluators against the corpus. Run
`make lean test validate generated` from the repository root.
