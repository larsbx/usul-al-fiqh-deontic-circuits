# A source-linked reference for acts discussed in fiqh

This reference connects the candidate maḥall catalogue to IDA's structured
targets. It supplies a vocabulary for review, source loci, and proposed argument
roles. It does **not** admit a ruling, certify an interpretation, or change the
Lean target algebra. Its descriptive title, **معجم أنواع الأفعال والتصرفات في
الفقه**, names this project's reference rather than an established exhaustive
classical taxonomy.

The machine-readable input is
[`corpus/proposals/fiqh-acts/reference.json`](../../corpus/proposals/fiqh-acts/reference.json).
The validator and exporter are in
[`pipeline/usul_corpus/act_reference.py`](../../pipeline/usul_corpus/act_reference.py).
All 34 proposed kinds remain candidates, including the one whose proposed roles
can currently be assigned existing IDA reference sorts.

## 1. What is already represented

[`Usul.IDA`](../../formal/lean/Usul/IDA.lean) already replaces the numeric target
with `Target`, which contains a complete `TargetExpr` and a proof of its
structural well-formedness. The expressions are:

| Form | Contents |
|---|---|
| `perform` | An `Action`: operation symbol, declared parameter signature, and ordered, named operands |
| `omit` | An action plus an `Opportunity`: occurrence name, clock name, and increasing interval bounds |
| `affect` | An affective quality and the typed referent it concerns |

The five `RefKind` constructors are `person`, `asset`, `obligation`,
`occurrence`, and `proposition`. Role names must be nonempty and distinct;
operands must match the declared signature, including order; references must
have nonempty qualified names. Full expression structure participates in
equality. Changing a recipient, role assignment, operation signature, or omission
interval changes the target. Reconstructing the same structure preserves
equality. See the [specification](islamic-deontic-algebra-spec.md) and
[verification guide](ida-foundation.md).

These checks establish structural consistency. A declared signature does not
become authoritative because its operands match. A reference name does not prove
resolution, and `perform` does not prove that a performance occurred. `affect` is
not a general constructor for every state, object, relation, or event mentioned
in fiqh. The other six scope coordinates, including `Key.subject`, remain
numeric. An actor operand inside a target is independent of `Key.subject`; the
current structure does not prove their consistency.

This document adds a reference around that model. The exporter is not a runtime
`Target` loader. Separate judgment and derivation work exists on `main`; this PR
remains based on the merged foundation until that work is separately integrated.
No claim of joint compilation or new admission machinery follows from this
catalogue integration.

## 2. Preserve the whole candidate graph

The existing [labels](../../corpus/mahall/labels/all.json) contain **537
concepts**: **293** labeled `act`, **173** `item`, and **71** `issue`. The
[topic index](../../corpus/mahall/abwab.json) has **57 roots**. The reference
preserves their identifiers, existing classifications, and source references.
These counts describe the repository's candidate inventory, not all acts in
fiqh or a verified ontology.

Restricting review to the 293 act labels would lose relevant senses.
`rahn.rahn`, `wadia.wadia`, and `nafaqat.nafaqa` are labeled items, while
`amma.niyya` is an issue. Conversely, the act-labeled subset includes
`faraid.mirath` and `ghasb.itlaf_bahaim`, which require disambiguating inheritance
and livestock damage before proposing human conduct. A legacy label is evidence
of an annotation, not a proof of target sort.

The **34 concrete kind proposals** are a separate seed: purification and prayer
performances, fasting, pilgrimage acts, payment, transactions, dispositions,
agency operations, declarations, evidentiary acts, damage, maintenance, and
slaughter. Their family tags support navigation. They neither replace the 537
concepts nor turn the existing `broader` graph into semantic subtyping. Sharing a
chapter, stem, or family does not establish equivalent operations or transfer a
ruling. The existing [maḥall architecture](../architecture/mahall.md) remains
the background for interpreting this candidate graph.

## 3. Four identities that must remain distinct

| Identity | Example | Evidence still needed |
|---|---|---|
| Source occurrence | A paragraph about sale in a specified witness | Its exact locus and retained qualifications |
| Act concept or kind | A proposed definition of sale formation | A reviewed meaning, version, and argument schema |
| Act description | This seller's described exchange concerning specified property | Resolved operands and supported qualifications |
| Act occurrence | A particular attempted exchange at a particular time | Evidence that the event occurred and how it instantiates the description |

A source occurrence is a textual occurrence, not the event described. Two
performances can instantiate the same description without becoming one event.
Conversely, two differently phrased descriptions are not legally equivalent
merely because they point to similar words. IDA structural equality supplies
neither occurrence evidence nor synonym resolution.

Keep definition identity separate from the list of supporting citations. Adding
a citation need not change a meaning; changing the meaning must not silently
reuse its version. The proposed naming convention uses
`space = "fiqh.act.candidate.v1"` and `name = proposed_kind_id` for definition
version 1. Thus the proposed payment kind has name `transfer.pay_zakat`.
This convention is not a registry enforced by Lean: the core still permits
different self-declared signatures under the same symbol and distinguishes them
structurally. A future registry would have to enforce the intended unique
signature for each versioned definition.

## 4. Source passages and their limits

The witnesses below are registered in [the registry](../../corpus/registry.json)
and pinned in [the lock](../../corpus/lock.json). Reference preparation checked
the complete bytes of these three witnesses against their existing locked
SHA-256 values. That integrity check supports reproducibility, not the proposed
interpretations. It did not reverify every other witness cited by the legacy
catalogue.

| Source and pinned witness | Representative loci | Contribution |
|---|---|---|
| Ibn Qudāma, [ʿUmdat al-Fiqh][umda], `openiti-ibnqudama-umda-shamela11315` | 15–18; 24–26; 39; 41–43; 53; 59; 65–66; 103–104; 151–154 | Concrete performances, transactions, declarations, and their qualifications |
| Ibn Qudāma, [Rawḍat al-Nāẓir][rawda], `openiti-rawda-shamela12010` | Volume 1, 139–140; 173–174 | Kind and individual act; doing, restraint, and intention in taklīf |
| Ibn Taymiyya, [al-Qawāʿid al-Nūrāniyya][nuraniyya], `openiti-nuraniyya-shamela21729` | Volume 1, 163–165 | Sayings and deeds considered under worship and ordinary practices |

ʿUmda supplies the enumeration spine. The payment proposal points specifically
to `src:openiti-ibnqudama-umda-shamela11315/v01:p039#b00034`; sale to
`/v01:p053#b00054`; agency to `/v01:p059#b00066`. The latter two abbreviations
use the same witness prefix. Their complete record identifiers and page spans
are preserved in the proposal file and the
[chapter records](../../corpus/records/openiti-ibnqudama-umda-shamela11315.jsonl).
The complete proposal loci are retained in JSON; the table above is representative.
These chapter or passage anchors locate material for review. They do **not**
prove that the author's definition has precisely the proposed software roles.

Rawḍa 1:139–140 distinguishes sameness by kind from an individual act and
discusses differences of relation and qualification, including prostration's
object and prayer on usurped property. This supports retaining those distinctions
for review; it does not by itself settle a software equality relation or the
reported disagreement about validity.

Rawḍa's phrase “والمقتضى بالتكليف: فعل أو كف” motivates retaining deliberate
restraint as a meaningful distinction. Nūrāniyya motivates attention to
manifestation and domain. Neither passage supplies an exhaustive, mutually
exclusive software type system. Their doctrinal applications remain dependent
on source interpretation and context.

## 5. Classify through independent facets

| Facet | What to record |
|---|---|
| Target sort | Whether the passage concerns conduct, omission, a state, object, relation, or event |
| Topic | One or more fiqh chapters or subject areas |
| Kind | The proposed operation or performance and its definition version |
| Manifestation | Bodily conduct, speech, writing, gesture, inward intending, or combinations |
| Structure | Components, sequence, sustained activity, or interaction |
| Roles | Participants and objects with explicit argument types |
| Qualifications | Asserted intention, consent, authority, coercion, time, ownership, or other relevant facts |
| Judgment | The separately supported ruling, validity assertion, cause, condition, or impediment |

This is a design discipline, not a claim that every facet is already encoded in
`TargetExpr`. Prayer can combine speech and movement. A transaction's permitted
manifestations may depend on a source profile. Topic membership does not answer
a validity question. An absent qualification remains unknown: no consent record
does not establish consent, and no classification does not establish
permissibility. Descriptions may also concern attempted or incomplete acts;
classifying their kind does not establish legal effect.

## 6. Conservative bridge to operation signatures

Proposed parameter roles are reviewable seeds. They are not all representable by
the five existing reference sorts. Within this seed, **only
`transfer.pay_zakat` has a complete conservative mapping of its proposed role
list**:

| Proposed role | Candidate `RefKind` |
|---|---|
| `payer` | `person` |
| `recipient` | `person` |
| `transferred_property` | `asset` |

This is a description with a person as recipient, not a universal claim about
all possible zakāt arrangements. It proves neither eligibility, ownership,
amount, discharge, nor occurrence. Even this mapping remains candidate.

For `transaction.sale`, party and property roles have plausible existing sorts,
but `consideration` and `manifestation` require further interpretation. For
`agency.revoke`, a `mandate_reference` should not be silently cast to
`obligation`. For `fasting.observe`, `interval` and `restraint_description` need
explicit representations. Ritual components, provided benefits, and causal
descriptions likewise remain unresolved. Assigning them all `proposition` would
hide the unanswered modeling question. The existence of `Opportunity` for an
omission does not supply an interval operand type for every other operation.

The bridge therefore records proposed kinds, versioned names, roles, source
links, and unresolved mappings. Constructing an actual action still requires a
complete signature and matching operands; admitting its interpretation requires
additional evidence. Neither step follows automatically from catalogue export.

## 7. Preserve qualifications during normalization

| Existing concept | Candidate analysis that preserves its meaning |
|---|---|
| `buyu.bay_fasid` | Sale description plus the source's invalidity assertion; retain the qualified label |
| `ayman.yamin_mukrah` | Oath description plus an evidenced coercion qualification |
| `salat.makan_maghsub` | Prayer description plus location and right-status assertions |
| `hajj.ihram` | Distinguish entering iḥrām from the continuing state |
| `faraid.mirath` | Distinguish entitlement, succession, allocation, and an act of distribution |
| `ghasb.itlaf_bahaim` | Preserve the animal damage event; investigate human conduct and liability separately |
| `amma.niyya` | Distinguish intending, an intention held, and intention as a condition |

These analyses are proposals about the
[existing labels](../../corpus/mahall/labels/all.json), not silent corrections.
Some definitions themselves carry legal qualifications. In ʿUmda's ghasb
discussion at 65–66, taking another's property without right is material to the
concept. A generic taking-possession description cannot replace it without
retaining that qualification. Nor should a qualified source phrase supply a
judgment for every superficially similar description.

## 8. Omission, restraint, and nonoccurrence

An IDA omission specifies an action and a named opportunity with an interval on
a named clock. Its structural proof establishes increasing bounds, not that the
opportunity actually existed, that the subject had capacity, or that an
obligation applied. Those require contextual and interpretive support.

Deliberate restraint, **kaff**, additionally concerns an intentional relation to
the restrained conduct; it cannot be inferred from arbitrary nonperformance.
Fasting also needs its specified interval and restraint conditions, as discussed
in [ʿUmda 41–43][umda] and [Rawḍa 1:173–174][rawda]. Nonoccurrence is a claim
about what did not happen. Failure to observe an event is weaker still. The
reference therefore preserves four distinct questions: what was described, what
occurred, whether there was deliberate restraint, and what judgment applies.
No missing catalogue entry, failed mapping, or empty observation answers them.

## 9. Reproduce and review

From a checkout containing this integration:

```sh
cd pipeline
python -m usul_corpus.act_reference --out ../.cache/fiqh-act-reference
```

The module validates and exports the candidate reference. By default, its receipt
checks pins and record metadata but reports witness bytes as `not_checked`. To
verify complete source bytes too, supply `--witness-dir PATH` containing all three
files named `<witness-id>.txt`; a missing file or a byte/hash mismatch fails.
The dedicated reference workflow retrieves the pinned URLs and runs this mode.
The receipt records each input hash, the checkout revision, and whether those
inputs match that revision, so a local edited tree is not presented as a
committed verification.

It writes the full concept catalogue, the legacy act subset (JSON and CSV),
the topic index, the enriched proposal file, and `source-verification.json`. Review its provenance,
preserved legacy counts and identifiers, proposed versions, source loci, and
unresolved role mappings together. It does not load runtime targets, modify
source pins, or turn proposal status into admission.

The next semantic step is to review a small definition and its full signature
against its source passages, resolve its operands, and connect its qualifications
to the appropriate context and profile. Any later Lean or Quint integration
must state and verify those additional contracts explicitly. The current
structural target proofs remain the foundation; the candidate reference supplies
concrete material for that review rather than a new proof of fiqh correctness.

[umda]: https://github.com/OpenITI/0625AH/blob/f1e38210b32fd0d043949ff6471e869d658c3b16/data/0620IbnQudamaMaqdisi/0620IbnQudamaMaqdisi.CumdatFiqh/0620IbnQudamaMaqdisi.CumdatFiqh.Shamela0011315-ara1
[rawda]: https://github.com/OpenITI/0625AH/blob/f1e38210b32fd0d043949ff6471e869d658c3b16/data/0620IbnQudamaMaqdisi/0620IbnQudamaMaqdisi.RawdatNazir/0620IbnQudamaMaqdisi.RawdatNazir.Shamela0012010-ara1
[nuraniyya]: https://github.com/OpenITI/0750AH/blob/7c9c84d9f98581470aa2b7f8bee00ae285c5c707/data/0728IbnTaymiyya/0728IbnTaymiyya.QawacidNuraniyya/0728IbnTaymiyya.QawacidNuraniyya.Shamela0021729-ara1.completed
