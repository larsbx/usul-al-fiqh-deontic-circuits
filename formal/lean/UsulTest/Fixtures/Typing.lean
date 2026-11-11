import Usul.Fixtures.Runner
import Usul.Fixtures.Typing

/-! The original 31 named routing expectations, with all nine negative premises.
Queries execute the finite relation model over the complete generated export. -/
namespace UsulTest.Fixtures.Typing
open Usul.Fixtures
open Usul.Fixtures.Typing

def fixtures : List Fixture := [
  .ofBool "well_typed" true allExportedWellTyped,
  .ofBool "ill_typed_caught" true (illTyped "fx_untyped" "no_such_field"),
  .ofBool "q14_shared_transgression" true
    (shares "transgressed" "trust_loss" "trust_voidance"),
  .ofBool "q28_shared_original" true
    (shares "original_possible" "substitute" "substitute_at_obligation"),
  .ofBool "negligence_routes_trust_loss" true (route "s_trustee" "trust_loss"),
  .ofBool "negligence_does_not_settle_inquiry" false (applies "excused_error" "s_trustee")
    [(stated "s_trustee").contains ("negligent", "true")],
  .ofBool "inquiry_is_the_missing_fact" true
    (missingFact "excused_error" "s_trustee" "negligent_inquiry"),
  .ofBool "negligence_fields_not_shared" false
    (shares "negligent" "excused_error" "trust_loss") [reads "trust_loss" "negligent"],
  .ofBool "itlaf_needs_q13" false (applies "itlaf" "s_purpose")
    [(stated "s_purpose").contains ("purpose", "benefit")],
  .ofBool "itlaf_missing_mental" true (missingFact "itlaf" "s_purpose" "mental"),
  .ofBool "luqata_extends_majhul" true (fieldOf "luqata" "unknown"),
  .ofBool "rukhsa_reaches_yaqin" true (fieldOf "rukhsa" "asl"),
  .ofBool "amana_is_not_yaqin" false (fieldOf "amana" "asl") [qaidaDeclared "amana"],
  .ofBool "known_field_not_missing" false (missingFact "trust_loss" "s_trustee" "hand")
    [(stated "s_trustee").contains ("hand", "trustee")],
  .ofBool "no_silent_identification" true noSilentIdentification,
  .ofBool "silent_identification_caught" true
    (unrelatedSharedField "fx_field" "fx_left" "fx_right"),
  .ofBool "year_settles_despair" true (holds "s_luqata" "despair" "true"),
  .ofBool "luqata_routes_to_majhul" true (route "s_luqata" "unknown_as_nonexistent"),
  .ofBool "stated_fact_kept" false (holds "s_hoped" "despair" "true")
    [(stated "s_hoped").contains ("despair", "false")],
  .ofBool "premise_required" false (holds "s_within_year" "despair" "true")
    [(stated "s_within_year").contains ("year_passed", "false")],
  .ofBool "consumed_is_unidentified" true (holds "s_consumed" "owner_identifiable" "false"),
  .ofBool "rukhsa_settles_firmness" true (holds "s_rukhsa" "needs_firm" "true"),
  .ofBool "q95_negligence_is_inquiry" true (holds "s_q95" "negligent_inquiry" "true"),
  .ofBool "q6_diligence_is_q95" true (holds "s_q6" "negligent_q95" "false"),
  .ofBool "q97_despair_is_106" true (holds "s_q97" "despair" "true"),
  .ofBool "q97_known_owner_not_majhul" false (known "s_q97" "unknown")
    [holds "s_q97" "despair" "true"],
  .ofBool "q97_unknown_owner_is_unidentified" true
    (holds "s_q97_unknown" "owner_identifiable" "false"),
  .ofBool "q98_owner_is_106_unknown" true (holds "s_q98" "unknown" "true"),
  .ofBool "q106_unknown_not_q98" false (known "s_luqata" "owner_unknown")
    [(stated "s_luqata").contains ("unknown", "true")],
  .ofBool "ghalaba_is_zahir" true (applies "doubt_in_condition" "s_doubt"),
  .ofBool "coverage_counts_known_fields" true (coverage "itlaf" "s_purpose" == some (1, 2))
]

/-- The generated legacy inventory binds every name, polarity, and premise count. -/
def inventoryAgrees : Bool :=
  fixtures.map (fun fixture => (fixture.name, fixture.expected, fixture.premises.length)) ==
    Data.referenceExpectations

/-- Conflicting derived values must both survive and feed later implications. -/
def conflictRelations : List Rule := [
  ⟨"positive", [("seed", "true")], [("derived", "true")]⟩,
  ⟨"negative", [("seed", "true")], [("derived", "false")]⟩,
  ⟨"uses_both", [("derived", "true"), ("derived", "false")], [("joined", "true")]⟩
]

def conflictClosure : Facts := close conflictRelations [("seed", "true")]

def derivedConflictRetained : Bool :=
  conflictClosure.contains ("derived", "true") &&
  conflictClosure.contains ("derived", "false") && conflictClosure.contains ("joined", "true")

/-- Stating the conflicting field blocks the other derived value and its join. -/
def statedConflictBlocked : Bool :=
  let facts := close conflictRelations [("seed", "true"), ("derived", "false")]
  facts.contains ("derived", "false") && !facts.contains ("derived", "true") &&
    !facts.contains ("joined", "true")

end UsulTest.Fixtures.Typing
