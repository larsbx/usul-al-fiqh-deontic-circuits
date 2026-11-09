import Usul.Typing.IDADerivation

/-!
# ACT-01: checked act descriptions and exact source bindings

The supported structural fragment is `perform`. Definition digests are exact
supplied pins, never an injectivity axiom or a source of authority. Qualifications
are attributed candidate assertions, not Lean proofs of their contents. The
trusted authority is supplied independently of the request. Acceptance requires
the existing source evaluator, as well as the new exact envelope binding.
-/

namespace Usul.IDA.ActRegistry

structure KindKey where
  symbol : Symbol
  version : Nat
  deriving DecidableEq, Repr

structure RoleSpec where
  role : String
  kind : Option RefKind
  deriving DecidableEq, Repr

structure Definition where
  key : KindKey
  digest : List Nat
  roles : List RoleSpec
  deriving DecidableEq, Repr

structure Registry where
  snapshot : Nat
  definitions : List Definition
  deriving DecidableEq, Repr

def Definition.WellFormed (d : Definition) : Prop :=
  d.key.symbol.WellFormed ∧ 0 < d.key.version ∧ Judgment.DigestShape d.digest ∧
  (∀ r ∈ d.roles, r.role ≠ "") ∧ (d.roles.map RoleSpec.role).Nodup

instance (d : Definition) : Decidable d.WellFormed := by
  unfold Definition.WellFormed
  infer_instance

def Registry.Unique (r : Registry) : Prop :=
  (r.definitions.map Definition.key).Nodup

def Registry.Shaped (r : Registry) : Prop := ∀ d ∈ r.definitions, d.WellFormed

instance (r : Registry) : Decidable r.Unique := by unfold Registry.Unique; infer_instance
instance (r : Registry) : Decidable r.Shaped := by unfold Registry.Shaped; infer_instance

structure Qualification where
  predicate : Symbol
  version : Nat
  arguments : List EntityRef
  polarity : Bool
  mention : Symbol
  deriving DecidableEq, Repr

def Qualification.WellFormed (q : Qualification) : Prop :=
  q.predicate.WellFormed ∧ 0 < q.version ∧
  (∀ a ∈ q.arguments, a.WellFormed) ∧ q.mention.WellFormed

instance (q : Qualification) : Decidable q.WellFormed := by
  unfold Qualification.WellFormed
  infer_instance

/-- Legacy coordinates plus explicit metadata; this is not a semantic interpretation. -/
structure Snapshot where
  contextId : Nat
  timeId : Nat
  profile : Nat
  profileVersion : Nat
  interpretationId : Nat
  interpretationVersion : Nat
  evidenceRevision : Nat
  clock : Symbol
  effectiveAt : Nat
  recordedAt : Nat
  deriving DecidableEq, Repr

def Snapshot.WellFormed (s : Snapshot) : Prop :=
  s.clock.WellFormed ∧ 0 < s.profileVersion ∧ 0 < s.interpretationVersion

instance (s : Snapshot) : Decidable s.WellFormed := by
  unfold Snapshot.WellFormed
  infer_instance

structure Envelope where
  key : KindKey
  definitionDigest : List Nat
  registrySnapshot : Nat
  qualifications : List Qualification
  context : Snapshot
  action : Action
  deriving DecidableEq, Repr

def Envelope.WellFormed (e : Envelope) : Prop :=
  e.action.WellFormed ∧ (∀ q ∈ e.qualifications, q.WellFormed) ∧ e.context.WellFormed

instance (e : Envelope) : Decidable e.WellFormed := by
  unfold Envelope.WellFormed
  infer_instance

/-- Explicitly lossy: definition and context metadata stay in the envelope. -/
def project (e : Envelope) : Judgment.ScopeTarget := .structured (.perform e.action)

def resolveRoles : List RoleSpec → Option (List Parameter)
  | [] => some []
  | r :: rs => do
    let kind ← r.kind
    let rest ← resolveRoles rs
    pure (⟨r.role, kind⟩ :: rest)

/-- The computed signature retains the original ordered roles and sorts. -/
theorem resolved_roles_exact {roles : List RoleSpec} {parameters : List Parameter}
    (h : resolveRoles roles = some parameters) :
    roles = parameters.map (fun p => (⟨p.role, some p.kind⟩ : RoleSpec)) := by
  induction roles generalizing parameters with
  | nil =>
    have hp : parameters = [] := by simpa [resolveRoles] using h.symm
    simp [hp]
  | cons role rest ih =>
    cases hk : role.kind with
    | none => simp [resolveRoles, hk] at h
    | some kind =>
      cases ht : resolveRoles rest with
      | none => simp [resolveRoles, hk, ht] at h
      | some tail =>
        have hp : (⟨role.role, kind⟩ : Parameter) :: tail = parameters := by
          simpa [resolveRoles, hk, ht] using h
        subst parameters
        have hr : role = ⟨role.role, some kind⟩ := by cases role; simp_all
        change role :: rest = (⟨role.role, some kind⟩ : RoleSpec) ::
          tail.map (fun p => (⟨p.role, some p.kind⟩ : RoleSpec))
        exact (congrArg (fun r => r :: rest) hr).trans
          (congrArg (List.cons ⟨role.role, some kind⟩) (ih ht))

def matchingDefinitions (r : Registry) (key : KindKey) : List Definition :=
  r.definitions.filter fun d => d.key == key

inductive Failure where
  | registryConflict | malformedRegistry | registrySnapshotMismatch | unknownKind
  | digestMismatch | unresolvedRole | declarationMismatch | argumentMismatch
  | malformedDescription | bindingConflict | missingBinding | envelopeMismatch
  | premiseMismatch | targetMismatch | sourceRejected | contextMismatch
  deriving DecidableEq, Repr

deriving instance DecidableEq for Except

def failureCode : Failure → Nat
  | .registryConflict => 1 | .malformedRegistry => 2
  | .registrySnapshotMismatch => 3 | .unknownKind => 4
  | .digestMismatch => 5 | .unresolvedRole => 6
  | .declarationMismatch => 7 | .argumentMismatch => 8
  | .malformedDescription => 9 | .bindingConflict => 10
  | .missingBinding => 11 | .envelopeMismatch => 12
  | .premiseMismatch => 13 | .targetMismatch => 14
  | .sourceRejected => 15 | .contextMismatch => 16

def resultCode {α : Type} : Except Failure α → Nat
  | .ok _ => 0 | .error f => failureCode f

/-- Validate the whole registry before attempting the requested key. Even equal
duplicate rows are rejected. There is no first-match interpretation. -/
def resolve (r : Registry) (e : Envelope) : Except Failure Definition :=
  if ¬ r.Unique then .error .registryConflict
  else if ¬ r.Shaped then .error .malformedRegistry
  else if e.registrySnapshot ≠ r.snapshot then .error .registrySnapshotMismatch
  else match matchingDefinitions r e.key with
    | [] => .error .unknownKind
    | [d] =>
      if e.definitionDigest ≠ d.digest then .error .digestMismatch
      else match resolveRoles d.roles with
        | none => .error .unresolvedRole
        | some parameters =>
          if e.action.operation ≠ ⟨d.key.symbol, parameters⟩ then
            .error .declarationMismatch
          else if e.action.operands.map Operand.parameter ≠ parameters then
            .error .argumentMismatch
          else if ¬ e.WellFormed then .error .malformedDescription
          else .ok d
    | _ :: _ :: _ => .error .registryConflict

def resolveCode (r : Registry) (e : Envelope) : Nat := resultCode (resolve r e)

def Resolution (r : Registry) (e : Envelope) (d : Definition) : Prop :=
  r.Unique ∧ r.Shaped ∧ e.registrySnapshot = r.snapshot ∧
  matchingDefinitions r e.key = [d] ∧ e.definitionDigest = d.digest ∧
  ∃ parameters, resolveRoles d.roles = some parameters ∧
    e.action.operation = ⟨d.key.symbol, parameters⟩ ∧
    e.action.operands.map Operand.parameter = parameters ∧ e.WellFormed

theorem resolve_iff (r : Registry) (e : Envelope) (d : Definition) :
    resolve r e = .ok d ↔ Resolution r e d := by
  constructor
  · intro h
    have hu : r.Unique := by
      by_cases hu : r.Unique
      · exact hu
      · simp [resolve, hu] at h
    have hw : r.Shaped := by
      by_cases hw : r.Shaped
      · exact hw
      · simp [resolve, hu, hw] at h
    have hs : e.registrySnapshot = r.snapshot := by
      by_cases hs : e.registrySnapshot = r.snapshot
      · exact hs
      · simp [resolve, hu, hw, hs] at h
    cases hm : matchingDefinitions r e.key with
    | nil => simp [resolve, hu, hw, hs, hm] at h
    | cons actual rest =>
      cases rest with
      | cons other rest => simp [resolve, hu, hw, hs, hm] at h
      | nil =>
        have hd : e.definitionDigest = actual.digest := by
          by_cases hd : e.definitionDigest = actual.digest
          · exact hd
          · simp [resolve, hu, hw, hs, hm, hd] at h
        cases hp : resolveRoles actual.roles with
        | none => simp [resolve, hu, hw, hs, hm, hd, hp] at h
        | some parameters =>
          have ho : e.action.operation = ⟨actual.key.symbol, parameters⟩ := by
            by_cases ho : e.action.operation = ⟨actual.key.symbol, parameters⟩
            · exact ho
            · simp [resolve, hu, hw, hs, hm, hd, hp, ho] at h
          have ha : e.action.operands.map Operand.parameter = parameters := by
            by_cases ha : e.action.operands.map Operand.parameter = parameters
            · exact ha
            · simp [resolve, hu, hw, hs, hm, hd, hp, ho, ha] at h
          have hf : e.WellFormed := by
            by_cases hf : e.WellFormed
            · exact hf
            · simp [resolve, hu, hw, hs, hm, hd, hp, ho, ha, hf] at h
          have he : actual = d := by
            simpa [resolve, hu, hw, hs, hm, hd, hp, ho, ha, hf] using h
          subst actual
          exact ⟨hu, hw, hs, hm, hd, parameters, hp, ho, ha, hf⟩
  · rintro ⟨hu, hw, hs, hm, hd, parameters, hp, ho, ha, hf⟩
    simp [resolve, hu, hw, hs, hm, hd, hp, ho, ha, hf]

theorem resolve_registered {r : Registry} {e : Envelope} {d : Definition}
    (h : resolve r e = .ok d) : d ∈ r.definitions ∧ d.key = e.key := by
  have hm := (resolve_iff r e d).mp h |>.2.2.2.1
  have : d ∈ matchingDefinitions r e.key := by rw [hm]; simp
  simpa [matchingDefinitions] using this

theorem resolve_unique {r : Registry} {e : Envelope} {d other : Definition}
    (h : resolve r e = .ok d) (ho : other ∈ r.definitions) (hk : other.key = e.key) :
    other = d := by
  have hm := (resolve_iff r e d).mp h |>.2.2.2.1
  have : other ∈ matchingDefinitions r e.key := by simp [matchingDefinitions, ho, hk]
  simpa [hm] using this

theorem resolve_schema {r : Registry} {e : Envelope} {d : Definition}
    (h : resolve r e = .ok d) :
    ∃ parameters, resolveRoles d.roles = some parameters ∧
      e.action.operation = ⟨d.key.symbol, parameters⟩ ∧
      e.action.operands.map Operand.parameter = parameters := by
  rcases (resolve_iff r e d).mp h with ⟨_, _, _, _, _, p, hp, ho, ha, _⟩
  exact ⟨p, hp, ho, ha⟩

theorem resolve_declared_schema {r : Registry} {e : Envelope} {d : Definition}
    (h : resolve r e = .ok d) :
    d.roles = e.action.operands.map
      (fun o => (⟨o.role, some o.referent.kind⟩ : RoleSpec)) := by
  rcases resolve_schema h with ⟨ps, hp, _, ha⟩
  rw [resolved_roles_exact hp, ← ha, List.map_map]
  rfl

theorem unresolved_member_rejected {r : Registry} {e : Envelope} {d : Definition}
    {role : RoleSpec} (hm : role ∈ d.roles) (hu : role.kind = none) :
    resolve r e ≠ .ok d := by
  intro h
  rcases resolve_schema h with ⟨ps, hp, _⟩
  rw [resolved_roles_exact hp] at hm
  rcases List.mem_map.mp hm with ⟨p, _, he⟩
  have hk := congrArg RoleSpec.kind he
  simp [hu] at hk

theorem resolve_wellFormed {r : Registry} {e : Envelope} {d : Definition}
    (h : resolve r e = .ok d) : e.WellFormed := by
  rcases (resolve_iff r e d).mp h with ⟨_, _, _, _, _, _, _, _, _, hf⟩
  exact hf

theorem registry_conflict_precedes_lookup (r : Registry) (e : Envelope)
    (h : ¬ r.Unique) : resolve r e = .error .registryConflict := by simp [resolve, h]

theorem unresolved_not_resolved {r : Registry} {e : Envelope} {d : Definition}
    (hu : resolveRoles d.roles = none) : resolve r e ≠ .ok d := by
  intro h
  rcases resolve_schema h with ⟨p, hp, _⟩
  simp [hu] at hp

/-- A structural family, indexed by the exact supplied registry, with an actual
resolver certificate. It carries no legal-admission constructor. -/
structure CheckedDescription (r : Registry) where
  envelope : Envelope
  definition : Definition
  checked : resolve r envelope = .ok definition

def CheckedDescription.target {r : Registry} (d : CheckedDescription r) : Target :=
  ⟨.perform d.envelope.action, (resolve_wellFormed d.checked).1⟩

theorem checked_target_exact {r : Registry} (d : CheckedDescription r) :
    d.target.expression = .perform d.envelope.action := rfl

theorem project_action_iff (e f : Envelope) : project e = project f ↔ e.action = f.action := by
  simp [project]

theorem projection_omits_qualifications (e : Envelope) (qs : List Qualification) :
    project { e with qualifications := qs } = project e := rfl

theorem projection_omits_context (e : Envelope) (s : Snapshot) :
    project { e with context := s } = project e := rfl

structure Binding where
  envelope : Envelope
  premise : Derivation.Premise
  deriving DecidableEq, Repr

structure Authority where
  registry : Registry
  bindings : List Binding
  environment : Derivation.Environment
  deriving DecidableEq, Repr

structure Request where
  envelope : Envelope
  premise : Derivation.Premise
  deriving DecidableEq, Repr

def Binding.entryId (b : Binding) : Nat := b.premise.request.entryId
def Authority.Unique (a : Authority) : Prop := (a.bindings.map Binding.entryId).Nodup
instance (a : Authority) : Decidable a.Unique := by unfold Authority.Unique; infer_instance

def matchingBindings (a : Authority) (entryId : Nat) : List Binding :=
  a.bindings.filter fun b => b.entryId == entryId

def Snapshot.Matches (s : Snapshot) (p : Derivation.Premise) : Prop :=
  s.contextId = p.request.record.scope.context ∧
  s.timeId = p.request.record.scope.time ∧
  s.profile = p.request.record.scope.profile ∧
  s.profileVersion = p.request.record.scope.profileVersion ∧
  s.interpretationId = p.request.record.provenance.interpretationId ∧
  s.interpretationVersion = p.request.record.provenance.interpretationVersion

instance (s : Snapshot) (p : Derivation.Premise) : Decidable (s.Matches p) := by
  unfold Snapshot.Matches
  infer_instance

structure Receipt where
  authority : Authority
  request : Request
  definition : Definition
  result : Derivation.Evaluation
  deriving DecidableEq

def admit (a : Authority) (q : Request) : Except Failure Receipt :=
  match resolve a.registry q.envelope with
  | .error reason => .error reason
  | .ok d =>
    if ¬ a.Unique then .error .bindingConflict
    else match matchingBindings a q.premise.request.entryId with
      | [] => .error .missingBinding
      | [b] =>
        if b.envelope ≠ q.envelope then .error .envelopeMismatch
        else if b.premise ≠ q.premise then .error .premiseMismatch
        else if project q.envelope ≠ q.premise.request.record.scope.target then
          .error .targetMismatch
        else if ¬ q.envelope.context.Matches q.premise then .error .contextMismatch
        else
          let result := Derivation.evaluateSource a.environment q.premise
          if result.Accepted then .ok ⟨a, q, d, result⟩
          else .error .sourceRejected
      | _ :: _ :: _ => .error .bindingConflict

def baseIssueCode (a : Authority) (q : Request) : Nat :=
  if resultCode (admit a q) = 15 then
    ((Derivation.evaluateSource a.environment q.premise).issues.map Derivation.issueCode).headD 0
  else 0

def Admission (a : Authority) (q : Request) (d : Definition) : Prop :=
  resolve a.registry q.envelope = .ok d ∧ a.Unique ∧
  matchingBindings a q.premise.request.entryId = [⟨q.envelope, q.premise⟩] ∧
  project q.envelope = q.premise.request.record.scope.target ∧
  q.envelope.context.Matches q.premise ∧
  (Derivation.evaluateSource a.environment q.premise).Accepted

theorem admit_iff (a : Authority) (q : Request) (receipt : Receipt) :
    admit a q = .ok receipt ↔
      receipt.authority = a ∧ receipt.request = q ∧
      receipt.result = Derivation.evaluateSource a.environment q.premise ∧
      Admission a q receipt.definition := by
  constructor
  · intro h
    cases hr : resolve a.registry q.envelope with
    | error reason => simp [admit, hr] at h
    | ok d =>
      have hu : a.Unique := by
        by_cases hu : a.Unique
        · exact hu
        · simp [admit, hr, hu] at h
      cases hm : matchingBindings a q.premise.request.entryId with
      | nil => simp [admit, hr, hu, hm] at h
      | cons b rest =>
        cases rest with
        | cons other rest => simp [admit, hr, hu, hm] at h
        | nil =>
          have he : b.envelope = q.envelope := by
            by_cases he : b.envelope = q.envelope
            · exact he
            · simp [admit, hr, hu, hm, he] at h
          have hp : b.premise = q.premise := by
            by_cases hp : b.premise = q.premise
            · exact hp
            · simp [admit, hr, hu, hm, he, hp] at h
          have ht : project q.envelope = q.premise.request.record.scope.target := by
            by_cases ht : project q.envelope = q.premise.request.record.scope.target
            · exact ht
            · simp [admit, hr, hu, hm, he, hp, ht] at h
          have hc : q.envelope.context.Matches q.premise := by
            by_cases hc : q.envelope.context.Matches q.premise
            · exact hc
            · simp [admit, hr, hu, hm, he, hp, ht, hc] at h
          have hs : (Derivation.evaluateSource a.environment q.premise).Accepted := by
            by_cases hs : (Derivation.evaluateSource a.environment q.premise).Accepted
            · exact hs
            · simp [admit, hr, hu, hm, he, hp, ht, hc, hs] at h
          have hh : (⟨a, q, d, Derivation.evaluateSource a.environment q.premise⟩ : Receipt) =
              receipt := by simpa [admit, hr, hu, hm, he, hp, ht, hc, hs] using h
          subst receipt
          have hb : b = ⟨q.envelope, q.premise⟩ := by cases b; simp_all
          exact ⟨rfl, rfl, rfl, hr, hu, hb ▸ hm, ht, hc, hs⟩
  · rintro ⟨ha, hq, he, hr, hu, hm, ht, hc, hs⟩
    cases receipt
    simp_all [admit]

theorem admitted_resolution {a : Authority} {q : Request} {r : Receipt}
    (h : admit a q = .ok r) : resolve a.registry q.envelope = .ok r.definition :=
  ((admit_iff a q r).mp h).2.2.2.1

theorem admitted_exact_binding {a : Authority} {q : Request} {r : Receipt}
    (h : admit a q = .ok r) : a.Unique ∧
      matchingBindings a q.premise.request.entryId = [⟨q.envelope, q.premise⟩] := by
  have hh := ((admit_iff a q r).mp h).2.2.2
  exact ⟨hh.2.1, hh.2.2.1⟩

theorem admitted_target {a : Authority} {q : Request} {r : Receipt}
    (h : admit a q = .ok r) : project q.envelope = q.premise.request.record.scope.target :=
  ((admit_iff a q r).mp h).2.2.2.2.2.2.1

theorem admitted_snapshot {a : Authority} {q : Request} {r : Receipt}
    (h : admit a q = .ok r) : q.envelope.context.Matches q.premise :=
  ((admit_iff a q r).mp h).2.2.2.2.2.2.2.1

theorem admitted_source {a : Authority} {q : Request} {r : Receipt}
    (h : admit a q = .ok r) :
    (Derivation.evaluateSource a.environment q.premise).Accepted :=
  ((admit_iff a q r).mp h).2.2.2.2.2.2.2.2

theorem admitted_source_authority {a : Authority} {q : Request} {r : Receipt}
    (h : admit a q = .ok r) : Derivation.AdmissibleLeaf a.environment q.premise :=
  (Derivation.source_accepted_iff _ _).mp (admitted_source h)

theorem admitted_binding_fields {a : Authority} {q : Request} {r : Receipt} {b : Binding}
    (h : admit a q = .ok r)
    (hb : matchingBindings a q.premise.request.entryId = [b]) :
    b.envelope.key = q.envelope.key ∧
    b.envelope.definitionDigest = q.envelope.definitionDigest ∧
    b.envelope.registrySnapshot = q.envelope.registrySnapshot ∧
    b.envelope.qualifications = q.envelope.qualifications ∧
    b.envelope.context = q.envelope.context ∧
    b.envelope.action = q.envelope.action ∧ b.premise = q.premise := by
  have he : b = ⟨q.envelope, q.premise⟩ := by
    simpa [hb] using (admitted_exact_binding h).2
  subst b
  exact ⟨rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩

theorem altered_envelope_rejected {a : Authority} {q : Request} {b : Binding}
    (hb : matchingBindings a q.premise.request.entryId = [b])
    (he : b.envelope ≠ q.envelope) (r : Receipt) : admit a q ≠ .ok r := by
  intro h
  have : b = ⟨q.envelope, q.premise⟩ := by
    simpa [hb] using (admitted_exact_binding h).2
  exact he (congrArg Binding.envelope this)

theorem changed_qualification_rejected {a : Authority} {q : Request} {b : Binding}
    (hb : matchingBindings a q.premise.request.entryId = [b])
    (he : b.envelope.qualifications ≠ q.envelope.qualifications) (r : Receipt) :
    admit a q ≠ .ok r :=
  altered_envelope_rejected hb (fun h => he (congrArg Envelope.qualifications h)) r

theorem changed_snapshot_rejected {a : Authority} {q : Request} {b : Binding}
    (hb : matchingBindings a q.premise.request.entryId = [b])
    (he : b.envelope.context ≠ q.envelope.context) (r : Receipt) : admit a q ≠ .ok r :=
  altered_envelope_rejected hb (fun h => he (congrArg Envelope.context h)) r

theorem source_rejection_blocks {a : Authority} {q : Request}
    (hs : ¬ (Derivation.evaluateSource a.environment q.premise).Accepted) (r : Receipt) :
    admit a q ≠ .ok r := fun h => hs (admitted_source h)

/-- Candidate rejection follows through the actual source/registry constructors. -/
theorem non_admitted_rejected {a : Authority} {q : Request} {entry : Judgment.Entry}
    (hm : Judgment.matchingEntries a.environment.registry q.premise.request.entryId = [entry])
    (hs : entry.status ≠ .admitted) (r : Receipt) : admit a q ≠ .ok r := by
  intro h
  rcases admitted_source_authority h with ⟨base, authority, _⟩
  exact Judgment.non_admitted_not_accepted _ _ base entry hm hs authority.registry

theorem duplicate_bindings_rejected {a : Authority} {q : Request}
    (hu : ¬ a.Unique) (r : Receipt) : admit a q ≠ .ok r := by
  intro h
  exact hu (admitted_exact_binding h).1

theorem target_mismatch_rejected {a : Authority} {q : Request}
    (ht : project q.envelope ≠ q.premise.request.record.scope.target) (r : Receipt) :
    admit a q ≠ .ok r := fun h => ht (admitted_target h)

theorem context_mismatch_rejected {a : Authority} {q : Request}
    (hc : ¬ q.envelope.context.Matches q.premise) (r : Receipt) :
    admit a q ≠ .ok r := fun h => hc (admitted_snapshot h)

def Receipt.ValidAt (r : Receipt) (a : Authority) (q : Request) : Prop := admit a q = .ok r

instance (r : Receipt) (a : Authority) (q : Request) : Decidable (r.ValidAt a q) := by
  unfold Receipt.ValidAt
  infer_instance

def verifyReceipt (a : Authority) (q : Request) (r : Receipt) : Bool := decide (r.ValidAt a q)

theorem receipt_binds_all {a : Authority} {q : Request} {r : Receipt}
    (h : verifyReceipt a q r = true) :
    r.authority = a ∧ r.request = q ∧
    r.result = Derivation.evaluateSource a.environment q.premise ∧
    (Derivation.evaluateSource a.environment q.premise).Accepted := by
  have hv : admit a q = .ok r := of_decide_eq_true h
  have hh := (admit_iff a q r).mp hv
  exact ⟨hh.1, hh.2.1, hh.2.2.1, admitted_source hv⟩

theorem receipt_preserves_source {a : Authority} {q : Request} {r : Receipt}
    (h : admit a q = .ok r) : r.result.provenance = [q.premise] := by
  rw [((admit_iff a q r).mp h).2.2.1]
  exact Derivation.source_provenance _ _

/-! ## Structural wire (textual JSON and SHA256 are separate host adapters)

Sort tags are canonical strings. Unknown tags fail decoding; `none` in a role
is preserved as unresolved, never converted to a supported reference sort.
Every other supplied field is retained exactly, including list order. These
theorems concern the structured wire, not JSON parsing or cryptographic hashes.
-/

def encodeKind : RefKind → String
  | .person => "person" | .asset => "asset" | .obligation => "obligation"
  | .occurrence => "occurrence" | .proposition => "proposition"

def decodeKind (s : String) : Option RefKind :=
  if s = "person" then some .person
  else if s = "asset" then some .asset
  else if s = "obligation" then some .obligation
  else if s = "occurrence" then some .occurrence
  else if s = "proposition" then some .proposition
  else none

theorem kind_roundtrip (k : RefKind) : decodeKind (encodeKind k) = some k := by
  cases k <;> decide

theorem kind_decode_sound {s : String} {k : RefKind} (h : decodeKind s = some k) :
    encodeKind k = s := by
  unfold decodeKind at h
  split at h
  · cases h; simpa [encodeKind] using ‹s = "person"›.symm
  · split at h
    · cases h; simpa [encodeKind] using ‹s = "asset"›.symm
    · split at h
      · cases h; simpa [encodeKind] using ‹s = "obligation"›.symm
      · split at h
        · cases h; simpa [encodeKind] using ‹s = "occurrence"›.symm
        · split at h
          · cases h; simpa [encodeKind] using ‹s = "proposition"›.symm
          · contradiction

def decodeList {α β : Type} (f : α → Option β) : List α → Option (List β)
  | [] => some []
  | a :: as => do
    let b ← f a
    let bs ← decodeList f as
    pure (b :: bs)

theorem decodeList_encode {α β : Type} (enc : β → α) (dec : α → Option β)
    (h : ∀ b, dec (enc b) = some b) (bs : List β) :
    decodeList dec (bs.map enc) = some bs := by
  induction bs with
  | nil => rfl
  | cons b bs ih => simp [decodeList, h, ih]

theorem decodeList_sound {α β : Type} (enc : β → α) (dec : α → Option β)
    (sound : ∀ a b, dec a = some b → enc b = a)
    {as : List α} {bs : List β} (h : decodeList dec as = some bs) : bs.map enc = as := by
  induction as generalizing bs with
  | nil => simpa [decodeList] using h.symm
  | cons a as ih =>
    cases ha : dec a with
    | none => simp [decodeList, ha] at h
    | some b =>
      cases hs : decodeList dec as with
      | none => simp [decodeList, ha, hs] at h
      | some rest =>
        have he : b :: rest = bs := by simpa [decodeList, ha, hs] using h
        subst bs
        simp [sound a b ha, ih hs]

structure RoleWire where
  role : String
  kind : Option String
  deriving DecidableEq, Repr

def encodeRole (r : RoleSpec) : RoleWire := ⟨r.role, r.kind.map encodeKind⟩
def decodeRole (r : RoleWire) : Option RoleSpec :=
  match r.kind with
  | none => some ⟨r.role, none⟩
  | some s => (decodeKind s).map fun k => ⟨r.role, some k⟩

theorem role_roundtrip (r : RoleSpec) : decodeRole (encodeRole r) = some r := by
  rcases r with ⟨role, kind⟩
  cases kind <;> simp [encodeRole, decodeRole, kind_roundtrip]

theorem role_decode_sound {w : RoleWire} {r : RoleSpec} (h : decodeRole w = some r) :
    encodeRole r = w := by
  rcases w with ⟨role, kind⟩
  cases kind with
  | none => cases h; rfl
  | some s =>
    cases hk : decodeKind s with
    | none => simp [decodeRole, hk] at h
    | some k =>
      have he : (⟨role, some k⟩ : RoleSpec) = r := by simpa [decodeRole, hk] using h
      subst r
      simp [encodeRole, kind_decode_sound hk]

structure DefinitionWire where
  key : KindKey
  digest : List Nat
  roles : List RoleWire
  deriving DecidableEq, Repr

def encodeDefinition (d : Definition) : DefinitionWire := ⟨d.key, d.digest, d.roles.map encodeRole⟩
def decodeDefinition (w : DefinitionWire) : Option Definition :=
  (decodeList decodeRole w.roles).map fun roles => ⟨w.key, w.digest, roles⟩

theorem definition_roundtrip (d : Definition) : decodeDefinition (encodeDefinition d) = some d := by
  cases d
  simp [encodeDefinition, decodeDefinition, decodeList_encode _ _ role_roundtrip]

theorem definition_decode_sound {w : DefinitionWire} {d : Definition}
    (h : decodeDefinition w = some d) : encodeDefinition d = w := by
  cases hr : decodeList decodeRole w.roles with
  | none => simp [decodeDefinition, hr] at h
  | some roles =>
    have he : (⟨w.key, w.digest, roles⟩ : Definition) = d := by
      simpa [decodeDefinition, hr] using h
    subst d
    have hs := decodeList_sound encodeRole decodeRole (fun _ _ => role_decode_sound) hr
    cases w
    simp_all [encodeDefinition]

structure RefWire where
  kind : String
  symbol : Symbol
  deriving DecidableEq, Repr
def encodeRef (r : EntityRef) : RefWire := ⟨encodeKind r.kind, r.symbol⟩
def decodeRef (w : RefWire) : Option EntityRef :=
  (decodeKind w.kind).map fun k => ⟨k, w.symbol⟩
theorem ref_roundtrip (r : EntityRef) : decodeRef (encodeRef r) = some r := by
  cases r; simp [decodeRef, encodeRef, kind_roundtrip]
theorem ref_decode_sound {w : RefWire} {r : EntityRef} (h : decodeRef w = some r) :
    encodeRef r = w := by
  cases hk : decodeKind w.kind with
  | none => simp [decodeRef, hk] at h
  | some k =>
    have he : (⟨k, w.symbol⟩ : EntityRef) = r := by simpa [decodeRef, hk] using h
    subst r
    have hs := kind_decode_sound hk
    cases w
    simp_all [encodeRef]

structure ParameterWire where
  role : String
  kind : String
  deriving DecidableEq, Repr
def encodeParameter (p : Parameter) : ParameterWire := ⟨p.role, encodeKind p.kind⟩
def decodeParameter (w : ParameterWire) : Option Parameter :=
  (decodeKind w.kind).map fun k => ⟨w.role, k⟩
theorem parameter_roundtrip (p : Parameter) : decodeParameter (encodeParameter p) = some p := by
  cases p; simp [decodeParameter, encodeParameter, kind_roundtrip]
theorem parameter_decode_sound {w : ParameterWire} {p : Parameter}
    (h : decodeParameter w = some p) : encodeParameter p = w := by
  cases hk : decodeKind w.kind with
  | none => simp [decodeParameter, hk] at h
  | some k =>
    have he : (⟨w.role, k⟩ : Parameter) = p := by simpa [decodeParameter, hk] using h
    subst p
    have hs := kind_decode_sound hk
    cases w
    simp_all [encodeParameter]

structure OperandWire where
  role : String
  referent : RefWire
  deriving DecidableEq, Repr
def encodeOperand (p : Operand) : OperandWire := ⟨p.role, encodeRef p.referent⟩
def decodeOperand (w : OperandWire) : Option Operand :=
  (decodeRef w.referent).map fun r => ⟨w.role, r⟩
theorem operand_roundtrip (p : Operand) : decodeOperand (encodeOperand p) = some p := by
  cases p; simp [decodeOperand, encodeOperand, ref_roundtrip]
theorem operand_decode_sound {w : OperandWire} {p : Operand}
    (h : decodeOperand w = some p) : encodeOperand p = w := by
  cases hr : decodeRef w.referent with
  | none => simp [decodeOperand, hr] at h
  | some r =>
    have he : (⟨w.role, r⟩ : Operand) = p := by simpa [decodeOperand, hr] using h
    subst p
    have hs := ref_decode_sound hr
    cases w
    simp_all [encodeOperand]

structure OperationWire where
  symbol : Symbol
  parameters : List ParameterWire
  deriving DecidableEq, Repr
structure ActionWire where
  operation : OperationWire
  operands : List OperandWire
  deriving DecidableEq, Repr
def encodeAction (a : Action) : ActionWire :=
  ⟨⟨a.operation.symbol, a.operation.parameters.map encodeParameter⟩, a.operands.map encodeOperand⟩
def decodeAction (w : ActionWire) : Option Action := do
  let ps ← decodeList decodeParameter w.operation.parameters
  let args ← decodeList decodeOperand w.operands
  pure ⟨⟨w.operation.symbol, ps⟩, args⟩
theorem action_roundtrip (a : Action) : decodeAction (encodeAction a) = some a := by
  rcases a with ⟨⟨symbol, ps⟩, args⟩
  simp [decodeAction, encodeAction, decodeList_encode _ _ parameter_roundtrip,
    decodeList_encode _ _ operand_roundtrip]
theorem action_decode_sound {w : ActionWire} {a : Action}
    (h : decodeAction w = some a) : encodeAction a = w := by
  cases hp : decodeList decodeParameter w.operation.parameters with
  | none => simp [decodeAction, hp] at h
  | some ps =>
    cases ho : decodeList decodeOperand w.operands with
    | none => simp [decodeAction, hp, ho] at h
    | some args =>
      have he : (⟨⟨w.operation.symbol, ps⟩, args⟩ : Action) = a := by
        simpa [decodeAction, hp, ho] using h
      subst a
      have hs := decodeList_sound encodeParameter decodeParameter (fun _ _ => parameter_decode_sound) hp
      have ht := decodeList_sound encodeOperand decodeOperand (fun _ _ => operand_decode_sound) ho
      rcases w with ⟨⟨symbol, parameters⟩, operands⟩
      simp_all [encodeAction]

structure QualificationWire where
  predicate : Symbol
  version : Nat
  arguments : List RefWire
  polarity : Bool
  mention : Symbol
  deriving DecidableEq, Repr
def encodeQualification (q : Qualification) : QualificationWire :=
  ⟨q.predicate, q.version, q.arguments.map encodeRef, q.polarity, q.mention⟩
def decodeQualification (w : QualificationWire) : Option Qualification :=
  (decodeList decodeRef w.arguments).map fun args =>
    ⟨w.predicate, w.version, args, w.polarity, w.mention⟩
theorem qualification_roundtrip (q : Qualification) :
    decodeQualification (encodeQualification q) = some q := by
  cases q
  simp [decodeQualification, encodeQualification, decodeList_encode _ _ ref_roundtrip]
theorem qualification_decode_sound {w : QualificationWire} {q : Qualification}
    (h : decodeQualification w = some q) : encodeQualification q = w := by
  cases ha : decodeList decodeRef w.arguments with
  | none => simp [decodeQualification, ha] at h
  | some args =>
    have he : (⟨w.predicate, w.version, args, w.polarity, w.mention⟩ : Qualification) = q := by
      simpa [decodeQualification, ha] using h
    subst q
    have hs := decodeList_sound encodeRef decodeRef (fun _ _ => ref_decode_sound) ha
    cases w
    simp_all [encodeQualification]

structure EnvelopeWire where
  key : KindKey
  definitionDigest : List Nat
  registrySnapshot : Nat
  qualifications : List QualificationWire
  context : Snapshot
  action : ActionWire
  deriving DecidableEq, Repr
def encodeEnvelope (e : Envelope) : EnvelopeWire :=
  ⟨e.key, e.definitionDigest, e.registrySnapshot, e.qualifications.map encodeQualification,
   e.context, encodeAction e.action⟩
def decodeEnvelope (w : EnvelopeWire) : Option Envelope := do
  let qs ← decodeList decodeQualification w.qualifications
  let act ← decodeAction w.action
  pure ⟨w.key, w.definitionDigest, w.registrySnapshot, qs, w.context, act⟩
theorem envelope_roundtrip (e : Envelope) : decodeEnvelope (encodeEnvelope e) = some e := by
  cases e
  simp [decodeEnvelope, encodeEnvelope, decodeList_encode _ _ qualification_roundtrip,
    action_roundtrip]
theorem envelope_decode_sound {w : EnvelopeWire} {e : Envelope}
    (h : decodeEnvelope w = some e) : encodeEnvelope e = w := by
  cases hq : decodeList decodeQualification w.qualifications with
  | none => simp [decodeEnvelope, hq] at h
  | some qs =>
    cases ha : decodeAction w.action with
    | none => simp [decodeEnvelope, hq, ha] at h
    | some act =>
      have he : (⟨w.key, w.definitionDigest, w.registrySnapshot, qs, w.context, act⟩ : Envelope) = e := by
        simpa [decodeEnvelope, hq, ha] using h
      subst e
      have hs := decodeList_sound encodeQualification decodeQualification
        (fun _ _ => qualification_decode_sound) hq
      have ht := action_decode_sound ha
      cases w
      simp_all [encodeEnvelope]

end Usul.IDA.ActRegistry
