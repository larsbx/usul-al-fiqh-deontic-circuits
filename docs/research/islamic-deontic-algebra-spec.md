# Islamic Deontic Algebra (IDA)
## Concise specification v0.1

**Status:** proposed contract, grounded in `larsbx/usul-al-fiqh-deontic-circuits` at `a52f1e492cd96cb82f08d190c19aad9ae6f2044c`. Requirements below are not a claim of completed implementation.

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

Each result carries its value or diagnostic witnesses. A target is a structurally checked expression: `perform(action)`, `omit(action, opportunity)`, or `affect(quality, concerns)`. An action carries a qualified operation name, its ordered signature of named reference sorts, and operands that match every declared role and sort. Qualified operand references participate directly in target identity. An omission includes its named occurrence, named clock, and strictly ordered opportunity bounds; it accepts an action, not an arbitrary target. An affect carries its quality and typed object. Context supplies additional object facts, capacity, voluntary control, intention, history, agency, and exceptions required by the selected rule. The judgment subject is a separate coordinate. An operation can also carry participant roles, including a performer or payer, but structural checking does not establish that a person reference and the opaque subject identifier denote the same person. A perform expression does not establish actual occurrence. Structural checking does not admit the supplied operation signature under a source profile, resolve its references, or establish that the opportunity is available to the subject. These are separate obligations. Full structural equality is used without automatic synonym resolution or event identification. Numeric fixture selectors are not target identities.

The [candidate act reference](ida-act-reference.md) distinguishes source mentions, versioned operation kinds, qualified act descriptions, and conduct occurrences. It records proposed parameter kinds and unresolved modeling decisions without admitting an operation signature or assigning a ruling. A definition version can participate in the existing qualified operation symbol; enforcing a unique source-approved signature for that symbol remains a profile obligation.

Every derivation records source hashes and passage locators, interpretation and profile versions, rule applications, and implementation revision.

### 5. Inference and composition

- **Application:** discharge the rule’s typed premises, conditions, capacity requirements, and absence of impediments.
- **Restriction:** specialize context while retaining provenance; recheck applicability and exception guards before carrying the conclusion forward.
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

[1]: https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/a52f1e492cd96cb82f08d190c19aad9ae6f2044c/formal/lean/Usul/Hukm.lean
[2]: https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/a52f1e492cd96cb82f08d190c19aad9ae6f2044c/docs/architecture/judgement.md
[3]: https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/a52f1e492cd96cb82f08d190c19aad9ae6f2044c/docs/architecture/hukm-interval-verdicts.md
[4]: https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/a52f1e492cd96cb82f08d190c19aad9ae6f2044c/docs/architecture/deontic-circuits-harness.md
[5]: https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/a52f1e492cd96cb82f08d190c19aad9ae6f2044c/docs/research/agency-pilot.md
