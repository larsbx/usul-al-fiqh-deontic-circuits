# Usul.Typing.IDAPremiseIngestion in Plain English

Source: [`formal/lean/Usul/Typing/IDAPremiseIngestion.lean`](../../../../formal/lean/Usul/Typing/IDAPremiseIngestion.lean)

This module checks the structural connection between supplied contextual
certificates, the complete source and destination applications, and a supplied
list of authenticated source references. Signature verification happens in
the host adapter. The existing [contextual admission checker](IDAAdmission.md)
still decides whether each certificate and application is admissible.

## Checked inputs and failures

`CertificateSource` selects the complete source reference recorded in a
certificate's underlying premise provenance. `Check` requires three things:

- Certificate tokens have no duplicates.
- The supplied certificates equal the source certificate list followed by the
  destination certificate list, preserving their complete contents and order.
- Every certificate's complete source reference occurs in the supplied source
  list.

`validate` checks those conditions in that order and returns either a witness
of `Check` or the corresponding `duplicateToken`, `certificateSet`, or
`sourceEvidence` failure. Source membership compares the full reference,
including its byte and passage commitments; an equal source identifier alone
does not suffice. This check does not replace the later contextual certificate,
interpretation, evidence, or application-grant checks.

`scopedAuthority` installs the supplied certificate and source lists into an
existing authority. It preserves all other authority data, including the
independent application grants. Calling this helper alone neither validates
those lists nor authenticates a signature.

## Theorems

| Theorem | What it establishes |
| --- | --- |
| `destination_source_bound` | Given `Check`, every destination certificate belongs to the supplied certificate list and its full source reference belongs to the supplied source list. |
| `source_bound` | Given `Check`, the same membership guarantees hold for every source-side certificate. |
| `grants_preserved` | Installing certificate and source lists with `scopedAuthority` leaves the existing application-grant list unchanged. |

## Trust boundary

The Lean statements are conditional on the supplied lists and existing
authority. They do not verify Ed25519 signatures, obtain current trust pins,
establish source truth, or authorize a juristic ruling. The
[authenticated premise adapter](../../../research/ida-premise-ingestion.md)
performs the host-side authentication for a fixed synthetic fixture before
invoking these checks and the existing ACT-05 admission path.
