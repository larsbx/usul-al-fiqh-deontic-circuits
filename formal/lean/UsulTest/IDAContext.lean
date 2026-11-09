import Usul.Typing.IDAContext
import UsulTest.IDAActRegistry
import Usul.Agency

/-! Finite ACT-01 fixtures and independent adverse controls. The two named
participants and the predicate are synthetic. Agency replay below stays in the
existing candidate model and does not resolve a mandate as an act kind. -/

namespace UsulTest.IDAContext

open Usul Usul.IDA Usul.IDA.Context
open IDAActRegistry (baseRegistry baseEnvelope baseQualification payer recipient property)

def opportunity : Opportunity := ⟨⟨"synthetic.event", "one"⟩, ⟨"clock", "test"⟩, 9, 12⟩
def predicate : PredicateDefinition :=
  ⟨⟨baseQualification.predicate, 1⟩, [.person]⟩
def vocabulary : Vocabulary := ⟨⟨⟨"synthetic.vocab", "pilot"⟩, 1⟩, [predicate]⟩

def synchronize (s : Snapshot) : Snapshot :=
  let m := s.envelope.context
  { s with inquiry := { s.inquiry with scope := { s.inquiry.scope with
    target := .structured s.target, context := m.contextId, time := m.timeId,
    profile := m.profile, profileVersion := m.profileVersion } } }

def base : Snapshot := synchronize
  { key := ⟨⟨"synthetic.snapshot", "pilot"⟩, 1⟩
    vocabulary := vocabulary
    admissionPolicy := ⟨⟨"synthetic.policy", "test"⟩, 1⟩
    envelope := { baseEnvelope with context := { baseEnvelope.context with recordedAt := 9 } }
    time := ⟨1, 10, .asKnown⟩
    inquiry := ⟨1, .wadi .shart, IDAActRegistry.basePremise.request.record.scope,
      recipient, ⟨"payer", payer⟩⟩
    opportunity := some opportunity }

def setMetadata (s : Snapshot) (f : ActRegistry.Snapshot → ActRegistry.Snapshot) : Snapshot :=
  synchronize { s with envelope := { s.envelope with context := f s.envelope.context } }

def setQualifications (qs : List ActRegistry.Qualification) : Snapshot :=
  { base with envelope := { base.envelope with qualifications := qs } }

def atTick (tick : Nat) : Snapshot :=
  { setMetadata base (fun m => { m with effectiveAt := tick, recordedAt := tick }) with
    time := { base.time with cutoff := tick } }

def snapshotCase : Nat → Snapshot
  | 1 => setQualifications [{ baseQualification with polarity := false }]
  | 2 => setQualifications [{ baseQualification with arguments := [recipient] }]
  | 3 => setQualifications [{ baseQualification with arguments := [property] }]
  | 4 => setQualifications [{ baseQualification with version := 2 }]
  | 5 => { base with vocabulary := { vocabulary with definitions :=
      [predicate, { predicate with arguments := [.asset] }] } }
  | 6 => setMetadata base fun m => { m with evidenceRevision := 2 }
  | 7 => setMetadata base fun m => { m with clock := ⟨"clock", "other"⟩ }
  | 8 => atTick 9
  | 9 => atTick 12
  | 10 => { setMetadata base (fun m => { m with recordedAt := 11 }) with
      time := ⟨1, 12, .retrospective⟩ }
  | 11 => { base with time := ⟨1, 11, .asKnown⟩ }
  | 12 => setMetadata base fun m => { m with recordedAt := 11 }
  | 13 => { base with inquiry := { base.inquiry with performer := ⟨"recipient", recipient⟩ } }
  | 14 => { base with inquiry := { base.inquiry with accountable := payer } }
  | 15 => { base with inquiry := { base.inquiry with performer := ⟨"property", property⟩ } }
  | 16 => { base with inquiry := { base.inquiry with scope :=
      { base.inquiry.scope with target := .legacy 1 .behavior } } }
  | 17 => { base with inquiry := { base.inquiry with scope :=
      { base.inquiry.scope with profileVersion := 2 } } }
  | 18 => synchronize { base with envelope := { base.envelope with action :=
      (IDAActRegistry.envelopeCase 9).action }, inquiry :=
      { base.inquiry with performer := ⟨"payer", recipient⟩ } }
  | 19 => { base with time := { base.time with clockVersion := 2 } }
  | 20 => synchronize { base with opportunity := some { opportunity with occurrence :=
      ⟨"synthetic.event", "other"⟩ } }
  | 21 => synchronize { base with opportunity := some { opportunity with closesAt := 13 } }
  | 22 => setQualifications []
  | 23 => synchronize { base with opportunity := none }
  | 24 => synchronize { base with opportunity := some { opportunity with closesAt := 9 } }
  | 25 => { base with admissionPolicy := { base.admissionPolicy with version := 2 } }
  | 26 => setQualifications [baseQualification, { baseQualification with polarity := false }]
  | 27 => { setMetadata base (fun m => { m with evidenceRevision := 2 }) with
      key := { base.key with version := 2 } }
  | _ => base

def differentKey (s : Snapshot) : Snapshot :=
  { s with key := { s.key with version := s.key.version + 1 } }

def differentCoordinates (s : Snapshot) : Snapshot :=
  setMetadata (differentKey s) fun m => { m with contextId := 2 }

def catalogCase (n : Nat) (s : Snapshot) : Catalog :=
  let other := differentCoordinates s
  match n with
  | 0 => [s]
  | 1 => [base]
  | 2 => [s, differentKey s]
  | 3 => [s, { other with key := s.key }]
  | 4 => []
  | 5 => [s, { other with vocabulary := ⟨{ s.vocabulary.pin with version := 2 },
      [{ predicate with arguments := [.asset] }]⟩ }]
  | 6 => [s, { other with time := { other.time with clockVersion := other.time.clockVersion + 1 } }]
  | 7 => [s, other]
  | 8 => [s, s]
  | 9 => [s, { other with vocabulary := { s.vocabulary with definitions := [] } }]
  | _ => []

def premiseFor (s : Snapshot) : Derivation.Premise :=
  let p := IDAActRegistry.renewedPremise s.envelope
  IDADerivation.changeRecord { p with questionId := s.inquiry.questionId } fun r =>
    { r with questionCode := Judgment.encodeQuestion s.inquiry.question, scope := s.inquiry.scope }

def premiseCase (n : Nat) (s : Snapshot) : Derivation.Premise :=
  let p := premiseFor s
  match n with
  | 1 => { p with questionId := p.questionId + 1 }
  | 2 => IDADerivation.changeRecord p fun r => { r with questionCode := 4 }
  | 3 => IDADerivation.changeScope p fun scope => { scope with subjectId := scope.subjectId + 1 }
  | 4 => IDADerivation.changeScope p fun scope => { scope with domain := .ibada }
  | 5 => IDADerivation.changeScope p fun scope => { scope with target := .legacy 1 .behavior }
  | 6 => IDADerivation.changeScope p fun scope => { scope with time := scope.time + 1 }
  | 7 => IDADerivation.changeRecord p fun r => { r with provenance :=
      { r.provenance with interpretationVersion := r.provenance.interpretationVersion + 1 } }
  | 8 => IDADerivation.changeScope p fun scope => { scope with profileVersion := scope.profileVersion + 1 }
  | 9 => IDADerivation.changeScope p fun scope => { scope with subject :=
      { scope.subject with aqil := !scope.subject.aqil } }
  | _ => p

def code {α : Type} : Except Failure α → Nat
  | .ok _ => 0
  | .error .ambiguous => 1
  | .error .missing => 2
  | .error .stale => 3
  | .error .malformed => 4
  | .error .inquiryMismatch => 5
  | .error .definitionConflict => 6

def compareCase (n c p : Nat) : Nat :=
  let s := snapshotCase n
  code (bind baseRegistry (catalogCase c s) s (premiseCase p s))

/-- Model coordinates: 0 historical receipt, 1 A's current authority,
2 B's current authority. Recording the revocation does not notify either agent. -/
def agencyCase (profile history coordinate : Nat) : Nat :=
  let cfg : Agency.Config := ⟨if profile = 0 then .immediate else .onKnowledge, true⟩
  let events : List Agency.Event := [.appoint, .executeA, .revoke] ++
    (match history with
     | 1 => [.notifyA]
     | 2 => [.notifyB]
     | 3 => [.notifyA, .notifyB]
     | _ => [])
  match Agency.replay cfg Agency.initial events with
  | none => 2
  | some s =>
    match coordinate with
    | 0 => if s.accepted = .a then 1 else 0
    | 1 => if Agency.effectiveA cfg s then 1 else 0
    | _ => if Agency.effectiveB cfg s then 1 else 0

set_option maxRecDepth 4096 in
theorem guard_controls :
    ([compareCase 0 0 0, compareCase 0 2 0, compareCase 0 3 0, compareCase 0 4 0,
      compareCase 1 1 0, compareCase 2 1 0, compareCase 3 0 0, compareCase 4 0 0,
      compareCase 5 0 0, compareCase 7 0 0, compareCase 11 0 0, compareCase 12 0 0,
      compareCase 16 0 0, compareCase 0 0 7, compareCase 0 5 0, compareCase 0 6 0,
      compareCase 0 9 0, compareCase 0 7 0, compareCase 24 0 0, compareCase 26 0 0] =
      [0, 1, 1, 2, 3, 3, 4, 4, 6, 4, 4, 4, 4, 5, 6, 6, 6, 0, 4, 0]) := by decide

theorem same_target_changed_qualification :
    (snapshotCase 1).target = base.target ∧ compareCase 1 1 0 = 3 := by decide

theorem candidate_source_stays_candidate :
    let p := premiseFor (snapshotCase 23)
    code (bind baseRegistry [snapshotCase 23] (snapshotCase 23) p) = 0 ∧
    ¬ (Derivation.evaluateSource (IDAActRegistry.sourceEnvironment 1 p) p).Accepted := by decide

theorem historical_receipt_current_authority :
    agencyCase 0 0 0 = 1 ∧ agencyCase 0 0 1 = 0 ∧
    agencyCase 1 0 1 = 1 ∧ agencyCase 1 1 1 = 0 ∧ agencyCase 1 1 2 = 1 := by decide

def reviewCase (profile scenario perspective coordinate : Nat) : Nat :=
  let cfg : Agency.Config := ⟨if profile = 0 then .immediate else .onKnowledge, true⟩
  let evidence : AgencyEvidence := match scenario with
    | 0 => ⟨12, 15, none⟩
    | 1 => ⟨8, 15, none⟩
    | 2 => ⟨8, 15, some 9⟩
    | 3 => ⟨8, 15, some 12⟩
    | 4 => ⟨10, 15, none⟩
    | _ => ⟨8, 15, some 7⟩
  let view : TimeView :=
    if perspective = 0 then ⟨1, 10, .asKnown⟩ else ⟨1, 15, .retrospective⟩
  match reviewAgency cfg view 10 evidence with
  | .invalid => 3
  | .blocked => 2
  | .replayed s =>
    (if coordinate = 0 then s.accepted == .a
     else if coordinate = 1 then Agency.effectiveA cfg s else s.knownA).toNat

theorem late_revocation_review :
    reviewCase 0 0 1 0 = 1 ∧ reviewCase 0 0 1 1 = 0 ∧
    reviewCase 0 1 0 0 = 1 ∧ reviewCase 0 1 1 0 = 2 ∧
    reviewCase 1 1 1 0 = 1 ∧ reviewCase 1 1 1 2 = 0 ∧
    reviewCase 1 2 0 2 = 0 ∧ reviewCase 1 2 1 0 = 2 ∧
    reviewCase 1 3 1 0 = 1 ∧ reviewCase 1 3 1 2 = 1 ∧
    reviewCase 0 4 1 0 = 3 ∧ reviewCase 0 5 1 0 = 3 := by decide

def omissionCase (scenario cutoff : Nat) : Nat :=
  let scope : OmissionScope := ⟨baseEnvelope.action, opportunity, 1⟩
  let other := { scope with opportunity := { opportunity with occurrence := ⟨"synthetic.event", "other"⟩ } }
  let report : Nat → PerformanceReport := fun tick => ⟨scope, tick, tick⟩
  let reports : List PerformanceReport := match scenario with
    | 2 => [report 9]
    | 3 => [report 12]
    | 4 => [{ report 9 with recordedAt := 14 }]
    | 5 => [{ report 9 with scope := other }]
    | 9 => [{ report 9 with recordedAt := 8 }]
    | 10 => [report 9, report 9]
    | _ => []
  let coverage : Option ObservationCoverage := match scenario with
    | 0 => none
    | 6 => some ⟨scope, 11, 12⟩
    | 7 => some ⟨scope, 12, 14⟩
    | 8 => some ⟨{ scope with clockVersion := 2 }, 12, 12⟩
    | _ => some ⟨scope, 12, 12⟩
  match observeOmission scope cutoff reports coverage with
  | .invalid => 0 | .pending => 1 | .performed => 2 | .unresolved => 3
  | .noRecordedPerformance => 4

theorem omission_observation_controls :
    [omissionCase 0 12, omissionCase 1 11, omissionCase 1 12, omissionCase 2 9,
     omissionCase 3 12, omissionCase 4 12, omissionCase 4 14, omissionCase 5 12,
     omissionCase 6 12, omissionCase 7 12, omissionCase 8 12, omissionCase 9 12,
     omissionCase 10 12] = [3, 1, 4, 2, 4, 4, 2, 4, 3, 3, 3, 4, 2] := by decide

end UsulTest.IDAContext
