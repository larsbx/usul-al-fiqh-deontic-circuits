----------------------------- MODULE MCNaskh -----------------------------
EXTENDS Naskh
CONSTANTS a, b, c
MCRulings == {a, b, c}
MCSource == [r \in MCRulings |-> CASE r = a -> "kitab" [] r = b -> "sunna" [] OTHER -> "ijma"]
=============================================================================
