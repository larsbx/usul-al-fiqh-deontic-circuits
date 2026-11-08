# IDA typed, source-bound judgment records

This slice implements the judgment-format boundary of the
[IDA specification](islamic-deontic-algebra-spec.md). It extends the
[algebra and partial-answer foundation](ida-foundation.md) with question-indexed
records, an explicit registry check, and receipt revalidation. The registry is
a separately supplied trusted input: its status decisions and contents are not
created or authorized by the candidate record.

## Typed answers

The record reuses `Usul.Question`, `Subject`, `Domain`, `Grade`, `DalilKind`, and
`Validity`. Every question has three payload states: no ruling, suspension, or
a known answer of its own type.

| Question | Known answer | Question tag | Known-answer tags |
|---|---|---:|---|
| Taklifi | Nonempty `IDA.Constraint` | 0 | Masks 1..31, using the foundation's five status bits |
| Sabab | Boolean | 1 | 33 false; 34 true |
| Shart | Boolean | 2 | 33 false; 34 true |
| Mani | Boolean | 3 | 33 false; 34 true |
| Validity | `Validity` | 4 | 35 fasid; 36 sahih |

No ruling uses answer tag 0 and suspension uses tag 32 for each question.
Every other question/answer pairing is rejected. Boolean signs retain their
distinct question identities even though their value types agree. A validity
answer cannot stand in for a taklifi status. A non-forbidden partial constraint,
an explicit mubāḥ singleton, and an absent ruling remain different values.

The typed record retains the existing judgment gate: it names at least one
kind of dalil, and a taklifi question requires the subject's two modeled capacity
conditions. Waḍʿī questions do not acquire that taklifi requirement. Evidence
grade and known preponderance remain separate fields. This transport check does
not infer that a given grade is sufficient for acting.

## Complete binding

| Part | Bound fields |
|---|---|
| Question and payload | Question identity and its full typed answer, including missing or suspended states |
| Scope | Subject ID and capacity data; target ID and behavior/affect kind; context; time; profile and profile version; domain |
| Source reference | Source ID; source SHA-256 digest; source byte count; half-open passage byte range; passage SHA-256 digest |
| Interpretation | Interpretation ID and version |
| Evidence | Grade, known preponderance, and ordered dalil list |
| Claimed derivation metadata | Ordered premise IDs, rule ID, and implementation revision |

Digests are represented as exactly 32 byte values, each between 0 and 255.
The passage range must satisfy `start < end <= sourceBytes`, and the
implementation revision must be nonempty. These checks establish reference
shape and exact equality with the registry. They do not recompute a digest,
read source bytes, validate a textual interpretation, or verify that the named
premises entail the conclusion. Identifiers and snapshot numbers are opaque
natural numbers; uniqueness and version issuance outside this function belong
to the registry's producer.

## Admission and revalidation

A registry contains a snapshot identifier and a list of entries. Each entry
has an ID, a status (`candidate`, `admitted`, `quarantined`, or `revoked`), and
the complete registered record. A request supplies the snapshot, entry ID,
and proposed record. It has no self-declared admission flag.

The validator uses the first applicable row below. These codes serialize the
validation result; they do not share the answer-tag namespace.

| Code | Result | Check |
|---:|---|---|
| 1 | Bad answer | The question/answer pair cannot be decoded |
| 2 | Bad reference | A digest, passage range, or implementation revision is malformed |
| 3 | Ill typed | Required evidence or taklifi capacity is absent |
| 4 | Stale snapshot | The request names a different registry snapshot |
| 5 | Missing entry | No entry has the requested ID |
| 6 | Ambiguous entry | More than one entry has the ID, even if the records are identical |
| 7 | Not admitted | The unique entry's status is not `admitted` |
| 8 | Record mismatch | Any field differs from the unique admitted record |
| 0 | Accepted | Return the decoded typed record with its snapshot and entry ID |

A receipt retains the complete accepted record. Revalidation reruns these
checks against the supplied current registry. It rejects a changed snapshot,
revocation, quarantine, removal, duplicate IDs, and replacement of the
registered record. A receipt is data whose binding is checked; it is not a
signature or a bearer credential. Historical storage, authenticated registry
selection, and atomic concurrent updates are outside this function.

Lean's natural-number fields exclude negative values by type. Quint additionally
checks its raw integer boundary and rejects negative natural-number fields as
bad references after question/answer decoding. These out-of-domain checks are
reported separately from the shared finite export.

## Evidence and declared bounds

General Lean theorems connect acceptance to the returned typed record, matching
snapshot, uniquely selected admitted entry, reference shape, and full record
equality. Fixed proposition-type witnesses prevent retaining a theorem's name
while weakening its required statement. The compiled audit includes the entire
declared project dependency closure and rejects undeclared imports, added
axioms, and admitted proofs.

Quint implements the same contract independently. Its deterministic assertions
cover type families, metadata changes, capacity, evidence, registry status,
duplicates, reference shape, partial/missing/suspended answers, and revalidation.
Semantic mutants must typecheck and then fail their named assertion. Parser
failures or tooling errors do not count as successful mutation controls.

The gate also inspects the pinned Quint compiler's resolved source inventory.
The model loads only its declared source; the table loads itself and the model.
Unlisted direct and transitive imports are rejected even when they typecheck.
Every accepted source is included in the receipt's before/after hash check.

| Export section | Complete declared family | Rows |
|---|---|---:|
| `codec` | Question tags 0..5 × answer tags 0..37 | 228 |
| `admission` | Five question families × four statuses × 38 variants | 760 |
| `revalidation` | Five initially accepted question families × eight registry updates | 40 |
| Total | Independent Lean and Quint computations | 1,028 |

All fixtures are synthetic. Their source hashes and admission statuses make no
claim about a real text or a real approved interpretation. The admission family
uses one canonical known answer per question; the codec family separately covers
all 31 nonempty taklifi sets and all missing/suspended/sign/validity tags.

| Admission variant | Change from the canonical fixture |
|---|---|
| 0 | None |
| 1–2 | Question; answer |
| 3–7 | Subject ID; each capacity bit; target ID; target kind |
| 8–12 | Context; time; profile; profile version; domain |
| 13–18 | Source ID; source hash; source byte count; passage start; passage end; passage hash |
| 19–26 | Interpretation ID; interpretation version; grade; known preponderance; dalil; premises; rule ID; implementation revision |
| 27–29 | Request snapshot; request entry ID; duplicate registry entry |
| 30–37 | Empty source hash; empty range; empty dalil; out-of-byte source hash; empty revision; empty passage hash; excessive passage end; out-of-byte passage hash |

Revalidation updates are: unchanged registry, changed snapshot, revoked status,
quarantined status, replaced source hash, replaced profile version, removed
entry, and duplicate entry. General Lean proofs quantify over arbitrary modeled
records. The finite export exhausts this declared family only.

## Reproduce

```sh
npm --prefix formal/quint ci
make ida ida-judgment
```

The gate pins Lean and Quint, runs the fixed tests and mutation controls,
compares canonical exports, and atomically writes `.cache/ida-judgment/`:
`report.json`, `compiled-axioms.json`, `lean.csv`, `quint.itf.json`, and
`quint-tests.json`. Reports bind source hashes, tool versions, loader overrides,
declared bounds, and the exact revision. `inputs_match_head: false` identifies
a worktree calculation rather than verification of that commit. A fresh run
removes any previous successful receipt before checking.

The dedicated IDA workflow runs both foundation and judgment gates at the PR's
actual head and retains their evidence. Repository-wide corpus, roadmap, Lean,
Mathlib, and agency checks continue to report their own results.

## Remaining obligations

The [source-bound derivation slice](ida-source-derivations.md) adds source leaves
and required-premise conjunction with complete provenance and separate source,
current-version, and evidence checks. Its [byte adapter](ida-source-auth.md)
checks a signed source catalog, full bytes, and half-open passage ranges. This
extends the record boundary without making an accepted calculation a juristic
endorsement or an authorization to act.

Source interpretation and admission decisions need their own review evidence.
General derivation rules, exception/default rules, contextual re-evaluation, action and
agency semantics, authenticated registry operations, and application refinement
remain separate tasks. This slice provides the typed and fully bound record
boundary those tasks can use.
