import Usul.Typing.IDAOmission

/-!
# Conditional semantic adequacy of omission observations

An independently supplied history describes completion events. Reports are a
separate input. Exhaustiveness and soundness connect the two without defining
the history from the reports or deriving either condition from authentication.

The bounded event content below consists of the exact native omission scope,
one of the native two completion modes, and an occurrence time. It does not
assert a globally unique physical event identity. Its history predicate can
model stipulated events; interpreting it as an actual history needs external
justification.
-/

namespace Usul.IDA.Omission.Semantics

structure Event where
  scope : Scope
  mode : Mode
  occurredAt : Nat
  deriving DecidableEq, Repr

/-- This event predicate is distinct from ACT-04's fixed-predicate
`Usul.IDA.Semantics.History`. Relating those two models is a separate obligation. -/
abbrev History := Event → Prop

/-- Recording time belongs to the report, not to the represented event. -/
def eventOf (r : Completion) : Event := ⟨r.scope, r.mode, r.occurredAt⟩

def Represents (r : Completion) (e : Event) : Prop := eventOf r = e

/-- Qualification concerns the entire half-open opportunity. The effective
time is handled separately when closure justifies a full-window conclusion. -/
def Qualifies (h : History) (s : Scope) (e : Event) : Prop :=
  h e ∧ e.scope = s ∧
    s.opportunity.opensAt ≤ e.occurredAt ∧ e.occurredAt < s.opportunity.closesAt

def NoQualifying (h : History) (s : Scope) : Prop := ¬ ∃ e, Qualifies h s e

/-- Each qualifying event has a report for the same exact event content,
chronologically recorded and visible by the declared recording cutoff. This
semantic premise is distinct from, and not established by, the native
structural coverage check. -/
def Exhaustive (h : History) (s : Scope) (cutoff : Nat)
    (reports : List Completion) : Prop :=
  ∀ e, Qualifies h s e →
    ∃ r ∈ reports, Represents r e ∧
      r.occurredAt ≤ r.recordedAt ∧ r.recordedAt ≤ cutoff

/-- Only reports selected by the native matching predicate need this premise.
It does not require every unrelated, future, or nonmatching report to be true. -/
def SoundFor (h : History) (s : Scope) (effective cutoff : Nat)
    (reports : List Completion) : Prop :=
  ∀ r ∈ reports, r.matches s effective cutoff = true → h (eventOf r)

@[simp] theorem eventOf_scope (r : Completion) : (eventOf r).scope = r.scope := rfl
@[simp] theorem eventOf_mode (r : Completion) : (eventOf r).mode = r.mode := rfl
@[simp] theorem eventOf_occurredAt (r : Completion) :
    (eventOf r).occurredAt = r.occurredAt := rfl

theorem represents_iff (r : Completion) (e : Event) :
    Represents r e ↔
      r.scope = e.scope ∧ r.mode = e.mode ∧ r.occurredAt = e.occurredAt := by
  cases r
  cases e
  simp [Represents, eventOf]

theorem completion_matches_iff (r : Completion) (s : Scope)
    (effective cutoff : Nat) :
    r.matches s effective cutoff = true ↔
      r.scope = s ∧ r.recordedAt ≤ cutoff ∧ r.occurredAt ≤ r.recordedAt ∧
      s.opportunity.opensAt ≤ r.occurredAt ∧
      r.occurredAt < s.opportunity.closesAt ∧ r.occurredAt ≤ effective := by
  simp [Completion.matches, Completion.visible, Bool.and_eq_true, and_assoc]

/-- A timely report representing a qualifying event matches once the whole
opportunity is closed at the effective time. -/
theorem matches_of_qualifies {h : History} {s : Scope} {e : Event}
    {r : Completion} {effective cutoff : Nat}
    (qualifies : Qualifies h s e) (represents : Represents r e)
    (chronological : r.occurredAt ≤ r.recordedAt) (visible : r.recordedAt ≤ cutoff)
    (closed : s.opportunity.closesAt ≤ effective) :
    r.matches s effective cutoff = true := by
  rcases qualifies with ⟨_, eventScope, opens, closes⟩
  rcases (represents_iff r e).mp represents with ⟨reportScope, _, occurrence⟩
  apply (completion_matches_iff r s effective cutoff).mpr
  refine ⟨reportScope.trans eventScope, visible, chronological, ?_, ?_, ?_⟩
  · simpa [occurrence] using opens
  · simpa [occurrence] using closes
  · rw [occurrence]
    exact Nat.le_trans (Nat.le_of_lt closes) closed

/-- A matching report represents a qualifying event under the explicit
soundness assumption for reports actually used by this observation. -/
theorem qualifies_of_matching {h : History} {s : Scope} {effective cutoff : Nat}
    {reports : List Completion} {r : Completion}
    (sound : SoundFor h s effective cutoff reports) (member : r ∈ reports)
    (matching : r.matches s effective cutoff = true) :
    Qualifies h s (eventOf r) := by
  rcases (completion_matches_iff r s effective cutoff).mp matching with
    ⟨scope, _, _, opens, closes, _⟩
  exact ⟨sound r member matching, scope, opens, closes⟩

theorem matching_report_of_qualifying {h : History} {s : Scope} {e : Event}
    {effective cutoff : Nat} {reports : List Completion}
    (qualifies : Qualifies h s e) (exhaustive : Exhaustive h s cutoff reports)
    (closed : s.opportunity.closesAt ≤ effective) :
    ∃ r ∈ reports, Represents r e ∧ r.matches s effective cutoff = true := by
  obtain ⟨r, member, represents, chronological, visible⟩ := exhaustive e qualifies
  exact ⟨r, member, represents,
    matches_of_qualifies qualifies represents chronological visible closed⟩

/-- Conditional soundness: a covered negative observation excludes qualifying
events in the supplied history if all such events would have timely reports.
Report soundness is unnecessary in this direction. -/
theorem covered_no_completion_sound {h : History} {s : Scope}
    {effective cutoff : Nat} {reports : List Completion} {coverage : Option Coverage}
    (covered : evaluate s effective cutoff reports coverage = .coveredNoCompletion)
    (exhaustive : Exhaustive h s cutoff reports) : NoQualifying h s := by
  rcases (covered_iff s effective cutoff reports coverage).mp covered with
    ⟨_, noMatching, closed, _⟩
  rintro ⟨e, qualifies⟩
  obtain ⟨r, member, _, matching⟩ :=
    matching_report_of_qualifying qualifies exhaustive closed
  have observed : reports.any (·.matches s effective cutoff) = true :=
    List.any_eq_true.mpr ⟨r, member, matching⟩
  rw [noMatching] at observed
  cases observed

/-- Conditional completeness: absence in the supplied history rules out all
matching reports only under soundness. Structural observation gates remain
separate requirements. Exhaustiveness is unnecessary in this direction. -/
theorem covered_no_completion_complete {h : History} {s : Scope}
    {effective cutoff : Nat} {reports : List Completion} {coverage : Option Coverage}
    (noQualifying : NoQualifying h s)
    (sound : SoundFor h s effective cutoff reports)
    (noMalformed : reports.any (·.malformed s cutoff) = false)
    (closed : s.opportunity.closesAt ≤ effective)
    (coverageComplete : Coverage.Complete s cutoff coverage) :
    evaluate s effective cutoff reports coverage = .coveredNoCompletion := by
  apply (covered_iff s effective cutoff reports coverage).mpr
  refine ⟨noMalformed, ?_, closed, coverageComplete⟩
  apply List.any_eq_false.mpr
  intro r member matching
  exact noQualifying ⟨eventOf r, qualifies_of_matching sound member matching⟩

theorem covered_no_completion_iff {h : History} {s : Scope}
    {effective cutoff : Nat} {reports : List Completion} {coverage : Option Coverage}
    (exhaustive : Exhaustive h s cutoff reports)
    (sound : SoundFor h s effective cutoff reports)
    (noMalformed : reports.any (·.malformed s cutoff) = false)
    (closed : s.opportunity.closesAt ≤ effective)
    (coverageComplete : Coverage.Complete s cutoff coverage) :
    evaluate s effective cutoff reports coverage = .coveredNoCompletion ↔
      NoQualifying h s := by
  exact ⟨fun covered => covered_no_completion_sound covered exhaustive,
    fun absent => covered_no_completion_complete absent sound noMalformed closed coverageComplete⟩

/-- The native wrapper first resolves the exact current snapshot. The semantic
premise is still supplied independently for the scope extracted from it. -/
theorem review_covered_no_completion_sound
    {registry : ActRegistry.Registry} {catalog : Context.Catalog}
    {expected : Context.Snapshot} {reports : List Completion} {coverage : Option Coverage}
    {h : History} {s : Scope}
    (reviewed : review registry catalog expected reports coverage = .ok (some .coveredNoCompletion))
    (scope : Scope.fromSnapshot expected = some s)
    (exhaustive : Exhaustive h s expected.time.cutoff reports) :
    Context.resolve registry catalog expected = .ok expected ∧ NoQualifying h s := by
  have current := review_current reviewed
  have covered : evaluate s expected.envelope.context.effectiveAt expected.time.cutoff
      reports coverage = .coveredNoCompletion := by
    simpa [review, current, scope] using reviewed
  exact ⟨current, covered_no_completion_sound covered exhaustive⟩

#print axioms eventOf_scope
#print axioms eventOf_mode
#print axioms eventOf_occurredAt
#print axioms represents_iff
#print axioms completion_matches_iff
#print axioms matches_of_qualifies
#print axioms qualifies_of_matching
#print axioms matching_report_of_qualifying
#print axioms covered_no_completion_sound
#print axioms covered_no_completion_complete
#print axioms covered_no_completion_iff
#print axioms review_covered_no_completion_sound

end Usul.IDA.Omission.Semantics
