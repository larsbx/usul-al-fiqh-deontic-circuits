import UsulTest.IDAPilot

/-!
# Three bounded ACT-08 structural cases

The corpus revocation kind remains unresolved. The other examples use synthetic
repayment descriptions, report observations, histories and certificate catalogs.
Each occurrence has its own plan; substitution never changes an occurrence or
profile. A formula reconstruction receipt is not a juristic admission.
-/

namespace UsulTest.IDAStructuralCases

open Usul Usul.IDA Usul.IDA.Substitution Usul.IDA.Semantics
open IDASubstitution (people x y atom vocabulary)
open IDASemantics (registry valuation history)

/-! ## Corpus-linked unresolved revocation -/

def revokeDefinition : ActRegistry.Definition :=
  ⟨⟨⟨"fiqh.act.candidate.v1", "agency.revoke"⟩, 1⟩, List.replicate 32 9,
   [⟨"revoking_party", some .person⟩, ⟨"mandate_reference", none⟩, ⟨"manifestation", none⟩]⟩

def candidateSignature : List String :=
  [revokeDefinition.key.symbol.space, revokeDefinition.key.symbol.name,
    toString revokeDefinition.key.version] ++
    revokeDefinition.roles.flatMap fun role =>
      [role.role, role.kind.map ActRegistry.encodeKind |>.getD "unresolved"]

/-- Attempted reference casts are submitted syntax, never changes to the corpus definition. -/
def revokeEnvelope (mandateKind : RefKind := .obligation) : ActRegistry.Envelope :=
  let operation : Operation := ⟨revokeDefinition.key.symbol,
    [⟨"revoking_party", .person⟩, ⟨"mandate_reference", mandateKind⟩,
     ⟨"manifestation", .proposition⟩]⟩
  { IDAActRegistry.baseEnvelope with
    key := revokeDefinition.key
    definitionDigest := revokeDefinition.digest
    qualifications := []
    action := ⟨operation,
      [⟨"revoking_party", IDAActRegistry.payer⟩,
       ⟨"mandate_reference", ⟨mandateKind, ⟨"synthetic.mandate", "m1"⟩⟩⟩,
       ⟨"manifestation", ⟨.proposition, ⟨"synthetic.manifestation", "m1"⟩⟩⟩]⟩ }

def registryFixture (variant : Nat) : ActRegistry.Registry × ActRegistry.Envelope :=
  let ordinary : ActRegistry.Registry := ⟨1, [revokeDefinition]⟩
  let e := revokeEnvelope .obligation
  match variant with
  | 1 => (ordinary, revokeEnvelope .person)
  | 2 => (ordinary, revokeEnvelope .asset)
  | 3 => (ordinary, revokeEnvelope .proposition)
  | 4 => (⟨1, []⟩, e)
  | 5 => (⟨1, [revokeDefinition, { revokeDefinition with roles :=
      [⟨"revoking_party", some .person⟩, ⟨"mandate_reference", some .obligation⟩,
       ⟨"manifestation", some .proposition⟩] }]⟩, e)
  | 6 => (ordinary, { e with definitionDigest := List.replicate 32 8 })
  | 7 => (ordinary, { e with key := { e.key with version := 2 } })
  | 8 => (⟨1, [{ revokeDefinition with roles :=
      [⟨"revoking_party", some .person⟩, ⟨"mandate_reference", none⟩,
       ⟨"manifestation", some .proposition⟩] }]⟩, e)
  | _ => (ordinary, e)

def registryCells (variant : Nat) : List Nat :=
  let (r, e) := registryFixture variant
  [ActRegistry.resolveCode r e]

theorem revoke_unresolved (r : ActRegistry.Registry) (e : ActRegistry.Envelope) :
    ActRegistry.resolve r e ≠ .ok revokeDefinition :=
  ActRegistry.unresolved_member_rejected
    (role := ⟨"mandate_reference", none⟩) (by decide) rfl

theorem registry_controls :
    (List.range 9).flatMap registryCells = [6, 6, 6, 6, 4, 1, 5, 4, 6] := by decide

/-! ## Two rigid occurrences under one profile -/

def occurrenceSymbol (second : Bool) : Symbol :=
  ⟨"synthetic.event", if second then "two" else "one"⟩

def opportunity (second : Bool) : Opportunity :=
  { IDAContext.opportunity with occurrence := occurrenceSymbol second }

def sourceId (second : Bool) : Nat := 1 + 2 * second.toNat
def destinationId (second : Bool) : Nat := 2 + 2 * second.toNat

def plan (second swapped : Bool) : Admission.Plan registry vocabulary :=
  let base := IDAAdmission.plan
  let inquiry := { base.inquiry with frame := { base.inquiry.frame with
    snapshot := { base.inquiry.frame.snapshot with contextId := sourceId second }
    opportunity := some (opportunity second) } }
  if swapped then
    { base with inquiry := inquiry, destinationContextId := destinationId second }
  else
    { destination := IDASemantics.arrowTarget
      source := IDASemantics.arrowTarget
      arrow := PremiseArrow.id IDASemantics.arrowTarget
      inquiry := inquiry
      conclusion := base.conclusion
      derivation := base.derivation
      sourceValuation := valuation 0
      destinationValuation := valuation 0
      destinationSubjectId := base.destinationSubjectId
      destinationContextId := destinationId second
      destinationPolicy := base.destinationPolicy }

def sourceSnapshot (second swapped : Bool) : Context.Snapshot :=
  let p := plan second swapped
  IDAPilot.reported (IDAAdmission.snapshot (sourceId second) p.inquiry p.sourceValuation) 9

def destinationSnapshot (second swapped : Bool) (mask : Nat) : Context.Snapshot :=
  let p := plan second swapped
  IDAPilot.reported
    (IDAAdmission.snapshot (destinationId second) p.destinationInquiry p.destinationValuation) mask

def sourceApplication (second swapped : Bool) : Admission.Application vocabulary :=
  (plan second swapped).sourceApplication (sourceSnapshot second swapped)

def destinationApplication (second swapped : Bool) (mask : Nat) : Admission.Application vocabulary :=
  (plan second swapped).destinationApplication (destinationSnapshot second swapped mask)

def sourceCertificate (second swapped : Bool) : Admission.Certificate vocabulary :=
  IDAAdmission.certificate (sourceId second) (sourceApplication second swapped)
    ((atom x).subst (valuation 0).grounding)

def destinationCertificate (second swapped : Bool) (mask : Nat) : Admission.Certificate vocabulary :=
  IDAAdmission.certificate (destinationId second) (destinationApplication second swapped mask)
    ((atom (if swapped then y else x)).subst (valuation 0).grounding)

def sourceSide (second swapped : Bool) : Admission.Side vocabulary :=
  ⟨sourceApplication second swapped, [sourceCertificate second swapped]⟩

def destinationSide (second swapped : Bool) (mask : Nat) : Admission.Side vocabulary :=
  ⟨destinationApplication second swapped mask, [destinationCertificate second swapped mask]⟩

/-- Four independently exact native applications. Authority is fixture data,
not something the production checker derives from a submitted certificate. -/
def authority (swapped : Bool) (leftMask rightMask : Nat) : Admission.Authority vocabulary :=
  let sides := [sourceSide false swapped, destinationSide false swapped leftMask,
    sourceSide true swapped, destinationSide true swapped rightMask]
  let certificates := sides.flatMap (·.certificates)
  let env := IDADerivation.E (certificates.map Admission.Certificate.premise)
  ⟨{ env with currentVersions := env.currentVersions.eraseDups },
   sides.map (·.application.snapshot), certificates, sides⟩

def baselineAuthority (swapped : Bool) := authority swapped 9 9

def failureCode : Admission.Failure → Nat
  | .premiseList => 1
  | .snapshot .stale => 2
  | .sourceAdmission .sourceUnauthenticated => 3
  | .certificateAuthentication => 4
  | .policy => 5
  | .inquiry => 6
  | .sourceAdmission .missingEvidence => 7
  | .changedAuthority => 8
  | .sourceAdmission (.registryRejected .staleSnapshot) => 9
  | .changedApplication => 10
  | .frame => 11
  | .certificateScope => 12
  | _ => 99

def sideCode {α : Type} : Except Admission.Failure α → Nat
  | .ok _ => 0
  | .error why => failureCode why

def admissionCode {p : Admission.Plan r v} :
    Except (Admission.Rejection v) (Admission.Receipt p) → Nat
  | .ok _ => 0
  | .error why => failureCode why.reason

def native (second swapped : Bool) (leftMask rightMask : Nat) :=
  Admission.reconstruct (plan second swapped) (authority swapped leftMask rightMask)
    (sourceSide second swapped)
    (destinationSide second swapped (if second then rightMask else leftMask))

def replayCode (second swapped : Bool) (current : Admission.Authority vocabulary) : Nat :=
  match native second swapped 9 9 with
  | .error _ => 99
  | .ok receipt => admissionCode (Admission.replay (plan second swapped) current receipt)

def rule (second swapped : Bool) : Projection.Rule :=
  ⟨Projection.scope (destinationSnapshot second swapped 9),
   ⟨IDASubstitution.predicate, rfl⟩, ⟨IDASubstitution.revised, rfl⟩, by decide +revert, true⟩

def input (second swapped : Bool) (mask : Nat) : Option (Projection.Input registry) :=
  let s := destinationSnapshot second swapped mask
  if h : s.WellFormed registry then some ⟨s, h⟩ else none

def scopeOccurrence : Judgment.ScopeTarget → Option Symbol
  | .structured (.omit _ o) => some o.occurrence
  | _ => none

def occurrenceCode (o : Option Symbol) : Nat :=
  if o = some (occurrenceSymbol false) then 1
  else if o = some (occurrenceSymbol true) then 2 else 0

theorem substitution_retains_occurrence (i : Inquiry r Γ) (σ : Sub Γ Δ) (ρ : Valuation Δ) :
    scopeOccurrence (interpretInquiry (i.subst σ) ρ).scope.target =
      i.frame.opportunity.map Opportunity.occurrence := by
  cases ho : i.frame.opportunity <;>
    simp [interpretInquiry, Inquiry.ground, Inquiry.toGround, Inquiry.subst, ho, scopeOccurrence]

theorem substitution_retains_profile (i : Inquiry r Γ) (σ : Sub Γ Δ) (ρ : Valuation Δ) :
    (interpretInquiry (i.subst σ) ρ).scope.profile = i.frame.snapshot.profile ∧
      (interpretInquiry (i.subst σ) ρ).scope.profileVersion = i.frame.snapshot.profileVersion :=
  ⟨rfl, rfl⟩

theorem two_stage_inquiry (i : Inquiry r Γ) (σ : Sub Γ Δ) (τ : Sub Δ Θ) (ρ : Valuation Θ) :
    interpretInquiry ((i.subst σ).subst τ) ρ =
      interpretInquiry i (Valuation.pull σ (Valuation.pull τ ρ)) := by
  rw [inquiry_subst, inquiry_subst]

theorem projection_retains_occurrence (rule : Projection.Rule) (x : Projection.Input r) :
    scopeOccurrence (Projection.project rule x).scope.inquiry.scope.target =
      x.val.opportunity.map Opportunity.occurrence := by
  change scopeOccurrence (Projection.scope x.val).inquiry.scope.target = _
  rw [Projection.projection_preserves_target]
  cases ho : x.val.opportunity <;> simp [Projection.core, Context.Snapshot.target, ho, scopeOccurrence]

theorem projection_view_contract (rule : Projection.Rule) (x : Projection.Input r) :
    Projection.evaluate rule x = Projection.evaluateProjected rule (Projection.project rule x) ∧
    scopeOccurrence (Projection.project rule x).scope.inquiry.scope.target =
      x.val.opportunity.map Opportunity.occurrence :=
  ⟨Projection.projection_exact rule x, projection_retains_occurrence rule x⟩

theorem distinct_occurrences_remain_distinct (rule : Projection.Rule) (x y : Projection.Input r)
    (h : x.val.opportunity.map Opportunity.occurrence ≠ y.val.opportunity.map Opportunity.occurrence) :
    Projection.project rule x ≠ Projection.project rule y := by
  intro he
  have hh := congrArg (fun d : Projection.Dependencies =>
    scopeOccurrence d.scope.inquiry.scope.target) he
  rw [projection_retains_occurrence, projection_retains_occurrence] at hh
  exact h hh

theorem cross_occurrence_certificate_rejected
    (r : ActRegistry.Registry) (a : Admission.Authority v) (side : Admission.Side v)
    (expected : Admission.Application v) (i : Inquiry r Γ) (ρ : Valuation Γ)
    (c : Admission.Certificate v) (hc : c ∈ side.certificates)
    (h : scopeOccurrence c.application.snapshot.inquiry.scope.target ≠
      scopeOccurrence expected.snapshot.inquiry.scope.target) :
    (Admission.checkSide r a side expected i ρ).isOk = false := by
  cases hs : Admission.checkSide r a side expected i ρ with
  | error why => rfl
  | ok valid =>
    have he := (valid.down.authority c hc).1
    exact False.elim (h (congrArg (fun app : Admission.Application v =>
      scopeOccurrence app.snapshot.inquiry.scope.target) he))

theorem changed_context_receipt_rejected (p : Admission.Plan r v)
    (a : Admission.Authority v) (receipt : Admission.Receipt p)
    (h : a.contexts ≠ receipt.authority.contexts) :
    Admission.replay p a receipt =
      .error ⟨.replay, .changedAuthority, receipt.source, receipt.destination⟩ :=
  Admission.replay_changed p a receipt (fun he => h (congrArg Admission.Authority.contexts he))

/-! ## Adverse certificate cases and finite observations -/

def mutationFixture (second swapped : Bool) (mutation : Nat) :
    Admission.Authority vocabulary × Admission.Side vocabulary :=
  let a := baselineAuthority swapped
  let d := destinationSide second swapped 9
  let c := destinationCertificate second swapped 9
  let other := destinationCertificate (!second) swapped 9
  match mutation with
  | 1 => (a, { d with certificates := [] })
  | 2 => (a, { d with certificates := [{ c with formula := .both c.formula c.formula }] })
  | 3 =>
    let proposed := { d with certificates := [other] }
    ({ a with grants := a.grants ++ [proposed] }, proposed)
  | 4 =>
    let contexts := a.contexts.map fun s =>
      if s.key = d.application.snapshot.key then
        { s with envelope := { s.envelope with context :=
          { s.envelope.context with evidenceRevision := s.envelope.context.evidenceRevision + 1 } } }
      else s
    ({ a with contexts := contexts }, d)
  | 5 => ({ a with authenticated := a.authenticated ++ [c] }, d)
  | 6 =>
    let evidence := a.environment.evidence.filter fun decision =>
      decide (decision.premise.request.entryId ≠ c.premise.request.entryId)
    ({ a with environment := { a.environment with evidence := evidence } }, d)
  | 7 => ({ a with grants := a.grants.filter (fun side => decide (side ≠ d)) }, d)
  | 8 =>
    let sources := a.environment.authenticatedSources.filter fun source =>
      decide (source ≠ c.premise.request.record.provenance.source)
    ({ a with environment := { a.environment with authenticatedSources := sources } }, d)
  | 9 =>
    let proposed := { d with certificates := [{ c with token := other.token }] }
    ({ a with grants := a.grants ++ [proposed] }, proposed)
  | _ => (a, d)

def occurrenceCells (second swapped : Bool) (mutation : Nat) : List Nat :=
  let p := plan second swapped
  let (a, d) := mutationFixture second swapped mutation
  let src := interpretInquiry p.inquiry p.sourceValuation
  let dst := interpretInquiry p.destinationInquiry p.destinationValuation
  let projected := match input second swapped 9 with
    | none => 0
    | some x => occurrenceCode (scopeOccurrence (Projection.project (rule second swapped) x).scope.inquiry.scope.target)
  [occurrenceCode (scopeOccurrence src.scope.target),
   occurrenceCode (scopeOccurrence dst.scope.target), projected,
   src.scope.profile, dst.scope.profile,
   sideCode (Admission.checkSide registry a d
     (p.destinationApplication d.application.snapshot) p.destinationInquiry p.destinationValuation),
   admissionCode (Admission.reconstruct p a (sourceSide second swapped) d),
   replayCode second swapped a]

def qualificationCells (second : Bool) (mask : Nat) : List Nat :=
  match input second true mask, input second true 9 with
  | some current, some base =>
    let r := rule second true
    let currentAuthority := authority true (if second then 9 else mask) (if second then mask else 9)
    let p := plan second true
    [1, IDAProjection.code (Projection.evaluate r current),
     IDAProjection.code (Projection.evaluateProjected r (Projection.project r current)),
     occurrenceCode (scopeOccurrence (Projection.project r current).scope.inquiry.scope.target),
     (decide (Projection.core current = Projection.core base)).toNat,
     (decide (Projection.kind current = Projection.kind base)).toNat,
     (Semantics.evaluate (history 2) p.destinationValuation
       (p.conclusion.subst p.arrow.substitution)).toNat,
     replayCode second true currentAuthority]
  | _, _ => List.replicate 8 99

def expectedObservation (mask : Nat) : Nat :=
  if mask.testBit 2 then if mask.testBit 3 then 7 else 6
  else if mask.testBit 0 then if mask.testBit 1 then 5 else 4
  else if mask.testBit 1 then 3
  else if mask.testBit 3 then 2 else 1

def expectedMutation (mutation : Nat) : List Nat :=
  match mutation with
  | 0 => [0, 0, 0]
  | 1 | 2 => [1, 1, 0]
  | 3 => [12, 12, 8]
  | 4 => [2, 2, 8]
  | 5 | 9 => [4, 4, 8]
  | 6 => [7, 7, 8]
  | 7 => [5, 5, 8]
  | 8 => [3, 3, 8]
  | _ => [99, 99, 99]

set_option maxRecDepth 8192 in
set_option maxHeartbeats 0 in
theorem occurrence_matrix : ∀ second swapped : Bool, ∀ mutation : Fin 10,
    occurrenceCells second swapped mutation.val =
      [second.toNat + 1, second.toNat + 1, second.toNat + 1, 1, 1] ++
        expectedMutation mutation.val := by decide

set_option maxRecDepth 8192 in
set_option maxHeartbeats 0 in
theorem qualification_matrix : ∀ second : Bool, ∀ mask : Fin 16,
    qualificationCells second mask.val =
      [1, expectedObservation mask.val, expectedObservation mask.val,
       second.toNat + 1, 1, 1, 1, if mask.val = 9 then 0 else 8] := by decide

set_option maxRecDepth 8192 in
set_option maxHeartbeats 0 in
theorem fresh_qualification_authority_admits : ∀ second : Bool, ∀ mask : Fin 16,
    admissionCode (native second true (if second then 9 else mask.val)
      (if second then mask.val else 9)) = 0 := by decide

theorem native_models (second swapped : Bool) :
    ModelsPremises (history (if swapped then 2 else 1))
      (plan second swapped).destinationValuation (plan second swapped).destination.premises := by
  cases swapped with
  | false =>
    intro f hf
    have he : f = atom x := List.eq_of_mem_singleton hf
    subst f
    change Semantics.evaluate (history 1) (valuation 0) (atom x) = true
    decide
  | true =>
    intro f hf
    have he : f = atom y := List.eq_of_mem_singleton hf
    subst f
    change Semantics.evaluate (history 2) (valuation 0) (atom y) = true
    decide

theorem native_conditional_sound (second swapped : Bool) :
    Satisfies (history (if swapped then 2 else 1))
      (plan second swapped).destinationValuation
      ((plan second swapped).conclusion.subst (plan second swapped).arrow.substitution) :=
  (plan second swapped).conditional_sound _ (native_models second swapped)

theorem hidden_exception_same_core :
    (destinationSnapshot false true 9).target = (destinationSnapshot false true 13).target ∧
    (destinationSnapshot false true 9).envelope.key = (destinationSnapshot false true 13).envelope.key ∧
    (qualificationCells false 9)[1]? = some 4 ∧
    (qualificationCells false 13)[1]? = some 7 := by decide

theorem same_kind_distinct_occurrences :
    (destinationSnapshot false true 9).envelope.key = (destinationSnapshot true true 9).envelope.key ∧
    (destinationSnapshot false true 9).target ≠ (destinationSnapshot true true 9).target := by decide

def rows : List (String × List Nat × List Nat) :=
  (List.range 9).map (fun n => ("registry", [n, 0, 0], registryCells n)) ++
  [false, true].flatMap (fun second => (List.range 16).map fun mask =>
    ("qualification", [second.toNat, mask, 0], qualificationCells second mask)) ++
  [false, true].flatMap (fun second => [false, true].flatMap fun swapped =>
    (List.range 10).map fun mutation =>
      ("occurrence", [second.toNat, swapped.toNat, mutation], occurrenceCells second swapped mutation))

end UsulTest.IDAStructuralCases
