import Usul.Typing.IDADerivation

/-!
# Synthetic source-bound derivation adversaries

The only source bytes are the artificial ASCII files `IDA\n` and `IDB\n`.
Nothing in these examples is a legal interpretation or an actual admission.
The fixture vocabulary and finite domains are shared with the independent Quint
replay; the semantic implementation is not generated from that replay.
-/

namespace UsulTest.IDADerivation

open Usul Usul.IDA Usul.IDA.Derivation

def syntheticSource (i : Nat) : Judgment.SourceRef :=
  if i = 1 then
    { sourceId := 1
      sourceHash := [186,29,212,220,231,84,88,79,207,141,146,254,115,4,103,238,
        6,112,140,192,4,251,252,68,37,94,197,6,229,77,11,90]
      sourceBytes := 4, passageStart := 1, passageEnd := 3
      passageHash := [65,165,86,179,131,19,10,60,154,253,106,235,174,55,83,203,
        233,237,227,132,205,125,78,197,92,180,180,31,175,219,49,5] }
  else
    { sourceId := 2
      sourceHash := [15,1,238,239,235,128,119,75,25,217,36,106,154,23,175,166,
        163,180,228,198,32,60,70,245,81,18,23,166,136,3,230,222]
      sourceBytes := 4, passageStart := 1, passageEnd := 3
      passageHash := [207,58,188,131,38,100,107,153,10,73,22,170,34,235,191,13,
        208,89,233,123,250,27,82,242,175,170,149,135,191,14,196,77] }

def sourceCells (i : Nat) : List Nat :=
  let s := syntheticSource i
  [s.sourceId] ++ s.sourceHash ++ [s.sourceBytes, s.passageStart, s.passageEnd] ++
    s.passageHash

def P (q a i : Nat) : Premise :=
  let raw := Judgment.syntheticBaseline q
  let provenance := { raw.provenance with
    source := syntheticSource (if i % 2 = 1 then 1 else 2), interpretationId := i }
  let record := { raw with answerCode := a, provenance := provenance }
  ⟨7, ⟨1, i, record⟩⟩

def E (ps : List Premise) : Environment :=
  { registry := ⟨1, ps.map fun p => ⟨p.request.entryId, .admitted, p.request.record⟩⟩
    authenticatedSources := ps.map fun p => p.request.record.provenance.source
    currentVersions := ps.map expectedVersion
    evidence := ps.map fun p => ⟨p, .supported⟩
    implementationRevision := "derivation-v1" }

def A (q : Nat) : Nat := if q = 0 then 16 else if q < 4 then 34 else 36

def B (q k : Nat) : Nat :=
  if k = 0 then 0 else if k = 1 then 32 else
    if q = 4 then if k = 2 then 35 else 36 else if k = 2 then 33 else 34

def changeRecord (p : Premise) (f : Judgment.RawRecord → Judgment.RawRecord) : Premise :=
  { p with request := { p.request with record := f p.request.record } }

def changeProvenance (p : Premise) (f : Judgment.Provenance → Judgment.Provenance) : Premise :=
  changeRecord p fun r => { r with provenance := f r.provenance }

def changeSource (p : Premise) (f : Judgment.SourceRef → Judgment.SourceRef) : Premise :=
  changeProvenance p fun r => { r with source := f r.source }

def changeScope (p : Premise) (f : Judgment.Scope → Judgment.Scope) : Premise :=
  changeRecord p fun r => { r with scope := f r.scope }

def setStatus (env : Environment) (i : Nat) (status : Judgment.Status) : Environment :=
  { env with registry := { env.registry with entries := env.registry.entries.map (fun e => if e.entryId = i then { e with status := status } else e) } }

def setEvidence (env : Environment) (i : Nat) (classification : EvidenceClass) : Environment :=
  { env with evidence := env.evidence.map fun e =>
      if e.premise.request.entryId = i then { e with classification := classification } else e }

def leafFixture (q variant : Nat) : Environment × Tree :=
  let p := P q (A q) 1
  let env := E [p]
  let singleton := fun p => (E [p], Tree.source p)
  match variant with
  | 1 => (setStatus env 1 .candidate, .source p)
  | 2 => (setStatus env 1 .quarantined, .source p)
  | 3 => (setStatus env 1 .revoked, .source p)
  | 4 => ({ env with authenticatedSources := [] }, .source p)
  | 5 => ({ env with authenticatedSources := env.authenticatedSources.map fun s => { s with sourceHash := List.replicate 32 0 } }, .source p)
  | 6 => ({ env with authenticatedSources := env.authenticatedSources.map fun s => { s with passageStart := 2 } }, .source p)
  | 7 => ({ env with authenticatedSources := env.authenticatedSources.map fun s => { s with passageHash := List.replicate 32 0 } }, .source p)
  | 8 => ({ env with currentVersions := [] }, .source p)
  | 9 => ({ env with currentVersions := env.currentVersions.map fun v => { v with profileVersion := 2 } }, .source p)
  | 10 => ({ env with currentVersions := env.currentVersions.map fun v => { v with interpretationVersion := 2 } }, .source p)
  | 11 => ({ env with currentVersions := env.currentVersions ++ env.currentVersions }, .source p)
  | 12 => ({ env with currentVersions := env.currentVersions ++
      env.currentVersions.map fun v => { v with interpretationVersion := 2 } }, .source p)
  | 13 => ({ env with evidence := [] }, .source p)
  | 14 => ({ env with evidence := env.evidence ++ env.evidence }, .source p)
  | 15 => ({ env with evidence := env.evidence ++
      env.evidence.map fun e => { e with classification := .disputed } }, .source p)
  | 16 => (setEvidence env 1 .disputed, .source p)
  | 17 => (setEvidence env 1 .missing, .source p)
  | 18 => (setEvidence env 1 .suspended, .source p)
  | 19 => (setEvidence env 1 .unauthenticated, .source p)
  | 20 => ({ env with evidence := env.evidence.map (fun e => { e with premise := { e.premise with questionId := 8 } }) }, .source p)
  | 21 => singleton (changeRecord p fun r => { r with answerCode := 0 })
  | 22 => singleton (changeRecord p fun r => { r with answerCode := 32 })
  | 23 => singleton (changeProvenance p fun r => { r with premises := [2] })
  | 24 => singleton (changeProvenance p fun r => { r with ruleId := 2 })
  | 25 => ({ env with implementationRevision := "" }, .source p)
  | 26 => (env, .source { p with request := { p.request with snapshot := 2 } })
  | 27 => (env, .source (changeSource p fun s => { s with sourceHash := List.replicate 32 0 }))
  | 28 => (env, .source (changeSource p fun s => { s with passageStart := 2 }))
  | 29 => (env, .source (changeProvenance p fun r => { r with interpretationVersion := 2 }))
  | 30 => (env, .source (changeProvenance p fun r => { r with grade := .zann }))
  | 31 => ({ env with evidence := env.evidence.map fun e =>
      { e with premise := changeProvenance e.premise fun r => { r with grade := .zann } } }, .source p)
  | _ => (env, .source p)

def leafEval (q variant : Nat) : Evaluation :=
  let (env, tree) := leafFixture q variant
  evaluate env tree

def pairFixture (q a b : Nat) : Environment × Tree :=
  let l := P q a 1
  let r := P q b 2
  (E [l, r], .both (.source l) (.source r))

def pairEval (q a b : Nat) : Evaluation :=
  let (env, tree) := pairFixture q a b
  evaluate env tree

def scopeFixture (variant : Nat) : Environment × Tree :=
  let l := P 1 34 1
  let r := P 1 34 2
  let right := match variant with
    | 1 => { r with questionId := 8 }
    | 2 => changeRecord r fun raw => { raw with questionCode := 2 }
    | 3 => changeScope r fun s => { s with subjectId := 2 }
    | 4 => changeScope r fun s => { s with subject := { s.subject with baligh := false } }
    | 5 => changeScope r fun s => { s with subject := { s.subject with aqil := false } }
    | 6 => changeScope r fun s => { s with target := .legacy 2 .behavior }
    | 7 => changeScope r fun s => { s with target := .legacy 1 .affect }
    | 8 => changeScope r fun s => { s with context := 2 }
    | 9 => changeScope r fun s => { s with time := 2 }
    | 10 => changeScope r fun s => { s with profile := 2 }
    | 11 => changeScope r fun s => { s with profileVersion := 2 }
    | 12 => changeScope r fun s => { s with domain := .ibada }
    | _ => r
  (E [l, right], .both (.source l) (.source right))

def scopeEval (variant : Nat) : Evaluation :=
  let (env, tree) := scopeFixture variant
  evaluate env tree

def withTarget (p : Premise) (target : Judgment.ScopeTarget) : Premise :=
  changeScope p fun s => { s with target }

private theorem target_fixture_exists : ∀ code : Fin 28,
    (TargetFixtures.expression code.val).isSome := by decide

def structuredPremise (i : Nat) (code : Fin 28) : Premise :=
  let expression := (TargetFixtures.expression code.val).get (target_fixture_exists code)
  withTarget (P 1 34 i) (.structured expression)

def targetFixture (variant : Nat) : Environment × Tree :=
  let l := structuredPremise 1 (if variant = 2 ∨ variant = 3 then 8
    else if variant = 4 ∨ variant = 5 then 14 else if variant = 7 then 21 else 0)
  let r := match variant with
    | 0 => structuredPremise 2 1
    | 1 => structuredPremise 2 6
    | 2 => structuredPremise 2 8
    | 3 => structuredPremise 2 10
    | 4 => structuredPremise 2 14
    | 5 => structuredPremise 2 17
    | 6 => P 1 34 2
    | 7 => structuredPremise 2 21
    | _ => structuredPremise 2 0
  let env := E [l, r]
  let legacy := P 1 34 2
  let env := match variant with
    | 8 => { env with currentVersions := [expectedVersion l,
        { expectedVersion r with interpretationVersion := 2 }] }
    | 9 =>
      let source := r.request.record.provenance.source
      { env with authenticatedSources := [l.request.record.provenance.source,
          { source with passageStart := 2 }] }
    | 10 => { env with registry := (E [l, legacy]).registry }
    | 11 => { env with evidence := (E [l, legacy]).evidence }
    | 12 => setStatus env 2 .candidate
    | _ => env
  (env, .both (.source l) (.source r))

def targetEval (variant : Nat) : Evaluation :=
  let (env, tree) := targetFixture variant
  evaluate env tree

def targetReplay (variant : Nat) : Bool :=
  let (env, tree) := targetFixture 0
  let r := receipt env tree
  let legacy : Judgment.ScopeTarget := .legacy 1 .behavior
  match variant with
  | 1 =>
    let conclusion := r.result.conclusion.map fun c =>
      { c with scope := { c.scope with target := legacy } }
    verifyReceipt env { r with result := { r.result with conclusion } }
  | 2 => verifyReceipt { env with registry := (E [structuredPremise 1 0, P 1 34 2]).registry } r
  | _ => verifyReceipt env r

def treeFixture (variant shape : Nat) : Environment × Tree :=
  let p1 := P 0 31 1
  let p2 := P 0 16 2
  let p3 := P 0 16 3
  let p2 := if variant = 1 then changeRecord p2 fun r => { r with answerCode := 0 }
    else if variant = 2 then changeRecord p2 fun r => { r with answerCode := 32 }
    else if variant = 7 then { p2 with questionId := 8 }
    else if variant = 8 then changeRecord p2 fun r => { r with answerCode := 1 }
    else p2
  let env := E [p1, p2, p3]
  let env := match variant with
    | 3 => setStatus env 2 .candidate
    | 4 => setEvidence env 2 .disputed
    | 5 => { env with authenticatedSources :=   env.authenticatedSources.filter fun s => s.sourceId != 2 }
    | 6 => { env with currentVersions := env.currentVersions.map fun v =>
        if v.interpretationId = 2 then { v with interpretationVersion := 2 } else v }
    | 9 => setEvidence env 2 .missing
    | _ => env
  let left := Tree.both (.source p1) (.source p2)
  let right := Tree.both (.source p2) (.source p3)
  let tree := if shape = 0 then Tree.both left (.source p3)
    else if shape = 1 then Tree.both (.source p1) right else Tree.both left right
  (env, tree)

def treeEval (variant shape : Nat) : Evaluation :=
  let (env, tree) := treeFixture variant shape
  evaluate env tree

def alternativesFixture (scenario : Nat) : Environment × List Tree :=
  let p1 := P 0 1 1
  let p2 := P 0 16 2
  let env := E [p1, p2]
  (if scenario = 1 then setStatus env 2 .candidate else env,
    [.source p1, .source p2])

def alternativeEval (scenario index : Nat) : Evaluation :=
  let (env, trees) := alternativesFixture scenario
  ((alternatives env trees)[index]?).getD (blocked [.malformedProgram] [])

def replayFixture (variant : Nat) : Environment × Receipt :=
  let (env, tree) := pairFixture 0 31 16
  let r := receipt env tree
  match variant with
  | 1 => ({ env with implementationRevision := "derivation-v2" }, r)
  | 2 => ({ env with registry := { env.registry with snapshot := 2 } }, r)
  | 3 => ({ env with authenticatedSources := [] }, r)
  | 4 => ({ env with currentVersions := env.currentVersions.map fun v =>
      if v.interpretationId = 2 then { v with interpretationVersion := 2 } else v }, r)
  | 5 => (setEvidence env 2 .disputed, r)
  | 6 => (setStatus env 2 .candidate, r)
  | 7 =>
    let forged : KnownConclusion := ⟨7, .taklifi, Constraint.singleton .haram,
      (P 0 31 1).request.record.scope⟩
    (env, { r with result := { r.result with conclusion := some forged } })
  | 8 => (env, { r with result := { r.result with provenance := [P 0 31 1] } })
  | 9 => (env, { r with result := { r.result with conclusion := r.result.conclusion.map fun c => { c with scope := { c.scope with context := 2 } } } })
  | 10 => (env, { r with environment := { r.environment with implementationRevision := "derivation-v2" } })
  | 11 => (env, { r with tree := .source (P 0 31 1) })
  | 12 => (env, { r with result := { r.result with conclusion := r.result.conclusion.map fun c => { c with questionId := 8 } } })
  | 13 => (env, { r with result := { r.result with issues := [.missingRuling] } })
  | 14 => (env, { r with result := { r.result with conclusion := none } })
  | 15 => (env, { r with environment := { r.environment with evidence := r.environment.evidence.filter fun e => e.premise.request.entryId != 2 } })
  | _ => (env, r)

def replayValue (variant : Nat) : Nat :=
  let (env, r) := replayFixture variant
  if verifyReceipt env r then 1 else 0

def primaryCode (e : Evaluation) : Nat :=
  if e.isAccepted then 0 else match e.issues with
    | [] => 23
    | issue :: _ => issueCode issue

def projection (e : Evaluation) : Nat → Nat
  | 0 => primaryCode e
  | 1 => if e.classification = .admitted then 1 else 0
  | 2 => e.conclusion.map (fun c => c.questionId + 1) |>.getD 0
  | 3 => e.conclusion.map (fun c => Judgment.encodeQuestion c.question + 1) |>.getD 0
  | 4 => e.conclusion.map (fun c => Judgment.encodeKnown c.question c.answer + 1) |>.getD 0
  | 5 => e.provenance.length
  | 6 => e.issues.foldl (fun acc i => acc * 32 + issueCode i) 0
  | 7 => e.provenance.foldl (fun acc p => acc * 16 + p.request.entryId) 0
  | _ => 0

/-! The following expected outputs are fixed from the textual contract. -/

def expectedLeafCode (variant : Nat) : Nat :=
  ([0,7,7,7,10,10,10,10,11,11,11,12,12,13,14,14,
    16,13,17,18,15,19,20,9,9,24,4,8,8,8,8,15] : List Nat)[variant]?.getD 23

def expectedKnown (q a : Nat) : Option KnownConclusion := do
  let question ← Judgment.decodeQuestion q
  let answer ← Judgment.decodeKnown question a
  pure ⟨7, question, answer, (Judgment.syntheticBaseline 0).scope⟩

def expectedPayloadIssue (a : Nat) : List Issue :=
  if a = 0 then [.missingRuling] else if a = 32 then [.suspendedRuling] else []

def expectedPair (q a b : Nat) : Evaluation :=
  let sources := [P q a 1, P q b 2]
  let issues := expectedPayloadIssue a ++ expectedPayloadIssue b
  if issues ≠ [] then ⟨none, issues, sources⟩
  else if q = 0 then
    let mask := Nat.land a b
    if mask = 0 then ⟨none, [.conflictingAnswers], sources⟩
    else ⟨expectedKnown q mask, [], sources⟩
  else if a = b then ⟨expectedKnown q a, [], sources⟩
  else ⟨none, [.conflictingAnswers], sources⟩

def expectedTreeIssues (variant shape : Nat) : List Issue :=
  if variant = 0 then []
  else if variant = 7 then List.replicate (if shape = 2 then 3 else 2) .outOfScope
  else if variant = 8 then [.conflictingAnswers]
  else
    let issue := match variant with
      | 1 => Issue.missingRuling
      | 2 => .suspendedRuling
      | 3 => .registryRejected .notAdmitted
      | 4 => .disputedEvidence
      | 5 => .sourceUnauthenticated
      | 6 => .staleInterpretation
      | _ => .missingEvidence
    List.replicate (if shape = 2 then 2 else 1) issue

set_option maxRecDepth 8192
set_option maxHeartbeats 10000000

theorem source_catalog_shapes :
    ∀ i : Fin 2, (syntheticSource (i.val + 1)).WellFormed ∧
      (sourceCells (i.val + 1)).length = 68 := by decide

theorem leaf_guard_matrix :
    ∀ (q : Fin 5) (v : Fin 32), primaryCode (leafEval q.val v.val) = expectedLeafCode v.val := by
  decide

theorem source_full_values :
    ∀ q : Fin 5, leafEval q.val 0 =
      ⟨expectedKnown q.val (A q.val), [], [P q.val (A q.val) 1]⟩ := by decide

theorem taklifi_full_values :
    ∀ (a b : Fin 33), pairEval 0 a.val b.val = expectedPair 0 a.val b.val := by decide

theorem typed_full_values :
    ∀ (q : Fin 4) (k : Fin 16),
      pairEval (q.val + 1) (B (q.val + 1) (k.val / 4)) (B (q.val + 1) (k.val % 4)) =
      expectedPair (q.val + 1) (B (q.val + 1) (k.val / 4)) (B (q.val + 1) (k.val % 4)) := by
  decide

theorem scope_guard_matrix :
    ∀ v : Fin 13, (scopeEval v.val).issues = (if v.val = 0 then [] else [.outOfScope]) ∧
      (scopeEval v.val).provenance = (scopeFixture v.val).2.leaves := by decide

theorem nested_blocker_matrix :
    ∀ (v : Fin 10) (shape : Fin 3),
      (treeEval v.val shape.val).issues = expectedTreeIssues v.val shape.val ∧
      (treeEval v.val shape.val).provenance = (treeFixture v.val shape.val).2.leaves := by decide

theorem alternatives_unselected :
    alternativeEval 0 0 = ⟨expectedKnown 0 1, [], [P 0 1 1]⟩ ∧
    alternativeEval 0 1 = ⟨expectedKnown 0 16, [], [P 0 16 2]⟩ ∧
    alternativeEval 1 0 = alternativeEval 0 0 ∧
    alternativeEval 1 1 = ⟨none, [.registryRejected .notAdmitted], [P 0 16 2]⟩ ∧
    pairEval 0 1 16 = ⟨none, [.conflictingAnswers], [P 0 1 1, P 0 16 2]⟩ := by decide

theorem receipt_mutation_matrix :
    ∀ v : Fin 16, replayValue v.val = (if v.val = 0 then 1 else 0) := by decide

theorem forged_admission_rejected :
    let (env, forged) := replayFixture 7
    forged.result.isAccepted = true ∧ verifyReceipt env forged = false := by decide

def expectedTargetIssues : Nat → List Issue
  | 0 | 2 | 4 => []
  | 1 | 3 | 5 | 6 => [.outOfScope]
  | 7 => [.registryRejected .illTyped, .registryRejected .illTyped]
  | 8 => [.staleInterpretation]
  | 9 => [.sourceUnauthenticated]
  | 10 => [.registryRejected .recordMismatch]
  | 11 => [.evidenceMismatch]
  | _ => [.registryRejected .notAdmitted]

theorem structured_target_matrix : ∀ v : Fin 13,
    (targetEval v.val).issues = expectedTargetIssues v.val ∧
    (targetEval v.val).isAccepted = (expectedTargetIssues v.val).isEmpty ∧
    (targetEval v.val).provenance = (targetFixture v.val).2.leaves := by decide

theorem structured_target_replay :
    targetReplay 0 = true ∧ targetReplay 1 = false ∧ targetReplay 2 = false := by decide

end UsulTest.IDADerivation
