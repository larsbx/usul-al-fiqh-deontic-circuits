import Lean
import UsulTest.IDAPremiseIngestion

open Lean Usul.IDA UsulTest.IDAPremiseIngestion

deriving instance FromJson, ToJson for Judgment.SourceRef

structure IngestionInput where
  revision : String
  sources : List Judgment.SourceRef
  tokens : List Nat
  deriving FromJson

def main (args : List String) : IO Unit := do
  match args with
  | ["controls"] => IO.println (toJson ((List.range 9).map control)).compress
  | ["check"] =>
    let input ← (← IO.getStdin).readToEnd
    let result := do
      let json ← Json.parse input
      fromJson? (α := IngestionInput) json
    match result with
    | .error why => throw (IO.userError why)
    | .ok input => IO.println (check input.revision input.sources input.tokens 0)
  | _ => throw (IO.userError "expected controls or check")
