# Islamic Deontic Algebra (IDA)
## Concise specification v0.1

**Status:** development contract, originally grounded in `larsbx/usul-al-fiqh-deontic-circuits` at `a52f1e492cd96cb82f08d190c19aad9ae6f2044c`. The context theory and M16 roadmap are accepted design as of 2026-11-09. Implementation and proof completion are tracked by their individual module and package evidence.

### 1. Purpose and scope

IDA represents source-linked Islamic legal judgments, composes their explicit conditions, and verifies derivations and state transitions. The initial doctrinal scope is named **Ḥanbalī source profiles**, preserving reported alternatives. The kernel establishes consequences of an encoded profile; source fidelity and application refinement carry independent evidence.

### 2. Semantic carrier

The core taklīfī carrier is:

| Code | Ruling | Demand | Binding |
|---|---|---|---|
| W | Wājib | Do | Yes |
| N | Mandūb / mustaḥabb | Do | No |
| M | Mubāḥ | Choice | No |
| K | Makrūh | Refrain | No |
| Ḥ | Ḥarām | Refrain | Yes |

These are distinct types of normative status. The existing carrier defines them through consequences of doing and omitting; reward is conditioned on obedience, and punishment means liability, not guaranteed infliction. [Carrier][1]

**Separate answer types** represent validity, causes, conditions, impediments, legal effects, and liability questions. Evidence grade is another axis. Boolean applicability and permission projections retain their underlying typed judgments. [Judgments][2]

### 3. Algebra

Use the order **Ḥ < K < M < N < W**, meaning increasing favor toward doing. Define `x ∧ y = min(x,y)` and `x ∨ y = max(x,y)` in that order. These compute bounds; evidence resolution follows §5.

The omission operation is:

`σ(W)=Ḥ; σ(N)=K; σ(M)=M; σ(K)=N; σ(Ḥ)=W.`

Require the bounded distributive lattice laws, `σ²=id`, order reversal, and De Morgan laws. The scale has no addition, averaging, or distance. Applying σ to an actual omission requires a specified act, opportunity, time, and interpretation; arbitrary contrary acts require their own rules. [Carrier][1]

A partially specified ruling is a nonempty subset of the carrier; convex subsets may use intervals. For example, “non-forbidden” permits `{K,M,N,W}`; it does not select M. Explicit `no_ruling`, suspension, and unresolved conflict remain outside the five rulings. [Partial verdicts][3]

### 4. Judgment contract

```text
Judgment = {
  question, subject, target, context, time, profile,
  answer : Answer(question),
  evidence_grade, premises, derivation
}
Result = Derived | Unresolved | Conflict | OutOfScope
```

Each result carries its value or diagnostic witnesses. Targets distinguish behavioral acts from affective states. Context supplies objects, capacity, voluntary control, intention, history, agency, and exceptions required by the selected rule. Every derivation records source hashes and passage locators, interpretation and profile versions, rule applications, and implementation revision.

The [accepted context theory](ida-context-theory.md) makes those contextual
obligations explicit. It separates typed schematic variables, factual situations,
evidence, source profiles, time/history, and authority/resource state. Current
IDA records bind context and time identifiers; their semantic interpretation,
refinement, and transport interfaces follow the accepted design and await implementation.
A derivation under stated assumptions and admission of those assumptions are
separate checks.

### 5. Inference and composition

- **Application:** discharge the rule’s typed premises, conditions, capacity requirements, and absence of impediments.
- **Restriction:** reindex under a declared context map while retaining provenance and stating the required preservation law. Restriction of an implemented `Usul.Cat.Sheaf` section narrows its domain and preserves values at retained situations.
- **Reevaluation:** changes in facts, evidence, time, or authority recheck applicability and exception guards before carrying a conclusion forward. More evidence does not by itself preserve a defeasible conclusion.
- **Conjunction:** intersect constraints on the same question, subject, target, context, time, and profile/version. An empty intersection produces a conflict witness.
- **Alternatives:** retain named positions separately. A profile may resolve them only through an explicit, source-linked precedence rule.
- **Exceptions and defaults:** apply declared guards and defeat rules; insufficient evidence produces an unresolved result.
- **Action structure:** represent sequencing, alternative duties, and collective discharge over actions and histories. Each requires a separate semantics and proof contract.

Only premises admitted under the selected profile enter its derivations. Candidate interpretations and quarantined records retain their status. LLMs may propose records and explanations; the deterministic kernel checks admission and inference. [Authority boundary][4]

### 6. Operational slice

Start with **one principal, two agents, one task**: scoped permissions, joint action, revocation, knowledge, withdrawal, and execution receipts. Keep immediate and knowledge-dependent revocation profiles separate. Mixed-knowledge composition remains explicitly candidate. Historical receipts persist; at-most-once execution is a declared workflow restriction. [Agency pilot][5]

### 7. Acceptance contract

Develop **Lean and Quint first**. Lean must prove algebraic laws, typing and provenance invariants, and declared history properties. Quint must check operational invariants within recorded bounds. Require independent transition comparison, semantic negative controls, compiled axiom auditing, and reproducible receipts bound to exact revisions.

Acceptance cases cover all five rulings, partial permission, missing premises, incompatible positions, invalid source references, capacity, and revocation. Record source correspondence, Lean proofs, bounded model checks, cross-model agreement, and runtime refinement independently.

### 8. Act classification and categorical transformations

The [detailed M16 roadmap](ida-act-classification-roadmap.md) records the accepted
design for the typed act registry, context/substitution laws, information-loss and scoped
equivalence contracts, supported interpretations, and evidence-bearing judgment
transport. The [ACT-00 integration](ida-target-integration.md) reconciles #140's
structured targets with the mainline IDA judgment and derivation machinery and
landed through [#144](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/pull/144)
at `ca38f35e32e23169e852fe7d5f8f8b1f3734ed0e`. Historical receipts retain their
recorded revisions and scopes. Source mentions, kinds, qualified
descriptions, and occurrences remain distinct, as do classification relations
and legal judgments.

Reuse the existing `Usul.Cat` factorization, typed-encoder, scale-duality, and
institution interfaces. Category laws do not admit source interpretations,
identify distinct occurrences, or preserve judgments across arbitrary changes
of profile or context. Compound descriptions and process/resource composition
are separate, conditional milestones. Those later contracts each have a separate acceptance gate.

The [context theory](ida-context-theory.md) refines the planned ACT-02/ACT-03/ACT-05
contracts and conditional process/indexing work within M16. Its premises,
consistency conditions, evidence revisions, temporal histories, and forgetting
witnesses are required obligations, with explicit countermodels and acceptance
criteria; this specification does not claim their implementation.

[1]: https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/a52f1e492cd96cb82f08d190c19aad9ae6f2044c/formal/lean/Usul/Hukm.lean
[2]: https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/a52f1e492cd96cb82f08d190c19aad9ae6f2044c/docs/architecture/judgement.md
[3]: https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/a52f1e492cd96cb82f08d190c19aad9ae6f2044c/docs/architecture/hukm-interval-verdicts.md
[4]: https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/a52f1e492cd96cb82f08d190c19aad9ae6f2044c/docs/architecture/deontic-circuits-harness.md
[5]: https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/a52f1e492cd96cb82f08d190c19aad9ae6f2044c/docs/research/agency-pilot.md
