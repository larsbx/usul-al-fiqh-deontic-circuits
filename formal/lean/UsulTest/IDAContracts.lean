import UsulTest.IDA

/-!
# Fixed IDA theorem contracts

These named witnesses state the acceptance propositions independently of the
types inferred from the implementation declarations. Each proof is a direct use
of the required theorem: replacing that theorem with a weaker statement must
fail here, even if its name and axiom inventory remain unchanged.

The algebra contracts implement specification section 3. The conjunction
contracts preserve all seven scope fields, both required premises, nonempty
known answers, and the distinction between missing information and explicit
permission. The final contracts fix the declared finite wire format and cases.

Keep these propositions explicit. Do not replace their types with inferred
aliases or reprove them independently of the required implementation theorem.
-/

namespace UsulTest.IDAContracts

open Usul Usul.IDA

/-! ## Bounded distributive lattice and omission duality (27 contracts) -/

theorem require_Usul_IDA_meet_le_left :
    ∀ a b : Hukm, meet a b ≤ a :=
  Usul.IDA.meet_le_left

theorem require_Usul_IDA_meet_le_right :
    ∀ a b : Hukm, meet a b ≤ b :=
  Usul.IDA.meet_le_right

theorem require_Usul_IDA_le_meet_iff :
    ∀ a b c : Hukm, a ≤ meet b c ↔ a ≤ b ∧ a ≤ c :=
  Usul.IDA.le_meet_iff

theorem require_Usul_IDA_left_le_join :
    ∀ a b : Hukm, a ≤ join a b :=
  Usul.IDA.left_le_join

theorem require_Usul_IDA_right_le_join :
    ∀ a b : Hukm, b ≤ join a b :=
  Usul.IDA.right_le_join

theorem require_Usul_IDA_join_le_iff :
    ∀ a b c : Hukm, join a b ≤ c ↔ a ≤ c ∧ b ≤ c :=
  Usul.IDA.join_le_iff

theorem require_Usul_IDA_meet_comm :
    ∀ a b : Hukm, meet a b = meet b a :=
  Usul.IDA.meet_comm

theorem require_Usul_IDA_join_comm :
    ∀ a b : Hukm, join a b = join b a :=
  Usul.IDA.join_comm

theorem require_Usul_IDA_meet_assoc :
    ∀ a b c : Hukm, meet (meet a b) c = meet a (meet b c) :=
  Usul.IDA.meet_assoc

theorem require_Usul_IDA_join_assoc :
    ∀ a b c : Hukm, join (join a b) c = join a (join b c) :=
  Usul.IDA.join_assoc

theorem require_Usul_IDA_meet_idem :
    ∀ a : Hukm, meet a a = a :=
  Usul.IDA.meet_idem

theorem require_Usul_IDA_join_idem :
    ∀ a : Hukm, join a a = a :=
  Usul.IDA.join_idem

theorem require_Usul_IDA_meet_absorb :
    ∀ a b : Hukm, meet a (join a b) = a :=
  Usul.IDA.meet_absorb

theorem require_Usul_IDA_join_absorb :
    ∀ a b : Hukm, join a (meet a b) = a :=
  Usul.IDA.join_absorb

theorem require_Usul_IDA_meet_join_distrib :
    ∀ a b c : Hukm, meet a (join b c) = join (meet a b) (meet a c) :=
  Usul.IDA.meet_join_distrib

theorem require_Usul_IDA_join_meet_distrib :
    ∀ a b c : Hukm, join a (meet b c) = meet (join a b) (join a c) :=
  Usul.IDA.join_meet_distrib

theorem require_Usul_IDA_meet_top :
    ∀ a : Hukm, meet a .wajib = a :=
  Usul.IDA.meet_top

theorem require_Usul_IDA_join_bottom :
    ∀ a : Hukm, join a .haram = a :=
  Usul.IDA.join_bottom

theorem require_Usul_IDA_meet_bottom :
    ∀ a : Hukm, meet a .haram = .haram :=
  Usul.IDA.meet_bottom

theorem require_Usul_IDA_join_top :
    ∀ a : Hukm, join a .wajib = .wajib :=
  Usul.IDA.join_top

theorem require_Usul_IDA_bottom_le :
    ∀ a : Hukm, Hukm.haram ≤ a :=
  Usul.IDA.bottom_le

theorem require_Usul_IDA_le_top :
    ∀ a : Hukm, a ≤ Hukm.wajib :=
  Usul.IDA.le_top

theorem require_Usul_IDA_sigma_involutive :
    ∀ a : Hukm, sigma (sigma a) = a :=
  Usul.IDA.sigma_involutive

theorem require_Usul_IDA_sigma_order_reversing :
    ∀ {a b : Hukm}, a ≤ b → sigma b ≤ sigma a :=
  @Usul.IDA.sigma_order_reversing

theorem require_Usul_IDA_sigma_le_sigma_iff :
    ∀ a b : Hukm, sigma a ≤ sigma b ↔ b ≤ a :=
  Usul.IDA.sigma_le_sigma_iff

theorem require_Usul_IDA_sigma_meet :
    ∀ a b : Hukm, sigma (meet a b) = join (sigma a) (sigma b) :=
  Usul.IDA.sigma_meet

theorem require_Usul_IDA_sigma_join :
    ∀ a b : Hukm, sigma (join a b) = meet (sigma a) (sigma b) :=
  Usul.IDA.sigma_join

/-! ## Scope, required premises, partial answers, and decoding (20 contracts) -/

theorem require_Usul_IDA_Key_eq_iff_fields :
    ∀ a b : Key, a = b ↔
      a.question = b.question ∧ a.subject = b.subject ∧ a.target = b.target ∧
      a.context = b.context ∧ a.time = b.time ∧ a.profile = b.profile ∧
      a.version = b.version :=
  Usul.IDA.Key.eq_iff_fields

theorem require_Usul_IDA_outOfScope_iff :
    ∀ (lk rk : Key) (left right : Input),
      combine lk rk left right = .outOfScope ↔ lk ≠ rk :=
  Usul.IDA.outOfScope_iff

theorem require_Usul_IDA_inScope_iff_all_fields :
    ∀ (lk rk : Key) (left right : Input),
      combine lk rk left right ≠ .outOfScope ↔
        lk.question = rk.question ∧ lk.subject = rk.subject ∧ lk.target = rk.target ∧
        lk.context = rk.context ∧ lk.time = rk.time ∧ lk.profile = rk.profile ∧
        lk.version = rk.version :=
  Usul.IDA.inScope_iff_all_fields

theorem require_Usul_IDA_known_result_exact :
    ∀ {lk rk : Key} {left right result : Constraint},
      combine lk rk (.known left) (.known right) = .known result →
        lk = rk ∧ result.set = left.set.inter right.set :=
  @Usul.IDA.known_result_exact

theorem require_Usul_IDA_known_result_subset_both :
    ∀ {lk rk : Key} {left right result : Constraint},
      combine lk rk (.known left) (.known right) = .known result →
        result.set.Subset left.set ∧ result.set.Subset right.set :=
  @Usul.IDA.known_result_subset_both

theorem require_Usul_IDA_known_result_nonempty :
    ∀ {lk rk : Key} {left right : Input} {result : Constraint},
      combine lk rk left right = .known result → result.set.Nonempty :=
  @Usul.IDA.known_result_nonempty

theorem require_Usul_IDA_known_requires_two_known :
    ∀ {lk rk : Key} {left right : Input} {result : Constraint},
      combine lk rk left right = .known result →
        lk = rk ∧ ∃ l r : Constraint, left = .known l ∧ right = .known r ∧
          result.set = l.set.inter r.set :=
  @Usul.IDA.known_requires_two_known

theorem require_Usul_IDA_missing_left_not_known :
    ∀ (lk rk : Key) (right : Input) (result : Constraint),
      combine lk rk .noRuling right ≠ .known result :=
  Usul.IDA.missing_left_not_known

theorem require_Usul_IDA_missing_right_not_known :
    ∀ (lk rk : Key) (left : Input) (result : Constraint),
      combine lk rk left .noRuling ≠ .known result :=
  Usul.IDA.missing_right_not_known

theorem require_Usul_IDA_suspended_left_preserved :
    ∀ (k : Key) (right : Input), combine k k .suspended right = .suspended :=
  Usul.IDA.suspended_left_preserved

theorem require_Usul_IDA_suspended_right_preserved :
    ∀ (k : Key) (left : Input), combine k k left .suspended = .suspended :=
  Usul.IDA.suspended_right_preserved

theorem require_Usul_IDA_conflict_iff_empty :
    ∀ (k : Key) (left right : Constraint),
      combine k k (.known left) (.known right) = .conflict ↔
        ¬ (left.set.inter right.set).Nonempty :=
  Usul.IDA.conflict_iff_empty

theorem require_Usul_IDA_conflict_iff_no_common_ruling :
    ∀ (k : Key) (left right : Constraint),
      combine k k (.known left) (.known right) = .conflict ↔
        ¬ ∃ h : Hukm, left.set.mem h = true ∧ right.set.mem h = true :=
  Usul.IDA.conflict_iff_no_common_ruling

theorem require_Usul_IDA_unknown_ne_all :
    Input.noRuling ≠ .known Constraint.all :=
  Usul.IDA.unknown_ne_all

theorem require_Usul_IDA_unknown_ne_mubah :
    Input.noRuling ≠ .known (Constraint.singleton .mubah) :=
  Usul.IDA.unknown_ne_mubah

theorem require_Usul_IDA_all_ne_mubah :
    Constraint.all ≠ Constraint.singleton .mubah :=
  Usul.IDA.all_ne_mubah

theorem require_Usul_IDA_hukm_roundtrip :
    ∀ h : Hukm, decodeHukm (encodeHukm h) = some h :=
  Usul.IDA.hukm_roundtrip

theorem require_Usul_IDA_decodeHukm_rejects :
    ∀ n : Nat, 5 ≤ n → decodeHukm n = none :=
  Usul.IDA.decodeHukm_rejects

theorem require_Usul_IDA_decodeInput_rejects :
    ∀ n : Nat, 32 < n → decodeInput n = none :=
  Usul.IDA.decodeInput_rejects

theorem require_Usul_IDA_decodeConstraint_rejects_zero :
    decodeConstraint 0 = none :=
  Usul.IDA.decodeConstraint_rejects_zero

/-! ## Fixed wire tags, finite-domain completeness, and scenarios (12 contracts) -/

theorem require_UsulTest_IDA_wire_tags :
    encodeHukm .haram = 0 ∧ encodeHukm .makruh = 1 ∧ encodeHukm .mubah = 2 ∧
      encodeHukm .mandub = 3 ∧ encodeHukm .wajib = 4 :=
  UsulTest.IDA.wire_tags

theorem require_UsulTest_IDA_all_masks_decode :
    ∀ n : Fin 31, (decodeConstraint (n.val + 1)).isSome = true :=
  UsulTest.IDA.all_masks_decode

theorem require_UsulTest_IDA_all_inputs_decode :
    ∀ n : Fin 33, (decodeInput n.val).isSome = true :=
  UsulTest.IDA.all_inputs_decode

theorem require_UsulTest_IDA_all_key_variants_decode :
    ∀ n : Fin 8, (keyVariant n.val).isSome = true :=
  UsulTest.IDA.all_key_variants_decode

theorem require_UsulTest_IDA_missing_required :
    refineCode 0 0 31 = some 0 ∧ refineCode 0 31 0 = some 0 :=
  UsulTest.IDA.missing_required

theorem require_UsulTest_IDA_suspension_priority :
    refineCode 0 0 32 = some 32 ∧ refineCode 0 32 0 = some 32 :=
  UsulTest.IDA.suspension_priority

theorem require_UsulTest_IDA_key_priority :
    ∀ k : Fin 7,
      refineCode (k.val + 1) 32 32 = some 34 ∧
      refineCode (k.val + 1) 0 0 = some 34 :=
  UsulTest.IDA.key_priority

theorem require_UsulTest_IDA_intersect_compatible :
    refineCode 0 7 6 = some 6 :=
  UsulTest.IDA.intersect_compatible

theorem require_UsulTest_IDA_intersect_conflict :
    refineCode 0 1 16 = some 33 :=
  UsulTest.IDA.intersect_conflict

theorem require_UsulTest_IDA_all_constraint_identity_on_known :
    ∀ n : Fin 31, refineCode 0 31 (n.val + 1) = some (n.val + 1) :=
  UsulTest.IDA.all_constraint_identity_on_known

theorem require_UsulTest_IDA_mubah_explicit :
    refineCode 0 4 31 = some 4 :=
  UsulTest.IDA.mubah_explicit

theorem require_UsulTest_IDA_invalid_codes :
    meetCode 5 0 = none ∧ meetCode 0 5 = none ∧
      joinCode 5 0 = none ∧ sigmaCode 5 = none ∧
      refineCode 8 1 1 = none ∧ refineCode 0 33 1 = none ∧
      refineCode 0 1 33 = none ∧ refineCode 100 100 100 = none :=
  UsulTest.IDA.invalid_codes

/-! ## Structured target contracts (20 universal, 5 finite scenarios) -/

theorem require_Usul_IDA_operation_wellFormed_parameter_roles :
    ∀ {operation : Operation}, operation.WellFormed →
      ∀ parameter ∈ operation.parameters, parameter.role ≠ "" :=
  @Usul.IDA.operation_wellFormed_parameter_roles

theorem require_Usul_IDA_operation_wellFormed_unique_roles :
    ∀ {operation : Operation}, operation.WellFormed →
      (operation.parameters.map Parameter.role).Nodup :=
  @Usul.IDA.operation_wellFormed_unique_roles

theorem require_Usul_IDA_action_wellFormed_operation :
    ∀ {action : Action}, action.WellFormed → action.operation.WellFormed :=
  @Usul.IDA.action_wellFormed_operation

theorem require_Usul_IDA_action_wellFormed_signature :
    ∀ {action : Action}, action.WellFormed →
      action.operands.map Operand.parameter = action.operation.parameters :=
  @Usul.IDA.action_wellFormed_signature

theorem require_Usul_IDA_action_wellFormed_references :
    ∀ {action : Action}, action.WellFormed →
      ∀ operand ∈ action.operands, operand.referent.WellFormed :=
  @Usul.IDA.action_wellFormed_references

theorem require_Usul_IDA_action_eq_iff_fields :
    ∀ left right : Action, left = right ↔
      left.operation = right.operation ∧ left.operands = right.operands :=
  Usul.IDA.action_eq_iff_fields

theorem require_Usul_IDA_opportunity_wellFormed_bounds :
    ∀ {opportunity : Opportunity}, opportunity.WellFormed →
      opportunity.opensAt < opportunity.closesAt :=
  @Usul.IDA.opportunity_wellFormed_bounds

theorem require_Usul_IDA_omit_wellFormed_iff :
    ∀ (action : Action) (opportunity : Opportunity),
      (TargetExpr.omit action opportunity).WellFormed ↔
        action.WellFormed ∧ opportunity.WellFormed :=
  Usul.IDA.omit_wellFormed_iff

theorem require_Usul_IDA_perform_ne_omit :
    ∀ (left right : Action) (opportunity : Opportunity),
      TargetExpr.perform left ≠ TargetExpr.omit right opportunity :=
  Usul.IDA.perform_ne_omit

theorem require_Usul_IDA_perform_ne_affect :
    ∀ (action : Action) (state : Affect),
      TargetExpr.perform action ≠ TargetExpr.affect state :=
  Usul.IDA.perform_ne_affect

theorem require_Usul_IDA_omit_ne_affect :
    ∀ (action : Action) (opportunity : Opportunity) (state : Affect),
      TargetExpr.omit action opportunity ≠ TargetExpr.affect state :=
  Usul.IDA.omit_ne_affect

theorem require_Usul_IDA_perform_eq_iff :
    ∀ left right : Action,
      TargetExpr.perform left = TargetExpr.perform right ↔ left = right :=
  Usul.IDA.perform_eq_iff

theorem require_Usul_IDA_omit_eq_iff :
    ∀ (left right : Action) (lo ro : Opportunity),
      TargetExpr.omit left lo = TargetExpr.omit right ro ↔
        left = right ∧ lo = ro :=
  Usul.IDA.omit_eq_iff

theorem require_Usul_IDA_affect_eq_iff :
    ∀ left right : Affect,
      TargetExpr.affect left = TargetExpr.affect right ↔ left = right :=
  Usul.IDA.affect_eq_iff

theorem require_Usul_IDA_target_eq_iff_expression_eq :
    ∀ left right : Target, left = right ↔ left.expression = right.expression :=
  Usul.IDA.target_eq_iff_expression_eq

theorem require_Usul_IDA_target_validate_eq_some_iff :
    ∀ (expression : TargetExpr) (target : Target),
      Target.validate expression = some target ↔ target.expression = expression :=
  Usul.IDA.target_validate_eq_some_iff

theorem require_Usul_IDA_target_validate_eq_none_iff :
    ∀ expression : TargetExpr,
      Target.validate expression = none ↔ ¬ expression.WellFormed :=
  Usul.IDA.target_validate_eq_none_iff

theorem require_Usul_IDA_target_validate_roundTrip :
    ∀ target : Target, Target.validate target.expression = some target :=
  Usul.IDA.target_validate_roundTrip

theorem require_Usul_IDA_target_mismatch_outOfScope :
    ∀ (lk rk : Key) (left right : Input),
      lk.target.expression ≠ rk.target.expression →
        combine lk rk left right = .outOfScope :=
  Usul.IDA.target_mismatch_outOfScope

theorem require_Usul_IDA_known_result_same_target :
    ∀ {lk rk : Key} {left right result : Constraint},
      combine lk rk (.known left) (.known right) = .known result →
        lk.target.expression = rk.target.expression :=
  @Usul.IDA.known_result_same_target

theorem require_UsulTest_IDA_target_fixture_admission :
    ∀ code : Fin 28,
      targetAdmitCode code.val = some (if code.val < 20 then 1 else 0) :=
  UsulTest.IDA.target_fixture_admission

theorem require_UsulTest_IDA_target_reconstruction :
    targetRefineCode 0 1 0 = some 16 ∧ targetRefineCode 1 0 5 = some 4 :=
  UsulTest.IDA.target_reconstruction

theorem require_UsulTest_IDA_target_distinctions :
    targetRefineCode 0 2 0 = some 34 ∧
    targetRefineCode 0 5 0 = some 34 ∧
    targetRefineCode 0 6 0 = some 34 ∧
    targetRefineCode 0 7 0 = some 34 ∧
    targetRefineCode 0 8 0 = some 34 ∧
    targetRefineCode 8 9 0 = some 34 ∧
    targetRefineCode 8 10 0 = some 34 ∧
    targetRefineCode 8 11 0 = some 34 ∧
    targetRefineCode 8 12 0 = some 34 ∧
    targetRefineCode 8 13 0 = some 34 ∧
    targetRefineCode 0 14 0 = some 34 ∧
    targetRefineCode 14 17 0 = some 34 ∧
    targetRefineCode 0 18 0 = some 34 ∧
    targetRefineCode 0 19 0 = some 34 :=
  UsulTest.IDA.target_distinctions

theorem require_UsulTest_IDA_malformed_targets_rejected :
    ∀ code : Fin 8,
      targetRefineCode (code.val + 20) 0 5 = some 35 ∧
      targetRefineCode 0 (code.val + 20) 4 = some 35 :=
  UsulTest.IDA.malformed_targets_rejected

theorem require_UsulTest_IDA_target_selector_bounds :
    targetAdmitCode 28 = none ∧ targetAdmitCode 100 = none ∧
    targetRefineCode 28 0 0 = none ∧ targetRefineCode 0 28 0 = none ∧
    targetRefineCode 0 0 6 = none :=
  UsulTest.IDA.target_selector_bounds

end UsulTest.IDAContracts
