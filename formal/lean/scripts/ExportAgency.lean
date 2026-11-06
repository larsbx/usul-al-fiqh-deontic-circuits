import Usul.Agency

/-!
# Exhaustive joint-agency transition export

Run from `formal/lean`: `lake env lean --run scripts/ExportAgency.lean`.
CSV on stdout contains all 13,312 `(config,state,event)` inputs, in numeric order.
The independently written Quint relation must produce the same enabled and disabled outcomes.
This checks finite executable conformance; it does not establish source interpretation or
verify the Lean compiler, Quint runtime, or an application consuming the models.
-/

def main : IO Unit := do
  IO.println "config,state,event,next"
  for config in List.range 4 do
    for state in List.range 256 do
      for event in List.range 13 do
        IO.println s!"{config},{state},{event},{Usul.Agency.transitionCode config state event}"
