# Clifford-Even Rotation Geometry as a Non-Authoritative Research Substrate

## Purpose

This note brings the Clifford-even finite-field program into the deontic-circuits research repository without changing the authority model of the deontic harness.

The deontic kernel remains responsible for admissibility, tier discipline, closure, defeat/blocking semantics, quarantine, and derivation traces. Clifford algebras, finite-field rotation groups, quadratic forms, and angle invariants are **not** sources of normative facts. They are an optional algebraic substrate for experiments in exact finite-state representation, symmetry, invariance, and associative transformation composition.

The integration rule is simple:

> Algebraic geometry may test or organize representations of a deontic circuit. It may not manufacture, strengthen, weaken, or defeat a normative claim merely because an algebraic invariant holds.

## Why this belongs in the project

A deontic circuit is already modeled as a finite, typed, inspectable structure. That makes several algebraic research questions natural:

1. Can finite circuit states or selected machine metadata be embedded into finite quadratic spaces without loss of the discrete facts that matter?
2. Can equivalence-preserving transformations be represented by an associative operator calculus rather than ad hoc rewrite tables?
3. Can exact invariants detect accidental representation drift across migrations, canonicalizations, or independent checker implementations?
4. Can symmetry actions help distinguish representational changes from semantic changes?
5. Can finite-field fixtures provide small exhaustive laboratories for checking transformation laws before any production use?

The Clifford-even construction is useful here because the even Clifford algebra is associative at every rank, while its rotor groups act by quadratic-form-preserving transformations.

## Mathematical substrate

Let $(V,Q)$ be a nondegenerate quadratic space over a field $k$ with $\operatorname{char}(k)\neq 2$. Write

$$
B(u,v)=\frac{1}{2}\bigl(Q(u+v)-Q(u)-Q(v)\bigr)
$$

for the associated symmetric bilinear form.

For non-null $u,v\in V$, define the angle invariant

$$
s(u,v)=1-\frac{B(u,v)^2}{Q(u)Q(v)}.
$$

Over the real numbers this is the squared sine of the angle between $u$ and $v$. Over finite fields it remains an exact algebraic invariant of relative orientation.

Write $Cl(V,Q)$ for the Clifford algebra and $Cl^+(V,Q)$ for its even subalgebra.

### Structural recursion

If $e_0\perp V$ and $Q(e_0)=a\neq 0$, then

$$
Cl^+(V\oplus ke_0,Q\perp\langle a\rangle)
\cong
Cl(V,-aQ).
$$

The factor $-a$ must be tracked because it may change the discriminant square class and hence the Witt class.

### Pseudoscalar control

For an orthogonal basis $e_1,\dots,e_n$, let

$$
\omega=e_1e_2\cdots e_n.
$$

Then

$$
\omega^2=(-1)^{n(n-1)/2}\prod_i Q(e_i).
$$

For $Q=\sum_i x_i^2$, this reduces to

$$
\omega^2=(-1)^{n(n-1)/2}.
$$

For even $n$, the square class of $\omega^2$ determines whether the center of $Cl^+$ splits or becomes a quadratic field extension.

### Finite-field normal form

For $p\equiv 3\pmod 4$ and $Q=\sum_i x_i^2$,

$$
Cl^+(\mathbb F_p^n,Q)\cong
\begin{cases}
M_{2^{(n-1)/2}}(\mathbb F_p), & n\equiv 1,3 \pmod 4,\\
M_{2^{(n-2)/2}}(\mathbb F_{p^2}), & n\equiv 2 \pmod 4,\\
M_{2^{(n-2)/2}}(\mathbb F_p)\times M_{2^{(n-2)/2}}(\mathbb F_p), & n\equiv 0 \pmod 4.
\end{cases}
$$

The classification follows from the center computation together with the triviality of the Brauer group of a finite field.

## The $\mathbb F_7$ laboratory

The first exact test field is $\mathbb F_7$, where $-1$ is a quadratic non-residue.

For

$$
Q(x,y,z)=x^2+y^2+z^2,
$$

one has

$$
Cl^+(\mathbb F_7^3,Q)\cong M_2(\mathbb F_7).
$$

The underlying quadratic space can be identified with

$$
\mathfrak{sl}_2(\mathbb F_7)
=
\{X\in M_2(\mathbb F_7):\operatorname{tr}(X)=0\}
$$

equipped with

$$
Q(X)=-\det(X).
$$

Under a chosen isometry, the rotor action becomes matrix conjugation:

$$
X\longmapsto RXR^{-1},
\qquad
R\in SL_2(\mathbb F_7).
$$

The action preserves $Q$, and the angle invariant becomes

$$
s(X,Y)
=
1-
\frac{\operatorname{tr}(XY)^2}
{4Q(X)Q(Y)}.
$$

Every element of $\mathbb F_7$ is attained by this invariant on some pair of non-null vectors. This makes the rank-3 case a compact exhaustive fixture for algebraic experimentation.

## Appropriate uses inside deontic circuits

### 1. Representation-invariance tests

Suppose a research encoding maps a finite collection of circuit states into a quadratic space. A transformation represented by a rotor can be required to preserve:

- $Q(v)$,
- $B(u,v)$,
- the angle invariant $s(u,v)$,
- and any explicitly declared discrete labels carried alongside the vector representation.

This can detect representational drift while leaving the semantic graph authoritative.

### 2. Associative transformation composition

Experimental transformations can be composed in $Cl^+$ or in an equivalent matrix model:

$$
R_{\mathrm{total}}=R_m\cdots R_2R_1.
$$

Associativity makes the transformation trace deterministic. This may be useful for canonicalization experiments, reversible normalization passes, or independent replay evidence.

### 3. Symmetry and equivalence experiments

A group action can test whether two encodings differ only by a declared symmetry. If so, the harness may record an **algebraic equivalence finding**.

Such a finding is diagnostic evidence only. It is not a deontic equivalence unless the deontic kernel independently proves that the corresponding domain facts and warrant paths are equivalent.

### 4. Small exhaustive fixtures

Finite fields permit exhaustive enumeration. The $\mathbb F_7$ rank-3 model is therefore suitable for:

- checking group actions,
- validating invariant formulas,
- checking serialization/canonicalization routines,
- cross-checking implementations in different languages,
- and generating deterministic regression fixtures.

## Authority firewall

The following rules are mandatory.

### The algebraic substrate MAY

- encode explicitly selected research metadata;
- apply declared finite-field transformations;
- emit invariant values and transformation traces;
- emit equivalence candidates;
- provide independent deterministic evidence;
- detect implementation or representation drift.

### The algebraic substrate MUST NOT

- create an \`AffectRoot\`, \`Warrant\`, \`HukmClassification\`, or \`Defeater\`;
- promote candidate facts into canonical facts;
- assign warrant tiers;
- infer normative strength from a norm, inner product, angle invariant, orbit, or group order;
- identify orthogonality with opposition;
- identify geometric proximity with semantic similarity;
- identify a symmetry orbit with deontic equivalence without an independent kernel proof;
- bypass quarantine or defeat semantics;
- become an implicit scoring model for fiqh judgments.

No geometric or algebraic invariant is itself a warrant.

## Proposed architectural placement

\`\`\`text
source material / scholarly notes
        ↓
LLM-assisted candidate extraction
        ↓
canonical database fact graph
        ↓
deterministic deontic kernel
        ↓
accepted derivations + traces
        │
        └──────────────┐
                       ↓
            optional algebraic research lane
            finite-field encodings / Cl+ operators
            invariants / symmetry / replay evidence
                       ↓
              research findings only
\`\`\`

The arrow into the algebraic lane comes from already explicit data or test fixtures. There is no authority arrow back into canonical normative data.

## Candidate interface

A later implementation should stay deliberately narrow:

\`\`\`text
encode_research_state(input) -> algebraic_state
apply_isometry(algebraic_state, operator) -> algebraic_state
invariant_signature(state_or_pair) -> signature
compare_signatures(left, right) -> algebraic_finding
replay_transform(trace) -> verified | mismatch
\`\`\`

Each result should carry provenance:

- field identifier,
- quadratic-form identifier,
- basis / encoding version,
- operator identifier,
- input record hashes,
- output invariant values,
- implementation version.

## Research acceptance gates

Before any algebraic lane is connected to the application runtime:

1. Specify exactly which non-normative data are encoded.
2. Prove that the encoding is injective on the declared domain, or document the quotient being taken.
3. State every invariant the transformation is expected to preserve.
4. Provide exhaustive finite-field fixtures for the smallest supported parameter set.
5. Cross-check at least one independent implementation.
6. Demonstrate that removing the algebraic lane leaves every normative derivation unchanged.
7. Add a fail-closed test preventing algebraic findings from being accepted as warrants or hukm evidence.

## Relationship to the deontic kernel

This work does **not** replace Boolean or graph-based deontic reasoning. It addresses a different layer.

The deontic kernel answers questions such as:

- Is this warrant admissible?
- Does this derivation respect tier discipline?
- Is this claim blocked or defeated?
- What is the minimal accepted warrant path?

The Clifford-even lane can answer questions such as:

- Did an experimental representation-preserving transform change a declared invariant?
- Are two finite encodings related by a declared symmetry?
- Can a transformation sequence be replayed exactly?
- Do two independent implementations produce the same finite algebraic evidence?

The distinction should remain explicit in code, schema, documentation, and review.

## Next research tasks

1. Add a machine-readable $\mathbb F_7$ rank-3 fixture containing the seven attainable angle-invariant witnesses.
2. Add a tiny independent reference implementation of $Q$, $B$, the angle invariant, and the $SL_2(\mathbb F_7)$ conjugation action.
3. Define an \`AlgebraicFinding\` research schema separate from canonical deontic facts.
4. Test whether the substrate adds useful migration or replay evidence before considering any deeper integration.
5. Keep the full Clifford-even paper as a mathematical reference, while this repository note remains focused on the deontic-circuit boundary.
