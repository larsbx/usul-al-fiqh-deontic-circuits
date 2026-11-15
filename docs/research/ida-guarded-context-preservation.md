---
title: "Context Abstraction and Exact Scope in Islamic Deontic Algebra"
subtitle: "Typed targets and conditional omission semantics"
date: "2026-11-15"
lang: en
---

# Context Abstraction and Exact Scope in Islamic Deontic Algebra

*Typed targets and conditional omission semantics*

A companion paper in the IDA context-theory research series · 15 November 2026

**Formats and proofs:** [PDF](ida-guarded-context-preservation/ida-context-abstraction-paper.pdf) · [TeX source](ida-guarded-context-preservation/ida-context-abstraction-paper.tex) · [Generic Lean appendix](../../formal/lean/UsulTest/IDAGuardedContext.lean) · [Native omission witness](../../formal/lean/UsulTest/IDAOmissionGuardWitness.lean) · [Semantic adequacy proofs](../../formal/lean/Usul/Typing/IDAOmissionSemantics.lean) · [Independent contracts and controls](../../formal/lean/UsulTest/IDAOmissionSemantics.lean)

## Abstract

An abstraction can retain an answer while discarding the scope required for its application. We make this distinction precise for the accepted context theory of Islamic Deontic Algebra (IDA). Typed targets distinguish performed acts, omissions of acts over named opportunities, and affective qualities directed toward typed referents. A foundational conjunction operation compares seven scope coordinates before combining required premises. We prove that a projection preserves every exact scope test if and only if its fibers preserve the scope key. Joint preservation of scope and a computed answer requires both components to be constant on those fibers. Injectivity is necessary only when the projection acts on complete keys themselves, not on entire snapshots. A counterexample using the existing Lean omission evaluator shows that erasing an opportunity bound identifies a closed window with an open one and changes the observation outcome. The categorical interpretation uses the accepted substitution presheaves and kernel-groupoid factorization interface. We also prove conditional semantic adequacy: the covered negative outcome is equivalent to absence in an independently supplied event history under explicit exhaustiveness, report soundness, and observation guards. Countermodels distinguish these premises from structural coverage and payload authentication. The next proof step is to justify the premises from a separately specified event ledger and report adapter, while retaining the distinction between model-relative absence and a juristic conclusion.

**Keywords** · Islamic Deontic Algebra; context; typed acts; omission; categorical semantics; information loss; Lean

## 1. Exact scope and justified reuse

An answer can be reused after a representation change only under a preservation theorem appropriate to that change. We study this requirement as *justified reuse*. Type correctness, semantic soundness, exact answer equality, and current admission concern different relations. The accepted IDA context specification already distinguishes these four claims and gives each its own interface [[1](#reference-1)]. The result below makes their separation concrete at the boundary between information loss and the exact scope guard.

The general mathematics of factorization through a projection is established background. IDA already contains `Usul.Cat.factors_iff_exists` and `factors_iff_functor`, as well as a concrete ACT-03 projection theorem [[3](#reference-3), [4](#reference-4)]. The contributions here are the scope criterion, its joint application to typed answers, and a checked counterexample for opportunity information in IDA's actual observation computation. We then establish a conditional adequacy theorem for the native observation evaluator and isolate the assumptions connecting its reports to a separately supplied history. Information needed for exact scope, information needed for computation, and evidence of semantic truth remain distinct.

The companion manuscript *Typed Context and Conditional Soundness in Islamic Deontic Algebra* studies receipt-bound transport and a fixed-receipt, varying-history countermodel [[9](#reference-9)]. The present argument addresses a different boundary: whether a reduced representation retains enough information for the exact scope guard and the selected computation.

## 2. Typed targets and seven guarded dimensions

### Acts, omissions, and affects

The target language has the three disjoint forms

$$
\operatorname{perform}(a),\qquad
 \operatorname{omit}(a,o),\qquad
 \operatorname{affect}(z).
$$

An action $a$ contains an operation with a qualified name and declared ordered signature, together with named, typed operands. Structural validation requires the operands' role-and-sort list to equal that signature. Distinct roles remain distinct even when their arguments have the same reference sort. Swapping a resolved debtor and creditor is consequently a change of the represented action, not a harmless renaming of a bound variable [[2](#reference-2), [5](#reference-5)].

An opportunity $o$ contains a named occurrence, a named clock, an opening bound, and a closing bound. Its structural condition includes $o.\mathrm{opensAt}<o.\mathrm{closesAt}$. An omission target retains both the action and this opportunity. The identity law is

$$
\operatorname{omit}(a,o)=\operatorname{omit}(a',o')
 \quad\Longleftrightarrow\quad a=a'\ \land\ o=o'.
$$

Well-formedness states that the description has the required shape. It does not establish actual opportunity, capacity, nonperformance, or deliberate abstention.

An affect $z$ contains an affective quality and the typed referent that it concerns. Here *affect* means an affective quality, not a causal effect produced by an act. Its representation does not itself assert voluntariness, observability, responsibility, or a ruling. The accountable subject belongs to the inquiry context; further relations among that subject, the performer, or the experiencer must be stated by the supported interpretation. The existing Lean target language proves constructor disjointness and equality criteria for all three forms [[2](#reference-2)].

There is a material implementation boundary. The core supports all three target constructors, whereas the current `Substitution.Inquiry.toGround` constructs performance or omission according to its optional opportunity. It has no affect branch. Thus the accepted categorical architecture includes typed target integration, but the current ACT-02/04 inquiry pilot does not establish a general affect transport calculus [[5](#reference-5), [6](#reference-6)].

### The foundational scope key

Write the core scope key as

$$
k=(q,s,t,c,\tau,p,v),
$$

where the coordinates denote question, subject, target, context, time, interpretive profile, and profile version.

**Table 1. The seven foundational equality guards**

| Coordinate | Distinction retained by the guard |
| --- | --- |
| Question | Which inquiry is answered; richer judgment records additionally index its answer family. |
| Subject | Whose case is under consideration; the performer is separately represented in richer inquiries. |
| Target | The complete structured act, omission opportunity, or affect expression. |
| Context | The designated contextual scope. |
| Time | The designated temporal scope; richer records distinguish effective time and recording cutoff. |
| Interpretive profile | The interpretation under which the premises and answer are read. |
| Profile version | The specific revision of that interpretation. |

The implemented foundational operation is

$$
\operatorname{combine}(k_1,k_2,a,b)=
\begin{cases}
\operatorname{combineSame}(a,b),&k_1=k_2,\\
\mathrm{outOfScope},&k_1\ne k_2.
\end{cases}
$$

The existing `inScope_iff_all_fields` theorem identifies acceptance of this scope gate with equality in all seven coordinates. Equality is a prerequisite for combining premises, not a guarantee of a known answer. Missing, suspended, and conflicting states remain explicit. When both inputs are known constraints, their combination uses intersection of the permitted ruling sets. This operation must be distinguished from the meet operation on individual values of the five-element `Hukm` lattice [[2](#reference-2)].

In the current core, the target is structured and the other six fields remain numeric identifiers. Richer context and judgment records add typed questions, references, domain distinctions, temporal structure, evidence, and authority data. Accordingly, the seven-coordinate key is the complete key for this foundational guard; it is not an exhaustive description of every later admission check. The theorem below applies to whichever scope extractor and evaluator are explicitly selected.

The normative carrier has five distinct constructors, ordered in the declared model as $H<K<M<N<W$. Its involution $\sigma$ reverses order and satisfies the De Morgan equations, but is not a Boolean complement. In particular, $\sigma(M)=M$, so $M\wedge\sigma(M)=M\ne H$ and $M\vee\sigma(M)=M\ne W$. Boolean scope tests, report-sign indicators, and history truth values belong to their own types. Observation outcomes and missing or suspended judgments do not introduce additional normative values [[2](#reference-2), [4](#reference-4)].

## 3. A criterion for exact guarded descent

Let $X$ be a declared supported domain of inputs, $\kappa:X\to K$ extract their scope, and $u:X\to U$ be a proposed projection. Let $J:X\to V$ be the selected evaluator. The answer type $V$ is fixed for the stated question and interpretation, or is an explicitly tagged sum of answer families when several questions are represented. Untagged comparison across different answer types is not intended.

For each expected scope $k$, define the exact guard

$$
G_k(x)\quad\Longleftrightarrow\quad\kappa(x)=k.
$$

For any function $F:X\to B$, let

$$
\operatorname{FC}_u(F)\quad\Longleftrightarrow\quad
 \forall x,y,\ u(x)=u(y)\Longrightarrow F(x)=F(y).
$$

This says that $F$ is constant on every fiber of the projection. Write $u^\sharp:X\to\operatorname{im}(u)$ for the same projection with its codomain restricted to its image.

**Theorem 1 (Exact scope and answer preservation).** With the definitions above, the following statements hold.

**(1)** Every exact scope test is preserved precisely when the scope key is constant on each projection fiber:

$$
\bigl[\forall k,x,y,\ u(x)=u(y)\Rightarrow
       (G_k(x)\leftrightarrow G_k(y))\bigr]
 \quad\Longleftrightarrow\quad \operatorname{FC}_u(\kappa).
$$

**(2)** Exact joint preservation separates into its two components:

$$
\operatorname{FC}_u\bigl(x\mapsto(\kappa(x),J(x))\bigr)
 \quad\Longleftrightarrow\quad
 \operatorname{FC}_u(\kappa)\ \land\ \operatorname{FC}_u(J).
$$

**(3)** The joint result factors uniquely through $\operatorname{im}(u)$ if and only if the two conditions in item 2 hold. Thus there is a unique $\overline F:\operatorname{im}(u)\to K\times V$ with

$$
\overline F(u^\sharp(x))=(\kappa(x),J(x))
 \quad\text{for every }x
$$

exactly under those conditions.

**Proof.** For item 1, fiberwise equality of keys permits substitution in any test against $k$. Conversely, choose $k=\kappa(x)$. The test holds at $x$, so preservation on the fiber implies $\kappa(y)=\kappa(x)$.

For item 2, apply the two product projections to equality of the paired outputs. In the other direction, equality of both components gives equality of the pair.

For item 3, any factorization yields constancy on fibers. Conversely, for $z\in\operatorname{im}(u)$, choose $x$ with $u(x)=z$ and set $\overline F(z)=(\kappa(x),J(x))$. Item 2 makes this value independent of the representative. Every element of the image has such a representative, so the factor is unique on the image. ∎

Items 1 and 2 require only equality reasoning. The supplied Lean construction of a representative on the image uses classical choice and records its standard axiom dependencies. No answer is assigned to an unattested point of $U$. A total extension to all of $U$ needs an additional extension condition, such as an inhabited output type; such an extension supplies neither source authority nor a classification of unseen cases [[3](#reference-3)].

**Corollary 2 (Projection of keys).** When $X=K$ and $\kappa$ is the identity, a projection preserves all exact key tests if and only if it is injective on the supported keys.

**Proof.** The first condition of Theorem 1 becomes $u(x)=u(y)\Rightarrow x=y$, the definition of injectivity. ∎

The restriction to keys is essential. A projection of entire snapshots may be noninjective while retaining their complete scope. For example, it can discard an annotation irrelevant to both scope and the selected evaluator. The existing ACT-03 projection retains its specified observation scope and complete support/exception sign summaries while forgetting other snapshot information [[4](#reference-4)]. Conversely, a constant evaluator automatically satisfies $\operatorname{FC}_u(J)$ even when the projection merges distinct keys. Equal answers therefore cannot by themselves justify reuse under the scope guard.

The result is relative to the supported domain. A field fixed throughout that domain, or recoverable from retained data, may be omitted from the physical encoding without merging distinct keys. The theorem requires preservation of distinguishing information, not a universal claim that every named field is independently indispensable in every restricted domain.

## 4. A checked omission counterexample

We instantiate the obstruction using `Usul.IDA.Omission.evaluate`, rather than assigning a juristic meaning to a new Boolean model. Take two structurally well-formed omission descriptions with the same action, occurrence, clock, accountable person, performer, and other fixed coordinates. Their opportunities are

$$
o_{10}=[0,10),\qquad o_{20}=[0,20).
$$

The intervals are half-open. They are two candidate descriptions of the same named occurrence with different declared closing bounds; we do not assert that both are simultaneously correct accounts of an actual opportunity. Fix effective time and recording cutoff to $15$, with an empty report list and no coverage claim. The evaluator then gives

$$
\begin{aligned}
 J(o_{10})&=\mathrm{coverageMissing},\\
 J(o_{20})&=\mathrm{pending}.
\end{aligned}
$$

In the first case the window has closed but the required observation coverage has not been supplied. In the second the window remains open. These statuses are distinct constructors of the existing observation result type [[7](#reference-7)].

Let $u$ erase the opportunity bounds while retaining the other scope components. Then

$$
u(o_{10})=u(o_{20})\quad\text{and}\quad J(o_{10})\ne J(o_{20}).
$$

Hence $\operatorname{FC}_u(J)$ fails, and no exact evaluator on this reduced representation can recover both outcomes. The structured omission targets also differ, so the foundational scope keys differ. The actual `combine` operation returns `outOfScope` for these two keys, independently of the premise payloads.

**Proposition 3 (Opportunity information cannot be erased in this domain).** On any supported domain containing the two inputs above, erasure of their opportunity bounds preserves neither all exact target-scope tests nor the omission observation evaluator.

**Proof.** The unequal targets and unequal observation results give witnesses against the two fiber-constancy conditions in Theorem 1. ∎

The native appendix also isolates the other direction of the separation. Keep a closed omission scope fixed, with no completion reports. Without a coverage claim the result is `coverageMissing`; with the evaluator's complete supplied coverage record the result is `coveredNoCompletion`. Erasing coverage therefore loses an evaluator dependency even when the exact scope remains fixed.

These are theorems about the declared computation. In particular, `coverageMissing` is not a finding of actual nonperformance. Even `coveredNoCompletion` is relative to the supplied observation view and completeness claim. Neither result alone establishes a culpable omission, an agent's capacity, an actual feasible opportunity, or any particular `Hukm`. The counterexample uses no rulings attributed to a juristic school.

## 5. The accepted categorical integration

### Substitution preserves declared structure

For a fixed registry $R$, typed contexts and substitutions form a category $\mathcal C_R$. A description family has the form

$$
\operatorname{Desc}_R(\Gamma)=
 \sum_{k:\operatorname{Schema}(R)}\operatorname{Args}_R(\Gamma,k).
$$

A substitution $\sigma:\Delta\to\Gamma$ assigns a well-typed term in $\Delta$ to each variable of $\Gamma$. Reindexing is contravariant and obeys

$$
a[\mathrm{id}]=a,\qquad
 (a[\sigma])[\tau]=a[\sigma\circ\tau].
$$

The repository implements the relevant presheaves and a category of conditional premise contexts. Composition of premise arrows uses substitution admissibility and simultaneous cut; it does not follow merely from the syntax's substitution laws [[5](#reference-5)]. This fits the established categorical treatment of contexts and indexed structure [[10](#reference-10), [11](#reference-11)].

The category-of-elements interpretation records a description together with its context and gives the accepted discrete-fibration reading. It is a structural interpretation of the description presheaf. The inspected implementation does not yet expose a separately named construction of that category of elements, and richer dependent indexing remains conditional in the roadmap [[1](#reference-1)].

For the supported ACT-04 fragment, fixed-history interpretation satisfies the naturality equation

$$
I_{\Delta}(a[\sigma])(\delta)
 = I_{\Gamma}(a)(\operatorname{Val}(\sigma)(\delta)).
$$

Formula satisfaction has the corresponding substitution law. The history and interpretation are fixed. A new report, a changed opportunity, a revoked grant, or a different interpretive profile is not automatically a substitution in this category [[6](#reference-6)].

### Projection requires a separate factorization

The information-loss problem uses another category. Define $\ker(u)$ to have objects $X$, with a unique arrow $x\to y$ whenever $u(x)=u(y)$. This is a thin groupoid. A function $F:X\to B$ extends to a functor

$$
\ker(u)\longrightarrow\operatorname{Disc}(B)
$$

exactly when $\operatorname{FC}_u(F)$ holds, because an arrow in a discrete output category requires equality of its endpoints. IDA already proves this interface [[3](#reference-3)].

Theorem 1 says that scope is one of the outputs that must survive the projection. A functor for the answer alone supplies no functor for scope. The paired functor into $\operatorname{Disc}(K\times V)$ exists precisely when both components survive. This is the categorical content of exact guarded descent.

The accepted ruling lattice has its own categorical reading. With an arrow $h\to h'$ when $h\le h'$, its meet and join are products and coproducts in a thin category, and its order-reversing involution gives a duality. These algebraic laws organize the qualitative ruling values. They do not establish the facts, scope compatibility, or evidence admission needed for a judgment about a concrete omission [[2](#reference-2), [1](#reference-1)].

Changing schema or profile introduces a translation problem with its own semantic and admission hypotheses. The institution satisfaction condition is an appropriate interface for sentence translation and model reducts [[12](#reference-12)]; it does not establish a cross-profile ruling rule. Likewise, the accepted sheaf fragment glues compatible assignments on a specified cover. It does not prove that evidence-bearing admitted judgments form a sheaf, provide missing coverage, or resolve an attributed disagreement [[1](#reference-1)].

## 6. Verification status and reproducibility

The accepted design, repository results, and appendix proofs have different evidence records. The original local proof audit of 11 November 2026 inspected revision [`98d4052eded4`](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/commit/98d4052eded4063c9cb928c87120f44aa628f23d). Its tree is identical to the inspected parent [`a868d78e1ba6`](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/commit/a868d78e1ba6f6f0440ec32b68d1a06a8393b726). Successful hosted runs for that parent include [ACT-03 projection](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/actions/runs/43053122574), [ACT-04 fixed-history semantics](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/actions/runs/43053122470), and [authenticated omission observations](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/actions/runs/43053122778). These are source-tree evidence for the named gates, not a claim of a new run at the merge commit. Broader workflow failures and a cancellation remain in the same run inventory.

Publication compatibility was checked against main revision [`65062cec8125`](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/commit/65062cec81255be893cba2fd722c99c904d8eec2) on 15 November 2026. All eleven source modules in the native omission witness's import closure, and the Lean toolchain pin, are byte-identical to the original baseline. The original source citations retain that publication baseline; reference [[13](#reference-13)] pins the semantic extension separately. The newer receipt transport and workbench results are documented in the companion manuscript [[9](#reference-9)]; the original hosted runs are not relabelled as evidence for this later revision.

The generic appendix, integrated as `UsulTest.IDAGuardedContext`, formalizes the scope criterion, joint-output criterion, image factorization, the key-level injectivity specialization, typed target distinctions, and a harmless noninjective snapshot projection. Its additional finite-history illustration is explicitly a separate mathematical model. The file imports only Lean's `Init`; its original declaration namespace remains `IDAContextDescent`.

The native appendix, integrated as `UsulTest.IDAOmissionGuardWitness`, imports the repository definitions and proves the omission outcomes, erasure witnesses, and foundational guard rejection. The original fresh build compiled its eleven repository dependencies and all nineteen native witness theorems. The generic appendix compiled twenty-six named theorems. Every one of these forty-five declarations had an explicit compiled axiom audit. The recorded dependencies were limited to the standard `propext`, `Classical.choice`, and `Quot.sound`; the native witness used at most `propext`. No admitted proof holes or custom axioms occurred in those audited results.

The original publication, PR [174](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/pull/174), passed all fifteen associated hosted workflows at head [`0b205500b27e`](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/commit/0b205500b27ebc164b3050bb35d3d20b3893d45c), including the [formalization audit](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/actions/runs/43707539191). Its merge revision [`6a112f29d52d`](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/commit/6a112f29d52d08e3db9c3b8e92625603ee24682a) passed all thirteen associated workflows, including [formalization](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/actions/runs/43707899458) and [omission authentication](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/actions/runs/43707899506). These results concern the original forty-five-declaration publication and are distinct from the earlier local audit.

The semantic extension is pinned separately to [`784af396db02`](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/commit/784af396db0241c8c83da096d060740c93f4ff1d). It adds twelve production theorems in `Usul.IDA.Omission.Semantics` and seventeen test declarations in `UsulTest.IDAOmissionSemantics`, while retaining the original forty-five declarations. The new declarations were locally kernel-checked and explicitly audited. Their axiom dependencies are limited to `propext` and `Quot.sound`; some use neither. The three test contracts independently expand the forward, reverse, and equivalence statements, and the remaining controls exercise the hypotheses rather than identifying a supplied history with its reports [[13](#reference-13)]. Hosted evidence for the new extension must be tied to its own revision; the PR 174 runs do not verify it.

The three paper test modules are imported by `UsulTest`. The repository's `make lean` gate rebuilds the pinned Lean 4.34.1 package, inventories compiled declarations and their transitive axiom dependencies, and checks the registered paper claims. Its revision-bound receipt is written to `.cache/lean-axioms/core.json`. Reproduction commands and the declaration concordance accompany the online manuscript.

**Table 2. Claim boundaries for the manuscript**

| Claim | Evidence and boundary |
| --- | --- |
| Three target constructors and seven-field guard | Existing Lean definitions and theorems; this is structural scope checking. |
| Substitution and fixed-history naturality | Existing supported ACT-02/04 fragment with dedicated successful hosted evidence; affect inquiry transport is incomplete. |
| Exact guarded descent criterion | Compiled generic appendix, integrated into the repository audit; general factorization is credited to existing mathematics and project code. |
| Opportunity and coverage counterexamples | Compiled proofs using the repository's omission evaluator; observation statuses only. |
| Absence in the supplied event history | New conditional adequacy theorem and necessity controls; semantic exhaustiveness and matching-report soundness are explicit premises. |
| Actual-history correspondence | Deriving the semantic premises from a specified ledger and adapter, and relating that ledger to actual circumstances, remain separate obligations. |
| Juristic ruling and current admission | Separate interpretation, evidence, scope, authority, and provenance obligations. |

Current main also contains bounded signed premise ingestion for four compiled synthetic certificates and persistent replay receipts. The limitation is therefore generalization beyond that closed adapter, rather than complete absence of authentication or persistence [[8](#reference-8)]. Authentication identifies an exact submitted statement. It does not by itself establish that a coverage assertion is true.

## 7. Conditional semantic adequacy

### An event history independent of reports

The new semantic model uses the native omission scope and the two native completion modes. An event is the bounded content

$$
e=(s_e,m_e,\tau_e),\qquad
 h:\operatorname{Event}\to\mathbf{Prop},
$$

where $s_e$ is its exact `Omission.Scope`, $m_e$ its mode, and $\tau_e$ its occurrence time. The history $h$ is supplied independently of the report list. Membership $h(e)$ is a proposition in that supplied model; identifying the model with actual circumstances requires separate justification. Event identity here is equality of scope, mode, and occurrence time, not a globally unique physical-event identifier. Recording time belongs to reports, not to events [[13](#reference-13)].

For a native completion report $r$, define

$$
\begin{aligned}
 \operatorname{eventOf}(r)&=(r.\mathrm{scope},r.\mathrm{mode},r.\mathrm{occurredAt}),\\
 \operatorname{Represents}(r,e)&\iff\operatorname{eventOf}(r)=e.
\end{aligned}
$$

This relation preserves the full native scope, including the action, named parties, occurrence, clock, opportunity bounds, definition pins, and clock version. It does not assert that the represented event occurred. Write $\ell_s,u_s$ for the opening and closing bounds of scope $s$. Qualification and absence concern the entire half-open opportunity:

$$
\begin{aligned}
 \operatorname{Qualifies}(h,s,e)&\iff
 h(e)\land s_e=s\land\ell_s\le\tau_e\land\tau_e<u_s,\\
 \operatorname{NoQualifying}(h,s)&\iff
 \neg\exists e,\ \operatorname{Qualifies}(h,s,e).
\end{aligned}
$$

The effective time does not occur in this definition. Closure will justify a conclusion about the full window.

Let $\mathcal R$ be the report list, $t$ the effective time, and $c$ the recording cutoff. Semantic exhaustiveness states that every qualifying event has a report for the same event content, recorded chronologically by that cutoff:

$$
\begin{split}
 \operatorname{Exhaustive}(h,s,c,\mathcal R)\iff
 \forall e,\ &\operatorname{Qualifies}(h,s,e)\Rightarrow\\
 &\exists r\in\mathcal R,\ \operatorname{Represents}(r,e)\ \land\\
 &r.\mathrm{occurredAt}\le r.\mathrm{recordedAt}\le c.
\end{split}
$$

This condition does not define the history from reports and does not use the evaluator's final outcome. Matching-report soundness is a different premise:

$$
\begin{split}
 \operatorname{SoundFor}(h,s,t,c,\mathcal R)\iff
 \forall r\in\mathcal R,\ &\operatorname{Matches}(r,s,t,c)\Rightarrow\\
 &h(\operatorname{eventOf}(r)),
\end{split}
$$

where $\operatorname{Matches}$ means that the existing native Boolean predicate `Completion.matches` is true. Soundness is required only for the reports used by that predicate; unrelated or nonmatching reports need not be made semantic premises.

Write $\operatorname{Clean}(s,c,\mathcal R)$ for the native condition that no visible in-scope report has malformed chronology, and $\operatorname{Complete}(s,c,C)$ for `Coverage.Complete` on the supplied coverage argument $C$. The latter checks the exact scope, both modeled modes, and recording bounds. It does not establish semantic exhaustiveness. Finally, abbreviate the negative observation by

$$
\operatorname{Covered}(s,t,c,\mathcal R,C)\iff
 \operatorname{evaluate}(s,t,c,\mathcal R,C)=\mathrm{coveredNoCompletion}.
$$

### The adequacy theorem

**Theorem 4 (Conditional adequacy of covered omission observations).** For any supplied event history and native observation inputs:

**(1)** $\operatorname{Covered}(s,t,c,\mathcal R,C)$ and $\operatorname{Exhaustive}(h,s,c,\mathcal R)$ imply $\operatorname{NoQualifying}(h,s)$. Matching-report soundness is not required for this implication.

**(2)** $\operatorname{NoQualifying}(h,s)$, $\operatorname{SoundFor}(h,s,t,c,\mathcal R)$, $\operatorname{Clean}(s,c,\mathcal R)$, closure $u_s\le t$, and $\operatorname{Complete}(s,c,C)$ imply $\operatorname{Covered}(s,t,c,\mathcal R,C)$. Semantic exhaustiveness is not required for this implication.

**(3)** Under exhaustiveness, matching-report soundness, clean chronology, closure, and the structural coverage condition,

$$
\operatorname{Covered}(s,t,c,\mathcal R,C)
 \quad\Longleftrightarrow\quad
 \operatorname{NoQualifying}(h,s).
$$

**Proof.** For item 1, the existing `covered_iff` theorem supplies absence of matching reports and $u_s\le t$. Suppose $e$ qualifies. Exhaustiveness supplies a report $r$ representing that same event, with $r.\mathrm{occurredAt}\le r.\mathrm{recordedAt}\le c$. Qualification supplies the exact scope and the half-open bounds. Since $\tau_e<u_s\le t$, the report also satisfies the effective-time guard. Thus the native matching predicate is true, contradicting the absence of matching reports. These steps are isolated in `matches_of_qualifies` and `matching_report_of_qualifying`.

For item 2, any matching report would, by `SoundFor`, denote an event present in $h$. The native matching conditions supply its exact scope and half-open bounds, so `qualifies_of_matching` makes it a qualifying event, contradicting absence. No report therefore matches. Together with clean chronology, closure, and `Coverage.Complete`, this is exactly the antecedent of the existing `covered_iff` characterization. Item 3 combines the two implications. ∎

The three statements are compiled as `covered_no_completion_sound`, `covered_no_completion_complete`, and `covered_no_completion_iff`. They quantify over arbitrary supplied event predicates and report lists; the finite controls below do not delimit their quantifiers [[13](#reference-13)]. No additional assumption $t\le c$ is needed: effective time and the recording perspective are distinct coordinates, and the stated guards supply the bounds used in the proof.

The wrapper `review_covered_no_completion_sound` additionally starts with a successful native review, the exact equation `Scope.fromSnapshot expected = some s`, and exhaustiveness at the expected snapshot's cutoff. It concludes both current full-snapshot resolution and $\operatorname{NoQualifying}(h,s)$. This retains the existing snapshot check. The native omission scope is not the foundational seven-coordinate key or the complete admission record: its equality does not replace question, profile, context, evidence, or authority checks elsewhere. The wrapper yields an observation result and a conditional semantic conclusion, not a juristic ruling or a new admission grant.

### Counterexamples identify the necessary assumptions

The compiled controls reuse the native scope with opportunity $[0,10)$. Unless a row states otherwise, effective time and cutoff are both 15, and the supplied coverage claim names both modeled modes and is recorded at tick 10. The positive controls give a covered result in an empty supplied history and an observed completion when an event in the supplied history at tick 5 has a truthful report recorded at tick 5. The following five controls retain the other hypotheses relevant to the failed implication [[13](#reference-13)].

**Table 3. Necessity controls for the adequacy theorem**

| Missing premise | Independently supplied history and reports | Native outcome |
| --- | --- | --- |
| Exhaustiveness | An event occurs at tick 5; the report list is empty. | `coveredNoCompletion`, despite that event. |
| Matching-report soundness | The history is empty; a report claims a tick-5 completion, recorded at tick 5. | `completionObserved`, despite absence. |
| Clean chronology | The history is empty; a visible report claims occurrence at 5 and recording at 4. | `invalidObservation`. |
| Effective closure | The history and reports are empty; effective time is 9 and cutoff is 15. | `pending`. |
| Structural coverage claim | The history and reports are empty; no coverage claim is supplied. | `coverageMissing`. |

A further cutoff control places an event in the supplied history at tick 5 and its exact, chronological report at recording tick 20. At cutoff 15 that report is invisible. The evaluator returns `coveredNoCompletion` with the complete supplied claim, but semantic exhaustiveness fails. Existence of a correct report somewhere in the input list does not establish timely coverage. This control keeps the recording deadline in the semantic bridge.

The fixed-payload control holds the scope, times, empty report list, and complete supplied coverage claim constant. One supplied history is empty; another contains the tick-5 event. The evaluator returns the same negative observation in both, while `NoQualifying` differs. The authentication corollary quantifies over a predicate of that fixed payload and assumes that it accepts the payload. There still exists a supplied history with a qualifying event, the same accepted payload, and the same negative observation. This is a conditional limit on payload-only authentication. It neither exhibits a forged signature nor claims that a newly constructed batch was accepted by a concrete host. Semantic exhaustiveness and the selection of an intended actual history require their own justification.

### The next proof obligation

The conditional implication is now proved. The next implementation step is to derive `Exhaustive` and `SoundFor` from an independently specified event ledger and report adapter. Its contract must identify the ledger's qualifying events independently of the report list, preserve exact event content, establish the relevant recording deadline, and show that every matching report originates in that ledger. Coverage of the two modeled completion modes and the relation between the ledger and actual circumstances remain explicit assumptions unless separately justified. Defining the history to be exactly the reported events would make the intended coverage claim uninformative.

A second correspondence remains open: this event predicate `Omission.Semantics.History` is not ACT-04's `Usul.IDA.Semantics.History`, which assigns truth values to typed ground predicates. An interpretation connecting those models and preserving the intended event, temporal, and grounding relations needs its own theorem. Theorem 4 does not establish that bridge automatically.

Affect-aware inquiry substitution and interpretation remains a separate, concrete implementation gap. It should preserve the affect quality and typed object under reindexing, prove identity and composition, and then establish a supported naturality theorem. No general theorem that every projection preserves admissibility is conjectured here: it is false without additional hypotheses. Broader semantic and admission claims remain conditional contracts with their supported domain and external assumptions stated.

## 8. Positioning and limits

The result supplies a precise thesis for the academic paper: *context abstraction is valid relative to what must be preserved*. An abstraction may preserve a selected answer, exact scope, both, or neither. The omission example shows that loss can arise within the structured target itself, before disputes about sources or juristic interpretation enter the model. The theorem also permits useful abstraction when the relevant key and complete evaluator dependencies survive.

The contribution is therefore a formal method for controlling reuse in an accepted IDA architecture, supported by inspectable counterexamples and explicit proof obligations. It does not establish completeness for Islamic jurisprudence, doctrinal correctness of an interpretation, observation of private affective states, or universal transport across profiles. The proved omission theorem retains explicit semantic premises. The next ledger, adapter, and interpretation bridges must retain their own scope and actual-history assumptions rather than hide them in implementation flags.

## Appendix A. Lean declaration concordance and reproduction

The generic declarations live in namespace `IDAContextDescent`; native declarations live in `IDAPaper.NativeOmission`. The modules are [UsulTest.IDAGuardedContext](../../formal/lean/UsulTest/IDAGuardedContext.lean) and [UsulTest.IDAOmissionGuardWitness](../../formal/lean/UsulTest/IDAOmissionGuardWitness.lean). Their [generic plain-English companion](../plain-english/UsulTest/IDAGuardedContext.md) and [native plain-English companion](../plain-english/UsulTest/IDAOmissionGuardWitness.md) enumerate the original 45 theorems. The principal obligations are:

| Obligation | Exact declaration | Module |
| --- | --- | --- |
| Every exact scope test | `IDAContextDescent.all_scope_tests_iff_key_fiberConstant` | [Generic appendix](../../formal/lean/UsulTest/IDAGuardedContext.lean) |
| Joint scope and evaluator preservation | `IDAContextDescent.guarded_output_descent_criterion` | [Generic appendix](../../formal/lean/UsulTest/IDAGuardedContext.lean) |
| Uniqueness on the image | `IDAContextDescent.descended_map_unique` | [Generic appendix](../../formal/lean/UsulTest/IDAGuardedContext.lean) |
| Key-only specialization | `IDAContextDescent.identity_key_descent_iff_injective` | [Generic appendix](../../formal/lean/UsulTest/IDAGuardedContext.lean) |
| Native opportunity obstruction | `IDAPaper.NativeOmission.no_evaluator_after_erasing_bounds` | [Native witness](../../formal/lean/UsulTest/IDAOmissionGuardWitness.lean) |
| Native foundational guard | `IDAPaper.NativeOmission.guarded_combination_rejects` | [Native witness](../../formal/lean/UsulTest/IDAOmissionGuardWitness.lean) |
| Native coverage obstruction | `IDAPaper.NativeOmission.no_evaluator_after_erasing_coverage` | [Native witness](../../formal/lean/UsulTest/IDAOmissionGuardWitness.lean) |

The semantic extension adds [`Usul.Typing.IDAOmissionSemantics`](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/784af396db0241c8c83da096d060740c93f4ff1d/formal/lean/Usul/Typing/IDAOmissionSemantics.lean) and [`UsulTest.IDAOmissionSemantics`](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/784af396db0241c8c83da096d060740c93f4ff1d/formal/lean/UsulTest/IDAOmissionSemantics.lean). Its [production companion](../plain-english/Usul/Typing/IDAOmissionSemantics.md) and [test companion](../plain-english/UsulTest/IDAOmissionSemantics.md) enumerate twelve production theorems and seventeen test declarations. The production namespace is `Usul.IDA.Omission.Semantics`. Principal declarations are:

- Exact event correspondence: `represents_iff`.
- Native matching from a timely same-event report: `matches_of_qualifies` and `matching_report_of_qualifying`.
- Qualification from a sound matching report: `qualifies_of_matching`.
- Adequacy in the two directions: `covered_no_completion_sound` and `covered_no_completion_complete`.
- Conditional equivalence: `covered_no_completion_iff`.
- Exact current-snapshot wrapper: `review_covered_no_completion_sound`.

The test namespace `UsulTest.IDAOmissionSemantics` contains the independently expanded `forward_statement_contract`, `reverse_statement_contract`, and `equivalence_statement_contract`; the five named necessity controls; the two positive controls; the fixed-payload history and authentication controls; and `late_report_not_exhaustive`. Four helper theorems establish the test histories and their elementary properties [[13](#reference-13)].

From a checkout of the published revision with the pinned Lean toolchain available, the focused build is:

```sh
cd formal/lean
lake build UsulTest.IDAGuardedContext \
           UsulTest.IDAOmissionGuardWitness \
           Usul.Typing.IDAOmissionSemantics \
           UsulTest.IDAOmissionSemantics
```

From the repository root, `make lean` performs the complete compiled axiom audit and resolves the registered paper claims. From `pipeline/`, the documentation and layer checks are:

```sh
python -m pytest -q tests/test_plain_english.py \
                    tests/test_layers.py
python -m usul_corpus roadmap --base origin/main
```

The roadmap command compares a publication branch with its base; after merging, use the PR's base revision to reproduce that comparison. Theorem 4 is now covered by the registered semantic declarations and independent statement contracts. Deriving its assumptions from an event-ledger adapter and proving the separate ACT-04 interpretation correspondence remain open obligations.

## Bibliography

1. <a id="reference-1"></a> IDA project. *IDA context theory and categorical integration*. Accepted specification. [Pinned source](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/65062cec81255be893cba2fd722c99c904d8eec2/docs/research/ida-context-theory.md), 2026.

2. <a id="reference-2"></a> IDA project. *Usul.IDA*. Structured targets, qualitative algebra, and guarded conjunction. [Pinned Lean source](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/65062cec81255be893cba2fd722c99c904d8eec2/formal/lean/Usul/IDA.lean), 2026.

3. <a id="reference-3"></a> IDA project. *Usul.Cat.Factor*. Kernel-groupoid and set-theoretic factorization. [Pinned Lean source](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/65062cec81255be893cba2fd722c99c904d8eec2/formal/lean/Usul/Cat/Factor.lean), 2026.

4. <a id="reference-4"></a> IDA project. *ACT-03 scoped projection and information loss*. [Specification](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/65062cec81255be893cba2fd722c99c904d8eec2/docs/research/ida-projection.md); [pure proofs](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/65062cec81255be893cba2fd722c99c904d8eec2/formal/lean/Usul/Typing/IDAProjection.lean); [categorical adapter](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/65062cec81255be893cba2fd722c99c904d8eec2/formal/lean/Usul/Cat/IDAProjection.lean), 2026.

5. <a id="reference-5"></a> IDA project. *ACT-02 typed substitution and premise contexts*. [Pure Lean source](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/65062cec81255be893cba2fd722c99c904d8eec2/formal/lean/Usul/Typing/IDASubstitution.lean); [categorical adapter](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/65062cec81255be893cba2fd722c99c904d8eec2/formal/lean/Usul/Cat/IDASubstitution.lean), 2026.

6. <a id="reference-6"></a> IDA project. *ACT-04 fixed-history semantics*. [Specification](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/65062cec81255be893cba2fd722c99c904d8eec2/docs/research/ida-semantics.md); [pure proofs](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/65062cec81255be893cba2fd722c99c904d8eec2/formal/lean/Usul/Typing/IDASemantics.lean), 2026.

7. <a id="reference-7"></a> IDA project. *ACT-08 bounded omission observation*. [Specification](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/65062cec81255be893cba2fd722c99c904d8eec2/docs/research/ida-omission-coverage.md); [Lean evaluator and proofs](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/65062cec81255be893cba2fd722c99c904d8eec2/formal/lean/Usul/Typing/IDAOmission.lean), 2026.

8. <a id="reference-8"></a> IDA project. *Authenticated contextual premise ingestion*. [Pinned specification](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/65062cec81255be893cba2fd722c99c904d8eec2/docs/research/ida-premise-ingestion.md), 2026.

9. <a id="reference-9"></a> IDA project. *Typed Context and Conditional Soundness in Islamic Deontic Algebra*. [Companion manuscript](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/65062cec81255be893cba2fd722c99c904d8eec2/docs/research/ida-context-theory-manuscript.md), 14 November 2026.

10. <a id="reference-10"></a> S. Awodey and A. Bauer. *Introduction to Categorical Logic*, chapter 4. Draft, 20 April 2024. [Author-hosted notes](https://awodey.github.io/catlog/notes/catlog4.pdf).

11. <a id="reference-11"></a> B. Jacobs. *Categorical Logic and Type Theory*. Studies in Logic and the Foundations of Mathematics 141. North Holland, 1999. [Author's book page](https://www.cs.ru.nl/B.Jacobs/CLT/bookinfo.html).

12. <a id="reference-12"></a> J. A. Goguen and R. M. Burstall. Institutions: Abstract model theory for specification and programming. *Journal of the ACM*, 39(1), 95–146, 1992. [Article](https://courses.grainger.illinois.edu/cs522/sp2016/InstitutionsAbstractModelTheory.pdf).

13. <a id="reference-13"></a> IDA project. *Conditional semantic adequacy of omission observations*. [Pinned production proofs](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/784af396db0241c8c83da096d060740c93f4ff1d/formal/lean/Usul/Typing/IDAOmissionSemantics.lean); [independent contracts and counterexamples](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/784af396db0241c8c83da096d060740c93f4ff1d/formal/lean/UsulTest/IDAOmissionSemantics.lean), 15 November 2026.
