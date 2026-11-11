# scripts.CheckIDAPremiseIngestion in Plain English

Source: [`formal/lean/scripts/CheckIDAPremiseIngestion.lean`](../../../formal/lean/scripts/CheckIDAPremiseIngestion.lean)

This executable is the JSON entry point to the fixed synthetic premise
ingestion fixture. It imports that fixture and adds JSON conversion for its
source-reference records. It defines no new proof theorem.

| Mode | Input | Output |
| --- | --- | --- |
| `controls` | No standard-input payload is used | The nine fixed control codes as a JSON array |
| `check` | A JSON object parsed into `IngestionInput`, with a revision string, source-reference list, and certificate-token list | The numeric result of the fixture's ordinary checking mode |

The ordinary checking mode resolves only the fixture's compiled certificates.
It does not accept arbitrary formulas, contexts, interpretations, or grants.
Malformed JSON, failure to decode the required typed fields, and unsupported
command arguments raise an input error. A successfully parsed request prints
its semantic result code; callers must inspect that code rather than infer
acceptance from process completion. Only `0` denotes modeled acceptance.

The script does not verify a signature, validate a Git revision, consult a
revocation service, or authenticate the supplied source references. The
[host adapter](../../../formal/ida-premise-ingestion.mjs) performs the separate
signature, source-byte, trust-pin, and exact-revision checks before invoking
this entry point, then requires the accepted result code. Invoking the Lean
script directly provides a model computation, not an authenticated receipt
or a human decision.
