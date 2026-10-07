------------------------------ MODULE Naskh ------------------------------
(***************************************************************************)
(* Abrogation over a revelation timeline (roadmap M6). A nāsikh must be    *)
(* revealed later than the mansūkh and come from Kitāb or Sunna; ijmāʿ     *)
(* indicates naskh but does not perform it.                               *)
(***************************************************************************)
EXTENDS Naturals

CONSTANTS Rulings, Source

VARIABLES clock, revealedAt, abrogatedBy

vars == <<clock, revealedAt, abrogatedBy>>

Abrogators == {"kitab", "sunna"}
None == "none"

Init == /\ clock = 0
        /\ revealedAt = [r \in Rulings |-> 0]      \* 0 = not yet revealed
        /\ abrogatedBy = [r \in Rulings |-> None]

Revealed(r) == revealedAt[r] > 0
Active == {r \in Rulings : Revealed(r) /\ abrogatedBy[r] = None}

Reveal(r) == /\ ~Revealed(r)
             /\ clock' = clock + 1
             /\ revealedAt' = [revealedAt EXCEPT ![r] = clock + 1]
             /\ UNCHANGED abrogatedBy

Abrogate(n, m) == /\ n # m
                  /\ n \in Active /\ m \in Active
                  /\ revealedAt[n] > revealedAt[m]
                  /\ Source[n] \in Abrogators
                  /\ abrogatedBy' = [abrogatedBy EXCEPT ![m] = n]
                  /\ UNCHANGED <<clock, revealedAt>>

Next == \/ \E r \in Rulings : Reveal(r)
        \/ \E n, m \in Rulings : Abrogate(n, m)

Spec == Init /\ [][Next]_vars

NoAbrogatedIsActive == \A r \in Active : abrogatedBy[r] = None
NasikhIsLater == \A m \in Rulings : abrogatedBy[m] # None =>
                   revealedAt[abrogatedBy[m]] > revealedAt[m]
NasikhIsNass == \A m \in Rulings : abrogatedBy[m] # None => Source[abrogatedBy[m]] \in Abrogators
NoSelfOrCycle == \A m \in Rulings : abrogatedBy[m] # m
=============================================================================
