# UsulTest.IDAPremiseIngestion in Plain English

Source: [`formal/lean/UsulTest/IDAPremiseIngestion.lean`](../../../formal/lean/UsulTest/IDAPremiseIngestion.lean)

This fixture connects the shared guarded repayment pilot to the premise
ingestion checks. Its four compiled certificates retain the existing source
and destination applications. Certificates with odd tokens refer to synthetic
source 1; those with even tokens refer to synthetic source 2. These are exact
model references, not signatures or real case evidence.

`authority` starts with the shared contexts and independent grants, but empty
authenticated-certificate and authenticated-source lists. It records the
supplied implementation-revision string. `check` resolves token selectors only
against the four compiled certificates, validates the exact certificate and
source lists, installs those lists, and invokes the existing guarded pilot.
An unknown token produces an incomplete resolution and is rejected. The
revision string is a supplied model input; Lean does not inspect Git.

## Fixed controls

| Control | Change | Output code and meaning |
| --- | --- | --- |
| 0 | Complete synthetic inputs | `0`: the modeled pilot accepts |
| 1 | Supply only the first source reference | `2`: a required source reference is missing |
| 2 | Remove the destination application grant | `4`: the independent policy grant is missing |
| 3 | Replace the destination context with a different report snapshot | `5`: the expected destination snapshot is stale |
| 4 | Change the profile in destination premise scopes | `6`: the certificate scope does not match its application |
| 5 | Change the destination premise question identifier | `6`: the certificate scope does not match its application |
| 6 | Supply tokens `[1, 2, 3, 3]` | `3`: a certificate token is duplicated |
| 7 | Remove current interpretation-version entries | `7`: the interpretation is stale |
| 8 | Supply only source-side tokens `[1, 2]` | `1`: the complete required certificate list is missing |

The profile and question controls also place their altered certificates in the
modeled authenticated list. They therefore check that authentication alone
cannot bypass contextual applicability. Code `99` is an unexpected failure
outside the explicitly classified outcomes.

## Theorem

| Theorem | What it establishes |
| --- | --- |
| `controls` | The nine fixed executable controls produce exactly `[0, 2, 4, 5, 6, 6, 3, 7, 1]`. |

This theorem checks those declared cases. General structural and conditional
soundness properties are supplied by the imported ingestion, admission, and
pilot modules. Native signature checks and the independent Quint comparison
belong to the [host acceptance procedure](../../research/ida-premise-ingestion.md);
they are not performed by this Lean fixture. Acceptance does not establish
actual-world truth or juristic authority.
