# Authenticated premise ingestion for the ACT-08 repayment fixture

The adapter runs the shared guarded repayment application with four exact
premise certificates. Two are scoped to the source application and two to the
destination. The existing synthetic source catalog authenticates the exact
source and passage bytes. A separate Ed25519 attestation signs the canonical
JSON tuple of schema, fixture, implementation revision, source manifest,
premise issuer, and ordered certificate tokens. The fixture name and exact
revision fix the typed meaning of each token. The resolver is closed over
these four compiled certificates. It accepts no arbitrary certificate,
interpretation, context, or ruling through the wire.

| Layer | Check |
| --- | --- |
| Source authentication | Independent issuer key and manifest pins, catalog signature, exact source and passage digests |
| Premise authentication | Separate active authority and key, exact canonical attestation, unique tokens, exact typed certificate and source membership |
| Interpretation validity | Existing derivation registry, independent evidence classification, current profile and interpretation versions |
| Contextual applicability | Existing ACT-05 checks on the full current snapshot, interpreted inquiry, frame, grounding, and exact premise list on each side |
| Authority to admit the application | Existing independent ACT-05 grants for the two exact sides, followed by the shared guard and finite history assessment |

ACT-01 resolves the registered definition in the snapshot. ACT-02 supplies
the typed substitution and both valuations. ACT-03 supplies exact current
context resolution. ACT-04 supplies the conditional semantic assessment.
ACT-05 supplies scoped certificates and independent application grants.
The adapter replaces only the authenticated inputs to the ACT-05 check.
Signed omission observations use a different schema and have no input to
premise ingestion. The existing categorical modules are unchanged.

## Reproduction and receipt

Use a clean checkout, Lean 4.34.1, and Node 22 or later with
`node:sqlite` available. Run `npm --prefix formal/quint ci` and
`make ida-premise-ingestion`. The gate compiles the Lean proofs, runs
the signed fixture and compares nine staged outcomes with Quint. The
revision-bound report is in `.cache/ida-premise-ingestion/report.json`.
All keys used by the gate are published test keys. The negative-control
key from the source fixture signs premise attestations and remains
untrusted for source authentication.

The SQLite transaction boundary is one unique insertion per fixture and
revision in a single database. Restart recovery reads the committed receipt.
An independent replay uses the original source bundle and attestation,
separately pinned trust inputs, and the exact clean implementation
revision. It recomputes the receipt and compares its complete encoding.
A replay authenticates the decision inputs. The local database supplies
the record of insertion. The receipt is neither a signed external
timestamp nor a cross-database uniqueness proof. Revocation state and
policy are supplied by the caller for each attempt. The fixture does not
implement a live authority service, revocation races, external durable
archival, or cross-revision deduplication.

## ACT-08 exit

The repayment trace has a synthetic, source-bound path for premise
authentication. The structural zakat transfer has a separate receipt in
the shared pilot index. The [structural-case component](ida-structural-cases.md) now integrates the
unresolved mandate-role rejection, qualification-sensitive report observations,
and two distinct occurrences through supported same-profile substitution,
projection, and application admission. The context component retains the agency
evidence chronology. Their receipts are indexed at the pilot's exact revision.
The new structural certificates are supplied test authority; this signed adapter
remains closed over its original four repayment certificates. The scoped omission
remains a separate signed replay on the shared destination. General migration
and full core acceptance require separate review of the integrated evidence. Record the supported bounds, missing
interpretation decisions, adverse controls, and repository-wide acceptance
results. Cross-profile reuse is rejected. Cross-profile migration and real
juristic authorization require separate work.
