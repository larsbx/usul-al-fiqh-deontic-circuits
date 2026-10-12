# ADR 0001: the logic core

Status: **proposed** (roadmap M1 exit: merged after review). Date 2026-10-12.

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
| **Structured argumentation** (ASPIC⁺ over Dung AFs) | yes: arguments are built from premises and rules, and ḥudūd enter as predicates | **yes**: any inference scheme, analogy included, is a rule; tamthīl and shumūl are two schemes whose arguments can be compared | **yes**: undercut (exception), rebut, undermine; arguments are terms, so the supporting dalīl is part of the conclusion | **yes**: preferred and stable extensions *are* the aqwāl; the grounded extension is the uncontested core | yes: finite AFs, a computable grounded extension, Lean semantics |

## Decision

**Use structured argumentation over Dung frameworks, with a tarjīḥ preference and the kernel's own resolution order, as the logic core.** Use SDL/KD only as a fragment, for strict (qaṭʿī) rules.

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
| Admissible ⊆ preferred (Dung's fundamental lemma) | **open**: needs `Preferred` (a maximal admissible set) and, for finite AFs, a maximality argument by cardinality |

Until the fundamental lemma lands, M1 stays "kernel proved", with the ADR as its other exit criterion.
