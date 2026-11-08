import Usul.Fixtures.Runner
import Usul.Fixtures.Sheaf

/-!
# v38/v39 contextual sheaf fixture corpus

Typed transcription of the source facts, observations, contexts, claims and
path tokens in `examples/v39_{affect,temporal,claim}_concern.pl`, followed by
the 58 named queries in `examples/v39_sheaf_concern.pl`. Qurʾānic and behavioral
warrants are preserved as source labels, not newly inferred normative facts.
The conflict and subject-scoping facts are deliberately synthetic fixtures.
-/

namespace UsulTest.Fixtures.Sheaf

open Usul.Fixtures Usul.Fixtures.Sheaf

def allahFear : Section :=
  ⟨"khawf", "allah_essence", .o, .comparative "other_than_allah", .quranic "3:175"⟩
def otherFear : Section :=
  ⟨"khawf", "other_than_allah", .f, .conditional "when_displaces_taqwa", .quranic "3:175"⟩
def raja : Section :=
  ⟨"raja", "allah_rahmah", .o, .unconditional, .quranic "39:53"⟩
def qunut : Section :=
  ⟨"qunut", "allah_rahmah", .f, .unconditional, .quranic "39:53"⟩
def hasad : Section :=
  ⟨"hasad", "creation_blessing", .f, .conditional "action_guiding", .behavioralProfile "hasad"⟩
def panic : Section :=
  ⟨"khawf_panic", "threat", .n, .conditional "involuntary", .somaticContextOnly⟩
def conflictObligation : Section :=
  ⟨"test_conflict_affect", "test_object", .o, .unconditional, .fixture "wajib_side"⟩
def conflictProhibition : Section :=
  ⟨"test_conflict_affect", "test_object", .f, .unconditional, .fixture "haram_side"⟩
def subjectScoped : Section :=
  ⟨"test_scoped_affect", "test_object", .f, .unconditional, .fixture "subject_scoped"⟩

def q3175 : Evidence := ⟨.tier1, .quranic "3:175"⟩
def q3953 : Evidence := ⟨.tier1, .quranic "39:53"⟩
def hasadEvidence : Evidence := ⟨.tier2, .behavioralProfile "hasad"⟩
def fixtureEvidence : Evidence := ⟨.fixture, .generated⟩
def quarantinedEvidence : Evidence := ⟨.tier4, .commentary "fixture"⟩

def database : Database where
  facts := [⟨allahFear, "all_mukallafin"⟩, ⟨otherFear, "all_mukallafin"⟩,
    ⟨raja, "all_mukallafin"⟩, ⟨qunut, "all_mukallafin"⟩, ⟨hasad, "all_mukallafin"⟩,
    ⟨panic, "all_mukallafin"⟩, ⟨conflictObligation, "all_mukallafin"⟩,
    ⟨conflictProhibition, "all_mukallafin"⟩, ⟨subjectScoped, "test_subject_class"⟩]
  aliases := [("ḥasad", "hasad"), ("test_ambiguous_alias", "test_conflict_affect"),
    ("test_ambiguous_alias", "test_scoped_affect")]
  contexts := [
    ⟨"w_allah_fear", "agent", [.tag "within_capacity", .strongerThan "other_than_allah"]⟩,
    ⟨"w_other_fear_defect", "agent", [.tag "within_capacity", .tag "when_displaces_taqwa"]⟩,
    ⟨"w_rahmah_balance", "agent", [.tag "within_capacity"]⟩,
    ⟨"w_yusuf_brothers", "brothers", [.tag "within_capacity", .tag "action_guiding"]⟩,
    ⟨"w_involuntary_panic", "agent", [.tag "involuntary"]⟩,
    ⟨"w_fixture_conflict", "agent", [.tag "within_capacity"]⟩,
    ⟨"w_other_fear_no_displacement", "agent", [.tag "within_capacity"]⟩,
    ⟨"w_allah_fear_no_precedence", "agent", [.tag "within_capacity"]⟩,
    ⟨"w_subject_inside", "member", [.tag "within_capacity"]⟩,
    ⟨"w_subject_outside", "outsider", [.tag "within_capacity"]⟩,
    ⟨"w_claim_alias", "agent", [.tag "within_capacity"]⟩,
    ⟨"w_claim_object", "agent", [.tag "within_capacity", .strongerThan "other_than_allah"]⟩,
    ⟨"w_claim_subject", "outsider", [.tag "within_capacity"]⟩,
    ⟨"w_claim_modality", "agent", [.tag "within_capacity"]⟩,
    ⟨"w_claim_capacity", "agent", [.tag "within_capacity", .tag "action_guiding"]⟩,
    ⟨"w_claim_tier", "agent", [.tag "within_capacity", .tag "when_displaces_taqwa"]⟩,
    ⟨"w_claim_unsupported", "agent", [.tag "within_capacity"]⟩,
    ⟨"w_claim_unobserved", "agent", [.tag "within_capacity"]⟩,
    ⟨"w_subject_unresolved", "stranger", [.tag "within_capacity"]⟩,
    ⟨"w_claim_unresolved_unobserved", "stranger", [.tag "within_capacity"]⟩,
    ⟨"w_subject_unresolved_unclaimed", "stranger", [.tag "within_capacity"]⟩]
  memberships := [("member", "test_subject_class")]
  closedSubjects := ["member", "outsider"]
  observations := [
    ⟨"w_allah_fear", "agent", "khawf", "allah_essence", q3175, .oriented⟩,
    ⟨"w_other_fear_defect", "agent", "khawf", "other_than_allah", q3175, .actionGuiding⟩,
    ⟨"w_rahmah_balance", "agent", "raja", "allah_rahmah", q3953, .oriented⟩,
    ⟨"w_rahmah_balance", "agent", "qunut", "allah_rahmah", q3953, .actionGuiding⟩,
    ⟨"w_yusuf_brothers", "brothers", "hasad", "creation_blessing", hasadEvidence, .actionGuiding⟩,
    ⟨"w_involuntary_panic", "agent", "khawf_panic", "threat", ⟨.tier3, .somaticContext⟩, .panicOverflow⟩,
    ⟨"w_fixture_conflict", "agent", "test_conflict_affect", "test_object", fixtureEvidence, .actionGuiding⟩,
    ⟨"w_other_fear_no_displacement", "agent", "khawf", "other_than_allah", q3175, .actionGuiding⟩,
    ⟨"w_allah_fear_no_precedence", "agent", "khawf", "allah_essence", q3175, .oriented⟩,
    ⟨"w_subject_inside", "member", "test_scoped_affect", "test_object", fixtureEvidence, .actionGuiding⟩,
    ⟨"w_subject_outside", "outsider", "test_scoped_affect", "test_object", fixtureEvidence, .actionGuiding⟩,
    ⟨"w_claim_object", "agent", "khawf", "other_than_allah", q3175, .oriented⟩,
    ⟨"w_claim_subject", "outsider", "test_scoped_affect", "test_object", fixtureEvidence, .actionGuiding⟩,
    ⟨"w_claim_modality", "agent", "khawf", "other_than_allah", q3175, .actionGuiding⟩,
    ⟨"w_claim_capacity", "agent", "hasad", "creation_blessing", hasadEvidence, .rawOccurrence⟩,
    ⟨"w_claim_tier", "agent", "khawf", "other_than_allah", quarantinedEvidence, .actionGuiding⟩,
    ⟨"w_claim_unsupported", "agent", "raja", "allah_rahmah", q3953, .oriented⟩,
    ⟨"w_subject_unresolved", "stranger", "test_scoped_affect", "test_object", fixtureEvidence, .actionGuiding⟩,
    ⟨"w_subject_unresolved_unclaimed", "stranger", "test_scoped_affect", "test_object", fixtureEvidence, .actionGuiding⟩]
  claims := [
    ⟨"w_allah_fear", "agent", allahFear, "candidate"⟩,
    ⟨"w_yusuf_brothers", "brothers", { hasad with affect := "ḥasad" }, "display_alias"⟩,
    ⟨"w_claim_alias", "agent", { conflictProhibition with affect := "test_ambiguous_alias" }, "ambiguous_alias"⟩,
    ⟨"w_claim_object", "agent", { allahFear with object := "other_than_allah" }, "wrong_object"⟩,
    ⟨"w_claim_subject", "outsider", subjectScoped, "outside_subject"⟩,
    ⟨"w_claim_modality", "agent", otherFear, "inactive_modality"⟩,
    ⟨"w_claim_capacity", "agent", hasad, "involuntary"⟩,
    ⟨"w_claim_tier", "agent", otherFear, "quarantined_evidence"⟩,
    ⟨"w_claim_unsupported", "agent", { raja with operator := .f }, "invented_verdict"⟩,
    ⟨"w_claim_unobserved", "agent", raja, "no_observation"⟩,
    ⟨"w_claim_no_context", "agent", raja, "no_context"⟩,
    ⟨"w_subject_unresolved", "stranger", subjectScoped, "unknown_membership"⟩,
    ⟨"w_claim_unresolved_unobserved", "stranger", subjectScoped, "unknown_membership_without_observation"⟩]
  realizations := [
    ⟨"path_allah_fear_ok", "agent", "khawf", "allah_essence"⟩,
    ⟨"path_other_fear_defect", "agent", "khawf", "other_than_allah"⟩,
    ⟨"path_raja_ok", "agent", "raja", "allah_rahmah"⟩,
    ⟨"path_qunut_without_raja", "agent", "qunut", "allah_rahmah"⟩,
    ⟨"path_yusuf_brothers", "brothers", "hasad", "creation_blessing"⟩,
    ⟨"path_panic_only", "agent", "khawf_panic", "threat"⟩]
  scopes := [
    ⟨"path_allah_fear_ok", "agent", "khawf", "allah_essence"⟩,
    ⟨"path_raja_ok", "agent", "raja", "allah_rahmah"⟩,
    ⟨"path_qunut_without_raja", "agent", "raja", "allah_rahmah"⟩]
  antiPairs := [⟨"raja", "qunut", "allah_rahmah"⟩]

def hasLocal (world agent affect object : String) (operator : Operator) : Bool :=
  (localSections database world agent).any (fun s =>
    s.affect == affect && s.object == object && s.operator == operator)

def hasObservation (world agent affect object : String) (control : Control) : Bool :=
  (observationsFor database world agent affect object).any (·.control == control)

def contextHas (world agent : String) (condition : Condition) : Bool :=
  (contextsFor database world agent).any (·.conditions.contains condition)

def contextLacks (world agent : String) (condition : Condition) : Bool :=
  (contextsFor database world agent).any (fun c => !c.conditions.contains condition)

def claimsAt (world : String) : List Claim := database.claims.filter (·.world == world)

def hasClaimReason (world : String) (category : Category) (detail : Detail) : Bool :=
  (claimsAt world).any (fun claim => (claimObstructions database claim).contains (category, detail))

def hasClaimObstruction (world : String) : Bool :=
  (claimsAt world).any (fun claim => !(claimObstructions database claim).isEmpty)

def hasClaimUnknown (world : String) (unknown : Unknown) : Bool :=
  (claimsAt world).any (fun claim => (claimUnknowns database claim).contains unknown)

def hasPathReason (world path : String) (reason : PathReason) : Bool :=
  (pathReasons database world path).contains reason

def unresolvedMembership : Unknown := .subjectMembership "stranger" "test_subject_class"

/-- Named queries preserve the source predicates' existential wildcard meaning. -/
def fixtures : List Fixture := [
  .ofBool "allah_fear_path_glues" true
    (pathVerdict database "w_allah_fear" "path_allah_fear_ok").gluable,
  .ofBool "other_fear_displacing_taqwa_blocks" true
    (hasPathReason "w_other_fear_defect" "path_other_fear_defect"
      (.forbidden "khawf" "other_than_allah" (.quranic "3:175"))),
  .ofBool "qunut_without_raja_blocks_by_forbidden_and_antipair" true
    (!(pathReasons database "w_rahmah_balance" "path_qunut_without_raja").isEmpty),
  .ofBool "yusuf_brothers_hasad_blocks" true
    (hasPathReason "w_yusuf_brothers" "path_yusuf_brothers"
      (.forbidden "hasad" "creation_blessing" (.behavioralProfile "hasad"))),
  .ofBool "involuntary_panic_not_direct_liability" true
    (pathVerdict database "w_involuntary_panic" "path_panic_only").gluable,
  .ofBool "operator_conflict_emits_obstruction" true
    (!(worldObstructions database "w_fixture_conflict").isEmpty),
  .ofBool "qunut_without_raja_emits_forbidden" true
    (hasPathReason "w_rahmah_balance" "path_qunut_without_raja"
      (.forbidden "qunut" "allah_rahmah" (.quranic "39:53"))),
  .ofBool "qunut_without_raja_emits_missing_required" true
    (hasPathReason "w_rahmah_balance" "path_qunut_without_raja"
      (.missingRequired "raja" "allah_rahmah" (.quranic "39:53"))),
  .ofBool "qunut_without_raja_emits_anti_pair_displacement" true
    (hasPathReason "w_rahmah_balance" "path_qunut_without_raja"
      (.antiPairDisplacement "raja" "qunut" "allah_rahmah")),
  .ofBool "raja_path_glues" true (pathVerdict database "w_rahmah_balance" "path_raja_ok").gluable,
  .ofBool "raja_path_has_no_missing_required" false
    ((pathReasons database "w_rahmah_balance" "path_raja_ok").any fun
      | .missingRequired _ _ _ => true | _ => false)
    [database.scopes.contains ⟨"path_raja_ok", "agent", "raja", "allah_rahmah"⟩,
     hasLocal "w_rahmah_balance" "agent" "raja" "allah_rahmah" .o],
  .ofBool "distinct_affects_do_not_conflict" false
    (!(worldObstructions database "w_rahmah_balance").isEmpty)
    [hasLocal "w_rahmah_balance" "agent" "raja" "allah_rahmah" .o,
     hasLocal "w_rahmah_balance" "agent" "qunut" "allah_rahmah" .f],
  .ofBool "involuntary_panic_lifts_no_section" false
    (!(localSections database "w_involuntary_panic" "agent").isEmpty)
    [hasObservation "w_involuntary_panic" "agent" "khawf_panic" "threat" .panicOverflow,
     database.facts.any (fun f => f.value.affect == "khawf_panic" && f.value.object == "threat")],
  .ofBool "involuntary_panic_path_has_no_obstruction" false
    (!(pathReasons database "w_involuntary_panic" "path_panic_only").isEmpty)
    [realizes database "path_panic_only" "agent" "khawf_panic" "threat"],
  .ofBool "other_fear_without_displacement_not_forbidden" false
    ((pathReasons database "w_other_fear_no_displacement" "path_other_fear_defect").any fun
      | .forbidden "khawf" "other_than_allah" _ => true | _ => false)
    [hasObservation "w_other_fear_no_displacement" "agent" "khawf" "other_than_allah" .actionGuiding,
     contextLacks "w_other_fear_no_displacement" "agent" (.tag "when_displaces_taqwa"),
     realizes database "path_other_fear_defect" "agent" "khawf" "other_than_allah"],
  .ofBool "allah_fear_with_precedence_lifts_obligation" true
    ((localSections database "w_allah_fear" "agent").contains allahFear),
  .ofBool "allah_fear_without_precedence_lifts_no_obligation" false
    (hasLocal "w_allah_fear_no_precedence" "agent" "khawf" "allah_essence" .o)
    [hasObservation "w_allah_fear_no_precedence" "agent" "khawf" "allah_essence" .oriented,
     contextLacks "w_allah_fear_no_precedence" "agent" (.strongerThan "other_than_allah")],
  .ofBool "subject_scoped_fact_lifts_inside_subject" true
    ((localSections database "w_subject_inside" "member").contains subjectScoped),
  .ofBool "subject_scoped_fact_does_not_lift_outside_subject" false
    (!(localSections database "w_subject_outside" "outsider").isEmpty)
    [hasObservation "w_subject_outside" "outsider" "test_scoped_affect" "test_object" .actionGuiding,
     !database.memberships.contains ("outsider", "test_subject_class")],
  .ofBool "claim_with_alias_ambiguity_emits_only_alias_gluing_failure" true
    (claimCategories database "w_claim_alias" == [.aliasGluingFailure]),
  .ofBool "alias_gluing_failure_names_alias_and_candidates" true
    (hasClaimReason "w_claim_alias" .aliasGluingFailure
      (.ambiguousAlias "test_ambiguous_alias" ["test_conflict_affect", "test_scoped_affect"])),
  .ofBool "claim_on_wrong_object_emits_only_object_collision" true
    (claimCategories database "w_claim_object" == [.objectCollision]),
  .ofBool "object_collision_names_claimed_and_source_objects" true
    (hasClaimReason "w_claim_object" .objectCollision (.claimedObject "other_than_allah" "allah_essence")),
  .ofBool "claim_outside_subject_emits_only_subject_collision" true
    (claimCategories database "w_claim_subject" == [.subjectCollision]),
  .ofBool "subject_collision_names_agent_and_subject" true
    (hasClaimReason "w_claim_subject" .subjectCollision (.outsideSubject "outsider" "test_subject_class")),
  .ofBool "claim_with_inactive_modality_emits_only_modality_unsatisfied" true
    (claimCategories database "w_claim_modality" == [.modalityUnsatisfied]),
  .ofBool "modality_unsatisfied_names_modality" true
    (hasClaimReason "w_claim_modality" .modalityUnsatisfied (.inactive (.conditional "when_displaces_taqwa"))),
  .ofBool "claim_on_involuntary_affect_emits_only_capacity_violation" true
    (claimCategories database "w_claim_capacity" == [.capacityViolation]),
  .ofBool "capacity_violation_names_control_status" true
    (hasClaimReason "w_claim_capacity" .capacityViolation (.controlStatus .rawOccurrence)),
  .ofBool "claim_on_quarantined_evidence_emits_only_tier_quarantine" true
    (claimCategories database "w_claim_tier" == [.tierQuarantine]),
  .ofBool "tier_quarantine_names_evidence" true
    (hasClaimReason "w_claim_tier" .tierQuarantine (.quarantinedEvidence quarantinedEvidence)),
  .ofBool "claim_without_source_fact_is_unsupported" true
    (hasClaimReason "w_claim_unsupported" .unsupportedClaim .noSourceFact),
  .ofBool "claim_without_observation_is_unsupported" true
    (hasClaimReason "w_claim_unobserved" .unsupportedClaim .noObservation),
  .ofBool "claim_without_context_is_unsupported" true
    (hasClaimReason "w_claim_no_context" .unsupportedClaim .noContext),
  .ofBool "claim_without_context_has_only_no_context" true
    ((claimsAt "w_claim_no_context").flatMap (fun c => (claimObstructions database c).map Prod.snd) == [.noContext]),
  .ofBool "quarantined_evidence_lifts_no_section" false
    (!(localSections database "w_claim_tier" "agent").isEmpty)
    [(observationsFor database "w_claim_tier" "agent" "khawf" "other_than_allah").any
      (fun o => o.evidence.tier == .tier4 && o.control == .actionGuiding),
     contextHas "w_claim_tier" "agent" (.tag "when_displaces_taqwa")],
  .ofBool "quarantined_evidence_supports_no_forbidden_path" false
    ((pathReasons database "w_claim_tier" "path_other_fear_defect").any fun
      | .forbidden _ _ _ => true | _ => false)
    [realizes database "path_other_fear_defect" "agent" "khawf" "other_than_allah",
     !(contextsFor database "w_claim_tier" "agent").isEmpty],
  .ofBool "lifted_claim_is_clean" false (hasClaimObstruction "w_allah_fear")
    [(claimsAt "w_allah_fear").any (·.agent == "agent")],
  .ofBool "display_alias_claim_normalizes_and_is_clean" false (hasClaimObstruction "w_yusuf_brothers")
    [(claimsAt "w_yusuf_brothers").any (fun c => c.agent == "brothers" && c.value.affect == "ḥasad"),
     database.aliases.contains ("ḥasad", "hasad")],
  .ofBool "claim_obstruction_blocks_world_gluing" true
    ((worldObstructions database "w_claim_subject").any fun
      | .claim "outsider" _ .subjectCollision _ => true | _ => false),
  .ofBool "world_with_obstructed_claim_is_not_gluable" false
    (worldVerdict database "w_claim_subject").gluable
    [!(contextsFor database "w_claim_subject" "outsider").isEmpty],
  .ofBool "every_obstruction_category_is_emitted" true
    (allCategories.all (emittedCategories database).contains),
  .ofBool "clean_world_verdict_glues_with_its_sections" true
    (match worldVerdict database "w_allah_fear" with
     | .glues sections => sections.any (fun (agent, s) => agent == "agent" &&
         s.affect == "khawf" && s.object == "allah_essence" && s.operator == .o)
     | _ => false),
  .ofBool "conflict_world_verdict_is_obstructed" true
    (match worldVerdict database "w_fixture_conflict" with
     | .obstructed [.conflict _ _] => true | _ => false),
  .ofBool "unresolved_subject_world_is_undetermined" true
    (worldVerdict database "w_subject_unresolved" == .undetermined [unresolvedMembership]),
  .ofBool "unknown_membership_without_claim_is_undetermined" true
    (worldVerdict database "w_subject_unresolved_unclaimed" == .undetermined [unresolvedMembership]),
  .ofBool "undetermined_world_is_not_gluable" false
    (worldVerdict database "w_subject_unresolved").gluable
    [!(contextsFor database "w_subject_unresolved" "stranger").isEmpty],
  .ofBool "world_without_context_is_undetermined" true
    (worldVerdict database "w_no_such_world" == .undetermined [.worldContext]),
  .ofBool "closed_outsider_world_glues" true
    (worldVerdict database "w_subject_outside" == .glues []),
  .ofBool "unbound_world_verdict_raises" true
    (match queryWorldVerdict database none with
     | .error "instantiation_error: world" => true | _ => false),
  .ofBool "every_fixture_world_has_exactly_one_verdict" true
    ((canonical (database.contexts.map (·.world))).all (fun world => (worldVerdict database world).valid)),
  .ofBool "obstructed_path_verdict_lists_every_reason" true
    (match pathVerdict database "w_rahmah_balance" "path_qunut_without_raja" with
     | .obstructed reasons => reasons.length == 3 | _ => false),
  .ofBool "clean_path_verdict_glues" true
    (pathVerdict database "w_allah_fear" "path_allah_fear_ok").gluable,
  .ofBool "undetermined_world_makes_path_undetermined" true
    (match pathVerdict database "w_subject_unresolved" "path_raja_ok" with
     | .undetermined _ => true | _ => false),
  .ofBool "claim_with_unknown_membership_is_undetermined" true
    (hasClaimUnknown "w_subject_unresolved" unresolvedMembership),
  .ofBool "obstruction_takes_precedence_over_unknown_membership" true
    ((claimsAt "w_claim_unresolved_unobserved").flatMap (claimStates database) == [.obstructed]),
  .ofBool "claim_with_unknown_membership_is_not_obstructed" false
    (hasClaimObstruction "w_subject_unresolved")
    [(claimsAt "w_subject_unresolved").any (·.agent == "stranger"),
     !database.closedSubjects.contains "stranger"],
  .ofBool "every_claim_has_exactly_one_state" true
    (database.claims.all (fun claim => (canonical (claimStates database claim)).length == 1))
    [database.claims.length >= 13]
]

end UsulTest.Fixtures.Sheaf
