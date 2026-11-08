# IDA source-bound judgments and required-premise derivations

This extension builds on the [accepted algebra contract](ida-foundation.md)
and the [typed judgment record boundary](ida-judgment-records.md). It checks
derivations from explicitly supplied, admitted premises. It does not determine
whether an interpretation faithfully represents a source or establish a new
juristic ruling.

The dependency is explicit: PR #137 provides the algebra; PR #138 provides the
question-indexed records and registry validation. This branch adds the
derivation checker and source-authentication fixture. Agency integration and
the repository-wide startup repair in PR #136 remain separate obligations.

## Judgments and provenance

The existing typed record retains its source and passage digests, half-open
passage byte range, interpretation ID and version, evidence grade, known
preponderance, source-evidence kinds, context, profile and version, and producer
revision. The derivation layer also distinguishes the identity of the inquiry
from its answer family. Two inquiries that happen to ask for the same kind of
answer do not become the same question.

Every derivation retains its complete ordered source premises. Repeated
references remain repeated references; repetition cannot raise an evidence
grade. Failed and unresolved derivations retain their submitted provenance for
inspection. No derived aggregate grade replaces the grades of the sources.
An admitted calculation can retain a low source grade. That status does not
assert that the grade suffices for acting; action authorization and its evidence
policy remain separate. A supported evidence decision cannot rewrite the
record's grade or known-preponderance field.

## Trust boundary

The submitter supplies a candidate premise or a derivation. Admission, source
authentication, current interpretation pins, and evidence classifications are
separate inputs to the checker. A candidate cannot grant itself one of these
statuses by changing a field in its submission.

The `Accepted` predicate and candidate/admitted classification describe a
result's structure. They are not credentials: a submitter can construct a
record that looks accepted. A consumer must evaluate the submitted derivation
against its own trusted environment, or verify a receipt by comparing its full
stored output with fresh evaluation under that environment. It must not grant
authority merely by inspecting a submitted output's classification.

The underlying registry check requires exactly one admitted entry and binds
the complete source record. The derivation gate adds the source, version, and
evidence checks before producing an admitted conclusion. Evidence is attached
to the complete premise, including the inquiry identity. Changing the source,
passage, interpretation, question, or evidence grade cannot reuse an admission
or evidence decision for a different premise.

The source-authentication adapter checks concrete bytes and passage digests
against a catalog authenticated under a separately configured trust input.
This authenticates the catalog issuer and the specified content. It does not
establish the historical origin of a text, its interpretation, or the issuer's
juristic authority. The executable examples use synthetic text and test keys;
they admit no actual religious position.

The modeled environment stores the authenticated reference list, not a catalog
signature or issuer key. A formal derivation receipt binds that complete modeled
environment. The executable verification receipt separately records the source
adapter's manifest hash, issuer-key fingerprint, input file hashes, and actual
Git revision. The environment's implementation-revision string is a modeled
version label; it does not authenticate the running binary or name the actual
Git revision by itself.

## Derivation rules

The calculus has source leaves and conjunction of two required premises. This
is a deliberately explicit rule set, with no default permission rule and no
generic rule-ID escape hatch.

Conjunction requires equal inquiry identity, question family, and complete
scope. The scope includes subject identity and capacity, target and kind,
context, time, profile and version, and domain. For taklifi answers, conjunction
uses the foundation's nonempty-set intersection. Disjoint constraints remain
conflicting. For Boolean signs and validity, equal known answers combine;
unequal answers remain conflicting. These structural rules do not resolve
juristic disagreement.

Missing information, suspended judgment, disputed evidence, unauthenticated
sources, and candidate or revoked registry entries cannot supply an accepted
normative premise. Their diagnostic status and provenance remain available.
Nested conjunction cannot remove a failed required premise. Alternative
interpretations are evaluated as separate alternatives, without a preference
function or automatic choice.

Reuse of the foundation is exact at the known taklifi intersection operation.
The derivation layer retains a list of all blocked-premise causes. For example,
a missing premise together with a suspended premise retains both diagnostics.
This richer diagnostic contract is separate from the foundation's single-result
priority. An out-of-scope diagnostic precedes inherited blockers.

## Verification boundaries

Lean establishes properties of arbitrary finite modeled derivations. Quint
independently implements the specified semantics and checks declared finite
families and adversarial programs. Agreement within those families is recorded
separately from the universal Lean proofs.

The verification gate requires fixed proposition-type witnesses for promised
proofs, compiled declaration and axiom inventories, exact project import
closures, compiler-resolved Quint source inventories, canonical independent
exports, and controls that weaken the specified guards. A malformed mutant or
missing tool is an error, not a successful adversarial control.

Source-to-theorem traceability records which structural obligations protect
each source-bound field and which independent assertions and mutants exercise
them. These links are verification evidence about the checker. They are not
citations asserting that a source passage establishes a juristic conclusion.

### Verification inventory

| Required evidence | Declared scope |
|---|---|
| Fixed Lean proposition witnesses | 44: 34 universal contracts and 10 scenario contracts |
| Full-value kernel-checked pair scenarios | All 1,089 taklifi pairs and 64 sign/validity pairs, including complete conclusions and provenance |
| Independent Quint tests | 21 deterministic tests; no ignored cases |
| Cross-model export | 1,360 evaluations at eight projections each, 16 replay cases, and 136 source-reference cells: 11,032 cells |
| Independent expected contract cases | 301 cases checked against both exports |
| Semantic negative controls | 23 mutants, each typechecked before its named assertion must fail |
| Source authentication | Six positive and 38 negative controls; two synthetic source references linked to both formal exports |
| Other controls | Seven export-corruption cases, three source-reference link controls, three compiled axiom/import probes, two Quint dependency probes, and one theorem-weakening probe |

The 11,032 cells are not 11,032 independent trees. The projections include
status, classification, inquiry identity, question family, answer, provenance
length, and ordered diagnostic/provenance encodings. Full-record equality is
covered by the separate universal proofs and complete-value scenarios, not
inferred from a potentially colliding integer projection.

The theorem-weakening control preserves the name and arguments of
`unauthorized_evidence_promotion` while changing its conclusion to `True`.
The ordinary core and scenario modules must still compile; the explicit fixed
contract must reject it for the expected proposition-type mismatch.

## Reproduce

Use the pinned Lean toolchain and Node 22 or later:

```sh
npm --prefix formal/quint ci
make ida ida-judgment ida-derivation
```

Successful scoped replay writes `.cache/ida-derivation/` with the report,
compiled axiom inventory, independent exports, Quint results, source
authentication evidence, and traceability receipts. The report binds the
captured repository revision, source hashes, tool versions, declared finite domain,
and recorded `LD_PRELOAD` library paths and hashes. Unsupported nonempty
`NODE_OPTIONS` overrides are rejected. A worktree calculation has
`inputs_match_head: false`; it is not acceptance of the named commit.

The dedicated workflow checks the pull request's actual head and requires all
three IDA receipts to identify that revision with matching committed inputs.
The workflow retains each scope separately. No result from this gate implies
repository-wide CI acceptance or authorizes an automatic merge.

## Further obligations

The model assumes the configured trust inputs are the intended current inputs.
It does not implement admission-authority governance, secure distribution of
trusted keys, atomic registry updates, revocation delivery, or a durable
production service. The byte adapter and the formal model need a separate
end-to-end refinement argument before an application can claim that all of its
inputs satisfy the model. Source interpretation remains separately evidenced.

Exceptions, defaults, contextual specialization, additional inference rules,
action effects, and agency semantics require their own proof contracts.
