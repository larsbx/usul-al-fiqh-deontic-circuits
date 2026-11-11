# Usul.Typing.IDAPremiseIngestion in Plain English

Source: [`formal/lean/Usul/Typing/IDAPremiseIngestion.lean`](../../../../formal/lean/Usul/Typing/IDAPremiseIngestion.lean)

The boundary accepts an already authenticated certificate list and source
references from the host. Lean checks unique tokens, the exact ordered source
and destination certificate lists, and membership of each certificate's full
source reference. The adapter preserves the current authority's application
grants. ACT-05 still checks the grants and decides contextual applicability.
