import UsulTest.IDAJudgment

/-!
# Fixed IDA judgment proof contracts

These witnesses give explicit acceptance propositions and refer directly to
the required theorem declarations. Their types must not be inferred from those
declarations or replaced by independent reproving. A required theorem changed
to a weaker proposition must fail to inhabit its fixed witness type.
-/

namespace UsulTest.IDAJudgmentContracts

open Usul Usul.IDA.Judgment UsulTest.IDAJudgment

theorem require_Usul_IDA_Judgment_question_roundtrip :
    ∀ q : Question, decodeQuestion (encodeQuestion q) = some q :=
  Usul.IDA.Judgment.question_roundtrip

theorem require_Usul_IDA_Judgment_question_decode_sound :
    ∀ {code : Nat} {q : Question},
      decodeQuestion code = some q → encodeQuestion q = code :=
  @Usul.IDA.Judgment.question_decode_sound

theorem require_Usul_IDA_Judgment_payload_roundtrip :
    ∀ (q : Question) (p : Payload (Answer q)),
      decodePayload q (encodePayload q p) = some p :=
  Usul.IDA.Judgment.payload_roundtrip

theorem require_Usul_IDA_Judgment_payload_decode_sound :
    ∀ {q : Question} {code : Nat} {p : Payload (Answer q)},
      decodePayload q code = some p → encodePayload q p = code :=
  @Usul.IDA.Judgment.payload_decode_sound

theorem require_Usul_IDA_Judgment_record_roundtrip :
    ∀ r : Record, decodeRecord (encodeRecord r) = some r :=
  Usul.IDA.Judgment.record_roundtrip

theorem require_Usul_IDA_Judgment_record_decode_sound :
    ∀ {raw : RawRecord} {r : Record},
      decodeRecord raw = some r → encodeRecord r = raw :=
  @Usul.IDA.Judgment.record_decode_sound

theorem require_Usul_IDA_Judgment_accepted_iff :
    ∀ (registry : Registry) (request : Request) (receipt : Receipt),
      validate registry request = .accepted receipt ↔
        decodeRecord request.record = some receipt.record ∧
        receipt.record.provenance.WellFormed ∧ receipt.record.WellTyped ∧
        request.snapshot = registry.snapshot ∧
        receipt.snapshot = request.snapshot ∧ receipt.entryId = request.entryId ∧
        ∃ entry, matchingEntries registry request.entryId = [entry] ∧
          entry.status = .admitted ∧ entry.record = request.record :=
  Usul.IDA.Judgment.accepted_iff

theorem require_Usul_IDA_Judgment_accepted_decoded :
    ∀ {registry : Registry} {request : Request} {receipt : Receipt},
      validate registry request = .accepted receipt →
        decodeRecord request.record = some receipt.record :=
  @Usul.IDA.Judgment.accepted_decoded

theorem require_Usul_IDA_Judgment_accepted_preserves_record :
    ∀ {registry : Registry} {request : Request} {receipt : Receipt},
      validate registry request = .accepted receipt →
        encodeRecord receipt.record = request.record :=
  @Usul.IDA.Judgment.accepted_preserves_record

theorem require_Usul_IDA_Judgment_accepted_reference_shape :
    ∀ {registry : Registry} {request : Request} {receipt : Receipt},
      validate registry request = .accepted receipt →
        receipt.record.provenance.source.WellFormed ∧
          receipt.record.provenance.implementationRevision ≠ "" :=
  @Usul.IDA.Judgment.accepted_reference_shape

theorem require_Usul_IDA_Judgment_accepted_well_typed :
    ∀ {registry : Registry} {request : Request} {receipt : Receipt},
      validate registry request = .accepted receipt →
        receipt.record.provenance.dalil ≠ [] ∧
          (receipt.record.question = .taklifi → receipt.record.scope.subject.IsMukallaf) :=
  @Usul.IDA.Judgment.accepted_well_typed

theorem require_Usul_IDA_Judgment_accepted_snapshot :
    ∀ {registry : Registry} {request : Request} {receipt : Receipt},
      validate registry request = .accepted receipt →
        receipt.snapshot = request.snapshot ∧ request.snapshot = registry.snapshot :=
  @Usul.IDA.Judgment.accepted_snapshot

theorem require_Usul_IDA_Judgment_accepted_unique_admitted :
    ∀ {registry : Registry} {request : Request} {receipt : Receipt},
      validate registry request = .accepted receipt →
        ∃ entry, matchingEntries registry request.entryId = [entry] ∧
          entry.status = .admitted ∧ entry.record = request.record :=
  @Usul.IDA.Judgment.accepted_unique_admitted

theorem require_Usul_IDA_Judgment_accepted_registered_record :
    ∀ {registry : Registry} {request : Request} {receipt : Receipt},
      validate registry request = .accepted receipt →
        ∃ entry, matchingEntries registry request.entryId = [entry] ∧
          entry.status = .admitted ∧ entry.record = encodeRecord receipt.record :=
  @Usul.IDA.Judgment.accepted_registered_record

theorem require_Usul_IDA_Judgment_accepted_preserves_grade :
    ∀ {registry : Registry} {request : Request} {receipt : Receipt},
      validate registry request = .accepted receipt →
        receipt.record.provenance.grade = request.record.provenance.grade ∧
          receipt.record.provenance.rujhanKnown = request.record.provenance.rujhanKnown :=
  @Usul.IDA.Judgment.accepted_preserves_grade

theorem require_Usul_IDA_Judgment_mismatched_record_not_accepted :
    ∀ (registry : Registry) (request : Request) (receipt : Receipt) (entry : Entry),
      matchingEntries registry request.entryId = [entry] →
        entry.record ≠ request.record → validate registry request ≠ .accepted receipt :=
  Usul.IDA.Judgment.mismatched_record_not_accepted

theorem require_Usul_IDA_Judgment_question_change_not_accepted :
    ∀ (registry : Registry) (request : Request) (receipt : Receipt) (entry : Entry),
      matchingEntries registry request.entryId = [entry] →
        entry.record.questionCode ≠ request.record.questionCode →
          validate registry request ≠ .accepted receipt :=
  Usul.IDA.Judgment.question_change_not_accepted

theorem require_Usul_IDA_Judgment_source_hash_change_not_accepted :
    ∀ (registry : Registry) (request : Request) (receipt : Receipt) (entry : Entry),
      matchingEntries registry request.entryId = [entry] →
        entry.record.provenance.source.sourceHash ≠ request.record.provenance.source.sourceHash →
          validate registry request ≠ .accepted receipt :=
  Usul.IDA.Judgment.source_hash_change_not_accepted

theorem require_Usul_IDA_Judgment_profile_change_not_accepted :
    ∀ (registry : Registry) (request : Request) (receipt : Receipt) (entry : Entry),
      matchingEntries registry request.entryId = [entry] →
        entry.record.scope.profile ≠ request.record.scope.profile →
          validate registry request ≠ .accepted receipt :=
  Usul.IDA.Judgment.profile_change_not_accepted

theorem require_Usul_IDA_Judgment_profile_version_change_not_accepted :
    ∀ (registry : Registry) (request : Request) (receipt : Receipt) (entry : Entry),
      matchingEntries registry request.entryId = [entry] →
        entry.record.scope.profileVersion ≠ request.record.scope.profileVersion →
          validate registry request ≠ .accepted receipt :=
  Usul.IDA.Judgment.profile_version_change_not_accepted

theorem require_Usul_IDA_Judgment_non_admitted_not_accepted :
    ∀ (registry : Registry) (request : Request) (receipt : Receipt) (entry : Entry),
      matchingEntries registry request.entryId = [entry] →
        entry.status ≠ .admitted → validate registry request ≠ .accepted receipt :=
  Usul.IDA.Judgment.non_admitted_not_accepted

theorem require_Usul_IDA_Judgment_duplicate_entries_not_accepted :
    ∀ (registry : Registry) (request : Request) (receipt : Receipt)
      (first second : Entry) (rest : List Entry),
      matchingEntries registry request.entryId = first :: second :: rest →
        validate registry request ≠ .accepted receipt :=
  Usul.IDA.Judgment.duplicate_entries_not_accepted

theorem require_Usul_IDA_Judgment_missing_entry_not_accepted :
    ∀ (registry : Registry) (request : Request) (receipt : Receipt),
      matchingEntries registry request.entryId = [] → validate registry request ≠ .accepted receipt :=
  Usul.IDA.Judgment.missing_entry_not_accepted

theorem require_Usul_IDA_Judgment_stale_snapshot_not_accepted :
    ∀ (registry : Registry) (request : Request) (receipt : Receipt),
      request.snapshot ≠ registry.snapshot → validate registry request ≠ .accepted receipt :=
  Usul.IDA.Judgment.stale_snapshot_not_accepted

theorem require_Usul_IDA_Judgment_receipt_request_preserved :
    ∀ {registry : Registry} {request : Request} {receipt : Receipt},
      validate registry request = .accepted receipt → receipt.request = request :=
  @Usul.IDA.Judgment.receipt_request_preserved

theorem require_Usul_IDA_Judgment_revalidate_original :
    ∀ {registry : Registry} {request : Request} {receipt : Receipt},
      validate registry request = .accepted receipt → revalidate registry receipt = .accepted receipt :=
  @Usul.IDA.Judgment.revalidate_original

theorem require_Usul_IDA_Judgment_revalidate_stale_not_accepted :
    ∀ (registry : Registry) (receipt result : Receipt),
      receipt.snapshot ≠ registry.snapshot → revalidate registry receipt ≠ .accepted result :=
  Usul.IDA.Judgment.revalidate_stale_not_accepted

theorem require_Usul_IDA_Judgment_revalidate_non_admitted_not_accepted :
    ∀ (registry : Registry) (receipt result : Receipt) (entry : Entry),
      matchingEntries registry receipt.entryId = [entry] →
        entry.status ≠ .admitted → revalidate registry receipt ≠ .accepted result :=
  Usul.IDA.Judgment.revalidate_non_admitted_not_accepted

theorem require_Usul_IDA_Judgment_revalidate_revoked_not_accepted :
    ∀ (registry : Registry) (receipt result : Receipt) (entry : Entry),
      matchingEntries registry receipt.entryId = [entry] →
        entry.status = .revoked → revalidate registry receipt ≠ .accepted result :=
  Usul.IDA.Judgment.revalidate_revoked_not_accepted

theorem require_Usul_IDA_Judgment_missing_ne_suspended :
    ∀ q : Question, (Payload.noRuling : Payload (Answer q)) ≠ .suspended :=
  Usul.IDA.Judgment.missing_ne_suspended

theorem require_Usul_IDA_Judgment_missing_ne_known :
    ∀ (q : Question) (a : Answer q), (Payload.noRuling : Payload (Answer q)) ≠ .known a :=
  Usul.IDA.Judgment.missing_ne_known

theorem require_Usul_IDA_Judgment_suspended_ne_known :
    ∀ (q : Question) (a : Answer q), (Payload.suspended : Payload (Answer q)) ≠ .known a :=
  Usul.IDA.Judgment.suspended_ne_known

/- The finite wire table and explicit scenario expectations are also fixed. -/

theorem require_UsulTest_IDAJudgment_codec_family_matrix :
    ∀ q : Fin 6, ∀ a : Fin 38,
      codecCode q.val a.val =
        if q.val < 5 ∧ (a.val = 0 ∨ a.val = 32 ∨
          (q.val = 0 ∧ 1 ≤ a.val ∧ a.val ≤ 31) ∨
          (1 ≤ q.val ∧ q.val ≤ 3 ∧ (a.val = 33 ∨ a.val = 34)) ∨
          (q.val = 4 ∧ (a.val = 35 ∨ a.val = 36))) then a.val + 1 else 0 :=
  UsulTest.IDAJudgment.codec_family_matrix

theorem require_UsulTest_IDAJudgment_out_of_range_codes :
    codecCode 5 0 = 0 ∧ codecCode 100 16 = 0 ∧ codecCode 0 100 = 0 ∧
      codecCode 1 100 = 0 ∧ codecCode 4 100 = 0 :=
  UsulTest.IDAJudgment.out_of_range_codes

theorem require_UsulTest_IDAJudgment_baseline_admitted :
    ∀ q : Fin 5, admissionCode q.val 1 0 = some 0 :=
  UsulTest.IDAJudgment.baseline_admitted

theorem require_UsulTest_IDAJudgment_unadmitted_statuses :
    ∀ q : Fin 5,
      admissionCode q.val 0 0 = some 7 ∧ admissionCode q.val 2 0 = some 7 ∧
        admissionCode q.val 3 0 = some 7 :=
  UsulTest.IDAJudgment.unadmitted_statuses

theorem require_UsulTest_IDAJudgment_all_metadata_bound :
    ∀ q : Fin 5, ∀ v : Fin 26, admissionCode q.val 1 (v.val + 1) ≠ some 0 :=
  UsulTest.IDAJudgment.all_metadata_bound

theorem require_UsulTest_IDAJudgment_duplicate_id_priority :
    ∀ q : Fin 5, ∀ s : Fin 4, admissionCode q.val s.val 29 = some 6 :=
  UsulTest.IDAJudgment.duplicate_id_priority

theorem require_UsulTest_IDAJudgment_snapshot_binding :
    ∀ q : Fin 5, ∀ s : Fin 4, admissionCode q.val s.val 27 = some 4 :=
  UsulTest.IDAJudgment.snapshot_binding

theorem require_UsulTest_IDAJudgment_missing_entry_binding :
    ∀ q : Fin 5, ∀ s : Fin 4, admissionCode q.val s.val 28 = some 5 :=
  UsulTest.IDAJudgment.missing_entry_binding

theorem require_UsulTest_IDAJudgment_reference_shape :
    ∀ q : Fin 5, ∀ s : Fin 4,
      admissionCode q.val s.val 30 = some 2 ∧
        admissionCode q.val s.val 31 = some 2 ∧
        admissionCode q.val s.val 33 = some 2 ∧
        admissionCode q.val s.val 34 = some 2 ∧
        admissionCode q.val s.val 35 = some 2 ∧
        admissionCode q.val s.val 36 = some 2 ∧
        admissionCode q.val s.val 37 = some 2 :=
  UsulTest.IDAJudgment.reference_shape

theorem require_UsulTest_IDAJudgment_evidence_required :
    ∀ q : Fin 5, ∀ s : Fin 4, admissionCode q.val s.val 32 = some 3 :=
  UsulTest.IDAJudgment.evidence_required

theorem require_UsulTest_IDAJudgment_typed_capacity :
    outcomeCode (syntheticRegistered (syntheticChildRecord 0)) = 3 ∧
      (∀ q : Fin 4, outcomeCode (syntheticRegistered (syntheticChildRecord (q.val + 1))) = 0) :=
  UsulTest.IDAJudgment.typed_capacity

theorem require_UsulTest_IDAJudgment_all_taklifi_payloads_preserved :
    ∀ a : Fin 33, syntheticReturnedAnswer 0 a.val = some a.val :=
  UsulTest.IDAJudgment.all_taklifi_payloads_preserved

theorem require_UsulTest_IDAJudgment_missing_and_suspension_preserved :
    ∀ q : Fin 5,
      syntheticReturnedAnswer q.val 0 = some 0 ∧ syntheticReturnedAnswer q.val 32 = some 32 :=
  UsulTest.IDAJudgment.missing_and_suspension_preserved

theorem require_UsulTest_IDAJudgment_partial_permission_distinct :
    syntheticReturnedAnswer 0 30 = some 30 ∧
      syntheticReturnedAnswer 0 4 = some 4 ∧
      syntheticReturnedAnswer 0 31 = some 31 ∧
      syntheticReturnedAnswer 0 0 = some 0 ∧
      syntheticReturnedAnswer 0 32 = some 32 :=
  UsulTest.IDAJudgment.partial_permission_distinct

theorem require_UsulTest_IDAJudgment_grade_preserved :
    syntheticReturnedGrade = some (.zann, false) :=
  UsulTest.IDAJudgment.grade_preserved

theorem require_UsulTest_IDAJudgment_revalidation_cases :
    ∀ q : Fin 5,
      revalidationCode q.val 0 = some 0 ∧ revalidationCode q.val 1 = some 4 ∧
        revalidationCode q.val 2 = some 7 ∧ revalidationCode q.val 3 = some 7 ∧
        revalidationCode q.val 4 = some 8 ∧ revalidationCode q.val 5 = some 8 ∧
        revalidationCode q.val 6 = some 5 ∧ revalidationCode q.val 7 = some 6 :=
  UsulTest.IDAJudgment.revalidation_cases

theorem require_UsulTest_IDAJudgment_export_bounds :
    admissionCode 5 1 0 = none ∧ admissionCode 0 4 0 = none ∧
      admissionCode 0 1 38 = none ∧ revalidationCode 5 0 = none ∧
      revalidationCode 0 8 = none :=
  UsulTest.IDAJudgment.export_bounds

end UsulTest.IDAJudgmentContracts
