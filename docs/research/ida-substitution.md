# ACT-02 typed substitution and premise contexts

This slice implements the [ACT-02 roadmap](ida-act-classification-roadmap.md#act-02--prove-the-context-and-substitution-calculus)
over the [ACT-01 ground context foundation](ida-context-foundation.md). Its
[Lean core](../../formal/lean/Usul/Typing/IDASubstitution.lean) and
[categorical adapter](../../formal/lean/Usul/Cat/IDASubstitution.lean) are
Mathlib-free.

## Substitution and grounding

A variable is a typed position in a finite list of reference sorts. Terms
are variable positions or well-formed rigid references. A substitution
from a context `Δ` to a context `Γ` supplies a term over `Δ` for each
variable of `Γ`, at that variable's declared sort. The raw term decoder
rejects an out-of-range variable and a mismatched rigid-reference sort.
A grounding supplies terms over the empty variable context.

Descriptions take an exact registered ACT-01 definition, its resolved named
role signature, and arguments indexed by those sorts. `Schema.ofResolved`
uses an actual registry resolution proof. Reindexing leaves the whole schema
fixed and applies one substitution at each argument position. Two positions
that share a term still share its image. Ground actions satisfy the existing
`Action.WellFormed` contract, including the ordered role signature.

Schematic inquiries also reindex the accountable person and performer.
The inquiry frame fixes question, legacy scope coordinates, clock and
opportunity, and policy pins. A grounded inquiry retains that frame and
offers a projection into the existing `Context.Inquiry`. The ACT-01 resolver
then checks the concrete scope and performer membership. One synthetic
repayment/omission fixture exercises that path.

## Premise arrows

Formulas contain signed typed atoms and conjunction. A predicate is pinned to
an exact version in a well-formed ACT-01 vocabulary. The rules are assumption,
conjunction introduction, and the two conjunction eliminations. Opposite
polarities are distinct syntax. The calculus can carry both while leaving an
unrelated atom underivable.

An arrow carries a substitution and a proof that its source premises derive
every substituted target premise. Lean proves substitution admissibility
and simultaneous cut for the stated rules. The executable arrow checker is
equivalent to this premise obligation. Its decision procedure checks whether
all target conjuncts appear among the available atoms after substitution.
A fixture composes two nonidentity premise arrows.

The categorical adapter constructs the substitution category and the
premise-context category, with a functor that forgets the premises.
Descriptions and formulas reindex as contravariant functors to small types.
The category's arrow equality uses proof-irrelevant admissibility. There
is no receipt or evidence argument to these arrows. Any proof-relevant
transport certificates belong to a separate layer.

## Reproduce

```sh
npm --prefix formal/quint ci
make ida-substitution
```

The gate builds fixed Lean statement contracts, audits compiled axiom
dependencies, and compares the actual Lean observations against an independent
[Quint model](../../formal/quint/ida-substitution.qnt). The finite abstraction
uses two person variables, a rigid obligation, three rigid person constants
including two with the same local name, two predicate versions, and nine
premise supplies. Both models enumerate 2,401 pairs of substitutions and
441 premise-arrow checks. Their 19,649 compared cells cover invalid inputs,
both grounded role references, the obligation, the accountable subject and
performer, both formula arguments, and direct versus staged equality.
Adverse model controls exercise wrong sorts, changed rigid debt, reversed
composition, omitted premises, and conflated namespaces.

The exact-head receipt records source hashes, compiled declarations, test
outcomes, and both output tables under `.cache/ida-substitution/`.

[ACT-03](ida-projection.md) uses the grounded inquiry to prove an exact
report dependency projection and concrete information-loss witnesses. ACT-04 must supply interpreted
histories and prove satisfaction and grounding commute for the supported
language. ACT-05 must reconstruct concrete source premises and revalidate
admission under the existing source authority before issuing a new receipt.
