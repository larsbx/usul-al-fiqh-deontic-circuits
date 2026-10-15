---------------------------- MODULE Istishab ----------------------------
(***************************************************************************)
(* al-aṣl baqāʾ mā kāna ʿalā mā kāna / al-yaqīn lā yazūl bi'l-shakk       *)
(* (al-Saʿdī, al-Qawāʿid al-Jāmiʿa; Ibn Rajab, Taqrīr). A ṭahāra state    *)
(* changes only on a certain event; doubt is a stutter on the state.       *)
(***************************************************************************)
EXTENDS Naturals

VARIABLES state, lastCertain, events

vars == <<state, lastCertain, events>>

States  == {"tahir", "muhdith"}
Certain == {"wudu", "hadath"}
After(e) == IF e = "wudu" THEN "tahir" ELSE "muhdith"

Init == /\ state \in States
        /\ lastCertain = "none"
        /\ events = 0

CertainEvent(e) == /\ state' = After(e)
                   /\ lastCertain' = e
                   /\ events' = events + 1

\* Doubt about a ḥadath (or about wuḍūʾ) after certainty: nothing moves.
Doubt == /\ events' = events + 1
         /\ UNCHANGED <<state, lastCertain>>

Next == /\ events < 6
        /\ \/ \E e \in Certain : CertainEvent(e)
           \/ Doubt

Spec == Init /\ [][Next]_vars

TypeOK == state \in States /\ lastCertain \in Certain \cup {"none"} /\ events \in 0..6

\* The state is always explained by the last certain event (or the initial yaqīn).
Explained == lastCertain # "none" => state = After(lastCertain)

\* Action property: no step without a certain event changes the state.
DoubtIsInert == [][lastCertain' = lastCertain => state' = state]_vars
=============================================================================
