import Lean
import UsulTest.IDACaseWorkbench

/-! Export computed synthetic fixture observations, not caller-authored verdicts.
The host independently supplies and checks the exact implementation revision. -/

open Lean Usul Usul.IDA Substitution CaseWorkbench
open UsulTest

private def symbolText (s : Symbol) : String := s.space ++ ":" ++ s.name
private def symbolJson (s : Symbol) : Json :=
  Json.mkObj [("space", toJson s.space), ("name", toJson s.name)]
private def kindJson (k : ActRegistry.KindKey) : Json :=
  Json.mkObj [("symbol", symbolJson k.symbol), ("version", toJson k.version)]

private def refKindText : RefKind → String
  | .person => "person" | .asset => "asset" | .obligation => "obligation"
  | .occurrence => "occurrence" | .proposition => "proposition"

private def refText (r : EntityRef) : String := refKindText r.kind ++ "(" ++ symbolText r.symbol ++ ")"
private def refJson (r : EntityRef) : Json :=
  Json.mkObj [("kind", toJson (refKindText r.kind)), ("symbol", symbolJson r.symbol)]

private def argumentRefs : Args [] ks → List EntityRef
  | .nil => []
  | .cons term rest => term.reference.val :: argumentRefs rest

private def formulaText : Formula v [] → String
  | .atom predicate args positive =>
    (if positive then "" else "NOT ") ++ symbolText predicate.val.key.symbol ++
      "@" ++ toString predicate.val.key.version ++ "(" ++
      String.intercalate ", " ((argumentRefs args).map refText) ++ ")"
  | .both left right => "(" ++ formulaText left ++ ") AND (" ++ formulaText right ++ ")"

private def formulaJson : Formula v [] → Json
  | .atom predicate args positive => Json.mkObj [
      ("kind", toJson "atom"), ("predicate", kindJson predicate.val.key),
      ("arguments", toJson ((argumentRefs args).map refJson)), ("positive", toJson positive)]
  | .both left right => Json.mkObj [
      ("kind", toJson "both"), ("left", formulaJson left), ("right", formulaJson right)]

private def reportStatusText : ReportStatus → String
  | .unknown => "unknown" | .supported => "supported"
  | .refuted => "refuted" | .conflicted => "conflicted"

private def signsJson (s : Projection.Signs) : Json := Json.mkObj [
  ("positive", toJson s.positive), ("negative", toJson s.negative),
  ("status", toJson (reportStatusText (reportStatus s)))]

private def assessmentText : Semantics.Assessment → String
  | .noCandidates => "noCandidates" | .inconsistent => "inconsistent"
  | .robust => "robust" | .counterexample => "counterexample"

private def outcomeText : Projection.Outcome → String
  | .outsideScope => "outsideScope" | .unresolved => "unresolved"
  | .fallback => "fallback" | .negativeSupport => "negativeSupport"
  | .positiveSupport => "positiveSupport" | .contestedSupport => "contestedSupport"
  | .exception => "exception" | .contestedException => "contestedException"

private def resultText : Nat → String
  | 0 => "accepted"
  | 1 => "destinationPremiseListMismatch"
  | 2 => "destinationEvidenceMissing"
  | 3 => "destinationSnapshotStale"
  | 4 => "destinationGrantMissing"
  | 5 => "guardRejected"
  | 6 => "noCandidateHistories"
  | 7 => "incompatibleHistories"
  | _ => "unexpectedFailure"

private def questionText : Question → String
  | .taklifi => "taklifi"
  | .wadi .sabab => "sabab"
  | .wadi .shart => "shart"
  | .wadi .mani => "mani"
  | .wadi .validity => "validity"

private def operandJson (operand : Operand) : Json := Json.mkObj [
  ("role", toJson operand.role), ("reference", refJson operand.referent)]

private def inquiryJson (s : Context.Snapshot) : Json := Json.mkObj [
  ("questionId", toJson s.inquiry.questionId),
  ("question", toJson (questionText s.inquiry.question)),
  ("subjectId", toJson s.inquiry.scope.subjectId),
  ("accountable", refJson s.inquiry.accountable),
  ("performer", operandJson s.inquiry.performer),
  ("act", symbolJson s.envelope.action.operation.symbol),
  ("operands", toJson (s.envelope.action.operands.map operandJson)),
  ("target", toJson (reprStr s.inquiry.scope.target)),
  ("targetForm", toJson (if s.opportunity.isSome then "omission" else "performance")),
  ("opportunityDetails", match s.opportunity with
    | none => Json.null
    | some opportunity => Json.mkObj [
      ("occurrence", symbolJson opportunity.occurrence), ("clock", symbolJson opportunity.clock),
      ("opensAt", toJson opportunity.opensAt), ("closesAt", toJson opportunity.closesAt)]),
  ("definition", kindJson s.envelope.key),
  ("definitionDigest", toJson s.envelope.definitionDigest),
  ("registrySnapshot", toJson s.envelope.registrySnapshot),
  ("vocabulary", kindJson s.vocabulary.pin),
  ("policy", kindJson s.admissionPolicy),
  ("snapshotKey", kindJson s.key),
  ("scopeRepresentation", toJson (reprStr s.inquiry.scope)),
  ("contextId", toJson s.envelope.context.contextId),
  ("timeId", toJson s.envelope.context.timeId),
  ("profile", toJson s.envelope.context.profile),
  ("profileVersion", toJson s.envelope.context.profileVersion),
  ("interpretationId", toJson s.envelope.context.interpretationId),
  ("interpretationVersion", toJson s.envelope.context.interpretationVersion),
  ("clock", symbolJson s.envelope.context.clock),
  ("clockVersion", toJson s.time.clockVersion),
  ("effectiveAt", toJson s.envelope.context.effectiveAt),
  ("recordedAt", toJson s.envelope.context.recordedAt),
  ("cutoff", toJson s.time.cutoff),
  ("perspective", toJson (match s.time.perspective with
    | .asKnown => "asKnown" | .retrospective => "retrospective")),
  ("opportunity", toJson (reprStr s.opportunity))]

private def snapshotJson (s : Context.Snapshot) : Json := Json.mkObj [
  ("representation", toJson (reprStr s)),
  ("key", kindJson s.key), ("definition", kindJson s.envelope.key),
  ("definitionDigest", toJson s.envelope.definitionDigest),
  ("registrySnapshot", toJson s.envelope.registrySnapshot),
  ("vocabulary", kindJson s.vocabulary.pin),
  ("admissionPolicy", kindJson s.admissionPolicy),
  ("evidenceRevision", toJson s.envelope.context.evidenceRevision)]

private def certificateJson (side : String) (c : Admission.Certificate v) : Json := Json.mkObj [
  ("token", toJson c.token), ("side", toJson side),
  ("formula", toJson (formulaText c.formula)),
  ("formulaSyntax", formulaJson c.formula),
  ("sourceId", toJson (PremiseIngestion.CertificateSource c).sourceId),
  ("sourceRepresentation", toJson (reprStr (PremiseIngestion.CertificateSource c))),
  ("scope", toJson (reprStr c.application.snapshot)),
  ("applicationPremises", toJson (c.application.premises.map formulaJson)),
  ("applicationConclusion", formulaJson c.application.conclusion)]

private def baselineJson (view : CaseWorkbench.View IDAPilot.plan IDAPilot.rule (IDAPilot.histories 2)) : Json :=
  Json.mkObj [
    ("snapshot", snapshotJson view.snapshot), ("inquiry", inquiryJson view.snapshot),
    ("support", signsJson view.dependencies.support),
    ("exception", signsJson view.dependencies.exception),
    ("guard", toJson (Pilot.guard IDAPilot.rule view.dependencies)),
    ("assessment", toJson (assessmentText (Pilot.assessment IDAPilot.plan (IDAPilot.histories 2)))),
    ("result", toJson "accepted"),
    ("premises", toJson (view.premises.map formulaText)),
    ("premiseSyntax", toJson (view.premises.map formulaJson)),
    ("conclusion", toJson (formulaText view.conclusion)),
    ("conclusionSyntax", formulaJson view.conclusion),
    ("certificateTokens", toJson (view.certificates.map Admission.Certificate.token)),
    ("certificates", toJson
      ((view.receipt.admission.source.certificates.map (certificateJson "source")) ++
        (view.receipt.admission.destination.certificates.map (certificateJson "destination")))),
    ("certificateSourceRepresentations", toJson (view.certificates.map fun c =>
      reprStr (PremiseIngestion.CertificateSource c))),
    ("authenticatedSourceRepresentations", toJson
      (view.receipt.admission.authority.environment.authenticatedSources.map reprStr)),
    ("authorityRevision", toJson view.receipt.admission.authority.environment.implementationRevision),
    ("candidateHistories", toJson (IDAPilot.histories 2).length),
    ("compatibleHistories", toJson
      (Semantics.compatible (Pilot.destinationPoints IDAPilot.plan (IDAPilot.histories 2))
        IDAPilot.plan.destination.premises).length)]

private def scenarioJson (mask population authorityMode : Nat) : Json := Id.run do
  let snapshot := IDAPilot.destinationSnapshot mask
  if h : snapshot.WellFormed IDASemantics.registry then
    let input : Projection.Input IDASemantics.registry := ⟨snapshot, h⟩
    let d := Projection.project IDAPilot.rule input
    let resultCode := IDAPilot.resultCode mask population authorityMode
    return Json.mkObj [
      ("mask", toJson mask), ("population", toJson population), ("authorityMode", toJson authorityMode),
      ("support", signsJson d.support), ("exception", signsJson d.exception),
      ("guard", toJson (Pilot.guard IDAPilot.rule d)),
      ("reportStatus", toJson (outcomeText (Projection.evaluate IDAPilot.rule input))),
      ("assessment", toJson (assessmentText (Pilot.assessment IDAPilot.plan (IDAPilot.histories population)))),
      ("result", toJson (resultText resultCode)), ("resultCode", toJson resultCode)]
  else
    return Json.mkObj [("mask", toJson mask), ("population", toJson population),
      ("authorityMode", toJson authorityMode), ("result", toJson "malformedSnapshot")]

def main (args : List String) : IO Unit := do
  let revision ← match args with
    | [revision] =>
      if revision.isEmpty then throw (IO.userError "Expected nonempty implementation revision")
      else pure revision
    | _ => throw (IO.userError "Expected exactly one implementation revision")
  let view ← match IDACaseWorkbench.sourceBoundTrial revision with
    | .ok receipt => pure (present receipt)
    | .error _ => throw (IO.userError "Source-bound baseline was rejected")
  let mut scenarios : Array Json := #[]
  for mask in [:16] do
    for population in [:4] do
      for authorityMode in [:6] do
        scenarios := scenarios.push (scenarioJson mask population authorityMode)
  IO.println (Json.mkObj [
    ("schema", toJson "ida-case-workbench-lean-v1"),
    ("revision", toJson revision),
    ("synthetic", toJson true),
    ("baseline", baselineJson view), ("scenarios", Json.arr scenarios)]).compress
