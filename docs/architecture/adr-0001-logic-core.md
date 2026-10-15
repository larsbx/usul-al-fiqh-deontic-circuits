# ADR 0001: the logic core

Status: **proposed** (roadmap M1 exit: merged after review; the Lean half of the exit is proved). Date 2026-10-12.

## Context

The roadmap (§0.1) fixes three constraints, taken from Ibn Taymiyya's *al-Radd ʿalā al-Manṭiqiyyīn*, before any axiom:

- **C1. No essentialist ḥadd.** A definition is a distinguishing mark (tamyīz), so ḥudūd are decidable predicates with coverage obligations. They are not real definitions.
- **C2. Tamthīl is primitive.** Qiyās al-tamthīl is an inference rule in its own right, inter-convertible with shumūl when the ʿilla is general. It is not a degraded syllogism.
- **C3. Defeasible and proof-relevant.** Uṣūl reasoning admits defeat: takhṣīṣ, naskh, tarjīḥ, mawāniʿ, mustathnayāt. *Which* dalīl supports a ḥukm matters, not only *that* one does.

Two further requirements come from the method (`derivation-method.md` §2, §4):

- **R1.** Ikhtilāf is data. Two riwāyas, or two wujūh, must both be expressible as admissible outcomes, never collapsed by the encoding.
- **R2.** The carrier is Lean 4, with Python and Haskell mirrors checked against it. The core must be computable on finite instances and provable in general.

## Options

| Option | C1 tamyīz | C2 tamthīl primitive | C3 defeasible, proof-relevant | R1 ikhtilāf as data | R2 Lean, finite, executable |
|---|---|---|---|---|---|
| **SDL / KD** (□-style O with D) | neutral | no: no inference beyond modus ponens | **no**: monotone; Chisholm's contrary-to-duty and Ross's paradox are derivable; conflicting obligations explode or are forbidden by D | **no**: one consistent theory; two riwāyas are inconsistent | yes, but only for the strict fragment |
| **Input/output logic** (Makinson–van der Torre) | yes: norms are pairs, no definitions | partly: derivation rules are fixed operations (OR, AND, CT), with no analogy rule | partly: constrained output handles some exceptions; defeasibility and *which norm* fired are not first-class | weak: multiple maxfamilies exist but are a side construction | yes |
| **Defeasible deontic logic** (Governatori et al.) | yes | no: rules only | yes: strict, defeasible and defeater rules, a superiority relation, team defeat | weak: the skeptical semantics gives one conclusion set, so a tie suspends without both outcomes surfacing | yes (linear-time proof theory) |
| **Structured argumentation** (ASPIC⁺ over Dung AFs) | yes: arguments are built from premises and rules, and ḥudūd enter as predicates | **yes**: any inference scheme, analogy included, is a rule; tamthīl and shumūl are two schemes whose arguments can be compared | **yes**: undercut (exception), rebut, undermine; arguments are terms, so the supporting dalīl is part of the conclusion | **yes**: preferred extensions can retain alternative admissible argument sets; stable extensions are optional and may not exist; their interpretation as aqwāl requires a structured, source-linked encoding | yes: finite AFs, a computable grounded extension, Lean semantics |

## Decision

**Propose structured argumentation over Dung frameworks, with a tarjīḥ preference and the kernel's own resolution order, as the logic core.** The implemented abstract AF semantics do not yet establish the structured-argument compilation or its jurisprudential adequacy. Use SDL/KD only as a fragment, for strict (qaṭʿī) rules.

| Roadmap element | Realised by |
|---|---|
| AF semantics | `Usul.Dung`: `ConflictFree`, `Defends`, the characteristic function `F`, `Admissible`, `Complete`, the approximation chain `approx` |
| Executable bridge | `Usul.Grounded` (`grounded`, with `defended_iff` and `mem_step_iff` tying each step to `F`) |
| Preference (tarjīḥ) | `Usul.Reconcile`: graded support compared lexicographically, `prevail`, and the grade order mirrored from the annotation convention |
| Resolution order | `Usul.Taarud.resolve`: jamʿ → naskh → tarjīḥ → tawaqquf |
| Exceptions | conservative refinements (`*_conservative`), never rewrites |
| Tamthīl | `Usul.QiyasLimits.tamthil_iff_shumul` and `shumul_of_factors` (C2) |
| Ḥukm algebra | `Usul.Hukm` (σ, `σ_involutive`, `σ_antitone`, `amr_nahy_didd`) |

Concretely, ikhtilāf is not an error class. The takhrīj bank records `genuine_ikhtilaf` with every position, and the ledger resolves apparent contradictions without deleting the other side (R1). Every output keeps its derivation: a reading, its facts, and the evidence and grade behind a tarjīḥ (C3).

## Independently checked semantic boundary (2026-10-13)

This review checks mathematical scope, not scholarly acceptance. The ADR remains **proposed**.

### Finite examples

Arguments are numbered; an edge a → b means a attacks b. Sets here contain arguments, not rulings.

| Framework | Grounded | Preferred | Stable |
|---|---|---|---|
| 0 → 1 → 2 → 0 | ∅ | {∅} | none |
| 0 ↔ 1 | ∅ | {{0}, {1}} | {{0}, {1}} |
| three unattacked arguments | {0,1,2} | {{0,1,2}} | {{0,1,2}} |
| 0 ↔ 1, unattacked 2 | {2} | {{0,2}, {1,2}} | {{0,2}, {1,2}} |
| three-cycle plus 3 → 0 | {1,3} | {{1,3}} | {{1,3}} |
| 0 → 0 | ∅ | {∅} | none |

The isolated directed three-cycle has no stable extension. Merely *containing* an odd cycle is insufficient for that conclusion: external attacks can restore stability. Preferred existence on finite AFs may yield only the empty extension; it does not guarantee a supported opinion.

Use the **family of preferred extensions** as the proposed default for alternative admissible argument sets. Retain the full family and all source positions. Stable semantics may be offered only with an existence check, an explicit no-stable result, or a separately proved sufficient assumption on the constructed AF. Do not silently delete positions when stability fails or invent attacks to force it.

Grounded is the least complete argument set under the stated finitary hypothesis. Calling it an “uncontested core” is a candidate interpretation relative to the chosen defeat relation, not a theorem about ijmāʿ or scholarly consensus. It need not equal the intersection of preferred extensions: for 0 ↔ 1, 0 → 2, 1 → 2, 2 → 3, grounded is empty while both preferred extensions ({0,3}, {1,3}) contain 3.

### What the Lean carrier supports

- **Proved abstract properties:** the M1 table below, with finitary/finite hypotheses as stated. The added `Stable`, `stable_admissible`, and `stable_preferred` establish the one-way stable ⇒ preferred implication. `UsulTest.ExtensionSemantics.cycle_no_stable` proves the finite three-cycle counterexample.
- **Executable bridge:** `defended_iff` and `mem_step_iff` identify defense and one restricted step. The existing file does not prove the n+1-step stabilization bound or final list equality with abstract grounded; that bridge obligation remains open. Endpoint bounds must be imposed for the finite 0..n-1 carrier.
- **Separate implemented components:** `Reconcile.prevail` selects a reported ruling from graded supports; it is not a selection function over preferred extensions. `QiyasLimits.tamthil_iff_shumul` proves extensional ruling equivalence under a nonempty feature class, not conversion of derivation terms preserving grade.
- **Structured obligations still open:** the inspected `Dung` carrier has only an argument type and an attack relation. It defines no premise/rule argument trees, source locators, undercut/rebut/undermine constructors, subargument closure, preference-to-defeat compilation, or provenance-preservation theorem. Separate source receipts and kernel readings do not establish this missing link.

No extension semantics by itself preserves evidence provenance. A structured layer must retain distinct argument IDs for distinct derivations even when their conclusions coincide, with premise/source receipts, rule applications, subarguments and grades. Its compilation must define attacks versus successful defeats, preserve the source links, and establish the intended closure/consistency properties before extension members are projected to jurisprudential positions. Not every recorded position is necessarily admissible under every candidate encoding; keep rejected or unsupported source positions with reasons instead of erasing them.

A muʿtamad projection needs a separately specified, versioned selection policy if a single output is required: its domain, eligibility, ties/no-selection, source authority and evidence trace. It must select only eligible extensions and retain alternatives. Until that contract exists, return alternatives or tawaqquf without claiming `prevail` has selected an extension. Ijmāʿ remains RQ-01; neither grounded membership nor agreement across preferred extensions promotes a report to ijmāʿ.

### Replay and validation scope

`pipeline/tests/test_extension_semantics.py` independently enumerates subsets and checks the examples above, including the skeptical-preferred counterexample. It exhausts all **531 labelled AFs on 0..3 nodes including self attacks**, checking grounded completeness/leastness, preferred existence, preferred completeness and stable ⇒ preferred. This finite enumeration is a regression, not a universal proof.

`formal/lean/UsulTest/ExtensionSemantics.lean` is imported by the normal Lean test root and checks grounded examples plus the universal no-stable theorem for the three-node carrier. Replay with `make lean` and `python -m pytest pipeline/tests/test_extension_semantics.py -q`.

The companion oracle PR #31 (merge `de452e7d2f828b88f39cc546e93a64c1e4d2ac9f`) checks grounded fingerprints on 10⁴ generated AFs pinned to uṣūl merge `b796eb5d782e43e57c47c6fa14c37e6cc94dd279`. It does **not** check preferred/stable semantics, structured argument compilation, source provenance or jurisprudential adequacy.

## Consequences

- **Gained:**
  - Disagreement is first-class.
  - Exceptions are local and auditable.
  - Analogy is a scheme with its own attacks: the qawādiḥ in `Usul.Jadal`.
  - The same finite instances are checked by three carriers. The M5 differential test reproduces one digest over 10⁴ generated AFs in Python, Lean and Haskell.
- **Given up:**
  - No single deontic modal calculus with a completeness theorem.
  - Norms are not closed under logical consequence (no inheritance law), which avoids the KD paradoxes by construction.
  - The strict fragment does not yet have its own KD model in Lean.
- **Open questions:**
  - **Selection among preferred extensions.** The muʿtamad, al-Mardāwī's selection, is modelled by graded evidence and tarjīḥ, not by a semantics. Whether some selection *function* is the right formal object is a register question, not an axiom.
  - **The place of ijmāʿ.** It currently enters as evidence that changes no class (RQ-01).

## M1 Lean obligations: proved and open

| Roadmap M1 result | Status |
|---|---|
| Grounded extension is conflict-free | `approx_conflictFree` for every stage; `grounded_conflictFree` for their union `grounded` |
| Grounded is admissible | `approx_admissible`, `grounded_admissible` |
| Grounded exists, is the least complete extension, and is unique | **proved** for finitary AFs (finitely many attackers per argument, every AF the bank builds): `grounded_complete`, `grounded_sub_complete`, `grounded_unique` |
| Admissible ⊆ preferred (Dung's fundamental lemma) | **proved** for finite AFs (arguments listed by some `U`): `Preferred`, `exists_preferred_superset`, `exists_preferred` (by strong induction on the arguments left outside) |

With these, the stated abstract M1 Lean exit is met. This mathematical scope review does not accept the proposed ADR or close the structured/provenance, selection, final executable bridge, M4 multiple-extension encoding, or M7 dialogue-correspondence obligations.

