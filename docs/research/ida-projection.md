# ACT-03 scoped projection and information loss

This slice gives the [ACT-03 roadmap](ida-act-classification-roadmap.md#act-03--account-for-forgetting-and-scoped-equivalence)
a complete dependency example over the synthetic repayment inquiry grounded in
[ACT-02](ida-substitution.md). The input type requires an ACT-01 well-formed
snapshot. The evaluator reads report rows and produces synthetic observation
statuses. The witness checks structure. Authentication, admission, source
fidelity, and juristic interpretation have separate contracts.

Two further finite controls exercise the accepted context theory's inference
boundaries: output relabeling preserves the information read by an encoder
while changing its answer, and consistent supplied cases leave an unattested
feature class free. These controls use synthetic Boolean answers, not source
judgments or admission outcomes.

## What each projection carries

| Projection | Retains | Can forget |
|---|---|---|
| `core` | The exact structured target, including named operands and the optional omission opportunity | Qualifications, inquiry and policy context, definition pins |
| `kind` | The described kind's qualified symbol and version | Concrete operands, opportunity, qualifications, and inquiry context |
| `project rule` | The complete scope key and positive and negative existence observations for both queries | Unmatched reports, mention identifiers, duplicates, row order, snapshot key, evidence revision |

The scope key preserves the full inquiry, participants, context coordinates,
question, definition version and digest, registry snapshot, vocabulary, policy
pin, interpretation coordinates, and temporal view. It keeps all context
metadata except evidence revision. Equality is relative to one fixed rule,
including its query definitions and fallback flag. The kind map is defined on
a described snapshot. An occurrence identifier alone supplies no description
or kind witness.

## Complete dependency and exact equality

The direct evaluator searches the raw report list for four observations. Support
is indexed by the accountable person and the exception by the performer. Each
query selects the exact qualified predicate, version, and rigid argument.
Both polarities are queried. Exceptions have priority. The fallback requires
the rule's default flag and an explicit negative exception report, with
neither sign of support and no positive exception.

The dependency projection filters the complete matching sets and summarizes
them by both signs. Lean proves that each summary is equal to the corresponding
direct search, then proves the factorization through
[`Schema.Factors`](../../formal/lean/Usul/Schema.lean).
The projected evaluator is defined explicitly on the whole codomain. It needs
no arbitrary extension off the image.

The pure evaluator, dependency projection, and ordinary factorization proofs
live in [`Usul.Typing.IDAProjection`](../../formal/lean/Usul/Typing/IDAProjection.lean).
The downstream [`Usul.Cat.IDAProjection`](../../formal/lean/Usul/Cat/IDAProjection.lean)
applies the existing categorical factorization equivalence: `evaluation_functor`
constructs a functor from the kernel category of `project rule` to the discrete
category of outcomes, with object map exactly `evaluate rule`. The fixed gate
contract checks this statement alongside the ordinary frame law. Admission
and the shared pilot consume the pure module, preserving the repository's
qawāʿid → types → categories dependency direction.

Scoped equivalence is equality of these dependencies. The frame theorem
preserves the exact observation outcome. An append theorem allows new rows
that fail both exact queries. A new row that matches either query must be
accounted for even if the prior outcome depended only on an old positive row.

The dependency list is complete for this evaluator. It covers the relevant
query sets, both signs, the exception priority and fallback, and all scoped
pins. Its queries inspect the supplied rows directly. Further evidence
derivations, transitive source authority, and authentication are outside this
synthetic evaluator. Any evaluator that adds such operations needs its own
dependency proof.

## Loss witnesses

- Adding a matching positive exception preserves every original report and the
  whole support summary while changing the result from positive support to an
  exception. Lean disproves factorization through the structured core.
- A second occurrence has the same versioned kind and a different structured
  target. It is outside the original rule's scope. Lean disproves
  factorization through the kind.
- An exception can yield the same outcome before and after a contrary support
  report is added. The dependencies still differ.
- An unrelated appended report with a revised snapshot can preserve scoped
  equivalence while ACT-01 rejects the old exact snapshot as stale.

The positive theorem proves exact observation equality within this fragment.
The coarse maps give no equality or approximation guarantee for the evaluator.
No quotient or replacement for ACT-01 receipt identity follows from this
relation.

## Information dependence does not fix an encoder's answer

The relabeling fixture has three Boolean coordinates: whether the encoder is
enabled, its relevant feature, and irrelevant noise. Its local projection is
`some feature` when enabled and `none` otherwise. The original encoder returns
the projected Boolean. The second encoder is the actual `Typed.mapRun`
construction with Boolean negation as its answer map.

The fixture instantiates
[`Usul.Cat.Typing.Reads.mapRun`](../../formal/lean/Usul/Cat/Typing.lean), proving
`Reads` in both directions. It also proves equality of the projections and
applicability, and factorization of both judgments through the same projection.
Nevertheless, their answers differ at every enabled situation: `some false`
becomes `some true`, and conversely. Both judgments remain `none` when disabled.
Varying noise affects neither encoder.

Thus `Reads` describes information dependence and applicability. Even an
isomorphism in the category of encoders does not establish equality of their
answers. An answer-preservation claim needs its own equation or an explicitly
chosen answer map. The existing frame theorem supplies such an equality for
the one fixed report evaluator; it does not identify two differently labeled
evaluators.

## Supplied cases do not determine an unseen feature class

The second fixture has four situations `(feature, noise)`. Its known list is
nonempty and contains both noise variants of `feature = false`, each with
answer `true`. Lean checks consistency of that actual list, both as a Boolean
test and as the `FactorsOn` proposition. Neither situation with
`feature = true` appears in the known feature classes.

For Boolean parameters `knownValue` and `unseenValue`, the candidate extension
is defined on every situation:

\[
H_{k,u}(f,n)=
\begin{cases}
k & f=\mathrm{false},\\
u & f=\mathrm{true}.
\end{cases}
\]

Every candidate factors globally through the feature projection, independently
of noise. It agrees with the supplied list exactly when `knownValue = true`.
Consequently, both \(H_{\mathrm{true},\mathrm{false}}\) and
\(H_{\mathrm{true},\mathrm{true}}\) factor and agree with every known case,
while disagreeing on each situation in the unseen feature class. The fixture
also directly instantiates `Usul.Cat.unattested_free` from
[`Usul.Cat.Factor`](../../formal/lean/Usul/Cat/Factor.lean): either Boolean answer
has a compatible factoring extension.

This is an underdetermination result about the supplied cases. It does not
prevent an independently justified rule from classifying a new case. The
source, rule, and premises for that classification must be supplied separately;
consistency and the existence of a mathematical extension provide no admission
or source authority.

## Reproduce

```sh
npm --prefix formal/quint ci
make ida-projection
```

The gate compiles fixed Lean statements, audits the compiled axiom dependencies,
and compares an independent Quint model. Its output contains four families:

| Family | Finite inputs | Rows | Output cells |
|---|---|---:|---:|
| Report evaluation and scope | Two fallback settings, fifteen scope shapes, sixteen polarity masks, six report-list variants | 2,880 | 28,800 |
| Snapshot pairs | Two fallback settings and two independent sixteen-mask snapshots | 512 | 2,048 |
| Output relabeling | Enabled, feature, and noise Booleans | 8 | 64 |
| Unattested feature | Known-value, unseen-value, feature, and noise Booleans | 16 | 128 |
| **Total** | | **3,416** | **31,040** |

The original scope and report families remain intact. The added relabeling
family compares the actual projections, applicability, and optional answers.
The extension family includes candidates that disagree with the known list as
well as the two distinct globally factoring candidates that agree with it.

The gate requires 35 named proof obligations and witnesses, including fifteen
new inference-boundary theorems, and fifteen corresponding fixed boundary
wrappers. Two controls replace the terminal boundary propositions with `True`
and require the unchanged wrappers to reject them. Seven malformed-export
controls check row identity, order, value encoding, completeness, and trace
success.

Four Quint tests cover the report dependencies, scope and fallback, output
relabeling, and unattested feature. Nine weakened models must typecheck and
then fail their intended assertion. The original seven remove a hidden
exception, ignore predicate version or participant identity, treat absence as
a negative report, collapse an occurrence, skip scope, or equate equal
answers. The two added models reuse the old answer merely because projections
are equal, or force the unseen feature's answer to the known-feature value.
These changes affect the computed answers, not just an acceptance flag.

The replay records source hashes, the checked revision, and both outputs in
`.cache/ida-projection/`. Its acceptance evidence applies to that exact source
revision and declared finite domain.

[ACT-04](ida-semantics.md) establishes fixed-history interpretation and
satisfaction under substitution for the synthetic fragment. Its named sourced
interpretation and migration obligations remain open. [ACT-05](ida-admission.md)
reconstructs and revalidates applications against supplied premise certificates,
their exact bindings, and independent grants before issuing a new receipt.
External source authentication retains its separate ingestion-adapter contract.
These ACT-03 controls do not complete the full ACT-08 core exit; completion
still requires the remaining accepted obligations and evidence at the actual
integration head.
