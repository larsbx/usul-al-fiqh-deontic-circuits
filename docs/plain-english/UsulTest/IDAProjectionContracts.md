# UsulTest.IDAProjectionContracts in Plain English

Source: [`formal/lean/UsulTest/IDAProjectionContracts.lean`](../../../formal/lean/UsulTest/IDAProjectionContracts.lean)

These fixed Lean statements independently specify exact projection,
equivalence, append, fallback, and counterexample obligations for the gate.
The categorical contract requires a functor from the complete dependency
projection's kernel to discrete observation outcomes, with the concrete
evaluator as its exact object map. This checks the statement of
`Usul.Cat.IDAProjection.evaluation_functor`; the gate also requires that named
theorem in its compiled proof inventory.

## Fixed inference-boundary contracts

The fifteen named `require_` wrappers state the new obligations independently
of the fixture theorem types. They keep the nonempty known list, global
factorization, complete known-case agreement, and unseen disagreement in the
checked propositions. An output comparison alone would not establish those
conditions.

| Contract | Required statement |
|---|---|
| `require_relabel_same_reads` | `Reads` holds in both directions for the actual original and relabeled encoders. |
| `require_relabel_same_projection` | Their projection functions are equal. |
| `require_relabel_same_applicability` | Their applicability agrees for every situation. |
| `require_relabel_changes_applicable_answer` | Their judgments differ at every enabled situation. |
| `require_relabel_factorization` | Both judgment functions factor through the same projection. |
| `require_relabel_matrix` | The eight observation columns have the declared values for every enabled/feature/noise combination. |
| `require_unattested_known_nonempty_consistent` | The known list is populated and passes both the Boolean and propositional consistency checks. |
| `require_unattested_candidate_factorization` | Every candidate extension factors globally through the feature. |
| `require_unattested_candidate_agreement` | A candidate agrees with all supplied cases exactly when its known-feature value is true. |
| `require_unattested_feature_absent` | The unseen feature class is absent from every known case. |
| `require_unattested_two_extensions` | Both explicit extensions factor and agree with all known cases while disagreeing at each unseen situation. |
| `require_unattested_free_answer` | Either unseen Boolean answer has a factoring extension that agrees with the known list. |
| `require_unattested_matrix` | The eight extension columns have the declared values for every candidate and situation. |
| `require_relabeling_boundary` | The combined relabeling conclusion includes mutual reads, identical projection and applicability, a concrete different answer, and both factorizations. |
| `require_unattested_boundary` | The combined extension conclusion retains nonempty consistent data, both global factorizations, both known-case agreements, and unseen disagreement. |

The gate requires these named wrappers in the compiled inventory. Separate
weakening controls replace each terminal fixture theorem's proposition with
`True`; its wrapper must then fail to compile. This checks that the registered
name still carries the required conclusion, in addition to auditing its axiom
dependencies.
