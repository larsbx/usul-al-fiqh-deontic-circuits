# ACT-03 scoped projection and information loss

This slice gives the [ACT-03 roadmap](ida-act-classification-roadmap.md#act-03--account-for-forgetting-and-scoped-equivalence)
a complete dependency example over the synthetic repayment inquiry grounded in
[ACT-02](ida-substitution.md). The input type requires an ACT-01 well-formed
snapshot. The evaluator reads report rows and produces synthetic observation
statuses. The witness checks structure. Authentication, admission, source
fidelity, and juristic interpretation have separate contracts.

The answer-bearing controls use the existing five-valued `Hukm` carrier. They
replace the earlier Boolean-output examples: output relabeling can preserve
what an encoder reads while changing its ruling value, and consistent supplied
cases can leave an unattested feature class undetermined. A third control
checks the actual fivefold lattice and its duality. These are synthetic
assignments of ruling values; they introduce no source judgment or admission.

## Fivefold answers and Boolean checks

The carrier is the one defined in
[`Usul.Hukm`](../../formal/lean/Usul/Hukm.lean) and used by
[`Usul.IDA`](../../formal/lean/Usul/IDA.lean):

| Status | Meaning | Total ruling wire code | `sigma` |
|---|---|---:|---|
| `haram` (H) | Forbidden | 0 | `wajib` |
| `makruh` (K) | Disliked | 1 | `mandub` |
| `mubah` (M) | Permitted | 2 | `mubah` |
| `mandub` (N) | Recommended | 3 | `makruh` |
| `wajib` (W) | Obligatory | 4 | `haram` |

These codes serialize five distinct constructors. They are not numerical
scores. In this repository's declared order,
\(H<K<M<N<W\), meet and join are the lower and upper bounds, and `sigma`
reverses that order. H and W are lattice bounds, not Boolean false and true.
The [carrier companion](../plain-english/Usul/Hukm.md) explains the doing/leaving
profiles behind this particular order; the
[IDA companion](../plain-english/Usul/IDA.md) separates its algebra from partial
answers and concrete case admission.

Boolean guards, feature tests, membership bits, and proposition checks retain
their own types. They do not replace `Hukm`. In particular, `some mubah` is an
applicable permitted answer, while `none` records an inapplicable encoder.
Missing evidence, suspension, and conflict also have their own representations;
none is a sixth ruling or another meaning of `mubah`. The report evaluator's
observation statuses below are diagnostics about supplied reports, not the
five ruling values.

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

The relabeling fixture has an enabled flag, a `Hukm` feature, and irrelevant
Boolean noise. Its local projection is `some feature` when enabled and `none`
otherwise. The original encoder returns that ruling value. The second encoder
uses the actual `Typed.mapRun` construction with the existing `IDA.sigma` map.

The fixture instantiates
[`Usul.Cat.Typing.Reads.mapRun`](../../formal/lean/Usul/Cat/Typing.lean), proving
`Reads` in both directions. It also proves equality of the projections and
applicability, and factorization of both judgments through the same projection.
For an enabled situation, the answers are equal exactly when its feature is
`mubah`. The other four values change according to the table above. Both
judgments remain `none` when disabled, and varying noise affects neither
encoder. Thus the control retains the fixed point of the actual fivefold
duality instead of treating it as Boolean negation.

Thus `Reads` describes information dependence and applicability. Even an
isomorphism in the category of encoders does not establish equality of their
answers. An answer-preservation claim needs its own equation. An algebraic
translation additionally needs its stated operation and variance laws.
[`Usul.Cat.sigmaIso`](../../formal/lean/Usul/Cat/Scales.lean) expresses the
existing duality as an isomorphism from the ruling-order category to its
opposite: it reverses arrows and exchanges meet with join. An arbitrary
`mapRun` function is not thereby a map preserving those algebraic laws.

The existing frame theorem supplies exact equality for one fixed report
evaluator. Neither that theorem nor `Reads.mapRun` establishes a valid new
inquiry, an occurrence of omission, or the evidence needed to apply a ruling
to an actual omitted act. Those require their own action, opportunity, time,
profile, and admission contracts.

## Supplied cases do not determine an unseen feature class

The second fixture has four situations `(feature, noise)`. Its known list is
nonempty and contains both noise variants of `feature = false`, each with
answer `wajib`. Lean checks consistency of that actual list, both as a Boolean
test and as the `FactorsOn` proposition. Neither situation with
`feature = true` appears in the known feature classes.

For parameters `knownValue` and `unseenValue` in `Hukm`, the candidate extension
is defined on every situation:

\[
H_{k,u}(f,n)=
\begin{cases}
k & f=\mathrm{false},\\
u & f=\mathrm{true}.
\end{cases}
\]

Every candidate factors globally through the feature projection, independently
of noise. There are 25 candidate functions. Exactly five agree with the supplied
list: those with `knownValue = wajib`, one for each possible unseen ruling.
Consequently, both \(H_{W,M}\) and \(H_{W,N}\) factor and agree with every known case,
while disagreeing on each situation in the unseen feature class. The fixture
also directly instantiates `Usul.Cat.unattested_free` from
[`Usul.Cat.Factor`](../../formal/lean/Usul/Cat/Factor.lean), with its answer
parameter typed as `Hukm`: every one of the five ruling values has a compatible
factoring extension.

This is an underdetermination result about the supplied cases. It does not
prevent an independently justified rule from classifying a new case. The
source, rule, and premises for that classification must be supplied separately;
consistency and the existence of a mathematical extension provide no admission
or source authority. Five mathematically compatible extensions do not establish
five legally admissible answers to an actual inquiry.

## The existing lattice is not Boolean

The IDA carrier satisfies the bounded distributive lattice laws and the De
Morgan equations

\[
\sigma(h\wedge k)=\sigma(h)\vee\sigma(k),\qquad
\sigma(h\vee k)=\sigma(h)\wedge\sigma(k).
\]

Its involution is not a Boolean complement. The concrete middle-value control
uses the actual `IDA.meet`, `IDA.join`, and `IDA.sigma` operations:

\[
\sigma(M)=M,\qquad
M\wedge\sigma(M)=M\ne H,\qquad
M\vee\sigma(M)=M\ne W.
\]

More strongly, in this five-element chain a value has any lattice complement
exactly when it is H or W. The other three values cannot satisfy both complement
equations with any candidate partner. The finite algebra family covers all 25
pairs of ruling values.

A Boolean projection can also discard deontic distinctions without producing
an error in its own Boolean type. The existing `Hukm.binding` function returns
the same flag for `mandub` and `mubah`, although these are distinct rulings.
The new control proves that concrete loss. The full carrier must be retained
where a fivefold classification is claimed; a Boolean view needs a declared
purpose and preservation contract.

## Reproduce

```sh
npm --prefix formal/quint ci
make ida-projection
```

The gate compiles fixed Lean statements, audits the compiled axiom dependencies,
and compares an independent Quint model. Its output contains five families:

| Family | Finite inputs | Rows | Output cells |
|---|---|---:|---:|
| Report evaluation and scope | Two fallback settings, fifteen scope shapes, sixteen polarity masks, six report-list variants | 2,880 | 28,800 |
| Snapshot pairs | Two fallback settings and two independent sixteen-mask snapshots | 512 | 2,048 |
| Output relabeling | Two enabled states, five `Hukm` features, two noise states | 20 | 160 |
| Unattested feature | Five known-feature ruling values, five unseen-feature ruling values, two feature states, two noise states | 100 | 800 |
| Fivefold algebra | All pairs of the five ruling values | 25 | 200 |
| **Total** | | **3,537** | **32,008** |

The original scope and report families remain intact. The added relabeling
family compares the actual projections, applicability, and optional answers.
The extension family includes candidates that disagree with the known list as
well as the two explicit globally factoring candidates that agree with it. The
algebra family evaluates the actual operations and complement predicates.

The gate requires 41 named proof obligations and witnesses, including 21
inference-boundary theorems, and 21 corresponding fixed boundary wrappers.
Three controls replace the terminal boundary propositions with `True`
and require the unchanged wrappers to reject them. Nine malformed-export
controls check row identity, order, value encoding, completeness, and trace
success.

Five Quint tests cover the report dependencies, scope and fallback, output
relabeling, unattested feature, and fivefold algebra. Twelve weakened models must typecheck and
then fail their intended assertion. The original seven remove a hidden
exception, ignore predicate version or participant identity, treat absence as
a negative report, collapse an occurrence, skip scope, or equate equal
answers. Two inference mutants reuse the old answer merely because projections
are equal, or force the unseen feature's answer to the known-feature value.
Three further mutants collapse ruling values to a binary answer, treat `mubah`
as absence, or incorrectly identify every `sigma` partner as a Boolean
complement. The last fault falsely accepts the interior pairs K/N and M/M as
complements; the actual meet and join equations reject them.

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
