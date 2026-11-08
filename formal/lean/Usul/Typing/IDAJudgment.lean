import Usul.IDA
import Usul.Judgement

/-!
# Question-indexed IDA records and registry binding

This module checks record shape, answer typing, and exact agreement with a
separately supplied registry snapshot. Digests are supplied byte sequences;
their equality does not authenticate source bytes or establish interpretation.
The registry's admission decisions and the meaning of premise and rule IDs
remain external inputs. All fixtures at the end of the module are synthetic.
-/

namespace Usul.IDA.Judgment

/- The answer family extends exact taklifi answers to nonempty constraints. -/
def Answer : Question → Type
  | .taklifi => Constraint
  | .wadi s => s.Value

instance (q : Question) : DecidableEq (Answer q) := by
  cases q <;> unfold Answer <;> infer_instance

inductive Payload (α : Type) where
  | noRuling
  | suspended
  | known (answer : α)
  deriving DecidableEq

def knownExact : (q : Question) → q.Answer → Payload (Answer q)
  | .taklifi, h => .known (Constraint.singleton h)
  | .wadi _, a => .known a

def ofInput : Input → Payload (Answer .taklifi)
  | .noRuling => .noRuling
  | .suspended => .suspended
  | .known c => .known c

inductive TargetKind where
  | behavior | affect
  deriving DecidableEq, Repr

structure Scope where
  subjectId : Nat
  subject : Subject
  targetId : Nat
  targetKind : TargetKind
  context : Nat
  time : Nat
  profile : Nat
  profileVersion : Nat
  domain : Domain
  deriving DecidableEq, Repr

structure SourceRef where
  sourceId : Nat
  sourceHash : List Nat
  sourceBytes : Nat
  passageStart : Nat
  passageEnd : Nat
  passageHash : List Nat
  deriving DecidableEq, Repr

structure Provenance where
  source : SourceRef
  interpretationId : Nat
  interpretationVersion : Nat
  grade : Grade
  rujhanKnown : Bool
  dalil : List DalilKind
  premises : List Nat
  ruleId : Nat
  implementationRevision : String
  deriving DecidableEq, Repr

structure RawRecord where
  questionCode : Nat
  answerCode : Nat
  scope : Scope
  provenance : Provenance
  deriving DecidableEq, Repr

structure Record where
  question : Question
  payload : Payload (Answer question)
  scope : Scope
  provenance : Provenance
  deriving DecidableEq

def DigestShape (digest : List Nat) : Prop :=
  digest.length = 32 ∧ ∀ b ∈ digest, b < 256

instance (digest : List Nat) : Decidable (DigestShape digest) := by
  unfold DigestShape
  infer_instance

def SourceRef.WellFormed (source : SourceRef) : Prop :=
  DigestShape source.sourceHash ∧ DigestShape source.passageHash ∧
  source.passageStart < source.passageEnd ∧ source.passageEnd ≤ source.sourceBytes

instance (source : SourceRef) : Decidable source.WellFormed := by
  unfold SourceRef.WellFormed
  infer_instance

def Provenance.WellFormed (p : Provenance) : Prop :=
  p.source.WellFormed ∧ p.implementationRevision ≠ ""

instance (p : Provenance) : Decidable p.WellFormed := by
  unfold Provenance.WellFormed
  infer_instance

def Record.WellTyped (r : Record) : Prop :=
  r.provenance.dalil ≠ [] ∧ (r.question = .taklifi → r.scope.subject.IsMukallaf)

instance (r : Record) : Decidable r.WellTyped := by
  unfold Record.WellTyped
  infer_instance

def encodeQuestion : Question → Nat
  | .taklifi => 0
  | .wadi .sabab => 1
  | .wadi .shart => 2
  | .wadi .mani => 3
  | .wadi .validity => 4

def decodeQuestion : Nat → Option Question
  | 0 => some .taklifi
  | 1 => some (.wadi .sabab)
  | 2 => some (.wadi .shart)
  | 3 => some (.wadi .mani)
  | 4 => some (.wadi .validity)
  | _ => none

def encodeKnown : (q : Question) → Answer q → Nat
  | .taklifi, c => encodeSet c.set
  | .wadi .sabab, false => 33
  | .wadi .sabab, true => 34
  | .wadi .shart, false => 33
  | .wadi .shart, true => 34
  | .wadi .mani, false => 33
  | .wadi .mani, true => 34
  | .wadi .validity, .fasid => 35
  | .wadi .validity, .sahih => 36

def encodePayload (q : Question) : Payload (Answer q) → Nat
  | .noRuling => 0
  | .suspended => 32
  | .known a => encodeKnown q a

def decodeBool (code : Nat) : Option Bool :=
  if code = 33 then some false else if code = 34 then some true else none

def decodeValidity (code : Nat) : Option Validity :=
  if code = 35 then some .fasid else if code = 36 then some .sahih else none

def decodeKnown : (q : Question) → Nat → Option (Answer q)
  | .taklifi, code => decodeConstraint code
  | .wadi .sabab, code => decodeBool code
  | .wadi .shart, code => decodeBool code
  | .wadi .mani, code => decodeBool code
  | .wadi .validity, code => decodeValidity code

def decodePayload (q : Question) (code : Nat) : Option (Payload (Answer q)) :=
  if code = 0 then some .noRuling
  else if code = 32 then some .suspended
  else (decodeKnown q code).map Payload.known

def encodeRecord (r : Record) : RawRecord :=
  ⟨encodeQuestion r.question, encodePayload r.question r.payload, r.scope, r.provenance⟩

def decodeRecord (r : RawRecord) : Option Record := do
  let q ← decodeQuestion r.questionCode
  let p ← decodePayload q r.answerCode
  pure ⟨q, p, r.scope, r.provenance⟩

theorem question_roundtrip (q : Question) : decodeQuestion (encodeQuestion q) = some q := by
  cases q with
  | taklifi => rfl
  | wadi s => cases s <;> rfl

theorem question_decode_sound {code : Nat} {q : Question}
    (h : decodeQuestion code = some q) : encodeQuestion q = code := by
  cases code with
  | zero => cases h; rfl
  | succ code =>
    cases code with
    | zero => cases h; rfl
    | succ code =>
      cases code with
      | zero => cases h; rfl
      | succ code =>
        cases code with
        | zero => cases h; rfl
        | succ code =>
          cases code with
          | zero => cases h; rfl
          | succ code => contradiction

theorem constraint_roundtrip (c : Constraint) :
    decodeConstraint (encodeSet c.set) = some c := by
  rcases c with ⟨⟨h, k, m, n, w⟩, hn⟩
  cases h <;> cases k <;> cases m <;> cases n <;> cases w <;>
    simp_all [encodeSet, decodeConstraint, decodeSet, HukmSet.Nonempty,
      Nat.testBit_succ]
  simp only [HukmSet.Nonempty, Bool.false_eq_true, or_self] at hn

theorem constraint_code_bounds (c : Constraint) :
    1 ≤ encodeSet c.set ∧ encodeSet c.set ≤ 31 := by
  rcases c with ⟨⟨h, k, m, n, w⟩, hn⟩
  cases h <;> cases k <;> cases m <;> cases n <;> cases w <;>
    simp_all [encodeSet]
  simp only [HukmSet.Nonempty, Bool.false_eq_true, or_self] at hn

theorem mask_decode_encode : ∀ n : Fin 32, encodeSet (decodeSet n.val) = n.val := by
  decide

theorem constraint_decode_sound {code : Nat} {c : Constraint}
    (h : decodeConstraint code = some c) : encodeSet c.set = code := by
  unfold decodeConstraint at h
  split at h
  · rename_i hb
    split at h
    · cases h
      exact mask_decode_encode ⟨code, by omega⟩
    · contradiction
  · contradiction

theorem known_roundtrip (q : Question) (a : Answer q) :
    decodeKnown q (encodeKnown q a) = some a := by
  cases q with
  | taklifi => exact constraint_roundtrip a
  | wadi s =>
    cases s <;> cases a <;> rfl

theorem known_code_not_status (q : Question) (a : Answer q) :
    encodeKnown q a ≠ 0 ∧ encodeKnown q a ≠ 32 := by
  cases q with
  | taklifi =>
    have h := constraint_code_bounds a
    change encodeSet a.set ≠ 0 ∧ encodeSet a.set ≠ 32
    omega
  | wadi s => cases s <;> cases a <;> decide

theorem known_decode_sound {q : Question} {code : Nat} {a : Answer q}
    (h : decodeKnown q code = some a) : encodeKnown q a = code := by
  cases q with
  | taklifi => exact constraint_decode_sound h
  | wadi s =>
    cases s <;> simp only [decodeKnown, decodeBool, decodeValidity] at h
    all_goals
      split at h
      · rename_i hc
        cases h
        exact hc.symm
      · split at h
        · rename_i hc
          cases h
          exact hc.symm
        · contradiction

theorem payload_roundtrip (q : Question) (p : Payload (Answer q)) :
    decodePayload q (encodePayload q p) = some p := by
  cases p with
  | noRuling => rfl
  | suspended => rfl
  | known a =>
    simp [encodePayload, decodePayload, (known_code_not_status q a).1,
      (known_code_not_status q a).2, known_roundtrip]

theorem payload_decode_sound {q : Question} {code : Nat} {p : Payload (Answer q)}
    (h : decodePayload q code = some p) : encodePayload q p = code := by
  unfold decodePayload at h
  split at h
  · rename_i hc
    cases h
    exact hc.symm
  · split at h
    · rename_i hc
      cases h
      exact hc.symm
    · cases hk : decodeKnown q code with
      | none => simp [hk] at h
      | some a =>
        simp only [hk, Option.map_some, Option.some.injEq] at h
        subst p
        exact known_decode_sound hk

theorem record_roundtrip (r : Record) : decodeRecord (encodeRecord r) = some r := by
  cases r
  simp [encodeRecord, decodeRecord, question_roundtrip, payload_roundtrip]

theorem record_decode_sound {raw : RawRecord} {r : Record}
    (h : decodeRecord raw = some r) : encodeRecord r = raw := by
  cases hq : decodeQuestion raw.questionCode with
  | none => simp [decodeRecord, hq] at h
  | some q =>
    cases hp : decodePayload q raw.answerCode with
    | none => simp [decodeRecord, hq, hp] at h
    | some p =>
      simp [decodeRecord, hq, hp] at h
      subst r
      cases raw
      simp only [encodeRecord, question_decode_sound hq, payload_decode_sound hp]

inductive Status where
  | candidate | admitted | quarantined | revoked
  deriving DecidableEq, Repr

structure Entry where
  entryId : Nat
  status : Status
  record : RawRecord
  deriving DecidableEq, Repr

structure Registry where
  snapshot : Nat
  entries : List Entry
  deriving DecidableEq, Repr

structure Request where
  snapshot : Nat
  entryId : Nat
  record : RawRecord
  deriving DecidableEq, Repr

structure Receipt where
  snapshot : Nat
  entryId : Nat
  record : Record
  deriving DecidableEq

inductive Failure where
  | badAnswer | badReference | illTyped | staleSnapshot
  | missingEntry | ambiguousEntry | notAdmitted | recordMismatch
  deriving DecidableEq, Repr

inductive Outcome where
  | accepted (receipt : Receipt)
  | rejected (reason : Failure)
  deriving DecidableEq

def matchingEntries (registry : Registry) (entryId : Nat) : List Entry :=
  registry.entries.filter (fun e => e.entryId == entryId)

def validate (registry : Registry) (request : Request) : Outcome :=
  match decodeRecord request.record with
  | none => .rejected .badAnswer
  | some record =>
    if ¬ record.provenance.WellFormed then .rejected .badReference
    else if ¬ record.WellTyped then .rejected .illTyped
    else if request.snapshot ≠ registry.snapshot then .rejected .staleSnapshot
    else
      match matchingEntries registry request.entryId with
      | [] => .rejected .missingEntry
      | [entry] =>
        if entry.status ≠ .admitted then .rejected .notAdmitted
        else if entry.record ≠ request.record then .rejected .recordMismatch
        else .accepted ⟨request.snapshot, request.entryId, record⟩
      | _ :: _ :: _ => .rejected .ambiguousEntry

def Receipt.request (receipt : Receipt) : Request :=
  ⟨receipt.snapshot, receipt.entryId, encodeRecord receipt.record⟩

def revalidate (registry : Registry) (receipt : Receipt) : Outcome :=
  validate registry receipt.request

def outcomeCode : Outcome → Nat
  | .accepted _ => 0
  | .rejected .badAnswer => 1
  | .rejected .badReference => 2
  | .rejected .illTyped => 3
  | .rejected .staleSnapshot => 4
  | .rejected .missingEntry => 5
  | .rejected .ambiguousEntry => 6
  | .rejected .notAdmitted => 7
  | .rejected .recordMismatch => 8

/- Acceptance is characterized by the returned data, not just a Boolean flag. -/
theorem accepted_iff (registry : Registry) (request : Request) (receipt : Receipt) :
    validate registry request = .accepted receipt ↔
      decodeRecord request.record = some receipt.record ∧
      receipt.record.provenance.WellFormed ∧ receipt.record.WellTyped ∧
      request.snapshot = registry.snapshot ∧
      receipt.snapshot = request.snapshot ∧ receipt.entryId = request.entryId ∧
      ∃ entry, matchingEntries registry request.entryId = [entry] ∧
        entry.status = .admitted ∧ entry.record = request.record := by
  constructor
  · intro h
    cases hd : decodeRecord request.record with
    | none => simp [validate, hd] at h
    | some record =>
      have href : record.provenance.WellFormed := by
        by_cases href : record.provenance.WellFormed
        · exact href
        · simp [validate, hd, href] at h
      have htyped : record.WellTyped := by
        by_cases htyped : record.WellTyped
        · exact htyped
        · simp [validate, hd, href, htyped] at h
      have hsnap : request.snapshot = registry.snapshot := by
        by_cases hsnap : request.snapshot = registry.snapshot
        · exact hsnap
        · simp [validate, hd, href, htyped, hsnap] at h
      cases hm : matchingEntries registry request.entryId with
      | nil => simp [validate, hd, href, htyped, hsnap, hm] at h
      | cons entry rest =>
        cases rest with
        | nil =>
          have hstatus : entry.status = .admitted := by
            by_cases hstatus : entry.status = .admitted
            · exact hstatus
            · simp [validate, hd, href, htyped, hsnap, hm, hstatus] at h
          have hrecord : entry.record = request.record := by
            by_cases hrecord : entry.record = request.record
            · exact hrecord
            · simp [validate, hd, href, htyped, hsnap, hm, hstatus, hrecord] at h
          have he : (⟨request.snapshot, request.entryId, record⟩ : Receipt) = receipt := by
            simpa [validate, hd, href, htyped, hsnap, hm, hstatus, hrecord] using h
          cases he
          exact ⟨rfl, href, htyped, hsnap, rfl, rfl, entry, rfl, hstatus, hrecord⟩
        | cons other rest => simp [validate, hd, href, htyped, hsnap, hm] at h
  · rintro ⟨hd, href, htyped, hsnap, hrsnap, hrentry, entry, hm, hstatus, hrecord⟩
    cases receipt
    simp_all [validate]

theorem accepted_decoded {registry : Registry} {request : Request} {receipt : Receipt}
    (h : validate registry request = .accepted receipt) :
    decodeRecord request.record = some receipt.record :=
  ((accepted_iff registry request receipt).mp h).1

theorem accepted_preserves_record {registry : Registry} {request : Request} {receipt : Receipt}
    (h : validate registry request = .accepted receipt) :
    encodeRecord receipt.record = request.record :=
  record_decode_sound (accepted_decoded h)

theorem accepted_reference_shape {registry : Registry} {request : Request} {receipt : Receipt}
    (h : validate registry request = .accepted receipt) :
    receipt.record.provenance.source.WellFormed ∧
      receipt.record.provenance.implementationRevision ≠ "" :=
  ((accepted_iff registry request receipt).mp h).2.1

theorem accepted_well_typed {registry : Registry} {request : Request} {receipt : Receipt}
    (h : validate registry request = .accepted receipt) :
    receipt.record.provenance.dalil ≠ [] ∧
      (receipt.record.question = .taklifi → receipt.record.scope.subject.IsMukallaf) :=
  ((accepted_iff registry request receipt).mp h).2.2.1

theorem accepted_snapshot {registry : Registry} {request : Request} {receipt : Receipt}
    (h : validate registry request = .accepted receipt) :
    receipt.snapshot = request.snapshot ∧ request.snapshot = registry.snapshot := by
  have checks := (accepted_iff registry request receipt).mp h
  exact ⟨checks.2.2.2.2.1, checks.2.2.2.1⟩

theorem accepted_unique_admitted {registry : Registry} {request : Request} {receipt : Receipt}
    (h : validate registry request = .accepted receipt) :
    ∃ entry, matchingEntries registry request.entryId = [entry] ∧
      entry.status = .admitted ∧ entry.record = request.record :=
  ((accepted_iff registry request receipt).mp h).2.2.2.2.2.2

theorem accepted_registered_record {registry : Registry} {request : Request} {receipt : Receipt}
    (h : validate registry request = .accepted receipt) :
    ∃ entry, matchingEntries registry request.entryId = [entry] ∧
      entry.status = .admitted ∧ entry.record = encodeRecord receipt.record := by
  rcases accepted_unique_admitted h with ⟨entry, hm, hs, hr⟩
  exact ⟨entry, hm, hs, hr.trans (accepted_preserves_record h).symm⟩

theorem accepted_preserves_grade {registry : Registry} {request : Request} {receipt : Receipt}
    (h : validate registry request = .accepted receipt) :
    receipt.record.provenance.grade = request.record.provenance.grade ∧
      receipt.record.provenance.rujhanKnown = request.record.provenance.rujhanKnown := by
  have he := accepted_preserves_record h
  exact ⟨congrArg (fun r => r.provenance.grade) he,
    congrArg (fun r => r.provenance.rujhanKnown) he⟩

theorem mismatched_record_not_accepted (registry : Registry) (request : Request)
    (receipt : Receipt) (entry : Entry)
    (hm : matchingEntries registry request.entryId = [entry])
    (hne : entry.record ≠ request.record) :
    validate registry request ≠ .accepted receipt := by
  intro h
  rcases accepted_unique_admitted h with ⟨actual, ha, _, hr⟩
  have he : entry = actual := by simpa [hm] using ha
  subst actual
  exact hne hr

theorem question_change_not_accepted (registry : Registry) (request : Request)
    (receipt : Receipt) (entry : Entry)
    (hm : matchingEntries registry request.entryId = [entry])
    (hne : entry.record.questionCode ≠ request.record.questionCode) :
    validate registry request ≠ .accepted receipt :=
  mismatched_record_not_accepted registry request receipt entry hm
    (fun he => hne (congrArg RawRecord.questionCode he))

theorem source_hash_change_not_accepted (registry : Registry) (request : Request)
    (receipt : Receipt) (entry : Entry)
    (hm : matchingEntries registry request.entryId = [entry])
    (hne : entry.record.provenance.source.sourceHash ≠
      request.record.provenance.source.sourceHash) :
    validate registry request ≠ .accepted receipt :=
  mismatched_record_not_accepted registry request receipt entry hm
    (fun he => hne (congrArg (fun r => r.provenance.source.sourceHash) he))

theorem profile_change_not_accepted (registry : Registry) (request : Request)
    (receipt : Receipt) (entry : Entry)
    (hm : matchingEntries registry request.entryId = [entry])
    (hne : entry.record.scope.profile ≠ request.record.scope.profile) :
    validate registry request ≠ .accepted receipt :=
  mismatched_record_not_accepted registry request receipt entry hm
    (fun he => hne (congrArg (fun r => r.scope.profile) he))

theorem profile_version_change_not_accepted (registry : Registry) (request : Request)
    (receipt : Receipt) (entry : Entry)
    (hm : matchingEntries registry request.entryId = [entry])
    (hne : entry.record.scope.profileVersion ≠ request.record.scope.profileVersion) :
    validate registry request ≠ .accepted receipt :=
  mismatched_record_not_accepted registry request receipt entry hm
    (fun he => hne (congrArg (fun r => r.scope.profileVersion) he))

theorem non_admitted_not_accepted (registry : Registry) (request : Request)
    (receipt : Receipt) (entry : Entry)
    (hm : matchingEntries registry request.entryId = [entry])
    (hne : entry.status ≠ .admitted) : validate registry request ≠ .accepted receipt := by
  intro h
  rcases accepted_unique_admitted h with ⟨actual, ha, hs, _⟩
  have he : entry = actual := by simpa [hm] using ha
  subst actual
  exact hne hs

theorem duplicate_entries_not_accepted (registry : Registry) (request : Request)
    (receipt : Receipt) (first second : Entry) (rest : List Entry)
    (hm : matchingEntries registry request.entryId = first :: second :: rest) :
    validate registry request ≠ .accepted receipt := by
  intro h
  rcases accepted_unique_admitted h with ⟨entry, he, _⟩
  simp [hm] at he

theorem missing_entry_not_accepted (registry : Registry) (request : Request)
    (receipt : Receipt) (hm : matchingEntries registry request.entryId = []) :
    validate registry request ≠ .accepted receipt := by
  intro h
  rcases accepted_unique_admitted h with ⟨entry, he, _⟩
  simp [hm] at he

theorem stale_snapshot_not_accepted (registry : Registry) (request : Request)
    (receipt : Receipt) (hne : request.snapshot ≠ registry.snapshot) :
    validate registry request ≠ .accepted receipt :=
  fun h => hne (accepted_snapshot h).2

theorem receipt_request_preserved {registry : Registry} {request : Request} {receipt : Receipt}
    (h : validate registry request = .accepted receipt) : receipt.request = request := by
  have checks := (accepted_iff registry request receipt).mp h
  have hp := accepted_preserves_record h
  cases request
  cases receipt
  simp_all [Receipt.request]

theorem revalidate_original {registry : Registry} {request : Request} {receipt : Receipt}
    (h : validate registry request = .accepted receipt) :
    revalidate registry receipt = .accepted receipt := by
  unfold revalidate
  rw [receipt_request_preserved h]
  exact h

theorem revalidate_stale_not_accepted (registry : Registry) (receipt result : Receipt)
    (hne : receipt.snapshot ≠ registry.snapshot) :
    revalidate registry receipt ≠ .accepted result :=
  stale_snapshot_not_accepted registry receipt.request result hne

theorem revalidate_non_admitted_not_accepted (registry : Registry) (receipt result : Receipt)
    (entry : Entry) (hm : matchingEntries registry receipt.entryId = [entry])
    (hne : entry.status ≠ .admitted) : revalidate registry receipt ≠ .accepted result :=
  non_admitted_not_accepted registry receipt.request result entry hm hne

theorem revalidate_revoked_not_accepted (registry : Registry) (receipt result : Receipt)
    (entry : Entry) (hm : matchingEntries registry receipt.entryId = [entry])
    (hs : entry.status = .revoked) : revalidate registry receipt ≠ .accepted result := by
  apply revalidate_non_admitted_not_accepted registry receipt result entry hm
  simp [hs]

theorem missing_ne_suspended (q : Question) :
    (Payload.noRuling : Payload (Answer q)) ≠ .suspended := by
  intro h
  cases h

theorem missing_ne_known (q : Question) (a : Answer q) :
    (Payload.noRuling : Payload (Answer q)) ≠ .known a := by
  intro h
  cases h

theorem suspended_ne_known (q : Question) (a : Answer q) :
    (Payload.suspended : Payload (Answer q)) ≠ .known a := by
  intro h
  cases h

/-! ## Synthetic, explicitly bounded audit fixtures -/

def codecCode (questionCode answerCode : Nat) : Nat :=
  match decodeQuestion questionCode with
  | none => 0
  | some q =>
    match decodePayload q answerCode with
    | none => 0
    | some p => encodePayload q p + 1

def decodeStatus : Nat → Option Status
  | 0 => some .candidate
  | 1 => some .admitted
  | 2 => some .quarantined
  | 3 => some .revoked
  | _ => none

def syntheticBaseline (q : Nat) : RawRecord :=
  { questionCode := q
    answerCode := if q = 0 then 16 else if q < 4 then 34 else 36
    scope :=
      { subjectId := 1, subject := ⟨true, true⟩, targetId := 1
        targetKind := .behavior, context := 1, time := 1, profile := 1
        profileVersion := 1, domain := .ada }
    provenance :=
      { source :=
          { sourceId := 1, sourceHash := List.replicate 32 0, sourceBytes := 4
            passageStart := 1, passageEnd := 3, passageHash := List.replicate 32 0 }
        interpretationId := 1, interpretationVersion := 1, grade := .qat
        rujhanKnown := true, dalil := [.nass], premises := [], ruleId := 1
        implementationRevision := "rev-a" } }

def syntheticEntry (q : Nat) (status : Status) : Entry :=
  ⟨1, status, syntheticBaseline q⟩

def syntheticRegistry (q : Nat) (status : Status) : Registry :=
  ⟨1, [syntheticEntry q status]⟩

def syntheticRequest (q : Nat) : Request := ⟨1, 1, syntheticBaseline q⟩

def syntheticRecordVariant (q variant : Nat) (r : RawRecord) : Option RawRecord :=
  match variant with
  | 0 => some r
  | 1 => some { r with questionCode := (q + 1) % 5 }
  | 2 => some { r with answerCode := if q = 0 then 1 else if q < 4 then 33 else 35 }
  | 3 => some { r with scope := { r.scope with subjectId := 2 } }
  | 4 => some { r with scope := { r.scope with subject := { r.scope.subject with baligh := false } } }
  | 5 => some { r with scope := { r.scope with subject := { r.scope.subject with aqil := false } } }
  | 6 => some { r with scope := { r.scope with targetId := 2 } }
  | 7 => some { r with scope := { r.scope with targetKind := .affect } }
  | 8 => some { r with scope := { r.scope with context := 2 } }
  | 9 => some { r with scope := { r.scope with time := 2 } }
  | 10 => some { r with scope := { r.scope with profile := 2 } }
  | 11 => some { r with scope := { r.scope with profileVersion := 2 } }
  | 12 => some { r with scope := { r.scope with domain := .ibada } }
  | 13 => some { r with provenance := { r.provenance with source :=
      { r.provenance.source with sourceId := 2 } } }
  | 14 => some { r with provenance := { r.provenance with source :=
      { r.provenance.source with sourceHash := List.replicate 32 1 } } }
  | 15 => some { r with provenance := { r.provenance with source :=
      { r.provenance.source with sourceBytes := 5 } } }
  | 16 => some { r with provenance := { r.provenance with source :=
      { r.provenance.source with passageStart := 2 } } }
  | 17 => some { r with provenance := { r.provenance with source :=
      { r.provenance.source with passageEnd := 4 } } }
  | 18 => some { r with provenance := { r.provenance with source :=
      { r.provenance.source with passageHash := List.replicate 32 1 } } }
  | 19 => some { r with provenance := { r.provenance with interpretationId := 2 } }
  | 20 => some { r with provenance := { r.provenance with interpretationVersion := 2 } }
  | 21 => some { r with provenance := { r.provenance with grade := .zann } }
  | 22 => some { r with provenance := { r.provenance with rujhanKnown := false } }
  | 23 => some { r with provenance := { r.provenance with dalil := [.qiyas] } }
  | 24 => some { r with provenance := { r.provenance with premises := [2] } }
  | 25 => some { r with provenance := { r.provenance with ruleId := 2 } }
  | 26 => some { r with provenance := { r.provenance with implementationRevision := "rev-b" } }
  | 27 | 28 | 29 => some r
  | 30 => some { r with provenance := { r.provenance with source :=
      { r.provenance.source with sourceHash := [] } } }
  | 31 => some { r with provenance := { r.provenance with source :=
      { r.provenance.source with passageStart := 3 } } }
  | 32 => some { r with provenance := { r.provenance with dalil := [] } }
  | 33 => some { r with provenance := { r.provenance with source :=
      { r.provenance.source with sourceHash := List.replicate 32 256 } } }
  | 34 => some { r with provenance := { r.provenance with implementationRevision := "" } }
  | 35 => some { r with provenance := { r.provenance with source :=
      { r.provenance.source with passageHash := [] } } }
  | 36 => some { r with provenance := { r.provenance with source :=
      { r.provenance.source with passageEnd := 5 } } }
  | 37 => some { r with provenance := { r.provenance with source :=
      { r.provenance.source with passageHash := List.replicate 32 256 } } }
  | _ => none

def admissionCode (q status variant : Nat) : Option Nat := do
  if q < 5 then
    let status ← decodeStatus status
    let record ← syntheticRecordVariant q variant (syntheticBaseline q)
    let entry := syntheticEntry q status
    let registry : Registry := ⟨1, if variant = 29 then [entry, entry] else [entry]⟩
    let request : Request :=
      ⟨if variant = 27 then 2 else 1, if variant = 28 then 2 else 1, record⟩
    pure (outcomeCode (validate registry request))
  else none

def syntheticRegistryUpdate (q update : Nat) : Option Registry :=
  let entry := syntheticEntry q .admitted
  match update with
  | 0 => some ⟨1, [entry]⟩
  | 1 => some ⟨2, [entry]⟩
  | 2 => some ⟨1, [{ entry with status := .revoked }]⟩
  | 3 => some ⟨1, [{ entry with status := .quarantined }]⟩
  | 4 => some ⟨1, [{ entry with record := { entry.record with provenance :=
      { entry.record.provenance with source :=
        { entry.record.provenance.source with sourceHash := List.replicate 32 1 } } } }]⟩
  | 5 => some ⟨1, [{ entry with record := { entry.record with scope :=
      { entry.record.scope with profileVersion := 2 } } }]⟩
  | 6 => some ⟨1, []⟩
  | 7 => some ⟨1, [entry, entry]⟩
  | _ => none

def revalidationCode (q update : Nat) : Option Nat := do
  if q < 5 then
    let registry ← syntheticRegistryUpdate q update
    match validate (syntheticRegistry q .admitted) (syntheticRequest q) with
    | .accepted receipt => some (outcomeCode (revalidate registry receipt))
    | .rejected _ => none
  else none

end Usul.IDA.Judgment
