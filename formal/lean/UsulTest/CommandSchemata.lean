import Usul

/-! Independent source controls for candidate M5 schemata; no adopted ruling. -/

open Usul Usul.CommandSchemata

#guard nonverbalUsage .qadiReported .writing == .notLiteral
#guard nonverbalUsage .qadiReported .gesture == .notLiteral
#guard nonverbalUsage .jamiWriting .writing == .literal
#guard nonverbalUsage .jamiWriting .gesture == .unsettled

#guard propheticActUsage .abuBarakat true == .figurative
#guard propheticActUsage .literalReport true == .literal
#guard propheticActUsage .authorConditional true == .literal
#guard propheticActUsage .authorConditional false == .unsettled

#guard obligationStatus .qadi .unqualifiedThreat (some .mandub) == .mandub
#guard obligationStatus .abuBarakat .unqualifiedThreat (some .mandub) == .wajib
#guard obligationStatus .qadi .wujubLabel (some .mubah) == .mubah
#guard obligationStatus .abuBarakat .wujubLabel (some .mubah) == .wajib
#guard obligationStatus .abuBarakat .fardLabel (some .mandub) == .wajib
#guard obligationStatus .abuBarakat .bareCommand (some .mandub) == .mandub

#guard intendedUsage .qadiReport .permission == .literal
#guard intendedUsage .qadiArgument .permission == .figurative
#guard intendedUsage .karkhiRazi .permission == .unsettled
#guard intendedUsage .abuBarakat .recommendation == .unsettled
#guard (intendedCommand .qadiReport .permission).ruling == .mubah
#guard (intendedCommand .qadiArgument .permission).ruling == .mubah
#guard (intendedCommand .qadiReport .recommendation).ruling == .mandub
#guard (intendedCommand .karkhiRazi .recommendation).ruling == .mandub

example (r : ObligationReading) (q : Option Hukm) :
    obligationStatus r .bareCommand q = Dalala.amrStatus q := bare_command_conservative r q

example (a b : IntendedUseReading) (i : IntendedRuling) :
    (intendedCommand a i).ruling = (intendedCommand b i).ruling := naming_preserves_intended_ruling a b i
