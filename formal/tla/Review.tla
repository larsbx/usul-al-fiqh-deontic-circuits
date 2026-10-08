----------------------------- MODULE Review -----------------------------
(***************************************************************************)
(* Repo harness rule (docs/architecture/deontic-circuits-harness.md):     *)
(* the LLM may propose; only human review admits a record; quarantined or *)
(* unaccepted records never support a derivation.                         *)
(***************************************************************************)
EXTENDS FiniteSets

CONSTANTS Records

VARIABLES status, reviewedBy, support

vars == <<status, reviewedBy, support>>

Statuses == {"absent", "candidate", "reviewed", "accepted", "quarantined"}

Init == /\ status = [r \in Records |-> "absent"]
        /\ reviewedBy = [r \in Records |-> "nobody"]
        /\ support = {}

LLMPropose(r) == /\ status[r] = "absent"
                 /\ status' = [status EXCEPT ![r] = "candidate"]
                 /\ UNCHANGED <<reviewedBy, support>>

HumanReview(r) == /\ status[r] = "candidate"
                  /\ status' = [status EXCEPT ![r] = "reviewed"]
                  /\ reviewedBy' = [reviewedBy EXCEPT ![r] = "human"]
                  /\ UNCHANGED support

Accept(r) == /\ status[r] = "reviewed"
             /\ status' = [status EXCEPT ![r] = "accepted"]
             /\ UNCHANGED <<reviewedBy, support>>

Quarantine(r) == /\ status[r] \in {"candidate", "reviewed", "accepted"}
                 /\ status' = [status EXCEPT ![r] = "quarantined"]
                 /\ support' = support \ {r}          \* retract dependent support
                 /\ UNCHANGED reviewedBy

UseInDerivation(r) == /\ status[r] = "accepted"
                      /\ support' = support \cup {r}
                      /\ UNCHANGED <<status, reviewedBy>>

\* The LLM has no action that reaches "reviewed" or "accepted".
Next == \E r \in Records :
          \/ LLMPropose(r) \/ HumanReview(r) \/ Accept(r)
          \/ Quarantine(r) \/ UseInDerivation(r)

Spec == Init /\ [][Next]_vars

TypeOK == /\ status \in [Records -> Statuses]
          /\ reviewedBy \in [Records -> {"nobody", "human"}]
          /\ support \subseteq Records

AcceptedWasReviewed == \A r \in Records : status[r] = "accepted" => reviewedBy[r] = "human"
SupportIsAccepted   == \A r \in support : status[r] = "accepted"
=============================================================================
