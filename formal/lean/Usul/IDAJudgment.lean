import Usul.Judgement
import Usul.IDA

namespace Usul.IDAJudgment

/-- A nonempty subset of the answer carrier selected by the question. -/
structure KnownAnswers (q : Question) where
  mem : q.Answer → Bool
  nonempty : ∃ answer, mem answer = true

/-- Exceptional epistemic states do not become ordinary carrier answers. -/
inductive Verdict (q : Question) where
  | known (answers : KnownAnswers q)
  | noRuling
  | suspended
  | conflict
  | outOfScope

structure DecodedJudgment where
  question : Question
  verdict : Verdict question
  answerTag : Nat

def decodeQuestion : Nat → Option Question
  | 0 => some .taklifi
  | 1 => some (.wadi .sabab)
  | 2 => some (.wadi .shart)
  | 3 => some (.wadi .mani)
  | 4 => some (.wadi .validity)
  | _ => none

def ofIDA (c : IDA.Constraint) : KnownAnswers .taklifi :=
  ⟨c.set.mem, IDA.Constraint.has_member c⟩

def boolKnown (s : Sign) (h : s ≠ .validity) (code : Nat) :
    Option (KnownAnswers (.wadi s)) := by
  cases s with
  | validity => exact False.elim (h rfl)
  | sabab | shart | mani =>
    exact match code with
    | 1 => some ⟨fun b => !b, ⟨false, rfl⟩⟩
    | 2 => some ⟨fun b => b, ⟨true, rfl⟩⟩
    | 3 => some ⟨fun _ => true, ⟨false, rfl⟩⟩
    | _ => none

def validityKnown : Nat → Option (KnownAnswers (.wadi .validity))
  | 1 => some ⟨fun v => v == .fasid, ⟨.fasid, rfl⟩⟩
  | 2 => some ⟨fun v => v == .sahih, ⟨.sahih, rfl⟩⟩
  | 3 => some ⟨fun _ => true, ⟨.fasid, rfl⟩⟩
  | _ => none

def decodeKnown : (q : Question) → Nat → Option (KnownAnswers q)
  | .taklifi, code => (IDA.decodeConstraint code).map ofIDA
  | .wadi .sabab, code => boolKnown .sabab (by decide) code
  | .wadi .shart, code => boolKnown .shart (by decide) code
  | .wadi .mani, code => boolKnown .mani (by decide) code
  | .wadi .validity, code => validityKnown code

def decodeVerdict (q : Question) (code : Nat) : Option (Verdict q) :=
  if code = 0 then some .noRuling
  else if code = 32 then some .suspended
  else if code = 33 then some .conflict
  else if code = 34 then some .outOfScope
  else (decodeKnown q code).map Verdict.known

def decode (q code : Nat) : Option DecodedJudgment := do
  let question ← decodeQuestion q
  let verdict ← decodeVerdict question code
  pure ⟨question, verdict, code⟩

structure Scope where
  question : Nat
  questionId : String
  subject : String
  target : String
  context : String
  time : String
  profile : String
  profileVersion : String
  deriving DecidableEq, Repr

structure SourceRef where
  sourceId : String
  sourceDigest : String
  locator : String
  passageDigest : String
  deriving DecidableEq, Repr

structure Claim where
  scope : Scope
  answer : Nat
  source : SourceRef
  interpretationId : String
  interpretationVersion : String
  evidenceGrade : String
  implementationRevision : String
  deriving DecidableEq, Repr

structure Derivation where
  frozenClaim : Claim
  schema : Nat
  rule : Nat
  deriving DecidableEq, Repr

structure Packet where
  claim : Claim
  derivation : Derivation
  reportedAdmissionStatus : Nat
  deriving DecidableEq, Repr

structure Admission where
  claim : Claim
  status : Nat
  deriving DecidableEq, Repr

structure TrustedSnapshot where
  currentScope : Scope
  registeredSource : SourceRef
  sourceEnabled : Bool
  admission : Admission
  deriving DecidableEq, Repr

/-- Success retains the entire bound provenance and the authoritative status. -/
structure Judgment where
  claim : Claim
  admissionStatus : Nat
  decoded : DecodedJudgment

def lowercaseHex (c : Char) : Bool :=
  ('0' ≤ c && c ≤ '9') || ('a' ≤ c && c ≤ 'f')

def validDigest (s : String) : Bool :=
  s.length == 64 && s.toList.all lowercaseHex

def validProvenance (c : Claim) : Bool :=
  !c.scope.questionId.isEmpty && !c.scope.profile.isEmpty &&
  !c.scope.profileVersion.isEmpty && !c.source.sourceId.isEmpty &&
  !c.source.locator.isEmpty && !c.interpretationId.isEmpty &&
  !c.interpretationVersion.isEmpty && !c.evidenceGrade.isEmpty &&
  !c.implementationRevision.isEmpty && validDigest c.source.sourceDigest &&
  validDigest c.source.passageDigest

structure Guards (p : Packet) (t : TrustedSnapshot) : Prop where
  decoded : ∃ d, decode p.claim.scope.question p.claim.answer = some d
  schema : p.derivation.schema = 1
  rule : p.derivation.rule = 0
  provenance : validProvenance p.claim = true
  scope : p.claim.scope = t.currentScope
  source : p.claim.source = t.registeredSource
  enabled : t.sourceEnabled = true
  admitted : t.admission.status = 1
  receipt : p.claim = p.derivation.frozenClaim
  admission : p.claim = t.admission.claim

/-- Ordered validation of one immutable packet against one externally trusted snapshot. -/
def replay (p : Packet) (t : TrustedSnapshot) : Except Nat Judgment :=
  match decode p.claim.scope.question p.claim.answer with
  | none => .error 100
  | some d =>
    if p.derivation.schema ≠ 1 ∨ p.derivation.rule ≠ 0 then .error 101
    else if validProvenance p.claim ≠ true then .error 102
    else if p.claim.scope ≠ t.currentScope then .error 103
    else if t.sourceEnabled ≠ true ∨ p.claim.source ≠ t.registeredSource then .error 104
    else if t.admission.status ≠ 1 then .error 105
    else if p.claim ≠ p.derivation.frozenClaim then .error 106
    else if p.claim ≠ t.admission.claim then .error 107
    else .ok ⟨p.claim, t.admission.status, d⟩

def Accepted (p : Packet) (t : TrustedSnapshot) : Prop :=
  ∃ judgment, replay p t = .ok judgment

theorem accepted_guards (p : Packet) (t : TrustedSnapshot) :
    Accepted p t → Guards p t := by
  rintro ⟨j, hj⟩
  unfold replay at hj
  split at hj
  · cases hj
  · rename_i d hd
    split at hj
    · cases hj
    · rename_i hv
      split at hj
      · cases hj
      · rename_i hp
        split at hj
        · cases hj
        · rename_i hs
          split at hj
          · cases hj
          · rename_i hr
            split at hj
            · cases hj
            · rename_i ha
              split at hj
              · cases hj
              · rename_i hf
                split at hj
                · cases hj
                · rename_i hb
                  exact ⟨⟨d, hd⟩, by simpa using (not_or.mp hv).1,
                    by simpa using (not_or.mp hv).2, by simpa using hp,
                    by simpa using hs, by simpa using (not_or.mp hr).2,
                    by simpa using (not_or.mp hr).1, by simpa using ha,
                    by simpa using hf, by simpa using hb⟩

theorem replay_of_guards (p : Packet) (t : TrustedSnapshot)
    (g : Guards p t) (d : DecodedJudgment)
    (hd : decode p.claim.scope.question p.claim.answer = some d) :
    replay p t = .ok ⟨p.claim, t.admission.status, d⟩ := by
  unfold replay
  rw [hd]
  simp only []
  rw [ite_eq_right (fun h => h.elim (fun hn => hn g.schema) (fun hn => hn g.rule))]
  rw [ite_eq_right (fun hn => hn g.provenance)]
  rw [ite_eq_right (fun hn => hn g.scope)]
  rw [ite_eq_right (fun h => h.elim (fun hn => hn g.enabled) (fun hn => hn g.source))]
  rw [ite_eq_right (fun hn => hn g.admitted)]
  rw [ite_eq_right (fun hn => hn g.receipt)]
  rw [ite_eq_right (fun hn => hn g.admission)]

theorem guards_accepted (p : Packet) (t : TrustedSnapshot) :
    Guards p t → Accepted p t := by
  intro h
  rcases h.decoded with ⟨d, hd⟩
  exact ⟨_, replay_of_guards p t h d hd⟩

theorem accepted_iff_guards (p : Packet) (t : TrustedSnapshot) :
    Accepted p t ↔ Guards p t :=
  ⟨accepted_guards p t, guards_accepted p t⟩

theorem accepted_decodes (p : Packet) (t : TrustedSnapshot) (h : Accepted p t) :
    ∃ d, decode p.claim.scope.question p.claim.answer = some d :=
  (accepted_guards p t h).decoded

theorem accepted_schema (p : Packet) (t : TrustedSnapshot) (h : Accepted p t) :
    p.derivation.schema = 1 := (accepted_guards p t h).schema

theorem accepted_rule (p : Packet) (t : TrustedSnapshot) (h : Accepted p t) :
    p.derivation.rule = 0 := (accepted_guards p t h).rule

theorem accepted_provenance (p : Packet) (t : TrustedSnapshot) (h : Accepted p t) :
    validProvenance p.claim = true := (accepted_guards p t h).provenance

theorem accepted_scope (p : Packet) (t : TrustedSnapshot) (h : Accepted p t) :
    p.claim.scope = t.currentScope := (accepted_guards p t h).scope

theorem accepted_source (p : Packet) (t : TrustedSnapshot) (h : Accepted p t) :
    p.claim.source = t.registeredSource := (accepted_guards p t h).source

theorem accepted_enabled (p : Packet) (t : TrustedSnapshot) (h : Accepted p t) :
    t.sourceEnabled = true := (accepted_guards p t h).enabled

theorem accepted_admitted (p : Packet) (t : TrustedSnapshot) (h : Accepted p t) :
    t.admission.status = 1 := (accepted_guards p t h).admitted

theorem accepted_receipt (p : Packet) (t : TrustedSnapshot) (h : Accepted p t) :
    p.claim = p.derivation.frozenClaim := (accepted_guards p t h).receipt

theorem accepted_admission (p : Packet) (t : TrustedSnapshot) (h : Accepted p t) :
    p.claim = t.admission.claim := (accepted_guards p t h).admission

theorem changed_receipt_cannot_reuse (p : Packet) (t : TrustedSnapshot)
    (h : p.claim ≠ p.derivation.frozenClaim) : ¬ Accepted p t :=
  fun ha => h (accepted_receipt p t ha)

theorem changed_admission_cannot_reuse (p : Packet) (t : TrustedSnapshot)
    (h : p.claim ≠ t.admission.claim) : ¬ Accepted p t :=
  fun ha => h (accepted_admission p t ha)

theorem changed_scope_cannot_reuse (p : Packet) (t : TrustedSnapshot)
    (h : p.claim.scope ≠ t.currentScope) : ¬ Accepted p t :=
  fun ha => h (accepted_scope p t ha)

theorem changed_source_cannot_reuse (p : Packet) (t : TrustedSnapshot)
    (h : p.claim.source ≠ t.registeredSource) : ¬ Accepted p t :=
  fun ha => h (accepted_source p t ha)

theorem reported_status_irrelevant (p : Packet) (t : TrustedSnapshot) (status : Nat) :
    replay { p with reportedAdmissionStatus := status } t = replay p t := rfl

theorem invalid_type_rejected (p : Packet) (t : TrustedSnapshot)
    (h : decode p.claim.scope.question p.claim.answer = none) :
    replay p t = .error 100 := by simp [replay, h]

theorem known_nonempty (q : Question) (answers : KnownAnswers q) :
    ∃ answer, answers.mem answer = true := answers.nonempty

theorem noRuling_ne_suspended (q : Question) :
    (Verdict.noRuling : Verdict q) ≠ .suspended := by intro h; cases h

theorem noRuling_ne_conflict (q : Question) :
    (Verdict.noRuling : Verdict q) ≠ .conflict := by intro h; cases h

theorem suspended_ne_conflict (q : Question) :
    (Verdict.suspended : Verdict q) ≠ .conflict := by intro h; cases h

theorem known_ne_exceptional (q : Question) (answers : KnownAnswers q) :
    Verdict.known answers ≠ .noRuling ∧ Verdict.known answers ≠ .suspended ∧
    Verdict.known answers ≠ .conflict ∧ Verdict.known answers ≠ .outOfScope := by
  exact ⟨(by intro h; cases h), (by intro h; cases h),
    (by intro h; cases h), (by intro h; cases h)⟩

theorem replay_retains_claim (p : Packet) (t : TrustedSnapshot) (j : Judgment)
    (h : replay p t = .ok j) : j.claim = p.claim := by
  have g := accepted_guards p t ⟨j, h⟩
  rcases g.decoded with ⟨d, hd⟩
  have hj := Except.ok.inj ((replay_of_guards p t g d hd).symm.trans h)
  cases hj
  rfl

theorem replay_retains_status (p : Packet) (t : TrustedSnapshot) (j : Judgment)
    (h : replay p t = .ok j) : j.admissionStatus = 1 := by
  have g := accepted_guards p t ⟨j, h⟩
  rcases g.decoded with ⟨d, hd⟩
  have hj := Except.ok.inj ((replay_of_guards p t g d hd).symm.trans h)
  cases hj
  exact g.admitted

theorem replay_retains_decoding (p : Packet) (t : TrustedSnapshot) (j : Judgment)
    (h : replay p t = .ok j) :
    decode p.claim.scope.question p.claim.answer = some j.decoded := by
  have g := accepted_guards p t ⟨j, h⟩
  rcases g.decoded with ⟨d, hd⟩
  have hj := Except.ok.inj ((replay_of_guards p t g d hd).symm.trans h)
  cases hj
  exact hd

/-! ## Typed serialization and carrier semantics -/

def encodeQuestion : Question → Nat
  | .taklifi => 0
  | .wadi .sabab => 1
  | .wadi .shart => 2
  | .wadi .mani => 3
  | .wadi .validity => 4

def encodeKnown : (q : Question) → KnownAnswers q → Nat
  | .taklifi, answers =>
      IDA.encodeSet ⟨answers.mem .haram, answers.mem .makruh, answers.mem .mubah,
        answers.mem .mandub, answers.mem .wajib⟩
  | .wadi .sabab, answers =>
      (if answers.mem false then 1 else 0) + (if answers.mem true then 2 else 0)
  | .wadi .shart, answers =>
      (if answers.mem false then 1 else 0) + (if answers.mem true then 2 else 0)
  | .wadi .mani, answers =>
      (if answers.mem false then 1 else 0) + (if answers.mem true then 2 else 0)
  | .wadi .validity, answers =>
      (if answers.mem .fasid then 1 else 0) + (if answers.mem .sahih then 2 else 0)

def encodeVerdict {q : Question} : Verdict q → Nat
  | .known answers => encodeKnown q answers
  | .noRuling => 0
  | .suspended => 32
  | .conflict => 33
  | .outOfScope => 34

def knownMember (q : Question) (code : Nat) (answer : q.Answer) : Option Bool :=
  (decodeKnown q code).map fun answers => answers.mem answer

theorem decodeQuestion_fidelity (tag : Nat) (q : Question)
    (h : decodeQuestion tag = some q) : encodeQuestion q = tag := by
  unfold decodeQuestion at h
  split at h <;> simp_all [encodeQuestion]
  all_goals subst q; rfl

theorem decode_question_fidelity (tag code : Nat) (d : DecodedJudgment)
    (h : decode tag code = some d) : encodeQuestion d.question = tag := by
  unfold decode at h
  cases hq : decodeQuestion tag with
  | none => simp [hq] at h
  | some q =>
    cases hv : decodeVerdict q code with
    | none => simp [hq, hv] at h
    | some v =>
      simp [hq, hv] at h
      cases h
      exact decodeQuestion_fidelity tag q hq

theorem decoded_canonical_codes : ∀ q : Fin 5, ∀ code : Fin 35,
    (decode q.val code.val).map (fun d => encodeVerdict d.verdict) =
      if code.val = 0 ∨ code.val = 32 ∨ code.val = 33 ∨ code.val = 34 ∨
         (1 ≤ code.val ∧ code.val ≤ (if q.val = 0 then 31 else 3))
      then some code.val else none := by decide

theorem taklifi_member_semantics (h : Hukm) :
    knownMember .taklifi 1 h = some (h == .haram) ∧
    knownMember .taklifi 2 h = some (h == .makruh) ∧
    knownMember .taklifi 4 h = some (h == .mubah) ∧
    knownMember .taklifi 8 h = some (h == .mandub) ∧
    knownMember .taklifi 16 h = some (h == .wajib) := by
  cases h <;> decide

theorem sabab_member_semantics (b : Bool) :
    knownMember (.wadi .sabab) 1 b = some (!b) ∧
    knownMember (.wadi .sabab) 2 b = some b ∧
    knownMember (.wadi .sabab) 3 b = some true := by
  cases b <;> decide

theorem shart_member_semantics (b : Bool) :
    knownMember (.wadi .shart) 1 b = some (!b) ∧
    knownMember (.wadi .shart) 2 b = some b ∧
    knownMember (.wadi .shart) 3 b = some true := by
  cases b <;> decide

theorem mani_member_semantics (b : Bool) :
    knownMember (.wadi .mani) 1 b = some (!b) ∧
    knownMember (.wadi .mani) 2 b = some b ∧
    knownMember (.wadi .mani) 3 b = some true := by
  cases b <;> decide

theorem validity_member_semantics (v : Validity) :
    knownMember (.wadi .validity) 1 v = some (v == .fasid) ∧
    knownMember (.wadi .validity) 2 v = some (v == .sahih) ∧
    knownMember (.wadi .validity) 3 v = some true := by
  cases v <;> decide

theorem decodeQuestion_rejects (tag : Nat) (h : 5 ≤ tag) :
    decodeQuestion tag = none := by
  unfold decodeQuestion
  split <;> first | rfl | omega

theorem decode_rejects_question (tag code : Nat) (h : 5 ≤ tag) :
    decode tag code = none := by
  simp [decode, decodeQuestion_rejects tag h]

theorem decodeVerdict_rejects (q : Question) (code : Nat) (h : 35 ≤ code) :
    decodeVerdict q code = none := by
  have h0 : code ≠ 0 := by omega
  have h32 : code ≠ 32 := by omega
  have h33 : code ≠ 33 := by omega
  have h34 : code ≠ 34 := by omega
  have h31 : ¬ (1 ≤ code ∧ code ≤ 31) := by omega
  cases q with
  | taklifi => simp [decodeVerdict, h0, h32, h33, h34, decodeKnown, IDA.decodeConstraint, h31]
  | wadi s =>
    cases s <;> simp [decodeVerdict, h0, h32, h33, h34, decodeKnown, boolKnown, validityKnown]
    all_goals split <;> first | rfl | omega

theorem decode_rejects_answer (tag code : Nat) (h : 35 ≤ code) :
    decode tag code = none := by
  unfold decode
  cases hq : decodeQuestion tag with
  | none => simp
  | some q => simp [decodeVerdict_rejects q code h]

theorem decode_answer_fidelity (tag code : Nat) (d : DecodedJudgment)
    (h : decode tag code = some d) : encodeVerdict d.verdict = code := by
  have htag : tag < 5 := by
    by_cases hb : 5 ≤ tag
    · rw [decode_rejects_question tag code hb] at h
      cases h
    · omega
  have hcode : code < 35 := by
    by_cases hb : 35 ≤ code
    · rw [decode_rejects_answer tag code hb] at h
      cases h
    · omega
  have hc := decoded_canonical_codes ⟨tag, htag⟩ ⟨code, hcode⟩
  change (decode tag code).map (fun d => encodeVerdict d.verdict) = _ at hc
  rw [h] at hc
  simp only [Option.map_some] at hc
  split at hc <;> split at hc
  all_goals first | exact Option.some.inj hc | cases hc

theorem replay_question_fidelity (p : Packet) (t : TrustedSnapshot) (j : Judgment)
    (h : replay p t = .ok j) : encodeQuestion j.decoded.question = p.claim.scope.question :=
  decode_question_fidelity _ _ _ (replay_retains_decoding p t j h)

theorem replay_answer_fidelity (p : Packet) (t : TrustedSnapshot) (j : Judgment)
    (h : replay p t = .ok j) : encodeVerdict j.decoded.verdict = p.claim.answer :=
  decode_answer_fidelity _ _ _ (replay_retains_decoding p t j h)

def replayCode (p : Packet) (t : TrustedSnapshot) : Nat :=
  match replay p t with
  | .error code => code
  | .ok j => encodeVerdict j.decoded.verdict

theorem replayCode_of_success (p : Packet) (t : TrustedSnapshot) (j : Judgment)
    (h : replay p t = .ok j) : replayCode p t = p.claim.answer := by
  unfold replayCode
  rw [h]
  exact replay_answer_fidelity p t j h

end Usul.IDAJudgment
