import Usul.Typing.IDAOmissionSemantics
import UsulTest.IDAOmissionGuardWitness

/-!
# Controls for semantic adequacy of omission observations

These tests keep the native scope, interval, modes and evaluator. The empty
history and the one-event history are supplied independently of every report
list. A modeled event is identified by its exact scope, mode and occurrence
time; these tests do not claim globally unique physical-event identifiers.

The necessity controls isolate semantic exhaustiveness, matching-report
soundness, chronology, closure and the evaluator's structural coverage claim.
The authentication theorem is conditional on a predicate of a fixed supplied
payload. It makes no claim that a new concrete batch was signed or accepted by
the host, and it supplies no juristic interpretation of nonperformance.
-/

namespace UsulTest.IDAOmissionSemantics

open Usul.IDA.Omission
open Usul.IDA.Omission.Semantics
open IDAPaper.NativeOmission

def actualEvent : Event := ⟨earlyScope, .direct, 5⟩

def emptyHistory : History := fun _ => False

def actualHistory : History := fun e => e = actualEvent

def truthfulReport : Completion := ⟨earlyScope, .direct, 5, 5⟩

def malformedReport : Completion := ⟨earlyScope, .direct, 5, 4⟩

def lateReport : Completion := ⟨earlyScope, .direct, 5, 20⟩

theorem actual_event_qualifies : Qualifies actualHistory earlyScope actualEvent := by
  exact ⟨rfl, rfl, by decide, by decide⟩

theorem empty_no_qualifying (s : Scope) : NoQualifying emptyHistory s := by
  rintro ⟨e, he⟩
  exact he.1

theorem empty_exhaustive (s : Scope) (cutoff : Nat) (reports : List Completion) :
    Exhaustive emptyHistory s cutoff reports := by
  intro e he
  exact False.elim he.1

theorem empty_reports_sound (h : History) (s : Scope) (effective cutoff : Nat) :
    SoundFor h s effective cutoff [] := by
  intro r hr _
  simp at hr

/-! The next three declarations restate the semantic conclusions and the
report assumptions independently of their convenient predicate aliases. They
must continue to elaborate against the actual production theorem statements. -/

theorem forward_statement_contract
    (h : Event → Prop) (s : Scope) (effective cutoff : Nat)
    (reports : List Completion) (coverage : Option Coverage)
    (covered : evaluate s effective cutoff reports coverage = .coveredNoCompletion)
    (exhaustive : ∀ e,
      (h e ∧ e.scope = s ∧ s.opportunity.opensAt ≤ e.occurredAt ∧
        e.occurredAt < s.opportunity.closesAt) →
      ∃ r ∈ reports, eventOf r = e ∧ r.occurredAt ≤ r.recordedAt ∧
        r.recordedAt ≤ cutoff) :
    ¬ ∃ e, h e ∧ e.scope = s ∧ s.opportunity.opensAt ≤ e.occurredAt ∧
      e.occurredAt < s.opportunity.closesAt := by
  exact covered_no_completion_sound covered exhaustive

theorem reverse_statement_contract
    (h : Event → Prop) (s : Scope) (effective cutoff : Nat)
    (reports : List Completion) (coverage : Option Coverage)
    (absent : ¬ ∃ e, h e ∧ e.scope = s ∧ s.opportunity.opensAt ≤ e.occurredAt ∧
      e.occurredAt < s.opportunity.closesAt)
    (sound : ∀ r ∈ reports, r.matches s effective cutoff = true → h (eventOf r))
    (noMalformed : reports.any (·.malformed s cutoff) = false)
    (closed : s.opportunity.closesAt ≤ effective)
    (complete : Coverage.Complete s cutoff coverage) :
    evaluate s effective cutoff reports coverage = .coveredNoCompletion := by
  exact covered_no_completion_complete absent sound noMalformed closed complete

theorem equivalence_statement_contract
    (h : Event → Prop) (s : Scope) (effective cutoff : Nat)
    (reports : List Completion) (coverage : Option Coverage)
    (exhaustive : ∀ e,
      (h e ∧ e.scope = s ∧ s.opportunity.opensAt ≤ e.occurredAt ∧
        e.occurredAt < s.opportunity.closesAt) →
      ∃ r ∈ reports, eventOf r = e ∧ r.occurredAt ≤ r.recordedAt ∧
        r.recordedAt ≤ cutoff)
    (sound : ∀ r ∈ reports, r.matches s effective cutoff = true → h (eventOf r))
    (noMalformed : reports.any (·.malformed s cutoff) = false)
    (closed : s.opportunity.closesAt ≤ effective)
    (complete : Coverage.Complete s cutoff coverage) :
    evaluate s effective cutoff reports coverage = .coveredNoCompletion ↔
      ¬ ∃ e, h e ∧ e.scope = s ∧ s.opportunity.opensAt ≤ e.occurredAt ∧
        e.occurredAt < s.opportunity.closesAt := by
  exact covered_no_completion_iff exhaustive sound noMalformed closed complete

/-! ## Positive controls -/

theorem closed_empty_history_covered :
    NoQualifying emptyHistory earlyScope ∧
    Exhaustive emptyHistory earlyScope 15 [] ∧
    SoundFor emptyHistory earlyScope 15 15 [] ∧
    evaluate earlyScope 15 15 [] (some completeCoverage) = .coveredNoCompletion := by
  refine ⟨empty_no_qualifying _, empty_exhaustive _ _ _,
    empty_reports_sound _ _ _ _, ?_⟩
  exact covered_no_completion_complete (empty_no_qualifying _)
    (empty_reports_sound _ _ _ _) rfl early_window_closed complete_coverage_well_scoped

theorem truthful_report_observed :
    Qualifies actualHistory earlyScope actualEvent ∧
    Exhaustive actualHistory earlyScope 15 [truthfulReport] ∧
    SoundFor actualHistory earlyScope 15 15 [truthfulReport] ∧
    [truthfulReport].any (·.malformed earlyScope 15) = false ∧
    evaluate earlyScope 15 15 [truthfulReport] (some completeCoverage) =
      .completionObserved := by
  refine ⟨actual_event_qualifies, ?_, ?_, by decide, by decide⟩
  · intro e he
    have same : e = actualEvent := he.1
    subst e
    exact ⟨truthfulReport, by simp, rfl, by decide, by decide⟩
  · intro r hr _
    have same : r = truthfulReport := by simpa using hr
    subst r
    rfl

/-! ## Necessity of the separate hypotheses -/

theorem completeness_needed :
    Coverage.Complete earlyScope 15 (some completeCoverage) ∧
    ([] : List Completion).any (·.malformed earlyScope 15) = false ∧
    earlyScope.opportunity.closesAt ≤ 15 ∧
    SoundFor actualHistory earlyScope 15 15 [] ∧
    evaluate earlyScope 15 15 [] (some completeCoverage) = .coveredNoCompletion ∧
    (∃ e, Qualifies actualHistory earlyScope e) ∧
    ¬ Exhaustive actualHistory earlyScope 15 [] := by
  refine ⟨complete_coverage_well_scoped, rfl, early_window_closed,
    empty_reports_sound _ _ _ _, covered_observation,
    ⟨actualEvent, actual_event_qualifies⟩, ?_⟩
  intro exhaustive
  obtain ⟨r, hr, _⟩ := exhaustive actualEvent actual_event_qualifies
  simp at hr

theorem soundness_needed :
    NoQualifying emptyHistory earlyScope ∧
    Exhaustive emptyHistory earlyScope 15 [truthfulReport] ∧
    [truthfulReport].any (·.malformed earlyScope 15) = false ∧
    earlyScope.opportunity.closesAt ≤ 15 ∧
    Coverage.Complete earlyScope 15 (some completeCoverage) ∧
    evaluate earlyScope 15 15 [truthfulReport] (some completeCoverage) =
      .completionObserved ∧
    ¬ SoundFor emptyHistory earlyScope 15 15 [truthfulReport] := by
  refine ⟨empty_no_qualifying _, empty_exhaustive _ _ _, by decide,
    early_window_closed, complete_coverage_well_scoped, by decide, ?_⟩
  intro sound
  exact sound truthfulReport (by simp) (by decide)

theorem chronology_needed :
    NoQualifying emptyHistory earlyScope ∧
    Exhaustive emptyHistory earlyScope 15 [malformedReport] ∧
    SoundFor emptyHistory earlyScope 15 15 [malformedReport] ∧
    earlyScope.opportunity.closesAt ≤ 15 ∧
    Coverage.Complete earlyScope 15 (some completeCoverage) ∧
    [malformedReport].any (·.malformed earlyScope 15) = true ∧
    evaluate earlyScope 15 15 [malformedReport] (some completeCoverage) =
      .invalidObservation := by
  refine ⟨empty_no_qualifying _, empty_exhaustive _ _ _, ?_, early_window_closed,
    complete_coverage_well_scoped, by decide, by decide⟩
  intro r hr matching
  have same : r = malformedReport := by simpa using hr
  subst r
  have mismatch : malformedReport.matches earlyScope 15 15 = false := by decide
  simp [mismatch] at matching

theorem closure_needed :
    NoQualifying emptyHistory earlyScope ∧
    Exhaustive emptyHistory earlyScope 15 [] ∧
    SoundFor emptyHistory earlyScope 9 15 [] ∧
    ([] : List Completion).any (·.malformed earlyScope 15) = false ∧
    Coverage.Complete earlyScope 15 (some completeCoverage) ∧
    9 < earlyScope.opportunity.closesAt ∧
    evaluate earlyScope 9 15 [] (some completeCoverage) = .pending := by
  exact ⟨empty_no_qualifying _, empty_exhaustive _ _ _, empty_reports_sound _ _ _ _,
    rfl, complete_coverage_well_scoped, by decide, by decide⟩

theorem structural_coverage_needed :
    NoQualifying emptyHistory earlyScope ∧
    Exhaustive emptyHistory earlyScope 15 [] ∧
    SoundFor emptyHistory earlyScope 15 15 [] ∧
    ([] : List Completion).any (·.malformed earlyScope 15) = false ∧
    earlyScope.opportunity.closesAt ≤ 15 ∧
    ¬ Coverage.Complete earlyScope 15 none ∧
    evaluate earlyScope 15 15 [] none = .coverageMissing := by
  exact ⟨empty_no_qualifying _, empty_exhaustive _ _ _, empty_reports_sound _ _ _ _,
    rfl, early_window_closed, by simp [Coverage.Complete], early_observation⟩

/-! ## Fixed payloads do not identify the actual history -/

theorem same_payload_different_histories :
    Coverage.Complete earlyScope 15 (some completeCoverage) ∧
    evaluate earlyScope 15 15 [] (some completeCoverage) = .coveredNoCompletion ∧
    NoQualifying emptyHistory earlyScope ∧
    ¬ NoQualifying actualHistory earlyScope := by
  refine ⟨complete_coverage_well_scoped, covered_observation, empty_no_qualifying _, ?_⟩
  intro absent
  exact absent ⟨actualEvent, actual_event_qualifies⟩

/-- Whatever payload-only authentication predicate is used, retaining an
accepted payload does not determine the separately supplied semantic history.
This conditional statement neither assumes nor exhibits a forged signature. -/
theorem payload_authentication_does_not_imply_absence
    (Authenticated : Scope → Nat → Nat → List Completion → Option Coverage → Prop)
    (accepted : Authenticated earlyScope 15 15 [] (some completeCoverage)) :
    ∃ h : History,
      Authenticated earlyScope 15 15 [] (some completeCoverage) ∧
      Coverage.Complete earlyScope 15 (some completeCoverage) ∧
      evaluate earlyScope 15 15 [] (some completeCoverage) = .coveredNoCompletion ∧
      ¬ NoQualifying h earlyScope := by
  refine ⟨actualHistory, accepted, complete_coverage_well_scoped, covered_observation, ?_⟩
  intro absent
  exact absent ⟨actualEvent, actual_event_qualifies⟩

/-! An exact and chronological report that arrives after the cutoff does not
provide coverage at the earlier recording perspective. -/

theorem late_report_not_exhaustive :
    Qualifies actualHistory earlyScope actualEvent ∧
    (∃ r ∈ [lateReport], Represents r actualEvent ∧ r.occurredAt ≤ r.recordedAt) ∧
    SoundFor actualHistory earlyScope 15 15 [lateReport] ∧
    [lateReport].any (·.malformed earlyScope 15) = false ∧
    earlyScope.opportunity.closesAt ≤ 15 ∧
    Coverage.Complete earlyScope 15 (some completeCoverage) ∧
    evaluate earlyScope 15 15 [lateReport] (some completeCoverage) = .coveredNoCompletion ∧
    ¬ Exhaustive actualHistory earlyScope 15 [lateReport] := by
  refine ⟨actual_event_qualifies, ⟨lateReport, by simp, rfl, by decide⟩,
    ?_, by decide, early_window_closed, complete_coverage_well_scoped, by decide, ?_⟩
  · intro r hr _
    have same : r = lateReport := by simpa using hr
    subst r
    rfl
  · intro exhaustive
    obtain ⟨r, hr, _, _, deadline⟩ := exhaustive actualEvent actual_event_qualifies
    have same : r = lateReport := by simpa using hr
    subst r
    have impossible : ¬ (20 ≤ 15) := by decide
    exact impossible deadline

end UsulTest.IDAOmissionSemantics
