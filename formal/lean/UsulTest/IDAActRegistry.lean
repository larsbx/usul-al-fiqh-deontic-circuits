import Usul.Typing.IDAActRegistry
import UsulTest.IDADerivation

/-! Synthetic ACT-01 fixtures. Neither the predicate nor the act is a fiqh ruling.
The public fixture data and finite domains are shared with independent Quint;
the oracle below is a separately stated table of expected observations. -/

namespace UsulTest.IDAActRegistry

open Usul Usul.IDA Usul.IDA.ActRegistry

def baseDigest : List Nat :=
  [8,70,205,21,208,245,133,192,119,114,183,158,215,102,36,130,
   195,174,38,21,178,69,147,192,44,51,172,159,176,205,107,148]

def baseDefinition : Definition :=
  { key := ⟨⟨"synthetic.act", "transfer"⟩, 1⟩
    digest := baseDigest
    roles := [⟨"payer", some .person⟩, ⟨"recipient", some .person⟩, ⟨"property", some .asset⟩] }

def baseRegistry : Registry := ⟨1, [baseDefinition]⟩
def payer : EntityRef := ⟨.person, ⟨"person", "alice"⟩⟩
def recipient : EntityRef := ⟨.person, ⟨"person", "bob"⟩⟩
def property : EntityRef := ⟨.asset, ⟨"asset", "coin"⟩⟩
def baseAction : Action :=
  ⟨⟨baseDefinition.key.symbol, [⟨"payer", .person⟩, ⟨"recipient", .person⟩, ⟨"property", .asset⟩]⟩,
   [⟨"payer", payer⟩, ⟨"recipient", recipient⟩, ⟨"property", property⟩]⟩
def baseQualification : Qualification :=
  ⟨⟨"synthetic.predicate", "qualified"⟩, 1, [payer], true, ⟨"synthetic.source", "mention-1"⟩⟩
def baseSnapshot : Snapshot := ⟨1, 1, 1, 1, 1, 1, 1, ⟨"clock", "test"⟩, 10, 20⟩
def baseEnvelope : Envelope :=
  ⟨baseDefinition.key, baseDigest, 1, [baseQualification], baseSnapshot, baseAction⟩

def otherDefinition : Definition :=
  { baseDefinition with key := { baseDefinition.key with symbol := ⟨"synthetic.act", "other"⟩ } }

def registryCase (n : Nat) : Registry :=
  let d := baseDefinition
  let defs := match n with
    | 0 => [d]
    | 1 => []
    | 2 => [d, d]
    | 3 => [d, { d with digest := List.replicate 32 2 }]
    | 4 => [d, { d with roles := d.roles.reverse }]
    | 5 => [d, otherDefinition, otherDefinition]
    | 6 => [{ d with roles := [⟨"payer", some .person⟩, ⟨"recipient", some .person⟩, ⟨"property", none⟩] }]
    | 7 => [{ d with digest := List.replicate 31 0 }]
    | 8 => [{ d with roles := [⟨"payer", some .person⟩, ⟨"recipient", some .person⟩, ⟨"payer", some .asset⟩] }]
    | 9 => [{ d with roles := [⟨"payer", some .person⟩, ⟨"recipient", some .person⟩, ⟨"", some .asset⟩] }]
    | 10 => [{ d with key := { d.key with symbol := ⟨"", "transfer"⟩ } }]
    | 11 => [d, otherDefinition]
    | 12 => [{ d with key := { d.key with version := 0 } }]
    | 13 => [d, { d with key := { d.key with version := 2 }, digest := List.replicate 32 2 }]
    | _ => []
  ⟨1, defs⟩

def withQualification (f : Qualification → Qualification) : Envelope :=
  { baseEnvelope with qualifications := [f baseQualification] }
def withContext (f : Snapshot → Snapshot) : Envelope := { baseEnvelope with context := f baseSnapshot }
def withAction (f : Action → Action) : Envelope := { baseEnvelope with action := f baseAction }

def envelopeCase (n : Nat) : Envelope :=
  match n with
  | 0 => baseEnvelope
  | 1 => { baseEnvelope with key := { baseDefinition.key with version := 2 } }
  | 2 => { baseEnvelope with key := { baseDefinition.key with symbol := ⟨"synthetic.act", "unknown"⟩ } }
  | 3 => { baseEnvelope with definitionDigest := List.replicate 32 2 }
  | 4 => { baseEnvelope with registrySnapshot := 2 }
  | 5 => withAction fun a => { a with operation := { a.operation with symbol := ⟨"synthetic.act", "renamed"⟩ } }
  | 6 => withAction fun a => { a with operation := { a.operation with parameters := a.operation.parameters.reverse } }
  | 7 => withAction fun a => { a with operands := a.operands.reverse }
  | 8 => withAction fun a => { a with operands := [⟨"payer", payer⟩, ⟨"recipient", recipient⟩, ⟨"property", { property with kind := .obligation }⟩] }
  | 9 => withAction fun a => { a with operands := [⟨"payer", recipient⟩, ⟨"recipient", payer⟩, ⟨"property", property⟩] }
  | 10 => withQualification fun q => { q with polarity := false }
  | 11 => withQualification fun q => { q with version := 2 }
  | 12 => withQualification fun q => { q with arguments := [recipient] }
  | 13 => withQualification fun q => { q with mention := ⟨"synthetic.source", "mention-2"⟩ }
  | 14 => withContext fun c => { c with evidenceRevision := 2 }
  | 15 => withContext fun c => { c with clock := ⟨"clock", "other"⟩ }
  | 16 => withContext fun c => { c with effectiveAt := 11 }
  | 17 => withContext fun c => { c with recordedAt := 21 }
  | 18 => withContext fun c => { c with contextId := 2 }
  | 19 => withContext fun c => { c with timeId := 2 }
  | 20 => withContext fun c => { c with profile := 2 }
  | 21 => withContext fun c => { c with profileVersion := 2 }
  | 22 => withContext fun c => { c with interpretationId := 2 }
  | 23 => withContext fun c => { c with interpretationVersion := 2 }
  | 24 => withAction fun a => { a with operands := [⟨"payer", payer⟩, ⟨"recipient", recipient⟩, ⟨"property", { property with symbol := ⟨"asset", ""⟩ }⟩] }
  | 25 => withQualification fun q => { q with mention := ⟨"synthetic.source", ""⟩ }
  | 26 => withQualification fun q => { q with version := 0 }
  | 27 => withContext fun c => { c with clock := ⟨"clock", ""⟩ }
  | 28 => withContext fun c => { c with profileVersion := 0 }
  | 29 => { baseEnvelope with key := { baseDefinition.key with version := 0 } }
  | 30 => withQualification fun q => { q with predicate := ⟨"synthetic.predicate", ""⟩ }
  | 31 => withQualification fun q => { q with arguments := [⟨.person, ⟨"person", ""⟩⟩] }
  | 32 => withContext fun c => { c with interpretationVersion := 0 }
  | 33 => withAction fun a => { a with operands := [⟨"payer", payer⟩, ⟨"recipient", recipient⟩, ⟨"other", property⟩] }
  | 34 => { baseEnvelope with qualifications := [] }
  | 35 => withAction fun a => { a with operands := [] }
  | _ => baseEnvelope

def structuralCode (r e : Nat) : Nat := resolveCode (registryCase r) (envelopeCase e)

/-- Independent priority oracle, stated over the fixture selectors. -/
def expectedStructural (r e : Nat) : Nat :=
  if r ∈ [2, 3, 4, 5] then 1
  else if r ∈ [7, 8, 9, 10, 12] then 2
  else if e = 4 then 3
  else if r = 1 then 4
  else if e ∈ [2, 29] then 4
  else if e = 1 then if r = 13 then 5 else 4
  else if e = 3 then 5
  else if r = 6 then 6
  else if e ∈ [5, 6] then 7
  else if e ∈ [7, 8, 33, 35] then 8
  else if e ∈ [24, 25, 26, 27, 28, 30, 31, 32] then 9
  else 0

def premiseFor (id : Nat) (e : Envelope) : Derivation.Premise :=
  IDADerivation.changeScope (IDADerivation.P 1 34 id) fun s => { s with target := project e }
def basePremise : Derivation.Premise := premiseFor 1 baseEnvelope
def baseBinding : Binding := ⟨baseEnvelope, basePremise⟩

/-- This fixture explicitly issues a new trusted authority. Production `admit`
does not construct authority from its request. -/
def renewedPremise (e : Envelope) : Derivation.Premise :=
  let p := premiseFor 1 e
  let c := e.context
  IDADerivation.changeRecord p fun r =>
    { r with
      scope := { r.scope with
        context := c.contextId
        time := c.timeId
        profile := c.profile
        profileVersion := c.profileVersion }
      provenance := { r.provenance with
        interpretationId := c.interpretationId
        interpretationVersion := c.interpretationVersion } }

def sourceEnvironment (s : Nat) (p : Derivation.Premise) : Derivation.Environment :=
  let env := IDADerivation.E [p]
  match s with
  | 1 => IDADerivation.setStatus env p.request.entryId .candidate
  | 2 => IDADerivation.setStatus env p.request.entryId .quarantined
  | 3 => IDADerivation.setStatus env p.request.entryId .revoked
  | 4 => { env with authenticatedSources := [] }
  | 5 => { env with currentVersions := env.currentVersions.map fun v =>
      { v with interpretationVersion := v.interpretationVersion + 1 } }
  | 6 => { env with evidence := [] }
  | 7 => { env with evidence := [⟨p, .disputed⟩] }
  | 8 => { env with evidence := env.evidence ++ env.evidence }
  | 9 => { env with implementationRevision := "" }
  | 10 => { env with registry := { env.registry with entries := env.registry.entries ++ env.registry.entries } }
  | 11 => { env with registry := { env.registry with entries := env.registry.entries.map fun entry =>
      { entry with record := { entry.record with provenance := { entry.record.provenance with
        source := { entry.record.provenance.source with sourceHash := List.replicate 32 1 } } } } } }
  | _ => env

def boundFixture (e b s : Nat) : Authority × Request :=
  let envelope := envelopeCase e
  let p := if b = 6 then renewedPremise envelope else basePremise
  let other : Binding := ⟨baseEnvelope, premiseFor 2 baseEnvelope⟩
  let bindings := match b with
    | 0 => [baseBinding]
    | 1 => []
    | 2 => [baseBinding, baseBinding]
    | 3 => [baseBinding, ⟨envelopeCase 10, basePremise⟩]
    | 4 => [baseBinding, other, other]
    | 5 => [⟨envelope, basePremise⟩]
    | 6 => [⟨envelope, p⟩]
    | 7 => [⟨baseEnvelope, IDADerivation.changeSource basePremise fun source =>
        { source with sourceHash := List.replicate 32 1 }⟩]
    | 8 => [baseBinding, other]
    | 9 => [⟨envelopeCase 10, basePremise⟩]
    | _ => []
  (⟨baseRegistry, bindings, sourceEnvironment s p⟩, ⟨envelope, p⟩)

def boundCode (e b s : Nat) : Nat :=
  let (a, q) := boundFixture e b s
  resultCode (admit a q)
def boundBaseIssue (e b s : Nat) : Nat :=
  let (a, q) := boundFixture e b s
  baseIssueCode a q

def expectedBound (e b s : Nat) : Nat :=
  if expectedStructural 0 e ≠ 0 then expectedStructural 0 e
  else if b ∈ [2, 3, 4] then 10
  else if b = 1 then 11
  else if b ∈ [0, 7, 8] ∧ e ≠ 0 then 12
  else if b = 9 ∧ e ≠ 10 then 12
  else if b = 7 then 13
  else if b = 5 ∧ e = 9 then 14
  else if b = 5 ∧ e ∈ [18, 19, 20, 21, 22, 23] then 16
  else if s ≠ 0 then 15
  else 0

def expectedBaseIssue (s : Nat) : Nat :=
  match s with
  | 0 => 0 | 1 | 2 | 3 => 7 | 4 => 10 | 5 => 11
  | 6 => 13 | 7 => 16 | 8 => 14 | 9 => 24 | 10 => 6 | 11 => 8 | _ => 0

set_option maxRecDepth 8192 in
set_option maxHeartbeats 0 in
theorem structural_matrix : ∀ r : Fin 14, ∀ e : Fin 36,
    structuralCode r.val e.val = expectedStructural r.val e.val := by decide

set_option maxRecDepth 8192 in
set_option maxHeartbeats 0 in
theorem bound_guard_matrix : ∀ e : Fin 36, ∀ b : Fin 10,
    boundCode e.val b.val 0 = expectedBound e.val b.val 0 := by decide

set_option maxRecDepth 8192 in
set_option maxHeartbeats 0 in
theorem actual_source_matrix : ∀ s : Fin 12,
    boundCode 0 0 s.val = (if s.val = 0 then 0 else 15) ∧
    boundBaseIssue 0 0 s.val = expectedBaseIssue s.val := by decide

theorem same_target_changed_qualification :
    project (envelopeCase 0) = project (envelopeCase 10) ∧
    boundCode 10 0 0 = 12 ∧ boundCode 10 5 0 = 0 := by decide

theorem wrong_target_independently_blocked : boundCode 9 5 0 = 14 := by decide

set_option maxRecDepth 8192 in
theorem snapshot_coordinates_independently_blocked : ∀ i : Fin 6,
    boundCode (18 + i.val) 5 0 = 16 ∧ boundCode (18 + i.val) 6 0 = 0 := by decide

theorem candidate_structurally_checked_but_not_admitted :
    resolveCode baseRegistry baseEnvelope = 0 ∧
    boundCode 0 0 1 = 15 ∧ boundBaseIssue 0 0 1 = 7 := by decide

theorem unresolved_ne_unknown :
    structuralCode 6 0 = 6 ∧ structuralCode 1 0 = 4 := by decide

theorem projection_is_lossy :
    envelopeCase 0 ≠ envelopeCase 10 ∧ project (envelopeCase 0) = project (envelopeCase 10) := by decide

/-- Isolate exact binding from earlier resolver checks. Pin changes here are
synthetic supplied data; the host's canonical-hash gate remains independent. -/
def omittedMetadataFixture (n : Nat) : Authority × Request :=
  let changed := match n with
    | 0 => { baseDefinition with key := { baseDefinition.key with version := 2 } }
    | 1 => { baseDefinition with digest := List.replicate 32 2 }
    | _ => baseDefinition
  let registry : Registry := ⟨if n = 2 then 2 else 1, [changed]⟩
  let e := { baseEnvelope with
    key := changed.key
    definitionDigest := changed.digest
    registrySnapshot := registry.snapshot }
  (⟨registry, [baseBinding], IDADerivation.E [basePremise]⟩, ⟨e, basePremise⟩)

theorem omitted_metadata_independently_blocked : ∀ n : Fin 3,
    let (a, q) := omittedMetadataFixture n.val
    resolveCode a.registry q.envelope = 0 ∧ project q.envelope = project baseEnvelope ∧
      resultCode (admit a q) = 12 := by decide

def twoSourceFixture : Authority × List Request :=
  let p := basePremise
  let q := IDADerivation.changeProvenance (premiseFor 2 baseEnvelope) fun provenance =>
    { provenance with interpretationId := 1 }
  let env := IDADerivation.E [p, q]
  let shared := { env with currentVersions := [Derivation.expectedVersion p] }
  (⟨baseRegistry, [⟨baseEnvelope, p⟩, ⟨baseEnvelope, q⟩], shared⟩,
    [⟨baseEnvelope, p⟩, ⟨baseEnvelope, q⟩])

theorem independent_sources_share_envelope :
    twoSourceFixture.2.map (fun q => resultCode (admit twoSourceFixture.1 q)) = [0, 0] := by decide

def wireCases : List Bool :=
  [decodeDefinition (encodeDefinition baseDefinition) == some baseDefinition,
   decodeEnvelope (encodeEnvelope baseEnvelope) == some baseEnvelope,
   decodeRole ⟨"mandate", none⟩ == some ⟨"mandate", none⟩,
   decodeRole ⟨"mandate", some "mandate"⟩ == none,
   decodeRef ⟨"mandate", ⟨"relation", "m1"⟩⟩ == none]

theorem wire_negative_controls : wireCases = [true, true, true, true, true] := by decide

end UsulTest.IDAActRegistry
