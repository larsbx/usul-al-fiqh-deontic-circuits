import Usul.Cat.IDASemantics

/-! ACT-05 checks a finite contextual derivation against current source and
application authority. An authenticated catalog is a trusted input. The receipt
records a contextual formula and has no operation that publishes a ruling. -/

namespace Usul.IDA.Admission

open Substitution Semantics

/-- Include every valuation slot, including slots unused by the inquiry. -/
def groundingValues : {Γ : Variables} → Valuation Γ → List EntityRef
  | [], _ => []
  | k :: _, ρ => (ρ k .here).val :: groundingValues (fun j x => ρ j (.there x))

structure Application (v : Context.Vocabulary) where
  snapshot : Context.Snapshot
  grounding : List EntityRef
  premises : List (Formula v [])
  conclusion : Formula v []
  deriving DecidableEq

structure Certificate (v : Context.Vocabulary) where
  token : Nat
  application : Application v
  formula : Formula v []
  premise : Derivation.Premise
  deriving DecidableEq

structure Side (v : Context.Vocabulary) where
  application : Application v
  certificates : List (Certificate v)
  deriving DecidableEq

structure Authority (v : Context.Vocabulary) where
  environment : Derivation.Environment
  contexts : Context.Catalog
  authenticated : List (Certificate v)
  grants : List (Side v)
  deriving DecidableEq

/-- The catalog verifier is outside Lean. Even a previously authenticated
token must resolve uniquely to the full submitted certificate. -/
def Certificate.Authenticated (c : Certificate v) (a : Authority v) : Prop :=
  c.token ≠ 0 ∧ a.authenticated.filter (fun other => other.token == c.token) = [c]

instance (c : Certificate v) (a : Authority v) : Decidable (c.Authenticated a) := by
  unfold Certificate.Authenticated
  infer_instance

def Certificate.Authorized (c : Certificate v) (a : Authority v)
    (application : Application v) : Prop :=
  c.application = application ∧ application.snapshot.MatchesPremise c.premise ∧
    c.Authenticated a ∧ (Derivation.evaluateSource a.environment c.premise).Accepted

instance (c : Certificate v) (a : Authority v) (application : Application v) :
    Decidable (c.Authorized a application) := by
  unfold Certificate.Authorized
  infer_instance

structure Plan (r : ActRegistry.Registry) (v : Context.Vocabulary) where
  destination : PremiseContext v
  source : PremiseContext v
  arrow : PremiseArrow destination source
  inquiry : Inquiry r source.variables
  conclusion : Formula v source.variables
  derivation : Derives source.premises conclusion
  sourceValuation : Valuation source.variables
  destinationValuation : Valuation destination.variables
  destinationSubjectId : Nat
  destinationContextId : Nat
  destinationPolicy : ActRegistry.KindKey

/-- The bounded route changes subject, context and admission policy explicitly. The
question, profile, temporal frame and registered act definition are retained. -/
def Plan.destinationInquiry (p : Plan r v) : Inquiry r p.destination.variables :=
  let i := p.inquiry.subst p.arrow.substitution
  { i with frame := { i.frame with
      subjectId := p.destinationSubjectId
      snapshot := { i.frame.snapshot with contextId := p.destinationContextId }
      admissionPolicy := p.destinationPolicy } }

def Plan.sourceApplication (p : Plan r v) (snapshot : Context.Snapshot) : Application v :=
  ⟨snapshot, groundingValues p.sourceValuation,
    p.source.premises.map (·.subst p.sourceValuation.grounding),
    p.conclusion.subst p.sourceValuation.grounding⟩

def Plan.destinationApplication (p : Plan r v) (snapshot : Context.Snapshot) : Application v :=
  ⟨snapshot, groundingValues p.destinationValuation,
    p.destination.premises.map (·.subst p.destinationValuation.grounding),
    (p.conclusion.subst p.arrow.substitution).subst p.destinationValuation.grounding⟩

theorem Plan.reconstructed (p : Plan r v) :
    Derives p.destination.premises (p.conclusion.subst p.arrow.substitution) := by
  apply Derives.cut (p.derivation.subst p.arrow.substitution)
  intro f hf
  obtain ⟨old, hm, rfl⟩ := List.mem_map.mp hf
  exact p.arrow.admissible old hm

theorem Plan.conditional_sound (p : Plan r v) (h : History v)
    (hp : ModelsPremises h p.destinationValuation p.destination.premises) :
    Satisfies h p.destinationValuation (p.conclusion.subst p.arrow.substitution) :=
  sound p.reconstructed h p.destinationValuation hp

def frameMatches (i : Inquiry r Γ) (s : Context.Snapshot) : Prop :=
  s.envelope.context = i.frame.snapshot ∧ s.time = i.frame.timeView ∧
    s.admissionPolicy = i.frame.admissionPolicy ∧ s.opportunity = i.frame.opportunity ∧
    s.envelope.key = i.description.schema.definition.key ∧
    s.envelope.definitionDigest = i.description.schema.definition.digest

instance (i : Inquiry r Γ) (s : Context.Snapshot) : Decidable (frameMatches i s) := by
  unfold frameMatches
  infer_instance

structure Side.Valid (r : ActRegistry.Registry) (a : Authority v) (side : Side v)
    (expected : Application v) (i : Inquiry r Γ) (ρ : Valuation Γ) : Prop where
  exactApplication : side.application = expected
  currentSnapshot :
    Context.resolve r a.contexts expected.snapshot = .ok expected.snapshot
  exactInquiry : expected.snapshot.inquiry = interpretInquiry i ρ
  exactFrame : frameMatches i expected.snapshot
  vocabulary : expected.snapshot.vocabulary = v
  exactPremises : side.certificates.map Certificate.formula = expected.premises
  authority : ∀ c ∈ side.certificates, c.Authorized a expected
  policy : side ∈ a.grants

inductive Failure where
  | changedApplication | snapshot (why : Context.Failure) | inquiry | vocabulary
  | frame | premiseList | certificateScope | certificateAuthentication
  | sourceAdmission (why : Derivation.Issue) | policy | changedAuthority
  deriving DecidableEq, Repr

private def checkCertificate (a : Authority v) (expected : Application v)
    (c : Certificate v) : Except Failure (PLift (c.Authorized a expected)) :=
  if hs : c.application = expected ∧ expected.snapshot.MatchesPremise c.premise then
    if ha : c.Authenticated a then
      let result := Derivation.evaluateSource a.environment c.premise
      if hr : result.Accepted then .ok ⟨hs.1, hs.2, ha, hr⟩
      else .error (.sourceAdmission (result.issues.headD .badEnvironment))
    else .error .certificateAuthentication
  else .error .certificateScope

private def checkCertificates (a : Authority v) (expected : Application v)
    (certs : List (Certificate v)) :
    Except Failure (PLift (∀ c ∈ certs, c.Authorized a expected)) :=
  match certs with
  | [] => .ok ⟨by simp⟩
  | c :: rest => do
    let head ← checkCertificate a expected c
    let tail ← checkCertificates a expected rest
    return ⟨by
      intro entry hm
      rcases List.mem_cons.mp hm with he | ht
      · subst entry
        exact head.down
      · exact tail.down entry ht⟩

def checkSide (r : ActRegistry.Registry) (a : Authority v) (side : Side v)
    (expected : Application v) (i : Inquiry r Γ) (ρ : Valuation Γ) :
    Except Failure (PLift (side.Valid r a expected i ρ)) := do
  if he : side.application = expected then
    match h : Context.resolve r a.contexts expected.snapshot with
    | .error why => throw (.snapshot why)
    | .ok actual =>
      have hs : actual = expected.snapshot :=
        ((Context.resolve_iff r a.contexts expected.snapshot actual).mp h).2.2.2
      if hi : expected.snapshot.inquiry = interpretInquiry i ρ then
        if hf : frameMatches i expected.snapshot then
          if hv : expected.snapshot.vocabulary = v then
            if hp : side.certificates.map Certificate.formula = expected.premises then
              let certs ← checkCertificates a expected side.certificates
              if hg : side ∈ a.grants then
                return ⟨⟨he, hs ▸ h, hi, hf, hv, hp, certs.down, hg⟩⟩
              else throw .policy
            else throw .premiseList
          else throw .vocabulary
        else throw .frame
      else throw .inquiry
  else throw .changedApplication

/-- The plan index retains the original derivation, typed substitution and both
valuations. The two proof fields witness separate validations. -/
structure Receipt (p : Plan r v) where
  authority : Authority v
  source : Side v
  destination : Side v
  sourceValid : source.Valid r authority (p.sourceApplication source.application.snapshot)
    p.inquiry p.sourceValuation
  destinationValid : destination.Valid r authority
    (p.destinationApplication destination.application.snapshot)
    p.destinationInquiry p.destinationValuation

inductive Stage where
  | source | destination | replay
  deriving DecidableEq, Repr

structure Rejection (v : Context.Vocabulary) where
  stage : Stage
  reason : Failure
  source : Side v
  destination : Side v
  deriving DecidableEq

def reconstruct (p : Plan r v) (a : Authority v) (source destination : Side v) :
    Except (Rejection v) (Receipt p) :=
  match checkSide r a source (p.sourceApplication source.application.snapshot)
      p.inquiry p.sourceValuation with
  | .error why => .error ⟨.source, why, source, destination⟩
  | .ok hs =>
    match checkSide r a destination (p.destinationApplication destination.application.snapshot)
        p.destinationInquiry p.destinationValuation with
    | .error why => .error ⟨.destination, why, source, destination⟩
    | .ok hd => .ok ⟨a, source, destination, hs.down, hd.down⟩

/-- Fail closed on authority changes. A new application can be reconstructed
against changed authority only by running both validations with current inputs. -/
def replay (p : Plan r v) (current : Authority v) (receipt : Receipt p) :
    Except (Rejection v) (Receipt p) :=
  if current = receipt.authority then reconstruct p current receipt.source receipt.destination
  else .error ⟨.replay, .changedAuthority, receipt.source, receipt.destination⟩

theorem replay_changed (p : Plan r v) (a : Authority v) (receipt : Receipt p)
    (h : a ≠ receipt.authority) : replay p a receipt =
      .error ⟨.replay, .changedAuthority, receipt.source, receipt.destination⟩ := by
  simp [replay, h]

theorem reconstruct_preserves_provenance (p : Plan r v) (a : Authority v)
    (source destination : Side v) :
    match reconstruct p a source destination with
    | .ok receipt =>
      receipt.source = source ∧ receipt.destination = destination ∧ receipt.authority = a
    | .error rejected => rejected.source = source ∧ rejected.destination = destination := by
  cases hs : checkSide r a source (p.sourceApplication source.application.snapshot)
      p.inquiry p.sourceValuation with
  | error why => simp [reconstruct, hs]
  | ok sourceValid =>
    cases hd : checkSide r a destination (p.destinationApplication destination.application.snapshot)
        p.destinationInquiry p.destinationValuation <;> simp [reconstruct, hs, hd]

theorem authorized_certificate_source {c : Certificate v} {a : Authority v}
    {application : Application v} (h : c.Authorized a application) :
    ∃ receipt, Derivation.authorize a.environment c.premise = .ok receipt ∧
      Derivation.Authority a.environment c.premise receipt := by
  obtain ⟨receipt, ha, _⟩ := (Derivation.source_accepted_iff _ _).mp h.2.2.2
  exact ⟨receipt, (Derivation.authorized_iff _ _ _).mpr ha, ha⟩

theorem no_token_reuse {c d : Certificate v} {a : Authority v}
    (hc : c.Authenticated a) (hd : d.Authenticated a) (h : c.token = d.token) : c = d := by
  have same := hc.2
  rw [h, hd.2] at same
  exact (List.singleton_inj.mp same).symm

theorem Receipt.destination_grounding {p : Plan r v} (receipt : Receipt p) :
    receipt.destination.application.snapshot.inquiry =
      interpretInquiry p.destinationInquiry p.destinationValuation :=
  receipt.destinationValid.exactInquiry

theorem Receipt.destination_certificates {p : Plan r v} (receipt : Receipt p) :
    receipt.destination.certificates.map Certificate.formula =
      p.destination.premises.map (·.subst p.destinationValuation.grounding) :=
  receipt.destinationValid.exactPremises

theorem Receipt.destination_question {p : Plan r v} (receipt : Receipt p) :
    receipt.destination.application.snapshot.inquiry.question = p.inquiry.frame.question :=
  congrArg Context.Inquiry.question receipt.destination_grounding

theorem Receipt.conditional_sound {p : Plan r v} (receipt : Receipt p) (h : History v)
    (empty : Valuation []) (hp : ModelsPremises h p.destinationValuation p.destination.premises) :
    Satisfies h empty receipt.destination.application.conclusion := by
  rw [receipt.destinationValid.exactApplication]
  change Satisfies h empty
    ((p.conclusion.subst p.arrow.substitution).subst p.destinationValuation.grounding)
  apply (satisfaction_subst h _ p.destinationValuation.grounding empty).mpr
  exact p.conditional_sound h hp

end Usul.IDA.Admission
