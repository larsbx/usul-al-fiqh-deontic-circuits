import Usul.Typing.IDAJudgment

/-!
# Source-bound IDA derivation trees

The environment supplies authority; a submitted premise supplies only an exact
request and its question identity. Authentication below is exact membership in
the supplied catalog, not a theorem about cryptography or juristic correctness.
Every source occurrence survives evaluation, including blocked occurrences.
-/

namespace Usul.IDA.Derivation


structure Premise where
  questionId : Nat
  request : Judgment.Request
  deriving DecidableEq, Repr

structure CurrentVersion where
  profile : Nat
  interpretationId : Nat
  profileVersion : Nat
  interpretationVersion : Nat
  deriving DecidableEq, Repr

inductive EvidenceClass where
  | supported | missing | suspended | disputed | unauthenticated
  deriving DecidableEq, Repr

structure EvidenceDecision where
  premise : Premise
  classification : EvidenceClass
  deriving DecidableEq, Repr

structure Environment where
  registry : Judgment.Registry
  authenticatedSources : List Judgment.SourceRef
  currentVersions : List CurrentVersion
  evidence : List EvidenceDecision
  implementationRevision : String
  deriving DecidableEq, Repr

structure KnownConclusion where
  questionId : Nat
  question : Question
  answer : Judgment.Answer question
  scope : Judgment.Scope
  deriving DecidableEq

inductive Issue where
  | registryRejected (reason : Judgment.Failure)
  | badSourceRule | sourceUnauthenticated | staleInterpretation
  | conflictingVersions | missingEvidence | conflictingEvidence
  | evidenceMismatch | disputedEvidence | suspendedEvidence
  | unauthenticatedEvidence | missingRuling | suspendedRuling
  | outOfScope | conflictingAnswers | malformedProgram | badEnvironment
  deriving DecidableEq, Repr

def issueCode : Issue → Nat
  | .registryRejected f => Judgment.outcomeCode (.rejected f)
  | .badSourceRule => 9
  | .sourceUnauthenticated => 10
  | .staleInterpretation => 11
  | .conflictingVersions => 12
  | .missingEvidence => 13
  | .conflictingEvidence => 14
  | .evidenceMismatch => 15
  | .disputedEvidence => 16
  | .suspendedEvidence => 17
  | .unauthenticatedEvidence => 18
  | .missingRuling => 19
  | .suspendedRuling => 20
  | .outOfScope => 21
  | .conflictingAnswers => 22
  | .malformedProgram => 23
  | .badEnvironment => 24

structure Evaluation where
  conclusion : Option KnownConclusion
  issues : List Issue
  provenance : List Premise
  deriving DecidableEq

def Evaluation.Accepted (e : Evaluation) : Prop :=
  ∃ c, e.conclusion = some c ∧ e.issues = []

def blocked (issues : List Issue) (sources : List Premise) : Evaluation :=
  ⟨none, issues, sources⟩

def known (c : KnownConclusion) (sources : List Premise) : Evaluation :=
  ⟨some c, [], sources⟩

def Evaluation.isAccepted (e : Evaluation) : Bool :=
  e.conclusion.isSome && e.issues.isEmpty

theorem isAccepted_iff (e : Evaluation) : e.isAccepted = true ↔ e.Accepted := by
  cases hc : e.conclusion <;> simp [Evaluation.isAccepted, Evaluation.Accepted, hc]

instance (e : Evaluation) : Decidable e.Accepted :=
  decidable_of_iff (e.isAccepted = true) (isAccepted_iff e)

/-- Admission here is relative to the supplied environment, not a legal judgment. -/
def Evaluation.classification (e : Evaluation) : Judgment.Status :=
  if e.isAccepted then .admitted else .candidate

def expectedVersion (p : Premise) : CurrentVersion :=
  ⟨p.request.record.scope.profile, p.request.record.provenance.interpretationId,
   p.request.record.scope.profileVersion,
   p.request.record.provenance.interpretationVersion⟩

def matchingVersions (env : Environment) (p : Premise) : List CurrentVersion :=
  env.currentVersions.filter fun v =>
    v.profile == p.request.record.scope.profile &&
    v.interpretationId == p.request.record.provenance.interpretationId

def matchingEvidence (env : Environment) (p : Premise) : List EvidenceDecision :=
  env.evidence.filter fun e => e.premise.request.entryId == p.request.entryId

def versionIssue (env : Environment) (p : Premise) : Option Issue :=
  match matchingVersions env p with
  | [] => some .staleInterpretation
  | [v] => if v = expectedVersion p then none else some .staleInterpretation
  | _ :: _ :: _ => some .conflictingVersions

def evidenceIssue (env : Environment) (p : Premise) : Option Issue :=
  match matchingEvidence env p with
  | [] => some .missingEvidence
  | [e] =>
    if e.premise ≠ p then some .evidenceMismatch
    else match e.classification with
      | .supported => none
      | .missing => some .missingEvidence
      | .suspended => some .suspendedEvidence
      | .disputed => some .disputedEvidence
      | .unauthenticated => some .unauthenticatedEvidence
  | _ :: _ :: _ => some .conflictingEvidence

def SourceRule (p : Premise) : Prop :=
  p.request.record.provenance.ruleId = 1 ∧
  p.request.record.provenance.premises = []

instance (p : Premise) : Decidable (SourceRule p) := by
  unfold SourceRule
  infer_instance

def authorize (env : Environment) (p : Premise) : Except Issue Judgment.Receipt :=
  if env.implementationRevision = "" then .error .badEnvironment
  else match Judgment.validate env.registry p.request with
    | .rejected reason => .error (.registryRejected reason)
    | .accepted receipt =>
      if ¬ SourceRule p then .error .badSourceRule
      else if p.request.record.provenance.source ∉ env.authenticatedSources then
        .error .sourceUnauthenticated
      else match versionIssue env p with
        | some issue => .error issue
        | none => match evidenceIssue env p with
          | some issue => .error issue
          | none => .ok receipt

def evaluateSource (env : Environment) (p : Premise) : Evaluation :=
  match authorize env p with
  | .error issue => blocked [issue] [p]
  | .ok receipt => match receipt.record.payload with
    | .noRuling => blocked [.missingRuling] [p]
    | .suspended => blocked [.suspendedRuling] [p]
    | .known answer =>
      known ⟨p.questionId, receipt.record.question, answer, receipt.record.scope⟩ [p]

structure ScopeKey where
  questionId : Nat
  questionCode : Nat
  scope : Judgment.Scope
  deriving DecidableEq, Repr

def Premise.key (p : Premise) : ScopeKey :=
  ⟨p.questionId, p.request.record.questionCode, p.request.record.scope⟩

def KnownConclusion.key (c : KnownConclusion) : ScopeKey :=
  ⟨c.questionId, Judgment.encodeQuestion c.question, c.scope⟩

def Homogeneous : List Premise → Prop
  | [] => False
  | p :: ps => ∀ q ∈ ps, q.key = p.key

instance (ps : List Premise) : Decidable (Homogeneous ps) := by
  cases ps <;> unfold Homogeneous <;> infer_instance

/-- Known answers meet only inside a single typed question family. -/
def intersectAnswers : (q : Question) → Judgment.Answer q → Judgment.Answer q → Option (Judgment.Answer q)
  | .taklifi, a, b => match IDA.intersectKnown a b with
    | .known c => some c
    | _ => none
  | .wadi _, a, b => if a = b then some a else none

def combineConclusions (left right : KnownConclusion) : Option KnownConclusion :=
  if hq : left.question = right.question then
    if left.questionId = right.questionId ∧ left.scope = right.scope then
      (intersectAnswers left.question left.answer (hq ▸ right.answer)).map
        fun answer => ⟨left.questionId, left.question, answer, left.scope⟩
    else none
  else none

def requireBoth (left right : Evaluation) : Evaluation :=
  let sources := left.provenance ++ right.provenance
  let issues := left.issues ++ right.issues
  if ¬ Homogeneous sources then blocked (.outOfScope :: issues) sources
  else if issues ≠ [] then blocked issues sources
  else match left.conclusion, right.conclusion with
    | some a, some b =>
      if a.key ≠ b.key then blocked [.outOfScope] sources
      else match combineConclusions a b with
        | some c => known c sources
        | none => blocked [.conflictingAnswers] sources
    | _, _ => blocked [.malformedProgram] sources

inductive Tree where
  | source (premise : Premise)
  | both (left right : Tree)
  deriving DecidableEq, Repr

def Tree.leaves : Tree → List Premise
  | .source p => [p]
  | .both l r => l.leaves ++ r.leaves

def evaluate (env : Environment) : Tree → Evaluation
  | .source p => evaluateSource env p
  | .both l r => requireBoth (evaluate env l) (evaluate env r)

/-- Ordered alternatives are evaluated separately; no preferred result is chosen. -/
def alternatives (env : Environment) (trees : List Tree) : List Evaluation :=
  trees.map (evaluate env)

/-- Receipts bind the full supplied authority, program, and complete output. -/
structure Receipt where
  environment : Environment
  tree : Tree
  result : Evaluation
  deriving DecidableEq

def receipt (env : Environment) (tree : Tree) : Receipt :=
  ⟨env, tree, evaluate env tree⟩

def replay (current : Environment) (r : Receipt) : Evaluation :=
  evaluate current r.tree

def Receipt.ValidAt (r : Receipt) (current : Environment) : Prop :=
  r.environment = current ∧ r.result = replay current r

instance (r : Receipt) (current : Environment) : Decidable (r.ValidAt current) := by
  unfold Receipt.ValidAt
  infer_instance

def Receipt.AcceptedAt (r : Receipt) (current : Environment) : Prop :=
  r.ValidAt current ∧ r.result.Accepted

instance (r : Receipt) (current : Environment) : Decidable (r.AcceptedAt current) := by
  unfold Receipt.AcceptedAt
  infer_instance

def verifyReceipt (current : Environment) (r : Receipt) : Bool :=
  decide (r.AcceptedAt current)

/-! ## Universal, kernel-checked contracts -/

theorem version_issue_none_iff (env : Environment) (p : Premise) :
    versionIssue env p = none ↔ matchingVersions env p = [expectedVersion p] := by
  cases hm : matchingVersions env p with
  | nil => simp [versionIssue, hm]
  | cons v rest =>
    cases rest with
    | nil => simp [versionIssue, hm]
    | cons w rest => simp [versionIssue, hm]

theorem evidence_issue_none_iff (env : Environment) (p : Premise) :
    evidenceIssue env p = none ↔
      matchingEvidence env p = [⟨p, .supported⟩] := by
  cases hm : matchingEvidence env p with
  | nil => simp [evidenceIssue, hm]
  | cons e rest =>
    cases rest with
    | nil =>
      rcases e with ⟨premise, classification⟩
      cases classification <;> by_cases hp : premise = p <;>
        simp [evidenceIssue, hm, EvidenceDecision.mk.injEq, hp]
    | cons f rest => simp [evidenceIssue, hm]

structure Authority (env : Environment) (p : Premise) (r : Judgment.Receipt) : Prop where
  revision : env.implementationRevision ≠ ""
  registry : Judgment.validate env.registry p.request = .accepted r
  sourceRule : SourceRule p
  authenticated : p.request.record.provenance.source ∈ env.authenticatedSources
  current : matchingVersions env p = [expectedVersion p]
  evidence : matchingEvidence env p = [⟨p, .supported⟩]

theorem authorized_iff (env : Environment) (p : Premise) (r : Judgment.Receipt) :
    authorize env p = .ok r ↔ Authority env p r := by
  constructor
  · intro h
    have hr : env.implementationRevision ≠ "" := by
      intro he
      simp [authorize, he] at h
    cases hv : Judgment.validate env.registry p.request with
    | rejected reason => simp [authorize, hr, hv] at h
    | accepted actual =>
      have hs : SourceRule p := by
        by_cases hs : SourceRule p
        · exact hs
        · simp [authorize, hr, hv, hs] at h
      have ha : p.request.record.provenance.source ∈ env.authenticatedSources := by
        by_cases ha : p.request.record.provenance.source ∈ env.authenticatedSources
        · exact ha
        · simp [authorize, hr, hv, hs, ha] at h
      cases hp : versionIssue env p with
      | some issue => simp [authorize, hr, hv, hs, ha, hp] at h
      | none =>
        cases he : evidenceIssue env p with
        | some issue => simp [authorize, hr, hv, hs, ha, hp, he] at h
        | none =>
          have heq : actual = r := by
            simpa [authorize, hr, hv, hs, ha, hp, he] using h
          subst actual
          exact ⟨hr, hv, hs, ha, (version_issue_none_iff env p).mp hp,
            (evidence_issue_none_iff env p).mp he⟩
  · intro h
    simp [authorize, h.revision, h.registry, h.sourceRule, h.authenticated,
      (version_issue_none_iff env p).mpr h.current,
      (evidence_issue_none_iff env p).mpr h.evidence]

def AdmissibleLeaf (env : Environment) (p : Premise) : Prop :=
  ∃ r, Authority env p r ∧ ∃ a, r.record.payload = .known a

theorem source_accepted_iff (env : Environment) (p : Premise) :
    (evaluateSource env p).Accepted ↔ AdmissibleLeaf env p := by
  constructor
  · rintro ⟨c, hc, hi⟩
    cases ha : authorize env p with
    | error issue => simp [evaluateSource, ha, blocked] at hc
    | ok r =>
      cases hp : r.record.payload with
      | noRuling => simp [evaluateSource, ha, hp, blocked] at hc
      | suspended => simp [evaluateSource, ha, hp, blocked] at hc
      | known a => exact ⟨r, (authorized_iff env p r).mp ha, a, hp⟩
  · rintro ⟨r, ha, a, hp⟩
    refine ⟨⟨p.questionId, r.record.question, a, r.record.scope⟩, ?_, ?_⟩ <;>
      simp [evaluateSource, (authorized_iff env p r).mpr ha, hp, known]

theorem source_provenance (env : Environment) (p : Premise) :
    (evaluateSource env p).provenance = [p] := by
  unfold evaluateSource
  split
  · rfl
  · split <;> rfl

theorem both_provenance (l r : Evaluation) :
    (requireBoth l r).provenance = l.provenance ++ r.provenance := by
  dsimp only [requireBoth]
  split
  · rfl
  · split
    · rfl
    · split
      · split
        · rfl
        · split <;> rfl
      · rfl

theorem both_accepted_inputs {l r : Evaluation} (h : (requireBoth l r).Accepted) :
    l.Accepted ∧ r.Accepted ∧ Homogeneous (l.provenance ++ r.provenance) := by
  rcases h with ⟨c, hc, hi⟩
  dsimp only [requireBoth] at hc
  split at hc
  · simp [blocked] at hc
  · rename_i hs
    have hs' : Homogeneous (l.provenance ++ r.provenance) := by simpa using hs
    split at hc
    · simp [blocked] at hc
    · rename_i hi'
      have hempty : l.issues = [] ∧ r.issues = [] := by simpa using hi'
      split at hc
      · rename_i a b hla hrb
        exact ⟨⟨a, hla, hempty.1⟩, ⟨b, hrb, hempty.2⟩, hs'⟩
      · simp [blocked] at hc

theorem provenance_exact (env : Environment) (tree : Tree) :
    (evaluate env tree).provenance = tree.leaves := by
  induction tree with
  | source p => exact source_provenance env p
  | both l r ihl ihr =>
    simp only [evaluate, both_provenance, Tree.leaves, ihl, ihr]

theorem leaves_nonempty (tree : Tree) : tree.leaves ≠ [] := by
  induction tree with
  | source p => simp [Tree.leaves]
  | both l r ihl ihr => simp [Tree.leaves, ihl, ihr]

theorem accepted_every_source {env : Environment} {tree : Tree}
    (h : (evaluate env tree).Accepted) :
    ∀ p ∈ tree.leaves, AdmissibleLeaf env p := by
  induction tree with
  | source p =>
    intro q hq
    have he : q = p := by simpa [Tree.leaves] using hq
    subst q
    exact (source_accepted_iff env p).mp h
  | both l r ihl ihr =>
    have hc := both_accepted_inputs h
    intro p hp
    rcases List.mem_append.mp hp with hp | hp
    · exact ihl hc.1 p hp
    · exact ihr hc.2.1 p hp

theorem accepted_homogeneous {env : Environment} {tree : Tree}
    (h : (evaluate env tree).Accepted) : Homogeneous tree.leaves := by
  cases tree with
  | source p => simp [Tree.leaves, Homogeneous]
  | both l r =>
    have hs := (both_accepted_inputs h).2.2
    simpa only [provenance_exact, Tree.leaves] using hs

theorem homogeneous_pairwise {sources : List Premise} (h : Homogeneous sources)
    {p q : Premise} (hp : p ∈ sources) (hq : q ∈ sources) : p.key = q.key := by
  cases sources with
  | nil => simp at hp
  | cons first rest =>
    simp only [List.mem_cons] at hp hq
    have hp' : p.key = first.key := by
      rcases hp with hp | hp
      · subst p; rfl
      · exact h p hp
    have hq' : q.key = first.key := by
      rcases hq with hq | hq
      · subst q; rfl
      · exact h q hq
    exact hp'.trans hq'.symm

theorem incompatible_scopes_rejected {env : Environment} {tree : Tree}
    {p q : Premise} (hp : p ∈ tree.leaves) (hq : q ∈ tree.leaves)
    (hne : p.key ≠ q.key) : ¬ (evaluate env tree).Accepted := by
  intro h
  exact hne (homogeneous_pairwise (accepted_homogeneous h) hp hq)

theorem rejected_leaf_blocks_tree {env : Environment} {tree : Tree} {p : Premise}
    (hp : p ∈ tree.leaves) (hb : ¬ (evaluateSource env p).Accepted) :
    ¬ (evaluate env tree).Accepted := by
  intro h
  exact hb ((source_accepted_iff env p).mpr (accepted_every_source h p hp))

theorem accepted_leaf_authority {env : Environment} {tree : Tree}
    (h : (evaluate env tree).Accepted) (p : Premise) (hp : p ∈ tree.leaves) :
    ∃ r, Judgment.validate env.registry p.request = .accepted r ∧
      env.implementationRevision ≠ "" ∧ SourceRule p ∧
      p.request.record.provenance.source ∈ env.authenticatedSources ∧
      matchingVersions env p = [expectedVersion p] ∧
      matchingEvidence env p = [⟨p, .supported⟩] ∧
      ∃ a, r.record.payload = .known a := by
  rcases accepted_every_source h p hp with ⟨r, ha, hk⟩
  exact ⟨r, ha.registry, ha.revision, ha.sourceRule, ha.authenticated,
    ha.current, ha.evidence, hk⟩

theorem accepted_leaf_admitted {env : Environment} {tree : Tree}
    (h : (evaluate env tree).Accepted) (p : Premise) (hp : p ∈ tree.leaves) :
    ∃ entry, Judgment.matchingEntries env.registry p.request.entryId = [entry] ∧
      entry.status = .admitted ∧ entry.record = p.request.record := by
  rcases accepted_every_source h p hp with ⟨r, ha, _⟩
  exact Judgment.accepted_unique_admitted ha.registry

theorem admissible_known_payload {env : Environment} {p : Premise}
    (h : AdmissibleLeaf env p) :
    ∃ q, ∃ a : Judgment.Answer q,
      p.request.record.questionCode = Judgment.encodeQuestion q ∧
      p.request.record.answerCode = Judgment.encodeKnown q a := by
  rcases h with ⟨r, ha, a, hp⟩
  have he := Judgment.accepted_preserves_record ha.registry
  refine ⟨r.record.question, a, ?_, ?_⟩
  · exact (congrArg Judgment.RawRecord.questionCode he).symm
  · have he' := (congrArg Judgment.RawRecord.answerCode he).symm
    simpa [Judgment.encodeRecord, hp, Judgment.encodePayload] using he'

theorem missing_ruling_blocks_tree {env : Environment} {tree : Tree} {p : Premise}
    (hp : p ∈ tree.leaves) (hm : p.request.record.answerCode = 0) :
    ¬ (evaluate env tree).Accepted := by
  intro h
  rcases admissible_known_payload (accepted_every_source h p hp) with ⟨q, a, _, he⟩
  exact (Judgment.known_code_not_status q a).1 (he.symm.trans hm)

theorem suspended_ruling_blocks_tree {env : Environment} {tree : Tree} {p : Premise}
    (hp : p ∈ tree.leaves) (hm : p.request.record.answerCode = 32) :
    ¬ (evaluate env tree).Accepted := by
  intro h
  rcases admissible_known_payload (accepted_every_source h p hp) with ⟨q, a, _, he⟩
  exact (Judgment.known_code_not_status q a).2 (he.symm.trans hm)

theorem unauthenticated_source_blocks_tree {env : Environment} {tree : Tree}
    {p : Premise} (hp : p ∈ tree.leaves)
    (ha : p.request.record.provenance.source ∉ env.authenticatedSources) :
    ¬ (evaluate env tree).Accepted := by
  intro h
  rcases accepted_every_source h p hp with ⟨r, authority, _⟩
  exact ha authority.authenticated

theorem stale_interpretation_blocks_tree {env : Environment} {tree : Tree}
    {p : Premise} (hp : p ∈ tree.leaves)
    (hv : matchingVersions env p ≠ [expectedVersion p]) :
    ¬ (evaluate env tree).Accepted := by
  intro h
  rcases accepted_every_source h p hp with ⟨r, authority, _⟩
  exact hv authority.current

theorem non_admitted_leaf_blocks_tree {env : Environment} {tree : Tree}
    {p : Premise} {entry : Judgment.Entry} (hp : p ∈ tree.leaves)
    (hm : Judgment.matchingEntries env.registry p.request.entryId = [entry])
    (hs : entry.status ≠ .admitted) : ¬ (evaluate env tree).Accepted := by
  intro h
  rcases accepted_every_source h p hp with ⟨r, authority, _⟩
  exact Judgment.non_admitted_not_accepted env.registry p.request r entry hm hs
    authority.registry

theorem substituted_record_blocks_tree {env : Environment} {tree : Tree}
    {p : Premise} {entry : Judgment.Entry} (hp : p ∈ tree.leaves)
    (hm : Judgment.matchingEntries env.registry p.request.entryId = [entry])
    (hs : entry.record ≠ p.request.record) : ¬ (evaluate env tree).Accepted := by
  intro h
  rcases accepted_every_source h p hp with ⟨r, authority, _⟩
  exact Judgment.mismatched_record_not_accepted env.registry p.request r entry hm hs
    authority.registry

theorem unsupported_evidence_blocks_tree {env : Environment} {tree : Tree}
    {p : Premise} {decision : EvidenceDecision} (hp : p ∈ tree.leaves)
    (hm : matchingEvidence env p = [decision])
    (hs : decision.classification ≠ .supported) : ¬ (evaluate env tree).Accepted := by
  intro h
  rcases accepted_every_source h p hp with ⟨r, authority, _⟩
  have he : decision = ⟨p, .supported⟩ := by simpa [hm] using authority.evidence
  exact hs (congrArg EvidenceDecision.classification he)

theorem question_identity_guard {env : Environment} {tree : Tree} {p q : Premise}
    (hp : p ∈ tree.leaves) (hq : q ∈ tree.leaves)
    (hne : p.questionId ≠ q.questionId) : ¬ (evaluate env tree).Accepted :=
  incompatible_scopes_rejected hp hq
    (fun he => hne (congrArg ScopeKey.questionId he))

theorem context_guard {env : Environment} {tree : Tree} {p q : Premise}
    (hp : p ∈ tree.leaves) (hq : q ∈ tree.leaves)
    (hne : p.request.record.scope.context ≠ q.request.record.scope.context) :
    ¬ (evaluate env tree).Accepted :=
  incompatible_scopes_rejected hp hq
    (fun he => hne (congrArg (fun k => k.scope.context) he))

theorem provenance_grades_preserved (env : Environment) (tree : Tree) :
    (evaluate env tree).provenance.map (fun p => p.request.record.provenance.grade) =
      tree.leaves.map (fun p => p.request.record.provenance.grade) := by
  rw [provenance_exact]

theorem taklifi_intersection_exact {left right result : Constraint}
    (h : intersectAnswers .taklifi left right = some result) :
    result.set = left.set.inter right.set := by
  cases hm : IDA.intersectKnown left right <;>
    simp [intersectAnswers, hm] at h
  case known c =>
    cases Option.some.inj h
    exact IDA.known_intersection_exact hm

theorem taklifi_subset_both {left right result : Constraint}
    (h : intersectAnswers .taklifi left right = some result) :
    result.set.Subset left.set ∧ result.set.Subset right.set := by
  rw [taklifi_intersection_exact h]
  exact ⟨HukmSet.inter_subset_left _ _, HukmSet.inter_subset_right _ _⟩

theorem sign_agreement (sign : Sign) (left right result : Judgment.Answer (.wadi sign))
    (h : intersectAnswers (.wadi sign) left right = some result) :
    left = right ∧ result = left := by
  simp only [intersectAnswers] at h
  split at h
  · rename_i he
    exact ⟨he, Option.some.inj h |>.symm⟩
  · contradiction

theorem source_conclusion_key {env : Environment} {p : Premise} {c : KnownConclusion}
    (h : (evaluateSource env p).conclusion = some c) : c.key = p.key := by
  cases ha : authorize env p with
  | error issue => simp [evaluateSource, ha, blocked] at h
  | ok r =>
    cases hp : r.record.payload with
    | noRuling => simp [evaluateSource, ha, hp, blocked] at h
    | suspended => simp [evaluateSource, ha, hp, blocked] at h
    | known answer =>
      have he : (⟨p.questionId, r.record.question, answer, r.record.scope⟩ :
          KnownConclusion) = c := by simpa [evaluateSource, ha, hp, known] using h
      subst c
      have hr := Judgment.accepted_preserves_record ((authorized_iff env p r).mp ha).registry
      have hq := congrArg Judgment.RawRecord.questionCode hr
      have hs := congrArg Judgment.RawRecord.scope hr
      simp only [Judgment.encodeRecord] at hq hs
      simp only [KnownConclusion.key, Premise.key, hq, hs]

theorem combine_conclusion_keys {l r c : KnownConclusion}
    (h : combineConclusions l r = some c) : c.key = l.key ∧ l.key = r.key := by
  unfold combineConclusions at h
  split at h
  · rename_i hq
    split at h
    · rename_i hs
      cases hm : intersectAnswers l.question l.answer (hq ▸ r.answer) with
      | none => simp [hm] at h
      | some answer =>
        simp only [hm, Option.map_some, Option.some.injEq] at h
        subst c
        exact ⟨rfl, by simp only [KnownConclusion.key, hq, hs.1, hs.2]⟩
    · contradiction
  · contradiction

theorem both_conclusion_left {l r : Evaluation} {c : KnownConclusion}
    (h : (requireBoth l r).conclusion = some c) :
    ∃ a, l.conclusion = some a ∧ c.key = a.key := by
  dsimp only [requireBoth] at h
  split at h
  · simp [blocked] at h
  · split at h
    · simp [blocked] at h
    · split at h
      · rename_i a b hla hrb
        split at h
        · simp [blocked] at h
        · split at h
          · rename_i d hd
            have he : d = c := by simpa [known] using h
            subst d
            exact ⟨a, hla, (combine_conclusion_keys hd).1⟩
          · simp [blocked] at h
      · simp [blocked] at h

theorem conclusion_has_source_key {env : Environment} {tree : Tree} {c : KnownConclusion}
    (h : (evaluate env tree).conclusion = some c) :
    ∃ p ∈ tree.leaves, c.key = p.key := by
  induction tree generalizing c with
  | source p => exact ⟨p, by simp [Tree.leaves], source_conclusion_key h⟩
  | both l r ihl ihr =>
    rcases both_conclusion_left h with ⟨a, ha, hca⟩
    rcases ihl ha with ⟨p, hp, hk⟩
    exact ⟨p, List.mem_append_left _ hp, hca.trans hk⟩

theorem accepted_conclusion_scope {env : Environment} {tree : Tree} {c : KnownConclusion}
    (h : (evaluate env tree).Accepted)
    (hc : (evaluate env tree).conclusion = some c) :
    ∀ p ∈ tree.leaves, c.key = p.key := by
  rcases conclusion_has_source_key hc with ⟨q, hq, he⟩
  intro p hp
  exact he.trans (homogeneous_pairwise (accepted_homogeneous h) hq hp)

theorem classification_admitted_iff (e : Evaluation) :
    e.classification = .admitted ↔ e.Accepted := by
  simp [Evaluation.classification, isAccepted_iff]

theorem alternative_order (env : Environment) (trees : List Tree) (i : Nat) :
    (alternatives env trees)[i]? = (trees[i]?).map (evaluate env) := by
  simp [alternatives]

theorem alternatives_length (env : Environment) (trees : List Tree) :
    (alternatives env trees).length = trees.length := by simp [alternatives]

theorem alternatives_provenance (env : Environment) (trees : List Tree) :
    (alternatives env trees).map Evaluation.provenance = trees.map Tree.leaves := by
  simp [alternatives, List.map_map, provenance_exact]

theorem receipt_valid_original (env : Environment) (tree : Tree) :
    (receipt env tree).ValidAt env := by exact ⟨rfl, rfl⟩

theorem replay_recalculates (current : Environment) (r : Receipt) :
    replay current r = evaluate current r.tree := rfl

theorem receipt_accepted_iff (env : Environment) (tree : Tree) :
    (receipt env tree).AcceptedAt env ↔ (evaluate env tree).Accepted := by
  simp [Receipt.AcceptedAt, Receipt.ValidAt, receipt, replay]

theorem valid_receipt_binds_environment {current : Environment} {r : Receipt}
    (h : r.ValidAt current) : r.environment = current := h.1

theorem valid_receipt_binds_output {current : Environment} {r : Receipt}
    (h : r.ValidAt current) : r.result = evaluate current r.tree := h.2

theorem changed_revision_rejects_receipt {current : Environment} {r : Receipt}
    (h : r.environment.implementationRevision ≠ current.implementationRevision) :
    ¬ r.AcceptedAt current := by
  intro ha
  exact h (congrArg Environment.implementationRevision ha.1.1)

theorem changed_result_rejects_receipt {current : Environment} {r : Receipt}
    (h : r.result ≠ evaluate current r.tree) : ¬ r.AcceptedAt current := by
  intro ha
  exact h ha.1.2

theorem accepted_receipt_sources {current : Environment} {r : Receipt}
    (h : r.AcceptedAt current) :
    r.result.provenance = r.tree.leaves ∧
      ∀ p ∈ r.tree.leaves, AdmissibleLeaf current p := by
  have he : r.result = evaluate current r.tree := h.1.2
  rw [he]
  exact ⟨provenance_exact current r.tree, accepted_every_source (he ▸ h.2)⟩

theorem verifyReceipt_sound {current : Environment} {r : Receipt}
    (h : verifyReceipt current r = true) :
    r.environment = current ∧ r.result = evaluate current r.tree ∧
      (evaluate current r.tree).Accepted := by
  have ha : r.AcceptedAt current := of_decide_eq_true h
  have he : r.result = evaluate current r.tree := ha.1.2
  exact ⟨ha.1.1, he, he ▸ ha.2⟩

/-- Endpoint deliberately independent of scenario proofs: full evidence binding is mandatory. -/
theorem unauthorized_evidence_promotion (env : Environment) (tree : Tree) (p : Premise)
    (hp : p ∈ tree.leaves)
    (he : matchingEvidence env p ≠ [⟨p, .supported⟩]) :
    ¬ (evaluate env tree).Accepted := by
  intro h
  rcases accepted_every_source h p hp with ⟨r, authority, _⟩
  exact he authority.evidence

end Usul.IDA.Derivation
