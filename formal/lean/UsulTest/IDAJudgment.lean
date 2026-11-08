import Usul.IDAJudgment

namespace UsulTest.IDAJudgment

open Usul.IDAJudgment

set_option maxRecDepth 100000
set_option maxHeartbeats 4000000

/-- The fixture uses actual digest text, independently of the Quint representation. -/
def repeatedDigest (c : Char) : String := String.ofList (List.replicate 64 c)

/-- Base records are fixed by the shared wire contract, not generated from a validator. -/
def baseClaim (question answer : Nat) : Claim :=
  { scope :=
      { question := question
        questionId := "inquiry"
        subject := "subject"
        target := "target"
        context := "context"
        time := "time"
        profile := "profile"
        profileVersion := "v1" }
    answer := answer
    source :=
      { sourceId := "source"
        sourceDigest := repeatedDigest 'a'
        locator := "passage"
        passageDigest := repeatedDigest 'c' }
    interpretationId := "interpretation"
    interpretationVersion := "v1"
    evidenceGrade := "synthetic"
    implementationRevision := "revision" }

def changedAnswer (answer : Nat) : Nat := if answer = 1 then 2 else 1

def baseFixture (question answer status : Nat) : Packet × TrustedSnapshot :=
  let c := baseClaim question answer
  ({ claim := c
     derivation := { frozenClaim := c, schema := 1, rule := 0 }
     reportedAdmissionStatus := 0 },
   { currentScope := c.scope
     registeredSource := c.source
     sourceEnabled := true
     admission := { claim := c, status := status } })

/-- One changed claim field; all other fields retain their base values. -/
def changedClaim (c : Claim) (variant : Nat) : Claim :=
  match variant with
  | 1 => { c with scope := { c.scope with question := (c.scope.question + 1) % 5 } }
  | 2 => { c with scope := { c.scope with subject := "changed" } }
  | 3 => { c with scope := { c.scope with target := "changed" } }
  | 4 => { c with scope := { c.scope with context := "changed" } }
  | 5 => { c with scope := { c.scope with time := "changed" } }
  | 6 => { c with scope := { c.scope with profile := "changed" } }
  | 7 => { c with scope := { c.scope with profileVersion := "changed" } }
  | 8 => { c with answer := changedAnswer c.answer }
  | 9 => { c with source := { c.source with sourceId := "changed" } }
  | 10 => { c with source := { c.source with sourceDigest := repeatedDigest 'b' } }
  | 11 => { c with source := { c.source with locator := "changed" } }
  | 12 => { c with source := { c.source with passageDigest := repeatedDigest 'b' } }
  | 13 => { c with interpretationId := "changed" }
  | 14 => { c with interpretationVersion := "changed" }
  | 15 => { c with evidenceGrade := "changed" }
  | 16 => { c with implementationRevision := "changed" }
  | 32 => { c with scope := { c.scope with questionId := "changed" } }
  | _ => c

/-- Update the submitted claim and receipt together; authority is supplied separately. -/
def withClaimAndReceipt (p : Packet) (c : Claim) : Packet :=
  { p with claim := c, derivation := { p.derivation with frozenClaim := c } }

/--
The 34 variants are independent changes to the same base fixture. Variants outside
the declared comparison range are left at the base fixture and are never exported.
-/
def makeFixture (question answer status variant : Nat) : Packet × TrustedSnapshot :=
  let (p, t) := baseFixture question answer status
  let c := p.claim
  match variant with
  | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 32 =>
      ({ p with claim := changedClaim c variant }, t)
  | 17 => ({ p with derivation := { p.derivation with schema := 0 } }, t)
  | 18 => ({ p with derivation := { p.derivation with rule := 1 } }, t)
  | 19 =>
      ({ p with derivation :=
          { p.derivation with frozenClaim := { c with answer := changedAnswer c.answer } } }, t)
  | 20 => ({ p with reportedAdmissionStatus := 1 }, t)
  | 21 => (p, { t with sourceEnabled := false })
  | 22 => (p, { t with registeredSource := { t.registeredSource with sourceDigest := repeatedDigest 'b' } })
  | 23 => (p, { t with currentScope := { t.currentScope with profileVersion := "changed" } })
  | 24 =>
      let changed := { c with source := { c.source with locator := "" } }
      (withClaimAndReceipt p changed,
       { t with registeredSource := changed.source, admission := { t.admission with claim := changed } })
  | 25 =>
      let changed := changedClaim c 1
      (withClaimAndReceipt p changed, { t with currentScope := changed.scope })
  | 26 =>
      let changed := changedClaim c 10
      (withClaimAndReceipt p changed, { t with registeredSource := changed.source })
  | 27 =>
      let changed := changedClaim c 7
      (withClaimAndReceipt p changed, { t with currentScope := changed.scope })
  | 28 => (withClaimAndReceipt p (changedClaim c 8), t)
  | 29 => (withClaimAndReceipt p (changedClaim c 14), t)
  | 30 =>
      let changed := { c with source := { c.source with sourceDigest := "bad" } }
      (withClaimAndReceipt p changed,
       { t with registeredSource := changed.source, admission := { t.admission with claim := changed } })
  | 31 => (withClaimAndReceipt p (changedClaim c 16), t)
  | 33 =>
      let changed := changedClaim c 32
      (withClaimAndReceipt p changed, { t with currentScope := changed.scope })
  | _ => (p, t)

def fixture (question answer status variant : Nat) : Packet × TrustedSnapshot :=
  makeFixture question answer status variant

def fixtureCode (question answer status variant : Nat) : Nat :=
  let (p, t) := makeFixture question answer status variant
  replayCode p t

/-- Bind every fixture component to the same claim, isolating syntax checks. -/
def synchronizedCode (c : Claim) : Nat :=
  let (p, t) := baseFixture 0 1 1
  replayCode (withClaimAndReceipt p c)
    { t with
      currentScope := c.scope
      registeredSource := c.source
      admission := { t.admission with claim := c } }

def digestRejected (digest : String) : Bool :=
  let c := baseClaim 0 1
  (synchronizedCode { c with source := { c.source with sourceDigest := digest } } == 102) &&
  (synchronizedCode { c with source := { c.source with passageDigest := digest } } == 102)

theorem rejects_digest_syntax :
    digestRejected "" = true ∧ digestRejected (repeatedDigest 'A') = true ∧
    digestRejected (String.ofList (List.replicate 63 'a')) = true ∧
    digestRejected (String.ofList (List.replicate 65 'a')) = true ∧
    digestRejected (repeatedDigest 'g') = true := by decide

theorem rejects_empty_interpretation :
    let c := baseClaim 0 1
    synchronizedCode { c with interpretationId := "" } = 102 ∧
    synchronizedCode { c with interpretationVersion := "" } = 102 := by decide

theorem rejects_empty_required_identifiers :
    let c := baseClaim 0 1
    synchronizedCode { c with scope := { c.scope with questionId := "" } } = 102 ∧
    synchronizedCode { c with scope := { c.scope with profile := "" } } = 102 ∧
    synchronizedCode { c with scope := { c.scope with profileVersion := "" } } = 102 ∧
    synchronizedCode { c with source := { c.source with sourceId := "" } } = 102 ∧
    synchronizedCode { c with source := { c.source with locator := "" } } = 102 ∧
    synchronizedCode { c with evidenceGrade := "" } = 102 ∧
    synchronizedCode { c with implementationRevision := "" } = 102 := by decide

theorem accepts_empty_opaque_scope_identifiers :
    let c := baseClaim 0 1
    synchronizedCode { c with scope := { c.scope with
      subject := "", target := "", context := "", time := "" } } = 1 := by decide

theorem accepted_taklifi_masks : ∀ a : Fin 31,
    fixtureCode 0 (a.val + 1) 1 0 = a.val + 1 := by decide

theorem accepted_boolean_masks : ∀ q : Fin 3, ∀ a : Fin 3,
    fixtureCode (q.val + 1) (a.val + 1) 1 0 = a.val + 1 := by decide

theorem accepted_validity_masks : ∀ a : Fin 3,
    fixtureCode 4 (a.val + 1) 1 0 = a.val + 1 := by decide

theorem preserved_exceptional_statuses : ∀ q : Fin 5,
    fixtureCode q.val 0 1 0 = 0 ∧ fixtureCode q.val 32 1 0 = 32 ∧
    fixtureCode q.val 33 1 0 = 33 ∧ fixtureCode q.val 34 1 0 = 34 := by decide

theorem rejects_invalid_types :
    fixtureCode 5 1 1 0 = 100 ∧ fixtureCode 0 35 1 0 = 100 ∧
    fixtureCode 1 4 1 0 = 100 ∧ fixtureCode 2 4 1 0 = 100 ∧
    fixtureCode 3 4 1 0 = 100 ∧ fixtureCode 4 4 1 0 = 100 := by decide

theorem rejects_unsupported_schema_rule :
    fixtureCode 0 1 1 17 = 101 ∧ fixtureCode 0 1 1 18 = 101 := by decide

theorem rejects_malformed_provenance :
    fixtureCode 0 1 1 24 = 102 ∧ fixtureCode 0 1 1 30 = 102 := by decide

theorem rejects_changed_scope :
    fixtureCode 0 1 1 1 = 103 ∧ fixtureCode 0 1 1 2 = 103 ∧
    fixtureCode 0 1 1 3 = 103 ∧ fixtureCode 0 1 1 4 = 103 ∧
    fixtureCode 0 1 1 5 = 103 ∧ fixtureCode 0 1 1 6 = 103 ∧
    fixtureCode 0 1 1 7 = 103 ∧ fixtureCode 0 1 1 23 = 103 ∧
    fixtureCode 0 1 1 32 = 103 := by decide

theorem rejects_changed_registered_source :
    fixtureCode 0 1 1 9 = 104 ∧ fixtureCode 0 1 1 10 = 104 ∧
    fixtureCode 0 1 1 11 = 104 ∧ fixtureCode 0 1 1 12 = 104 ∧
    fixtureCode 0 1 1 21 = 104 ∧ fixtureCode 0 1 1 22 = 104 := by decide

theorem rejects_nonadmitted_despite_report :
    fixtureCode 0 1 0 20 = 105 ∧ fixtureCode 0 1 2 20 = 105 ∧
    fixtureCode 0 1 3 20 = 105 := by decide

theorem ignores_reported_admission :
    fixtureCode 0 1 1 0 = 1 ∧ fixtureCode 0 1 1 20 = 1 := by decide

theorem rejects_retained_derivation :
    fixtureCode 0 1 1 8 = 106 ∧ fixtureCode 0 1 1 13 = 106 ∧
    fixtureCode 0 1 1 14 = 106 ∧ fixtureCode 0 1 1 15 = 106 ∧
    fixtureCode 0 1 1 16 = 106 ∧ fixtureCode 0 1 1 19 = 106 := by decide

theorem rejects_coherent_claimant_rebind :
    fixtureCode 0 1 1 25 = 107 ∧ fixtureCode 0 1 1 26 = 107 ∧
    fixtureCode 0 1 1 27 = 107 ∧ fixtureCode 0 1 1 28 = 107 ∧
    fixtureCode 0 1 1 29 = 107 ∧ fixtureCode 0 1 1 31 = 107 ∧
    fixtureCode 0 1 1 33 = 107 := by decide

theorem type_precedes_schema : fixtureCode 5 1 0 17 = 100 := by decide

theorem schema_precedes_malformed :
    let (p, t) := makeFixture 0 1 0 30
    replayCode { p with derivation := { p.derivation with schema := 0 } } t = 101 := by decide

theorem malformed_precedes_scope :
    let (p, t) := makeFixture 0 1 0 24
    replayCode p { t with currentScope := { t.currentScope with questionId := "changed" } } = 102 := by decide

theorem scope_precedes_source :
    let (p, t) := makeFixture 0 1 0 1
    replayCode p { t with sourceEnabled := false } = 103 := by decide

theorem source_precedes_admission : fixtureCode 0 1 0 21 = 104 := by decide

theorem admission_precedes_derivation : fixtureCode 0 1 0 19 = 105 := by decide

theorem derivation_precedes_admission_binding : fixtureCode 0 1 1 8 = 106 := by decide

end UsulTest.IDAJudgment
