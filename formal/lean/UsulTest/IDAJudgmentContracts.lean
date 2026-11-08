import UsulTest.IDAJudgment

/-!
# Fixed source-bound judgment contracts

Every witness states its acceptance proposition explicitly and uses the named
implementation theorem directly. Keeping a theorem name while weakening its
statement must fail here. Do not replace these types with inferred aliases or
reprove the propositions independently of the required implementation theorem.

The trust assumption is external: these propositions check replay against a
fixed snapshot. They do not authenticate admission authority or source bytes.
-/

namespace UsulTest.IDAJudgmentContracts

open Usul Usul.IDAJudgment UsulTest.IDAJudgment

/-! ## Universal acceptance and exact binding -/

theorem require_Usul_IDAJudgment_accepted_guards :
    ∀ (p : Packet) (t : TrustedSnapshot), Accepted p t → Guards p t :=
  Usul.IDAJudgment.accepted_guards

theorem require_Usul_IDAJudgment_replay_of_guards :
    ∀ (p : Packet) (t : TrustedSnapshot), Guards p t →
      ∀ d : DecodedJudgment,
        decode p.claim.scope.question p.claim.answer = some d →
          replay p t = .ok ⟨p.claim, t.admission.status, d⟩ :=
  Usul.IDAJudgment.replay_of_guards

theorem require_Usul_IDAJudgment_guards_accepted :
    ∀ (p : Packet) (t : TrustedSnapshot), Guards p t → Accepted p t :=
  Usul.IDAJudgment.guards_accepted

theorem require_Usul_IDAJudgment_accepted_iff_guards :
    ∀ (p : Packet) (t : TrustedSnapshot), Accepted p t ↔ Guards p t :=
  Usul.IDAJudgment.accepted_iff_guards

theorem require_Usul_IDAJudgment_accepted_decodes :
    ∀ (p : Packet) (t : TrustedSnapshot), Accepted p t →
      ∃ d, decode p.claim.scope.question p.claim.answer = some d :=
  Usul.IDAJudgment.accepted_decodes

theorem require_Usul_IDAJudgment_accepted_schema :
    ∀ (p : Packet) (t : TrustedSnapshot), Accepted p t → p.derivation.schema = 1 :=
  Usul.IDAJudgment.accepted_schema

theorem require_Usul_IDAJudgment_accepted_rule :
    ∀ (p : Packet) (t : TrustedSnapshot), Accepted p t → p.derivation.rule = 0 :=
  Usul.IDAJudgment.accepted_rule

theorem require_Usul_IDAJudgment_accepted_provenance :
    ∀ (p : Packet) (t : TrustedSnapshot), Accepted p t → validProvenance p.claim = true :=
  Usul.IDAJudgment.accepted_provenance

theorem require_Usul_IDAJudgment_accepted_scope :
    ∀ (p : Packet) (t : TrustedSnapshot), Accepted p t → p.claim.scope = t.currentScope :=
  Usul.IDAJudgment.accepted_scope

theorem require_Usul_IDAJudgment_accepted_source :
    ∀ (p : Packet) (t : TrustedSnapshot), Accepted p t → p.claim.source = t.registeredSource :=
  Usul.IDAJudgment.accepted_source

theorem require_Usul_IDAJudgment_accepted_enabled :
    ∀ (p : Packet) (t : TrustedSnapshot), Accepted p t → t.sourceEnabled = true :=
  Usul.IDAJudgment.accepted_enabled

theorem require_Usul_IDAJudgment_accepted_admitted :
    ∀ (p : Packet) (t : TrustedSnapshot), Accepted p t → t.admission.status = 1 :=
  Usul.IDAJudgment.accepted_admitted

theorem require_Usul_IDAJudgment_accepted_receipt :
    ∀ (p : Packet) (t : TrustedSnapshot), Accepted p t → p.claim = p.derivation.frozenClaim :=
  Usul.IDAJudgment.accepted_receipt

theorem require_Usul_IDAJudgment_accepted_admission :
    ∀ (p : Packet) (t : TrustedSnapshot), Accepted p t → p.claim = t.admission.claim :=
  Usul.IDAJudgment.accepted_admission

theorem require_Usul_IDAJudgment_changed_receipt_cannot_reuse :
    ∀ (p : Packet) (t : TrustedSnapshot), p.claim ≠ p.derivation.frozenClaim → ¬ Accepted p t :=
  Usul.IDAJudgment.changed_receipt_cannot_reuse

theorem require_Usul_IDAJudgment_changed_admission_cannot_reuse :
    ∀ (p : Packet) (t : TrustedSnapshot), p.claim ≠ t.admission.claim → ¬ Accepted p t :=
  Usul.IDAJudgment.changed_admission_cannot_reuse

theorem require_Usul_IDAJudgment_changed_scope_cannot_reuse :
    ∀ (p : Packet) (t : TrustedSnapshot), p.claim.scope ≠ t.currentScope → ¬ Accepted p t :=
  Usul.IDAJudgment.changed_scope_cannot_reuse

theorem require_Usul_IDAJudgment_changed_source_cannot_reuse :
    ∀ (p : Packet) (t : TrustedSnapshot), p.claim.source ≠ t.registeredSource → ¬ Accepted p t :=
  Usul.IDAJudgment.changed_source_cannot_reuse

theorem require_Usul_IDAJudgment_reported_status_irrelevant :
    ∀ (p : Packet) (t : TrustedSnapshot) (status : Nat),
      replay { p with reportedAdmissionStatus := status } t = replay p t :=
  Usul.IDAJudgment.reported_status_irrelevant

theorem require_Usul_IDAJudgment_invalid_type_rejected :
    ∀ (p : Packet) (t : TrustedSnapshot),
      decode p.claim.scope.question p.claim.answer = none → replay p t = .error 100 :=
  Usul.IDAJudgment.invalid_type_rejected

/-! ## Nonempty typed answers and distinct exceptional states -/

theorem require_Usul_IDAJudgment_known_nonempty :
    ∀ (q : Question) (answers : KnownAnswers q), ∃ answer, answers.mem answer = true :=
  Usul.IDAJudgment.known_nonempty

theorem require_Usul_IDAJudgment_noRuling_ne_suspended :
    ∀ q : Question, (Verdict.noRuling : Verdict q) ≠ .suspended :=
  Usul.IDAJudgment.noRuling_ne_suspended

theorem require_Usul_IDAJudgment_noRuling_ne_conflict :
    ∀ q : Question, (Verdict.noRuling : Verdict q) ≠ .conflict :=
  Usul.IDAJudgment.noRuling_ne_conflict

theorem require_Usul_IDAJudgment_suspended_ne_conflict :
    ∀ q : Question, (Verdict.suspended : Verdict q) ≠ .conflict :=
  Usul.IDAJudgment.suspended_ne_conflict

theorem require_Usul_IDAJudgment_known_ne_exceptional :
    ∀ (q : Question) (answers : KnownAnswers q),
      Verdict.known answers ≠ .noRuling ∧ Verdict.known answers ≠ .suspended ∧
      Verdict.known answers ≠ .conflict ∧ Verdict.known answers ≠ .outOfScope :=
  Usul.IDAJudgment.known_ne_exceptional

/-! ## Successful outputs retain their checked record -/

theorem require_Usul_IDAJudgment_replay_retains_claim :
    ∀ (p : Packet) (t : TrustedSnapshot) (j : Judgment),
      replay p t = .ok j → j.claim = p.claim :=
  Usul.IDAJudgment.replay_retains_claim

theorem require_Usul_IDAJudgment_replay_retains_status :
    ∀ (p : Packet) (t : TrustedSnapshot) (j : Judgment),
      replay p t = .ok j → j.admissionStatus = 1 :=
  Usul.IDAJudgment.replay_retains_status

theorem require_Usul_IDAJudgment_replay_retains_decoding :
    ∀ (p : Packet) (t : TrustedSnapshot) (j : Judgment),
      replay p t = .ok j →
        decode p.claim.scope.question p.claim.answer = some j.decoded :=
  Usul.IDAJudgment.replay_retains_decoding

/-! ## Typed serialization, exact question identity, and carrier meanings -/

theorem require_Usul_IDAJudgment_decodeQuestion_fidelity :
    ∀ (tag : Nat) (q : Question),
      decodeQuestion tag = some q → encodeQuestion q = tag :=
  Usul.IDAJudgment.decodeQuestion_fidelity

theorem require_Usul_IDAJudgment_decode_question_fidelity :
    ∀ (tag code : Nat) (d : DecodedJudgment),
      decode tag code = some d → encodeQuestion d.question = tag :=
  Usul.IDAJudgment.decode_question_fidelity

theorem require_Usul_IDAJudgment_decoded_canonical_codes :
    ∀ q : Fin 5, ∀ code : Fin 35,
      (decode q.val code.val).map (fun d => encodeVerdict d.verdict) =
        if code.val = 0 ∨ code.val = 32 ∨ code.val = 33 ∨ code.val = 34 ∨
           (1 ≤ code.val ∧ code.val ≤ (if q.val = 0 then 31 else 3))
        then some code.val else none :=
  Usul.IDAJudgment.decoded_canonical_codes

theorem require_Usul_IDAJudgment_taklifi_member_semantics :
    ∀ h : Hukm,
      knownMember .taklifi 1 h = some (h == .haram) ∧
      knownMember .taklifi 2 h = some (h == .makruh) ∧
      knownMember .taklifi 4 h = some (h == .mubah) ∧
      knownMember .taklifi 8 h = some (h == .mandub) ∧
      knownMember .taklifi 16 h = some (h == .wajib) :=
  Usul.IDAJudgment.taklifi_member_semantics

theorem require_Usul_IDAJudgment_sabab_member_semantics :
    ∀ b : Bool,
      knownMember (.wadi .sabab) 1 b = some (!b) ∧
      knownMember (.wadi .sabab) 2 b = some b ∧
      knownMember (.wadi .sabab) 3 b = some true :=
  Usul.IDAJudgment.sabab_member_semantics

theorem require_Usul_IDAJudgment_shart_member_semantics :
    ∀ b : Bool,
      knownMember (.wadi .shart) 1 b = some (!b) ∧
      knownMember (.wadi .shart) 2 b = some b ∧
      knownMember (.wadi .shart) 3 b = some true :=
  Usul.IDAJudgment.shart_member_semantics

theorem require_Usul_IDAJudgment_mani_member_semantics :
    ∀ b : Bool,
      knownMember (.wadi .mani) 1 b = some (!b) ∧
      knownMember (.wadi .mani) 2 b = some b ∧
      knownMember (.wadi .mani) 3 b = some true :=
  Usul.IDAJudgment.mani_member_semantics

theorem require_Usul_IDAJudgment_validity_member_semantics :
    ∀ v : Validity,
      knownMember (.wadi .validity) 1 v = some (v == .fasid) ∧
      knownMember (.wadi .validity) 2 v = some (v == .sahih) ∧
      knownMember (.wadi .validity) 3 v = some true :=
  Usul.IDAJudgment.validity_member_semantics

theorem require_Usul_IDAJudgment_decodeQuestion_rejects :
    ∀ tag : Nat, 5 ≤ tag → decodeQuestion tag = none :=
  Usul.IDAJudgment.decodeQuestion_rejects

theorem require_Usul_IDAJudgment_decode_rejects_question :
    ∀ tag code : Nat, 5 ≤ tag → decode tag code = none :=
  Usul.IDAJudgment.decode_rejects_question

theorem require_Usul_IDAJudgment_decodeVerdict_rejects :
    ∀ (q : Question) (code : Nat), 35 ≤ code → decodeVerdict q code = none :=
  Usul.IDAJudgment.decodeVerdict_rejects

theorem require_Usul_IDAJudgment_decode_rejects_answer :
    ∀ tag code : Nat, 35 ≤ code → decode tag code = none :=
  Usul.IDAJudgment.decode_rejects_answer

theorem require_Usul_IDAJudgment_decode_answer_fidelity :
    ∀ (tag code : Nat) (d : DecodedJudgment),
      decode tag code = some d → encodeVerdict d.verdict = code :=
  Usul.IDAJudgment.decode_answer_fidelity

theorem require_Usul_IDAJudgment_replay_question_fidelity :
    ∀ (p : Packet) (t : TrustedSnapshot) (j : Judgment),
      replay p t = .ok j → encodeQuestion j.decoded.question = p.claim.scope.question :=
  Usul.IDAJudgment.replay_question_fidelity

theorem require_Usul_IDAJudgment_replay_answer_fidelity :
    ∀ (p : Packet) (t : TrustedSnapshot) (j : Judgment),
      replay p t = .ok j → encodeVerdict j.decoded.verdict = p.claim.answer :=
  Usul.IDAJudgment.replay_answer_fidelity

theorem require_Usul_IDAJudgment_replayCode_of_success :
    ∀ (p : Packet) (t : TrustedSnapshot) (j : Judgment),
      replay p t = .ok j → replayCode p t = p.claim.answer :=
  Usul.IDAJudgment.replayCode_of_success

/-! ## Literal syntax and coherent malformed records -/

theorem require_UsulTest_IDAJudgment_rejects_digest_syntax :
    digestRejected "" = true ∧ digestRejected (repeatedDigest 'A') = true ∧
    digestRejected (String.ofList (List.replicate 63 'a')) = true ∧
    digestRejected (String.ofList (List.replicate 65 'a')) = true ∧
    digestRejected (repeatedDigest 'g') = true :=
  UsulTest.IDAJudgment.rejects_digest_syntax

theorem require_UsulTest_IDAJudgment_rejects_empty_interpretation :
    let c := baseClaim 0 1
    synchronizedCode { c with interpretationId := "" } = 102 ∧
    synchronizedCode { c with interpretationVersion := "" } = 102 :=
  UsulTest.IDAJudgment.rejects_empty_interpretation

theorem require_UsulTest_IDAJudgment_rejects_empty_required_identifiers :
    let c := baseClaim 0 1
    synchronizedCode { c with scope := { c.scope with questionId := "" } } = 102 ∧
    synchronizedCode { c with scope := { c.scope with profile := "" } } = 102 ∧
    synchronizedCode { c with scope := { c.scope with profileVersion := "" } } = 102 ∧
    synchronizedCode { c with source := { c.source with sourceId := "" } } = 102 ∧
    synchronizedCode { c with source := { c.source with locator := "" } } = 102 ∧
    synchronizedCode { c with evidenceGrade := "" } = 102 ∧
    synchronizedCode { c with implementationRevision := "" } = 102 :=
  UsulTest.IDAJudgment.rejects_empty_required_identifiers

theorem require_UsulTest_IDAJudgment_accepts_empty_opaque_scope_identifiers :
    let c := baseClaim 0 1
    synchronizedCode { c with scope := { c.scope with
      subject := "", target := "", context := "", time := "" } } = 1 :=
  UsulTest.IDAJudgment.accepts_empty_opaque_scope_identifiers

/-! ## Declared replay examples and diagnostic priority -/

theorem require_UsulTest_IDAJudgment_accepted_taklifi_masks :
    ∀ a : Fin 31, fixtureCode 0 (a.val + 1) 1 0 = a.val + 1 :=
  UsulTest.IDAJudgment.accepted_taklifi_masks

theorem require_UsulTest_IDAJudgment_accepted_boolean_masks :
    ∀ q : Fin 3, ∀ a : Fin 3,
      fixtureCode (q.val + 1) (a.val + 1) 1 0 = a.val + 1 :=
  UsulTest.IDAJudgment.accepted_boolean_masks

theorem require_UsulTest_IDAJudgment_accepted_validity_masks :
    ∀ a : Fin 3, fixtureCode 4 (a.val + 1) 1 0 = a.val + 1 :=
  UsulTest.IDAJudgment.accepted_validity_masks

theorem require_UsulTest_IDAJudgment_preserved_exceptional_statuses :
    ∀ q : Fin 5,
      fixtureCode q.val 0 1 0 = 0 ∧ fixtureCode q.val 32 1 0 = 32 ∧
      fixtureCode q.val 33 1 0 = 33 ∧ fixtureCode q.val 34 1 0 = 34 :=
  UsulTest.IDAJudgment.preserved_exceptional_statuses

theorem require_UsulTest_IDAJudgment_rejects_invalid_types :
    fixtureCode 5 1 1 0 = 100 ∧ fixtureCode 0 35 1 0 = 100 ∧
    fixtureCode 1 4 1 0 = 100 ∧ fixtureCode 2 4 1 0 = 100 ∧
    fixtureCode 3 4 1 0 = 100 ∧ fixtureCode 4 4 1 0 = 100 :=
  UsulTest.IDAJudgment.rejects_invalid_types

theorem require_UsulTest_IDAJudgment_rejects_unsupported_schema_rule :
    fixtureCode 0 1 1 17 = 101 ∧ fixtureCode 0 1 1 18 = 101 :=
  UsulTest.IDAJudgment.rejects_unsupported_schema_rule

theorem require_UsulTest_IDAJudgment_rejects_malformed_provenance :
    fixtureCode 0 1 1 24 = 102 ∧ fixtureCode 0 1 1 30 = 102 :=
  UsulTest.IDAJudgment.rejects_malformed_provenance

theorem require_UsulTest_IDAJudgment_rejects_changed_scope :
    fixtureCode 0 1 1 1 = 103 ∧ fixtureCode 0 1 1 2 = 103 ∧
    fixtureCode 0 1 1 3 = 103 ∧ fixtureCode 0 1 1 4 = 103 ∧
    fixtureCode 0 1 1 5 = 103 ∧ fixtureCode 0 1 1 6 = 103 ∧
    fixtureCode 0 1 1 7 = 103 ∧ fixtureCode 0 1 1 23 = 103 ∧
    fixtureCode 0 1 1 32 = 103 :=
  UsulTest.IDAJudgment.rejects_changed_scope

theorem require_UsulTest_IDAJudgment_rejects_changed_registered_source :
    fixtureCode 0 1 1 9 = 104 ∧ fixtureCode 0 1 1 10 = 104 ∧
    fixtureCode 0 1 1 11 = 104 ∧ fixtureCode 0 1 1 12 = 104 ∧
    fixtureCode 0 1 1 21 = 104 ∧ fixtureCode 0 1 1 22 = 104 :=
  UsulTest.IDAJudgment.rejects_changed_registered_source

theorem require_UsulTest_IDAJudgment_rejects_nonadmitted_despite_report :
    fixtureCode 0 1 0 20 = 105 ∧ fixtureCode 0 1 2 20 = 105 ∧
    fixtureCode 0 1 3 20 = 105 :=
  UsulTest.IDAJudgment.rejects_nonadmitted_despite_report

theorem require_UsulTest_IDAJudgment_ignores_reported_admission :
    fixtureCode 0 1 1 0 = 1 ∧ fixtureCode 0 1 1 20 = 1 :=
  UsulTest.IDAJudgment.ignores_reported_admission

theorem require_UsulTest_IDAJudgment_rejects_retained_derivation :
    fixtureCode 0 1 1 8 = 106 ∧ fixtureCode 0 1 1 13 = 106 ∧
    fixtureCode 0 1 1 14 = 106 ∧ fixtureCode 0 1 1 15 = 106 ∧
    fixtureCode 0 1 1 16 = 106 ∧ fixtureCode 0 1 1 19 = 106 :=
  UsulTest.IDAJudgment.rejects_retained_derivation

theorem require_UsulTest_IDAJudgment_rejects_coherent_claimant_rebind :
    fixtureCode 0 1 1 25 = 107 ∧ fixtureCode 0 1 1 26 = 107 ∧
    fixtureCode 0 1 1 27 = 107 ∧ fixtureCode 0 1 1 28 = 107 ∧
    fixtureCode 0 1 1 29 = 107 ∧ fixtureCode 0 1 1 31 = 107 ∧
    fixtureCode 0 1 1 33 = 107 :=
  UsulTest.IDAJudgment.rejects_coherent_claimant_rebind

theorem require_UsulTest_IDAJudgment_type_precedes_schema :
    fixtureCode 5 1 0 17 = 100 :=
  UsulTest.IDAJudgment.type_precedes_schema

theorem require_UsulTest_IDAJudgment_schema_precedes_malformed :
    let (p, t) := makeFixture 0 1 0 30
    replayCode { p with derivation := { p.derivation with schema := 0 } } t = 101 :=
  UsulTest.IDAJudgment.schema_precedes_malformed

theorem require_UsulTest_IDAJudgment_malformed_precedes_scope :
    let (p, t) := makeFixture 0 1 0 24
    replayCode p { t with currentScope := { t.currentScope with questionId := "changed" } } = 102 :=
  UsulTest.IDAJudgment.malformed_precedes_scope

theorem require_UsulTest_IDAJudgment_scope_precedes_source :
    let (p, t) := makeFixture 0 1 0 1
    replayCode p { t with sourceEnabled := false } = 103 :=
  UsulTest.IDAJudgment.scope_precedes_source

theorem require_UsulTest_IDAJudgment_source_precedes_admission :
    fixtureCode 0 1 0 21 = 104 :=
  UsulTest.IDAJudgment.source_precedes_admission

theorem require_UsulTest_IDAJudgment_admission_precedes_derivation :
    fixtureCode 0 1 0 19 = 105 :=
  UsulTest.IDAJudgment.admission_precedes_derivation

theorem require_UsulTest_IDAJudgment_derivation_precedes_admission_binding :
    fixtureCode 0 1 1 8 = 106 :=
  UsulTest.IDAJudgment.derivation_precedes_admission_binding

end UsulTest.IDAJudgmentContracts
