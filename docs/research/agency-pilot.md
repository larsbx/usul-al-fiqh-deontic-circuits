# Joint agency: Lean and Quint verification pilot

This is the first implementation from the Hanbali formalization shortlist. It
extends the repository's candidate readings with a finite operational model of
joint agency and proofs about arbitrary successful histories. Its legal output
is limited to the modeled agency conditions at execution. Full transaction
validity, scholarly acceptance, and application refinement remain separate.

The [source profile](agency-source-profile.md) gives the precise passages,
existing witness identities, reported alternatives, and candidate compositions.
The model never selects one reported revocation position as the preferred
position of the school and does not add accepted propositions to the corpus.

## Implemented scope

There is one fixed principal, two fixed agents, one initial mandate, and one
fixed task. The principal is living and capable; the initial appointment is
valid and known to both agents. A shared independent-permission flag grants
solo authority to both agents or to neither. Asymmetric grants are outside this
fragment. Whole-mandate revocation, each agent's knowledge of it, withdrawal,
and attempted execution are separate events.

The two profiles are `immediate` and `onKnowledge`. In the second profile,
knowledge is a supplied fact, not an inference from notification delivery.
An expressly joint act requires effective authority for both agents. Combining
these rules when only one agent knows of revocation is explicitly a candidate
composition pending doctrinal review.

Two operational restrictions make this pilot finite and reviewable: there is
no reappointment, and the task may be accepted at most once. The latter is a
workflow restriction, not a general statement that an agent may act only once.
An accepted receipt records who acted and persists through later revocation,
knowledge, and withdrawal events. It does not settle separate questions about
rescission, compensation, or third-party rights.

## Components

| Component | Role |
|---|---|
| [`Usul.Agency`](../../formal/lean/Usul/Agency.lean) | Typed configuration, state, event relation, arbitrary-history proofs, and finite wire encodings |
| [`UsulTest.Agency`](../../formal/lean/UsulTest/Agency.lean) | Kernel-checked cases and executable regression examples |
| [`ExportAgency.lean`](../../formal/lean/scripts/ExportAgency.lean) | Evaluates the Lean relation for the complete finite transition table |
| [`agency.qnt`](../../formal/quint/agency.qnt) | Independently written Quint relation and executable state machine |
| [`Quint harness`](../../formal/quint/README.md) | Declared scenarios, exhaustive transition comparison, reachable-state checks, and negative controls |
| [`Source checker`](../../formal/check-agency-sources.mjs) | Checks existing full-file locks and three delimited source passages; rejects corruption and missing locators |
| [`Axioms checker`](../../formal/check-agency-axioms.mjs) | Rebuilds both modules and audits every named theorem, requiring complete output and only standard permitted axioms |

## State and event contract

The six state flags are `appointed`, `revoked`, `knownA`, `knownB`,
`withdrawnA`, and `withdrawnB`. The receipt is one of `none`, `a`, `b`, or
`joint`. This gives **256 raw states**. Many are unreachable, such as knowledge
of revocation before revocation; they remain in the complete comparison domain.
Lean proves the causal constraints for states reachable from the initial state.

Four configurations combine the two profiles with the symmetric permission
flag. Thirteen events cover appointment, revocation, knowledge for each agent,
withdrawal for each agent, three in-scope execution attempts, stuttering, and
three explicitly out-of-scope attempts.

The comparison domain is therefore **4 × 256 × 13 = 13,312** inputs. A result
of `-1` denotes a disabled transition; other results encode the successor state.
Each implementation evaluates its own relation. Neither implementation is
generated from the other's transition table.

The `onKnowledge` implementation uses `not known` as the revocation guard.
On coherent reachable states this equals `not (revoked and known)`, because
knowledge implies revocation. Outputs on inconsistent raw states are part of
the executable comparison contract, not additional legal rulings.

Disabled attempts are not transitions in Lean's `Run` or Quint's state machine.
The scenario harness may record a rejection and continue from the unchanged
state. Thus the arbitrary-history theorems concern successful transitions;
they do not assert that an application cannot receive an unauthorized request.

## What is verified

Lean's proofs address reachable-state coherence, scope preservation, joint-only
receipts when independent permission is absent, historical receipt persistence,
and execution-count conservation over arbitrary finite successful histories.
The conservation theorem establishes at-most-once acceptance for the chosen
one-task workflow. Further theorems exclude later execution after the relevant
revocation/knowledge cutoff and identify the authority at an execution's actual
pre-state.

The executable checks cover independently declared scenarios and every
one-step input in the finite wire domain. Negative controls deliberately remove
the independent-permission requirement or substitute the knowledge condition for
immediate revocation; the associated scenarios must reject those mutants.
Parse errors, missing tools, or an absent Lean export do not count as detecting
a semantic mutant.

Exhaustive executable agreement is conformance evidence for this finite model.
It is not a Lean theorem about Quint's implementation, a proof of the compilers,
or a refinement theorem for an application. The verification receipts retain the
actual counts and checks run. Simulation, where used, is labeled separately
from exhaustive enumeration.

The source checker verifies two already registered witnesses against the
unchanged `corpus/lock.json` entries and locates three relevant passages. It
does not turn the candidate source-to-model mapping into a reviewed conclusion.
The background Ibn Rajab readings in the source profile are not additional
premises silently executed by this model.

The axioms gate audits all 50 named theorems (35 core and 15 scenario theorems).
Its allowlist is `propext`, `Classical.choice`, and `Quot.sound`; the actual
dependency list is recorded per theorem. Synthetic parser controls ensure that
an admitted proof, custom axiom, missing result, or malformed output cannot
be reported as successful verification. A failed check removes its preceding
success receipt so a local rerun cannot leave stale acceptance evidence.

## Reproduce

Use the Lean version in `formal/lean/lean-toolchain` and the Quint version in
`formal/quint/package-lock.json`; CI uses Node 22.

```sh
git lfs pull --include="corpus/texts/openiti-buhuti-kashshaf-shamela21642.txt,corpus/texts/openiti-ibnqudama-mughni-shamela8463.txt"
npm --prefix formal/quint ci
make lean
make agency
cd pipeline
python -m pytest -q tests/test_plain_english.py tests/test_roadmap.py
python -m usul_corpus roadmap --base origin/main
```

Missing source bytes or verification tools fail the agency command. It never
updates the source locks or downloads replacement text under a different hash.
The dedicated [workflow](../../.github/workflows/agency.yml) runs on changes to
its model, tooling, source pins, or documentation and retains evidence artifacts.
The existing corpus, Lean, TLA+, Prolog, and roadmap workflows remain in place.

## Next modules from the shortlist

The next independent Lean target is a source-scoped inheritance allocator using
exact shares, initially restricted to known spouse/parent/child cases with a
son. The next commercial integration is a debt model separating hawala,
guarantee, payment, and release. These are **proposed follow-up modules**.

For this pilot, the next obligations are review of the mixed-knowledge and
withdrawal compositions, asymmetric permission, and a separately stated mapping
from application evidence and concurrent execution to the model's supplied
facts and atomic events. Adding an application does not make its behavior a
consequence of these proofs without that mapping and its verification.
