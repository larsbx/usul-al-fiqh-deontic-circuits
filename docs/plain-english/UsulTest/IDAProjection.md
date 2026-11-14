# UsulTest.IDAProjection in Plain English

Source: [`formal/lean/UsulTest/IDAProjection.lean`](../../../formal/lean/UsulTest/IDAProjection.lean)

The synthetic ACT-02 repayment fixture supplies two participants and an
omission occurrence. The checks expose a hidden exception, occurrence loss,
different dependencies with the same answer, and staleness of an old exact
snapshot even when the synthetic evaluation is preserved.

## Fivefold answers in the inference controls

The answer type is the existing `Hukm`: `haram`, `makruh`, `mubah`, `mandub`, and
`wajib`. Boolean guards and theorem checks are separate from these five ruling
values. The [Hukm companion](../Usul/Hukm.md) explains their definitions, and
the [IDA companion](../Usul/IDA.md) explains the lattice and partial-answer types.

The relabeling fixture reads an enabled flag and one `Hukm` feature; a Boolean
coordinate is irrelevant noise. When enabled, the original encoder answers
with the feature and its `mapRun sigma` version answers with the existing
duality: `haram`/`wajib` and `makruh`/`mandub` exchange places, while `mubah`
stays fixed. When disabled, both return no answer. They have the same
projection and applicability and satisfy `Reads` in both directions. Both
judgments factor through the projection, yet their applicable answers differ
exactly when the feature is not `mubah`. An applicable `mubah` answer remains
distinct from absence.

The unattested-feature fixture has four `(feature, noise)` situations. Its known
list contains both noise variants of `feature = false`, with answer `wajib` in
each. This is a nonempty, consistent list. A candidate extension answers with
`knownValue` when the feature is false and `unseenValue` when it is true. Every
candidate factors through the feature across the entire four-point domain.
Both candidate parameters range over `Hukm`, giving 25 functions; exactly the
five with `knownValue = wajib` agree with the known list. The two explicit
extensions using `mubah` and `mandub` for the unseen value agree with every
known case but disagree on both unseen situations. The general
`unattested_free` theorem is also instantiated directly for an arbitrary
`answer : Hukm`, so each of the five values has a compatible mathematical
extension.

## The duality is not Boolean complement

The algebra control uses actual `IDA.meet`, `IDA.join`, and `IDA.sigma` on the
repository's chain `haram < makruh < mubah < mandub < wajib`. These operations
form a bounded distributive De Morgan lattice. However, `sigma mubah = mubah`,
so both its meet and join with its dual equal `mubah`, rather than the two
lattice bounds. More generally, only `haram` and `wajib` have any lattice
complement in this chain. The matrix covers every pair of the five values.

The Boolean `Hukm.binding` view also loses information: `mandub` and `mubah`
have equal binding flags but are different rulings. It cannot replace the
fivefold answer. The synthetic assignments in this fixture establish limits
of information dependence, supplied examples, and algebraic relabeling. They
do not choose a source interpretation, establish an omission opportunity, or
issue an admission receipt.

## Named theorems

| Theorem | What it checks |
|---|---|
| `hidden_exception` | Appending a matching positive exception preserves the prior support observations and changes the result. |
| `core_loses_relevant_reports` | The report evaluator does not factor through the structured core alone. |
| `kind_loses_occurrence` | Equal kinds can have distinct occurrence-bearing targets and different scope outcomes. |
| `kind_does_not_factor` | The evaluator does not factor through kind alone. |
| `equivalent_receipt_can_be_stale` | Scoped equivalence can coexist with rejection of an old exact snapshot. |
| `equal_answers_do_not_imply_equivalence` | Equal observation outcomes need not have equal dependencies. |
| `explicit_negative_only` | Fallback requires an explicit negative exception report and the enabled fallback rule. |
| `relabel_same_reads` | The actual `Reads.mapRun` construction supplies `Reads` in both directions. |
| `relabel_same_projection` | The original and relabeled projection functions are equal. |
| `relabel_same_applicability` | Applicability is equal for every relabeling situation. |
| `relabel_changes_applicable_answer` | An enabled situation with a non-`mubah` feature receives different optional `Hukm` answers. |
| `relabel_fixed_answer_iff` | At an enabled situation, the two answers are equal exactly when the feature is `mubah`. |
| `relabel_factorization` | Both judgments factor through the original projection. |
| `relabel_matrix` | All twenty relabeling inputs produce the declared eight observations. |
| `unattested_known_nonempty_consistent` | The actual known list is nonempty and satisfies both the Boolean and propositional consistency checks. |
| `unattested_candidate_factorization` | Every candidate extension factors globally through the feature. |
| `unattested_candidate_agreement` | Agreement with the complete known list holds exactly when its known-feature answer is `wajib`. |
| `unattested_feature_absent` | Neither unseen situation's feature is attested by the known list. |
| `unattested_two_extensions` | Two explicit globally factoring extensions agree with all known cases and disagree on each unseen situation. |
| `unattested_free_answer` | The general `Usul.Cat.unattested_free` theorem gives a compatible extension for every unseen `Hukm` answer. |
| `unattested_matrix` | All one hundred extension inputs produce the declared eight observations. |
| `fivefold_sigma_not_boolean_complement` | The fixed point `mubah` violates both Boolean-complement equations with its `sigma` image. |
| `fivefold_boolean_complements_iff` | A ruling has a lattice complement exactly when it is `haram` or `wajib`. |
| `fivefold_binding_not_injective` | Distinct `mandub` and `mubah` values have the same Boolean binding flag. |
| `fivefold_matrix` | All twenty-five ruling pairs have the declared meet, join, dual, fixed-point, and complement observations. |
| `relabeling_boundary` | A single checked statement combines mutual reads, equal projection and applicability, a changed answer, the `mubah` fixed point, and both factorizations. |
| `unattested_boundary` | A single checked statement combines populated consistent data, two factoring and agreeing extensions that disagree unseen, and freedom of every unseen `Hukm` answer. |
| `fivefold_boundary` | A single checked statement retains the failure of Boolean complement, endpoint-only complements, and information lost by the binding view. |

The three terminal bundles preserve the complete conclusions used by the claim
register. Their fixed contract wrappers must fail to compile if any registered
statement is weakened to `True`.
