# ACT-00 structured targets in source-bound IDA

The integration starts at main `128f7b92dab524dffbbbe5ea9f2f9318bf2199c9`
and uses the target grammar and candidate reference from
[PR #140](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/pull/140).

## Target identity and admission

| Form | What must agree |
| --- | --- |
| Perform | Qualified operation name, complete ordered signature, and each ordered named operand's sort and qualified reference |
| Omit | The underlying perform description, occurrence identity, clock identity, and both bounds of the opportunity interval |
| Affect | Qualified quality and the sort and qualified reference of its object |
| Legacy | Original numeric ID and, in a judgment record, its original behavior/affect kind |

The foundation key compares the full target alongside question, subject,
context, time, profile, and profile version. It accepts structured targets
through `Target.validate`, which returns the checked expression. The judgment
record codec retains raw syntax so registry validation can diagnose a malformed
description as `illTyped` (code 3). It checks named, unique roles, exact signature
agreement, qualified references, and strictly ordered omission bounds. Existing
question, capacity, provenance-shape, snapshot, and status gates still apply.

The derivation key compares the inquiry ID, question family, and complete
judgment scope, including subject ID and capacity, target, context, time,
profile and its version, and domain. Each source separately needs an admitted
exact registry record, an authenticated exact source reference, the unique
current profile/interpretation pin for that source, a supported decision for the
exact premise, and a known typed answer. Two different authenticated source
references can support the same inquiry. Substituting a source reference or
using a stale interpretation pin fails the affected leaf's own checks. Full
provenance and full-value receipt replay preserve the target and all these
inputs. An actor operand and the accountable subject are distinct fields.
Any assertion that they coincide belongs to an explicitly supported source
interpretation or a later typed binding rule.

## Legacy compatibility and migration

| Input or operation | Rule |
| --- | --- |
| Historical foundation key | Wrap the old number as `KeyTarget.legacy id`. Equality of all seven coordinates is preserved. |
| Historical judgment record | Embed the pair `(targetId, targetKind)` as `ScopeTarget.legacy id kind`. Preserve every other field and the original registry and receipt provenance. |
| Mixed comparison | Legacy and structured tags are disjoint. A historical number cannot match a structured expression. |
| Missing or ambiguous mapping | Keep the original record readable and opaque. No built-in mapping, name inference, default role, or first-match selection is provided. |
| Proposed structured replacement | Create a new record with the complete expression. Resolve the intended meaning with source/profile evidence, then use the existing registry admission, current version checks, full-premise evidence decisions, and receipt issuance for the new record. Preserve the historical receipt as historical evidence. |

This is a representation embedding for legacy inputs. The typed models and
finite CSV/ITF test exports are the wire surfaces in scope. Historical numeric
inputs do not have a production JSON decoder in this slice. A consumer of an
older external encoding must explicitly decode its original schema and preserve
its original bytes. An altered target cannot reuse the previous record's
admission, evidence decision, or receipt. The signed source catalog can still
authenticate the same source bytes, which is a separate operation.

The [candidate reference](ida-act-reference.md) keeps all 33 unresolved role
proposals. The one fully typed candidate is still a proposal. Structural checks
establish only agreement with the supplied signature. Registry admission and
supported interpretation decisions are supplied authority, distinct from both
structural validity and source-byte authentication.

## Revision-bound verification

| Layer | Evidence |
| --- | --- |
| Foundation | `legacy_scope_preserved`, `legacy_structured_outOfScope`, the original lattice/conjunction contracts, and the complete structured-target fixture matrix |
| Judgment | `accepted_target`, `legacy_wellTyped`, and Quint controls for omitted shape and full-target checks |
| Derivation | `target_guard`, `accepted_leaf_target`, and the retained complete-scope, source, interpretation, and replay contracts |
| Independent comparison | The legacy export families plus 13 structured derivation cases and three structured receipt cases. The [wire contract](ida-derivation-wire.md) fixes their expected results. |
| Candidate reference | Separate catalogue and source-byte receipt with the unresolved roles intact |

Run `npm --prefix formal/quint ci` and `make ida ida-judgment ida-derivation`.
The scoped workflow requires each proof receipt to match the exact checked
revision and publishes the compiled contracts, projections, and control results.
The candidate-reference workflow records its separate witness checks. ACT-01
(versioned operation registry) and ACT-05 (evidence-bearing judgment transport)
have their own acceptance gates in the [M16 roadmap](ida-act-classification-roadmap.md).
