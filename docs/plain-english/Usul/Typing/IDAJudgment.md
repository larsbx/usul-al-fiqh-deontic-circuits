# Usul.Typing.IDAJudgment in Plain English

Source: [`formal/lean/Usul/Typing/IDAJudgment.lean`](../../../../formal/lean/Usul/Typing/IDAJudgment.lean)

This module gives IDA judgments a question-specific answer type and checks their
complete binding to a separately supplied registry. It builds on the existing
[judgment types](../Judgement.md) and [IDA partial answers](../IDA.md).

## What a record contains

A taklifi question can have a known nonempty set of ruling values. Cause,
condition, and impediment questions each take a Boolean answer. Validity takes
the existing validity type. Every question also has distinct no-ruling and
suspended states. A record's answer is indexed by its question, so values from
different families cannot be interchanged in a typed record.

The record carries the subject and its modeled capacity, target and kind,
context, time, profile/version, and domain. Provenance includes source and
passage digests, byte range, interpretation/version, evidence grade, known
preponderance, kinds of dalil, premise IDs, rule ID, and implementation revision.
Exact judgments can be represented as singleton partial answers without
discarding their underlying question type.

## What acceptance means

The validator decodes the raw question and answer, checks reference shape and
the existing evidence/capacity gate, checks the snapshot, requires one matching
registry entry, requires its admitted status, and compares the complete record.
Duplicate entry IDs are rejected even if the duplicates have identical data.
The candidate record cannot select its own admission status.

An accepted result returns the decoded typed record and a receipt bound to the
snapshot and entry. The proofs connect that returned value to the input and the
unique admitted record. Changes to question, answer, scope, source, profile, or
provenance cannot silently reuse the original admission. Revalidation reruns
the checks against the supplied registry, so revocation and registry replacement
are not bypassed by an old receipt.

## Limits

The registry is an explicit trusted input. This module checks digest shape and
equality; it does not read or hash source bytes. It preserves claimed premise
and rule IDs without proving a derivation from them. It does not authorize the
registry producer, certify a source interpretation, or provide a cryptographic
receipt. See the [judgment slice contract](../../../research/ida-judgment-records.md)
for the result codes, complete metadata fields, finite comparison, and remaining
application obligations.
