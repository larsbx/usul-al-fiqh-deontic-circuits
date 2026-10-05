----------------------------- MODULE Taklif -----------------------------
(***************************************************************************)
(* Taklīf state (roadmap M6): obligations bind only a mukallaf (bulūgh +   *)
(* ʿaql) with capacity (lā wājib maʿa ʿajz); a rukhṣa is active only while *)
(* its sabab (safar) holds. Bulūgh is irreversible; ʿaql may be lost.      *)
(***************************************************************************)
EXTENDS Naturals

CONSTANTS Duties

VARIABLES baligh, aqil, capable, travelling, bound, rukhsa

vars == <<baligh, aqil, capable, travelling, bound, rukhsa>>

Mukallaf == baligh /\ aqil

Init == /\ baligh = FALSE /\ aqil = TRUE /\ travelling = FALSE
        /\ capable = [d \in Duties |-> TRUE]
        /\ bound = {} /\ rukhsa = FALSE

\* Any change of capacity re-evaluates which duties bind (no stale obligations).
Rebind(b, a, cap) == bound' = IF b /\ a THEN {d \in Duties : cap[d]} ELSE {}

Bulugh == /\ ~baligh /\ baligh' = TRUE
          /\ Rebind(TRUE, aqil, capable)
          /\ UNCHANGED <<aqil, capable, travelling, rukhsa>>

LoseAql == /\ aqil /\ aqil' = FALSE
           /\ Rebind(baligh, FALSE, capable)
           /\ UNCHANGED <<baligh, capable, travelling, rukhsa>>

RegainAql == /\ ~aqil /\ aqil' = TRUE
             /\ Rebind(baligh, TRUE, capable)
             /\ UNCHANGED <<baligh, capable, travelling, rukhsa>>

Incapacity(d) == /\ capable[d]
                 /\ capable' = [capable EXCEPT ![d] = FALSE]
                 /\ Rebind(baligh, aqil, capable')
                 /\ UNCHANGED <<baligh, aqil, travelling, rukhsa>>

Recover(d) == /\ ~capable[d]
              /\ capable' = [capable EXCEPT ![d] = TRUE]
              /\ Rebind(baligh, aqil, capable')
              /\ UNCHANGED <<baligh, aqil, travelling, rukhsa>>

Depart == /\ ~travelling /\ travelling' = TRUE
          /\ UNCHANGED <<baligh, aqil, capable, bound, rukhsa>>

Arrive == /\ travelling /\ travelling' = FALSE /\ rukhsa' = FALSE
          /\ UNCHANGED <<baligh, aqil, capable, bound>>

TakeRukhsa == /\ travelling /\ Mukallaf /\ rukhsa' = TRUE
              /\ UNCHANGED <<baligh, aqil, capable, travelling, bound>>

Next == \/ Bulugh \/ LoseAql \/ RegainAql \/ Depart \/ Arrive \/ TakeRukhsa
        \/ \E d \in Duties : Incapacity(d) \/ Recover(d)

Spec == Init /\ [][Next]_vars

OnlyMukallafBound  == bound # {} => Mukallaf
OughtImpliesCan    == \A d \in bound : capable[d]
RukhsaNeedsSabab   == rukhsa => travelling
BulughIrreversible == [][baligh => baligh']_vars
=============================================================================
