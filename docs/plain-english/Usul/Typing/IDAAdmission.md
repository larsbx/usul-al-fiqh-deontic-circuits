# Usul.Typing.IDAAdmission in Plain English

Source: [`formal/lean/Usul/Typing/IDAAdmission.lean`](../../../../formal/lean/Usul/Typing/IDAAdmission.lean)

A contextual plan carries the original proof and a typed premise arrow.
Reconstruction computes the grounded source and destination applications.
Each application is checked against the current context catalog, exact inquiry
and frame, exact premise list, authenticated certificates, and an exact policy
grant. The existing judgment environment decides source and evidence admission.

The conditional semantics comes directly from
[`Usul.Typing.IDASemantics`](IDASemantics.md). Admission requires its semantic
laws without depending on the downstream functors or categorical adapters.

| Theorem | What it establishes |
|---|---|
| `Plan.reconstructed` | Substitution and cut reconstruct the conditional derivation from the destination premises. |
| `Plan.conditional_sound`, `Receipt.conditional_sound` | Histories satisfying the destination premises satisfy the reconstructed conclusion, including the exact grounded formula recorded by the receipt. |
| `replay_changed` | A receipt cannot replay under changed authority. |
| `reconstruct_preserves_provenance` | Both success and rejection retain the complete submitted source and destination certificate lists. |
| `authorized_certificate_source` | Every authorized certificate goes through the existing IDA source authorization and carries its exact authority witness. |
| `no_token_reuse` | A token that authenticates two certificates in one authority identifies the very same complete certificate. |
| `Receipt.destination_grounding`, `Receipt.destination_certificates`, `Receipt.destination_question` | The receipt binds the typed destination inquiry, ordered grounded premises, and original question family. |
