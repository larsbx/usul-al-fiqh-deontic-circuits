# Usul.Typing.IDAActIntake in Plain English

Source: [`formal/lean/Usul/Typing/IDAActIntake.lean`](../../../../formal/lean/Usul/Typing/IDAActIntake.lean)

This module prepares a candidate act description from typed references. The caller
supplies a versioned kind key, a definition digest, a registry snapshot number,
attributed qualifications, context metadata, and ordered operands. There is no
caller field for an operation signature, admission status, source authority,
application grant, or ruling.

## What preparation does

`selectOperation` checks the entire supplied registry before looking up the
requested definition. Duplicate keys, including identical duplicates, fail. It
then checks registry shape, snapshot, exact kind/version, digest, and whether
every registered role has a known reference sort. An unresolved role stays
unresolved regardless of the operands supplied by the caller.

The selected definition supplies the operation symbol and complete ordered
parameter signature. `prepare` copies the input into an envelope with that
operation, then calls the existing `ActRegistry.resolve`. Ordered role/sort
mismatches and malformed references or metadata fail that actual resolver.
Diagnostics retain the resolver's precedence. No first-match selection or
caller-supplied signature replaces the registered definition.

A successful `PreparedDraft registry` retains the whole input, derived envelope,
and resolved definition. Its two proof fields certify exact input retention and
successful structural resolution against that exact registry. Its `target`
contains the performed-action expression and a structural well-formedness proof.
The word "performed" is the name of the target constructor, not evidence that
an event occurred.

## Required properties

| Theorem | Meaning |
| --- | --- |
| `prepare_retains_input` | A successful call retains the exact supplied input. |
| `prepare_preserves_fields`, `prepared_fields` | Kind/version, digest, snapshot, qualifications, context, and all ordered operands survive unchanged. |
| `prepared_resolves` | The result has a proof from the existing structural resolver. |
| `prepared_registered`, `prepared_unique` | The selected definition belongs to the supplied registry and is unique for the requested key. |
| `prepared_signature`, `prepared_role_order` | The operation and operand roles match the registered ordered schema exactly. |
| `prepared_pins` | The key, definition digest, and registry snapshot agree with the selected definition/registry. |
| `prepared_wellFormed`, `prepared_target_exact` | The envelope is structurally valid and the target contains its exact action. |
| `unresolved_rejected` | An unresolved registered role prevents successful preparation for every supplied operand list. |
| `conflict_precedes_input` | An ambiguous registry is rejected before input-specific checks. |
| `qualifications_distinguished` | Different retained qualifications cannot silently become the same envelope. |
| `operands_distinguished` | Changed operand references remain distinct even when their sorts match. |

These statements quantify over arbitrary finite supplied registries and typed
inputs. They are not a theorem about the accuracy of a fiqh interpretation.

## Admission boundary

Preparation checks a structural candidate. It does not authenticate the supplied
registry, prove that a definition digest was computed correctly, prove a
qualification true, resolve a reference to an external entity, bind a participant
to the judgment subject, or establish validity, eligibility, occurrence, or
discharge. The existing source and application admission mechanisms retain their
separate inputs and obligations. This result type carries none of their receipts
or authority objects.

The independent host decoder checks the supported wire grammar and definition
hashes. Those byte-level checks and the finite Lean–Quint comparisons have their
own recorded evidence; they are not implied by the universal structural proofs.
