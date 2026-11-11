import UsulTest.IDAPilot
import Usul.Typing.IDAPremiseIngestion

namespace UsulTest.IDAPremiseIngestion

open Usul.IDA Admission PremiseIngestion
open IDAPilot (plan rule histories)
open IDASubstitution (vocabulary)

private def bindSources (s : Side vocabulary) : Side vocabulary :=
  { s with certificates := s.certificates.map fun c =>
    { c with premise := IDADerivation.changeSource c.premise fun _ =>
        IDADerivation.syntheticSource (if c.token % 2 = 1 then 1 else 2) } }

def source := bindSources IDAPilot.source
def destination := bindSources (IDAPilot.destination 9)
def certificates := source.certificates ++ destination.certificates
def sources := [IDADerivation.syntheticSource 1, IDADerivation.syntheticSource 2]

def authority (revision : String) : Authority vocabulary :=
  let old := IDAPilot.authority 9
  let env := IDADerivation.E (certificates.map Certificate.premise)
  ⟨{ env with currentVersions := env.currentVersions.eraseDups
              authenticatedSources := []
              implementationRevision := revision },
    old.contexts, [], [source, destination]⟩

def check (revision : String) (refs : List Judgment.SourceRef) (tokens : List Nat)
    (mode : Nat) : Nat :=
  let attested := tokens.filterMap fun token => certificates.find? (·.token == token)
  let current := authority revision
  let current := match mode with
    | 2 => { current with grants := [source] }
    | 3 => { current with contexts := [IDAPilot.sourceSnapshot,
        IDAPilot.destinationSnapshot 1] }
    | 7 => { current with environment := { current.environment with currentVersions := [] } }
    | _ => current
  let proposed := match mode with
    | 4 => { destination with certificates := destination.certificates.map fun c =>
        { c with premise := IDADerivation.changeScope c.premise fun s => { s with profile := s.profile + 1 } } }
    | 5 => { destination with certificates := destination.certificates.map fun c =>
        { c with premise := { c.premise with questionId := c.premise.questionId + 1 } } }
    | _ => destination
  -- An altered request can be independently attested in these controls. It
  -- still has to pass ACT-05 against the current application and environment.
  let attested := if mode = 4 || mode = 5 then source.certificates ++ proposed.certificates else attested
  if attested.length != tokens.length then 1 else
  match validate source proposed attested refs with
  | .error .certificateSet => 1
  | .error .sourceEvidence => 2
  | .error .duplicateToken => 3
  | .ok _ =>
    match Pilot.run plan rule (histories 2) (scopedAuthority current attested refs) source proposed with
    | .ok _ => 0
    | .error (.admission rejected) =>
      match rejected.reason with
      | .policy => 4
      | .snapshot .stale => 5
      | .certificateScope => 6
      | .sourceAdmission .staleInterpretation => 7
      | _ => 99
    | .error _ => 99

def control (n : Nat) : Nat :=
  let refs := if n = 1 then sources.take 1 else sources
  let tokens := if n = 6 then [1, 2, 3, 3] else if n = 8 then [1, 2] else [1, 2, 3, 4]
  check "synthetic-revision" refs tokens n

theorem controls : (List.range 9).map control = [0, 2, 4, 5, 6, 6, 3, 7, 1] := by decide

end UsulTest.IDAPremiseIngestion
