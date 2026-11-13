import Usul.Typing.IDAActRegistry

/-!
# Candidate-only act intake

The caller supplies references and attributed qualifications, never an operation
signature or source-admission capability. Preparation derives the operation from
the complete supplied registry and invokes its existing structural resolver.
A prepared draft proves shape and exact data retention. It contains no ruling,
source premise, admission authority, application grant, or source receipt.
-/

namespace Usul.IDA.ActIntake

open ActRegistry

structure Input where
  key : KindKey
  definitionDigest : List Nat
  registrySnapshot : Nat
  qualifications : List Qualification
  context : Snapshot
  operands : List Operand
  deriving DecidableEq, Repr

def Input.toEnvelope (i : Input) (operation : Operation) : Envelope :=
  ⟨i.key, i.definitionDigest, i.registrySnapshot, i.qualifications, i.context,
    ⟨operation, i.operands⟩⟩

/-- Registry-indexed structural evidence, with the entire original input. -/
structure PreparedDraft (r : Registry) where
  input : Input
  envelope : Envelope
  definition : Definition
  retained : envelope = input.toEnvelope envelope.action.operation
  checked : resolve r envelope = .ok definition

/-- Select the operation only after checking the whole registry and exact pins.
The diagnostic precedence is the existing resolver's precedence. -/
def selectOperation (r : Registry) (i : Input) : Except Failure Operation :=
  if ¬ r.Unique then .error .registryConflict
  else if ¬ r.Shaped then .error .malformedRegistry
  else if i.registrySnapshot ≠ r.snapshot then .error .registrySnapshotMismatch
  else match matchingDefinitions r i.key with
    | [] => .error .unknownKind
    | [d] =>
      if i.definitionDigest ≠ d.digest then .error .digestMismatch
      else match resolveRoles d.roles with
        | none => .error .unresolvedRole
        | some parameters => .ok ⟨d.key.symbol, parameters⟩
    | _ :: _ :: _ => .error .registryConflict

def prepare (r : Registry) (i : Input) : Except Failure (PreparedDraft r) :=
  match selectOperation r i with
  | .error failure => .error failure
  | .ok operation =>
    let envelope := i.toEnvelope operation
    match h : resolve r envelope with
    | .error failure => .error failure
    | .ok definition => .ok ⟨i, envelope, definition, rfl, h⟩

def prepareCode (r : Registry) (i : Input) : Nat := resultCode (prepare r i)

def PreparedDraft.target {r : Registry} (d : PreparedDraft r) : Target :=
  ⟨.perform d.envelope.action, (resolve_wellFormed d.checked).1⟩

/-- Preparation never replaces the supplied references or metadata. -/
theorem prepare_retains_input {r : Registry} {i : Input} {draft : PreparedDraft r}
    (h : prepare r i = .ok draft) : draft.input = i := by
  unfold prepare at h
  split at h
  · contradiction
  · dsimp only at h
    split at h
    · contradiction
    · cases h
      rfl

theorem prepared_fields {r : Registry} (draft : PreparedDraft r) :
    draft.envelope.key = draft.input.key ∧
    draft.envelope.definitionDigest = draft.input.definitionDigest ∧
    draft.envelope.registrySnapshot = draft.input.registrySnapshot ∧
    draft.envelope.qualifications = draft.input.qualifications ∧
    draft.envelope.context = draft.input.context ∧
    draft.envelope.action.operands = draft.input.operands := by
  have h := draft.retained
  exact ⟨congrArg Envelope.key h, congrArg Envelope.definitionDigest h,
    congrArg Envelope.registrySnapshot h, congrArg Envelope.qualifications h,
    congrArg Envelope.context h, congrArg (fun e => e.action.operands) h⟩

theorem prepare_preserves_fields {r : Registry} {i : Input} {draft : PreparedDraft r}
    (h : prepare r i = .ok draft) :
    draft.envelope.key = i.key ∧
    draft.envelope.definitionDigest = i.definitionDigest ∧
    draft.envelope.registrySnapshot = i.registrySnapshot ∧
    draft.envelope.qualifications = i.qualifications ∧
    draft.envelope.context = i.context ∧ draft.envelope.action.operands = i.operands := by
  simpa [prepare_retains_input h] using prepared_fields draft

theorem prepared_resolves {r : Registry} (draft : PreparedDraft r) :
    resolve r draft.envelope = .ok draft.definition := draft.checked

theorem prepared_registered {r : Registry} (draft : PreparedDraft r) :
    draft.definition ∈ r.definitions ∧ draft.definition.key = draft.input.key := by
  have h := resolve_registered draft.checked
  exact ⟨h.1, h.2.trans (prepared_fields draft).1⟩

theorem prepared_signature {r : Registry} (draft : PreparedDraft r) :
    ∃ parameters, resolveRoles draft.definition.roles = some parameters ∧
      draft.envelope.action.operation = ⟨draft.definition.key.symbol, parameters⟩ ∧
      draft.input.operands.map Operand.parameter = parameters := by
  rcases resolve_schema draft.checked with ⟨ps, hp, ho, ha⟩
  exact ⟨ps, hp, ho, by simpa [(prepared_fields draft).2.2.2.2.2] using ha⟩

theorem prepared_role_order {r : Registry} (draft : PreparedDraft r) :
    draft.definition.roles = draft.input.operands.map
      (fun o => (⟨o.role, some o.referent.kind⟩ : RoleSpec)) := by
  simpa [(prepared_fields draft).2.2.2.2.2] using resolve_declared_schema draft.checked

theorem prepared_pins {r : Registry} (draft : PreparedDraft r) :
    draft.input.key = draft.definition.key ∧
    draft.input.definitionDigest = draft.definition.digest ∧
    draft.input.registrySnapshot = r.snapshot := by
  rcases (resolve_iff r draft.envelope draft.definition).mp draft.checked with
    ⟨_, _, hs, _, hd, _⟩
  have hf := prepared_fields draft
  exact ⟨(prepared_registered draft).2.symm, hf.2.1.symm.trans hd,
    hf.2.2.1.symm.trans hs⟩

theorem prepared_wellFormed {r : Registry} (draft : PreparedDraft r) :
    draft.envelope.WellFormed := resolve_wellFormed draft.checked

theorem prepared_unique {r : Registry} (draft : PreparedDraft r) {other : Definition}
    (hm : other ∈ r.definitions) (hk : other.key = draft.input.key) :
    other = draft.definition :=
  resolve_unique draft.checked hm (hk.trans (prepared_fields draft).1.symm)

theorem prepared_target_exact {r : Registry} (draft : PreparedDraft r) :
    draft.target.expression = .perform draft.envelope.action := rfl

/-- An unresolved registered role cannot be repaired by caller-supplied operands. -/
theorem unresolved_rejected {r : Registry} {i : Input} {d : Definition}
    (hm : matchingDefinitions r i.key = [d]) (hu : resolveRoles d.roles = none) :
    ∀ draft : PreparedDraft r, prepare r i ≠ .ok draft := by
  intro draft h
  have hi := prepare_retains_input h
  have hk : draft.envelope.key = i.key := (prepared_fields draft).1.trans (congrArg Input.key hi)
  have hd := (resolve_iff r draft.envelope draft.definition).mp draft.checked |>.2.2.2.1
  rw [hk, hm] at hd
  have he : d = draft.definition := by simpa using hd
  exact unresolved_not_resolved (r := r) (e := draft.envelope) (he ▸ hu) draft.checked

theorem conflict_precedes_input (r : Registry) (i : Input) (h : ¬ r.Unique) :
    prepare r i = .error .registryConflict := by simp [prepare, selectOperation, h]

/-- Different retained qualifications cannot become one prepared envelope. -/
theorem qualifications_distinguished {r s : Registry}
    (a : PreparedDraft r) (b : PreparedDraft s)
    (h : a.input.qualifications ≠ b.input.qualifications) : a.envelope ≠ b.envelope := by
  intro he
  exact h ((prepared_fields a).2.2.2.1.symm.trans
    ((congrArg Envelope.qualifications he).trans (prepared_fields b).2.2.2.1))

/-- Same-sort reference substitutions remain distinct in the retained description. -/
theorem operands_distinguished {r s : Registry}
    (a : PreparedDraft r) (b : PreparedDraft s)
    (h : a.input.operands ≠ b.input.operands) : a.envelope ≠ b.envelope := by
  intro he
  exact h ((prepared_fields a).2.2.2.2.2.symm.trans
    ((congrArg (fun e => e.action.operands) he).trans (prepared_fields b).2.2.2.2.2))

end Usul.IDA.ActIntake
