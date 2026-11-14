import UsulTest.IDAStructuralCases

/-! Explicit ACT-08 contract types. Expected propositions are stated here;
they are not inferred from the implementation declarations. -/

namespace UsulTest.IDAStructuralCasesContracts

open Usul Usul.IDA Usul.IDA.Substitution Usul.IDA.Semantics
open IDAStructuralCases
open IDASubstitution (vocabulary)
open IDASemantics (registry history)

theorem require_revoke_unresolved :
    ∀ (r : ActRegistry.Registry) (e : ActRegistry.Envelope),
      ActRegistry.resolve r e ≠ .ok revokeDefinition := revoke_unresolved

theorem require_registry_controls :
    (List.range 9).flatMap registryCells = [6, 6, 6, 6, 4, 1, 5, 4, 6] := registry_controls

theorem require_substitution_retains_occurrence :
    ∀ {r : ActRegistry.Registry} {Γ Δ : Variables}
      (i : Inquiry r Γ) (σ : Sub Γ Δ) (ρ : Valuation Δ),
      scopeOccurrence (interpretInquiry (i.subst σ) ρ).scope.target =
        i.frame.opportunity.map Opportunity.occurrence := @substitution_retains_occurrence

theorem require_substitution_retains_profile :
    ∀ {r : ActRegistry.Registry} {Γ Δ : Variables}
      (i : Inquiry r Γ) (σ : Sub Γ Δ) (ρ : Valuation Δ),
      (interpretInquiry (i.subst σ) ρ).scope.profile = i.frame.snapshot.profile ∧
      (interpretInquiry (i.subst σ) ρ).scope.profileVersion = i.frame.snapshot.profileVersion :=
  @substitution_retains_profile

theorem require_two_stage_inquiry :
    ∀ {r : ActRegistry.Registry} {Γ Δ Θ : Variables}
      (i : Inquiry r Γ) (σ : Sub Γ Δ) (τ : Sub Δ Θ) (ρ : Valuation Θ),
      interpretInquiry ((i.subst σ).subst τ) ρ =
        interpretInquiry i (Valuation.pull σ (Valuation.pull τ ρ)) := @two_stage_inquiry

theorem require_projection_retains_occurrence :
    ∀ {r : ActRegistry.Registry} (rule : Projection.Rule) (x : Projection.Input r),
      scopeOccurrence (Projection.project rule x).scope.inquiry.scope.target =
        x.val.opportunity.map Opportunity.occurrence := @projection_retains_occurrence

theorem require_projection_view_contract :
    ∀ {r : ActRegistry.Registry} (rule : Projection.Rule) (x : Projection.Input r),
      Projection.evaluate rule x = Projection.evaluateProjected rule (Projection.project rule x) ∧
      scopeOccurrence (Projection.project rule x).scope.inquiry.scope.target =
        x.val.opportunity.map Opportunity.occurrence := @projection_view_contract

theorem require_distinct_occurrences_remain_distinct :
    ∀ {r : ActRegistry.Registry} (rule : Projection.Rule) (x y : Projection.Input r),
      x.val.opportunity.map Opportunity.occurrence ≠ y.val.opportunity.map Opportunity.occurrence →
      Projection.project rule x ≠ Projection.project rule y := @distinct_occurrences_remain_distinct

theorem require_cross_occurrence_certificate_rejected :
    ∀ {v : Context.Vocabulary} {Γ : Variables}
      (r : ActRegistry.Registry) (a : Admission.Authority v) (side : Admission.Side v)
      (expected : Admission.Application v) (i : Inquiry r Γ) (ρ : Valuation Γ)
      (c : Admission.Certificate v), c ∈ side.certificates →
      scopeOccurrence c.application.snapshot.inquiry.scope.target ≠
        scopeOccurrence expected.snapshot.inquiry.scope.target →
      (Admission.checkSide r a side expected i ρ).isOk = false := @cross_occurrence_certificate_rejected

theorem require_changed_context_receipt_rejected :
    ∀ {r : ActRegistry.Registry} {v : Context.Vocabulary}
      (p : Admission.Plan r v) (a : Admission.Authority v) (receipt : Admission.Receipt p),
      a.contexts ≠ receipt.authority.contexts →
      Admission.replay p a receipt =
        .error ⟨.replay, .changedAuthority, receipt.source, receipt.destination⟩ :=
  @changed_context_receipt_rejected

theorem require_occurrence_matrix : ∀ second swapped : Bool, ∀ mutation : Fin 10,
    occurrenceCells second swapped mutation.val =
      [second.toNat + 1, second.toNat + 1, second.toNat + 1, 1, 1] ++
        expectedMutation mutation.val := occurrence_matrix

theorem require_qualification_matrix : ∀ second : Bool, ∀ mask : Fin 16,
    qualificationCells second mask.val =
      [1, expectedObservation mask.val, expectedObservation mask.val,
       second.toNat + 1, 1, 1, 1, if mask.val = 9 then 0 else 8] := qualification_matrix

theorem require_fresh_qualification_authority_admits : ∀ second : Bool, ∀ mask : Fin 16,
    admissionCode (native second true (if second then 9 else mask.val)
      (if second then mask.val else 9)) = 0 := fresh_qualification_authority_admits

theorem require_native_models : ∀ second swapped : Bool,
    ModelsPremises (history (if swapped then 2 else 1))
      (plan second swapped).destinationValuation (plan second swapped).destination.premises := native_models

theorem require_native_conditional_sound : ∀ second swapped : Bool,
    Satisfies (history (if swapped then 2 else 1)) (plan second swapped).destinationValuation
      ((plan second swapped).conclusion.subst (plan second swapped).arrow.substitution) := native_conditional_sound

theorem require_hidden_exception_same_core :
    (destinationSnapshot false true 9).target = (destinationSnapshot false true 13).target ∧
    (destinationSnapshot false true 9).envelope.key = (destinationSnapshot false true 13).envelope.key ∧
    (qualificationCells false 9)[1]? = some 4 ∧
    (qualificationCells false 13)[1]? = some 7 := hidden_exception_same_core

theorem require_same_kind_distinct_occurrences :
    (destinationSnapshot false true 9).envelope.key = (destinationSnapshot true true 9).envelope.key ∧
    (destinationSnapshot false true 9).target ≠ (destinationSnapshot true true 9).target := same_kind_distinct_occurrences

end UsulTest.IDAStructuralCasesContracts
