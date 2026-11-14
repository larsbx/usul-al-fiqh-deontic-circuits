# UsulTest.IDAProjection in Plain English

Source: [`formal/lean/UsulTest/IDAProjection.lean`](../../../formal/lean/UsulTest/IDAProjection.lean)

The synthetic ACT-02 repayment fixture supplies two participants and an
omission occurrence. The checks expose a hidden exception, occurrence loss,
different dependencies with the same answer, and staleness of an old exact
snapshot even when the synthetic evaluation is preserved.

## Two inference boundaries

The relabeling fixture reads an enabled flag and one Boolean feature; a second
Boolean is irrelevant noise. When enabled, the original encoder answers with
the feature and its `mapRun Bool.not` version answers with the opposite Boolean.
When disabled, both return no answer. They have the same projection and
applicability and satisfy `Reads` in both directions. Both judgments factor
through the projection, yet their applicable answers differ. Reading the same
information does not force two encoders to use the same answer labels.

The unattested-feature fixture has four `(feature, noise)` situations. Its known
list contains both noise variants of `feature = false`, with answer `true` in
each. This is a nonempty, consistent list. A candidate extension answers with
`knownValue` when the feature is false and `unseenValue` when it is true. Every
candidate factors through the feature across the entire four-point domain;
it agrees with the known list exactly when `knownValue = true`. The two
candidates with that value and opposite `unseenValue` agree with every known
case but disagree on both unseen situations. The general `unattested_free`
theorem is also instantiated directly, permitting either answer on that
unseen feature class.

All new answers are synthetic Booleans. These examples establish limits of
inference from information dependence and supplied cases. They do not select
a source interpretation or issue an admission receipt.

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
| `relabel_changes_applicable_answer` | Every enabled situation receives different optional Boolean answers. |
| `relabel_factorization` | Both judgments factor through the original projection. |
| `relabel_matrix` | All eight relabeling inputs produce the declared eight observations. |
| `unattested_known_nonempty_consistent` | The actual known list is nonempty and satisfies both the Boolean and propositional consistency checks. |
| `unattested_candidate_factorization` | Every candidate extension factors globally through the feature. |
| `unattested_candidate_agreement` | Agreement with the complete known list holds exactly when its known-feature answer is true. |
| `unattested_feature_absent` | Neither unseen situation's feature is attested by the known list. |
| `unattested_two_extensions` | Two explicit globally factoring extensions agree with all known cases and disagree on each unseen situation. |
| `unattested_free_answer` | The general `Usul.Cat.unattested_free` theorem gives a compatible extension for either unseen answer. |
| `unattested_matrix` | All sixteen extension inputs produce the declared eight observations. |
| `relabeling_boundary` | A single checked statement combines mutual reads, equal projection and applicability, different applicable answers, and both factorizations. |
| `unattested_boundary` | A single checked statement combines populated consistent data with both factoring, agreeing, and disagreeing extensions. |

The two terminal bundles preserve the complete conclusions used by the claim
register. Their fixed contract wrappers fail to compile if either registered
statement is weakened to `True`.
