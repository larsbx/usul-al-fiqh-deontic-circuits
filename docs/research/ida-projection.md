# ACT-03 scoped projection and information loss

This slice gives the [ACT-03 roadmap](ida-act-classification-roadmap.md#act-03--account-for-forgetting-and-scoped-equivalence)
a complete dependency example over the synthetic repayment inquiry grounded in
[ACT-02](ida-substitution.md). The input type requires an ACT-01 well-formed
snapshot. The evaluator reads report rows and produces synthetic observation
statuses. The witness checks structure. Authentication, admission, source
fidelity, and juristic interpretation have separate contracts.

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

## Reproduce

```sh
npm --prefix formal/quint ci
make ida-projection
```

The gate compiles fixed Lean statements, audits the compiled axiom dependencies,
and compares an independent Quint truth table and report-query model. It checks
2,880 scope and report cases and 512 pairs of snapshots, for 30,848 output
cells. The finite cases vary both signs of each query, six report-list variants,
two fallback settings, and fifteen scope shapes. The seven weakened models
remove a hidden exception, ignore predicate version or participant identity,
treat absence as a negative report, collapse an occurrence, skip scope, or
equate equal answers. The replay records source hashes and both outputs in
`.cache/ida-projection/`.

ACT-04 still needs an interpreted semantic domain and substitution satisfaction
laws. ACT-05 must reconstruct, authenticate, and revalidate concrete evidence
before issuing a new receipt.
