import Lean
import Usul.Typing.IDAActRegistry

/-! Executable JSON-to-model boundary for the ACT-01 comparison gate.
The host first rejects duplicate keys/noncanonical bytes and verifies SHA-256.
This adapter independently parses every semantic field and calls the real Lean
resolver. It emits the entire decoded input, so omitted fields cannot hide in a
comparison of status codes. Byte-level JSON parsing is tested, not proved. -/

open Lean Usul.IDA Usul.IDA.ActRegistry

namespace Usul.IDA.ActRegistry.WireAdapter

def keys (j : Json) (expected : List String) : Except String Unit := do
  let actual := (← j.getObj?).toList.map Prod.fst
  if actual.length = expected.length && actual.all (fun k => expected.contains k) then
    pure ()
  else throw "unexpected JSON fields"

def listOf (f : Json → Except String α) (j : Json) : Except String (List α) := do
  (← j.getArr?).toList.mapM f

def sym (j : Json) : Except String Symbol := do
  keys j ["space", "name"]
  return ⟨← (← j.getObjVal? "space").getStr?, ← (← j.getObjVal? "name").getStr?⟩

def refKind (j : Json) : Except String RefKind := do
  match ← j.getStr? with
  | "person" => pure .person
  | "asset" => pure .asset
  | "obligation" => pure .obligation
  | "occurrence" => pure .occurrence
  | "proposition" => pure .proposition
  | _ => throw "unknown reference sort"

def key (j : Json) : Except String KindKey := do
  keys j ["symbol", "version"]
  return ⟨← sym (← j.getObjVal? "symbol"), ← (← j.getObjVal? "version").getNat?⟩

def role (j : Json) : Except String RoleSpec := do
  keys j ["role", "kind"]
  let k ← j.getObjVal? "kind"
  let kind ← match k with
    | .null => pure none
    | _ => some <$> refKind k
  return ⟨← (← j.getObjVal? "role").getStr?, kind⟩

def entity (j : Json) : Except String EntityRef := do
  keys j ["kind", "symbol"]
  return ⟨← refKind (← j.getObjVal? "kind"), ← sym (← j.getObjVal? "symbol")⟩

def parameter (j : Json) : Except String Parameter := do
  keys j ["role", "kind"]
  return ⟨← (← j.getObjVal? "role").getStr?, ← refKind (← j.getObjVal? "kind")⟩

def operand (j : Json) : Except String Operand := do
  keys j ["role", "referent"]
  return ⟨← (← j.getObjVal? "role").getStr?, ← entity (← j.getObjVal? "referent")⟩

def action (j : Json) : Except String Action := do
  keys j ["operation", "operands"]
  let operation ← j.getObjVal? "operation"
  keys operation ["symbol", "parameters"]
  return ⟨⟨← sym (← operation.getObjVal? "symbol"),
             ← listOf parameter (← operation.getObjVal? "parameters")⟩,
          ← listOf operand (← j.getObjVal? "operands")⟩

def qualification (j : Json) : Except String Qualification := do
  keys j ["predicate", "version", "arguments", "polarity", "mention"]
  return { predicate := ← sym (← j.getObjVal? "predicate")
           version := ← (← j.getObjVal? "version").getNat?
           arguments := ← listOf entity (← j.getObjVal? "arguments")
           polarity := ← (← j.getObjVal? "polarity").getBool?
           mention := ← sym (← j.getObjVal? "mention") }

def snapshot (j : Json) : Except String Snapshot := do
  keys j ["contextId", "timeId", "profile", "profileVersion", "interpretationId",
          "interpretationVersion", "evidenceRevision", "clock", "effectiveAt", "recordedAt"]
  return { contextId := ← (← j.getObjVal? "contextId").getNat?
           timeId := ← (← j.getObjVal? "timeId").getNat?
           profile := ← (← j.getObjVal? "profile").getNat?
           profileVersion := ← (← j.getObjVal? "profileVersion").getNat?
           interpretationId := ← (← j.getObjVal? "interpretationId").getNat?
           interpretationVersion := ← (← j.getObjVal? "interpretationVersion").getNat?
           evidenceRevision := ← (← j.getObjVal? "evidenceRevision").getNat?
           clock := ← sym (← j.getObjVal? "clock")
           effectiveAt := ← (← j.getObjVal? "effectiveAt").getNat?
           recordedAt := ← (← j.getObjVal? "recordedAt").getNat? }

def definition (j : Json) : Except String Definition := do
  keys j ["key", "digest", "roles"]
  return ⟨← key (← j.getObjVal? "key"),
          ← listOf Json.getNat? (← j.getObjVal? "digest"),
          ← listOf role (← j.getObjVal? "roles")⟩

def registry (j : Json) : Except String Registry := do
  keys j ["snapshot", "definitions"]
  return ⟨← (← j.getObjVal? "snapshot").getNat?,
          ← listOf definition (← j.getObjVal? "definitions")⟩

def envelope (j : Json) : Except String Envelope := do
  keys j ["key", "definitionDigest", "registrySnapshot", "qualifications", "context", "action"]
  return { key := ← key (← j.getObjVal? "key")
           definitionDigest := ← listOf Json.getNat? (← j.getObjVal? "definitionDigest")
           registrySnapshot := ← (← j.getObjVal? "registrySnapshot").getNat?
           qualifications := ← listOf qualification (← j.getObjVal? "qualifications")
           context := ← snapshot (← j.getObjVal? "context")
           action := ← action (← j.getObjVal? "action") }

def array (f : α → Json) (values : List α) : Json := .arr (values.map f).toArray
def symJson (s : Symbol) : Json := Json.mkObj [("space", toJson s.space), ("name", toJson s.name)]
def kindJson : RefKind → Json
  | .person => toJson "person" | .asset => toJson "asset"
  | .obligation => toJson "obligation" | .occurrence => toJson "occurrence"
  | .proposition => toJson "proposition"
def keyJson (k : KindKey) : Json := Json.mkObj [("symbol", symJson k.symbol), ("version", toJson k.version)]
def roleJson (r : RoleSpec) : Json := Json.mkObj [("role", toJson r.role), ("kind", r.kind.elim .null kindJson)]
def entityJson (e : EntityRef) : Json := Json.mkObj [("kind", kindJson e.kind), ("symbol", symJson e.symbol)]
def parameterJson (p : Parameter) : Json := Json.mkObj [("role", toJson p.role), ("kind", kindJson p.kind)]
def operandJson (o : Operand) : Json := Json.mkObj [("role", toJson o.role), ("referent", entityJson o.referent)]
def actionJson (a : Action) : Json := Json.mkObj [
  ("operation", Json.mkObj [("symbol", symJson a.operation.symbol),
                            ("parameters", array parameterJson a.operation.parameters)]),
  ("operands", array operandJson a.operands)]
def qualificationJson (q : Qualification) : Json := Json.mkObj [
  ("predicate", symJson q.predicate), ("version", toJson q.version),
  ("arguments", array entityJson q.arguments), ("polarity", toJson q.polarity),
  ("mention", symJson q.mention)]
def snapshotJson (s : Snapshot) : Json := Json.mkObj [
  ("contextId", toJson s.contextId), ("timeId", toJson s.timeId),
  ("profile", toJson s.profile), ("profileVersion", toJson s.profileVersion),
  ("interpretationId", toJson s.interpretationId),
  ("interpretationVersion", toJson s.interpretationVersion),
  ("evidenceRevision", toJson s.evidenceRevision), ("clock", symJson s.clock),
  ("effectiveAt", toJson s.effectiveAt), ("recordedAt", toJson s.recordedAt)]
def definitionJson (d : Definition) : Json := Json.mkObj [
  ("key", keyJson d.key), ("digest", array toJson d.digest), ("roles", array roleJson d.roles)]
def registryJson (r : Registry) : Json := Json.mkObj [
  ("snapshot", toJson r.snapshot), ("definitions", array definitionJson r.definitions)]
def envelopeJson (e : Envelope) : Json := Json.mkObj [
  ("key", keyJson e.key), ("definitionDigest", array toJson e.definitionDigest),
  ("registrySnapshot", toJson e.registrySnapshot),
  ("qualifications", array qualificationJson e.qualifications),
  ("context", snapshotJson e.context), ("action", actionJson e.action)]

def evaluate (j : Json) : Except String Json := do
  keys j ["format", "registry", "envelope"]
  if (← (← j.getObjVal? "format").getStr?) != "usul.ida.act-registry.v1" then
    throw "unsupported wire version"
  let r ← registry (← j.getObjVal? "registry")
  let e ← envelope (← j.getObjVal? "envelope")
  return Json.mkObj [("code", toJson (resolveCode r e)),
    ("registry", registryJson r), ("envelope", envelopeJson e),
    ("projectedTarget", Json.mkObj [("form", toJson "perform"), ("action", actionJson e.action)])]

end Usul.IDA.ActRegistry.WireAdapter

def main (args : List String) : IO UInt32 := do
  match args with
  | [path] =>
    let input ← IO.FS.readFile path
    match Json.parse input >>= (Usul.IDA.ActRegistry.WireAdapter.listOf Usul.IDA.ActRegistry.WireAdapter.evaluate) with
    | .error message => throw (IO.userError message)
    | .ok values =>
      (← IO.getStdout).putStrLn (Json.compress (.arr values.toArray))
      return 0
  | _ => throw (IO.userError "expected a JSON array fixture path")
