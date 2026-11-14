---
title: "Typed Context and Conditional Soundness in Islamic Deontic Algebra"
subtitle: "Research manuscript draft"
date: "2026-11-14"
lang: en
---

## Abstract

A rule can apply to a well-typed description under stated premises, an authority can admit reports supporting those premises for a particular inquiry, and the premises can hold in a semantic history. These are three distinct judgments. We present the accepted context theory of Islamic Deontic Algebra (IDA) and its implemented fragment. Typed substitutions act contravariantly on descriptions and formulas. A category of premise contexts adds derivability witnesses to substitutions, making transport compositional by simultaneous cut. Fixed-history interpretation commutes with reindexing. For a successfully reconstructed admission receipt, the grounded destination conclusion follows in every history satisfying the destination premises, and the receipt binds the conclusion to an exact inquiry and certificate list. A countermodel using the repository's synthetic repayment fixture holds the admitted receipt fixed while varying a single semantic truth value. Even a receipt with a nonempty compatible candidate population can coexist with a history that falsifies its conclusion. The results give a formal basis for inspectable conditional reasoning in a deontic workbench. Substantive juristic rule soundness and the relation between reports and actual circumstances require additional evidence and theorems.

**Keywords** · contextual deontic reasoning, typed substitution, categorical semantics, premise admission, uṣūl al-fiqh, Lean

## 1. Context and the object of judgment

A deontic inquiry needs an identifiable act, omission, or affect, an accountable subject, a question, and a scope in which an answer is sought. For example, a repayment description can name a payer, recipient, and obligation. The accountable subject is a separate coordinate, and the identity of the obligation persists through substitutions that change the two person arguments. A change of recipient can change the qualified act or its application even when the operation and argument sorts are unchanged. The accepted IDA design treats act kind, qualified description, occurrence, and source mention as distinct identities [1].

The object of a ruling is denoted here by *al-maḥkūm fīh* (المحكوم فيه), also expressed in the project terminology as *al-maḥkūm bih* (المحكوم به). The accountable addressee is *al-maḥkūm ʿalayh* (المحكوم عليه). These terms orient the formal roles. Equating particular classical usages with implementation fields would require text- and school-specific argument. The accepted IDA interface uses question-indexed answers. A question about a *ḥukm taklīfī* (حكم تكليفي) can draw on the five categories of obligation (*wājib*), recommendation (*mandūb*), permissibility (*mubāḥ*), reprehensibility (*makrūh*), and prohibition (*ḥarām*). Questions of validity, attribution, and discharge have their own answer types. Missing evidence, conflict, and unsupported interpretation are evaluation statuses. This article proves results for contextual formulas used by that interface. A theorem assigning a substantive ruling would require a source-supported rule with an independently justified semantics.

We use $R$ for the act registry, $v$ for the predicate vocabulary, $P$ for the interpretation and its version pins, $A$ for admission authority, and $E$ for the attributed evidence available at evaluation. A typed variable context $\Gamma$ determines the available reference slots. A premise list $\Phi$ records what an argument assumes. A valuation $\rho$ resolves the slots. The inquiry $\Omega$ determines the question, target, accountable subject, temporal coordinates, and scope. A semantic history $h$ determines the truth values of interpreted ground predicates. In the accepted design, the judgment

$$P;\Gamma;\Phi\vdash\Omega\Rightarrow r,\qquad r\in\operatorname{Answer}(\Omega.\mathrm{question})$$

has a semantic obligation of the form

$$
h,\rho\models_P\Phi
 \land P;\Gamma;\Phi\vdash\Omega\Rightarrow r
\quad\Longrightarrow\quad
\operatorname{Holds}_P(h,\operatorname{ground}(\Omega,\rho),r).
$$

The admission judgment $(P,A,E,\Omega,\rho)\Vdash_{\mathrm{adm}}\Phi$ concerns exact evidence and authority for the grounded application. The Lean fragment studied here proves the corresponding semantic implication with a formula $f$ as conclusion. The broader question-indexed implication above states the accepted interface and the obligation for extending the fragment [1, 2].

## 2. Typed syntax and conditional entailment

A context is a finite list of reference sorts. Write $\operatorname{Var}_k(\Gamma)$ for the positions of sort $k$ in $\Gamma$. A term of sort $k$ is a variable at such a position or a well-formed rigid reference of sort $k$. Let $[]$ denote the empty context. A grounding $\gamma_\rho:[]\to\Gamma$ substitutes a rigid reference for each slot. A description consists of a resolved registry schema and a tuple of terms indexed by its ordered argument sorts. Named roles belong to the schema. Reindexing acts on the terms and preserves the schema, the equality of repeated variable occurrences, and the well-formedness of the grounded action. Terms of the same sort may legally exchange positions. Their roles retain their respective names.

A formula is a signed atom $p^s(t_1,\ldots,t_n)$ for a typed predicate $p$ and polarity $s\in\{0,1\}$, or a conjunction $f\land g$. A negative atom is a signed atomic assertion, with no connective for arbitrary formula negation. The entailment $\Phi\vdash f$ is generated by list membership and conjunction introduction and elimination. Its proof-irrelevant Lean type is `Derives`. There is no explosion rule. In fact, `Derives.iff_atoms` characterizes entailment by membership of every complete signed atom of $f$ among the conjunction leaves of the premises. The forward direction follows by induction on the derivation. For the reverse direction, use conjunction elimination to recover each required atom from an assumed premise, then reassemble $f$ by introduction. This characterization also makes entailment decidable in the implemented syntax.

A substitution $\sigma:\Delta\to\Gamma$ supplies a term in $\Delta$ for each slot of $\Gamma$. The implementation spells this type `Sub Γ Δ`. For $\tau:\Xi\to\Delta$, its composite $\sigma\circ\tau$ is `σ.then τ`. Pointwise variable substitution gives the identities and associativity. Structural recursion on argument tuples and formulas yields

$$u[\mathrm{id}]=u,\qquad u[\sigma][\tau]=u[\sigma\circ\tau].$$

The same substitutions act on an inquiry's description, performer, and accountable reference. Inquiry-frame pins are preserved by pure substitution. Explicit administrative changes made during application reconstruction are additional operations.

**Lemma 1 (Substitution and simultaneous cut).** If $\Phi\vdash f$, then $\Phi[\sigma]\vdash f[\sigma]$. If $\Phi\vdash f$ and $\Psi\vdash g$ for every $g\in\Phi$, then $\Psi\vdash f$.

**Proof.** Induct on the derivation in each case. An assumption remains a member of the mapped list under substitution. Under cut, replace that assumption by the supplied derivation. In both inductions, rebuild the conjunction constructor or elimination step from the induction hypotheses. These are `Derives.subst` and `Derives.cut`. ∎

## 3. Categorical constructions and interpretation

Let $\mathcal C$ have typed contexts as objects and the substitutions above as arrows. For fixed $R$ and $v$, descriptions and formulas define presheaves $D_R,F_v:\mathcal C^{op}\to\mathbf{Set}$ by reindexing. Lean packages these with its small category interface. In the category of elements of $D_R$, an arrow $(\Delta,b)\to(\Gamma,a)$ lies over $\sigma:\Delta\to\Gamma$ when $b=a[\sigma]$. Given $\sigma$ and $(\Gamma,a)$, the unique lift with that codomain has domain $(\Delta,a[\sigma])$. Composition uses $a[\sigma][\tau]=a[\sigma\circ\tau]$. Thus the forgetful projection is a discrete fibration. This is the mathematical construction specified in [1], derived here from the compiled presheaf laws. The declaration inventory in Appendix A concerns the presheaves and their laws.

Let $\mathcal P_v$ be the premise-context category. Its objects are $(\Gamma,\Phi)$. An arrow $(\Delta,\Psi)\to(\Gamma,\Phi)$ is a pair $(\sigma,w)$ with $w$ witnessing $\Psi\vdash g[\sigma]$ for every $g\in\Phi$. Identity uses the assumption rule. For a second arrow $(\Xi,\Theta)\to(\Delta,\Psi)$ over $\tau$, apply Lemma 1 to get $\Psi[\tau]\vdash g[\sigma][\tau]$. The second arrow supplies the replacements for $\Psi[\tau]$. Cut and the substitution composition law give $\Theta\vdash g[\sigma\circ\tau]$. Equality of arrows follows from equality of substitutions because the witnesses are propositions. Associativity and unit laws therefore reduce to the substitution laws. The functor $U:\mathcal P_v\to\mathcal C$ forgets the premises and their witnesses. Provenance lives in the separate receipt data, where certificate occurrences retain their identity and order. A concrete attestation needs destination validation even when a conditional proof transports.

For fixed $h$, a Lean history assigns a Boolean to every well-typed ground predicate application in $v$. Satisfaction for an atom compares that Boolean with its explicit sign. Conjunction requires both conjuncts. For a list, $h,\rho\models\Phi$ means satisfaction of every member. If $\delta\in V(\Delta)$, where $V(\Delta)$ is the type of valuations of $\Delta$, then $V(\sigma)\delta\in V(\Gamma)$ evaluates each supplied term in $\delta$. The grounding law is $\gamma_{V(\sigma)\delta}=\sigma\circ\gamma_\delta$. It implies the functor laws for $V:\mathcal C\to\mathbf{Set}$.

Precomposition with $V(\sigma)$ makes $\Gamma\mapsto(V(\Gamma)\to B)$ a presheaf for any fixed codomain $B$. Boolean evaluation defines a natural transformation from $F_v$ to this presheaf with $B=\mathrm{Bool}$. The description interpreter gives a second transformation with codomain $\operatorname{Option}(B)$ for an underlying denotation type $B$. It reads the grounded description against a supported registered definition and role signature, returning an optional denotation. The laws are

$$
\begin{aligned}
h,\delta\models f[\sigma]&\iff h,V(\sigma)\delta\models f,\\
I_\Delta(a[\sigma])(\delta)&=I_\Gamma(a)(V(\sigma)\delta),\\
\operatorname{ground}(\Omega[\sigma],\delta)&=
 \operatorname{ground}(\Omega,V(\sigma)\delta).
\end{aligned}
$$

For atoms, both evaluation paths give the same ground tuple by the grounding law. Induction extends this equality to conjunctions. For descriptions, both paths pass the same grounded description to the interpreter. For inquiries, grounding composition gives equality before conversion to the ground representation. The last equality concerns pure substitution, with a fixed inquiry frame. A change in evidence, interpretation, history, or administrative scope requires its own justification. A map between compatible valuation spaces supports preservation of a conclusion on its image. Reflection back to every source point requires coverage of those points or an independent argument.

## 4. Exact contextual admission and the transport theorem

In the implemented route, a plan carries source and destination premise contexts, a premise arrow from destination to source, a source inquiry and conditional derivation, and separate source and destination valuations. It constructs the destination inquiry $\Omega_d$ by substituting into the source inquiry and explicitly setting the destination subject identifier, context identifier, and admission policy. The question is preserved. The plan stores the source valuation independently. The naturality comparison uses $V(\sigma)\delta$, which may differ from the stored source valuation.

A concrete application stores a snapshot, every grounding slot, an ordered list of ground premises, and a ground conclusion. Each certificate binds a token, the entire application, a ground formula, and a source premise. For each side, `Side.Valid` requires exact application equality, current snapshot resolution, exact grounded inquiry and frame, agreement of vocabulary, exact equality of the ordered certificate-formula list with the grounded premises, certificate authorization, and a grant for the exact side. Certificate authorization checks snapshot scope, a nonzero token that resolves uniquely to the supplied certificate in the authenticated catalog, and source admission by the derivation environment. The Lean admission checker takes that catalog as input. The signed fixture adapter authenticates its closed bundle externally and then supplies those inputs [3]. The checker contains no semantic-history argument.

**Theorem 2 (Conditional soundness of a reconstructed application).** Fix $R,v$, a plan $p$ with source $(\Gamma,\Phi)$, destination $(\Delta,\Psi)$, arrow $(\sigma,w)$, source derivation $\Phi\vdash f$, and destination valuation $\delta$. Suppose reconstruction with authority $A$ and submitted sides $S,D$ returns receipt $c$. With $q_c$ the recorded destination inquiry, $C_c$ the recorded ordered destination certificate list, and $f_c$ the recorded ground conclusion, the following hold:

1. The receipt retains $S,D,A$ and both validations. In particular, $q_c=\operatorname{ground}(\Omega_d,\delta)$, its question equals the source question, the formulas of $C_c$ are exactly $\Psi[\gamma_\delta]$, and $f_c=f[\sigma][\gamma_\delta]$.
2. $\Psi\vdash f[\sigma]$. Along every further premise-context arrow over $\tau$, the transported conditional conclusion is $f[\sigma\circ\tau]$ and is derivable from the new premises.
3. For every $h$ and the empty valuation $\epsilon$,

   $$
 h,\delta\models\Psi
 \quad\Longrightarrow\quad
 h,\epsilon\models f_c .
 $$

   The truth value of $f_c$ at $\epsilon$ is the truth value of $f$ at $V(\sigma)\delta$ in the same history.

**Proof.** In the successful branch `reconstruct` has checked both sides. `reconstruct_preserves_provenance` identifies the submitted sides and authority with those in $c$. The fields of `destinationValid` give exact snapshot, inquiry, certificate, and application equalities. Unfolding `Plan.destinationApplication` gives the equation for $f_c$. The destination frame update leaves the question field intact.

For (2), substitute $\sigma$ into the source derivation and cut with $w$. This is `Plan.reconstructed`. Apply the same substitution-and-cut argument to the second arrow, then use formula composition. The second arrow carries a conditional derivation. Applying it to a concrete occurrence requires its own admission check.

For (3), induction on the reconstructed derivation proves satisfaction from $h,\delta\models\Psi$. In the assumption case use premise satisfaction. In the remaining cases use introduction or projection of Boolean conjunction. This is `Semantics.sound` as applied by `Plan.conditional_sound`. Apply satisfaction under $\gamma_\delta$ and use $V(\gamma_\delta)\epsilon=\delta$. The exact application equation identifies the resulting closed formula with $f_c$, yielding `Admission.Receipt.conditional_sound`. The final equality follows by applying the evaluation substitution law first to $\gamma_\delta$, then to $\sigma$. ∎

The compiled `Usul.IDA.Admission.Receipt.transport_contract` checks the exact destination inquiry and certificate formulas, reconstructed derivability, agreement at the pulled valuation, and conditional soundness [12]. Provenance and the preserved question follow from the accompanying receipt contracts. Further transport uses substitution and cut again. The truth implication assumes that the semantic history satisfies the destination premises. The pilot receipt and workbench view carry that same implication.

## 5. A countermodel with the admitted receipt fixed

**Proposition 3 (Admission and finite robustness can coexist with a false conclusion).** There is a successful synthetic workbench receipt and a semantic history in the same Lean vocabulary in which its admitted ground conclusion is false.

**Proof.** Use the compiled `UsulTest.IDAPilot.plan`. Its destination premises are $[p^+(x),q^-(y)]$ and its source conclusion is $p^+(y)\land q^-(x)$. The premise arrow swaps the slots. At `valuation 0`, $x$ resolves to the reference coded 1 and $y$ to the reference coded 2. Here $p$ is the version-1 predicate and $q$ the version-2 predicate in the synthetic fixture. The recorded destination conclusion is therefore

$$f_c=p^+(1)\land q^-(2).$$

The numerals in this formula are display codes for the rigid person references. The baseline `resultCode 9 2 0 = 0` in `UsulTest.IDAPilot.nonidentity_admitted` and the workbench's `source_bound_baseline_checked` give the successful fixture. Its candidate history list is `histories 2 = [history 1]`. From `UsulTest.IDASemantics.history`, evaluation of the unsigned applications $p(1)$ and $q(2)$ reads bits 0 and 3 of the mask, respectively. Consequently the two relevant histories are

| History | $p(1)$ | $q(2)$ | Satisfies destination premises | Satisfies $f_c$ |
|---|---:|---:|---|---|
| `history 1` | 1 | 0 | yes | yes |
| `history 0` | 0 | 0 | no | no |

Keep the full baseline receipt, its authority, reports, grounded certificates, and supplied candidate list fixed. Evaluate the conclusion in the separately supplied history `history 0`. Its positive conjunct evaluates to false, so the conjunction is false. The pilot's compatible list remains nonempty since `history 1` is still its candidate. The alternate history has the same vocabulary and typed reference carriers. The receipt soundness theorem quantifies over histories with a premise-satisfaction hypothesis, and the second row fails that hypothesis. ∎

The compiled `UsulTest.IDACaseWorkbench.admission_and_robustness_do_not_imply_truth` witnesses a successful `sourceBoundTrial`, a nonempty compatible candidate list, and falsity of the presented conclusion in `history 0`. Its proof uses the exact conclusion retained by the receipt. The dedicated workbench gate compiles an independent statement of this proposition [12]. The predicate keys, source bytes, and signing keys are synthetic.

For an external application, a sufficient bridge is a justified claim that each ground premise certified for this application holds in the independently identified actual history $h_*$, under the pinned interpretation. The exact certificate-list equation and grounding law then supply $h_*,\delta\models\Psi$. Alternatively, a finite assessment can be used if there is independent justification that the actual point lies in its **compatible** set. Merely placing the actual point in the candidate list leaves open whether filtering discards it. The countermodel shows why neither a signature nor the existence of a compatible candidate supplies this bridge.

## 6. Scoped projection and workbench interpretation

The implemented projection retains the evaluator's exact scope and the support and exception report signs used by one synthetic rule. `projection_exact` proves that evaluation through those dependencies gives the full evaluator result. `frame` gives equal outputs on inputs with equal projections. The categorical adapter `evaluation_functor` packages this bounded factorization. A report pair has four states according to its positive and negative components: unknown, supported, refuted, and conflicted. The pilot guard requires the exact scope, positive-only support, and negative-only exception evidence. An absent exception report and a conflicting exception report both fail the guard. The Booleans encoding report signs and the Boolean denotation of a ground predicate belong to different structures.

The pilot assesses a supplied finite list of histories, holding the destination valuation fixed. It filters by satisfaction of the premises and distinguishes an empty population from a nonempty population with no compatible points. `robust_iff` requires at least one compatible point and satisfaction at every compatible point. The workbench view preserves that nonvacuity witness, both signs, the grounded premise list, and source and destination certificate occurrences. It inherits conditional soundness with the same satisfaction hypothesis. Synthetic scenario exploration can show exactly which assumptions or reports change an outcome. An adjudicator (*qāḍī* in the classical jurisprudential terminology) or mufti reviews evidence and applies the authority appropriate to the institution and question. The view's presentation perspective carries no additional formal authority.

## 7. Relation to prior work and requirements for submission

The use of contexts and substitutions follows standard categorical logic. Awodey and Bauer [5] give the syntax and reindexing perspective, and Jacobs [6] develops indexed and fibred categories. The present contribution is the composition of those structural mechanisms with exact application-specific admission and a receipt-level semantic implication. The substitution/satisfaction square resembles the satisfaction condition of Goguen and Burstall [7]. Here the implemented arrows change variable contexts over a fixed vocabulary, and their semantic action pulls valuations. A full institution across vocabulary revisions would require signature morphisms, sentence translation, model reducts, and the relevant satisfaction law.

Von Wright [8] supplies a historical point of comparison for deontic operators. Input/output logic [9] is a closer comparator for moving from factual inputs through norms to normative outputs. The current entailment layer is the signed conjunctive fragment. A comparative treatment should specify normative rule activation, constraints, conflicting norms, and the semantics of question-indexed outputs before claiming a translation or expressiveness result. McCarthy and Buvač [10] address lifting between contexts. IDA's premise-context arrows state the derivations required for the lift and leave occurrence-specific evidence to the admission layer.

Hallaq [11] supplies historical orientation for Sunni legal theory. A jurisprudential submission should cite identified Arabic editions and passages for each claimed Ḥanbalī interpretation, the act and subject terminology, the distinction between evidentiary proof (*bayyina*) and particular forms of testimony (*shahāda*) where relevant, the authority of a report, and distinctions among normative judgment, validity, and discharge. It should justify any link between formal case grounding and *taḥqīq al-manāṭ* (تحقيق المناط), the inquiry into whether a rule's operative criterion is realized in the case, and state the role of the reviewer in that link. The mathematical results stand on the declared calculus and models. Substantive doctrinal comparisons require that additional primary-source work.

## 8. Limits and open obligations

The verified fragment has variables and rigid references, signed atoms, conjunctions, a fixed-vocabulary interpretation, and bounded application machinery. Its semantic induction covers the stated proof rules. General rule soundness for a question-indexed answer, quantified or defeasible rules, and compatibility under profile or vocabulary migration require additional rules and proofs. The accepted design also provides conditional milestones for richer dependent families and semantic coherence. The discrete fibration described in Section 3 follows from ordinary presheaf laws and entails no claim about descent, sheaf gluing, or a general comprehension structure.

The implemented projection applies to its declared evaluator and dependencies. An evaluator with new defaults, exceptions, or time dependencies needs a new factorization argument. A robust conclusion is relative to its compatible set. Conclusive claims about omissions need independently justified opportunity bounds and observation coverage. Authority replay in the core checks exact equality of supplied authority and reruns validation. Real institutional authorization, arbitrary evidence ingestion, independent actual-history identification, and cross-revision or cross-profile reuse require distinct work. The synthetic workbench and case-specific adapter demonstrate a bounded path with closed inputs. They leave the broader ACT-08 exit and human-decision workflow open [3, 4].

## Appendix A. Lean declaration concordance

The paths below are relative to `formal/lean/`. The concordance is pinned to main at `957dedf27c86fdc6d3f70271c3c4ef92cf8c376d`, the merge of PR #169 [12].

| Result | Module and exact declarations |
|---|---|
| Typed syntax and proof calculus | [Usul/Typing/IDASubstitution.lean](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/957dedf27c86fdc6d3f70271c3c4ef92cf8c376d/formal/lean/Usul/Typing/IDASubstitution.lean), namespace `Usul.IDA.Substitution`: `Sub.assoc`, `Args.get_subst`, `Description.schema_preserved`, `Inquiry.ground_comp`, `Formula.subst_comp`, `Derives.subst`, `Derives.cut`, `Derives.iff_atoms`, `PremiseArrow.comp`, `PremiseArrow.assoc` |
| Categorical transport | [Usul/Cat/IDASubstitution.lean](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/957dedf27c86fdc6d3f70271c3c4ef92cf8c376d/formal/lean/Usul/Cat/IDASubstitution.lean), namespace `Usul.Cat.IDASubstitution`: `contexts`, `premiseContexts`, `forgetPremises`, `descriptions`, `formulas` |
| Semantic substitution and entailment | [Usul/Typing/IDASemantics.lean](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/957dedf27c86fdc6d3f70271c3c4ef92cf8c376d/formal/lean/Usul/Typing/IDASemantics.lean), namespace `Usul.IDA.Semantics`: `grounding_pull`, `satisfaction_subst`, `premises_subst`, `sound`, `sound_along`, `interpret_subst`, `inquiry_subst`, `opposing_premises_incompatible`, `robust_iff` |
| Naturality | [Usul/Cat/IDASemantics.lean](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/957dedf27c86fdc6d3f70271c3c4ef92cf8c376d/formal/lean/Usul/Cat/IDASemantics.lean), namespace `Usul.Cat.IDASemantics`: `valuations`, `meanings`, `description_naturality`, `formula_naturality` |
| Projection | `Usul.IDA.Projection.projection_exact` and `Usul.IDA.Projection.frame` in [Usul/Typing/IDAProjection.lean](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/957dedf27c86fdc6d3f70271c3c4ef92cf8c376d/formal/lean/Usul/Typing/IDAProjection.lean). `Usul.Cat.IDAProjection.evaluation_functor` in [Usul/Cat/IDAProjection.lean](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/957dedf27c86fdc6d3f70271c3c4ef92cf8c376d/formal/lean/Usul/Cat/IDAProjection.lean). |
| Admission and the receipt | [Usul/Typing/IDAAdmission.lean](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/957dedf27c86fdc6d3f70271c3c4ef92cf8c376d/formal/lean/Usul/Typing/IDAAdmission.lean), namespace `Usul.IDA.Admission`: `Side.Valid`, `Plan.reconstructed`, `Plan.conditional_sound`, `reconstruct_preserves_provenance`, `Receipt.destination_grounding`, `Receipt.destination_certificates`, `Receipt.destination_question`, `Receipt.conditional_sound`, `Receipt.transport_contract`, `replay_changed` |
| Pilot and display | `Usul.IDA.Pilot.Receipt.compatible_history` and `Usul.IDA.Pilot.Receipt.conditional_sound` in [Usul/Typing/IDAPilot.lean](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/957dedf27c86fdc6d3f70271c3c4ef92cf8c376d/formal/lean/Usul/Typing/IDAPilot.lean). `Usul.IDA.CaseWorkbench.View.exact_certificates`, `View.all_source_occurrences`, `View.nonvacuous`, and `View.conditional_sound` in [Usul/Typing/IDACaseWorkbench.lean](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/957dedf27c86fdc6d3f70271c3c4ef92cf8c376d/formal/lean/Usul/Typing/IDACaseWorkbench.lean). |
| Countermodel inputs | `UsulTest.IDASemantics.valuation` and `history` in [UsulTest/IDASemantics.lean](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/957dedf27c86fdc6d3f70271c3c4ef92cf8c376d/formal/lean/UsulTest/IDASemantics.lean). `UsulTest.IDAPilot.plan`, `histories`, and `nonidentity_admitted` in [UsulTest/IDAPilot.lean](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/957dedf27c86fdc6d3f70271c3c4ef92cf8c376d/formal/lean/UsulTest/IDAPilot.lean). `UsulTest.IDACaseWorkbench.source_bound_baseline_checked` and `admission_and_robustness_do_not_imply_truth` in [UsulTest/IDACaseWorkbench.lean](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/957dedf27c86fdc6d3f70271c3c4ef92cf8c376d/formal/lean/UsulTest/IDACaseWorkbench.lean). |

## Appendix B. Reproduction and evidence

Start from a clean checkout of the stated revision. Use Elan with the repository pin `leanprover/lean4:v4.34.1`, Python 3, and Node 22 with `node:sqlite`. Run the following at the repository root.

```sh
git checkout --detach 957dedf27c86fdc6d3f70271c3c4ef92cf8c376d
git rev-parse HEAD
git status --porcelain
npm --prefix formal/quint ci
make lean ida-case-workbench
make ida-substitution ida-projection ida-semantics ida-admission
make ida-premise-ingestion
```

For a declaration-level audit after building the core, save the following as a temporary Lean file outside the checkout. From the formal/lean directory, run `lake env lean /absolute/path/to/Audit.lean`. Inspect the printed types for the satisfaction hypothesis and the axiom output for any unexpected dependencies.

```lean
import Usul.Cat.IDASemantics
import Usul.Typing.IDACaseWorkbench
import UsulTest.IDACaseWorkbench

#check Usul.Cat.IDASemantics.formula_naturality
#check Usul.IDA.Semantics.sound_along
#check Usul.IDA.Admission.Plan.reconstructed
#check Usul.IDA.Admission.Receipt.destination_certificates
#check Usul.IDA.Admission.Receipt.conditional_sound
#check Usul.IDA.Admission.Receipt.transport_contract
#check UsulTest.IDACaseWorkbench.admission_and_robustness_do_not_imply_truth
#print axioms Usul.IDA.Admission.Receipt.transport_contract
#print axioms UsulTest.IDACaseWorkbench.admission_and_robustness_do_not_imply_truth
```

The first Make invocation audits compiled core declarations and runs the workbench gate. The component targets exercise the more focused contracts. Inspect the revision and input-binding fields of the reports under `.cache/` and compare them with the checkout. The workflow retains the core audit, workbench formal and host reports, pilot trace, and generated interface package. To reproduce hosted evidence at an exact PR revision, substitute that SHA in the checkout command. Revision-bound package digests can change with the revision.

- **ACT-01–05 integration.** PR #160 reports exact-head local proof and replay evidence at `6e1c0552406bff45994ecba5c84e9087b72a2c12`. Its merge-time account lists thirteen hosted successes and a pending dedicated semantics run, alongside a successful local semantics replay [2].
- **Workbench, earlier head.** Run [43031702167](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/actions/runs/43031702167) succeeded at `1c7289f4480e2db8dd6835c2dd6ed7147435e596`. The PR reports 19 universal workbench theorems, seven fixture controls, and 384 bounded scenario rows compared with Quint. These are different kinds of evidence. The bounded comparisons check agreement over the enumerated inputs.
- **Workbench, final PR head.** At `e6661d8453bed39304bd3b14f250a829fd98e953`, run [43041931743](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/actions/runs/43041931743) passed the core audit and workbench verification step and retained the package. The overall job failed at Playwright and Chromium installation, and browser execution was skipped. The separate [fixed-history semantics run](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/actions/runs/43041931568) and [admission run](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/actions/runs/43041931839) passed at this head. The broader [Formalization pipeline](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/actions/runs/43041931560) failed. PR #169 supplies the later hosted replay below.

- **Manuscript proof replay.** All 15 hosted workflows passed at `e4cb646200e5ca5ba448d6203bd42b6ffbefc91a`. The [core audit](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/actions/runs/43511490385/job/132182590830) compiled 20,487 declarations in 183 modules and resolved the registered workbench claims. The dedicated [admission](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/actions/runs/43511490538), [fixed-history semantics](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/actions/runs/43511490396), and [workbench](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/actions/runs/43511490411) workflows passed. Main at `957dedf27c86fdc6d3f70271c3c4ef92cf8c376d` has the same files as the tested head [12].

## Bibliography

1. Islamic Deontic Algebra project. “IDA context theory and categorical integration.” Accepted project specification. [Merge-pinned text](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/957dedf27c86fdc6d3f70271c3c4ef92cf8c376d/docs/research/ida-context-theory.md).
2. Islamic Deontic Algebra project. “Integrate the accepted contextual core and bounded ACT-08 pilot.” [Pull request 160](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/pull/160).
3. Islamic Deontic Algebra project. “Authenticated premise ingestion for the ACT-08 repayment fixture.” [Merge-pinned protocol](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/957dedf27c86fdc6d3f70271c3c4ef92cf8c376d/docs/research/ida-premise-ingestion.md).
4. Islamic Deontic Algebra project. “Add an IDA case workbench for adjudicator and mufti review.” [Pull request 163](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/pull/163), [merge source tree](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/tree/f9b66fb0b4683ddbbac5ee6ef10484a3fcba2b5d).
5. Awodey, Steve, and Andrej Bauer. *Introduction to Categorical Logic*. Lecture notes, ch. 4. [Author-hosted chapter](https://awodey.github.io/catlog/notes/catlog4.pdf).
6. Jacobs, Bart. *Categorical Logic and Type Theory*. Studies in Logic and the Foundations of Mathematics 141. Elsevier, 1999. [Publisher record](https://shop.elsevier.com/books/categorical-logic-and-type-theory/jacobs/978-0-444-50170-7).
7. Goguen, Joseph A., and Rod M. Burstall. “Institutions: Abstract Model Theory for Specification and Programming.” *Journal of the ACM* 39, no. 1 (1992), 95–146. [Article](https://cseweb.ucsd.edu/~goguen/pps/ins.pdf).
8. von Wright, Georg Henrik. “Deontic Logic.” *Mind* 60, no. 237 (1951), 1–15. [DOI](https://doi.org/10.1093/mind/LX.237.1).
9. Makinson, David, and Leendert van der Torre. “Input/Output Logics.” *Journal of Philosophical Logic* 29 (2000), 393–408. [Author manuscript](https://orbilu.uni.lu/bitstream/10993/26428/1/10.1.1.114.6153.pdf).
10. McCarthy, John, and Saša Buvač. “Formalizing Context (Expanded Notes).” [Author-hosted text](https://www-formal.stanford.edu/jmc/mccarthy-buvac-98/context/context.html).
11. Hallaq, Wael B. *A History of Islamic Legal Theories: An Introduction to Sunnī Uṣūl al-Fiqh*. Cambridge University Press, 1997. [DOI](https://doi.org/10.1017/CBO9780511801266).
12. Islamic Deontic Algebra project. Receipt transport and the workbench countermodel in [PR 166](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/pull/166), statement and audit gates in [PR 167](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/pull/167), and compiled replay in [PR 169](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/pull/169). [Main revision](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/commit/957dedf27c86fdc6d3f70271c3c4ef92cf8c376d).
