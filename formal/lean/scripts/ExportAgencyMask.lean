import Usul.AgencyMask

def main : IO Unit := do
  IO.println "config,state,event,next"
  for config in List.range 8 do
    for state in List.range 256 do
      for event in List.range 13 do
        IO.println s!"{config},{state},{event},{Usul.AgencyMask.transitionCode config state event}"
