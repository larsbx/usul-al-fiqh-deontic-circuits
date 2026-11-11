import Lean
import Usul.Typing.IDAOmissionWire
import UsulTest.IDAPilot

/-! The local host replay adapter uses synthetic trusted registry and snapshot
inputs. The observation batch is the only datum read from standard input. -/

namespace CheckIDAOmissionWire

open Lean Usul.IDA Usul.IDA.ActRegistry Usul.IDA.Omission.Wire UsulTest.IDAContext

deriving instance ToJson, FromJson for Symbol, Opportunity, KindKey, RefWire,
  ParameterWire, OperandWire, OperationWire, ActionWire, ScopeWire, ReportWire, CoverageWire, View

def parseView (input : String) : Except String View := do
  let json ← Json.parse input
  let view : View ← fromJson? json
  if (toJson view).compress = json.compress then .ok view else .error "non-exact wire shape"

def run (scenario input : String) : Except String String := do
  let view ← parseView input
  let result ← if scenario = "pilot" then
    .ok (review UsulTest.IDASemantics.registry (UsulTest.IDAPilot.authority 9).contexts
      (UsulTest.IDAPilot.destinationSnapshot 9) view)
  else
    let closed := atTick 12
    let (expected, current) ← match scenario with
      | "closed" => .ok (closed, closed)
      | "open" => .ok (base, base)
      | "stale" => .ok (base, closed)
      | "none" => .ok (snapshotCase 23, snapshotCase 23)
      | "retrospective" =>
        let late := { closed with time := { closed.time with cutoff := 14, perspective := .retrospective } }
        .ok (late, late)
      | _ => .error "unknown fixture scenario"
    .ok (review UsulTest.IDAActRegistry.baseRegistry [current] expected view)
  match result with
  | .error failure => .error (reprStr failure)
  | .ok outcome => .ok (reprStr outcome)

def template : View :=
  ⟨schema, encodeScope omissionScope, [], some ⟨["direct", "alternate"], 12⟩⟩

end CheckIDAOmissionWire
open Lean

def main (args : List String) : IO Unit := do
  match args with
  | ["template"] => IO.println (toJson CheckIDAOmissionWire.template).compress
  | ["pilot-template"] =>
    match UsulTest.IDAPilot.omissionBatch 0 with
    | some view => IO.println (toJson view).compress
    | none => throw (IO.userError "pilot snapshot is missing its omission scope")
  | [scenario] =>
    let input ← (← IO.getStdin).readToEnd
    let result := match CheckIDAOmissionWire.run scenario input with
      | .ok outcome => Json.mkObj [("outcome", toJson outcome)]
      | .error failure => Json.mkObj [("failure", toJson failure)]
    IO.println result.compress
  | _ => throw (IO.userError "expected one synthetic fixture scenario")
