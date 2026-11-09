import Usul.Typing.IDAActRegistry

/-!
# ACT-01: exact contextual identity

This is a ground fragment. Qualifications are attributed syntax, and policy,
evidence, and clock pins are supplied identities. Validation returns a structural
witness only. Source admission stays with the existing derivation evaluator.
-/

namespace Usul.IDA.Context

open ActRegistry (KindKey Qualification Envelope Registry)

def versioned (key : KindKey) : Prop := key.symbol.WellFormed ∧ 0 < key.version
instance (key : KindKey) : Decidable (versioned key) := by
  unfold versioned
  infer_instance

structure PredicateDefinition where
  key : KindKey
  arguments : List RefKind
  deriving DecidableEq, Repr

structure Vocabulary where
  pin : KindKey
  definitions : List PredicateDefinition
  deriving DecidableEq, Repr

def Vocabulary.WellFormed (v : Vocabulary) : Prop :=
  versioned v.pin ∧ (v.definitions.map PredicateDefinition.key).Nodup ∧
    ∀ d ∈ v.definitions, versioned d.key

instance (v : Vocabulary) : Decidable v.WellFormed := by
  unfold Vocabulary.WellFormed
  infer_instance

def matchingPredicates (v : Vocabulary) (q : Qualification) : List PredicateDefinition :=
  v.definitions.filter fun d => d.key == ⟨q.predicate, q.version⟩

/-- Ordered argument sorts and exact version are checked, independently of polarity. -/
def Typed (v : Vocabulary) (q : Qualification) : Prop :=
  q.WellFormed ∧
    matchingPredicates v q = [⟨⟨q.predicate, q.version⟩, q.arguments.map EntityRef.kind⟩]

instance (v : Vocabulary) (q : Qualification) : Decidable (Typed v q) := by
  unfold Typed
  infer_instance

inductive Perspective where
  | asKnown | retrospective
  deriving DecidableEq, Repr

structure TimeView where
  clockVersion : Nat
  cutoff : Nat
  perspective : Perspective
  deriving DecidableEq, Repr

/-- The pilot has one clock. Recording is distinct from actor awareness. -/
def TimeView.Matches (t : TimeView) (m : ActRegistry.Snapshot) : Prop :=
  0 < t.clockVersion ∧ m.recordedAt ≤ t.cutoff ∧
    (match t.perspective with
     | .asKnown => t.cutoff = m.effectiveAt
     | .retrospective => m.effectiveAt < t.cutoff)

instance (t : TimeView) (m : ActRegistry.Snapshot) : Decidable (t.Matches m) := by
  cases t with
  | mk version cutoff perspective =>
    cases perspective <;> unfold TimeView.Matches <;> infer_instance

structure Inquiry where
  questionId : Nat
  question : Question
  scope : Judgment.Scope
  accountable : EntityRef
  performer : Operand
  deriving DecidableEq, Repr

/-- Canonical structural payload for schema v1. Lists are ordered, including
attributed qualification lists. No digest, normalization, or alias can replace
comparison of the full value. -/
structure Snapshot where
  key : KindKey
  vocabulary : Vocabulary
  admissionPolicy : KindKey
  envelope : Envelope
  time : TimeView
  inquiry : Inquiry
  opportunity : Option Opportunity
  deriving DecidableEq, Repr

/-- Versioned canonical typed wire. The existing registry codec handles the
envelope; all other fields keep their exact structural representation. -/
structure SnapshotWire where
  format : String
  key : KindKey
  vocabulary : Vocabulary
  admissionPolicy : KindKey
  envelope : ActRegistry.EnvelopeWire
  time : TimeView
  inquiry : Inquiry
  opportunity : Option Opportunity
  deriving DecidableEq, Repr

def wireFormat : String := "usul.ida.context.v1"

def encode (s : Snapshot) : SnapshotWire :=
  ⟨wireFormat, s.key, s.vocabulary, s.admissionPolicy, ActRegistry.encodeEnvelope s.envelope,
    s.time, s.inquiry, s.opportunity⟩

def decode (w : SnapshotWire) : Option Snapshot :=
  if w.format = wireFormat then
    (ActRegistry.decodeEnvelope w.envelope).map fun e =>
      ⟨w.key, w.vocabulary, w.admissionPolicy, e, w.time, w.inquiry, w.opportunity⟩
  else none

theorem decode_encode (s : Snapshot) : decode (encode s) = some s := by
  cases s
  simp [decode, encode, ActRegistry.envelope_roundtrip]

theorem encode_decode {w : SnapshotWire} {s : Snapshot} (h : decode w = some s) :
    encode s = w := by
  by_cases hf : w.format = wireFormat
  · cases he : ActRegistry.decodeEnvelope w.envelope with
    | none => simp [decode, hf, he] at h
    | some e =>
      simp [decode, hf, he] at h
      subst s
      have hw := ActRegistry.envelope_decode_sound he
      cases w
      simp_all [encode]
  · simp [decode, hf] at h

theorem encode_injective {s t : Snapshot} (h : encode s = encode t) : s = t := by
  simpa [decode_encode] using congrArg decode h

def Snapshot.target (s : Snapshot) : TargetExpr :=
  match s.opportunity with
  | none => .perform s.envelope.action
  | some o => .omit s.envelope.action o

def Snapshot.coordinates (s : Snapshot) : Nat × Nat :=
  (s.envelope.context.contextId, s.envelope.context.timeId)

def Snapshot.InquiryExact (s : Snapshot) : Prop :=
  let scope := s.inquiry.scope
  let m := s.envelope.context
  scope.target = .structured s.target ∧
    (scope.context, scope.time) = s.coordinates ∧
    scope.profile = m.profile ∧ scope.profileVersion = m.profileVersion

instance (s : Snapshot) : Decidable s.InquiryExact := by
  unfold Snapshot.InquiryExact
  infer_instance

def Snapshot.ParticipantsExact (s : Snapshot) : Prop :=
  s.inquiry.accountable.WellFormed ∧ s.inquiry.accountable.kind = .person ∧
    s.inquiry.performer.referent.kind = .person ∧
    s.inquiry.performer ∈ s.envelope.action.operands

instance (s : Snapshot) : Decidable s.ParticipantsExact := by
  unfold Snapshot.ParticipantsExact
  infer_instance

def Snapshot.Temporal (s : Snapshot) : Prop :=
  s.time.Matches s.envelope.context ∧
    ∀ o ∈ s.opportunity.toList, o.WellFormed ∧ o.clock = s.envelope.context.clock

instance (s : Snapshot) : Decidable s.Temporal := by
  unfold Snapshot.Temporal
  infer_instance

def Snapshot.WellFormed (r : Registry) (s : Snapshot) : Prop :=
  versioned s.key ∧ versioned s.admissionPolicy ∧ s.vocabulary.WellFormed ∧
    (∀ q ∈ s.envelope.qualifications, Typed s.vocabulary q) ∧
    (ActRegistry.resolve r s.envelope).isOk = true ∧
    s.InquiryExact ∧ s.ParticipantsExact ∧ s.Temporal

instance (r : Registry) (s : Snapshot) : Decidable (s.WellFormed r) := by
  unfold Snapshot.WellFormed
  infer_instance

/-- This phase is an interval calculation only. At closing time the opportunity
is closed. No observation or nonperformance follows from the phase. -/
def phase (o : Opportunity) (tick : Nat) : Nat :=
  if tick < o.opensAt then 0 else if tick < o.closesAt then 1 else 2

abbrev Catalog := List Snapshot

def Catalog.Unambiguous (c : Catalog) : Prop :=
  (c.map Snapshot.key).Nodup ∧ (c.map Snapshot.coordinates).Nodup

instance (c : Catalog) : Decidable c.Unambiguous := by
  unfold Catalog.Unambiguous
  infer_instance

def Snapshot.clockIdentity (s : Snapshot) : Symbol × Nat :=
  (s.envelope.context.clock, s.time.clockVersion)

def Snapshot.effectiveIdentity (s : Snapshot) : (Symbol × Nat) × Nat :=
  (s.clockIdentity, s.envelope.context.effectiveAt)

def Catalog.Consistent (c : Catalog) : Prop :=
  (∀ s ∈ c, ∀ t ∈ c, s.vocabulary.pin = t.vocabulary.pin → s.vocabulary = t.vocabulary) ∧
    (∀ s ∈ c, ∀ t ∈ c, s.coordinates.2 = t.coordinates.2 →
      s.effectiveIdentity = t.effectiveIdentity) ∧
    let definitions := c.flatMap fun s => s.vocabulary.definitions
    ∀ d ∈ definitions, ∀ e ∈ definitions, d.key = e.key → d = e

instance (c : Catalog) : Decidable c.Consistent := by
  unfold Catalog.Consistent
  infer_instance

def matching (c : Catalog) (coordinates : Nat × Nat) : Catalog :=
  c.filter fun s => s.coordinates == coordinates

inductive Failure where
  | ambiguous | missing | stale | malformed | inquiryMismatch | definitionConflict
  deriving DecidableEq, Repr

/-- The caller names the complete expected snapshot. The catalog is supplied
independently. No implicit interpretation exists for an unmapped legacy pair. -/
def resolve (r : Registry) (c : Catalog) (expected : Snapshot) : Except Failure Snapshot :=
  if ¬ c.Unambiguous then .error .ambiguous
  else if ¬ c.Consistent then .error .definitionConflict
  else match matching c expected.coordinates with
    | [] => .error .missing
    | [actual] =>
      if actual ≠ expected then .error .stale
      else if ¬ actual.WellFormed r then .error .malformed
      else .ok actual
    | _ :: _ :: _ => .error .ambiguous

def Snapshot.MatchesPremise (s : Snapshot) (p : Derivation.Premise) : Prop :=
  p.questionId = s.inquiry.questionId ∧
    p.request.record.questionCode = Judgment.encodeQuestion s.inquiry.question ∧
    p.request.record.scope = s.inquiry.scope ∧ s.envelope.context.Matches p

instance (s : Snapshot) (p : Derivation.Premise) : Decidable (s.MatchesPremise p) := by
  unfold Snapshot.MatchesPremise
  infer_instance

/-- A structural receipt retains the exact snapshot and untouched premise.
There is no source or evidential admission in this result. -/
structure BindingReceipt where
  snapshot : Snapshot
  premise : Derivation.Premise
  deriving DecidableEq, Repr

def bind (r : Registry) (c : Catalog) (s : Snapshot) (p : Derivation.Premise) :
    Except Failure BindingReceipt :=
  match resolve r c s with
  | .error why => .error why
  | .ok actual =>
    if actual.MatchesPremise p then .ok ⟨actual, p⟩ else .error .inquiryMismatch

theorem resolve_iff (r : Registry) (c : Catalog) (expected actual : Snapshot) :
    resolve r c expected = .ok actual ↔
    (c.Unambiguous ∧ c.Consistent) ∧ matching c expected.coordinates = [expected] ∧
      expected.WellFormed r ∧ actual = expected := by
  by_cases hu : c.Unambiguous
  · by_cases hc : c.Consistent
    · cases hm : matching c expected.coordinates with
      | nil => simp [resolve, hu, hc, hm]
      | cons head tail =>
        cases tail with
        | nil =>
          by_cases he : head = expected
          · subst head
            by_cases hw : expected.WellFormed r <;> simp [resolve, hu, hc, hm, hw, eq_comm]
          · simp [resolve, hu, hc, hm, he]
        | cons next tail => simp [resolve, hu, hc, hm]
    · simp [resolve, hu, hc]
  · simp [resolve, hu]

theorem resolve_unique {r : Registry} {c : Catalog} {expected actual other : Snapshot}
    (h : resolve r c expected = .ok actual) (hm : other ∈ c)
    (hc : other.coordinates = expected.coordinates) : other = actual := by
  rcases (resolve_iff r c expected actual).mp h with ⟨_, hs, _, he⟩
  subst actual
  have : other ∈ matching c expected.coordinates := by simp [matching, hm, hc]
  simpa [hs] using this

theorem resolve_rigid {r : Registry} {c : Catalog} {expected actual : Snapshot}
    (h : resolve r c expected = .ok actual) :
    actual.target = expected.target ∧
      actual.inquiry.accountable = expected.inquiry.accountable ∧
      actual.inquiry.performer = expected.inquiry.performer ∧ actual.time = expected.time := by
  rw [(resolve_iff r c expected actual).mp h |>.2.2.2]
  exact ⟨rfl, rfl, rfl, rfl⟩

theorem changed_snapshot_stale {r : Registry} {c : Catalog} {old current : Snapshot}
    (h : resolve r c current = .ok current) (hc : old.coordinates = current.coordinates)
    (hd : old ≠ current) : resolve r c old = .error .stale := by
  rcases (resolve_iff r c current current).mp h with ⟨⟨hu, hv⟩, hm, _, _⟩
  simp [resolve, hu, hv, hc, hm, Ne.symm hd]

theorem changed_qualification_stale {r : Registry} {c : Catalog} {old current : Snapshot}
    (h : resolve r c current = .ok current) (hc : old.coordinates = current.coordinates)
    (hq : old.envelope.qualifications ≠ current.envelope.qualifications) :
    resolve r c old = .error .stale :=
  changed_snapshot_stale h hc (fun he => hq (congrArg (fun s => s.envelope.qualifications) he))

/-- Resolution cannot factor through the target projection when that projection
forgets a changed qualification. This concerns structural resolution only. -/
theorem no_target_factorization {r : Registry} {c : Catalog} {old current : Snapshot}
    (h : resolve r c current = .ok current) (hc : old.coordinates = current.coordinates)
    (ht : old.target = current.target)
    (hq : old.envelope.qualifications ≠ current.envelope.qualifications) :
    ¬ ∃ f : TargetExpr → Except Failure Snapshot, ∀ s, resolve r c s = f s.target := by
  rintro ⟨f, hf⟩
  have hs := changed_qualification_stale h hc hq
  have he := (hf old).trans ((congrArg f ht).trans (hf current).symm)
  rw [hs, h] at he
  contradiction

theorem typed_arguments {v : Vocabulary} {q : Qualification} {d : PredicateDefinition}
    (ht : Typed v q) (hm : d ∈ v.definitions) (hk : d.key = ⟨q.predicate, q.version⟩) :
    q.arguments.map EntityRef.kind = d.arguments := by
  have hd : d ∈ matchingPredicates v q := by simp [matchingPredicates, hm, hk]
  rw [ht.2] at hd
  simp only [List.mem_singleton] at hd
  exact (congrArg PredicateDefinition.arguments hd).symm

theorem bind_iff {r : Registry} {c : Catalog} {s : Snapshot} {p : Derivation.Premise} {result : BindingReceipt} :
    bind r c s p = .ok result ↔
    resolve r c s = .ok s ∧ s.MatchesPremise p ∧ result = ⟨s, p⟩ := by
  cases hr : resolve r c s with
  | error why => simp [bind, hr]
  | ok actual =>
    have he := (resolve_iff r c s actual).mp hr |>.2.2.2
    subst actual
    by_cases hb : s.MatchesPremise p <;> simp [bind, hr, hb, eq_comm]

theorem ambiguous_rejected (r : Registry) (c : Catalog) (s : Snapshot)
    (h : ¬ c.Unambiguous) : resolve r c s = .error .ambiguous := by
  simp [resolve, h]

theorem inconsistent_rejected (r : Registry) (c : Catalog) (s : Snapshot)
    (hu : c.Unambiguous) (h : ¬ c.Consistent) :
    resolve r c s = .error .definitionConflict := by
  simp [resolve, hu, h]

theorem time_identity_unique {r : Registry} {c : Catalog} {s t : Snapshot}
    (hs : resolve r c s = .ok s) (ht : resolve r c t = .ok t)
    (hi : s.coordinates.2 = t.coordinates.2) : s.effectiveIdentity = t.effectiveIdentity := by
  have member (x : Snapshot) (h : resolve r c x = .ok x) : x ∈ c := by
    have hm := ((resolve_iff r c x x).mp h).2.1
    have hx : x ∈ matching c x.coordinates := by simp [hm]
    exact (List.mem_filter.mp hx).1
  exact ((resolve_iff r c s s).mp hs).1.2.2.1 s (member s hs) t (member t ht) hi

theorem omission_clock {r : Registry} {c : Catalog} {s : Snapshot} {o : Opportunity}
    (h : resolve r c s = .ok s) (ho : s.opportunity = some o) :
    o.WellFormed ∧ o.clock = s.envelope.context.clock := by
  rcases ((resolve_iff r c s s).mp h).2.2.1 with ⟨_, _, _, _, _, _, _, temporal⟩
  exact temporal.2 o (by simp [ho])

theorem resolved_target_wellFormed {r : Registry} {c : Catalog} {s : Snapshot}
    (h : resolve r c s = .ok s) : s.target.WellFormed := by
  rcases ((resolve_iff r c s s).mp h).2.2.1 with ⟨_, _, _, _, resolved, _⟩
  have ha : s.envelope.action.WellFormed := by
    cases hd : ActRegistry.resolve r s.envelope with
    | error reason => simp [hd, Except.isOk, Except.toBool] at resolved
    | ok d => exact (ActRegistry.resolve_wellFormed hd).1
  cases ho : s.opportunity with
  | none => simpa [Snapshot.target, ho, TargetExpr.WellFormed] using ha
  | some o => simpa [Snapshot.target, ho, TargetExpr.WellFormed] using
      And.intro ha (omission_clock h ho).1

theorem phase_closes {o : Opportunity} (h : o.WellFormed) :
    phase o o.closesAt = 2 := by
  simp [phase, Nat.not_lt.mpr (Nat.le_of_lt h.2.2)]

end Usul.IDA.Context
