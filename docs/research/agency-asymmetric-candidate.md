# Candidate asymmetric agency permission

The original [source profile](agency-source-profile.md) and its symmetric
wire format remain the reference for the merged pilot. This companion
models the K1 distinction in al-Buhūtī, *Kashshāf al-Qināʿ*, book of agency,
printed 3:472–473, between permission for a specified agent and permission
for each. K1 is checked against the existing locked witness
`openiti-buhuti-kashshaf-shamela21642`. No source lock or classification
changes here.

Each agent receives a separate solo permission. Solo execution requires
that actor's own grant, effective authority, and an empty receipt.
Joint execution continues to require both actors' effective authority
and an empty receipt. Withdrawal and actual knowledge of revocation are
individual facts. Neither fact transfers a grant to the other actor.
Mixed-knowledge joint action, and an independently authorized survivor
continuing after withdrawal, remain candidate compositions. The proofs
concern modeled authority. Legal validity and evidence of actual knowledge
are separate obligations.

The Lean extension proves that symmetric grants preserve every step and
every finite run in the prior model. It also proves that a change in one
agent's solo permission leaves the other agent's solo transition
unchanged. Once an agent withdraws, or knows of revocation under the
knowledge profile, no event in a successful suffix can involve that
agent. The actor-swapped fixtures establish feasible continuing solo
histories and reject permission transfer to an ungranted survivor.

The extension's configuration code is four times the profile code plus
the mask. A's bit is 1 and B's is 2. The original configurations
`0, 1, 2, 3` correspond to extension codes `0, 3, 4, 7`. State and event
codes are inherited. The new configuration code is scoped to 0 through
7, and the checker tests that domain exhaustively.

Run `npm --prefix formal/quint ci` and `make agency-mask`. The gate checks
the existing source anchors, builds the Lean proofs, runs independent
Quint cases, rejects a mutant that reads A's grant bit for B, compares all
26,624 transition rows, and checks all 13,312
symmetric rows against the original export. The receipt and exports are
written under `.cache/agency-mask/`.
