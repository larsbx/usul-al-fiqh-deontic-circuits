# IDA source-bound judgment replay: shared wire contract

This is a **single-source import/replay model**, building on the IDA foundation.
The independently implemented Lean and Quint models share this interface and
the stated examples, not executable validation code. The trusted snapshot is an
explicit assumption. This slice does not authenticate its origin, make a
juristic admission decision, or verify that an interpretation follows a passage.

## Typed answers

Reuse `Usul.Question` and its answer family. Question tags are 0 = taklifi,
1 = sabab, 2 = shart, 3 = mani, 4 = validity. Other tags are invalid.
Known answers are nonempty subsets of the appropriate answer carrier.

For taklifi, bits 0 through 4 denote haram, makruh, mubah, mandub, wajib;
known masks are 1 through 31. For the three Boolean questions, bits 0 and 1
denote false and true. For validity they denote fasid and sahih. Their known
masks are 1 through 3. In every question, 0 means no ruling, 32 suspension,
33 conflict, and 34 out of scope. All other payload tags are invalid.
In particular, an empty mask never constructs a known answer, and a validity
answer cannot be used as a taklifi answer by retaining its old derivation.

## Records and external trust

`Scope` binds question kind, question ID, subject, target, context, time, profile,
and profile version. The question ID identifies the particular inquiry independently
of its answer carrier; wording or premise revisions must use a different inquiry
ID or context identity.
All fields other than the question tag are strings. `SourceRef` binds source ID,
source SHA-256, passage locator, and passage SHA-256. A claim contains this
scope, an answer tag, a source reference, interpretation ID and version,
evidence-grade label, and implementation revision. Grade is an opaque label;
the checker supplies no ordering or doctrinal interpretation of grades.

A submitted packet contains a claim and a derivation with a frozen copy of that
claim, schema tag 1, and rule tag 0 (`source_import_v1`). Its reported admission
status is untrusted metadata and cannot change the result.

The separately supplied trusted snapshot contains the current requested scope,
one registered source reference and its enabled flag, and one admission entry
binding a complete claim to its **current authoritative decision** and status: 0 candidate, 1 admitted, 2 quarantined,
3 revoked. The single-entry boundary is intentional; registry lookup,
multi-source derivation graphs, admission authority and concurrent storage are
future integration obligations.

The source ID and passage locator must be nonempty. Both digests must be exactly
64 lowercase hexadecimal characters. Interpretation ID/version, evidence-grade
label and implementation revision must be nonempty. The question ID, profile ID
and profile version must also be nonempty. Other scope strings are opaque keys;
this model permits an empty subject, target, context or time key, but still binds
it exactly. Interpreting those keys belongs to the application refinement. Digest syntax and equality
do not prove authenticity, collision resistance, or correspondence to source
bytes. The trusted source reference must already have been established from
the actual source and passage by its provider.

## Replay priority and output

Check these guards in order; the first failing guard determines the diagnostic:

| Code | Rejection |
|---|---|
| 100 | Question or answer cannot be decoded |
| 101 | Derivation schema is not 1 or rule is not 0 |
| 102 | Required provenance is empty or a digest has invalid syntax |
| 103 | Claim scope differs from current requested scope |
| 104 | Registered source is disabled or differs from the claim reference |
| 105 | Trusted admission status is not admitted |
| 106 | Claim differs from the frozen derivation claim |
| 107 | Claim differs from the trusted admission claim |

After all guards pass, return a decoded, question-indexed judgment retaining
the complete original claim/provenance and the externally established admitted
status, and preserve its answer tag exactly (0..34). Successful binding of a conflict or
suspension record remains a conflict or suspension, not a derived known ruling.
No receipt is a signature, authority credential, or application acceptance.

## Complete declared comparison family

Enumerate question 0..5, answer 0..35, admission status 0..3, variant 0..33 in
that order (variant innermost): **29,376 rows**. This includes an unknown question,
invalid answer codes, every admission status, and the following perturbations.
It is not exhaustive enumeration of arbitrary strings or multi-field changes.
Lean's binding theorems quantify over arbitrary claims and snapshots.

The base scope uses question ID `inquiry`, subject `subject`, target `target`, context `context`,
time `time`, profile `profile`, version `v1`; question is the enumerated tag.
The answer is the enumerated tag. Source ID is `source`, locator `passage`,
source digest is 64 `a` characters and passage digest is 64 `c` characters.
Interpretation is `interpretation`, its version `v1`, grade `synthetic`,
implementation `revision`. The trusted scope/source/admission and receipt
initially copy this claim. Source is enabled; reported admission is candidate.

For a changed ordinary string use `changed`. Changed digest is 64 `b`
characters. Changed question is `(question + 1) % 5`. Changed answer is 2 if
the original answer is 1, otherwise 1. Mutations are applied independently to
the base fixture, never cumulatively.

| Variant | Mutation |
|---|---|
| 0 | No change |
| 1..7 | Change only claim question, subject, target, context, time, profile, profile version, respectively |
| 8 | Change only claim answer |
| 9..12 | Change only claim source ID, source digest, locator, passage digest, respectively |
| 13..16 | Change only claim interpretation ID, interpretation version, grade, implementation revision, respectively |
| 17 | Receipt schema becomes 0 |
| 18 | Receipt rule becomes 1 |
| 19 | Change only receipt's frozen answer |
| 20 | Reported admission becomes admitted; trusted status is unchanged |
| 21 | Trusted source becomes disabled |
| 22 | Change only registered source digest |
| 23 | Change only requested scope profile version |
| 24 | Empty locator in claim, receipt, admission and registered source |
| 25 | Change question in claim, receipt and requested scope; admission remains unchanged |
| 26 | Change source digest in claim, receipt and registered source; admission remains unchanged |
| 27 | Change profile version in claim, receipt and requested scope; admission remains unchanged |
| 28 | Change answer in claim and receipt; admission remains unchanged |
| 29 | Change interpretation version in claim and receipt; admission remains unchanged |
| 30 | Source digest becomes `bad` in claim, receipt, admission and registered source |
| 31 | Change implementation revision in claim and receipt; admission remains unchanged |
| 32 | Change only claim question ID |
| 33 | Change question ID in claim, receipt and requested scope; admission remains unchanged |

Lean CSV header is `question,answer,admission,variant,result`. Quint exports
one ITF state with the sole variable `results`, a vector of integers in exactly
the same order. Both exporters must compute each entry independently.

Lean represents digest text as strings. Quint represents it as a list of ASCII
code points: digits 48..57 and lowercase hexadecimal letters 97..102. This
permits independent syntax checking without host-language string operations.
Fixture digest text maps to its ordered code-point list. Neither representation
verifies source bytes.
