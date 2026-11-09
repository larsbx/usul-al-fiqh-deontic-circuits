import UsulTest.IDAActRegistry

/-!
Fixed, explicitly typed ACT-01 contracts. These statements are independently
written requirements, not inferred theorem types. Replacing an implementation
proposition by `True` must fail compilation of this module.
-/

namespace UsulTest.IDAActRegistryContracts

open Usul Usul.IDA Usul.IDA.ActRegistry

theorem require_Usul_IDA_ActRegistry_resolved_roles_exact :
    ∀ {roles : List RoleSpec} {parameters : List Parameter},
      resolveRoles roles = some parameters →
      roles = parameters.map (fun p => (⟨p.role, some p.kind⟩ : RoleSpec)) := @resolved_roles_exact

theorem require_Usul_IDA_ActRegistry_resolve_iff :
    ∀ (r : Registry) (e : Envelope) (d : Definition),
      resolve r e = .ok d ↔
        r.Unique ∧ r.Shaped ∧ e.registrySnapshot = r.snapshot ∧
        matchingDefinitions r e.key = [d] ∧ e.definitionDigest = d.digest ∧
        ∃ ps, resolveRoles d.roles = some ps ∧
          e.action.operation = ⟨d.key.symbol, ps⟩ ∧
          e.action.operands.map Operand.parameter = ps ∧ e.WellFormed := resolve_iff

theorem require_Usul_IDA_ActRegistry_resolve_registered :
    ∀ {r : Registry} {e : Envelope} {d : Definition},
      resolve r e = .ok d → d ∈ r.definitions ∧ d.key = e.key := @resolve_registered

theorem require_Usul_IDA_ActRegistry_resolve_unique :
    ∀ {r : Registry} {e : Envelope} {d other : Definition},
      resolve r e = .ok d → other ∈ r.definitions → other.key = e.key → other = d := @resolve_unique

theorem require_Usul_IDA_ActRegistry_resolve_schema :
    ∀ {r : Registry} {e : Envelope} {d : Definition}, resolve r e = .ok d →
      ∃ ps, resolveRoles d.roles = some ps ∧
        e.action.operation = ⟨d.key.symbol, ps⟩ ∧
        e.action.operands.map Operand.parameter = ps := @resolve_schema

theorem require_Usul_IDA_ActRegistry_resolve_declared_schema :
    ∀ {r : Registry} {e : Envelope} {d : Definition}, resolve r e = .ok d →
      d.roles = e.action.operands.map (fun o => (⟨o.role, some o.referent.kind⟩ : RoleSpec)) :=
  @resolve_declared_schema

theorem require_Usul_IDA_ActRegistry_unresolved_member_rejected :
    ∀ {r : Registry} {e : Envelope} {d : Definition} {role : RoleSpec},
      role ∈ d.roles → role.kind = none → resolve r e ≠ .ok d := @unresolved_member_rejected

theorem require_Usul_IDA_ActRegistry_resolve_wellFormed :
    ∀ {r : Registry} {e : Envelope} {d : Definition},
      resolve r e = .ok d → e.action.WellFormed ∧
        (∀ q ∈ e.qualifications, q.WellFormed) ∧ e.context.WellFormed := @resolve_wellFormed

theorem require_Usul_IDA_ActRegistry_registry_conflict_precedes_lookup :
    ∀ (r : Registry) (e : Envelope), ¬ r.Unique →
      resolve r e = .error .registryConflict := registry_conflict_precedes_lookup

theorem require_Usul_IDA_ActRegistry_unresolved_not_resolved :
    ∀ {r : Registry} {e : Envelope} {d : Definition},
      resolveRoles d.roles = none → resolve r e ≠ .ok d := @unresolved_not_resolved

theorem require_Usul_IDA_ActRegistry_checked_target_exact :
    ∀ {r : Registry} (d : CheckedDescription r),
      d.target.expression = .perform d.envelope.action := @checked_target_exact

theorem require_Usul_IDA_ActRegistry_project_action_iff :
    ∀ e f : Envelope, project e = project f ↔ e.action = f.action := project_action_iff

theorem require_Usul_IDA_ActRegistry_projection_omits_qualifications :
    ∀ (e : Envelope) (qs : List Qualification),
      project { e with qualifications := qs } = project e := projection_omits_qualifications

theorem require_Usul_IDA_ActRegistry_projection_omits_context :
    ∀ (e : Envelope) (s : Snapshot), project { e with context := s } = project e :=
  projection_omits_context

theorem require_Usul_IDA_ActRegistry_admit_iff :
    ∀ (a : Authority) (q : Request) (r : Receipt), admit a q = .ok r ↔
      r.authority = a ∧ r.request = q ∧
      r.result = Derivation.evaluateSource a.environment q.premise ∧
      resolve a.registry q.envelope = .ok r.definition ∧ a.Unique ∧
      matchingBindings a q.premise.request.entryId = [⟨q.envelope, q.premise⟩] ∧
      project q.envelope = q.premise.request.record.scope.target ∧
      q.envelope.context.Matches q.premise ∧
      (Derivation.evaluateSource a.environment q.premise).Accepted := admit_iff

theorem require_Usul_IDA_ActRegistry_admitted_resolution :
    ∀ {a : Authority} {q : Request} {r : Receipt}, admit a q = .ok r →
      resolve a.registry q.envelope = .ok r.definition := @admitted_resolution

theorem require_Usul_IDA_ActRegistry_admitted_exact_binding :
    ∀ {a : Authority} {q : Request} {r : Receipt}, admit a q = .ok r → a.Unique ∧
      matchingBindings a q.premise.request.entryId = [⟨q.envelope, q.premise⟩] := @admitted_exact_binding

theorem require_Usul_IDA_ActRegistry_admitted_target :
    ∀ {a : Authority} {q : Request} {r : Receipt}, admit a q = .ok r →
      project q.envelope = q.premise.request.record.scope.target := @admitted_target

theorem require_Usul_IDA_ActRegistry_admitted_snapshot :
    ∀ {a : Authority} {q : Request} {r : Receipt}, admit a q = .ok r →
      q.envelope.context.contextId = q.premise.request.record.scope.context ∧
      q.envelope.context.timeId = q.premise.request.record.scope.time ∧
      q.envelope.context.profile = q.premise.request.record.scope.profile ∧
      q.envelope.context.profileVersion = q.premise.request.record.scope.profileVersion ∧
      q.envelope.context.interpretationId = q.premise.request.record.provenance.interpretationId ∧
      q.envelope.context.interpretationVersion = q.premise.request.record.provenance.interpretationVersion :=
  @admitted_snapshot

theorem require_Usul_IDA_ActRegistry_admitted_source :
    ∀ {a : Authority} {q : Request} {r : Receipt}, admit a q = .ok r →
      (Derivation.evaluateSource a.environment q.premise).Accepted := @admitted_source

theorem require_Usul_IDA_ActRegistry_admitted_source_authority :
    ∀ {a : Authority} {q : Request} {r : Receipt}, admit a q = .ok r →
      ∃ base, Derivation.Authority a.environment q.premise base ∧
        ∃ answer, base.record.payload = .known answer := @admitted_source_authority

theorem require_Usul_IDA_ActRegistry_admitted_binding_fields :
    ∀ {a : Authority} {q : Request} {r : Receipt} {b : Binding}, admit a q = .ok r →
      matchingBindings a q.premise.request.entryId = [b] →
      b.envelope.key = q.envelope.key ∧
      b.envelope.definitionDigest = q.envelope.definitionDigest ∧
      b.envelope.registrySnapshot = q.envelope.registrySnapshot ∧
      b.envelope.qualifications = q.envelope.qualifications ∧
      b.envelope.context = q.envelope.context ∧
      b.envelope.action = q.envelope.action ∧ b.premise = q.premise := @admitted_binding_fields

theorem require_Usul_IDA_ActRegistry_altered_envelope_rejected :
    ∀ {a : Authority} {q : Request} {b : Binding},
      matchingBindings a q.premise.request.entryId = [b] →
      b.envelope ≠ q.envelope → ∀ r : Receipt, admit a q ≠ .ok r := @altered_envelope_rejected

theorem require_Usul_IDA_ActRegistry_changed_qualification_rejected :
    ∀ {a : Authority} {q : Request} {b : Binding},
      matchingBindings a q.premise.request.entryId = [b] →
      b.envelope.qualifications ≠ q.envelope.qualifications →
      ∀ r : Receipt, admit a q ≠ .ok r := @changed_qualification_rejected

theorem require_Usul_IDA_ActRegistry_changed_snapshot_rejected :
    ∀ {a : Authority} {q : Request} {b : Binding},
      matchingBindings a q.premise.request.entryId = [b] → b.envelope.context ≠ q.envelope.context →
      ∀ r : Receipt, admit a q ≠ .ok r := @changed_snapshot_rejected

theorem require_Usul_IDA_ActRegistry_source_rejection_blocks :
    ∀ {a : Authority} {q : Request},
      ¬ (Derivation.evaluateSource a.environment q.premise).Accepted →
      ∀ r : Receipt, admit a q ≠ .ok r := @source_rejection_blocks

theorem require_Usul_IDA_ActRegistry_non_admitted_rejected :
    ∀ {a : Authority} {q : Request} {entry : Judgment.Entry},
      Judgment.matchingEntries a.environment.registry q.premise.request.entryId = [entry] →
      entry.status ≠ .admitted → ∀ r : Receipt, admit a q ≠ .ok r := @non_admitted_rejected

theorem require_Usul_IDA_ActRegistry_duplicate_bindings_rejected :
    ∀ {a : Authority} {q : Request}, ¬ a.Unique →
      ∀ r : Receipt, admit a q ≠ .ok r := @duplicate_bindings_rejected

theorem require_Usul_IDA_ActRegistry_target_mismatch_rejected :
    ∀ {a : Authority} {q : Request}, project q.envelope ≠ q.premise.request.record.scope.target →
      ∀ r : Receipt, admit a q ≠ .ok r := @target_mismatch_rejected

theorem require_Usul_IDA_ActRegistry_context_mismatch_rejected :
    ∀ {a : Authority} {q : Request}, ¬ q.envelope.context.Matches q.premise →
      ∀ r : Receipt, admit a q ≠ .ok r := @context_mismatch_rejected

theorem require_Usul_IDA_ActRegistry_receipt_binds_all :
    ∀ {a : Authority} {q : Request} {r : Receipt}, verifyReceipt a q r = true →
      r.authority = a ∧ r.request = q ∧
      r.result = Derivation.evaluateSource a.environment q.premise ∧
      (Derivation.evaluateSource a.environment q.premise).Accepted := @receipt_binds_all

theorem require_Usul_IDA_ActRegistry_receipt_preserves_source :
    ∀ {a : Authority} {q : Request} {r : Receipt}, admit a q = .ok r →
      r.result.provenance = [q.premise] := @receipt_preserves_source

theorem require_Usul_IDA_ActRegistry_kind_roundtrip :
    ∀ k : RefKind, decodeKind (encodeKind k) = some k := kind_roundtrip

theorem require_Usul_IDA_ActRegistry_kind_decode_sound :
    ∀ {s : String} {k : RefKind}, decodeKind s = some k → encodeKind k = s := @kind_decode_sound

theorem require_Usul_IDA_ActRegistry_decodeList_encode :
    ∀ {α β : Type} (enc : β → α) (dec : α → Option β),
      (∀ b, dec (enc b) = some b) → ∀ bs : List β,
      decodeList dec (bs.map enc) = some bs := @decodeList_encode

theorem require_Usul_IDA_ActRegistry_decodeList_sound :
    ∀ {α β : Type} (enc : β → α) (dec : α → Option β),
      (∀ a b, dec a = some b → enc b = a) →
      ∀ {as : List α} {bs : List β}, decodeList dec as = some bs → bs.map enc = as := @decodeList_sound

theorem require_Usul_IDA_ActRegistry_role_roundtrip :
    ∀ r : RoleSpec, decodeRole (encodeRole r) = some r := role_roundtrip

theorem require_Usul_IDA_ActRegistry_role_decode_sound :
    ∀ {w : RoleWire} {r : RoleSpec}, decodeRole w = some r → encodeRole r = w := @role_decode_sound

theorem require_Usul_IDA_ActRegistry_ref_roundtrip :
    ∀ r : EntityRef, decodeRef (encodeRef r) = some r := ref_roundtrip

theorem require_Usul_IDA_ActRegistry_ref_decode_sound :
    ∀ {w : RefWire} {r : EntityRef}, decodeRef w = some r → encodeRef r = w := @ref_decode_sound

theorem require_Usul_IDA_ActRegistry_parameter_roundtrip :
    ∀ p : Parameter, decodeParameter (encodeParameter p) = some p := parameter_roundtrip

theorem require_Usul_IDA_ActRegistry_parameter_decode_sound :
    ∀ {w : ParameterWire} {p : Parameter}, decodeParameter w = some p → encodeParameter p = w :=
  @parameter_decode_sound

theorem require_Usul_IDA_ActRegistry_operand_roundtrip :
    ∀ p : Operand, decodeOperand (encodeOperand p) = some p := operand_roundtrip

theorem require_Usul_IDA_ActRegistry_operand_decode_sound :
    ∀ {w : OperandWire} {p : Operand}, decodeOperand w = some p → encodeOperand p = w :=
  @operand_decode_sound

theorem require_Usul_IDA_ActRegistry_action_roundtrip :
    ∀ a : Action, decodeAction (encodeAction a) = some a := action_roundtrip

theorem require_Usul_IDA_ActRegistry_action_decode_sound :
    ∀ {w : ActionWire} {a : Action}, decodeAction w = some a → encodeAction a = w :=
  @action_decode_sound

theorem require_Usul_IDA_ActRegistry_qualification_roundtrip :
    ∀ q : Qualification, decodeQualification (encodeQualification q) = some q := qualification_roundtrip

theorem require_Usul_IDA_ActRegistry_qualification_decode_sound :
    ∀ {w : QualificationWire} {q : Qualification},
      decodeQualification w = some q → encodeQualification q = w := @qualification_decode_sound

theorem require_Usul_IDA_ActRegistry_definition_roundtrip :
    ∀ d : Definition, decodeDefinition (encodeDefinition d) = some d := definition_roundtrip

theorem require_Usul_IDA_ActRegistry_definition_decode_sound :
    ∀ {w : DefinitionWire} {d : Definition},
      decodeDefinition w = some d → encodeDefinition d = w := @definition_decode_sound

theorem require_Usul_IDA_ActRegistry_envelope_roundtrip :
    ∀ e : Envelope, decodeEnvelope (encodeEnvelope e) = some e := envelope_roundtrip

theorem require_Usul_IDA_ActRegistry_envelope_decode_sound :
    ∀ {w : EnvelopeWire} {e : Envelope}, decodeEnvelope w = some e → encodeEnvelope e = w :=
  @envelope_decode_sound

theorem require_UsulTest_IDAActRegistry_structural_matrix : ∀ r : Fin 14, ∀ e : Fin 36,
    IDAActRegistry.structuralCode r.val e.val = IDAActRegistry.expectedStructural r.val e.val :=
  IDAActRegistry.structural_matrix

theorem require_UsulTest_IDAActRegistry_bound_guard_matrix : ∀ e : Fin 36, ∀ b : Fin 10,
    IDAActRegistry.boundCode e.val b.val 0 = IDAActRegistry.expectedBound e.val b.val 0 :=
  IDAActRegistry.bound_guard_matrix

theorem require_UsulTest_IDAActRegistry_actual_source_matrix : ∀ s : Fin 12,
    IDAActRegistry.boundCode 0 0 s.val = (if s.val = 0 then 0 else 15) ∧
    IDAActRegistry.boundBaseIssue 0 0 s.val = IDAActRegistry.expectedBaseIssue s.val :=
  IDAActRegistry.actual_source_matrix

theorem require_UsulTest_IDAActRegistry_same_target_changed_qualification :
    project (IDAActRegistry.envelopeCase 0) = project (IDAActRegistry.envelopeCase 10) ∧
    IDAActRegistry.boundCode 10 0 0 = 12 ∧ IDAActRegistry.boundCode 10 5 0 = 0 :=
  IDAActRegistry.same_target_changed_qualification

theorem require_UsulTest_IDAActRegistry_wrong_target_independently_blocked :
    IDAActRegistry.boundCode 9 5 0 = 14 := IDAActRegistry.wrong_target_independently_blocked

theorem require_UsulTest_IDAActRegistry_snapshot_coordinates_independently_blocked : ∀ i : Fin 6,
    IDAActRegistry.boundCode (18 + i.val) 5 0 = 16 ∧
      IDAActRegistry.boundCode (18 + i.val) 6 0 = 0 :=
  IDAActRegistry.snapshot_coordinates_independently_blocked

theorem require_UsulTest_IDAActRegistry_candidate_structurally_checked_but_not_admitted :
    resolveCode IDAActRegistry.baseRegistry IDAActRegistry.baseEnvelope = 0 ∧
    IDAActRegistry.boundCode 0 0 1 = 15 ∧ IDAActRegistry.boundBaseIssue 0 0 1 = 7 :=
  IDAActRegistry.candidate_structurally_checked_but_not_admitted

theorem require_UsulTest_IDAActRegistry_unresolved_ne_unknown :
    IDAActRegistry.structuralCode 6 0 = 6 ∧ IDAActRegistry.structuralCode 1 0 = 4 :=
  IDAActRegistry.unresolved_ne_unknown

theorem require_UsulTest_IDAActRegistry_projection_is_lossy :
    IDAActRegistry.envelopeCase 0 ≠ IDAActRegistry.envelopeCase 10 ∧
    project (IDAActRegistry.envelopeCase 0) = project (IDAActRegistry.envelopeCase 10) :=
  IDAActRegistry.projection_is_lossy

theorem require_UsulTest_IDAActRegistry_omitted_metadata_independently_blocked : ∀ n : Fin 3,
    let (a, q) := IDAActRegistry.omittedMetadataFixture n.val
    resolveCode a.registry q.envelope = 0 ∧
      project q.envelope = project IDAActRegistry.baseEnvelope ∧
      resultCode (admit a q) = 12 := IDAActRegistry.omitted_metadata_independently_blocked

theorem require_UsulTest_IDAActRegistry_independent_sources_share_envelope :
    IDAActRegistry.twoSourceFixture.2.map
      (fun q => resultCode (admit IDAActRegistry.twoSourceFixture.1 q)) = [0, 0] :=
  IDAActRegistry.independent_sources_share_envelope

theorem require_UsulTest_IDAActRegistry_wire_negative_controls :
    IDAActRegistry.wireCases = [true, true, true, true, true] := IDAActRegistry.wire_negative_controls

end UsulTest.IDAActRegistryContracts
