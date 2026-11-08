/-!
# Contextual affect and claim fixtures

Executable finite semantics for the v38/v39 fixture language. Source facts,
observations, claims, and paths are independent inputs. Claims never create
observations or local sections. Unknown membership differs from closed-world
nonmembership, and a determined obstruction takes priority over uncertainty.

The fixture corpus and its source loci live in `UsulTest.Fixtures.Sheaf`.
These definitions interpret that bounded language; they make no general claim
that Prolog's operational semantics and Lean reduction are interchangeable.
-/

namespace Usul.Fixtures.Sheaf

inductive Operator where
  | o | f | n
  deriving DecidableEq, BEq, Repr

inductive Condition where
  | tag (name : String)
  | strongerThan (object : String)
  deriving DecidableEq, BEq, Repr

inductive Modality where
  | unconditional
  | conditional (condition : String)
  | comparative (object : String)
  | scalar (scale : String)
  deriving DecidableEq, BEq, Repr

inductive Warrant where
  | quranic (locus : String)
  | behavioralProfile (affect : String)
  | somaticContextOnly
  | fixture (name : String)
  deriving DecidableEq, BEq, Repr

inductive Tier where
  | tier1 | tier2 | tier3 | tier4 | fixture
  deriving DecidableEq, BEq, Repr

inductive EvidenceSource where
  | quranic (locus : String)
  | behavioralProfile (affect : String)
  | somaticContext | generated
  | commentary (name : String)
  deriving DecidableEq, BEq, Repr

structure Evidence where
  tier : Tier
  source : EvidenceSource
  deriving DecidableEq, BEq, Repr

inductive Control where
  | cultivated | dominant | endorsed | actionGuiding | oriented
  | rawOccurrence | involuntaryStartle | panicOverflow | descriptiveOnly
  deriving DecidableEq, BEq, Repr

structure Section where
  affect : String
  object : String
  operator : Operator
  modality : Modality
  warrant : Warrant
  deriving DecidableEq, BEq, Repr

structure SourceFact where
  value : Section
  subject : String := "all_mukallafin"
  deriving DecidableEq, BEq, Repr

structure Context where
  world : String
  agent : String
  conditions : List Condition
  deriving DecidableEq, BEq, Repr

structure Observation where
  world : String
  agent : String
  affect : String
  object : String
  evidence : Evidence
  control : Control
  deriving DecidableEq, BEq, Repr

structure Claim where
  world : String
  agent : String
  value : Section
  origin : String
  deriving DecidableEq, BEq, Repr

structure PathToken where
  path : String
  agent : String
  affect : String
  object : String
  deriving DecidableEq, BEq, Repr

structure AntiPair where
  commanded : String
  forbidden : String
  object : String
  deriving DecidableEq, BEq, Repr

structure Database where
  facts : List SourceFact := []
  contexts : List Context := []
  observations : List Observation := []
  claims : List Claim := []
  aliases : List (String × String) := []
  memberships : List (String × String) := []
  closedSubjects : List String := []
  realizations : List PathToken := []
  scopes : List PathToken := []
  antiPairs : List AntiPair := []
  deriving Repr

inductive Category where
  | objectCollision | subjectCollision | modalityUnsatisfied
  | capacityViolation | tierQuarantine | antiPairFailure
  | operatorConflict | aliasGluingFailure | unsupportedClaim
  deriving DecidableEq, BEq, Repr

inductive Detail where
  | ambiguousAlias (alias : String) (candidates : List String)
  | claimedObject (claimed source : String)
  | outsideSubject (agent subject : String)
  | inactive (modality : Modality)
  | controlStatus (control : Control)
  | quarantinedEvidence (evidence : Evidence)
  | noSourceFact | noContext | noObservation
  deriving DecidableEq, BEq, Repr

inductive Unknown where
  | worldContext
  | subjectMembership (agent subject : String)
  deriving DecidableEq, BEq, Repr

inductive PathReason where
  | forbidden (affect object : String) (warrant : Warrant)
  | missingRequired (affect object : String) (warrant : Warrant)
  | antiPairDisplacement (commanded forbidden object : String)
  deriving DecidableEq, BEq, Repr

inductive Reason where
  | claim (agent : String) (value : Section) (category : Category) (detail : Detail)
  | conflict (left right : Section)
  | path (reason : PathReason)
  deriving DecidableEq, BEq, Repr

inductive Verdict where
  | glues (sections : List (String × Section))
  | obstructed (reasons : List Reason)
  | undetermined (unknowns : List Unknown)
  deriving DecidableEq, BEq, Repr

inductive ClaimState where
  | obstructed | undetermined | lifted
  deriving DecidableEq, BEq, Repr

/-- Canonical finite sets: deduplicate witnesses and order their typed encoding. -/
def canonical [BEq α] [Repr α] (values : List α) : List α :=
  values.eraseDups.mergeSort (fun a b => reprStr a ≤ reprStr b)

def underTaklifControl : Control → Bool
  | .cultivated | .dominant | .endorsed | .actionGuiding | .oriented => true
  | .panicOverflow => false
  | _ => false

def quarantined (evidence : Evidence) : Bool := evidence.tier == .tier4

def modalitySatisfied (modality : Modality) (conditions : List Condition) : Bool :=
  match modality with
  | .unconditional => true
  | .conditional condition => conditions.contains (.tag condition)
  | .comparative object => conditions.contains (.strongerThan object)
  | .scalar scale => conditions.contains (.tag scale)

def subjectMatches (db : Database) (agent subject : String) : Bool :=
  subject == "all_mukallafin" || db.memberships.contains (agent, subject)

def membershipUnknown (db : Database) (agent subject : String) : Bool :=
  subject != "all_mukallafin" && !db.memberships.contains (agent, subject) &&
    !db.closedSubjects.contains agent

def contextsFor (db : Database) (world agent : String) : List Context :=
  db.contexts.filter (fun c => c.world == world && c.agent == agent)

def observationsFor (db : Database) (world agent affect object : String) : List Observation :=
  db.observations.filter (fun o => o.world == world && o.agent == agent &&
    o.affect == affect && o.object == object)

def supportingObservation (db : Database) (world agent affect object : String) : Bool :=
  (observationsFor db world agent affect object).any (fun o =>
    underTaklifControl o.control && !quarantined o.evidence)

def localSections (db : Database) (world agent : String) : List Section :=
  canonical ((contextsFor db world agent).flatMap fun context =>
    db.facts.filterMap fun fact =>
      let s := fact.value
      if supportingObservation db world agent s.affect s.object &&
          subjectMatches db agent fact.subject && modalitySatisfied s.modality context.conditions
      then some s else none)

def realizes (db : Database) (path agent affect object : String) : Bool :=
  db.realizations.contains ⟨path, agent, affect, object⟩

def pathReasons (db : Database) (world path : String) : List PathReason :=
  let localReasons := (db.contexts.filter (·.world == world)).flatMap fun context =>
    (localSections db world context.agent).flatMap fun s =>
      (if s.operator == .f && realizes db path context.agent s.affect s.object
       then [.forbidden s.affect s.object s.warrant] else []) ++
      (if s.operator == .o && db.scopes.contains ⟨path, context.agent, s.affect, s.object⟩ &&
          !realizes db path context.agent s.affect s.object
       then [.missingRequired s.affect s.object s.warrant] else [])
  let antiReasons := (db.realizations.filter (·.path == path)).flatMap fun token =>
    db.antiPairs.filterMap fun pair =>
      if token.affect == pair.forbidden && token.object == pair.object &&
          !realizes db path token.agent pair.commanded pair.object
      then some (.antiPairDisplacement pair.commanded pair.forbidden pair.object) else none
  canonical (localReasons ++ antiReasons)

def sameScope (left right : Section) : Bool :=
  left.affect == right.affect && left.object == right.object

def operatorIncompatible (left right : Operator) : Bool :=
  match left, right with
  | .o, .f | .f, .o => true
  | .o, .n | .n, .o | .f, .n | .n, .f => true
  | _, _ => false

def resolveId (db : Database) (term : String) : Except (List String) String :=
  let ids := canonical (db.aliases.filterMap (fun (alias, id) => if alias == term then some id else none))
  match ids with
  | [] => .ok term
  | [id] => .ok id
  | many => .error many

def normalizedSection (db : Database) (value : Section) : Option Section := do
  let affect ← (resolveId db value.affect).toOption
  let object ← (resolveId db value.object).toOption
  pure { value with affect, object }

def sourceFacts (db : Database) (value : Section) : List SourceFact :=
  db.facts.filter (·.value == value)

def sameSourceExceptObject (left right : Section) : Bool :=
  left.affect == right.affect && left.operator == right.operator &&
    left.modality == right.modality && left.warrant == right.warrant

/-- Emit failed checks only when their prerequisites are present. -/
def sectionObstructions (db : Database) (world agent : String) (value : Section) :
    List (Category × Detail) := Id.run do
  let sources := sourceFacts db value
  let candidates := db.facts.filter (fun fact => sameSourceExceptObject value fact.value)
  let contexts := contextsFor db world agent
  let observations := observationsFor db world agent value.affect value.object
  let mut reasons : List (Category × Detail) := []
  if sources.isEmpty then
    reasons := reasons ++ (candidates.filterMap fun fact =>
      if fact.value.object != value.object
      then some (.objectCollision, .claimedObject value.object fact.value.object) else none)
  if candidates.isEmpty then
    reasons := reasons ++ [(.unsupportedClaim, .noSourceFact)]
  if !sources.isEmpty && contexts.isEmpty then
    reasons := reasons ++ [(.unsupportedClaim, .noContext)]
  for fact in sources do
    if !subjectMatches db agent fact.subject && !membershipUnknown db agent fact.subject then
      reasons := reasons ++ [(.subjectCollision, .outsideSubject agent fact.subject)]
  if !sources.isEmpty then
    for context in contexts do
      if !modalitySatisfied value.modality context.conditions then
        reasons := reasons ++ [(.modalityUnsatisfied, .inactive value.modality)]
  if !sources.isEmpty && !contexts.isEmpty then
    if observations.isEmpty then
      reasons := reasons ++ [(.unsupportedClaim, .noObservation)]
    if !supportingObservation db world agent value.affect value.object then
      for observation in observations do
        if !underTaklifControl observation.control then
          reasons := reasons ++ [(.capacityViolation, .controlStatus observation.control)]
        if quarantined observation.evidence then
          reasons := reasons ++ [(.tierQuarantine, .quarantinedEvidence observation.evidence)]
  return canonical reasons

def claimObstructions (db : Database) (claim : Claim) : List (Category × Detail) :=
  let aliasReasons := [claim.value.affect, claim.value.object].filterMap fun term =>
    match resolveId db term with
    | .ok _ => none
    | .error ids => some (.aliasGluingFailure, .ambiguousAlias term ids)
  let sectionReasons := match normalizedSection db claim.value with
    | none => []
    | some value => sectionObstructions db claim.world claim.agent value
  canonical (aliasReasons ++ sectionReasons)

def claimLifted (db : Database) (claim : Claim) : Bool :=
  match normalizedSection db claim.value with
  | none => false
  | some value => (localSections db claim.world claim.agent).contains value

def claimUnknowns (db : Database) (claim : Claim) : List Unknown :=
  match normalizedSection db claim.value with
  | none => []
  | some value => canonical ((sourceFacts db value).filterMap fun fact =>
      if membershipUnknown db claim.agent fact.subject && (claimObstructions db claim).isEmpty
      then some (.subjectMembership claim.agent fact.subject) else none)

/-- Keep the relation's alternatives explicit so the fixture checks uniqueness. -/
def claimStates (db : Database) (claim : Claim) : List ClaimState :=
  (if !(claimObstructions db claim).isEmpty then [.obstructed] else []) ++
  (if !(claimUnknowns db claim).isEmpty then [.undetermined] else []) ++
  (if claimLifted db claim then [.lifted] else [])

def worldObstructions (db : Database) (world : String) : List Reason :=
  let claimReasons := (db.claims.filter (·.world == world)).flatMap fun claim =>
    (claimObstructions db claim).map fun (category, detail) =>
      Reason.claim claim.agent claim.value category detail
  let conflicts := (db.contexts.filter (·.world == world)).flatMap fun context =>
    let sections := localSections db world context.agent
    sections.flatMap fun left => sections.filterMap fun right =>
      if reprStr left < reprStr right && sameScope left right &&
          operatorIncompatible left.operator right.operator
      then some (.conflict left right) else none
  canonical (claimReasons ++ conflicts)

def worldUnknowns (db : Database) (world : String) : List Unknown :=
  let observed := (db.contexts.filter (·.world == world)).flatMap fun context =>
    db.facts.filterMap fun fact =>
      let s := fact.value
      if supportingObservation db world context.agent s.affect s.object &&
          modalitySatisfied s.modality context.conditions &&
          membershipUnknown db context.agent fact.subject
      then some (.subjectMembership context.agent fact.subject) else none
  let claimed := (db.claims.filter (·.world == world)).flatMap (claimUnknowns db)
  canonical (observed ++ claimed)

def worldVerdict (db : Database) (world : String) : Verdict :=
  if !(db.contexts.any (·.world == world)) then .undetermined [.worldContext]
  else
    let reasons := worldObstructions db world
    let unknowns := worldUnknowns db world
    if !reasons.isEmpty then .obstructed reasons
    else if !unknowns.isEmpty then .undetermined unknowns
    else .glues (canonical ((db.contexts.filter (·.world == world)).flatMap fun context =>
      (localSections db world context.agent).map (fun value => (context.agent, value))))

/-- A missing externally supplied world identifier is an error, never enumeration. -/
def queryWorldVerdict (db : Database) (world : Option String) : Except String Verdict :=
  match world with
  | none => .error "instantiation_error: world"
  | some name => .ok (worldVerdict db name)

def pathVerdict (db : Database) (world path : String) : Verdict :=
  match worldVerdict db world with
  | .glues sections =>
    let reasons := pathReasons db world path
    if reasons.isEmpty then .glues sections else .obstructed (reasons.map Reason.path)
  | other => other

def Verdict.gluable : Verdict → Bool
  | .glues _ => true
  | _ => false

def Verdict.valid : Verdict → Bool
  | .glues _ => true
  | .obstructed reasons => !reasons.isEmpty
  | .undetermined unknowns => !unknowns.isEmpty

def claimCategories (db : Database) (world : String) : List Category :=
  canonical ((db.claims.filter (·.world == world)).flatMap fun claim =>
    (claimObstructions db claim).map Prod.fst)

def allCategories : List Category :=
  [.objectCollision, .subjectCollision, .modalityUnsatisfied, .capacityViolation,
   .tierQuarantine, .antiPairFailure, .operatorConflict, .aliasGluingFailure, .unsupportedClaim]

def emittedCategories (db : Database) : List Category :=
  let worlds := canonical (db.contexts.map (·.world) ++ db.claims.map (·.world))
  let paths := canonical (db.realizations.map (·.path) ++ db.scopes.map (·.path))
  let fromWorlds := worlds.flatMap fun world => (worldObstructions db world).filterMap fun
    | .claim _ _ category _ => some category
    | .conflict _ _ => some .operatorConflict
    | .path _ => none
  let fromPaths := worlds.flatMap fun world => paths.flatMap fun path =>
    (pathReasons db world path).filterMap fun
      | .antiPairDisplacement _ _ _ => some .antiPairFailure
      | _ => none
  canonical (fromWorlds ++ fromPaths)

end Usul.Fixtures.Sheaf
