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

The 21 named `require_` wrappers state the obligations independently
of the fixture theorem types. They keep the nonempty known list, global
factorization, complete known-case agreement, and unseen disagreement in the
checked propositions. Their answer carrier is the existing fivefold `Hukm`.
Separate contracts retain `mubah` as the duality's fixed point, disprove
Boolean-complement behavior, and expose the information lost by the Boolean
binding projection. An output comparison alone would not establish all these
conditions.

| Contract | Required statement |
|---|---|
| `require_relabel_same_reads` | `Reads` holds in both directions for the actual original and relabeled encoders. |
| `require_relabel_same_projection` | Their projection functions are equal. |
| `require_relabel_same_applicability` | Their applicability agrees for every situation. |
| `require_relabel_changes_applicable_answer` | Their judgments differ at every enabled situation whose feature is not `mubah`. |
| `require_relabel_fixed_answer_iff` | For an enabled situation, their judgments agree exactly when the feature is `mubah`. |
| `require_relabel_factorization` | Both judgment functions factor through the same projection. |
| `require_relabel_matrix` | The eight observation columns have the declared values for every enabled/feature/noise combination. |
| `require_unattested_known_nonempty_consistent` | The known list is populated and passes both the Boolean and propositional consistency checks. |
| `require_unattested_candidate_factorization` | Every candidate extension factors globally through the feature. |
| `require_unattested_candidate_agreement` | A candidate agrees with all supplied cases exactly when its known-feature value is `wajib`. |
| `require_unattested_feature_absent` | The unseen feature class is absent from every known case. |
| `require_unattested_two_extensions` | Both explicit extensions factor and agree with all known cases while disagreeing at each unseen situation. |
| `require_unattested_free_answer` | Every unseen `Hukm` answer has a factoring extension that agrees with the known list. |
| `require_unattested_matrix` | The eight extension columns have the declared values for every candidate and situation. |
| `require_fivefold_sigma_not_boolean_complement` | `sigma mubah` is `mubah`, and its meet and join with that value do not equal the lattice bounds. |
| `require_fivefold_boolean_complements_iff` | A ruling has any lattice complement exactly when it is one of the two endpoints. |
| `require_fivefold_binding_not_injective` | `mandub` and `mubah` are distinct while their Boolean binding flags agree. |
| `require_fivefold_matrix` | The eight columns are correct for all twenty-five pairs under the actual `Hukm` operations. |
| `require_relabeling_boundary` | The combined relabeling conclusion includes mutual reads, identical projection and applicability, a concrete different answer, the `mubah` fixed-point law, and both factorizations. |
| `require_unattested_boundary` | The combined extension conclusion retains nonempty consistent data, both global factorizations, both known-case agreements, unseen disagreement, and every possible unseen `Hukm` answer. |
| `require_fivefold_boundary` | The combined algebra conclusion retains non-Boolean complement behavior, endpoint-only complement existence, and loss of information under the binding view. |

The gate requires these named wrappers in the compiled inventory. Separate
weakening controls replace each terminal fixture theorem's proposition with
`True`; its wrapper must then fail to compile. This checks that the registered
name still carries the required conclusion, in addition to auditing its axiom
dependencies.
