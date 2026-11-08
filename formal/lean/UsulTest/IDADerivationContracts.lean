import UsulTest.IDADerivation

/-!
# Fixed derivation contracts

The propositions here are explicit independently reviewable requirements.
They do not infer their expected types from the implementation declarations.
Changing an implementation theorem to a weaker proposition must fail this file.
-/

namespace UsulTest.IDADerivationContracts

open Usul Usul.IDA Usul.IDA.Derivation

theorem require_Usul_IDA_Derivation_authorized_iff :
    ∀ (env : Environment) (p : Premise) (r : Judgment.Receipt),
      authorize env p = .ok r ↔ Authority env p r := authorized_iff

theorem require_Usul_IDA_Derivation_source_accepted_iff :
    ∀ (env : Environment) (p : Premise),
      (evaluateSource env p).Accepted ↔ AdmissibleLeaf env p := source_accepted_iff

theorem require_Usul_IDA_Derivation_both_accepted_inputs :
    ∀ {l r : Evaluation}, (requireBoth l r).Accepted →
      l.Accepted ∧ r.Accepted ∧ Homogeneous (l.provenance ++ r.provenance) :=
  @both_accepted_inputs

theorem require_Usul_IDA_Derivation_provenance_exact :
    ∀ (env : Environment) (tree : Tree),
      (evaluate env tree).provenance = tree.leaves := provenance_exact

theorem require_Usul_IDA_Derivation_accepted_leaf_authority :
    ∀ {env : Environment} {tree : Tree}, (evaluate env tree).Accepted →
      ∀ (p : Premise), p ∈ tree.leaves →
      ∃ r, Judgment.validate env.registry p.request = .accepted r ∧
        env.implementationRevision ≠ "" ∧ SourceRule p ∧
        p.request.record.provenance.source ∈ env.authenticatedSources ∧
        matchingVersions env p = [expectedVersion p] ∧
        matchingEvidence env p = [⟨p, .supported⟩] ∧
        ∃ a, r.record.payload = .known a := @accepted_leaf_authority

theorem require_Usul_IDA_Derivation_accepted_leaf_admitted :
    ∀ {env : Environment} {tree : Tree}, (evaluate env tree).Accepted →
      ∀ (p : Premise), p ∈ tree.leaves →
      ∃ entry, Judgment.matchingEntries env.registry p.request.entryId = [entry] ∧
        entry.status = .admitted ∧ entry.record = p.request.record := @accepted_leaf_admitted

theorem require_Usul_IDA_Derivation_accepted_homogeneous :
    ∀ {env : Environment} {tree : Tree}, (evaluate env tree).Accepted →
      Homogeneous tree.leaves := @accepted_homogeneous

theorem require_Usul_IDA_Derivation_incompatible_scopes_rejected :
    ∀ {env : Environment} {tree : Tree} {p q : Premise},
      p ∈ tree.leaves → q ∈ tree.leaves → p.key ≠ q.key →
      ¬ (evaluate env tree).Accepted := @incompatible_scopes_rejected

theorem require_Usul_IDA_Derivation_rejected_leaf_blocks_tree :
    ∀ {env : Environment} {tree : Tree} {p : Premise}, p ∈ tree.leaves →
      ¬ (evaluateSource env p).Accepted → ¬ (evaluate env tree).Accepted :=
  @rejected_leaf_blocks_tree

theorem require_Usul_IDA_Derivation_missing_ruling_blocks_tree :
    ∀ {env : Environment} {tree : Tree} {p : Premise}, p ∈ tree.leaves →
      p.request.record.answerCode = 0 → ¬ (evaluate env tree).Accepted :=
  @missing_ruling_blocks_tree

theorem require_Usul_IDA_Derivation_suspended_ruling_blocks_tree :
    ∀ {env : Environment} {tree : Tree} {p : Premise}, p ∈ tree.leaves →
      p.request.record.answerCode = 32 → ¬ (evaluate env tree).Accepted :=
  @suspended_ruling_blocks_tree

theorem require_Usul_IDA_Derivation_unauthenticated_source_blocks_tree :
    ∀ {env : Environment} {tree : Tree} {p : Premise}, p ∈ tree.leaves →
      p.request.record.provenance.source ∉ env.authenticatedSources →
      ¬ (evaluate env tree).Accepted := @unauthenticated_source_blocks_tree

theorem require_Usul_IDA_Derivation_stale_interpretation_blocks_tree :
    ∀ {env : Environment} {tree : Tree} {p : Premise}, p ∈ tree.leaves →
      matchingVersions env p ≠ [expectedVersion p] →
      ¬ (evaluate env tree).Accepted := @stale_interpretation_blocks_tree

theorem require_Usul_IDA_Derivation_non_admitted_leaf_blocks_tree :
    ∀ {env : Environment} {tree : Tree} {p : Premise} {entry : Judgment.Entry},
      p ∈ tree.leaves → Judgment.matchingEntries env.registry p.request.entryId = [entry] →
      entry.status ≠ .admitted → ¬ (evaluate env tree).Accepted :=
  @non_admitted_leaf_blocks_tree

theorem require_Usul_IDA_Derivation_substituted_record_blocks_tree :
    ∀ {env : Environment} {tree : Tree} {p : Premise} {entry : Judgment.Entry},
      p ∈ tree.leaves → Judgment.matchingEntries env.registry p.request.entryId = [entry] →
      entry.record ≠ p.request.record → ¬ (evaluate env tree).Accepted :=
  @substituted_record_blocks_tree

theorem require_Usul_IDA_Derivation_unsupported_evidence_blocks_tree :
    ∀ {env : Environment} {tree : Tree} {p : Premise} {decision : EvidenceDecision},
      p ∈ tree.leaves → matchingEvidence env p = [decision] →
      decision.classification ≠ .supported → ¬ (evaluate env tree).Accepted :=
  @unsupported_evidence_blocks_tree

theorem require_Usul_IDA_Derivation_question_identity_guard :
    ∀ {env : Environment} {tree : Tree} {p q : Premise},
      p ∈ tree.leaves → q ∈ tree.leaves → p.questionId ≠ q.questionId →
      ¬ (evaluate env tree).Accepted := @question_identity_guard

theorem require_Usul_IDA_Derivation_context_guard :
    ∀ {env : Environment} {tree : Tree} {p q : Premise},
      p ∈ tree.leaves → q ∈ tree.leaves →
      p.request.record.scope.context ≠ q.request.record.scope.context →
      ¬ (evaluate env tree).Accepted := @context_guard

theorem require_Usul_IDA_Derivation_provenance_grades_preserved :
    ∀ (env : Environment) (tree : Tree),
      (evaluate env tree).provenance.map (fun p => p.request.record.provenance.grade) =
        tree.leaves.map (fun p => p.request.record.provenance.grade) := provenance_grades_preserved

theorem require_Usul_IDA_Derivation_taklifi_intersection_exact :
    ∀ {left right result : Constraint}, intersectAnswers .taklifi left right = some result →
      result.set = left.set.inter right.set := @taklifi_intersection_exact

theorem require_Usul_IDA_Derivation_taklifi_subset_both :
    ∀ {left right result : Constraint}, intersectAnswers .taklifi left right = some result →
      result.set.Subset left.set ∧ result.set.Subset right.set := @taklifi_subset_both

theorem require_Usul_IDA_Derivation_sign_agreement :
    ∀ (sign : Sign) (left right result : Judgment.Answer (.wadi sign)),
      intersectAnswers (.wadi sign) left right = some result →
      left = right ∧ result = left := sign_agreement

theorem require_Usul_IDA_Derivation_accepted_conclusion_scope :
    ∀ {env : Environment} {tree : Tree} {c : KnownConclusion},
      (evaluate env tree).Accepted → (evaluate env tree).conclusion = some c →
      ∀ p ∈ tree.leaves, c.key = p.key := @accepted_conclusion_scope

theorem require_Usul_IDA_Derivation_classification_admitted_iff :
    ∀ (e : Evaluation), e.classification = .admitted ↔ e.Accepted := classification_admitted_iff

theorem require_Usul_IDA_Derivation_alternative_order :
    ∀ (env : Environment) (trees : List Tree) (i : Nat),
      (alternatives env trees)[i]? = (trees[i]?).map (evaluate env) := alternative_order

theorem require_Usul_IDA_Derivation_alternatives_length :
    ∀ (env : Environment) (trees : List Tree),
      (alternatives env trees).length = trees.length := alternatives_length

theorem require_Usul_IDA_Derivation_alternatives_provenance :
    ∀ (env : Environment) (trees : List Tree),
      (alternatives env trees).map Evaluation.provenance = trees.map Tree.leaves :=
  alternatives_provenance

theorem require_Usul_IDA_Derivation_receipt_valid_original :
    ∀ (env : Environment) (tree : Tree), (receipt env tree).ValidAt env := receipt_valid_original

theorem require_Usul_IDA_Derivation_receipt_accepted_iff :
    ∀ (env : Environment) (tree : Tree),
      (receipt env tree).AcceptedAt env ↔ (evaluate env tree).Accepted := receipt_accepted_iff

theorem require_Usul_IDA_Derivation_changed_revision_rejects_receipt :
    ∀ {current : Environment} {r : Receipt},
      r.environment.implementationRevision ≠ current.implementationRevision →
      ¬ r.AcceptedAt current := @changed_revision_rejects_receipt

theorem require_Usul_IDA_Derivation_changed_result_rejects_receipt :
    ∀ {current : Environment} {r : Receipt},
      r.result ≠ evaluate current r.tree → ¬ r.AcceptedAt current := @changed_result_rejects_receipt

theorem require_Usul_IDA_Derivation_accepted_receipt_sources :
    ∀ {current : Environment} {r : Receipt}, r.AcceptedAt current →
      r.result.provenance = r.tree.leaves ∧
        ∀ p ∈ r.tree.leaves, AdmissibleLeaf current p := @accepted_receipt_sources

theorem require_Usul_IDA_Derivation_verifyReceipt_sound :
    ∀ {current : Environment} {r : Receipt}, verifyReceipt current r = true →
      r.environment = current ∧ r.result = evaluate current r.tree ∧
        (evaluate current r.tree).Accepted := @verifyReceipt_sound

theorem require_Usul_IDA_Derivation_unauthorized_evidence_promotion :
    ∀ (env : Environment) (tree : Tree) (p : Premise), p ∈ tree.leaves →
      matchingEvidence env p ≠ [⟨p, .supported⟩] → ¬ (evaluate env tree).Accepted :=
  unauthorized_evidence_promotion

open UsulTest.IDADerivation

theorem require_UsulTest_IDADerivation_source_catalog_shapes :
    ∀ i : Fin 2, (syntheticSource (i.val + 1)).WellFormed ∧
      (sourceCells (i.val + 1)).length = 68 := source_catalog_shapes

theorem require_UsulTest_IDADerivation_leaf_guard_matrix :
    ∀ (q : Fin 5) (v : Fin 32), primaryCode (leafEval q.val v.val) = expectedLeafCode v.val :=
  leaf_guard_matrix

theorem require_UsulTest_IDADerivation_source_full_values :
    ∀ q : Fin 5, leafEval q.val 0 =
      ⟨expectedKnown q.val (A q.val), [], [P q.val (A q.val) 1]⟩ := source_full_values

theorem require_UsulTest_IDADerivation_taklifi_full_values :
    ∀ (a b : Fin 33), pairEval 0 a.val b.val = expectedPair 0 a.val b.val := taklifi_full_values

theorem require_UsulTest_IDADerivation_typed_full_values :
    ∀ (q : Fin 4) (k : Fin 16),
      pairEval (q.val + 1) (B (q.val + 1) (k.val / 4)) (B (q.val + 1) (k.val % 4)) =
      expectedPair (q.val + 1) (B (q.val + 1) (k.val / 4)) (B (q.val + 1) (k.val % 4)) :=
  typed_full_values

theorem require_UsulTest_IDADerivation_scope_guard_matrix :
    ∀ v : Fin 13, (scopeEval v.val).issues = (if v.val = 0 then [] else [.outOfScope]) ∧
      (scopeEval v.val).provenance = (scopeFixture v.val).2.leaves := scope_guard_matrix

theorem require_UsulTest_IDADerivation_nested_blocker_matrix :
    ∀ (v : Fin 10) (shape : Fin 3),
      (treeEval v.val shape.val).issues = expectedTreeIssues v.val shape.val ∧
      (treeEval v.val shape.val).provenance = (treeFixture v.val shape.val).2.leaves :=
  nested_blocker_matrix

theorem require_UsulTest_IDADerivation_alternatives_unselected :
    alternativeEval 0 0 = ⟨expectedKnown 0 1, [], [P 0 1 1]⟩ ∧
    alternativeEval 0 1 = ⟨expectedKnown 0 16, [], [P 0 16 2]⟩ ∧
    alternativeEval 1 0 = alternativeEval 0 0 ∧
    alternativeEval 1 1 = ⟨none, [.registryRejected .notAdmitted], [P 0 16 2]⟩ ∧
    pairEval 0 1 16 = ⟨none, [.conflictingAnswers], [P 0 1 1, P 0 16 2]⟩ :=
  alternatives_unselected

theorem require_UsulTest_IDADerivation_receipt_mutation_matrix :
    ∀ v : Fin 16, replayValue v.val = (if v.val = 0 then 1 else 0) := receipt_mutation_matrix

theorem require_UsulTest_IDADerivation_forged_admission_rejected :
    let (env, forged) := replayFixture 7
    forged.result.isAccepted = true ∧ verifyReceipt env forged = false := forged_admission_rejected

end UsulTest.IDADerivationContracts
