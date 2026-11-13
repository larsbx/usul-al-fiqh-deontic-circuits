import UsulTest.IDAActIntake

/-! Independently stated proposition contracts for candidate-only intake.
They retain their explicit types if an implementation theorem is weakened. -/

namespace UsulTest.IDAActIntakeContracts

open Usul Usul.IDA Usul.IDA.ActRegistry Usul.IDA.ActIntake

theorem require_prepare_retains_input :
    ∀ {r : Registry} {i : ActIntake.Input} {draft : PreparedDraft r},
      prepare r i = .ok draft → draft.input = i := @prepare_retains_input

theorem require_prepare_preserves_fields :
    ∀ {r : Registry} {i : ActIntake.Input} {draft : PreparedDraft r}, prepare r i = .ok draft →
      draft.envelope.key = i.key ∧
      draft.envelope.definitionDigest = i.definitionDigest ∧
      draft.envelope.registrySnapshot = i.registrySnapshot ∧
      draft.envelope.qualifications = i.qualifications ∧
      draft.envelope.context = i.context ∧ draft.envelope.action.operands = i.operands :=
  @prepare_preserves_fields

theorem require_prepared_resolves :
    ∀ {r : Registry} (draft : PreparedDraft r),
      resolve r draft.envelope = .ok draft.definition := @prepared_resolves

theorem require_prepared_registered :
    ∀ {r : Registry} (draft : PreparedDraft r),
      draft.definition ∈ r.definitions ∧ draft.definition.key = draft.input.key :=
  @prepared_registered

theorem require_prepared_signature :
    ∀ {r : Registry} (draft : PreparedDraft r),
      ∃ ps, resolveRoles draft.definition.roles = some ps ∧
        draft.envelope.action.operation = ⟨draft.definition.key.symbol, ps⟩ ∧
        draft.input.operands.map Operand.parameter = ps := @prepared_signature

theorem require_prepared_role_order :
    ∀ {r : Registry} (draft : PreparedDraft r),
      draft.definition.roles = draft.input.operands.map
        (fun o => (⟨o.role, some o.referent.kind⟩ : RoleSpec)) := @prepared_role_order

theorem require_prepared_pins :
    ∀ {r : Registry} (draft : PreparedDraft r),
      draft.input.key = draft.definition.key ∧
      draft.input.definitionDigest = draft.definition.digest ∧
      draft.input.registrySnapshot = r.snapshot := @prepared_pins

theorem require_prepared_wellFormed :
    ∀ {r : Registry} (draft : PreparedDraft r),
      draft.envelope.action.WellFormed ∧
      (∀ q ∈ draft.envelope.qualifications, q.WellFormed) ∧
      draft.envelope.context.WellFormed := @prepared_wellFormed

theorem require_prepared_unique :
    ∀ {r : Registry} (draft : PreparedDraft r) {other : Definition},
      other ∈ r.definitions → other.key = draft.input.key → other = draft.definition :=
  @prepared_unique

theorem require_prepared_target_exact :
    ∀ {r : Registry} (draft : PreparedDraft r),
      draft.target.expression = .perform draft.envelope.action := @prepared_target_exact

theorem require_unresolved_rejected :
    ∀ {r : Registry} {i : ActIntake.Input} {d : Definition},
      matchingDefinitions r i.key = [d] → resolveRoles d.roles = none →
      ∀ draft : PreparedDraft r, prepare r i ≠ .ok draft := @unresolved_rejected

theorem require_conflict_precedes_input :
    ∀ (r : Registry) (i : ActIntake.Input), ¬ r.Unique →
      prepare r i = .error .registryConflict := conflict_precedes_input

theorem require_qualifications_distinguished :
    ∀ {r s : Registry} (a : PreparedDraft r) (b : PreparedDraft s),
      a.input.qualifications ≠ b.input.qualifications → a.envelope ≠ b.envelope :=
  @qualifications_distinguished

theorem require_operands_distinguished :
    ∀ {r s : Registry} (a : PreparedDraft r) (b : PreparedDraft s),
      a.input.operands ≠ b.input.operands → a.envelope ≠ b.envelope := @operands_distinguished

theorem require_preparation_matrix :
    ∀ r : Fin 14, ∀ i : Fin 36,
      IDAActIntake.preparationCode r.val i.val = IDAActIntake.expectedPreparation r.val i.val :=
  IDAActIntake.preparation_matrix

theorem require_signature_is_derived :
    IDAActIntake.inputCase 0 = IDAActIntake.inputCase 5 ∧
    IDAActIntake.inputCase 0 = IDAActIntake.inputCase 6 ∧
    IDAActIntake.draftEnvelope 0 0 = some IDAActRegistry.baseEnvelope ∧
    IDAActIntake.preparationCode 0 5 = 0 ∧ IDAActIntake.preparationCode 0 6 = 0 :=
  IDAActIntake.signature_is_derived

theorem require_same_sort_swap_retained :
    IDAActIntake.preparationCode 0 0 = 0 ∧ IDAActIntake.preparationCode 0 9 = 0 ∧
    IDAActIntake.draftEnvelope 0 9 = some (IDAActRegistry.envelopeCase 9) ∧
    IDAActIntake.draftEnvelope 0 0 ≠ IDAActIntake.draftEnvelope 0 9 :=
  IDAActIntake.same_sort_swap_retained

theorem require_qualifications_and_context_retained :
    IDAActIntake.draftEnvelope 0 10 = some (IDAActRegistry.envelopeCase 10) ∧
    IDAActIntake.draftEnvelope 0 14 = some (IDAActRegistry.envelopeCase 14) ∧
    IDAActIntake.draftEnvelope 0 0 ≠ IDAActIntake.draftEnvelope 0 10 ∧
    IDAActIntake.draftEnvelope 0 0 ≠ IDAActIntake.draftEnvelope 0 14 :=
  IDAActIntake.qualifications_and_context_retained

theorem require_unresolved_is_not_unknown :
    IDAActIntake.preparationCode 6 0 = 6 ∧ IDAActIntake.preparationCode 1 0 = 4 ∧
    IDAActIntake.draftEnvelope 6 0 = none ∧ IDAActIntake.draftEnvelope 1 0 = none :=
  IDAActIntake.unresolved_is_not_unknown

theorem require_malformed_operands_rejected :
    IDAActIntake.preparationCode 0 7 = 8 ∧ IDAActIntake.preparationCode 0 8 = 8 ∧
    IDAActIntake.preparationCode 0 24 = 9 ∧ IDAActIntake.preparationCode 0 35 = 8 :=
  IDAActIntake.malformed_operands_rejected

end UsulTest.IDAActIntakeContracts
